//
//  ExplorationManager.swift
//  EarthLord
//
//  探索管理器
//  负责管理探索流程、GPS追踪、距离计算
//

import Foundation
import CoreLocation
import Combine
import Supabase

/// 探索轨迹点
struct ExplorationTrackPoint {
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let accuracy: Double
}

/// 探索管理器
/// 负责管理探索流程、GPS追踪、距离计算
@MainActor
final class ExplorationManager: ObservableObject {

    // MARK: - 单例

    static let shared = ExplorationManager()

    // MARK: - 发布属性

    /// 当前探索状态
    @Published private(set) var state: ExplorationState = .idle

    /// 是否正在探索
    @Published private(set) var isExploring = false

    /// 当前探索的有效距离（米）
    @Published private(set) var currentDistance: Double = 0

    /// 当前探索时长（秒）
    @Published private(set) var currentDuration: TimeInterval = 0

    /// 探索轨迹点
    @Published private(set) var trackPoints: [ExplorationTrackPoint] = []

    /// 最新探索结果
    @Published var latestResult: ExplorationResult?

    // MARK: - 私有属性

    private let locationManager = LocationManager.shared
    private var startTime: Date?
    private var durationTimer: Timer?
    private var samplingTimer: Timer?
    private var lastValidLocation: CLLocation?
    private var lastLocationTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 配置常量

    /// 最小精度要求（米）
    private let minAccuracy: Double = 50.0
    /// 最大跳变距离（米）
    private let maxJumpDistance: Double = 100.0
    /// 最小时间间隔（秒）
    private let minTimeInterval: TimeInterval = 1.0
    /// 采点间隔（秒）
    private let sampleInterval: TimeInterval = 3.0

    // MARK: - 初始化

    private init() {
        print("🔍 [探索管理器] 初始化")
    }

    // MARK: - 公共方法

    /// 开始探索
    func startExploration() {
        guard canStartExploration() else {
            return
        }

        print("🔍 [探索] 开始探索")

        // 重置状态
        resetExplorationData()

        // 设置状态
        state = .exploring
        isExploring = true
        startTime = Date()

        // 确保定位服务运行
        if !locationManager.isUpdatingLocation {
            locationManager.startUpdatingLocation()
        }

        // 启动时长计时器
        startDurationTimer()

        // 启动采点定时器
        startSamplingTimer()
    }

    /// 结束探索
    func stopExploration() async -> ExplorationResult? {
        guard isExploring else {
            print("🔍 [探索] 当前未在探索状态")
            return nil
        }

        print("🔍 [探索] 结束探索，开始计算奖励...")

        state = .processing
        isExploring = false

        // 停止计时器
        stopTimers()

        let endTime = Date()
        let duration = startTime.map { endTime.timeIntervalSince($0) } ?? 0

        // 计算奖励等级
        let tier = RewardTier.from(distance: currentDistance)

        // 生成奖励物品
        var collectedItems: [CollectedItem] = []
        if tier != .none {
            collectedItems = await RewardGenerator.shared.generateRewards(tier: tier)
        }

        // 保存探索记录到数据库
        let sessionId = await saveExplorationSession(
            startTime: startTime ?? endTime,
            endTime: endTime,
            duration: Int(duration),
            distance: currentDistance,
            tier: tier,
            itemsCount: collectedItems.count
        )

        // 将物品保存到背包
        if let sessionId = sessionId, !collectedItems.isEmpty {
            await InventoryManager.shared.addItems(
                collectedItems,
                sourceType: "exploration",
                sourceSessionId: sessionId
            )
        }

        // 构建结果
        let stats = ExplorationStats(
            totalDistance: currentDistance,
            duration: duration,
            pointsVerified: trackPoints.count,
            distanceRank: tier.displayName
        )

        let result = ExplorationResult(
            isSuccess: tier != .none,
            message: tier == .none ? "行走距离不足200米，未获得奖励" : "探索成功！",
            itemsCollected: collectedItems,
            experienceGained: calculateExperience(tier: tier, distance: currentDistance),
            distanceWalked: currentDistance,
            stats: stats,
            startTime: startTime ?? endTime,
            endTime: endTime
        )

        latestResult = result
        state = .completed

        print("🔍 [探索] 探索完成，距离: \(String(format: "%.1f", currentDistance))m，等级: \(tier.displayName)，物品: \(collectedItems.count)个")

        return result
    }

    /// 取消探索（不保存记录）
    func cancelExploration() {
        guard isExploring else { return }

        print("🔍 [探索] 取消探索")

        stopTimers()
        resetExplorationData()
        state = .idle
        isExploring = false
    }

    // MARK: - 私有方法

    /// 检查是否可以开始探索
    private func canStartExploration() -> Bool {
        guard state == .idle || state == .completed || isFailedState() else {
            print("🔍 [探索] 当前状态不允许开始探索: \(state)")
            return false
        }

        guard locationManager.isAuthorized else {
            state = .failed("需要定位权限")
            return false
        }

        return true
    }

    /// 检查是否为失败状态
    private func isFailedState() -> Bool {
        if case .failed = state {
            return true
        }
        return false
    }

    /// 重置探索数据
    private func resetExplorationData() {
        currentDistance = 0
        currentDuration = 0
        trackPoints.removeAll()
        startTime = nil
        lastValidLocation = nil
        lastLocationTimestamp = nil
        latestResult = nil
    }

    /// 启动时长计时器
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.startTime else { return }
                self.currentDuration = Date().timeIntervalSince(start)
            }
        }
    }

    /// 启动采点定时器
    private func startSamplingTimer() {
        samplingTimer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleCurrentLocation()
            }
        }
    }

    /// 停止计时器
    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        samplingTimer?.invalidate()
        samplingTimer = nil
    }

    /// 采集当前位置
    private func sampleCurrentLocation() {
        guard isExploring else { return }

        guard let coordinate = locationManager.userLocation else {
            print("🔍 [探索] 当前位置为空，跳过采点")
            return
        }

        // 创建 CLLocation
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let now = Date()

        // 位置过滤
        if !validateLocation(location, timestamp: now) {
            return
        }

        // 计算与上一个有效点的距离
        var distanceIncrement: Double = 0
        if let last = lastValidLocation {
            distanceIncrement = location.distance(from: last)
        }

        // 记录轨迹点
        let trackPoint = ExplorationTrackPoint(
            coordinate: coordinate,
            timestamp: now,
            accuracy: location.horizontalAccuracy
        )
        trackPoints.append(trackPoint)

        // 累加距离
        currentDistance += distanceIncrement

        // 更新最后位置
        lastValidLocation = location
        lastLocationTimestamp = now

        print("🔍 [探索] 采点 #\(trackPoints.count)，距离增加: \(String(format: "%.1f", distanceIncrement))m，总计: \(String(format: "%.1f", currentDistance))m")
    }

    /// 位置有效性验证
    private func validateLocation(_ location: CLLocation, timestamp: Date) -> Bool {
        // 1. 精度过滤（负值表示无效）
        if location.horizontalAccuracy > minAccuracy || location.horizontalAccuracy < 0 {
            print("🔍 [探索] 精度不足: \(location.horizontalAccuracy)m，跳过")
            return false
        }

        // 2. 时间间隔过滤
        if let lastTime = lastLocationTimestamp {
            let interval = timestamp.timeIntervalSince(lastTime)
            if interval < minTimeInterval {
                print("🔍 [探索] 时间间隔不足: \(interval)s，跳过")
                return false
            }
        }

        // 3. 跳变过滤
        if let lastLocation = lastValidLocation {
            let distance = location.distance(from: lastLocation)
            if distance > maxJumpDistance {
                print("🔍 [探索] 位置跳变过大: \(distance)m，跳过")
                return false
            }
        }

        return true
    }

    /// 保存探索记录到数据库
    private func saveExplorationSession(
        startTime: Date,
        endTime: Date,
        duration: Int,
        distance: Double,
        tier: RewardTier,
        itemsCount: Int
    ) async -> UUID? {
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("🔍 [探索] 未登录，无法保存探索记录")
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let sessionData = InsertExplorationSession(
            userId: userId.uuidString,
            startedAt: formatter.string(from: startTime),
            endedAt: formatter.string(from: endTime),
            durationSeconds: duration,
            totalDistance: distance,
            pointCount: trackPoints.count,
            rewardTier: tier.rawValue,
            itemsCount: itemsCount
        )

        do {
            let response: [ExplorationSession] = try await supabase
                .from("exploration_sessions")
                .insert(sessionData)
                .select()
                .execute()
                .value

            print("🔍 [探索] 探索记录保存成功")
            return response.first?.id
        } catch {
            print("🔍 [探索] 保存探索记录失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 计算经验值
    private func calculateExperience(tier: RewardTier, distance: Double) -> Int {
        // 基础经验 = 距离 / 10
        let baseExp = Int(distance / 10)

        // 等级加成
        let tierMultiplier: Double
        switch tier {
        case .none: tierMultiplier = 0
        case .bronze: tierMultiplier = 1.0
        case .silver: tierMultiplier = 1.5
        case .gold: tierMultiplier = 2.0
        case .diamond: tierMultiplier = 3.0
        }

        return Int(Double(baseExp) * tierMultiplier)
    }
}

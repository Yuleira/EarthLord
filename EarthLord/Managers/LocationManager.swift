//
//  LocationManager.swift
//  EarthLord
//
//  Created by Claude on 02/01/2026.
//
//  GPS 定位管理器
//  负责请求定位权限、获取用户位置、处理授权状态变化
//

import Foundation
import CoreLocation
import Combine

/// GPS 定位管理器
/// 负责管理用户定位权限和实时位置更新
final class LocationManager: NSObject, ObservableObject {

    // MARK: - 单例
    static let shared = LocationManager()

    // MARK: - 发布属性

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位授权状态
    @Published var authorizationStatus: CLAuthorizationStatus

    /// 定位错误信息
    @Published var locationError: String?

    /// 是否正在定位
    @Published var isUpdatingLocation = false

    // MARK: - 路径追踪属性

    /// 是否正在追踪路径
    @Published var isTracking = false

    /// 路径坐标数组（存储原始 WGS-84 坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（触发 SwiftUI 更新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否闭合（用于 Day16 圈地判断）
    @Published var isPathClosed = false

    // MARK: - 私有属性

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（用于 Timer 采点）
    private var currentLocation: CLLocation?

    /// 路径采点定时器
    private var pathUpdateTimer: Timer?

    /// 最小采点距离（米）
    private let minDistanceForNewPoint: Double = 10.0

    /// 采点间隔（秒）
    private let pathUpdateInterval: TimeInterval = 2.0

    // MARK: - 计算属性

    /// 是否已授权定位
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// 是否被拒绝定位
    var isDenied: Bool {
        authorizationStatus == .denied
    }

    /// 是否尚未决定
    var isNotDetermined: Bool {
        authorizationStatus == .notDetermined
    }

    // MARK: - 初始化

    private override init() {
        // 获取当前授权状态
        self.authorizationStatus = locationManager.authorizationStatus

        super.init()

        // 配置定位管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 最高精度
        locationManager.distanceFilter = 10  // 移动 10 米才更新

        print("📍 [定位管理器] 初始化完成，当前授权状态: \(authorizationStatusDescription)")
    }

    // MARK: - 公共方法

    /// 请求定位权限
    func requestPermission() {
        print("📍 [定位管理器] 请求定位权限...")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        guard isAuthorized else {
            print("📍 [定位管理器] ⚠️ 未授权，无法开始定位")
            if isNotDetermined {
                requestPermission()
            }
            return
        }

        print("📍 [定位管理器] 开始更新位置...")
        isUpdatingLocation = true
        locationError = nil
        locationManager.startUpdatingLocation()
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        print("📍 [定位管理器] 停止更新位置")
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }

    /// 请求单次位置更新
    func requestLocation() {
        guard isAuthorized else {
            print("📍 [定位管理器] ⚠️ 未授权，无法请求位置")
            return
        }

        print("📍 [定位管理器] 请求单次位置...")
        locationManager.requestLocation()
    }

    // MARK: - 路径追踪方法

    /// 开始路径追踪
    func startPathTracking() {
        guard isAuthorized else {
            print("📍 [路径追踪] ⚠️ 未授权，无法开始追踪")
            return
        }

        print("📍 [路径追踪] 开始追踪...")

        // 清除旧路径
        clearPath()

        // 标记开始追踪
        isTracking = true

        // 确保正在定位
        if !isUpdatingLocation {
            startUpdatingLocation()
        }

        // 如果有当前位置，立即记录第一个点
        if let location = currentLocation {
            let coordinate = location.coordinate
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            print("📍 [路径追踪] 记录起始点: (\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude)))")
        }

        // 启动定时器，每 2 秒检查一次是否需要记录新点
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: pathUpdateInterval, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("📍 [路径追踪] 停止追踪，共记录 \(pathCoordinates.count) 个点")

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil

        // 标记停止追踪
        isTracking = false
    }

    /// 清除路径
    func clearPath() {
        print("📍 [路径追踪] 清除路径")
        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
    }

    /// 定时器回调：判断是否记录新点
    private func recordPathPoint() {
        guard isTracking else { return }
        guard let location = currentLocation else {
            print("📍 [路径追踪] ⚠️ 当前位置为空，跳过采点")
            return
        }

        let coordinate = location.coordinate

        // 如果是第一个点，直接记录
        if pathCoordinates.isEmpty {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            print("📍 [路径追踪] 记录第一个点: (\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude)))")
            return
        }

        // 计算与上一个点的距离
        guard let lastCoordinate = pathCoordinates.last else { return }
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastLocation)

        // 距离超过阈值才记录新点
        if distance >= minDistanceForNewPoint {
            pathCoordinates.append(coordinate)
            pathUpdateVersion += 1
            print("📍 [路径追踪] 记录新点 #\(pathCoordinates.count): 距离上点 \(String(format: "%.1f", distance))m")
        }
    }

    // MARK: - 私有方法

    /// 授权状态描述
    private var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "未决定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态变化回调
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus

        print("📍 [定位管理器] 授权状态变化: \(oldStatus.rawValue) -> \(authorizationStatus.rawValue) (\(authorizationStatusDescription))")

        // 如果刚刚授权，自动开始定位
        if isAuthorized && !isUpdatingLocation {
            startUpdatingLocation()
        }
    }

    /// 位置更新回调
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let coordinate = location.coordinate
        userLocation = coordinate
        locationError = nil

        // 保存当前位置（Timer 采点需要用）
        currentLocation = location

        print("📍 [定位管理器] 位置更新: (\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude)))")
    }

    /// 定位失败回调
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [定位管理器] ❌ 定位失败: \(error.localizedDescription)")

        // 处理不同的错误类型
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = "定位权限被拒绝，请在设置中开启"
            case .locationUnknown:
                locationError = "无法获取位置，请稍后重试"
            case .network:
                locationError = "网络错误，请检查网络连接"
            default:
                locationError = "定位失败: \(error.localizedDescription)"
            }
        } else {
            locationError = "定位失败: \(error.localizedDescription)"
        }
    }
}

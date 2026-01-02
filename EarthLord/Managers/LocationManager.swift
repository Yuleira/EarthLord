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

    // MARK: - 私有属性

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

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

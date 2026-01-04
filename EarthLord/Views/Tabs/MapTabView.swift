//
//  MapTabView.swift
//  EarthLord
//
//  Created by Yu Lei on 24/12/2025.
//
//  地图页面
//  显示末世风格地图、用户位置、定位权限处理
//

import SwiftUI
import CoreLocation

/// 地图页面主视图
struct MapTabView: View {

    // MARK: - 状态属性

    /// 定位管理器
    @ObservedObject private var locationManager = LocationManager.shared

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位
    @State private var hasLocatedUser = false

    var body: some View {
        ZStack {
            // 背景色
            ApocalypseTheme.background
                .ignoresSafeArea()

            // 根据授权状态显示不同内容
            if locationManager.isDenied {
                // 权限被拒绝：显示提示卡片
                LocationDeniedView()
            } else {
                // 已授权或未决定：显示地图
                mapContent
            }
        }
        .onAppear {
            handleOnAppear()
        }
    }

    // MARK: - 子视图

    /// 地图内容视图
    private var mapContent: some View {
        ZStack {
            // 末世风格地图
            MapViewRepresentable(
                userLocation: $userLocation,
                hasLocatedUser: $hasLocatedUser,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                isTracking: locationManager.isTracking,
                showsUserLocation: true
            )
            .ignoresSafeArea()

            // 右下角控制按钮
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        // 定位按钮
                        locateButton

                        // 圈地按钮
                        trackingButton
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)  // 避开 TabBar
                }
            }

            // 加载指示器（首次定位时显示）
            if !hasLocatedUser && locationManager.isAuthorized {
                loadingOverlay
            }
        }
    }

    /// 圈地按钮
    private var trackingButton: some View {
        Button {
            toggleTracking()
        } label: {
            HStack(spacing: 8) {
                // 图标
                Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                    .font(.system(size: 16, weight: .semibold))

                // 文字
                if locationManager.isTracking {
                    Text("停止圈地".localized)
                        .font(.system(size: 14, weight: .semibold))

                    // 显示当前点数
                    Text("(\(locationManager.pathCoordinates.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("开始圈地".localized)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(locationManager.isTracking ? Color.red : ApocalypseTheme.primary)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .disabled(!locationManager.isAuthorized)
        .opacity(locationManager.isAuthorized ? 1.0 : 0.5)
    }

    /// 定位按钮
    private var locateButton: some View {
        Button {
            centerToUserLocation()
        } label: {
            ZStack {
                // 背景圆形
                Circle()
                    .fill(ApocalypseTheme.cardBackground.opacity(0.9))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // 定位图标
                Image(systemName: locationIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(locationIconColor)
            }
        }
        .disabled(!locationManager.isAuthorized)
    }

    /// 加载中覆盖层
    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                .scaleEffect(1.5)

            Text("正在定位...".localized)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ApocalypseTheme.cardBackground.opacity(0.95))
        )
    }

    // MARK: - 计算属性

    /// 定位按钮图标
    private var locationIcon: String {
        if !locationManager.isAuthorized {
            return "location.slash"
        } else if hasLocatedUser {
            return "location.fill"
        } else {
            return "location"
        }
    }

    /// 定位按钮图标颜色
    private var locationIconColor: Color {
        if !locationManager.isAuthorized {
            return ApocalypseTheme.textMuted
        } else if hasLocatedUser {
            return ApocalypseTheme.primary
        } else {
            return ApocalypseTheme.textPrimary
        }
    }

    // MARK: - 方法

    /// 页面出现时处理
    private func handleOnAppear() {
        print("🗺️ [地图页面] 页面出现")

        // 检查授权状态
        if locationManager.isNotDetermined {
            // 首次使用，请求权限
            print("🗺️ [地图页面] 首次使用，请求定位权限")
            locationManager.requestPermission()
        } else if locationManager.isAuthorized {
            // 已授权，开始定位
            print("🗺️ [地图页面] 已授权，开始定位")
            locationManager.startUpdatingLocation()
        }
    }

    /// 居中到用户位置
    private func centerToUserLocation() {
        print("🗺️ [地图页面] 用户点击定位按钮")

        // 重置居中标志，触发地图重新居中
        hasLocatedUser = false

        // 确保正在定位
        if !locationManager.isUpdatingLocation {
            locationManager.startUpdatingLocation()
        }
    }

    /// 切换圈地状态
    private func toggleTracking() {
        if locationManager.isTracking {
            // 停止圈地
            print("🗺️ [地图页面] 用户停止圈地")
            locationManager.stopPathTracking()
        } else {
            // 开始圈地
            print("🗺️ [地图页面] 用户开始圈地")
            locationManager.startPathTracking()
        }
    }
}

// MARK: - 权限被拒绝视图

/// 定位权限被拒绝时显示的提示视图
struct LocationDeniedView: View {

    var body: some View {
        VStack(spacing: 24) {
            // 图标
            Image(systemName: "location.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.warning)

            // 标题
            Text("无法获取位置".localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 说明文字
            Text("《地球新主》需要获取您的位置才能显示您在末日世界中的坐标。请在设置中开启定位权限。".localized)
                .font(.subheadline)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // 前往设置按钮
            Button {
                openSettings()
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("前往设置".localized)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ApocalypseTheme.primary)
                )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ApocalypseTheme.cardBackground)
        )
        .padding(.horizontal, 24)
    }

    /// 打开系统设置
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 预览

#Preview {
    MapTabView()
}

//
//  MapViewRepresentable.swift
//  EarthLord
//
//  Created by Claude on 02/01/2026.
//
//  MKMapView 的 SwiftUI 包装器
//  实现末世风格地图显示、用户位置追踪、自动居中功能
//

import SwiftUI
import MapKit

/// 末世风格地图视图
/// 包装 MKMapView 以在 SwiftUI 中使用
struct MapViewRepresentable: UIViewRepresentable {

    // MARK: - 绑定属性

    /// 用户位置坐标（双向绑定）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位（防止重复居中）
    @Binding var hasLocatedUser: Bool

    /// 追踪路径坐标数组（WGS-84 原始坐标）
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号（触发轨迹更新）
    var pathUpdateVersion: Int

    /// 是否正在追踪
    var isTracking: Bool

    /// 是否显示用户位置
    var showsUserLocation: Bool = true

    // MARK: - UIViewRepresentable

    /// 创建 MKMapView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // 配置地图类型：卫星图 + 道路标签（末世废土风格）
        mapView.mapType = .hybrid

        // 隐藏所有 POI 标签（商店、餐厅等）
        mapView.pointOfInterestFilter = .excludingAll

        // 隐藏 3D 建筑
        mapView.showsBuildings = false

        // 显示用户位置蓝点
        mapView.showsUserLocation = showsUserLocation

        // 允许用户交互
        mapView.isZoomEnabled = true      // 允许缩放
        mapView.isScrollEnabled = true    // 允许拖动
        mapView.isRotateEnabled = true    // 允许旋转
        mapView.isPitchEnabled = true     // 允许倾斜

        // 显示比例尺
        mapView.showsScale = true

        // 显示指南针
        mapView.showsCompass = true

        // 设置代理（关键！否则 didUpdate userLocation 不会被调用）
        mapView.delegate = context.coordinator

        // 应用末世滤镜效果
        applyApocalypseFilter(to: mapView)

        print("🗺️ [地图视图] MKMapView 创建完成")

        return mapView
    }

    /// 更新 MKMapView（SwiftUI 状态变化时调用）
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 更新轨迹显示
        updateTrackingPath(on: mapView, context: context)
    }

    /// 更新轨迹路径
    private func updateTrackingPath(on mapView: MKMapView, context: Context) {
        // 移除旧的轨迹覆盖层
        let existingOverlays = mapView.overlays.filter { $0 is MKPolyline }
        mapView.removeOverlays(existingOverlays)

        // 如果没有路径点，不绘制
        guard trackingPath.count >= 2 else { return }

        // 坐标转换：WGS-84 → GCJ-02（解决中国地区偏移问题）
        let convertedCoordinates = CoordinateConverter.wgs84ToGcj02(trackingPath)

        // 创建轨迹线
        let polyline = MKPolyline(coordinates: convertedCoordinates, count: convertedCoordinates.count)

        // 添加到地图
        mapView.addOverlay(polyline)

        print("🗺️ [地图视图] 轨迹已更新，共 \(trackingPath.count) 个点")
    }

    /// 创建 Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - 私有方法

    /// 应用末世滤镜效果
    /// - 降低饱和度：让地图看起来更荒凉
    /// - 添加棕褐色调：营造废土泛黄效果
    private func applyApocalypseFilter(to mapView: MKMapView) {
        // 色调控制滤镜
        guard let colorControls = CIFilter(name: "CIColorControls") else {
            print("🗺️ [地图视图] ⚠️ 无法创建 CIColorControls 滤镜")
            return
        }

        // 设置滤镜参数
        colorControls.setValue(-0.15, forKey: kCIInputBrightnessKey)  // 稍微变暗
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)    // 降低饱和度到 50%

        // 棕褐色调滤镜（废土泛黄效果）
        guard let sepiaFilter = CIFilter(name: "CISepiaTone") else {
            print("🗺️ [地图视图] ⚠️ 无法创建 CISepiaTone 滤镜")
            return
        }

        sepiaFilter.setValue(0.65, forKey: kCIInputIntensityKey)  // 棕褐色强度

        // 应用滤镜到地图图层
        mapView.layer.filters = [colorControls, sepiaFilter]

        print("🗺️ [地图视图] 末世滤镜已应用")
    }

    // MARK: - Coordinator

    /// Coordinator 类
    /// 作为 MKMapView 的代理，处理地图事件
    class Coordinator: NSObject, MKMapViewDelegate {

        /// 父视图引用
        var parent: MapViewRepresentable

        /// 是否已完成首次居中（防止重复居中）
        private var hasInitialCentered = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - MKMapViewDelegate

        /// 用户位置更新回调（关键方法！）
        /// 当 MapKit 获取到用户位置时调用
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取位置坐标
            guard let location = userLocation.location else {
                print("🗺️ [地图代理] ⚠️ 用户位置为空")
                return
            }

            let coordinate = location.coordinate

            // 更新绑定的位置（在主线程）
            DispatchQueue.main.async {
                self.parent.userLocation = coordinate
            }

            print("🗺️ [地图代理] 用户位置更新: (\(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude)))")

            // 首次获得位置时，自动居中地图
            guard !hasInitialCentered else {
                // 已经居中过，不再自动移动（允许用户自由拖动）
                return
            }

            print("🗺️ [地图代理] 首次定位，自动居中地图...")

            // 创建居中区域（约 1 公里范围）
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )

            // 平滑居中地图（带动画）
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true

            // 更新外部状态（在主线程）
            DispatchQueue.main.async {
                self.parent.hasLocatedUser = true
            }

            print("🗺️ [地图代理] ✅ 地图已居中到用户位置")
        }

        /// 地图区域变化回调
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let center = mapView.centerCoordinate
            print("🗺️ [地图代理] 地图区域变化: (\(String(format: "%.4f", center.latitude)), \(String(format: "%.4f", center.longitude)))")
        }

        /// 地图加载完成回调
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("🗺️ [地图代理] 地图瓦片加载完成")
        }

        /// 地图加载失败回调
        func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
            print("🗺️ [地图代理] ❌ 地图加载失败: \(error.localizedDescription)")
        }

        /// 用户位置追踪失败回调
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
            print("🗺️ [地图代理] ❌ 定位失败: \(error.localizedDescription)")
        }

        /// 轨迹渲染器（关键！没有这个方法轨迹不会显示）
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.cyan  // 青色轨迹
                renderer.lineWidth = 5               // 线宽 5pt
                renderer.lineCap = .round            // 圆头
                renderer.lineJoin = .round           // 圆角连接
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - 预览

#Preview {
    MapViewRepresentable(
        userLocation: .constant(nil),
        hasLocatedUser: .constant(false),
        trackingPath: .constant([]),
        pathUpdateVersion: 0,
        isTracking: false
    )
}

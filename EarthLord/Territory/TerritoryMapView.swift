//
//  TerritoryMapView.swift
//  EarthLord
//
//  领地地图视图（UIKit MKMapView 包装）
//  渲染领地多边形和建筑标注
//  ⚠️ 关键：数据库坐标已是 GCJ-02，直接使用，不要二次转换！
//
//  Tactical Aurora Theme: Neon green boundary, hex building bases, pulse glow
//

import SwiftUI
import MapKit

struct TerritoryMapView: UIViewRepresentable {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let buildings: [PlayerBuilding]
    let buildingTemplates: [String: BuildingTemplate]

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 清除旧的覆盖层和标注
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        // 1. 添加领地多边形
        if territoryCoordinates.count >= 3 {
            let polygon = MKPolygon(coordinates: territoryCoordinates, count: territoryCoordinates.count)
            mapView.addOverlay(polygon)

            // 设置地图区域以显示整个多边形
            let rect = polygon.boundingMapRect
            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 200, right: 50)
            mapView.setVisibleMapRect(rect, edgePadding: edgePadding, animated: false)
        }

        // 2. 添加建筑标注
        for building in buildings {
            // ⚠️ 重要：building.locationLat/Lon 已经是 GCJ-02 坐标
            // 直接使用，不要调用 CoordinateConverter！
            guard let coordinate = building.coordinate else { continue }

            let annotation = BuildingAnnotation(
                coordinate: coordinate,
                building: building,
                template: buildingTemplates[building.templateId]
            )
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {

        // 渲染多边形覆盖层 — Tactical Aurora 霓虹绿边界
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                // Neon Green 边界 0.8 opacity, 3pt stroke
                renderer.strokeColor = UIColor(ApocalypseTheme.neonGreen).withAlphaComponent(0.8)
                renderer.lineWidth = 3
                // 轻绿渐变填充
                renderer.fillColor = UIColor(ApocalypseTheme.neonGreen).withAlphaComponent(0.08)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // 渲染建筑标注 — 自定义六角底座 + 辉光
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let buildingAnnotation = annotation as? BuildingAnnotation else {
                return nil
            }

            let identifier = "TacticalBuildingAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // 生成六角底座 + 图标的合成图像
            let isActive = buildingAnnotation.building.status == .active
            let template = buildingAnnotation.template
            let categoryColor = categoryUIColor(for: template)
            let iconName = template?.icon ?? "building.2.fill"

            let size = CGSize(width: 52, height: 52)
            let renderer = UIGraphicsImageRenderer(size: size)

            let compositeImage = renderer.image { ctx in
                let context = ctx.cgContext
                let rect = CGRect(origin: .zero, size: size)
                let insetRect = rect.insetBy(dx: 4, dy: 4)

                // 外辉光（Active 建筑）
                if isActive {
                    let glowColor = UIColor(ApocalypseTheme.auroraGlow).withAlphaComponent(0.4)
                    context.setShadow(offset: .zero, blur: 8, color: glowColor.cgColor)
                }

                // 六角形底座
                let hexPath = hexagonPath(in: insetRect)
                context.addPath(hexPath)
                context.setFillColor(categoryColor.withAlphaComponent(0.25).cgColor)
                context.fillPath()

                // 六角形边框
                context.addPath(hexPath)
                context.setStrokeColor(categoryColor.withAlphaComponent(0.7).cgColor)
                context.setLineWidth(1.5)
                context.strokePath()

                // 重置阴影再画图标
                context.setShadow(offset: .zero, blur: 0, color: nil)

                // SF Symbol 图标
                let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
                if let iconImage = UIImage(systemName: iconName, withConfiguration: iconConfig) {
                    let tinted = iconImage.withTintColor(categoryColor, renderingMode: .alwaysOriginal)
                    let iconSize = tinted.size
                    let iconOrigin = CGPoint(
                        x: (size.width - iconSize.width) / 2,
                        y: (size.height - iconSize.height) / 2
                    )
                    tinted.draw(at: iconOrigin)
                }
            }

            annotationView?.image = compositeImage
            annotationView?.centerOffset = CGPoint(x: 0, y: -size.height / 2)

            // Active 建筑的脉冲动画
            if isActive {
                addPulseAnimation(to: annotationView!)
            } else {
                annotationView?.layer.removeAllAnimations()
                annotationView?.alpha = 0.7
            }

            return annotationView
        }

        // MARK: - Helper: 六角形路径

        private func hexagonPath(in rect: CGRect) -> CGPath {
            let path = CGMutablePath()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2

            for i in 0..<6 {
                let angle = CGFloat(Double.pi / 3.0 * Double(i)) - CGFloat(Double.pi / 6.0)
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
            return path
        }

        // MARK: - Helper: 脉冲动画

        private func addPulseAnimation(to view: UIView) {
            // 避免重复添加
            guard view.layer.animation(forKey: "tacticalPulse") == nil else { return }

            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.7
            pulse.duration = 1.5
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.layer.add(pulse, forKey: "tacticalPulse")
        }

        // MARK: - Helper: 建筑标注颜色（统一使用主题橘红色）

        private func categoryUIColor(for template: BuildingTemplate?) -> UIColor {
            guard template != nil else { return .gray }
            return UIColor(ApocalypseTheme.primary)
        }
    }
}




// MARK: - Preview

#Preview {
    let sampleCoords = [
        CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        CLLocationCoordinate2D(latitude: 31.2314, longitude: 121.4747),
        CLLocationCoordinate2D(latitude: 31.2324, longitude: 121.4737),
        CLLocationCoordinate2D(latitude: 31.2314, longitude: 121.4727)
    ]

    let sampleBuilding = PlayerBuilding(
        id: UUID(),
        userId: UUID(),
        territoryId: "test",
        templateId: "campfire",
        buildingName: "Campfire",
        status: .active,
        level: 1,
        locationLat: 31.2310,
        locationLon: 121.4740,
        buildStartedAt: Date().addingTimeInterval(-3600),
        buildCompletedAt: Date().addingTimeInterval(-3540)
    )

    let template = BuildingTemplate(
        id: UUID(),
        templateId: "campfire",
        name: "Campfire",
        category: .survival,
        tier: 1,
        description: "Test",
        icon: "flame.fill",
        requiredResources: [:],
        buildTimeSeconds: 60,
        maxPerTerritory: 3,
        maxLevel: 3
    )

    TerritoryMapView(
        territoryCoordinates: sampleCoords,
        buildings: [sampleBuilding],
        buildingTemplates: ["campfire": template]
    )
}

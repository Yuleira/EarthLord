//
//  POIDetailView.swift
//  EarthLord
//
//  Created by Claude on 09/01/2026.
//
//  POI 详情页面
//  显示 POI 的详细信息，支持搜寻、标记等操作
//

import SwiftUI

/// POI 详情页面
struct POIDetailView: View {

    // MARK: - 参数

    /// 当前 POI
    let poi: ExplorationPOI

    // MARK: - 状态

    /// 是否正在搜寻
    @State private var isSearching = false

    /// POI 状态（可变）
    @State private var poiStatus: POIStatus

    /// 环境变量：dismiss
    @Environment(\.dismiss) private var dismiss

    // MARK: - 常量

    /// 模拟距离（米）
    private let mockDistance: Double = 350

    // MARK: - 初始化

    init(poi: ExplorationPOI) {
        self.poi = poi
        self._poiStatus = State(initialValue: poi.status)
    }

    // MARK: - 计算属性

    /// 是否可以搜寻
    private var canSearch: Bool {
        poiStatus != .looted && poiStatus != .undiscovered
    }

    /// 危险等级颜色
    private var dangerColor: Color {
        switch poiStatus {
        case .dangerous:
            return ApocalypseTheme.danger
        case .looted:
            return ApocalypseTheme.textMuted
        default:
            return ApocalypseTheme.success
        }
    }

    /// 危险等级文本
    private var dangerText: String {
        switch poiStatus {
        case .dangerous:
            return "危险"
        case .looted:
            return "已搜空"
        case .undiscovered:
            return "未知"
        default:
            return "安全"
        }
    }

    // MARK: - 视图

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 顶部图片区域
                    topImageArea

                    // 信息区域
                    infoSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // 操作按钮
                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        handleShare()
                    } label: {
                        Label("分享位置", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        handleReport()
                    } label: {
                        Label("举报错误", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - 顶部图片区域

    /// 顶部图片区域（约 1/3 屏幕高度）
    private var topImageArea: some View {
        let (icon, color) = iconAndColor(for: poi.type)

        return GeometryReader { geometry in
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        color.opacity(0.8),
                        color.opacity(0.4),
                        ApocalypseTheme.background
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 大图标
                VStack(spacing: 16) {
                    // 图标容器
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: icon)
                            .font(.system(size: 80, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    // 名称和类型
                    VStack(spacing: 6) {
                        Text(poi.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text(poi.type.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
        }
        .frame(height: 280)
    }

    // MARK: - 信息区域

    /// 信息区域
    private var infoSection: some View {
        VStack(spacing: 12) {
            // 第一行：距离 + 物资状态
            HStack(spacing: 12) {
                infoCard(
                    icon: "location.fill",
                    title: "距离",
                    value: String(format: "%.0fm", mockDistance),
                    color: ApocalypseTheme.info
                )

                infoCard(
                    icon: "cube.box.fill",
                    title: "物资",
                    value: lootStatusText,
                    color: lootStatusColor
                )
            }

            // 第二行：危险等级 + 数据来源
            HStack(spacing: 12) {
                infoCard(
                    icon: "exclamationmark.shield.fill",
                    title: "危险等级",
                    value: dangerText,
                    color: dangerColor
                )

                infoCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "数据来源",
                    value: "众包数据",
                    color: ApocalypseTheme.primary
                )
            }

            // 第三行：描述（如有）
            if !poi.description.isEmpty {
                descriptionCard(poi.description)
            }
        }
    }

    /// 物资状态文本
    private var lootStatusText: String {
        switch poiStatus {
        case .hasLoot:
            return "有物资"
        case .looted:
            return "已搜空"
        case .discovered:
            return "未知"
        case .undiscovered:
            return "未知"
        case .dangerous:
            return "危险区"
        }
    }

    /// 物资状态颜色
    private var lootStatusColor: Color {
        switch poiStatus {
        case .hasLoot:
            return ApocalypseTheme.success
        case .looted:
            return ApocalypseTheme.textMuted
        case .dangerous:
            return ApocalypseTheme.danger
        default:
            return ApocalypseTheme.warning
        }
    }

    /// 单个信息卡片
    private func infoCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // 文本
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(ApocalypseTheme.textMuted)

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ApocalypseTheme.cardBackground)
        )
    }

    /// 描述卡片
    private func descriptionCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.textMuted)

                Text("描述")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ApocalypseTheme.cardBackground)
        )
    }

    // MARK: - 操作按钮

    /// 操作按钮区域
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 主按钮：搜寻此 POI
            Button {
                handleSearch()
            } label: {
                HStack(spacing: 10) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Text(isSearching ? "搜寻中..." : "搜寻此POI")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canSearch ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                )
            }
            .disabled(!canSearch || isSearching)

            // 辅助按钮行
            HStack(spacing: 12) {
                // 标记已发现
                secondaryButton(
                    title: "标记已发现",
                    icon: "eye.fill",
                    isActive: poiStatus != .undiscovered
                ) {
                    handleMarkDiscovered()
                }

                // 标记无物资
                secondaryButton(
                    title: "标记无物资",
                    icon: "xmark.bin.fill",
                    isActive: poiStatus == .looted
                ) {
                    handleMarkLooted()
                }
            }
        }
    }

    /// 辅助按钮
    private func secondaryButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isActive ? ApocalypseTheme.primary : ApocalypseTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? ApocalypseTheme.primary : ApocalypseTheme.textMuted.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - 辅助方法

    /// 根据 POI 类型返回图标和颜色
    private func iconAndColor(for type: POIType) -> (String, Color) {
        switch type {
        case .hospital:
            return ("cross.case.fill", .red)
        case .supermarket:
            return ("cart.fill", .green)
        case .factory:
            return ("building.2.fill", .gray)
        case .pharmacy:
            return ("pills.fill", .purple)
        case .gasStation:
            return ("fuelpump.fill", .orange)
        case .warehouse:
            return ("shippingbox.fill", .brown)
        case .residence:
            return ("house.fill", .blue)
        case .office:
            return ("building.fill", .cyan)
        case .school:
            return ("book.fill", .yellow)
        case .police:
            return ("shield.fill", .indigo)
        }
    }

    // MARK: - 操作方法

    /// 处理搜寻
    private func handleSearch() {
        guard canSearch else { return }

        isSearching = true
        print("开始搜寻 POI: \(poi.name)")

        // 模拟搜寻过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSearching = false
            // TODO: 跳转到搜寻结果页面
            print("搜寻完成: \(poi.name)")
        }
    }

    /// 标记已发现
    private func handleMarkDiscovered() {
        withAnimation {
            if poiStatus == .undiscovered {
                poiStatus = .discovered
            }
        }
        print("标记已发现: \(poi.name)")
    }

    /// 标记无物资
    private func handleMarkLooted() {
        withAnimation {
            poiStatus = .looted
        }
        print("标记无物资: \(poi.name)")
    }

    /// 分享位置
    private func handleShare() {
        print("分享 POI: \(poi.name)")
        // TODO: 实现分享功能
    }

    /// 举报错误
    private func handleReport() {
        print("举报 POI: \(poi.name)")
        // TODO: 实现举报功能
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        POIDetailView(poi: MockExplorationData.pois[0])
    }
}

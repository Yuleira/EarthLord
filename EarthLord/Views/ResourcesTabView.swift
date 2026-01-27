//
//  ResourcesTabView.swift
//  EarthLord
//
//  Created by Claude on 09/01/2026.
//
//  资源模块主入口页面
//  包含POI、背包、已购、领地、交易五个分段
//

import SwiftUI

/// 资源分段类型
enum ResourceSegment: Int, CaseIterable {
    case poi = 0
    case backpack
    case purchased
    case territory
    case trade

    var title: LocalizedStringKey {
        switch self {
        case .poi:
            return "POI"
        case .backpack:
            return "segment_backpack"
        case .purchased:
            return "segment_purchased"
        case .territory:
            return "segment_territory"
        case .trade:
            return "segment_trade"
        }
    }
}

/// 资源模块主入口页面
struct ResourcesTabView: View {

    // MARK: - 状态

    /// 当前选中的分段
    @State private var selectedSegment: ResourceSegment = .poi

    /// 交易开关状态（假数据）
    @State private var isTradeEnabled = false

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 分段选择器
                    segmentPicker
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    // 内容区域
                    contentView
                }
            }
            .navigationTitle(LocalizedString.tabResources)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    tradeToggle
                }
            }
        }
    }

    // MARK: - 分段选择器

    /// 分段选择器
    private var segmentPicker: some View {
        Picker("resource_segment_picker", selection: $selectedSegment) {
            ForEach(ResourceSegment.allCases, id: \.self) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 交易开关

    /// 交易开关
    private var tradeToggle: some View {
        HStack(spacing: 6) {
            Text(LocalizedString.segmentTrade)
                .font(.system(size: 13))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Toggle("", isOn: $isTradeEnabled)
                .labelsHidden()
                .scaleEffect(0.8)
                .tint(ApocalypseTheme.primary)
        }
    }

    // MARK: - 内容区域

    /// 根据选中分段显示对应内容
    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .poi:
            placeholderView(title: "segment_poi_list", icon: "mappin.circle.fill")

        case .backpack:
            BackpackView()

        case .purchased:
            placeholderView(title: "segment_purchased", icon: "cart.fill")

        case .territory:
            placeholderView(title: "segment_territory_resources", icon: "flag.fill")

        case .trade:
            TradeTabView()
        }
    }

    /// 占位视图
    private func placeholderView(title: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(ApocalypseTheme.textMuted)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text(LocalizedString.featureInDevelopment)
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textMuted)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 预览

#Preview {
    ResourcesTabView()
}

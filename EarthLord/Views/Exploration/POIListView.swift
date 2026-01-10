//
//  POIListView.swift
//  EarthLord
//
//  POI列表页面 - 显示附近的兴趣点
//

import SwiftUI

/// POI数据模型
struct POI: Identifiable, Codable {
    let id: String
    let poi_type: String
    let name: String
    let latitude: Double
    let longitude: Double
}

/// POI列表视图
struct POIListView: View {

    // MARK: - 状态

    @State private var pois: [POI] = []
    @State private var selectedType: String? = nil
    @State private var isLoading = false

    // POI类型列表
    private let poiTypes = ["全部", "商店", "医院", "加油站", "餐厅", "公园"]

    // MARK: - 计算属性

    /// 过滤后的POI列表
    private var filteredPOIs: [POI] {
        guard let type = selectedType, type != "全部" else {
            return pois
        }
        return pois.filter { $0.poi_type == type }
    }

    /// 是否显示空状态
    private var showEmptyState: Bool {
        !isLoading && pois.isEmpty
    }

    /// 是否显示筛选无结果状态
    private var showNoFilterResults: Bool {
        !isLoading && !pois.isEmpty && filteredPOIs.isEmpty
    }

    // MARK: - 视图

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 筛选器
                if !pois.isEmpty {
                    filterPicker
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                // 内容区域
                contentView
            }
        }
        .navigationTitle("附近POI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: searchNearbyPOIs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }
        }
        .onAppear {
            loadMockData()
        }
    }

    // MARK: - 筛选器

    /// POI类型筛选器
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(poiTypes, id: \.self) { type in
                    filterButton(type: type)
                }
            }
        }
    }

    private func filterButton(type: String) -> some View {
        Button(action: {
            selectedType = (type == "全部") ? nil : type
        }) {
            Text(type)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected(type) ? .white : ApocalypseTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected(type) ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
                .cornerRadius(20)
        }
    }

    private func isSelected(_ type: String) -> Bool {
        if type == "全部" {
            return selectedType == nil
        }
        return selectedType == type
    }

    // MARK: - 内容区域

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if showEmptyState {
            emptyStateView
        } else if showNoFilterResults {
            noFilterResultsView
        } else {
            poiListView
        }
    }

    /// 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ApocalypseTheme.primary)

            Text("正在搜索附近POI...")
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 空状态视图
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "mappin.slash.circle",
            title: "附近暂无兴趣点",
            subtitle: "点击搜索按钮发现周围的废墟",
            buttonTitle: nil,
            action: nil
        )
    }

    /// 筛选无结果视图
    private var noFilterResultsView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "没有找到该类型的地点",
            subtitle: "试试其他类型或清除筛选条件",
            buttonTitle: nil,
            action: nil
        )
    }

    /// POI列表
    private var poiListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredPOIs) { poi in
                    POIRowView(poi: poi)
                }
            }
            .padding(16)
        }
    }

    // MARK: - 业务逻辑

    /// 搜索附近POI
    private func searchNearbyPOIs() {
        isLoading = true

        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            loadMockData()
            isLoading = false
        }
    }

    /// 加载模拟数据
    private func loadMockData() {
        pois = []
        // 可以在这里加载一些模拟数据进行测试
        // pois = MockPOIData.samples
    }
}

// MARK: - POI行视图

struct POIRowView: View {
    let poi: POI

    var body: some View {
        HStack(spacing: 12) {
            // POI图标
            Image(systemName: iconForType(poi.poi_type))
                .font(.system(size: 24))
                .foregroundColor(ApocalypseTheme.primary)
                .frame(width: 48, height: 48)
                .background(ApocalypseTheme.cardBackground)
                .cornerRadius(12)

            // POI信息
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text(poi.poi_type)
                    .font(.system(size: 13))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 导航箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textMuted)
        }
        .padding(12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "商店": return "cart.fill"
        case "医院": return "cross.case.fill"
        case "加油站": return "fuelpump.fill"
        case "餐厅": return "fork.knife"
        case "公园": return "tree.fill"
        default: return "mappin.circle.fill"
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        POIListView()
    }
}

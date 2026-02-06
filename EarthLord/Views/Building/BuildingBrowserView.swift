//
//  BuildingBrowserView.swift
//  EarthLord
//
//  建筑浏览器
//  水平胶囊分类筛选 + 居中简洁网格卡片
//

import SwiftUI

struct BuildingBrowserView: View {
    @StateObject private var buildingManager = BuildingManager.shared
    @StateObject private var inventoryManager = InventoryManager.shared
    @Environment(\.dismiss) private var dismiss

    /// 当前领地 ID
    let territoryId: String

    /// 选中的建筑模板，用于触发下一步建造流程
    let onStartConstruction: (BuildingTemplate) -> Void

    // MARK: - State

    /// 当前选中的分类（nil = 全部）
    @State private var selectedCategory: BuildingCategory? = nil

    /// 筛选后的建筑列表
    private var filteredTemplates: [BuildingTemplate] {
        if let category = selectedCategory {
            return buildingManager.buildingTemplates.filter { $0.category == category }
        }
        return buildingManager.buildingTemplates
    }

    /// 当前资源汇总
    private var playerResources: [String: Int] {
        inventoryManager.getResourceSummary()
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                ApocalypseTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 1. 水平胶囊分类选择器
                    categorySelector
                        .padding(.top, 12)
                        .padding(.bottom, 12)

                    // 2. 建筑网格
                    if filteredTemplates.isEmpty {
                        emptyStateView
                    } else {
                        buildingGrid
                    }
                }
            }
            .navigationTitle(LocalizedString.buildingBrowserTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }
            .onAppear {
                Task {
                    await buildingManager.loadTemplates()
                    await buildingManager.fetchPlayerBuildings(territoryId: territoryId)
                    await inventoryManager.loadItems()
                }
            }
        }
    }

    // MARK: - Subviews

    /// 水平胶囊分类选择器
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "全部" 按钮
                CategoryButton(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = nil
                        }
                    }
                )

                // 各分类按钮
                ForEach(BuildingCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    /// 建筑网格
    private var buildingGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(filteredTemplates) { template in
                    let currentCount = buildingManager.getBuildingCount(
                        templateId: template.templateId,
                        territoryId: territoryId
                    )
                    let availability = availabilityInfo(for: template)

                    BuildingCard(
                        template: template,
                        isLocked: false,
                        isDisabled: !availability.isAvailable,
                        statusResource: availability.statusResource,
                        builtCurrent: currentCount,
                        builtMax: template.maxPerTerritory,
                        onTap: {
                            handleBuildingSelection(template)
                        }
                    )
                }

                #if DEBUG
                debugAddResourceCard
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(ApocalypseTheme.textMuted)

            Text(LocalizedString.buildingBrowserEmptyTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 调试资源按钮
    #if DEBUG
    private var debugAddResourceCard: some View {
        Button {
            Task {
                await InventoryManager.shared.addTestResources()
                await inventoryManager.loadItems()
            }
        } label: {
            VStack {
                Image(systemName: "hammer.fill")
                    .font(.title)
                Text(LocalizedString.debugAddMaterials)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
        }
    }
    #endif

    // MARK: - Helper Methods

    private func handleBuildingSelection(_ template: BuildingTemplate) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onStartConstruction(template)
        }
    }

    private func availabilityInfo(for template: BuildingTemplate) -> (isAvailable: Bool, statusResource: LocalizedStringResource?) {
        let validation = buildingManager.canBuild(
            template: template,
            territoryId: territoryId,
            playerResources: playerResources
        )

        if validation.canBuild {
            return (true, nil)
        }

        guard let error = validation.error else {
            return (false, nil)
        }

        switch error {
        case .insufficientResources:
            return (false, LocalizedString.insufficientResources)
        case .maxBuildingsReached:
            return (false, LocalizedString.maxBuildingsReached)
        default:
            return (false, LocalizedString.commonError)
        }
    }
}

// MARK: - Preview

#Preview {
    BuildingBrowserView(
        territoryId: "debug-territory",
        onStartConstruction: { _ in }
    )
}

//
//  CategoryButton.swift
//  EarthLord
//
//  建筑分类选择按钮 — 水平胶囊药丸样式
//  支持 "全部" + 各分类的横向滚动选择
//

import SwiftUI

/// 分类胶囊按钮（用于 BuildingBrowserView 的横向分类栏）
struct CategoryButton: View {
    /// 分类（nil 表示"全部"）
    let category: BuildingCategory?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // 图标（"全部"无图标）
                if let category = category {
                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                }

                // 文字
                if let category = category {
                    Text(category.localizedName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(LocalizedString.filterAll)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? ApocalypseTheme.primary : ApocalypseTheme.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : ApocalypseTheme.textMuted.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            CategoryButton(category: nil, isSelected: true, action: {})
            CategoryButton(category: .survival, isSelected: false, action: {})
            CategoryButton(category: .storage, isSelected: false, action: {})
            CategoryButton(category: .production, isSelected: false, action: {})
            CategoryButton(category: .energy, isSelected: false, action: {})
        }
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 16)
    .background(ApocalypseTheme.background)
}

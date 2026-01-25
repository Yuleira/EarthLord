//
//  CategoryButton.swift
//  EarthLord
//
//  建筑分类选择按钮
//  支持选中状态和视觉反馈
//

import SwiftUI

struct CategoryButton: View {
    let category: BuildingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                
                Text(category.localizedName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : ApocalypseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.accentColor : ApocalypseTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? category.accentColor.opacity(0.6) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected ? category.accentColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            CategoryButton(
                category: .survival,
                isSelected: true,
                action: {}
            )
            
            CategoryButton(
                category: .storage,
                isSelected: false,
                action: {}
            )
        }
        
        HStack(spacing: 12) {
            CategoryButton(
                category: .production,
                isSelected: false,
                action: {}
            )
            
            CategoryButton(
                category: .energy,
                isSelected: false,
                action: {}
            )
        }
    }
    .padding()
    .background(ApocalypseTheme.background)
}

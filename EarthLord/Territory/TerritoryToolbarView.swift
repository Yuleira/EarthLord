//
//  TerritoryToolbarView.swift
//  EarthLord
//
//  领地工具栏（浮动顶部）
//  提供返回、建造、信息按钮
//

import SwiftUI

struct TerritoryToolbarView: View {
    let territoryName: LocalizedStringResource
    let onBack: () -> Void
    let onInfo: () -> Void

    var body: some View {
        HStack {
            // 返回按钮 - 小型圆形，半透明
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }

            Spacer()

            // 领地名称（中央）- 无背景，简洁显示
            Text(territoryName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Spacer()
            
            // 设置按钮 - 小型圆形，半透明
            Button(action: onInfo) {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ApocalypseTheme.background
            .ignoresSafeArea()

        VStack {
            TerritoryToolbarView(
                territoryName: LocalizedString.unnamedTerritory,
                onBack: {},
                onInfo: {}
            )
            
            Spacer()
        }
    }
}

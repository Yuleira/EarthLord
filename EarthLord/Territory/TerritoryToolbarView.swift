//
//  TerritoryToolbarView.swift
//  EarthLord
//
//  领地工具栏（浮动顶部）
//  返回按钮 + 领地名称（可点击重命名）
//

import SwiftUI

struct TerritoryToolbarView: View {
    let territoryName: String
    let onBack: () -> Void
    /// 点击标题触发重命名
    var onTitleTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            // 返回按钮
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

            // 领地名称（点击可重命名）
            Button {
                onTitleTap?()
            } label: {
                HStack(spacing: 4) {
                    Text(territoryName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ApocalypseTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
            }

            Spacer()

            // 占位：保持标题居中
            Color.clear
                .frame(width: 36, height: 36)
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
                territoryName: String(localized: "unnamed_territory"),
                onBack: {},
                onTitleTap: {}
            )

            Spacer()
        }
    }
}

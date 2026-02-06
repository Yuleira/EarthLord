//
//  BuildingCard.swift
//  EarthLord
//
//  建筑卡片组件 — 居中简洁风格
//  大圆形图标 + 名称 + 分类标签 + 等级 + 建造时间
//

import SwiftUI

struct BuildingCard: View {
    let template: BuildingTemplate
    let isLocked: Bool
    let isDisabled: Bool
    let statusResource: LocalizedStringResource?
    let builtCurrent: Int?
    let builtMax: Int?
    let onTap: () -> Void

    /// 格式化建造时间（秒 → 本地化可读格式，如 "1分钟"、"30秒"、"1分 30秒"）
    private var formattedBuildTime: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        formatter.calendar?.locale = LanguageManager.shared.currentLocale
        return formatter.string(from: TimeInterval(template.buildTimeSeconds)) ?? "\(template.buildTimeSeconds)s"
    }

    /// Tier 文字
    private var tierText: String {
        "T\(template.tier)"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // 大圆形图标
                ZStack {
                    Circle()
                        .fill(template.category.accentColor.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: template.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isLocked ? ApocalypseTheme.textMuted : template.category.accentColor)
                }
                .padding(.top, 4)

                // 建筑名称
                Text(template.localizedName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isLocked ? ApocalypseTheme.textMuted : ApocalypseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // 分类标签 + 等级
                HStack(spacing: 8) {
                    // 分类彩色标签
                    Text(template.category.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(template.category.accentColor)

                    // 等级灰色标签
                    Text(tierText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ApocalypseTheme.textMuted.opacity(0.15))
                        )
                }

                // 建造时间
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(ApocalypseTheme.textMuted)

                    Text(formattedBuildTime)
                        .font(.system(size: 12))
                        .foregroundColor(ApocalypseTheme.textMuted)
                }
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ApocalypseTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isLocked ? ApocalypseTheme.textMuted.opacity(0.15) : ApocalypseTheme.neonGreen.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .opacity((isLocked || isDisabled) ? 0.5 : 1.0)
            .overlay(
                Group {
                    if isLocked {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.5))
                            VStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                Text(LocalizedString.commonLocked)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// MARK: - Preview

#Preview {
    let sampleTemplate = BuildingTemplate(
        id: UUID(),
        templateId: "campfire",
        name: "building_name_campfire",
        category: .survival,
        tier: 1,
        description: "building_description_campfire",
        icon: "flame.fill",
        requiredResources: ["wood": 30, "stone": 20],
        buildTimeSeconds: 60,
        maxPerTerritory: 3,
        maxLevel: 3
    )

    LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
        spacing: 12
    ) {
        BuildingCard(
            template: sampleTemplate,
            isLocked: false,
            isDisabled: false,
            statusResource: nil,
            builtCurrent: 1,
            builtMax: 3,
            onTap: {}
        )

        BuildingCard(
            template: sampleTemplate,
            isLocked: true,
            isDisabled: true,
            statusResource: "common_locked",
            builtCurrent: nil,
            builtMax: nil,
            onTap: {}
        )
    }
    .padding()
    .background(ApocalypseTheme.background)
}

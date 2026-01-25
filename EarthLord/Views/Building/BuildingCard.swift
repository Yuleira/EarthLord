//
//  BuildingCard.swift
//  EarthLord
//
//  建筑卡片组件
//  显示建筑图标、名称、等级、成本预览
//

import SwiftUI

struct BuildingCard: View {
    let template: BuildingTemplate
    let isLocked: Bool
    let isDisabled: Bool
    /// Status pill (Insufficient Resources, Build Limit Reached, etc.); uses LocalizedString.insufficientResources when applicable.
    let statusResource: LocalizedStringResource?
    /// Built count: current built, max allowed. When both provided, shows Built current/max.
    let builtCurrent: Int?
    let builtMax: Int?
    let onTap: () -> Void
    
    /// 资源成本摘要（显示前3个资源）
    private var resourceSummary: String {
        let resources = template.requiredResources.prefix(3)
        return resources.map { "\(InventoryManager.shared.resourceDisplayName(for: $0.key)) ×\($0.value)" }
            .joined(separator: ", ")
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 卡片主体
                VStack(alignment: .leading, spacing: 12) {
                    // 顶部：图标 + 等级标签
                    HStack {
                        ZStack {
                            Circle()
                                .fill(template.category.accentColor.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: template.icon)
                                .font(.system(size: 24))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(isLocked ? ApocalypseTheme.textMuted : ApocalypseTheme.primary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: String(localized: LocalizedString.buildingTierFormat), template.tier))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isLocked ? ApocalypseTheme.textMuted : ApocalypseTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(ApocalypseTheme.cardBackground))
                    }
                    
                    Text(template.localizedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isLocked ? ApocalypseTheme.textMuted : ApocalypseTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(template.localizedDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isLocked ? ApocalypseTheme.textMuted : ApocalypseTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let cur = builtCurrent, let max = builtMax {
                        Text(String(format: String(localized: LocalizedString.builtFormat), cur, max))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 10))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(ApocalypseTheme.primary)
                        
                        Text(resourceSummary)
                            .font(.system(size: 11))
                            .foregroundColor(ApocalypseTheme.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    
                    HStack {
                        Label {
                            Text("\(template.buildTimeSeconds)s")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        } icon: {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                        .foregroundColor(ApocalypseTheme.textSecondary)
                        
                        Spacer()
                        
                        Label {
                            Text(String(format: String(localized: LocalizedString.buildingMaxLimitFormat), template.maxPerTerritory))
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        } icon: {
                            Image(systemName: "number.circle.fill")
                                .font(.system(size: 10))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(ApocalypseTheme.primary)
                        }
                        .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(ApocalypseTheme.cardBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isLocked ? ApocalypseTheme.textMuted.opacity(0.2) : template.category.accentColor.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .opacity((isLocked || isDisabled) ? 0.6 : 1.0)
                .overlay(
                    Group {
                        if isLocked {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.4))
                                VStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 24))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.white)
                                    Text(LocalizedString.commonLocked)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                )
                
                // 状态徽章（资源不足 / 已达上限）：使用 LocalizedString.insufficientResources 等
                if let res = statusResource {
                    HStack {
                        Spacer()
                        Text(res)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isDisabled ? ApocalypseTheme.danger : ApocalypseTheme.success))
                    }
                }
            }
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
    
    VStack(spacing: 16) {
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

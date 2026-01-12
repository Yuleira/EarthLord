import Foundation
import SwiftUI

// MARK: - 物品品质（影响物品状态/耐久度）

enum ItemQuality: String, Codable, CaseIterable {
    case pristine = "完美"
    case good = "良好"
    case worn = "陈旧"
    case damaged = "破损"
    case ruined = "报废"

    var color: Color {
        switch self {
        case .pristine: return .purple
        case .good: return .blue
        case .worn: return .green
        case .damaged: return .orange
        case .ruined: return .gray
        }
    }
}

// MARK: - 物品稀有度（决定掉落概率和价值）

/// 物品稀有度（独立于品质 ItemQuality）
/// - common: 普通物品，最常见
/// - rare: 稀有物品，有一定价值
/// - epic: 史诗物品，非常珍贵
enum ItemRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"

    /// 中文显示名称
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .rare: return "稀有"
        case .epic: return "史诗"
        }
    }

    /// 对应的显示颜色
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        }
    }

    /// 背景渐变色（用于卡片展示）
    var gradientColors: [Color] {
        switch self {
        case .common: return [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]
        case .rare: return [Color.blue.opacity(0.3), Color.cyan.opacity(0.1)]
        case .epic: return [Color.purple.opacity(0.4), Color.pink.opacity(0.2)]
        }
    }
}

// MARK: - 物品分类

enum ItemCategory: String, Codable, CaseIterable {
    case water = "水"
    case food = "食物"
    case medical = "药品"
    case material = "材料"
    case tool = "工具"
    case weapon = "武器"
    case other = "其他"
}

// MARK: - 物品定义

struct ItemDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ItemCategory
    let icon: String
    let rarity: ItemRarity

    /// 向后兼容的初始化器（默认稀有度为普通）
    init(id: String, name: String, description: String, category: ItemCategory, icon: String, rarity: ItemRarity = .common) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.icon = icon
        self.rarity = rarity
    }
}

struct CollectedItem: Identifiable, Codable {
    let id: UUID
    let definition: ItemDefinition
    let quality: ItemQuality
    let foundDate: Date
    var quantity: Int = 1 // 补上 quantity
    
    // 补上 itemId，让 View 能找到它
    var itemId: String {
        return definition.id
    }
    
    init(id: UUID = UUID(), definition: ItemDefinition, quality: ItemQuality, foundDate: Date = Date(), quantity: Int = 1) {
        self.id = id
        self.definition = definition
        self.quality = quality
        self.foundDate = foundDate
        self.quantity = quantity
    }
}

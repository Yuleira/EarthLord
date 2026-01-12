//
//  InventoryItem.swift
//  EarthLord
//
//  数据库物品模型（与 Supabase 表结构对应）
//

import Foundation

// MARK: - 数据库物品定义模型

/// 对应 item_definitions 表
struct DBItemDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let icon: String
    let rarity: String
    let baseValue: Int?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, icon, rarity
        case baseValue = "base_value"
        case isActive = "is_active"
    }

    /// 转换为 App 模型
    func toItemDefinition() -> ItemDefinition {
        ItemDefinition(
            id: id,
            name: name,
            description: description,
            category: ItemCategory(rawValue: category) ?? .other,
            icon: icon,
            rarity: ItemRarity(rawValue: rarity) ?? .common
        )
    }
}

// MARK: - 数据库背包物品模型

/// 对应 inventory_items 表
struct DBInventoryItem: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let itemDefinitionId: String
    let quality: String
    let quantity: Int
    let sourceType: String
    let sourceSessionId: UUID?
    let acquiredAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemDefinitionId = "item_definition_id"
        case quality
        case quantity
        case sourceType = "source_type"
        case sourceSessionId = "source_session_id"
        case acquiredAt = "acquired_at"
        case updatedAt = "updated_at"
    }

    /// 转换为 CollectedItem（需要提供物品定义）
    func toCollectedItem(definition: ItemDefinition) -> CollectedItem {
        CollectedItem(
            id: id,
            definition: definition,
            quality: ItemQuality(rawValue: quality) ?? .worn,
            foundDate: acquiredAt ?? Date(),
            quantity: quantity
        )
    }
}

// MARK: - 插入数据模型

/// 用于插入背包物品的数据结构
struct InsertInventoryItem: Codable {
    let userId: String
    let itemDefinitionId: String
    let quality: String
    let quantity: Int
    let sourceType: String
    let sourceSessionId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case itemDefinitionId = "item_definition_id"
        case quality
        case quantity
        case sourceType = "source_type"
        case sourceSessionId = "source_session_id"
    }
}

/// 用于插入探索会话的数据结构
struct InsertExplorationSession: Codable {
    let userId: String
    let startedAt: String
    let endedAt: String
    let durationSeconds: Int
    let totalDistance: Double
    let pointCount: Int
    let rewardTier: String
    let itemsCount: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case totalDistance = "total_distance"
        case pointCount = "point_count"
        case rewardTier = "reward_tier"
        case itemsCount = "items_count"
    }
}

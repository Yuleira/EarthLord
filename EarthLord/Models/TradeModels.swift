//
//  TradeModels.swift
//  EarthLord
//
//  交易系统数据模型
//  支持玩家之间的异步物品交易
//

import Foundation

// MARK: - 交易挂单状态

/// 交易挂单状态
enum TradeOfferStatus: String, Codable {
    case active = "active"           // 等待中，可被接受
    case completed = "completed"     // 已完成
    case cancelled = "cancelled"     // 已取消
    case expired = "expired"         // 已过期

    /// 本地化显示名称
    var localizedName: LocalizedStringResource {
        switch self {
        case .active:
            return "trade_status_active"
        case .completed:
            return "trade_status_completed"
        case .cancelled:
            return "trade_status_cancelled"
        case .expired:
            return "trade_status_expired"
        }
    }
}

// MARK: - 交易物品

/// 交易物品（用于 JSON 存储）
struct TradeItem: Codable, Identifiable {
    let itemId: String      // 物品定义ID（item_definition_id）
    let quantity: Int       // 数量

    var id: String { itemId }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case quantity
    }

    init(itemId: String, quantity: Int) {
        self.itemId = itemId
        self.quantity = quantity
    }
}

// MARK: - 交易挂单

/// 交易挂单模型
struct TradeOffer: Codable, Identifiable {
    let id: String                      // 挂单ID
    let ownerId: String                 // 发布者用户ID
    let ownerUsername: String?          // 发布者用户名（冗余，方便显示）
    let offeringItems: [TradeItem]      // 提供的物品列表
    let requestingItems: [TradeItem]    // 需要的物品列表
    let status: TradeOfferStatus        // 状态
    let message: String?                // 可选留言
    let createdAt: String               // 创建时间（ISO8601）
    let expiresAt: String               // 过期时间（ISO8601）
    let completedAt: String?            // 完成时间（可选）
    let completedByUserId: String?      // 接受者用户ID（可选）
    let completedByUsername: String?    // 接受者用户名（可选）

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case ownerUsername = "owner_username"
        case offeringItems = "offering_items"
        case requestingItems = "requesting_items"
        case status
        case message
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case completedAt = "completed_at"
        case completedByUserId = "completed_by_user_id"
        case completedByUsername = "completed_by_username"
    }

    /// 是否已过期（查询时动态判断）
    var isExpired: Bool {
        guard status == .active else { return false }
        return expiresDate < Date()
    }

    /// 过期时间（Date 对象）
    var expiresDate: Date {
        ISO8601DateFormatter().date(from: expiresAt) ?? Date()
    }

    /// 创建时间（Date 对象）
    var createdDate: Date {
        ISO8601DateFormatter().date(from: createdAt) ?? Date()
    }

    /// 完成时间（Date 对象，可选）
    var completedDate: Date? {
        guard let completedAt = completedAt else { return nil }
        return ISO8601DateFormatter().date(from: completedAt)
    }

    /// 格式化的过期时间显示
    var formattedExpiresAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: expiresDate)
    }

    /// 格式化的创建时间显示
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: createdDate)
    }
}

// MARK: - 交易历史

/// 交易历史记录
struct TradeHistory: Codable, Identifiable {
    let id: String                      // 历史记录ID
    let offerId: String?                // 关联的挂单ID（可选）
    let sellerId: String                // 卖家（发布者）ID
    let sellerUsername: String?         // 卖家用户名
    let buyerId: String                 // 买家（接受者）ID
    let buyerUsername: String?          // 买家用户名
    let itemsExchanged: ItemsExchanged  // 交换的物品详情
    let completedAt: String             // 完成时间（ISO8601）
    let sellerRating: Int?              // 卖家给买家的评分（1-5）
    let buyerRating: Int?               // 买家给卖家的评分（1-5）
    let sellerComment: String?          // 卖家评语
    let buyerComment: String?           // 买家评语

    enum CodingKeys: String, CodingKey {
        case id
        case offerId = "offer_id"
        case sellerId = "seller_id"
        case sellerUsername = "seller_username"
        case buyerId = "buyer_id"
        case buyerUsername = "buyer_username"
        case itemsExchanged = "items_exchanged"
        case completedAt = "completed_at"
        case sellerRating = "seller_rating"
        case buyerRating = "buyer_rating"
        case sellerComment = "seller_comment"
        case buyerComment = "buyer_comment"
    }

    /// 完成时间（Date 对象）
    var completedDate: Date {
        ISO8601DateFormatter().date(from: completedAt) ?? Date()
    }

    /// 格式化的完成时间显示
    var formattedCompletedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: completedDate)
    }
}

// MARK: - 交换物品详情

/// 交换的物品详情（用于交易历史）
struct ItemsExchanged: Codable {
    let offered: [TradeItem]    // 卖家提供的物品
    let requested: [TradeItem]  // 买家提供的物品
}

// MARK: - 创建挂单请求

/// 创建挂单请求参数
struct CreateTradeOfferRequest {
    let offeringItems: [TradeItem]      // 提供的物品列表
    let requestingItems: [TradeItem]    // 需要的物品列表
    let validityHours: Int              // 有效期（小时数，默认24）
    let message: String?                // 留言（可选）

    init(
        offeringItems: [TradeItem],
        requestingItems: [TradeItem],
        validityHours: Int = 24,
        message: String? = nil
    ) {
        self.offeringItems = offeringItems
        self.requestingItems = requestingItems
        self.validityHours = validityHours
        self.message = message
    }
}

// MARK: - 评价交易请求

/// 评价交易请求参数
struct RateTradeRequest {
    let tradeHistoryId: String  // 交易历史ID
    let rating: Int             // 评分（1-5）
    let comment: String?        // 评语（可选）

    init(tradeHistoryId: String, rating: Int, comment: String? = nil) {
        self.tradeHistoryId = tradeHistoryId
        self.rating = max(1, min(5, rating)) // 限制在1-5范围
        self.comment = comment
    }
}

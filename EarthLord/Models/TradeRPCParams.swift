//
//  TradeRPCParams.swift
//  EarthLord
//
//  Created by Yu Lei on 27/01/2026.
//

import Foundation

// 🚀 物理隔离：把参数放在独立文件，彻底断绝与 @MainActor 类的血缘关系

nonisolated struct CreateTradeOfferParams: Encodable, Sendable {
    let p_offering_items: [TradeItem]
    let p_requesting_items: [TradeItem]
    let p_validity_hours: Int
    let p_message: String?
}

nonisolated struct AcceptTradeOfferParams: Encodable, Sendable {
    let p_offer_id: String
}

nonisolated struct CancelTradeOfferParams: Encodable, Sendable {
    let p_offer_id: String
}

nonisolated struct GetMyTradeOffersParams: Encodable, Sendable {
    let p_status: String?
}

nonisolated struct GetAvailableTradeOffersParams: Encodable, Sendable {
    let p_limit: Int
    let p_offset: Int
}

nonisolated struct RateTradeParams: Encodable, Sendable {
    let p_trade_id: UUID
    let p_rating: Int
    let p_comment: String?
}

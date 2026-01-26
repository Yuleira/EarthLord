//
//  TradeManager.swift
//  EarthLord
//
//  交易系统管理器
//  负责玩家之间的物品交易逻辑
//

import Foundation
import Supabase

/// 交易错误类型
enum TradeError: LocalizedError {
    case notAuthenticated
    case insufficientItems(itemId: String, needed: Int, available: Int)
    case offerNotFound
    case offerNotActive
    case offerExpired
    case cannotAcceptOwnOffer
    case notOfferOwner
    case alreadyRated
    case invalidParameters
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return String(localized: "error_not_logged_in")
        case .insufficientItems(let itemId, let needed, let available):
            return String(format: String(localized: "trade_error_insufficient_items"), itemId, needed, available)
        case .offerNotFound:
            return String(localized: "trade_error_offer_not_found")
        case .offerNotActive:
            return String(localized: "trade_error_offer_not_active")
        case .offerExpired:
            return String(localized: "trade_error_offer_expired")
        case .cannotAcceptOwnOffer:
            return String(localized: "trade_error_cannot_accept_own_offer")
        case .notOfferOwner:
            return String(localized: "trade_error_not_offer_owner")
        case .alreadyRated:
            return String(localized: "trade_error_already_rated")
        case .invalidParameters:
            return String(localized: "trade_error_invalid_parameters")
        case .databaseError(let message):
            return String(format: String(localized: "error_database_format"), message)
        }
    }
}

/// 交易系统管理器
@MainActor
class TradeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TradeManager()

    // MARK: - Published Properties

    /// 我的挂单列表
    @Published var myOffers: [TradeOffer] = []

    /// 可接受的挂单列表（市场）
    @Published var availableOffers: [TradeOffer] = []

    /// 交易历史列表
    @Published var tradeHistory: [TradeHistory] = []

    /// 是否正在加载
    @Published var isLoading = false

    /// 错误信息
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let supabase = SupabaseClient.shared.client
    private let authManager = AuthManager.shared
    private let inventoryManager = InventoryManager.shared

    // MARK: - Initialization

    private init() {
        print("🔄 [TradeManager] Initialized")
    }

    // MARK: - Public Methods

    /// 创建交易挂单
    /// - Parameters:
    ///   - offeringItems: 提供的物品列表
    ///   - requestingItems: 需要的物品列表
    ///   - validityHours: 有效期（小时数，默认24小时）
    ///   - message: 留言（可选）
    /// - Returns: 创建成功的挂单ID
    func createTradeOffer(
        offeringItems: [TradeItem],
        requestingItems: [TradeItem],
        validityHours: Int = 24,
        message: String? = nil
    ) async throws -> String {
        print("📦 [TradeManager] Creating trade offer...")

        // 1. 验证用户登录
        guard authManager.isAuthenticated else {
            throw TradeError.notAuthenticated
        }

        // 2. 验证参数
        guard !offeringItems.isEmpty, !requestingItems.isEmpty else {
            throw TradeError.invalidParameters
        }

        // 3. 构建参数
        let offeringJson = try JSONEncoder().encode(offeringItems)
        let requestingJson = try JSONEncoder().encode(requestingItems)

        guard let offeringData = try? JSONSerialization.jsonObject(with: offeringJson) as? [[String: Any]],
              let requestingData = try? JSONSerialization.jsonObject(with: requestingJson) as? [[String: Any]] else {
            throw TradeError.invalidParameters
        }

        do {
            // 4. 调用数据库函数创建挂单
            let response = try await supabase.rpc(
                "create_trade_offer",
                params: [
                    "p_offering_items": offeringData,
                    "p_requesting_items": requestingData,
                    "p_validity_hours": validityHours,
                    "p_message": message ?? NSNull()
                ]
            ).execute()

            // 5. 解析返回的挂单ID
            guard let offerId = String(data: response.data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))) else {
                throw TradeError.databaseError("Failed to parse offer ID")
            }

            print("✅ [TradeManager] Trade offer created: \(offerId)")

            // 6. 刷新我的挂单列表
            await loadMyOffers()

            // 7. 刷新库存（物品已被锁定）
            await inventoryManager.loadInventory()

            return offerId

        } catch let error as PostgrestError {
            // 解析数据库错误
            if let message = error.message {
                if message.contains("Insufficient items") {
                    // 提取物品不足的信息
                    print("❌ [TradeManager] Insufficient items: \(message)")
                    throw TradeError.databaseError(message)
                }
            }
            print("❌ [TradeManager] Database error: \(error)")
            throw TradeError.databaseError(error.message ?? "Unknown error")
        } catch {
            print("❌ [TradeManager] Error creating trade offer: \(error)")
            throw error
        }
    }

    /// 接受交易挂单
    /// - Parameter offerId: 挂单ID
    /// - Returns: 交易结果（包含历史记录ID和交换的物品）
    func acceptTradeOffer(offerId: String) async throws -> (historyId: String, offeredItems: [TradeItem], receivedItems: [TradeItem]) {
        print("🤝 [TradeManager] Accepting trade offer: \(offerId)")

        // 1. 验证用户登录
        guard authManager.isAuthenticated else {
            throw TradeError.notAuthenticated
        }

        do {
            // 2. 调用数据库函数接受挂单
            let response = try await supabase.rpc(
                "accept_trade_offer",
                params: ["p_offer_id": offerId]
            ).execute()

            // 3. 解析返回结果
            struct AcceptResult: Codable {
                let success: Bool
                let historyId: String
                let offeredItems: [TradeItem]
                let receivedItems: [TradeItem]

                enum CodingKeys: String, CodingKey {
                    case success
                    case historyId = "history_id"
                    case offeredItems = "offered_items"
                    case receivedItems = "received_items"
                }
            }

            let result = try JSONDecoder().decode(AcceptResult.self, from: response.data)

            print("✅ [TradeManager] Trade accepted successfully")
            print("   📜 History ID: \(result.historyId)")
            print("   📦 Offered: \(result.offeredItems.count) items")
            print("   📥 Received: \(result.receivedItems.count) items")

            // 4. 刷新相关数据
            await loadAvailableOffers()
            await loadTradeHistory()
            await inventoryManager.loadInventory()

            return (result.historyId, result.offeredItems, result.receivedItems)

        } catch let error as PostgrestError {
            // 解析具体错误
            if let message = error.message {
                if message.contains("not found") {
                    throw TradeError.offerNotFound
                } else if message.contains("not active") {
                    throw TradeError.offerNotActive
                } else if message.contains("expired") {
                    throw TradeError.offerExpired
                } else if message.contains("your own") {
                    throw TradeError.cannotAcceptOwnOffer
                } else if message.contains("Insufficient items") {
                    throw TradeError.databaseError(message)
                }
            }
            print("❌ [TradeManager] Database error: \(error)")
            throw TradeError.databaseError(error.message ?? "Unknown error")
        } catch {
            print("❌ [TradeManager] Error accepting trade offer: \(error)")
            throw error
        }
    }

    /// 取消交易挂单
    /// - Parameter offerId: 挂单ID
    func cancelTradeOffer(offerId: String) async throws {
        print("❌ [TradeManager] Cancelling trade offer: \(offerId)")

        // 1. 验证用户登录
        guard authManager.isAuthenticated else {
            throw TradeError.notAuthenticated
        }

        do {
            // 2. 调用数据库函数取消挂单
            let _ = try await supabase.rpc(
                "cancel_trade_offer",
                params: ["p_offer_id": offerId]
            ).execute()

            print("✅ [TradeManager] Trade offer cancelled successfully")

            // 3. 刷新相关数据
            await loadMyOffers()
            await inventoryManager.loadInventory() // 物品已退回

        } catch let error as PostgrestError {
            // 解析具体错误
            if let message = error.message {
                if message.contains("not found") {
                    throw TradeError.offerNotFound
                } else if message.contains("only cancel your own") {
                    throw TradeError.notOfferOwner
                } else if message.contains("only cancel active") {
                    throw TradeError.offerNotActive
                }
            }
            print("❌ [TradeManager] Database error: \(error)")
            throw TradeError.databaseError(error.message ?? "Unknown error")
        } catch {
            print("❌ [TradeManager] Error cancelling trade offer: \(error)")
            throw error
        }
    }

    /// 加载我的挂单
    /// - Parameter status: 可选，过滤指定状态的挂单
    func loadMyOffers(status: TradeOfferStatus? = nil) async {
        print("📋 [TradeManager] Loading my offers...")

        guard authManager.isAuthenticated else {
            print("⚠️ [TradeManager] Not authenticated")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.rpc(
                "get_my_trade_offers",
                params: ["p_status": status?.rawValue ?? NSNull()]
            ).execute()

            let offers = try JSONDecoder().decode([TradeOffer].self, from: response.data)
            self.myOffers = offers

            print("✅ [TradeManager] Loaded \(offers.count) my offers")

        } catch {
            print("❌ [TradeManager] Error loading my offers: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// 加载可接受的挂单（交易市场）
    /// - Parameters:
    ///   - limit: 限制数量（默认50）
    ///   - offset: 偏移量（默认0，用于分页）
    func loadAvailableOffers(limit: Int = 50, offset: Int = 0) async {
        print("🛒 [TradeManager] Loading available offers...")

        guard authManager.isAuthenticated else {
            print("⚠️ [TradeManager] Not authenticated")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.rpc(
                "get_available_trade_offers",
                params: [
                    "p_limit": limit,
                    "p_offset": offset
                ]
            ).execute()

            let offers = try JSONDecoder().decode([TradeOffer].self, from: response.data)
            self.availableOffers = offers

            print("✅ [TradeManager] Loaded \(offers.count) available offers")

        } catch {
            print("❌ [TradeManager] Error loading available offers: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// 加载交易历史
    func loadTradeHistory() async {
        print("📜 [TradeManager] Loading trade history...")

        guard authManager.isAuthenticated else {
            print("⚠️ [TradeManager] Not authenticated")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await supabase.rpc(
                "get_my_trade_history"
            ).execute()

            let history = try JSONDecoder().decode([TradeHistory].self, from: response.data)
            self.tradeHistory = history

            print("✅ [TradeManager] Loaded \(history.count) trade history records")

        } catch {
            print("❌ [TradeManager] Error loading trade history: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// 评价交易
    /// - Parameters:
    ///   - tradeHistoryId: 交易历史ID
    ///   - rating: 评分（1-5）
    ///   - comment: 评语（可选）
    func rateTrade(tradeHistoryId: String, rating: Int, comment: String? = nil) async throws {
        print("⭐ [TradeManager] Rating trade: \(tradeHistoryId), rating: \(rating)")

        // 1. 验证用户登录
        guard authManager.isAuthenticated else {
            throw TradeError.notAuthenticated
        }

        // 2. 验证评分范围
        let validRating = max(1, min(5, rating))

        do {
            // 3. 调用数据库函数评价交易
            let _ = try await supabase.rpc(
                "rate_trade",
                params: [
                    "p_trade_history_id": tradeHistoryId,
                    "p_rating": validRating,
                    "p_comment": comment ?? NSNull()
                ]
            ).execute()

            print("✅ [TradeManager] Trade rated successfully")

            // 4. 刷新交易历史
            await loadTradeHistory()

        } catch let error as PostgrestError {
            // 解析具体错误
            if let message = error.message {
                if message.contains("not found") {
                    throw TradeError.offerNotFound
                } else if message.contains("already rated") {
                    throw TradeError.alreadyRated
                } else if message.contains("not a participant") {
                    throw TradeError.notOfferOwner
                }
            }
            print("❌ [TradeManager] Database error: \(error)")
            throw TradeError.databaseError(error.message ?? "Unknown error")
        } catch {
            print("❌ [TradeManager] Error rating trade: \(error)")
            throw error
        }
    }

    /// 处理过期挂单（定时任务调用或手动触发）
    func processExpiredOffers() async -> Int {
        print("🕒 [TradeManager] Processing expired offers...")

        guard authManager.isAuthenticated else {
            print("⚠️ [TradeManager] Not authenticated")
            return 0
        }

        do {
            let response = try await supabase.rpc("process_expired_offers").execute()

            // 解析处理的挂单数量
            if let countString = String(data: response.data, encoding: .utf8),
               let count = Int(countString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                print("✅ [TradeManager] Processed \(count) expired offers")

                // 刷新我的挂单列表
                await loadMyOffers()
                await inventoryManager.loadInventory()

                return count
            }

            return 0

        } catch {
            print("❌ [TradeManager] Error processing expired offers: \(error)")
            return 0
        }
    }

    // MARK: - Helper Methods

    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }

    /// 获取物品显示名称（辅助方法）
    /// - Parameter itemId: 物品ID
    /// - Returns: 本地化的物品名称
    func getItemDisplayName(for itemId: String) -> String {
        return inventoryManager.resourceDisplayName(for: itemId)
    }

    /// 获取物品图标名称（辅助方法）
    /// - Parameter itemId: 物品ID
    /// - Returns: SF Symbol 图标名称
    func getItemIconName(for itemId: String) -> String {
        return inventoryManager.resourceIconName(for: itemId)
    }
}

# 交易系统实现说明

## 📦 已完成的组件

### 1. 数据模型 (TradeModels.swift)

**位置**: `EarthLord/Models/TradeModels.swift`

**包含的模型**:
- `TradeOfferStatus` - 交易状态枚举（active/completed/cancelled/expired）
- `TradeItem` - 交易物品结构
- `TradeOffer` - 交易挂单模型
- `TradeHistory` - 交易历史记录
- `ItemsExchanged` - 交换物品详情
- `CreateTradeOfferRequest` - 创建挂单请求参数
- `RateTradeRequest` - 评价交易请求参数

**特性**:
- ✅ 完整的 Codable 支持
- ✅ Late-Binding 本地化支持
- ✅ 自动过期检测
- ✅ 格式化时间显示

---

### 2. 数据库迁移 (008_trade_system.sql)

**位置**: `supabase/migrations/008_trade_system.sql`

**包含的表**:
- `trade_offers` - 交易挂单表
- `trade_history` - 交易历史表

**核心函数**:
1. `create_trade_offer()` - 创建挂单，自动锁定物品
2. `accept_trade_offer()` - 接受交易，执行物品交换
3. `cancel_trade_offer()` - 取消挂单，退还物品
4. `rate_trade()` - 评价交易
5. `process_expired_offers()` - 处理过期挂单
6. `get_available_trade_offers()` - 查询可接受的挂单
7. `get_my_trade_offers()` - 查询我的挂单
8. `get_my_trade_history()` - 查询交易历史

**安全特性**:
- ✅ 行级安全策略 (RLS)
- ✅ 并发控制（行级锁）
- ✅ 事务完整性
- ✅ 权限验证
- ✅ 防止重复交易
- ✅ 防止自我交易

---

### 3. 管理器 (TradeManager.swift)

**位置**: `EarthLord/Managers/TradeManager.swift`

**提供的方法**:

#### 核心交易功能
```swift
// 创建交易挂单
func createTradeOffer(
    offeringItems: [TradeItem],
    requestingItems: [TradeItem],
    validityHours: Int = 24,
    message: String? = nil
) async throws -> String

// 接受交易
func acceptTradeOffer(offerId: String) async throws -> (
    historyId: String,
    offeredItems: [TradeItem],
    receivedItems: [TradeItem]
)

// 取消挂单
func cancelTradeOffer(offerId: String) async throws

// 评价交易
func rateTrade(
    tradeHistoryId: String,
    rating: Int,
    comment: String? = nil
) async throws
```

#### 查询功能
```swift
// 加载我的挂单
func loadMyOffers(status: TradeOfferStatus? = nil) async

// 加载可接受的挂单（市场）
func loadAvailableOffers(limit: Int = 50, offset: Int = 0) async

// 加载交易历史
func loadTradeHistory() async

// 处理过期挂单
func processExpiredOffers() async -> Int
```

#### 辅助方法
```swift
// 获取物品显示名称
func getItemDisplayName(for itemId: String) -> String

// 获取物品图标
func getItemIconName(for itemId: String) -> String

// 清除错误信息
func clearError()
```

**Published 属性**（自动更新 UI）:
- `myOffers: [TradeOffer]` - 我的挂单列表
- `availableOffers: [TradeOffer]` - 可接受的挂单列表
- `tradeHistory: [TradeHistory]` - 交易历史列表
- `isLoading: Bool` - 加载状态
- `errorMessage: String?` - 错误信息

---

### 4. 本地化支持 (LocalizedString.swift)

**已添加 38 个交易系统相关的本地化 Key**:

#### UI 文本
- `tradeMarketTitle` - 交易市场
- `tradeMyOffers` - 我的挂单
- `tradeHistory` - 交易历史
- `tradeCreateOffer` - 创建挂单
- `tradeAccept` - 接受交易
- `tradeCancel` - 取消挂单
- `tradeRate` - 评价交易
- `tradeOffering` - 提供物品
- `tradeRequesting` - 需要物品
- 等等...

#### 状态标签
- `tradeStatusActive` - 等待中
- `tradeStatusCompleted` - 已完成
- `tradeStatusCancelled` - 已取消
- `tradeStatusExpired` - 已过期

#### 错误信息
- `tradeErrorInsufficientItems` - 物品不足
- `tradeErrorOfferNotFound` - 挂单不存在
- `tradeErrorOfferExpired` - 挂单已过期
- 等等...

---

## 🚀 使用示例

### 示例 1: 创建交易挂单

```swift
import SwiftUI

struct CreateTradeView: View {
    @StateObject private var tradeManager = TradeManager.shared
    @State private var offeringItems: [TradeItem] = []
    @State private var requestingItems: [TradeItem] = []

    var body: some View {
        Form {
            Section(header: Text(LocalizedString.tradeOffering)) {
                // 选择提供的物品
                // 例如: [TradeItem(itemId: "wood", quantity: 50)]
            }

            Section(header: Text(LocalizedString.tradeRequesting)) {
                // 选择需要的物品
                // 例如: [TradeItem(itemId: "stone", quantity: 30)]
            }

            Button(LocalizedString.tradeCreateOffer) {
                Task {
                    do {
                        let offerId = try await tradeManager.createTradeOffer(
                            offeringItems: offeringItems,
                            requestingItems: requestingItems,
                            validityHours: 24,
                            message: "Fair trade!"
                        )
                        print("✅ Created offer: \(offerId)")
                    } catch {
                        print("❌ Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
```

### 示例 2: 浏览交易市场

```swift
struct TradeMarketView: View {
    @StateObject private var tradeManager = TradeManager.shared

    var body: some View {
        List(tradeManager.availableOffers) { offer in
            TradeOfferRow(offer: offer) {
                Task {
                    do {
                        let result = try await tradeManager.acceptTradeOffer(
                            offerId: offer.id
                        )
                        print("✅ Trade completed!")
                        print("   Received: \(result.receivedItems)")
                    } catch {
                        print("❌ Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await tradeManager.loadAvailableOffers()
            }
        }
    }
}
```

### 示例 3: 查看我的挂单

```swift
struct MyOffersView: View {
    @StateObject private var tradeManager = TradeManager.shared

    var body: some View {
        List(tradeManager.myOffers) { offer in
            VStack(alignment: .leading) {
                Text("Status: \(offer.status.localizedName)")
                Text("Expires: \(offer.formattedExpiresAt)")

                if offer.status == .active {
                    Button(LocalizedString.tradeCancel) {
                        Task {
                            try? await tradeManager.cancelTradeOffer(
                                offerId: offer.id
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await tradeManager.loadMyOffers()
            }
        }
    }
}
```

### 示例 4: 评价交易

```swift
struct RateTradeView: View {
    let trade: TradeHistory
    @StateObject private var tradeManager = TradeManager.shared
    @State private var rating = 3
    @State private var comment = ""

    var body: some View {
        Form {
            Section {
                // 星级评分选择器
                Picker("Rating", selection: $rating) {
                    ForEach(1...5, id: \.self) { star in
                        Text("\(star) ⭐").tag(star)
                    }
                }

                TextField(LocalizedString.tradeComment, text: $comment)
            }

            Button(LocalizedString.tradeRate) {
                Task {
                    try? await tradeManager.rateTrade(
                        tradeHistoryId: trade.id,
                        rating: rating,
                        comment: comment.isEmpty ? nil : comment
                    )
                }
            }
        }
    }
}
```

---

## 📋 部署步骤

### 1. 运行数据库迁移

```bash
cd supabase
supabase migration up
```

或者手动在 Supabase Dashboard 执行：
```sql
-- 打开 SQL Editor
-- 粘贴 supabase/migrations/008_trade_system.sql 的内容
-- 执行
```

### 2. 添加 String Catalog 条目

在 `Localizable.xcstrings` 中添加以下 keys（需要添加英文和中文翻译）：

#### UI 文本 (21 keys)
- `trade_market_title` → "Trade Market" / "交易市场"
- `trade_my_offers` → "My Offers" / "我的挂单"
- `trade_history` → "Trade History" / "交易历史"
- `trade_create_offer` → "Create Offer" / "创建挂单"
- `trade_accept` → "Accept" / "接受"
- `trade_cancel` → "Cancel" / "取消"
- `trade_rate` → "Rate" / "评价"
- `trade_offering` → "Offering" / "提供物品"
- `trade_requesting` → "Requesting" / "需要物品"
- `trade_message` → "Message" / "留言"
- `trade_validity` → "Validity" / "有效期"
- `trade_expires_at` → "Expires At" / "过期时间"
- `trade_owner` → "Owner" / "发布者"
- `trade_accepter` → "Accepter" / "接受者"
- `trade_rating` → "Rating" / "评分"
- `trade_comment` → "Comment" / "评语"
- `trade_empty_offers` → "No trade offers yet" / "暂无交易挂单"
- `trade_empty_history` → "No trade history" / "暂无交易历史"
- `trade_confirm_accept` → "Confirm Accept" / "确认接受"
- `trade_confirm_cancel` → "Confirm Cancel" / "确认取消"
- `trade_success` → "Trade Successful!" / "交易成功！"
- `trade_published` → "Published" / "已发布"
- `trade_expired_label` → "Expired" / "已过期"

#### 状态 (4 keys)
- `trade_status_active` → "Active" / "等待中"
- `trade_status_completed` → "Completed" / "已完成"
- `trade_status_cancelled` → "Cancelled" / "已取消"
- `trade_status_expired` → "Expired" / "已过期"

#### 错误信息 (8 keys)
- `trade_error_insufficient_items` → "Insufficient %@: need %d, have %d" / "%@ 不足：需要 %d 个，拥有 %d 个"
- `trade_error_offer_not_found` → "Trade offer not found" / "交易挂单不存在"
- `trade_error_offer_not_active` → "Trade offer is not active" / "交易挂单未激活"
- `trade_error_offer_expired` → "Trade offer has expired" / "交易挂单已过期"
- `trade_error_cannot_accept_own_offer` → "Cannot accept your own offer" / "不能接受自己的挂单"
- `trade_error_not_offer_owner` → "You are not the owner of this offer" / "你不是该挂单的发布者"
- `trade_error_already_rated` → "You have already rated this trade" / "你已经评价过这笔交易"
- `trade_error_invalid_parameters` → "Invalid parameters" / "参数无效"

### 3. 在 Xcode 项目中添加文件

确保以下文件已添加到 Xcode 项目：
- ✅ `EarthLord/Models/TradeModels.swift`
- ✅ `EarthLord/Managers/TradeManager.swift`

### 4. 创建 UI 视图

根据上面的使用示例，创建以下视图：
- `TradeMarketView.swift` - 交易市场（浏览挂单）
- `CreateTradeOfferView.swift` - 创建挂单
- `MyOffersView.swift` - 我的挂单
- `TradeHistoryView.swift` - 交易历史
- `TradeOfferDetailView.swift` - 挂单详情
- `RateTradeView.swift` - 评价交易

---

## 🔧 集成要点

### 与 InventoryManager 协调

交易系统已经与 InventoryManager 集成：
- 创建挂单时，自动调用数据库函数锁定物品
- 接受交易时，数据库函数自动处理物品转移
- 取消挂单时，数据库函数自动退还物品
- TradeManager 在操作后自动刷新库存

### 数据库依赖

交易系统依赖以下数据库函数（需要在 InventoryManager 迁移中实现）：
- `remove_items_by_definition()` - 按物品定义ID扣除物品
- `add_item_to_inventory()` - 向库存添加物品

**如果这些函数不存在，需要先实现它们。**

---

## ⚠️ 注意事项

### 1. 物品锁定机制

- 发布挂单时，物品立即从库存扣除并锁定在挂单中
- 挂单完成后，物品转移给接受者
- 挂单取消或过期后，物品退回发布者
- **重要**: 不要在挂单期间手动操作相关物品

### 2. 并发安全

- 使用了数据库行级锁，防止同时接受同一挂单
- 所有物品操作在单个事务中完成，保证数据一致性

### 3. 过期处理

两种方式：
- **方式一**: 定时任务调用 `process_expired_offers()`
- **方式二**: 查询时自动过滤过期挂单（推荐用于小规模）

### 4. 权限控制

- 只能取消自己的挂单
- 不能接受自己的挂单
- 只能看到自己参与的交易历史
- 只能评价自己参与的交易

---

## 📊 数据流程图

### 创建挂单流程
```
用户选择物品 → 验证库存 → 创建挂单 → 锁定物品 → 发布成功
                  ↓
              库存不足 → 返回错误
```

### 接受交易流程
```
用户点击接受 → 查询并锁定挂单 → 验证状态和库存 → 执行物品交换
                                                    ↓
                                          创建历史记录 → 交易完成
```

### 取消挂单流程
```
用户点击取消 → 验证权限 → 退还物品 → 更新状态 → 取消成功
```

---

## 🎯 下一步建议

1. **创建 UI 视图** - 根据使用示例实现交易相关界面
2. **添加推送通知** - 挂单被接受时通知发布者
3. **添加搜索过滤** - 按物品类型、稀有度筛选挂单
4. **实现举报功能** - 允许举报不当交易
5. **添加交易统计** - 显示用户的交易总量、评分等
6. **优化 UI/UX** - 添加动画效果、确认对话框等

---

## 📝 API 完整性检查清单

- ✅ 数据模型（TradeModels.swift）
- ✅ 数据库表（trade_offers, trade_history）
- ✅ 核心函数（create, accept, cancel, rate）
- ✅ 查询函数（get my offers, get available offers, get history）
- ✅ 安全策略（RLS, 行级锁, 事务）
- ✅ TradeManager（完整API）
- ✅ 本地化支持（38 keys）
- ✅ 错误处理（TradeError枚举）
- ⚠️ UI 视图（待实现）
- ⚠️ String Catalog 翻译（待添加）

---

## 💡 技术亮点

1. **Late-Binding 本地化** - 所有字符串在渲染时才解析
2. **类型安全** - Swift 枚举和结构体保证类型正确
3. **并发安全** - 数据库行级锁防止竞态条件
4. **事务完整性** - 物品交换在单个事务中完成
5. **自动刷新** - TradeManager 自动协调 InventoryManager
6. **错误处理** - 详细的错误类型和本地化错误信息
7. **异步操作** - 使用 async/await 简化异步代码
8. **观察者模式** - @Published 属性自动更新 UI

---

## 📞 支持

如有问题或建议，请联系开发团队。

**注意**: 这是数据层和核心逻辑的完整实现，UI 层需要根据实际设计自行实现。

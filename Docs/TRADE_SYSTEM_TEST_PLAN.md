# 交易系统完整测试计划

## 测试目标
验证从点击"交易"到物品进入对方背包的完整逻辑闭环。

---

## 前置条件

### 1. 数据库迁移
确保所有迁移已应用：
```bash
# 启动Docker Desktop
# 然后执行：
cd /Users/LeiYu/Code/EarthLord
supabase db reset --local

# 验证函数是否存在
supabase db execute --local "SELECT proname FROM pg_proc WHERE proname IN ('remove_items_by_definition', 'add_item_to_inventory', 'create_trade_offer', 'accept_trade_offer');"
```

应该显示4个函数：
- remove_items_by_definition
- add_item_to_inventory
- create_trade_offer
- accept_trade_offer

### 2. Xcode项目配置
将Trade UI文件添加到Xcode项目：
1. 打开 `EarthLord.xcodeproj`
2. 右键点击 `Views` 文件夹 → "Add Files to EarthLord..."
3. 选择 `EarthLord/Views/Trade` 文件夹
4. 确保勾选：
   - ✅ Create groups
   - ✅ Target: EarthLord
5. 点击 "Add"

### 3. 准备测试数据
需要两个测试账号：
- **用户A（发布者）**：alice@test.com / password123
- **用户B（接受者）**：bob@test.com / password123

---

## 测试流程

### 阶段1：用户A发布挂单

#### 1.1 添加测试物品到用户A的库存
```swift
// 在Xcode调试控制台或TestMenuView中执行
await InventoryManager.shared.addBuildingTestResources()

// 验证库存
print(InventoryManager.shared.items.map { "\($0.definition.id): \($0.quantity)" })
```

**预期结果：**
```
wood: 500
stone: 500
metal: 200
fabric: 200
glass: 100
scrap_metal: 150
circuit: 50
concrete: 300
```

#### 1.2 进入交易界面
1. 登录为 alice@test.com
2. 点击底部 Tab Bar → "资源"
3. 点击顶部分段控制 → "交易"
4. 应该看到3个子标签：我的挂单 / 交易市场 / 交易历史

#### 1.3 发布挂单
1. 点击 "创建新挂单" 按钮
2. 在 "我要出的物品" 区域点击 "添加物品"
3. 选择 "木材"，数量设置为 50
4. 点击 "确认添加"
5. 在 "我想要的物品" 区域点击 "添加物品"
6. 选择 "石头"，数量设置为 30
7. 点击 "确认添加"
8. 有效期选择：24小时
9. 留言（可选）："Need stone for building!"
10. 点击 "发布挂单"

**预期结果：**
- ✅ 显示 "交易成功！" 提示
- ✅ 自动返回 "我的挂单" 页面
- ✅ 看到刚发布的挂单卡片，状态为 "进行中"
- ✅ 库存中木材数量变为 450（500 - 50 = 450）

**数据库验证：**
```sql
-- 检查挂单记录
SELECT id, owner_username, status, offering_items, requesting_items
FROM trade_offers
WHERE owner_id = (SELECT id FROM auth.users WHERE email = 'alice@test.com')
ORDER BY created_at DESC LIMIT 1;

-- 检查用户A库存（木材应该减少50）
SELECT item_definition_id, SUM(quantity) as total
FROM inventory_items
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alice@test.com')
  AND item_definition_id = 'wood'
GROUP BY item_definition_id;
```

**关键检查点：**
- ✅ trade_offers表中有新记录，status = 'active'
- ✅ offering_items = [{"item_id":"wood","quantity":50}]
- ✅ requesting_items = [{"item_id":"stone","quantity":30}]
- ✅ inventory_items中wood的总数 = 450

---

### 阶段2：用户B浏览并接受挂单

#### 2.1 添加测试物品到用户B的库存
```swift
// 切换到用户B账号，执行：
await InventoryManager.shared.addBuildingTestResources()
```

#### 2.2 浏览交易市场
1. 登录为 bob@test.com
2. 进入 "资源" → "交易" → "交易市场"
3. 应该看到用户A发布的挂单

**预期结果：**
- ✅ 看到挂单卡片显示：
  - 发布者：alice@test.com
  - 提供：木材 ×50
  - 需要：石头 ×30
  - 状态：进行中
  - 剩余时间：24小时

#### 2.3 查看挂单详情
1. 点击挂单卡片
2. 查看详情页面

**预期结果：**
- ✅ 显示发布者信息
- ✅ 显示 "对方出" 区域：木材 ×50
- ✅ 显示 "对方要" 区域：石头 ×30
- ✅ 显示留言："Need stone for building!"
- ✅ 显示 "你的库存" 区域：
  - 石头 ×500 ✅ (绿色勾号)
- ✅ "接受交易" 按钮为绿色且可点击

#### 2.4 接受交易
1. 点击 "接受交易" 按钮
2. 确认对话框显示交易详情
3. 点击 "确认接受"

**预期结果：**
- ✅ 显示 "交易成功！" 提示
- ✅ 提示内容："你已获得：木材 ×50"
- ✅ 自动关闭详情页，返回市场页
- ✅ 挂单从市场列表中消失
- ✅ "交易历史" 标签出现新记录

**数据库验证：**
```sql
-- 检查挂单状态更新
SELECT id, status, completed_by_username, completed_at
FROM trade_offers
WHERE id = '<offer_id>';

-- 检查交易历史记录
SELECT *
FROM trade_history
WHERE offer_id = '<offer_id>';

-- 检查用户A库存（应该获得石头30）
SELECT item_definition_id, SUM(quantity) as total
FROM inventory_items
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alice@test.com')
  AND item_definition_id IN ('wood', 'stone')
GROUP BY item_definition_id;

-- 检查用户B库存（应该失去石头30，获得木材50）
SELECT item_definition_id, SUM(quantity) as total
FROM inventory_items
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'bob@test.com')
  AND item_definition_id IN ('wood', 'stone')
GROUP BY item_definition_id;
```

**关键检查点：**
| 项目 | 预期值 | 说明 |
|------|--------|------|
| trade_offers.status | 'completed' | 挂单已完成 |
| trade_offers.completed_by_username | 'bob@test.com' | 由用户B完成 |
| trade_history 记录数 | 1 | 创建了历史记录 |
| 用户A - wood | 450 | 未变化（已锁定） |
| 用户A - stone | 530 | +30 |
| 用户B - wood | 550 | +50 |
| 用户B - stone | 470 | -30 |

---

### 阶段3：验证库存刷新

#### 3.1 用户A检查库存
1. 用户A进入 "资源" → "背包"
2. 查看石头数量

**预期结果：**
- ✅ 石头数量显示 530（500 + 30）
- ✅ 木材数量显示 450（已经在挂单时扣除）

#### 3.2 用户B检查库存
1. 用户B进入 "资源" → "背包"
2. 查看木材和石头数量

**预期结果：**
- ✅ 木材数量显示 550（500 + 50）
- ✅ 石头数量显示 470（500 - 30）

---

### 阶段4：验证交易历史

#### 4.1 用户A查看历史
1. 用户A进入 "资源" → "交易" → "交易历史"
2. 应该看到刚完成的交易

**预期结果：**
- ✅ 显示交易卡片
- ✅ 交易对象：bob@test.com
- ✅ 你给出：木材 ×50
- ✅ 你获得：石头 ×30
- ✅ 显示 "去评价" 按钮

#### 4.2 用户B查看历史
1. 用户B进入 "资源" → "交易" → "交易历史"
2. 应该看到相同的交易

**预期结果：**
- ✅ 显示交易卡片
- ✅ 交易对象：alice@test.com
- ✅ 你给出：石头 ×30
- ✅ 你获得：木材 ×50
- ✅ 显示 "去评价" 按钮

---

### 阶段5：评价系统测试

#### 5.1 用户A评价交易
1. 用户A在交易历史中点击 "去评价"
2. 选择星级：5星
3. 填写评语："Great trade, thanks!"
4. 点击 "提交评价"

**预期结果：**
- ✅ 评价成功提示
- ✅ 返回交易历史
- ✅ 该交易卡片显示 "你的评价：⭐⭐⭐⭐⭐"
- ✅ "去评价" 按钮消失

#### 5.2 用户B评价交易
1. 用户B在交易历史中点击 "去评价"
2. 选择星级：4星
3. 填写评语："Good trade"
4. 点击 "提交评价"

**预期结果：**
- ✅ 评价成功提示
- ✅ 双方评价都显示在卡片上

**数据库验证：**
```sql
-- 检查评价记录
SELECT seller_rating, seller_comment, buyer_rating, buyer_comment
FROM trade_history
WHERE id = '<history_id>';
```

**关键检查点：**
- ✅ seller_rating = 5
- ✅ seller_comment = "Great trade, thanks!"
- ✅ buyer_rating = 4
- ✅ buyer_comment = "Good trade"

---

## 边界情况测试

### 测试1：库存不足
1. 用户A发布挂单：出木材1000（但只有500）
2. **预期结果：** 显示错误提示 "库存不足"

### 测试2：接受自己的挂单
1. 用户A发布挂单
2. 同一用户尝试在市场接受
3. **预期结果：** 挂单不显示在自己的市场列表中

### 测试3：挂单过期
1. 用户A发布挂单，有效期1小时
2. 修改系统时间或等待1小时
3. 用户B尝试接受
4. **预期结果：** 显示 "挂单已过期"

### 测试4：取消挂单
1. 用户A发布挂单：出木材50
2. 在 "我的挂单" 页面点击 "取消挂单"
3. 确认取消
4. **预期结果：**
   - ✅ 挂单状态变为 "已取消"
   - ✅ 木材50退回用户A库存（500 - 50 + 50 = 500）

**数据库验证：**
```sql
-- 检查挂单状态
SELECT status FROM trade_offers WHERE id = '<offer_id>';
-- 应该返回 'cancelled'

-- 检查用户A库存恢复
SELECT SUM(quantity) FROM inventory_items
WHERE user_id = '<user_a_id>' AND item_definition_id = 'wood';
-- 应该返回 500
```

### 测试5：并发接受
1. 用户B和用户C同时点击接受同一挂单
2. **预期结果：** 只有一人成功，另一人收到 "挂单已完成" 错误

---

## 性能测试

### 测试1：大批量物品交换
1. 发布挂单：出10种不同物品，每种100个
2. **预期结果：** 交易成功，耗时 < 3秒

### 测试2：高并发市场浏览
1. 发布100个挂单
2. 多用户同时浏览市场
3. **预期结果：** 列表加载流畅，无卡顿

---

## 错误处理测试

### 测试1：网络中断
1. 发布挂单过程中断开网络
2. **预期结果：** 显示错误提示，不会扣除库存

### 测试2：数据库锁定
1. 两个用户同时接受同一挂单
2. **预期结果：** 使用 FOR UPDATE 行级锁，只有一人成功

---

## 成功标准

### 核心流程完整性 ✅
- [x] 发布挂单成功，物品立即锁定
- [x] 接受挂单成功，物品正确交换
- [x] 双方库存数量准确更新
- [x] 交易历史正确记录
- [x] 评价系统正常工作

### 数据一致性 ✅
- [x] 物品总量守恒（发布者扣除 = 接受者获得）
- [x] 数据库状态正确（active → completed）
- [x] 无物品重复获得或丢失
- [x] 库存与UI显示一致

### 并发安全性 ✅
- [x] 行级锁防止并发接受
- [x] 事务确保原子性
- [x] 无竞态条件

### 用户体验 ✅
- [x] 所有操作有明确反馈
- [x] 错误提示清晰友好
- [x] 界面流畅无卡顿
- [x] 状态实时更新

---

## 测试记录模板

```markdown
## 测试执行记录

**测试日期：** 2026-01-27
**测试人员：**
**App版本：**

### 阶段1：发布挂单
- [ ] 库存初始化成功
- [ ] 发布挂单成功
- [ ] 物品锁定生效
- [ ] UI显示正确

**实际库存变化：**
- 木材：500 → ___
- 石头：500 → ___

### 阶段2：接受挂单
- [ ] 市场显示挂单
- [ ] 详情页显示完整
- [ ] 接受交易成功
- [ ] 物品交换正确

**用户A最终库存：**
- 木材：___（预期450）
- 石头：___（预期530）

**用户B最终库存：**
- 木材：___（预期550）
- 石头：___（预期470）

### 阶段3-5
- [ ] 交易历史显示正确
- [ ] 评价系统正常
- [ ] 所有边界情况通过

**遇到的问题：**
1.
2.

**解决方案：**
1.
2.
```

---

## 快速验证脚本

```swift
// 在Xcode调试控制台执行

// 1. 添加测试资源
await InventoryManager.shared.addBuildingTestResources()

// 2. 检查库存
print("=== 库存检查 ===")
for item in InventoryManager.shared.items {
    print("\(item.definition.id): \(item.quantity)")
}

// 3. 发布挂单
let offerId = try await TradeManager.shared.createTradeOffer(
    offeringItems: [TradeItem(itemId: "wood", quantity: 50)],
    requestingItems: [TradeItem(itemId: "stone", quantity: 30)],
    validityHours: 24,
    message: "Test trade"
)
print("✅ Offer created: \(offerId)")

// 4. 加载市场
await TradeManager.shared.loadAvailableOffers()
print("=== 市场挂单数 ===")
print(TradeManager.shared.availableOffers.count)

// 5. 接受挂单（需切换到另一用户）
let result = try await TradeManager.shared.acceptTradeOffer(offerId: offerId)
print("✅ Trade accepted: \(result.historyId)")

// 6. 验证库存
await InventoryManager.shared.loadInventory()
print("=== 交易后库存 ===")
for item in InventoryManager.shared.items {
    print("\(item.definition.id): \(item.quantity)")
}
```

---

## 常见问题排查

### 问题1：发布挂单后库存未减少
**原因：** remove_items_by_definition 函数未生效
**解决：** 检查数据库函数是否正确创建，查看 Supabase 日志

### 问题2：接受交易失败，提示"挂单未找到"
**原因：** RLS策略限制或挂单已过期
**解决：** 检查 trade_offers 表的 RLS 策略，确认 expires_at

### 问题3：物品交换后数量不对
**原因：** add_item_to_inventory 逻辑错误
**解决：** 查看数据库日志，验证 JSONB 解析是否正确

### 问题4：UI未刷新
**原因：** TradeManager 的 @Published 属性未触发更新
**解决：** 检查 await loadInventory() 是否正确调用

---

## 下一步优化建议

1. **通知系统**：交易完成后推送通知给发布者
2. **搜索过滤**：市场添加物品筛选功能
3. **交易统计**：显示用户交易次数、信誉评分
4. **价格建议**：基于历史交易数据给出参考价格
5. **批量操作**：支持一次发布多个挂单

---

## 总结

本测试计划覆盖了交易系统的完整生命周期：
1. ✅ 发布挂单（物品锁定）
2. ✅ 市场浏览（RLS权限控制）
3. ✅ 接受交易（物品交换、并发控制）
4. ✅ 库存同步（双方库存更新）
5. ✅ 交易历史（记录保留）
6. ✅ 评价系统（信誉机制）

执行此测试计划后，可以确保交易系统的逻辑闭环完整、数据一致性正确、用户体验流畅。

# 交易系统诊断与修复指南
# Trade System Diagnostic & Fix Guide

## 🔍 问题诊断步骤

### 步骤 1：使用诊断按钮

1. **打开 App**，导航到 **Trade** → **My Offers** → **Create Listing**
2. 你会看到橙色的 **"Debug Tools"** 区域
3. **点击 "Debug: Test Database"** 按钮
4. **查看 Xcode 控制台输出**

### 步骤 2：分析诊断结果

控制台会输出以下信息：

```
============================================================
🔍 [DEBUG] Database Connection Test
============================================================

1️⃣ Supabase Configuration:
   URL: https://zkcjvhdhartrrekzjtjg.supabase.co
   Key: eyJhbGciOiJIUzI1NiI...
   Valid: ✅ YES (或 ❌ NO)

2️⃣ Authentication Status:
   Authenticated: ✅ YES
   User ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

3️⃣ Testing Database Table Access:
   ✅ trade_offers table accessible
   (或)
   ❌ trade_offers table error:
      ⚠️ Table 'trade_offers' does not exist!
      👉 Run migration: 007_trade_system.sql

4️⃣ Testing RPC Function:
   ✅ get_my_trade_offers() function exists
   (或)
   ❌ RPC function error:
      ⚠️ RPC functions do not exist!
      👉 Run migrations:
         1. 007_trade_system.sql
         2. 008_inventory_helper_functions.sql
```

---

## 🛠️ 修复方案

### 情况 A：表或函数不存在

**诊断结果显示：**
```
❌ Table 'trade_offers' does not exist!
或
❌ RPC functions do not exist!
```

**解决方法：执行数据库迁移**

#### 方式 1：使用 Supabase CLI（推荐）

```bash
# 1. 确保已安装 Supabase CLI
# https://supabase.com/docs/guides/cli

# 2. 导航到项目目录
cd /Users/LeiYu/Code/EarthLord

# 3. 链接到你的 Supabase 项目
supabase link --project-ref zkcjvhdhartrrekzjtjg

# 4. 推送所有迁移到远程数据库
supabase db push
```

#### 方式 2：使用 Supabase Dashboard（手动）

1. **访问** https://supabase.com/dashboard
2. **选择你的项目** (zkcjvhdhartrrekzjtjg)
3. **导航到** SQL Editor
4. **创建新查询**
5. **复制并执行以下文件内容（按顺序）：**

   **第一步：** 执行 `008_inventory_helper_functions.sql`
   ```sql
   -- 复制 /Users/LeiYu/Code/EarthLord/supabase/migrations/008_inventory_helper_functions.sql
   -- 粘贴到 SQL 编辑器
   -- 点击 "Run" 或按 Cmd+Enter
   ```

   **第二步：** 执行 `007_trade_system.sql`
   ```sql
   -- 复制 /Users/LeiYu/Code/EarthLord/supabase/migrations/007_trade_system.sql
   -- 粘贴到 SQL 编辑器
   -- 点击 "Run"
   ```

6. **验证迁移成功**：
   ```sql
   -- 检查表是否存在
   SELECT * FROM trade_offers LIMIT 1;
   SELECT * FROM trade_history LIMIT 1;

   -- 检查函数是否存在
   SELECT proname FROM pg_proc WHERE proname LIKE '%trade%';
   ```

---

### 情况 B：网络连接问题

**诊断结果显示：**
```
URLError caught
Error code: -1003 (或其他网络错误码)
```

**可能原因：**
1. **设备无网络连接**
2. **防火墙阻止连接**
3. **Supabase 服务暂时不可用**

**解决方法：**
1. 检查设备网络连接
2. 尝试在浏览器中访问 https://zkcjvhdhartrrekzjtjg.supabase.co
3. 检查 Supabase 状态页面：https://status.supabase.com

---

### 情况 C：权限问题（RLS）

**诊断结果显示：**
```
PostgrestError caught
Code: 42501
Message: permission denied for table trade_offers
```

**解决方法：** 检查 Row Level Security (RLS) 策略

```sql
-- 在 Supabase SQL 编辑器中执行
-- 查看当前策略
SELECT * FROM pg_policies WHERE tablename = 'trade_offers';

-- 如果策略不正确，重新运行 007_trade_system.sql 中的 RLS 部分
```

---

## 📊 完整的错误代码参考

| 错误类型 | 特征 | 根本原因 | 修复方法 |
|---------|------|---------|---------|
| **RPC 函数不存在** | `function "create_trade_offer" does not exist` | 数据库迁移未执行 | 执行 007 和 008 迁移 |
| **表不存在** | `relation "trade_offers" does not exist` | 数据库迁移未执行 | 执行 007 迁移 |
| **网络连接失败** | `Could not connect to the server` | 网络问题或 URL 错误 | 检查网络和 Supabase URL |
| **权限错误** | `permission denied` | RLS 策略错误 | 重新执行 RLS 策略 |
| **参数类型错误** | `invalid input syntax for type` | RPC 参数格式错误 | 检查客户端代码 |
| **认证失败** | `Not authenticated` | 用户未登录 | 确保已登录 |

---

## 🧪 验证修复成功

执行迁移后，按以下步骤验证：

### 1. 重新运行诊断测试
- 点击 **"Debug: Test Database"** 按钮
- 确保所有检查都显示 ✅

### 2. 测试完整流程
1. **填充库存：** 点击 "Debug: Fill Inventory"
2. **添加物品：** 在 "I Am Offering" 中添加 Wood x30
3. **添加需求：** 在 "I Want" 中添加 Stone x20
4. **发布挂单：** 点击 "Publish Listing"
5. **验证成功：** 应该看到 "Trade Success" 弹窗

### 3. 检查数据库
在 Supabase Dashboard SQL 编辑器中：

```sql
-- 查看你的挂单
SELECT * FROM trade_offers WHERE owner_id = auth.uid();

-- 查看物品是否被扣除
SELECT * FROM inventory_items WHERE user_id = auth.uid();
```

---

## 🚨 常见问题排查

### Q1: 迁移执行后仍然报错
**A:** 清理 App 缓存并重启：
```bash
# 删除 App
# 重新运行 (Xcode → Product → Clean Build Folder)
# 重新安装
```

### Q2: 提示 "Insufficient items" 但库存明明有物品
**A:** 检查 `item_definition_id` 是否匹配：
```sql
-- 查看库存中的物品 ID
SELECT item_definition_id, quantity FROM inventory_items WHERE user_id = auth.uid();

-- 应该是小写的 "wood", "stone" 等，而不是 "item_wood"
```

### Q3: RPC 函数执行超时
**A:** 检查数据库性能和索引：
```sql
-- 确保索引存在
SELECT indexname FROM pg_indexes WHERE tablename = 'inventory_items';
```

---

## 📝 技术细节

### 涉及的数据库对象

**表：**
- `trade_offers` - 交易挂单表
- `trade_history` - 交易历史表
- `inventory_items` - 库存表（依赖项）

**RPC 函数：**
- `create_trade_offer()` - 创建挂单
- `accept_trade_offer()` - 接受挂单
- `cancel_trade_offer()` - 取消挂单
- `get_my_trade_offers()` - 查询我的挂单
- `get_available_trade_offers()` - 查询市场挂单
- `get_my_trade_history()` - 查询交易历史
- `rate_trade()` - 评价交易
- `process_expired_offers()` - 处理过期挂单

**辅助函数（依赖项）：**
- `remove_items_by_definition()` - 从库存移除物品
- `add_item_to_inventory()` - 向库存添加物品

---

## ✅ 成功标志

当一切正常工作时，你应该能：

1. ✅ 点击 "Debug: Test Database" 看到所有 ✅
2. ✅ 填充库存并看到物品数量
3. ✅ 添加物品到 "I Am Offering" 和 "I Want"
4. ✅ 成功发布挂单
5. ✅ 在 "My Offers" 中看到挂单
6. ✅ 物品数量正确减少

---

## 📞 获取帮助

如果上述步骤都无法解决问题，请提供以下信息：

1. **完整的 Xcode 控制台输出**（从 "Debug: Test Database" 开始）
2. **Supabase Dashboard SQL 查询结果**：
   ```sql
   -- 执行这些查询并提供结果
   SELECT proname FROM pg_proc WHERE proname LIKE '%trade%';
   SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%trade%';
   ```
3. **错误截图**（包括完整的错误消息）

---

**最后更新：** 2026-01-27
**版本：** 1.0

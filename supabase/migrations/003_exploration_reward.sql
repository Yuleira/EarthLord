-- 《地球新主》探索奖励系统
-- Migration: 003_exploration_reward
--
-- 执行方式：
-- 1. 通过 Supabase Dashboard → SQL Editor 执行
-- 2. 或通过 supabase db push 命令
-- 3. 或通过 Supabase MCP 工具执行

-- ============================================
-- 1. item_definitions（物品定义表）
-- ============================================
CREATE TABLE IF NOT EXISTS item_definitions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,  -- 'water'/'food'/'medical'/'material'/'tool'/'weapon'/'other'
    icon TEXT NOT NULL,      -- SF Symbol 名称
    rarity TEXT NOT NULL,    -- 'common'/'rare'/'epic'
    base_value INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS item_definitions_category_idx ON item_definitions(category);
CREATE INDEX IF NOT EXISTS item_definitions_rarity_idx ON item_definitions(rarity);

-- RLS（所有人可读）
ALTER TABLE item_definitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "item_definitions_select_all" ON item_definitions;
CREATE POLICY "item_definitions_select_all" ON item_definitions
    FOR SELECT USING (true);

-- ============================================
-- 2. 插入初始物品数据
-- ============================================
INSERT INTO item_definitions (id, name, description, category, icon, rarity) VALUES
-- Common 物品（普通）
('water_bottle', '纯净水', '一瓶还算干净的水', 'water', 'drop.fill', 'common'),
('dirty_water', '污水', '需要净化才能饮用', 'water', 'drop', 'common'),
('canned_beans', '罐头豆子', '高蛋白食物', 'food', 'takeoutbag.and.cup.and.straw.fill', 'common'),
('stale_bread', '陈面包', '有点硬但能吃', 'food', 'birthday.cake', 'common'),
('bandage', '绷带', '简单的止血工具', 'medical', 'bandage.fill', 'common'),
('scrap_metal', '废金属', '可用于制造', 'material', 'gearshape.fill', 'common'),
('wood_plank', '木板', '基础建材', 'material', 'square.stack.3d.up.fill', 'common'),
('rope', '绳索', '多用途工具', 'tool', 'line.diagonal', 'common'),
-- Rare 物品（稀有）
('purified_water', '净化水', '经过处理的安全饮用水', 'water', 'drop.circle.fill', 'rare'),
('canned_meat', '肉罐头', '珍贵的蛋白质来源', 'food', 'fork.knife', 'rare'),
('first_aid_kit', '急救包', '包含多种医疗用品', 'medical', 'cross.case.fill', 'rare'),
('electronic_parts', '电子零件', '稀有的科技材料', 'material', 'cpu.fill', 'rare'),
('multi_tool', '多功能刀', '实用的生存工具', 'tool', 'wrench.and.screwdriver.fill', 'rare'),
('flashlight', '手电筒', '黑暗中的光明', 'tool', 'flashlight.on.fill', 'rare'),
-- Epic 物品（史诗）
('antibiotics', '抗生素', '珍贵的药物', 'medical', 'pills.fill', 'epic'),
('solar_battery', '太阳能电池', '可再生能源', 'material', 'battery.100.bolt', 'epic'),
('water_filter', '净水器', '可持续净化水源', 'tool', 'drop.triangle.fill', 'epic'),
('survival_knife', '生存刀', '高品质求生装备', 'weapon', 'scissors', 'epic'),
('radio', '对讲机', '远距离通讯设备', 'tool', 'antenna.radiowaves.left.and.right', 'epic')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. exploration_sessions（探索会话记录表）
-- ============================================
CREATE TABLE IF NOT EXISTS exploration_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER NOT NULL,
    total_distance DOUBLE PRECISION NOT NULL,
    raw_distance DOUBLE PRECISION,
    point_count INTEGER NOT NULL,
    reward_tier TEXT NOT NULL,  -- 'none'/'bronze'/'silver'/'gold'/'diamond'
    items_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS exploration_sessions_user_id_idx ON exploration_sessions(user_id);
CREATE INDEX IF NOT EXISTS exploration_sessions_created_at_idx ON exploration_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS exploration_sessions_reward_tier_idx ON exploration_sessions(reward_tier);

-- RLS
ALTER TABLE exploration_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "exploration_sessions_select_own" ON exploration_sessions;
CREATE POLICY "exploration_sessions_select_own" ON exploration_sessions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "exploration_sessions_insert_own" ON exploration_sessions;
CREATE POLICY "exploration_sessions_insert_own" ON exploration_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 4. inventory_items（背包物品表）
-- ============================================
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    item_definition_id TEXT NOT NULL REFERENCES item_definitions(id),
    quality TEXT NOT NULL,  -- 'pristine'/'good'/'worn'/'damaged'/'ruined'
    quantity INTEGER NOT NULL DEFAULT 1,
    source_type TEXT NOT NULL DEFAULT 'exploration',  -- 'exploration'/'trade'/'craft'
    source_session_id UUID REFERENCES exploration_sessions(id),
    acquired_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS inventory_items_user_id_idx ON inventory_items(user_id);
CREATE INDEX IF NOT EXISTS inventory_items_item_definition_id_idx ON inventory_items(item_definition_id);
CREATE INDEX IF NOT EXISTS inventory_items_quality_idx ON inventory_items(quality);

-- 唯一约束：同用户、同物品、同品质只存一条（用于堆叠）
CREATE UNIQUE INDEX IF NOT EXISTS inventory_items_stack_idx
    ON inventory_items(user_id, item_definition_id, quality);

-- RLS
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inventory_items_select_own" ON inventory_items;
CREATE POLICY "inventory_items_select_own" ON inventory_items
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "inventory_items_insert_own" ON inventory_items;
CREATE POLICY "inventory_items_insert_own" ON inventory_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "inventory_items_update_own" ON inventory_items;
CREATE POLICY "inventory_items_update_own" ON inventory_items
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "inventory_items_delete_own" ON inventory_items;
CREATE POLICY "inventory_items_delete_own" ON inventory_items
    FOR DELETE USING (auth.uid() = user_id);

-- 更新时间戳触发器
CREATE OR REPLACE FUNCTION update_inventory_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS inventory_items_updated ON inventory_items;
CREATE TRIGGER inventory_items_updated
    BEFORE UPDATE ON inventory_items
    FOR EACH ROW EXECUTE FUNCTION update_inventory_timestamp();

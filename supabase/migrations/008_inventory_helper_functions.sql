-- =============================================
-- 库存辅助函数迁移
-- 版本: 008
-- 创建时间: 2026-01-27
-- 描述: 添加库存操作辅助函数，供交易系统调用
-- =============================================

-- =============================================
-- 1. 函数：从库存中移除指定物品（按定义ID）
-- =============================================

CREATE OR REPLACE FUNCTION remove_items_by_definition(
    p_user_id UUID,
    p_item_definition_id TEXT,
    p_quantity INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item RECORD;
    v_remaining INTEGER := p_quantity;
    v_to_remove INTEGER;
BEGIN
    -- 验证参数
    IF p_user_id IS NULL OR p_item_definition_id IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid parameters';
    END IF;

    -- 按品质从低到高（FIFO策略）移除物品
    -- 品质顺序: ruined < damaged < worn < good < pristine
    FOR v_item IN
        SELECT id, quantity, quality
        FROM inventory_items
        WHERE user_id = p_user_id
          AND LOWER(item_definition_id) = LOWER(p_item_definition_id)
        ORDER BY
            CASE quality
                WHEN 'ruined' THEN 1
                WHEN 'damaged' THEN 2
                WHEN 'worn' THEN 3
                WHEN 'good' THEN 4
                WHEN 'pristine' THEN 5
                ELSE 6
            END,
            acquired_at ASC
        FOR UPDATE
    LOOP
        EXIT WHEN v_remaining <= 0;

        v_to_remove := LEAST(v_remaining, v_item.quantity);

        IF v_item.quantity <= v_to_remove THEN
            -- 删除整个堆叠
            DELETE FROM inventory_items WHERE id = v_item.id;
            RAISE NOTICE 'Deleted stack: % (%) x%', p_item_definition_id, v_item.quality, v_item.quantity;
        ELSE
            -- 减少数量
            UPDATE inventory_items
            SET quantity = quantity - v_to_remove
            WHERE id = v_item.id;
            RAISE NOTICE 'Reduced quantity: % (%) % -> %',
                p_item_definition_id, v_item.quality, v_item.quantity, v_item.quantity - v_to_remove;
        END IF;

        v_remaining := v_remaining - v_to_remove;
    END LOOP;

    -- 检查是否成功移除所有数量
    IF v_remaining > 0 THEN
        RAISE EXCEPTION 'Insufficient items: % (needed %, short %)',
            p_item_definition_id, p_quantity, v_remaining;
    END IF;

    RETURN TRUE;
END;
$$
-- =============================================
-- 2. 函数：向库存添加物品
-- =============================================

CREATE OR REPLACE FUNCTION add_item_to_inventory(
    p_user_id UUID,
    p_item_definition_id TEXT,
    p_quantity INTEGER,
    p_quality TEXT DEFAULT 'good',
    p_rarity TEXT DEFAULT 'common',
    p_source TEXT DEFAULT 'trade'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item_id UUID;
    v_existing_item RECORD;
BEGIN
    -- 验证参数
    IF p_user_id IS NULL OR p_item_definition_id IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Invalid parameters';
    END IF;

    -- 验证品质值
    IF p_quality NOT IN ('pristine', 'good', 'worn', 'damaged', 'ruined') THEN
        RAISE EXCEPTION 'Invalid quality: %', p_quality;
    END IF;

    -- 尝试找到相同定义+品质+稀有度的现有堆叠
    SELECT id, quantity INTO v_existing_item
    FROM inventory_items
    WHERE user_id = p_user_id
      AND LOWER(item_definition_id) = LOWER(p_item_definition_id)
      AND quality = p_quality
      AND rarity = p_rarity
    ORDER BY acquired_at DESC
    LIMIT 1
    FOR UPDATE;

    IF v_existing_item IS NOT NULL THEN
        -- 增加现有堆叠的数量
        UPDATE inventory_items
        SET quantity = quantity + p_quantity
        WHERE id = v_existing_item.id;

        v_item_id := v_existing_item.id;
        RAISE NOTICE 'Increased existing stack: % (%) % -> %',
            p_item_definition_id, p_quality, v_existing_item.quantity, v_existing_item.quantity + p_quantity;
    ELSE
        -- 创建新堆叠
        INSERT INTO inventory_items (
            user_id,
            item_definition_id,
            quantity,
            quality,
            rarity,
            source,
            acquired_at
        ) VALUES (
            p_user_id,
            LOWER(p_item_definition_id),
            p_quantity,
            p_quality,
            p_rarity,
            p_source,
            now()
        )
        RETURNING id INTO v_item_id;

        RAISE NOTICE 'Created new stack: % (%) x%', p_item_definition_id, p_quality, p_quantity;
    END IF;

    RETURN v_item_id;
END;
$$
-- =============================================
-- 3. 添加注释
-- =============================================

COMMENT ON FUNCTION remove_items_by_definition IS '从库存中移除指定物品（按FIFO策略，品质从低到高）'
COMMENT ON FUNCTION add_item_to_inventory IS '向库存添加物品（自动堆叠相同定义+品质+稀有度）'
-- =============================================
-- 完成迁移
-- =============================================
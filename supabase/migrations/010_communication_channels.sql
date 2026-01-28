-- =====================================================
-- 010: Communication Channels System
-- 通讯频道系统 - 支持频道创建、订阅管理
-- =====================================================

-- =====================================================
-- 1. 频道表
-- =====================================================

CREATE TABLE IF NOT EXISTS public.communication_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    channel_type TEXT NOT NULL CHECK (channel_type IN ('official', 'public', 'walkie', 'camp', 'satellite')),
    channel_code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    member_count INT NOT NULL DEFAULT 1,
    location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================================================
-- 2. 频道订阅表
-- =====================================================

CREATE TABLE IF NOT EXISTS public.channel_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
    is_muted BOOLEAN NOT NULL DEFAULT false,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, channel_id)
);

-- =====================================================
-- 3. 索引
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_channels_creator ON public.communication_channels(creator_id);
CREATE INDEX IF NOT EXISTS idx_channels_type ON public.communication_channels(channel_type);
CREATE INDEX IF NOT EXISTS idx_channels_active ON public.communication_channels(is_active);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.channel_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_channel ON public.channel_subscriptions(channel_id);

-- =====================================================
-- 4. 启用 RLS
-- =====================================================

ALTER TABLE public.communication_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channel_subscriptions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. RLS 策略 - communication_channels
-- =====================================================

-- 任何人可查看活跃频道
CREATE POLICY "任何人可查看活跃频道" ON public.communication_channels FOR SELECT
TO authenticated USING (is_active = true);

-- 创建者可以添加频道
CREATE POLICY "创建者可以添加频道" ON public.communication_channels FOR INSERT
TO authenticated WITH CHECK (auth.uid() = creator_id);

-- 创建者可以更新自己的频道
CREATE POLICY "创建者可以更新频道" ON public.communication_channels FOR UPDATE
TO authenticated USING (auth.uid() = creator_id);

-- 创建者可以删除自己的频道
CREATE POLICY "创建者可以删除频道" ON public.communication_channels FOR DELETE
TO authenticated USING (auth.uid() = creator_id);

-- =====================================================
-- 6. RLS 策略 - channel_subscriptions
-- =====================================================

-- 用户可以查看自己的订阅
CREATE POLICY "用户可以查看自己的订阅" ON public.channel_subscriptions FOR SELECT
TO authenticated USING (auth.uid() = user_id);

-- 用户可以添加订阅
CREATE POLICY "用户可以添加订阅" ON public.channel_subscriptions FOR INSERT
TO authenticated WITH CHECK (auth.uid() = user_id);

-- 用户可以更新自己的订阅
CREATE POLICY "用户可以更新订阅" ON public.channel_subscriptions FOR UPDATE
TO authenticated USING (auth.uid() = user_id);

-- 用户可以删除自己的订阅
CREATE POLICY "用户可以删除订阅" ON public.channel_subscriptions FOR DELETE
TO authenticated USING (auth.uid() = user_id);

-- =====================================================
-- 7. RPC 函数 - 生成频道码
-- =====================================================

CREATE OR REPLACE FUNCTION generate_channel_code(p_channel_type TEXT)
RETURNS TEXT AS $$
DECLARE
    v_prefix TEXT;
    v_random TEXT;
    v_code TEXT;
    v_exists BOOLEAN;
BEGIN
    -- 根据频道类型设置前缀
    CASE p_channel_type
        WHEN 'official' THEN v_prefix := 'OFF-';
        WHEN 'public' THEN v_prefix := 'PUB-';
        WHEN 'walkie' THEN v_prefix := '438.';
        WHEN 'camp' THEN v_prefix := 'CAMP-';
        WHEN 'satellite' THEN v_prefix := 'SAT-';
        ELSE v_prefix := 'CH-';
    END CASE;

    -- 生成唯一码
    LOOP
        IF p_channel_type = 'walkie' THEN
            -- 对讲机频道使用三位数字格式 (438.XXX)
            v_random := LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0');
        ELSE
            -- 其他频道使用六位字母数字组合
            v_random := UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6));
        END IF;

        v_code := v_prefix || v_random;

        -- 检查是否已存在
        SELECT EXISTS(SELECT 1 FROM public.communication_channels WHERE channel_code = v_code) INTO v_exists;

        IF NOT v_exists THEN
            EXIT;
        END IF;
    END LOOP;

    RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. RPC 函数 - 创建频道并自动订阅
-- =====================================================

CREATE OR REPLACE FUNCTION create_channel_with_subscription(
    p_creator_id UUID,
    p_channel_type TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_channel_id UUID;
    v_channel_code TEXT;
BEGIN
    -- 生成频道码
    v_channel_code := generate_channel_code(p_channel_type);

    -- 创建频道
    INSERT INTO public.communication_channels (
        creator_id, channel_type, channel_code, name, description, member_count
    ) VALUES (
        p_creator_id, p_channel_type, v_channel_code, p_name, p_description, 1
    ) RETURNING id INTO v_channel_id;

    -- 自动订阅创建者
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (p_creator_id, v_channel_id);

    RETURN v_channel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. RPC 函数 - 订阅频道
-- =====================================================

CREATE OR REPLACE FUNCTION subscribe_to_channel(p_channel_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    -- 检查频道是否存在且活跃
    IF NOT EXISTS (SELECT 1 FROM public.communication_channels WHERE id = p_channel_id AND is_active = true) THEN
        RAISE EXCEPTION '频道不存在或已关闭';
    END IF;

    -- 检查是否已订阅
    IF EXISTS (SELECT 1 FROM public.channel_subscriptions WHERE user_id = v_user_id AND channel_id = p_channel_id) THEN
        RETURN true; -- 已订阅，直接返回成功
    END IF;

    -- 添加订阅
    INSERT INTO public.channel_subscriptions (user_id, channel_id)
    VALUES (v_user_id, p_channel_id);

    -- 更新成员数
    UPDATE public.communication_channels
    SET member_count = member_count + 1, updated_at = now()
    WHERE id = p_channel_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. RPC 函数 - 取消订阅频道
-- =====================================================

CREATE OR REPLACE FUNCTION unsubscribe_from_channel(p_channel_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_creator_id UUID;
BEGIN
    v_user_id := auth.uid();

    -- 获取频道创建者
    SELECT creator_id INTO v_creator_id FROM public.communication_channels WHERE id = p_channel_id;

    -- 创建者不能取消订阅自己的频道
    IF v_user_id = v_creator_id THEN
        RAISE EXCEPTION '频道创建者不能取消订阅';
    END IF;

    -- 检查是否已订阅
    IF NOT EXISTS (SELECT 1 FROM public.channel_subscriptions WHERE user_id = v_user_id AND channel_id = p_channel_id) THEN
        RETURN true; -- 未订阅，直接返回成功
    END IF;

    -- 删除订阅
    DELETE FROM public.channel_subscriptions
    WHERE user_id = v_user_id AND channel_id = p_channel_id;

    -- 更新成员数
    UPDATE public.communication_channels
    SET member_count = GREATEST(member_count - 1, 1), updated_at = now()
    WHERE id = p_channel_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. RPC 函数 - 删除频道
-- =====================================================

CREATE OR REPLACE FUNCTION delete_channel(p_channel_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_user_id UUID;
    v_creator_id UUID;
BEGIN
    v_user_id := auth.uid();

    -- 获取频道创建者
    SELECT creator_id INTO v_creator_id FROM public.communication_channels WHERE id = p_channel_id;

    -- 检查权限
    IF v_user_id != v_creator_id THEN
        RAISE EXCEPTION '只有频道创建者可以删除频道';
    END IF;

    -- 删除所有订阅（级联删除会自动处理，但显式删除更清晰）
    DELETE FROM public.channel_subscriptions WHERE channel_id = p_channel_id;

    -- 删除频道
    DELETE FROM public.communication_channels WHERE id = p_channel_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

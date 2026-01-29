-- Migration: 011_channel_messages
-- Day 34: Message System - Real-time Communication
--
-- This migration creates the channel_messages table and send_channel_message RPC function
-- for real-time messaging in communication channels.
--
-- IMPORTANT: Execute this SQL manually in Supabase Dashboard > SQL Editor

-- Enable PostGIS extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create messages table
CREATE TABLE IF NOT EXISTS public.channel_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id UUID NOT NULL REFERENCES public.communication_channels(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    sender_callsign TEXT,
    content TEXT NOT NULL,
    sender_location GEOGRAPHY(POINT, 4326),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Subscribers can view messages
CREATE POLICY "Subscribers can view channel messages" ON public.channel_messages
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.channel_subscriptions
            WHERE channel_subscriptions.channel_id = channel_messages.channel_id
            AND channel_subscriptions.user_id = auth.uid()
        )
    );

-- RLS Policy: Subscribers can send messages
CREATE POLICY "Subscribers can send messages" ON public.channel_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.channel_subscriptions
            WHERE channel_subscriptions.channel_id = channel_messages.channel_id
            AND channel_subscriptions.user_id = auth.uid()
        )
    );

-- Indexes for performance
CREATE INDEX idx_messages_channel ON public.channel_messages(channel_id);
CREATE INDEX idx_messages_sender ON public.channel_messages(sender_id);
CREATE INDEX idx_messages_created ON public.channel_messages(created_at DESC);

-- CRITICAL: Enable Realtime Publication for the messages table
-- This allows Supabase Realtime to broadcast INSERT events
ALTER PUBLICATION supabase_realtime ADD TABLE channel_messages;

-- Create the send_channel_message RPC function
CREATE OR REPLACE FUNCTION send_channel_message(
    p_channel_id UUID,
    p_content TEXT,
    p_latitude DOUBLE PRECISION DEFAULT NULL,
    p_longitude DOUBLE PRECISION DEFAULT NULL,
    p_device_type TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_message_id UUID;
    v_sender_id UUID;
    v_callsign TEXT;
    v_location GEOGRAPHY(POINT, 4326);
    v_metadata JSONB;
BEGIN
    v_sender_id := auth.uid();

    -- Check if user is subscribed to the channel
    IF NOT EXISTS (
        SELECT 1 FROM public.channel_subscriptions
        WHERE channel_id = p_channel_id AND user_id = v_sender_id
    ) THEN
        RAISE EXCEPTION 'You must subscribe to send messages';
    END IF;

    -- Get user callsign from profiles (using username field)
    BEGIN
        SELECT COALESCE(username, 'Anonymous')
        INTO v_callsign
        FROM public.profiles
        WHERE id = v_sender_id;
    EXCEPTION
        WHEN undefined_table THEN
            v_callsign := 'Anonymous';
    END;

    IF v_callsign IS NULL THEN
        v_callsign := 'Anonymous';
    END IF;

    -- Create location point if coordinates provided
    IF p_latitude IS NOT NULL AND p_longitude IS NOT NULL THEN
        v_location := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::GEOGRAPHY;
    END IF;

    -- Build metadata JSON
    v_metadata := jsonb_build_object('device_type', COALESCE(p_device_type, 'unknown'));

    -- Insert the message
    INSERT INTO public.channel_messages (
        channel_id, sender_id, sender_callsign, content, sender_location, metadata
    )
    VALUES (
        p_channel_id, v_sender_id, v_callsign, p_content, v_location, v_metadata
    )
    RETURNING message_id INTO v_message_id;

    RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify Realtime publication is configured correctly
-- Run this to check: SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

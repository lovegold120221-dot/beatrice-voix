-- ── Beatrice Local Seed Data ──
-- Safe for local/dev only. Does not override live dynamic data.

-- Default local tenant
INSERT INTO app_tenants (id, name, slug, settings)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Local Dev',
  'local-dev',
  '{"environment": "development", "features": {"memory_v2": true, "eburon_whitelist": true}}'::jsonb
) ON CONFLICT (slug) DO NOTHING;

-- Default local developer user (Firebase UID placeholder)
INSERT INTO app_users (id, tenant_id, firebase_uid, email, display_name)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'local-dev-firebase-uid',
  'dev@local.eburon.ai',
  'Local Developer'
) ON CONFLICT (email) DO NOTHING;

-- Default profile
INSERT INTO user_profiles (user_id, tenant_id, persona_name, language, timezone)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'Beatrice',
  'en',
  'Europe/Brussels'
) ON CONFLICT DO NOTHING;

-- Eburon provider settings
INSERT INTO eburon_provider_settings (tenant_id, provider_key, is_enabled, config)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'eburon_core', true, '{"type": "primary", "priority": 1}'::jsonb)
ON CONFLICT (provider_key) DO NOTHING;

-- Eburon model whitelist
INSERT INTO eburon_model_whitelist (tenant_id, model_alias, is_active)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'eburon_text', true),
  ('00000000-0000-0000-0000-000000000001', 'eburon_realtime_voice', true),
  ('00000000-0000-0000-0000-000000000001', 'eburon_vision', true),
  ('00000000-0000-0000-0000-000000000001', 'eburon_worker', true)
ON CONFLICT (model_alias) DO NOTHING;

-- Beatrice default app settings
INSERT INTO app_settings (user_id, settings_key, settings_value)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  'beatrice_defaults',
  '{
    "memory_provider": "local_supabase",
    "dynamic_memory": true,
    "static_memory_disabled": true,
    "eburon_provider": "eburon_core"
  }'::jsonb
) ON CONFLICT (user_id, settings_key) DO NOTHING;

-- Default WhatsApp sync permissions (all false, user must grant)
INSERT INTO whatsapp_sync_permissions (user_id, permission_key, is_granted)
SELECT
  '00000000-0000-0000-0000-000000000002',
  p.key,
  false
FROM (VALUES
  ('delegated_send'),
  ('delegated_receive'),
  ('delegated_read_chats'),
  ('delegated_read_messages'),
  ('delegated_read_contacts'),
  ('delegated_media_download'),
  ('delegated_profile_manage'),
  ('delegated_group_manage'),
  ('delegated_broadcast')
) AS p(key)
ON CONFLICT (user_id, permission_key) DO NOTHING;

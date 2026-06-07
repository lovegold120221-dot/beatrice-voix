-- ── Beatrice Core Schema ──
-- Run via: supabase migration up

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "extensions";

-- 2. Tenants & Users
CREATE TABLE IF NOT EXISTS app_tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  settings JSONB DEFAULT '{}'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  firebase_uid TEXT UNIQUE,
  email TEXT UNIQUE,
  display_name TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_app_users_tenant ON app_users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_app_users_firebase ON app_users(firebase_uid);

-- 3. User Profiles
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  persona_name TEXT DEFAULT 'Beatrice',
  custom_prompt TEXT DEFAULT '',
  selected_voice TEXT DEFAULT 'Aoede',
  user_title TEXT DEFAULT 'Boss',
  language TEXT DEFAULT 'en',
  theme TEXT DEFAULT 'dark',
  context_size INTEGER DEFAULT 20,
  censorship_enabled BOOLEAN DEFAULT false,
  ambient_enabled BOOLEAN DEFAULT false,
  ambient_volume REAL DEFAULT 0.15,
  timezone TEXT,
  avatar_url TEXT,
  settings JSONB DEFAULT '{}'::jsonb,
  last_seen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user ON user_profiles(user_id);

-- 4. Sessions
CREATE TABLE IF NOT EXISTS beatrice_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  session_label TEXT,
  is_active BOOLEAN DEFAULT true,
  message_count INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT now(),
  ended_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON beatrice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON beatrice_sessions(user_id, is_active) WHERE is_active = true;

-- 5. Conversation Threads
CREATE TABLE IF NOT EXISTS beatrice_conversation_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  session_id UUID REFERENCES beatrice_sessions(id) ON DELETE SET NULL,
  title TEXT,
  is_archived BOOLEAN DEFAULT false,
  message_count INTEGER DEFAULT 0,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_threads_user ON beatrice_conversation_threads(user_id);
CREATE INDEX IF NOT EXISTS idx_threads_session ON beatrice_conversation_threads(session_id);

-- 6. Messages
CREATE TABLE IF NOT EXISTS beatrice_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  session_id UUID REFERENCES beatrice_sessions(id) ON DELETE SET NULL,
  thread_id UUID REFERENCES beatrice_conversation_threads(id) ON DELETE SET NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'model', 'system', 'tool')),
  text TEXT NOT NULL,
  tool_name TEXT,
  tool_input JSONB,
  tool_result JSONB,
  attachment_url TEXT,
  attachment_name TEXT,
  attachment_type TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_user ON beatrice_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_session ON beatrice_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_thread ON beatrice_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON beatrice_messages(created_at DESC);

-- 7. Memory Records
CREATE TABLE IF NOT EXISTS beatrice_memory_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  session_id UUID REFERENCES beatrice_sessions(id) ON DELETE SET NULL,
  conversation_id UUID,
  message_id UUID REFERENCES beatrice_messages(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  summary TEXT,
  memory_type TEXT DEFAULT 'fact' CHECK (memory_type IN ('fact', 'preference', 'event', 'context', 'contact', 'concept', 'summary')),
  source TEXT DEFAULT 'manual_note',
  source_id TEXT,
  tags TEXT[] DEFAULT '{}',
  importance_score REAL DEFAULT 1.0,
  recency_score REAL DEFAULT 1.0,
  confidence_score REAL DEFAULT 1.0,
  event_timestamp TIMESTAMPTZ,
  source_timestamp TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ,
  is_stale BOOLEAN DEFAULT false,
  supersedes_memory_id UUID REFERENCES beatrice_memory_records(id) ON DELETE SET NULL,
  superseded_by_memory_id UUID REFERENCES beatrice_memory_records(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_memory_user ON beatrice_memory_records(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_user_stale ON beatrice_memory_records(user_id, is_stale);
CREATE INDEX IF NOT EXISTS idx_memory_source ON beatrice_memory_records(source);
CREATE INDEX IF NOT EXISTS idx_memory_session ON beatrice_memory_records(session_id);
CREATE INDEX IF NOT EXISTS idx_memory_importance ON beatrice_memory_records(importance_score DESC);
CREATE INDEX IF NOT EXISTS idx_memory_event_time ON beatrice_memory_records(event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_memory_recency ON beatrice_memory_records(recency_score DESC);
CREATE INDEX IF NOT EXISTS idx_memory_expires ON beatrice_memory_records(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_memory_tags ON beatrice_memory_records USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_memory_content_trgm ON beatrice_memory_records USING GIN(content gin_trgm_ops);

-- 8. Memory Summaries
CREATE TABLE IF NOT EXISTS beatrice_memory_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  session_id UUID REFERENCES beatrice_sessions(id) ON DELETE SET NULL,
  summary TEXT NOT NULL,
  covered_start_at TIMESTAMPTZ,
  covered_end_at TIMESTAMPTZ,
  source_message_ids UUID[] DEFAULT '{}',
  source_message_count INTEGER DEFAULT 0,
  generated_at TIMESTAMPTZ DEFAULT now(),
  is_complete BOOLEAN DEFAULT false,
  is_stale BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_memory_summaries_user ON beatrice_memory_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_summaries_session ON beatrice_memory_summaries(session_id);

-- 9. Memory Embeddings
CREATE TABLE IF NOT EXISTS beatrice_memory_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  memory_record_id UUID REFERENCES beatrice_memory_records(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  embedding vector(768),
  model_source TEXT DEFAULT 'eburon_text',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_embeddings_memory ON beatrice_memory_embeddings(memory_record_id);
CREATE INDEX IF NOT EXISTS idx_embeddings_user ON beatrice_memory_embeddings(user_id);

-- 10. Contact Profiles
CREATE TABLE IF NOT EXISTS beatrice_contact_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  display_name TEXT,
  phone_number TEXT,
  email TEXT,
  company TEXT,
  role TEXT,
  notes TEXT,
  tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}'::jsonb,
  last_contacted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_contacts_user ON beatrice_contact_profiles(user_id);

-- 11. WhatsApp Integrations
CREATE TABLE IF NOT EXISTS whatsapp_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  provider TEXT DEFAULT 'linked_device' CHECK (provider IN ('linked_device', 'cloud_api')),
  phone_number TEXT,
  wa_phone TEXT,
  display_name TEXT,
  status TEXT DEFAULT 'disconnected' CHECK (status IN ('disconnected', 'connecting', 'paired', 'error')),
  config JSONB DEFAULT '{}'::jsonb,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_wa_integrations_user ON whatsapp_integrations(user_id);

-- 12. WhatsApp Contacts
CREATE TABLE IF NOT EXISTS whatsapp_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  integration_id UUID REFERENCES whatsapp_integrations(id) ON DELETE SET NULL,
  jid TEXT NOT NULL,
  name TEXT,
  notify TEXT,
  phone_number TEXT,
  is_business BOOLEAN DEFAULT false,
  is_group BOOLEAN DEFAULT false,
  profile_pic_url TEXT,
  is_restricted BOOLEAN DEFAULT false,
  last_seen_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(user_id, jid)
);

CREATE INDEX IF NOT EXISTS idx_wa_contacts_user ON whatsapp_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_wa_contacts_jid ON whatsapp_contacts(jid);

-- 13. WhatsApp Threads
CREATE TABLE IF NOT EXISTS whatsapp_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  integration_id UUID REFERENCES whatsapp_integrations(id) ON DELETE SET NULL,
  contact_jid TEXT NOT NULL,
  contact_name TEXT,
  is_group BOOLEAN DEFAULT false,
  is_restricted BOOLEAN DEFAULT false,
  last_message_at TIMESTAMPTZ,
  message_count INTEGER DEFAULT 0,
  unread_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_wa_threads_user ON whatsapp_threads(user_id);
CREATE INDEX IF NOT EXISTS idx_wa_threads_jid ON whatsapp_threads(contact_jid);

-- 14. WhatsApp Messages
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  integration_id UUID REFERENCES whatsapp_integrations(id) ON DELETE SET NULL,
  thread_id UUID REFERENCES whatsapp_threads(id) ON DELETE SET NULL,
  wa_message_id TEXT,
  contact_jid TEXT NOT NULL,
  from_me BOOLEAN DEFAULT false,
  message_type TEXT,
  text TEXT,
  media_url TEXT,
  media_mime_type TEXT,
  media_size INTEGER,
  media_duration REAL,
  media_filename TEXT,
  has_media BOOLEAN DEFAULT false,
  is_forwarded BOOLEAN DEFAULT false,
  reply_to_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  source_timestamp TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wa_messages_user ON whatsapp_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_wa_messages_thread ON whatsapp_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_wa_messages_jid ON whatsapp_messages(contact_jid);
CREATE INDEX IF NOT EXISTS idx_wa_messages_wa_id ON whatsapp_messages(wa_message_id);

-- 15. WhatsApp Media
CREATE TABLE IF NOT EXISTS whatsapp_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  message_id UUID REFERENCES whatsapp_messages(id) ON DELETE SET NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT,
  file_size INTEGER,
  file_name TEXT,
  width INTEGER,
  height INTEGER,
  duration REAL,
  is_downloaded BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wa_media_user ON whatsapp_media(user_id);
CREATE INDEX IF NOT EXISTS idx_wa_media_message ON whatsapp_media(message_id);

-- 16. WhatsApp Extracted Content (OCR, transcription, document text)
CREATE TABLE IF NOT EXISTS whatsapp_extracted_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  message_id UUID REFERENCES whatsapp_messages(id) ON DELETE SET NULL,
  media_id UUID REFERENCES whatsapp_media(id) ON DELETE SET NULL,
  content_type TEXT CHECK (content_type IN ('ocr', 'transcription', 'document_text', 'caption')),
  extracted_text TEXT NOT NULL,
  confidence REAL,
  processing_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wa_extracted_message ON whatsapp_extracted_content(message_id);

-- 17. WhatsApp Sync Permissions
CREATE TABLE IF NOT EXISTS whatsapp_sync_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  integration_id UUID REFERENCES whatsapp_integrations(id) ON DELETE SET NULL,
  permission_key TEXT NOT NULL,
  is_granted BOOLEAN DEFAULT false,
  granted_by TEXT DEFAULT 'user',
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, permission_key)
);

CREATE INDEX IF NOT EXISTS idx_wa_permissions_user ON whatsapp_sync_permissions(user_id);

-- 18. WhatsApp Sync Jobs
CREATE TABLE IF NOT EXISTS whatsapp_sync_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  integration_id UUID REFERENCES whatsapp_integrations(id) ON DELETE SET NULL,
  job_type TEXT NOT NULL CHECK (job_type IN ('initial_sync', 'incremental_sync', 'media_download', 'contact_sync', 'extraction')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
  progress REAL DEFAULT 0,
  total_items INTEGER DEFAULT 0,
  processed_items INTEGER DEFAULT 0,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wa_sync_jobs_user ON whatsapp_sync_jobs(user_id);

-- 19. App Media Files
CREATE TABLE IF NOT EXISTS app_media_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  storage_bucket TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  original_name TEXT,
  mime_type TEXT,
  file_size INTEGER,
  width INTEGER,
  height INTEGER,
  duration REAL,
  is_public BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_media_user ON app_media_files(user_id);
CREATE INDEX IF NOT EXISTS idx_media_bucket ON app_media_files(storage_bucket);

-- 20. App Documents
CREATE TABLE IF NOT EXISTS app_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  document_type TEXT,
  content TEXT,
  template_name TEXT,
  storage_path TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_documents_user ON app_documents(user_id);

-- 21. Audit Logs
CREATE TABLE IF NOT EXISTS app_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON app_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON app_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_created ON app_audit_logs(created_at DESC);

-- 22. App Settings
CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  settings_key TEXT NOT NULL,
  settings_value JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, settings_key)
);

CREATE INDEX IF NOT EXISTS idx_settings_user ON app_settings(user_id);

-- 23. Eburon Provider Settings
CREATE TABLE IF NOT EXISTS eburon_provider_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  provider_key TEXT NOT NULL UNIQUE CHECK (provider_key IN ('eburon_core', 'eburon_text', 'eburon_realtime_voice', 'eburon_vision', 'eburon_worker')),
  is_enabled BOOLEAN DEFAULT true,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 24. Eburon Model Whitelist
CREATE TABLE IF NOT EXISTS eburon_model_whitelist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  model_alias TEXT NOT NULL UNIQUE CHECK (model_alias IN ('eburon_text', 'eburon_realtime_voice', 'eburon_vision', 'eburon_worker')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 25. Eburon Request Audit Logs
CREATE TABLE IF NOT EXISTS eburon_request_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES app_tenants(id) ON DELETE SET NULL,
  user_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  model_alias TEXT NOT NULL,
  request_type TEXT NOT NULL,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  duration_ms INTEGER,
  is_successful BOOLEAN DEFAULT true,
  error_message TEXT,
  request_metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_eburon_audit_user ON eburon_request_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_eburon_audit_model ON eburon_request_audit_logs(model_alias);
CREATE INDEX IF NOT EXISTS idx_eburon_audit_created ON eburon_request_audit_logs(created_at DESC);

-- ── RLS Policies ──
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_conversation_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_memory_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_memory_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_memory_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE beatrice_contact_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_extracted_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_sync_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_sync_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_media_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE eburon_provider_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE eburon_model_whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE eburon_request_audit_logs ENABLE ROW LEVEL SECURITY;

-- Tenant-scoped: user sees own records
CREATE POLICY "tenant_user_select" ON app_users FOR SELECT USING (id = auth.uid()::uuid OR tenant_id = (SELECT tenant_id FROM app_users WHERE id = auth.uid()::uuid));
CREATE POLICY "tenant_user_insert" ON app_users FOR INSERT WITH CHECK (true);
CREATE POLICY "tenant_user_update" ON app_users FOR UPDATE USING (id = auth.uid()::uuid);

CREATE POLICY "user_profile_self" ON user_profiles FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "user_profile_self_insert" ON user_profiles FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "user_profile_self_update" ON user_profiles FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "sessions_self" ON beatrice_sessions FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "sessions_self_insert" ON beatrice_sessions FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "sessions_self_update" ON beatrice_sessions FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "threads_self" ON beatrice_conversation_threads FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "threads_self_insert" ON beatrice_conversation_threads FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "threads_self_update" ON beatrice_conversation_threads FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "messages_self" ON beatrice_messages FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "messages_self_insert" ON beatrice_messages FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "memory_self" ON beatrice_memory_records FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "memory_self_insert" ON beatrice_memory_records FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "memory_self_update" ON beatrice_memory_records FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "memory_summaries_self" ON beatrice_memory_summaries FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "embeddings_self" ON beatrice_memory_embeddings FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "contacts_self" ON beatrice_contact_profiles FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "contacts_self_insert" ON beatrice_contact_profiles FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "contacts_self_update" ON beatrice_contact_profiles FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "wa_integrations_self" ON whatsapp_integrations FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "wa_integrations_self_insert" ON whatsapp_integrations FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "wa_contacts_self" ON whatsapp_contacts FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "wa_contacts_self_insert" ON whatsapp_contacts FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "wa_threads_self" ON whatsapp_threads FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "wa_threads_self_insert" ON whatsapp_threads FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "wa_messages_self" ON whatsapp_messages FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "wa_messages_self_insert" ON whatsapp_messages FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "wa_media_self" ON whatsapp_media FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "wa_extracted_self" ON whatsapp_extracted_content FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "wa_permissions_self" ON whatsapp_sync_permissions FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "wa_permissions_self_insert" ON whatsapp_sync_permissions FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "wa_jobs_self" ON whatsapp_sync_jobs FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "media_self" ON app_media_files FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "documents_self" ON app_documents FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "documents_self_insert" ON app_documents FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "audit_self" ON app_audit_logs FOR SELECT USING (user_id = auth.uid()::uuid);

CREATE POLICY "settings_self" ON app_settings FOR SELECT USING (user_id = auth.uid()::uuid);
CREATE POLICY "settings_self_insert" ON app_settings FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);
CREATE POLICY "settings_self_update" ON app_settings FOR UPDATE USING (user_id = auth.uid()::uuid);

CREATE POLICY "eburon_provider_admin" ON eburon_provider_settings FOR SELECT USING (true);
CREATE POLICY "eburon_model_whitelist_read" ON eburon_model_whitelist FOR SELECT USING (true);
CREATE POLICY "eburon_audit_insert" ON eburon_request_audit_logs FOR INSERT WITH CHECK (true);

-- Service role sees all (bypasses RLS via service_role key)
ALTER TABLE app_tenants FORCE ROW LEVEL SECURITY;
CREATE POLICY "tenant_admin_all" ON app_tenants FOR ALL USING (true);

-- Service role policies (service_role key bypasses all RLS automatically)

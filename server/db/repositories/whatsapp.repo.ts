// ── WhatsApp Repository ──
import { adminClient } from '../admin';

export async function upsertWhatsAppIntegration(userId: string, data: {
  provider?: string;
  phone_number?: string;
  wa_phone?: string;
  display_name?: string;
  status?: string;
  config?: Record<string, any>;
}) {
  const { data: existing } = await adminClient
    .from('whatsapp_integrations')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (existing) {
    const { error } = await adminClient
      .from('whatsapp_integrations')
      .update({
        ...data,
        last_synced_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', existing.id);

    if (error) return { ok: false, error: error.message };
    return { ok: true, id: existing.id };
  }

  const { data: inserted, error } = await adminClient
    .from('whatsapp_integrations')
    .insert({
      user_id: userId,
      provider: data.provider || 'linked_device',
      phone_number: data.phone_number,
      wa_phone: data.wa_phone,
      display_name: data.display_name,
      status: data.status || 'disconnected',
      config: data.config || {},
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function upsertWhatsAppContact(userId: string, jid: string, data: {
  name?: string;
  notify?: string;
  phone_number?: string;
  is_business?: boolean;
  is_group?: boolean;
  profile_pic_url?: string;
  is_restricted?: boolean;
}) {
  const { data: existing } = await adminClient
    .from('whatsapp_contacts')
    .select('id')
    .eq('user_id', userId)
    .eq('jid', jid)
    .maybeSingle();

  const payload = {
    ...data,
    last_seen_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  if (existing) {
    const { error } = await adminClient
      .from('whatsapp_contacts')
      .update(payload)
      .eq('id', existing.id);

    if (error) return { ok: false, error: error.message };
    return { ok: true, id: existing.id };
  }

  const { data: inserted, error } = await adminClient
    .from('whatsapp_contacts')
    .insert({ user_id: userId, jid, ...payload })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function insertWhatsAppMessage(userId: string, data: {
  thread_id?: string;
  wa_message_id?: string;
  contact_jid: string;
  from_me?: boolean;
  message_type?: string;
  text?: string;
  media_url?: string;
  media_mime_type?: string;
  media_size?: number;
  media_duration?: number;
  media_filename?: string;
  has_media?: boolean;
  is_forwarded?: boolean;
  reply_to_id?: string;
  metadata?: Record<string, any>;
  source_timestamp?: string;
}) {
  const { data: inserted, error } = await adminClient
    .from('whatsapp_messages')
    .insert({
      user_id: userId,
      contact_jid: data.contact_jid,
      thread_id: data.thread_id,
      wa_message_id: data.wa_message_id,
      from_me: data.from_me ?? false,
      message_type: data.message_type,
      text: data.text,
      media_url: data.media_url,
      media_mime_type: data.media_mime_type,
      media_size: data.media_size,
      media_duration: data.media_duration,
      media_filename: data.media_filename,
      has_media: data.has_media ?? false,
      is_forwarded: data.is_forwarded ?? false,
      reply_to_id: data.reply_to_id,
      metadata: data.metadata || {},
      source_timestamp: data.source_timestamp,
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function upsertWhatsAppThread(userId: string, contactJid: string, data: {
  contact_name?: string;
  is_group?: boolean;
  is_restricted?: boolean;
  last_message_at?: string;
  message_count?: number;
  unread_count?: number;
}) {
  const { data: existing } = await adminClient
    .from('whatsapp_threads')
    .select('id')
    .eq('user_id', userId)
    .eq('contact_jid', contactJid)
    .maybeSingle();

  const payload = { ...data, updated_at: new Date().toISOString() };

  if (existing) {
    const { error } = await adminClient
      .from('whatsapp_threads')
      .update(payload)
      .eq('id', existing.id);

    if (error) return { ok: false, error: error.message };
    return { ok: true, id: existing.id };
  }

  const { data: inserted, error } = await adminClient
    .from('whatsapp_threads')
    .insert({ user_id: userId, contact_jid: contactJid, ...payload })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function insertWhatsAppMedia(userId: string, data: {
  message_id?: string;
  storage_path: string;
  mime_type?: string;
  file_size?: number;
  file_name?: string;
  width?: number;
  height?: number;
  duration?: number;
  is_downloaded?: boolean;
}) {
  const { data: inserted, error } = await adminClient
    .from('whatsapp_media')
    .insert({
      user_id: userId,
      message_id: data.message_id,
      storage_path: data.storage_path,
      mime_type: data.mime_type,
      file_size: data.file_size,
      file_name: data.file_name,
      width: data.width,
      height: data.height,
      duration: data.duration,
      is_downloaded: data.is_downloaded ?? true,
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function createSyncPermission(userId: string, permissionKey: string) {
  const { error } = await adminClient
    .from('whatsapp_sync_permissions')
    .insert({
      user_id: userId,
      permission_key: permissionKey,
      is_granted: false,
    });

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function getDefaultSyncPermissions(userId: string) {
  const { data, error } = await adminClient
    .from('whatsapp_sync_permissions')
    .select('permission_key, is_granted')
    .eq('user_id', userId);

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

// ── Media Repository ──
import { adminClient } from '../admin';

export async function insertMediaFile(data: {
  user_id: string;
  tenant_id?: string;
  storage_bucket: string;
  storage_path: string;
  original_name?: string;
  mime_type?: string;
  file_size?: number;
  width?: number;
  height?: number;
  duration?: number;
  is_public?: boolean;
  metadata?: Record<string, any>;
}) {
  const { data: inserted, error } = await adminClient
    .from('app_media_files')
    .insert({
      user_id: data.user_id,
      tenant_id: data.tenant_id,
      storage_bucket: data.storage_bucket,
      storage_path: data.storage_path,
      original_name: data.original_name,
      mime_type: data.mime_type,
      file_size: data.file_size,
      width: data.width,
      height: data.height,
      duration: data.duration,
      is_public: data.is_public ?? false,
      metadata: data.metadata || {},
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: inserted.id };
}

export async function getMediaFile(id: string) {
  const { data, error } = await adminClient
    .from('app_media_files')
    .select('*')
    .eq('id', id)
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || null };
}

export async function listUserMedia(userId: string, bucket?: string) {
  let query = adminClient
    .from('app_media_files')
    .select('id, storage_bucket, storage_path, original_name, mime_type, file_size, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (bucket) {
    query = query.eq('storage_bucket', bucket);
  }

  const { data, error } = await query;
  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

export async function deleteMediaFile(id: string) {
  const { error } = await adminClient
    .from('app_media_files')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id);

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

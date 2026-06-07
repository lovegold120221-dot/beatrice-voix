// ── Settings Repository ──
import { adminClient } from '../admin';

export async function getAppSetting(userId: string, key: string) {
  const { data, error } = await adminClient
    .from('app_settings')
    .select('settings_value')
    .eq('user_id', userId)
    .eq('settings_key', key)
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  return { ok: true, value: data?.settings_value || null };
}

export async function setAppSetting(userId: string, key: string, value: Record<string, any>) {
  const { data: existing } = await adminClient
    .from('app_settings')
    .select('id')
    .eq('user_id', userId)
    .eq('settings_key', key)
    .maybeSingle();

  if (existing) {
    const { error } = await adminClient
      .from('app_settings')
      .update({ settings_value: value, updated_at: new Date().toISOString() })
      .eq('id', existing.id);

    if (error) return { ok: false, error: error.message };
    return { ok: true };
  }

  const { error } = await adminClient
    .from('app_settings')
    .insert({ user_id: userId, settings_key: key, settings_value: value });

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function getUserProfile(userId: string) {
  const { data, error } = await adminClient
    .from('user_profiles')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || null };
}

export async function upsertUserProfile(userId: string, data: Record<string, any>) {
  const { data: existing } = await adminClient
    .from('user_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  const payload = { ...data, updated_at: new Date().toISOString() };

  if (existing) {
    const { error } = await adminClient
      .from('user_profiles')
      .update(payload)
      .eq('id', existing.id);

    if (error) return { ok: false, error: error.message };
    return { ok: true };
  }

  const { error } = await adminClient
    .from('user_profiles')
    .insert({ user_id: userId, ...payload });

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

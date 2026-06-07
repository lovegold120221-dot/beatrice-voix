// ── Eburon Repository ──
import { adminClient } from '../admin';

export async function getEburonProviderSettings() {
  const { data, error } = await adminClient
    .from('eburon_provider_settings')
    .select('*')
    .eq('is_enabled', true)
    .order('created_at', { ascending: true });

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

export async function getEburonModelWhitelist() {
  const { data, error } = await adminClient
    .from('eburon_model_whitelist')
    .select('model_alias, is_active')
    .eq('is_active', true);

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

export async function validateEburonModelFromDb(modelAlias: string): Promise<boolean> {
  const { data } = await adminClient
    .from('eburon_model_whitelist')
    .select('id')
    .eq('model_alias', modelAlias)
    .eq('is_active', true)
    .maybeSingle();

  return !!data;
}

export async function logEburonRequest(entry: {
  user_id?: string;
  tenant_id?: string;
  model_alias: string;
  request_type: string;
  input_tokens?: number;
  output_tokens?: number;
  duration_ms?: number;
  is_successful?: boolean;
  error_message?: string;
  request_metadata?: Record<string, any>;
}) {
  const { error } = await adminClient
    .from('eburon_request_audit_logs')
    .insert({
      user_id: entry.user_id,
      tenant_id: entry.tenant_id,
      model_alias: entry.model_alias,
      request_type: entry.request_type,
      input_tokens: entry.input_tokens ?? 0,
      output_tokens: entry.output_tokens ?? 0,
      duration_ms: entry.duration_ms ?? 0,
      is_successful: entry.is_successful ?? true,
      error_message: entry.error_message,
      request_metadata: entry.request_metadata || {},
    });

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

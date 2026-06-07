// ── Server-side Supabase admin client (service_role — backend jobs only) ──
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!serviceRoleKey) {
  console.warn('[DB] SUPABASE_SERVICE_ROLE_KEY not set — admin operations will fail');
}

export const adminClient = createClient(supabaseUrl, serviceRoleKey || 'placeholder');

export function getAdminClient() {
  return adminClient;
}

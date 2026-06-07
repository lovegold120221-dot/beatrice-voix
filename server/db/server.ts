// ── Server-side Supabase client (anon role for public operations) ──
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY || '';

if (!supabaseAnonKey) {
  console.warn('[DB] SUPABASE_ANON_KEY not set — using dummy key for local dev');
}

export const supabaseClient = createClient(supabaseUrl, supabaseAnonKey || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder');

export function getSupabaseClient() {
  return supabaseClient;
}

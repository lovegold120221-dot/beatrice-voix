// ── Memory Repository ──
import { adminClient } from '../admin';

export interface MemoryRecord {
  id?: string;
  user_id: string;
  tenant_id?: string;
  session_id?: string;
  conversation_id?: string;
  message_id?: string;
  content: string;
  summary?: string;
  memory_type?: 'fact' | 'preference' | 'event' | 'context' | 'contact' | 'concept' | 'summary';
  source?: string;
  source_id?: string;
  tags?: string[];
  importance_score?: number;
  recency_score?: number;
  confidence_score?: number;
  event_timestamp?: string;
  source_timestamp?: string;
  is_stale?: boolean;
  supersedes_memory_id?: string;
  metadata?: Record<string, any>;
}

export async function saveMemoryRecord(record: MemoryRecord) {
  const { data, error } = await adminClient
    .from('beatrice_memory_records')
    .insert({
      user_id: record.user_id,
      tenant_id: record.tenant_id,
      session_id: record.session_id,
      conversation_id: record.conversation_id,
      message_id: record.message_id,
      content: record.content,
      summary: record.summary,
      memory_type: record.memory_type || 'fact',
      source: record.source || 'manual_note',
      source_id: record.source_id,
      tags: record.tags || [],
      importance_score: record.importance_score ?? 1,
      recency_score: record.recency_score ?? 1,
      confidence_score: record.confidence_score ?? 1,
      event_timestamp: record.event_timestamp,
      source_timestamp: record.source_timestamp,
      is_stale: record.is_stale ?? false,
      supersedes_memory_id: record.supersedes_memory_id,
      metadata: record.metadata || {},
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: data.id };
}

export async function getLatestConversationContext(userId: string, limit = 10) {
  const { data, error } = await adminClient
    .from('beatrice_memory_records')
    .select('id, content, memory_type, tags, importance_score, created_at, event_timestamp')
    .eq('user_id', userId)
    .eq('is_stale', false)
    .is('superseded_by_memory_id', null)
    .order('recency_score', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

export async function getRelevantLongTermMemory(userId: string, query: string, limit = 5) {
  const { data, error } = await adminClient
    .from('beatrice_memory_records')
    .select('id, content, summary, memory_type, tags, importance_score, confidence_score, created_at')
    .eq('user_id', userId)
    .eq('is_stale', false)
    .is('superseded_by_memory_id', null)
    .or(`content.ilike.%${query}%,tags.cs.{${query}}`)
    .order('importance_score', { ascending: false })
    .limit(limit);

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data || [] };
}

export async function markMemoryStale(memoryId: string) {
  const { error } = await adminClient
    .from('beatrice_memory_records')
    .update({ is_stale: true, updated_at: new Date().toISOString() })
    .eq('id', memoryId);

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function getLatestSessionSummary(userId: string, sessionId?: string) {
  let query = adminClient
    .from('beatrice_memory_summaries')
    .select('id, summary, covered_start_at, covered_end_at, source_message_count, is_complete, generated_at')
    .eq('user_id', userId)
    .eq('is_stale', false)
    .order('generated_at', { ascending: false })
    .limit(1);

  if (sessionId) {
    query = query.eq('session_id', sessionId);
  }

  const { data, error } = await query;
  if (error) return { ok: false, error: error.message };
  return { ok: true, data: data?.[0] || null };
}

export async function rebuildSessionMemory(userId: string, sessionId: string) {
  const { data: recentMessages, error: msgError } = await adminClient
    .from('beatrice_messages')
    .select('role, text, created_at')
    .eq('user_id', userId)
    .eq('session_id', sessionId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (msgError) return { ok: false, error: msgError.message };

  const { data: recentMemory, error: memError } = await adminClient
    .from('beatrice_memory_records')
    .select('content, memory_type, created_at, importance_score')
    .eq('user_id', userId)
    .eq('is_stale', false)
    .is('superseded_by_memory_id', null)
    .order('importance_score', { ascending: false })
    .limit(20);

  if (memError) return { ok: false, error: memError.message };

  return {
    ok: true,
    messages: recentMessages || [],
    memories: recentMemory || [],
  };
}

export async function updateSessionActivity(userId: string) {
  const { error } = await adminClient
    .from('beatrice_sessions')
    .update({ last_activity_at: new Date().toISOString(), updated_at: new Date().toISOString() })
    .eq('user_id', userId)
    .eq('is_active', true);

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

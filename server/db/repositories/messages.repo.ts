// ── Messages Repository ──
import { adminClient } from '../admin';

export interface MessageRecord {
  id?: string;
  user_id: string;
  tenant_id?: string;
  session_id?: string;
  thread_id?: string;
  role: 'user' | 'model' | 'system' | 'tool';
  text: string;
  tool_name?: string;
  tool_input?: Record<string, any>;
  tool_result?: Record<string, any>;
  attachment_url?: string;
  attachment_name?: string;
  attachment_type?: string;
  metadata?: Record<string, any>;
}

export async function saveMessage(message: MessageRecord) {
  const { data, error } = await adminClient
    .from('beatrice_messages')
    .insert({
      user_id: message.user_id,
      tenant_id: message.tenant_id,
      session_id: message.session_id,
      thread_id: message.thread_id,
      role: message.role,
      text: message.text,
      tool_name: message.tool_name,
      tool_input: message.tool_input,
      tool_result: message.tool_result,
      attachment_url: message.attachment_url,
      attachment_name: message.attachment_name,
      attachment_type: message.attachment_type,
      metadata: message.metadata || {},
    })
    .select('id')
    .single();

  if (error) return { ok: false, error: error.message };
  return { ok: true, id: data.id };
}

export async function getRecentRawMessages(userId: string, limit = 30) {
  const { data, error } = await adminClient
    .from('beatrice_messages')
    .select('id, role, text, attachment_url, attachment_name, session_id, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) return { ok: false, error: error.message };
  return { ok: true, data: (data || []).reverse() };
}

export async function getLatestUserConversation(userId: string, sessionId?: string) {
  let query = adminClient
    .from('beatrice_messages')
    .select('id, role, text, session_id, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(30);

  if (sessionId) {
    query = query.eq('session_id', sessionId);
  }

  const { data, error } = await query;
  if (error) return { ok: false, error: error.message };
  return { ok: true, data: (data || []).reverse() };
}

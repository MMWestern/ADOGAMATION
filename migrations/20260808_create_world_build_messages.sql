-- Stage 3A: World Build Messages table
-- Stores messages within a build session

CREATE TABLE IF NOT EXISTS world_build_messages (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL REFERENCES world_build_sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text',
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_build_messages_session ON world_build_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_build_messages_created ON world_build_messages(session_id, created_at);

ALTER TABLE world_build_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_build_messages
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

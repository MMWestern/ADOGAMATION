-- Stage 3A: World Build Sessions table
-- Stores AI-assisted development sessions

CREATE TABLE IF NOT EXISTS world_build_sessions (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  pillar_key TEXT,
  assistance_mode TEXT NOT NULL DEFAULT 'organizer',
  creativity_level TEXT NOT NULL DEFAULT 'balanced',
  depth_level TEXT NOT NULL DEFAULT 'foundation',
  auto_create_proposals BOOLEAN NOT NULL DEFAULT TRUE,
  settings_snapshot JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_build_sessions_series ON world_build_sessions(series_id);
CREATE INDEX IF NOT EXISTS idx_build_sessions_status ON world_build_sessions(status);

ALTER TABLE world_build_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_build_sessions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

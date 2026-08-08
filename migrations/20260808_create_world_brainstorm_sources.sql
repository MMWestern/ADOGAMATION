-- Stage 2A: World Brainstorm Sources table
-- Stores raw brainstorm material per series

CREATE TABLE IF NOT EXISTS world_brainstorm_sources (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  content_html TEXT NOT NULL DEFAULT '',
  source_type TEXT NOT NULL DEFAULT 'manual',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_brainstorm_sources_series ON world_brainstorm_sources(series_id);

ALTER TABLE world_brainstorm_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_brainstorm_sources
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

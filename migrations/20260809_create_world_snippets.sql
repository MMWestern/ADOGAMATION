-- World Builder: Snippets table
-- Stores reusable text snippets for the World Builder assistant

CREATE TABLE IF NOT EXISTS world_snippets (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_snippets_series ON world_snippets(series_id);
CREATE INDEX IF NOT EXISTS idx_snippets_category ON world_snippets(category);

ALTER TABLE world_snippets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_snippets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

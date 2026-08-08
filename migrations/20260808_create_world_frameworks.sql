-- Stage 2A: World Framework table
-- One active framework per series

CREATE TABLE IF NOT EXISTS world_frameworks (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  settings JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_world_frameworks_series ON world_frameworks(series_id);

ALTER TABLE world_frameworks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_frameworks
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

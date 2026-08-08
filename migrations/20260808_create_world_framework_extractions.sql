-- Stage 2A: World Framework Extractions table
-- Extracted fragments from brainstorm sources

CREATE TABLE IF NOT EXISTS world_framework_extractions (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES world_brainstorm_sources(id) ON DELETE CASCADE,
  pillar_key TEXT NOT NULL,
  fragment TEXT NOT NULL,
  author_action TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_extractions_source ON world_framework_extractions(source_id);
CREATE INDEX IF NOT EXISTS idx_extractions_pillar ON world_framework_extractions(pillar_key);

ALTER TABLE world_framework_extractions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_framework_extractions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

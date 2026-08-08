-- Stage 2A: World Framework Pillars table
-- Pillar content per framework

CREATE TABLE IF NOT EXISTS world_framework_pillars (
  id BIGSERIAL PRIMARY KEY,
  framework_id BIGINT NOT NULL REFERENCES world_frameworks(id) ON DELETE CASCADE,
  pillar_key TEXT NOT NULL,
  label TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  state TEXT NOT NULL DEFAULT 'empty',
  author_content TEXT NOT NULL DEFAULT '',
  ai_content TEXT NOT NULL DEFAULT '',
  locked_content TEXT NOT NULL DEFAULT '',
  is_visible BOOLEAN NOT NULL DEFAULT TRUE,
  is_custom BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pillars_framework_key ON world_framework_pillars(framework_id, pillar_key);
CREATE INDEX IF NOT EXISTS idx_pillars_framework_sort ON world_framework_pillars(framework_id, sort_order);

ALTER TABLE world_framework_pillars ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_framework_pillars
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

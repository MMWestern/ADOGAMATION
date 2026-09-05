-- Phase 1.2: Create codex_entity_appearances table
-- Tracks where entities appear in the narrative (books/chapters)
-- Separate from scope (ownership) and mentions (text-matching)
-- Date: 2026-09-05

CREATE TABLE IF NOT EXISTS codex_entity_appearances (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  appearance_type TEXT NOT NULL DEFAULT 'appears',
  notes TEXT,
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for navigation and filtering
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_entity ON codex_entity_appearances(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_series ON codex_entity_appearances(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_book ON codex_entity_appearances(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_chapter ON codex_entity_appearances(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_type ON codex_entity_appearances(appearance_type);

-- Composite index for primary query path: "show all appearances for entity X in book Y"
CREATE INDEX IF NOT EXISTS idx_codex_entity_appearances_entity_book
  ON codex_entity_appearances(entity_id, book_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION trg_codex_entity_appearances_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_codex_entity_appearances_updated_at
  BEFORE UPDATE ON codex_entity_appearances
  FOR EACH ROW EXECUTE FUNCTION trg_codex_entity_appearances_updated_at();

-- RLS (match existing pattern)
ALTER TABLE codex_entity_appearances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_entity_appearances
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Comments
COMMENT ON TABLE codex_entity_appearances IS 'Tracks where entities appear in the narrative (books/chapters). Separate from scope (ownership) and mentions (text-matching).';
COMMENT ON COLUMN codex_entity_appearances.appearance_type IS 'Type of appearance: appears, mentioned, pov, introduced, flashback, dies, returns, other';
COMMENT ON COLUMN codex_entity_appearances.source IS 'How this record was created: manual, derived, import, AI proposal';

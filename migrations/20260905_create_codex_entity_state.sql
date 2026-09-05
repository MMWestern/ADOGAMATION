-- Phase 1.3: Create codex_entity_state table
-- Generic time-aware state layer for entity properties
-- Supports LitRPG numeric progression AND non-LitRPG narrative state
-- Date: 2026-09-05

CREATE TABLE IF NOT EXISTS codex_entity_state (
  id BIGSERIAL PRIMARY KEY,
  subject_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  property_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  property_key TEXT,
  value_number NUMERIC,
  value_text TEXT,
  value_json JSONB,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  effective_from_sort NUMERIC,
  effective_to_sort NUMERIC,
  state_status TEXT DEFAULT 'draft',
  source_reference TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for navigation and filtering
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_subject ON codex_entity_state(subject_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_property_entity ON codex_entity_state(property_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_series ON codex_entity_state(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_book ON codex_entity_state(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_chapter ON codex_entity_state(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_effective ON codex_entity_state(effective_from_sort);
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_status ON codex_entity_state(state_status);

-- Composite index for primary query path: "show Patrick's Strength at Book 1 Ch 10"
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_subject_book_chapter
  ON codex_entity_state(subject_entity_id, book_id, effective_from_sort);

-- Composite index for: "show all state changes for Patrick in Book 2"
CREATE INDEX IF NOT EXISTS idx_codex_entity_state_subject_series
  ON codex_entity_state(subject_entity_id, series_id, effective_from_sort);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION trg_codex_entity_state_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_codex_entity_state_updated_at
  BEFORE UPDATE ON codex_entity_state
  FOR EACH ROW EXECUTE FUNCTION trg_codex_entity_state_updated_at();

-- RLS (match existing pattern)
ALTER TABLE codex_entity_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_entity_state
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Comments
COMMENT ON TABLE codex_entity_state IS 'Generic time-aware state layer. Records what is true about an entity at a particular narrative point. Never overwrites old state — appends new records.';
COMMENT ON COLUMN codex_entity_state.subject_entity_id IS 'Entity whose state is being recorded (e.g. Patrick)';
COMMENT ON COLUMN codex_entity_state.property_entity_id IS 'Optional entity definition (e.g. Strength stat, Fireball skill)';
COMMENT ON COLUMN codex_entity_state.property_key IS 'Scalar/system key when no entity is appropriate (e.g. "class")';
COMMENT ON COLUMN codex_entity_state.value_number IS 'Numeric value (for stats, levels, etc.)';
COMMENT ON COLUMN codex_entity_state.value_text IS 'Text/enum value (for class names, status, etc.)';
COMMENT ON COLUMN codex_entity_state.value_json IS 'Complex structured value (for nested data)';
COMMENT ON COLUMN codex_entity_state.effective_from_sort IS 'Narrative order start (references document_sections.sort_order)';
COMMENT ON COLUMN codex_entity_state.effective_to_sort IS 'Narrative order end if bounded';
COMMENT ON COLUMN codex_entity_state.state_status IS 'Canon status: planned, draft, canon, deprecated';

-- Phase 1.4: Create codex_progression_events table
-- Records what changed, when, and why (state tells us what is true, events tell us what changed)
-- Date: 2026-09-05

CREATE TABLE IF NOT EXISTS codex_progression_events (
  id BIGSERIAL PRIMARY KEY,
  subject_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  property_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  old_value JSONB,
  new_value JSONB,
  delta NUMERIC,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL,
  reason TEXT,
  source_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  canon_status TEXT DEFAULT 'draft',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for navigation and filtering
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_subject ON codex_progression_events(subject_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_series ON codex_progression_events(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_book ON codex_progression_events(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_chapter ON codex_progression_events(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_type ON codex_progression_events(event_type);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_canon ON codex_progression_events(canon_status);
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_source ON codex_progression_events(source_entity_id);

-- Composite index for primary query path: "show all progression events for Patrick in Book 1"
CREATE INDEX IF NOT EXISTS idx_codex_progression_events_subject_series
  ON codex_progression_events(subject_entity_id, series_id, created_at);

-- RLS (match existing pattern)
ALTER TABLE codex_progression_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_progression_events
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Comments
COMMENT ON TABLE codex_progression_events IS 'Records what changed, when, and why. State tells us what is true; events tell us what changed. Essential for LitRPG auditability and continuity checks.';
COMMENT ON COLUMN codex_progression_events.subject_entity_id IS 'Usually a character/creature whose state changed';
COMMENT ON COLUMN codex_progression_events.event_type IS 'Type of change: level_up, skill_unlock, stat_change, item_acquired, item_lost, title_awarded, class_change, reputation_change, custom';
COMMENT ON COLUMN codex_progression_events.property_entity_id IS 'Stat/skill/item/etc. affected';
COMMENT ON COLUMN codex_progression_events.old_value IS 'Optional JSONB snapshot of previous value';
COMMENT ON COLUMN codex_progression_events.new_value IS 'Optional JSONB snapshot of new value';
COMMENT ON COLUMN codex_progression_events.delta IS 'Optional numeric change amount';
COMMENT ON COLUMN codex_progression_events.reason IS 'Why the change happened: quest reward, achievement, training, plot event, etc.';
COMMENT ON COLUMN codex_progression_events.source_entity_id IS 'Optional quest/achievement/item/event that caused the change';
COMMENT ON COLUMN codex_progression_events.canon_status IS 'Canon status: draft, provisional, canon, deprecated';

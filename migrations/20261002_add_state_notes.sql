-- Notes on states.
--
-- sce_states already carried name, purpose, before_text and after_text, and
-- sceSaveState persisted all four, but nothing in the timeline could edit any of
-- them except the (unsaved) contenteditable name. The state inspector surfaces
-- those four plus notes, which has no column yet.
--
-- Nullable with no default: existing states read as no notes rather than an
-- empty string, so nothing about current compositions changes. Rows are never
-- rewritten by this migration.
--
-- No RLS change is needed. sce_states already has "Authenticated full access"
-- for ALL, matching every other sce_ table.

ALTER TABLE sce_states
  ADD COLUMN IF NOT EXISTS notes TEXT;

COMMENT ON COLUMN sce_states.notes IS
  'Free-form notes for this state. Edited from the state inspector.';
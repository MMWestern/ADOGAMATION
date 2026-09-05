-- Phase 1.1: Extend codex_connections with context and temporal fields
-- Safe: additive only — new nullable columns, no existing data affected
-- Date: 2026-09-05

-- Add book/chapter context columns
ALTER TABLE codex_connections
  ADD COLUMN IF NOT EXISTS book_id BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS chapter_id BIGINT REFERENCES document_sections(id) ON DELETE SET NULL;

-- Add temporal validity columns (using sort_order from document_sections as narrative anchor)
ALTER TABLE codex_connections
  ADD COLUMN IF NOT EXISTS valid_from_sort NUMERIC,
  ADD COLUMN IF NOT EXISTS valid_to_sort NUMERIC;

-- Add status and provenance columns
ALTER TABLE codex_connections
  ADD COLUMN IF NOT EXISTS context_status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS created_source TEXT DEFAULT 'manual';

-- Indexes for new query paths
CREATE INDEX IF NOT EXISTS idx_codex_connections_book_id ON codex_connections(book_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_chapter_id ON codex_connections(chapter_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_valid_from ON codex_connections(valid_from_sort);
CREATE INDEX IF NOT EXISTS idx_codex_connections_context_status ON codex_connections(context_status);

-- Add comment for documentation
COMMENT ON COLUMN codex_connections.book_id IS 'Optional book-level context for this relationship';
COMMENT ON COLUMN codex_connections.chapter_id IS 'Optional chapter-level context for this relationship';
COMMENT ON COLUMN codex_connections.valid_from_sort IS 'Narrative ordering anchor — when this relationship becomes active (references document_sections.sort_order)';
COMMENT ON COLUMN codex_connections.valid_to_sort IS 'Narrative ordering anchor — when this relationship ends';
COMMENT ON COLUMN codex_connections.context_status IS 'Status of this contextual relationship: active, ended, planned, etc.';
COMMENT ON COLUMN codex_connections.notes IS 'Human notes about this relationship';
COMMENT ON COLUMN codex_connections.created_source IS 'How this record was created: manual, import, AI proposal, migration';

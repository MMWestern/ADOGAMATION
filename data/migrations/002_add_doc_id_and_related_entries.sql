-- Add doc_id and related_entries columns to handbook_entries
-- Run this if you already ran the original 001 migration.
-- If you haven't run 001 yet, just use the updated 001 instead.

ALTER TABLE handbook_entries ADD COLUMN IF NOT EXISTS doc_id TEXT UNIQUE;
ALTER TABLE handbook_entries ADD COLUMN IF NOT EXISTS related_entries JSONB DEFAULT '[]';

CREATE INDEX IF NOT EXISTS idx_handbook_entries_doc_id ON handbook_entries (doc_id);

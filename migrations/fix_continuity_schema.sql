-- Migration: Fix continuity schema — add missing columns
-- Date: 2026-06-04
-- Run this in Supabase SQL Editor

-- Add columns that are used in saveWritingCodexModal / listSupabaseSeriesContinuityEntriesJsonFromClient
-- but may be missing from the original table creation
ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'book';

ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS color VARCHAR(7) NOT NULL DEFAULT '';

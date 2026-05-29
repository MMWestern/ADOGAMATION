-- Migration: Add color column to codex tables for entry theming
-- Date: 2026-05-29
-- Author: opencode-agent

ALTER TABLE series_characters
  ADD COLUMN IF NOT EXISTS color VARCHAR(7) DEFAULT '';

ALTER TABLE series_locations
  ADD COLUMN IF NOT EXISTS color VARCHAR(7) DEFAULT '';

ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS color VARCHAR(7) DEFAULT '';

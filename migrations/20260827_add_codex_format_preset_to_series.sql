-- Migration: Add codex_format_preset column to series table
-- Date: 2026-08-27

ALTER TABLE series ADD COLUMN IF NOT EXISTS codex_format_preset TEXT DEFAULT 'standard_fantasy';

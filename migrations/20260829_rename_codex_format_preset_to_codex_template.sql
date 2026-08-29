-- Migration: Rename codex_format_preset to codex_template
-- Date: 2026-08-29

ALTER TABLE series RENAME COLUMN codex_format_preset TO codex_template;

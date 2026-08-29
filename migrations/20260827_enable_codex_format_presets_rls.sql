-- Migration: Enable RLS on codex_format_presets table
-- Date: 2026-08-27

ALTER TABLE codex_format_presets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_format_presets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

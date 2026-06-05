-- Migration: Create codex AI suggestions and jobs tables
-- Date: 2026-06-05

CREATE TABLE IF NOT EXISTS codex_ai_suggestions (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  suggestion_type TEXT NOT NULL,
  target_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  prompt TEXT,
  context_snapshot JSONB NOT NULL DEFAULT '{}',
  suggested_payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  provider TEXT,
  model TEXT,
  prompt_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_codex_ai_suggestions_series ON codex_ai_suggestions(series_id);

CREATE TABLE IF NOT EXISTS codex_continuity_findings (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  finding_type TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'info',
  status TEXT NOT NULL DEFAULT 'open',
  title TEXT NOT NULL,
  description TEXT,
  evidence JSONB NOT NULL DEFAULT '{}',
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_codex_continuity_findings_series ON codex_continuity_findings(series_id);

ALTER TABLE codex_ai_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_continuity_findings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_ai_suggestions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON codex_continuity_findings
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

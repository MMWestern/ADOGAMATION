-- Stage 4A: World Proposals table
-- Stores reviewable proposals from AI-assisted sessions

CREATE TABLE IF NOT EXISTS world_proposals (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  session_id BIGINT REFERENCES world_build_sessions(id),
  proposal_type TEXT NOT NULL,
  target_entity_type TEXT,
  target_entity_id BIGINT,
  proposed_content JSONB NOT NULL DEFAULT '{}',
  summary TEXT NOT NULL DEFAULT '',
  source_passage TEXT,
  source_pillar_key TEXT,
  contradictions JSONB NOT NULL DEFAULT '[]',
  ai_assumptions JSONB NOT NULL DEFAULT '[]',
  suggested_connections JSONB NOT NULL DEFAULT '[]',
  review_status TEXT NOT NULL DEFAULT 'pending',
  reviewer_edits JSONB NOT NULL DEFAULT '{}',
  rejection_reason TEXT,
  do_not_suggest_again BOOLEAN NOT NULL DEFAULT FALSE,
  resulting_entity_id BIGINT,
  resulting_connection_id BIGINT,
  settings_snapshot JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_proposals_series ON world_proposals(series_id);
CREATE INDEX IF NOT EXISTS idx_proposals_status ON world_proposals(review_status);
CREATE INDEX IF NOT EXISTS idx_proposals_session ON world_proposals(session_id);

ALTER TABLE world_proposals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON world_proposals
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

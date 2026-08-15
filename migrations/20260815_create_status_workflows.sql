-- Status Workflows: Maps status → next_step
-- Run in Supabase SQL editor

CREATE TABLE IF NOT EXISTS status_workflows (
  id BIGSERIAL PRIMARY KEY,
  status TEXT NOT NULL UNIQUE,
  next_step TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default mappings
INSERT INTO status_workflows (status, next_step) VALUES
  ('Idea', 'Define concept'),
  ('Concept', 'Create outline'),
  ('Planning', 'Begin drafting'),
  ('Draft', 'Continue writing'),
  ('Writing', 'Start editing'),
  ('Editing', 'Finalize manuscript'),
  ('Complete', 'Prepare for publish'),
  ('Publish Ready', 'Publish'),
  ('Published', '')
ON CONFLICT (status) DO NOTHING;

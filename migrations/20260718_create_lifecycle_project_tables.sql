-- Lifecycle Engine: Project lifecycle tracking tables
-- project_lifecycles + project_stage_status + lifecycle_approvals

CREATE TABLE IF NOT EXISTS project_lifecycles (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  template_id BIGINT NOT NULL REFERENCES lifecycle_templates(id),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_project_lifecycles_project ON project_lifecycles(project_id);
CREATE INDEX IF NOT EXISTS idx_project_lifecycles_template ON project_lifecycles(template_id);

CREATE OR REPLACE FUNCTION update_project_lifecycles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_project_lifecycles_updated_at ON project_lifecycles;
CREATE TRIGGER trg_project_lifecycles_updated_at
  BEFORE UPDATE ON project_lifecycles
  FOR EACH ROW
  EXECUTE FUNCTION update_project_lifecycles_updated_at();


CREATE TABLE IF NOT EXISTS project_stage_status (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  lifecycle_id BIGINT NOT NULL REFERENCES project_lifecycles(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  completed_at TIMESTAMPTZ,
  blocked_reason TEXT,
  notes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_project_stage_status_unique ON project_stage_status(project_id, stage_key);
CREATE INDEX IF NOT EXISTS idx_project_stage_status_lifecycle ON project_stage_status(lifecycle_id);
CREATE INDEX IF NOT EXISTS idx_project_stage_status_status ON project_stage_status(status);

CREATE OR REPLACE FUNCTION update_project_stage_status_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_project_stage_status_updated_at ON project_stage_status;
CREATE TRIGGER trg_project_stage_status_updated_at
  BEFORE UPDATE ON project_stage_status
  FOR EACH ROW
  EXECUTE FUNCTION update_project_stage_status_updated_at();


CREATE TABLE IF NOT EXISTS lifecycle_approvals (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  decided_at TIMESTAMPTZ,
  decision TEXT,
  approver_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_approvals_project ON lifecycle_approvals(project_id);
CREATE INDEX IF NOT EXISTS idx_lifecycle_approvals_stage ON lifecycle_approvals(stage_key);

CREATE OR REPLACE FUNCTION update_lifecycle_approvals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lifecycle_approvals_updated_at ON lifecycle_approvals;
CREATE TRIGGER trg_lifecycle_approvals_updated_at
  BEFORE UPDATE ON lifecycle_approvals
  FOR EACH ROW
  EXECUTE FUNCTION update_lifecycle_approvals_updated_at();

-- Lifecycle Engine: Core tables
-- lifecycle_templates + lifecycle_template_stages

CREATE TABLE IF NOT EXISTS lifecycle_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_templates_default ON lifecycle_templates(is_default);
CREATE INDEX IF NOT EXISTS idx_lifecycle_templates_sort ON lifecycle_templates(sort_order);

CREATE OR REPLACE FUNCTION update_lifecycle_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lifecycle_templates_updated_at ON lifecycle_templates;
CREATE TRIGGER trg_lifecycle_templates_updated_at
  BEFORE UPDATE ON lifecycle_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_lifecycle_templates_updated_at();


CREATE TABLE IF NOT EXISTS lifecycle_template_stages (
  id BIGSERIAL PRIMARY KEY,
  template_id BIGINT NOT NULL REFERENCES lifecycle_templates(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,
  label TEXT NOT NULL,
  phase TEXT NOT NULL DEFAULT 'Pre-Production',
  is_required BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  gate_conditions JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_template_stages_template ON lifecycle_template_stages(template_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_lifecycle_template_stages_key ON lifecycle_template_stages(template_id, stage_key);
CREATE INDEX IF NOT EXISTS idx_lifecycle_template_stages_sort ON lifecycle_template_stages(template_id, sort_order);

CREATE OR REPLACE FUNCTION update_lifecycle_template_stages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lifecycle_template_stages_updated_at ON lifecycle_template_stages;
CREATE TRIGGER trg_lifecycle_template_stages_updated_at
  BEFORE UPDATE ON lifecycle_template_stages
  FOR EACH ROW
  EXECUTE FUNCTION update_lifecycle_template_stages_updated_at();

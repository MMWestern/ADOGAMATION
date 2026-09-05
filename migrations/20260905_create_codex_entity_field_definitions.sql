-- Phase 1.5: Create codex_entity_field_definitions table
-- Schema-driven field definitions instead of hard-coded entity type panels
-- Date: 2026-09-05

CREATE TABLE IF NOT EXISTS codex_entity_field_definitions (
  id BIGSERIAL PRIMARY KEY,
  entity_type_key TEXT NOT NULL,
  field_key TEXT NOT NULL,
  label TEXT NOT NULL,
  field_type TEXT NOT NULL DEFAULT 'text',
  group_name TEXT,
  sort_order INTEGER DEFAULT 0,
  required BOOLEAN DEFAULT FALSE,
  options_json JSONB,
  relationship_type_id BIGINT REFERENCES codex_relationship_types(id) ON DELETE SET NULL,
  help_text TEXT,
  preset_visibility JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(entity_type_key, field_key)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_defs_type ON codex_entity_field_definitions(entity_type_key);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_defs_group ON codex_entity_field_definitions(entity_type_key, group_name);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION trg_codex_entity_field_definitions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_codex_entity_field_definitions_updated_at
  BEFORE UPDATE ON codex_entity_field_definitions
  FOR EACH ROW EXECUTE FUNCTION trg_codex_entity_field_definitions_updated_at();

-- RLS (match existing pattern)
ALTER TABLE codex_entity_field_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_entity_field_definitions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Comments
COMMENT ON TABLE codex_entity_field_definitions IS 'Schema-driven field definitions per entity type. Instead of hard-coding 47 entity type panels, define fields in data and render generically.';
COMMENT ON COLUMN codex_entity_field_definitions.entity_type_key IS 'Entity type this field applies to (e.g. "character", "location")';
COMMENT ON COLUMN codex_entity_field_definitions.field_key IS 'Unique key within the entity type (e.g. "age", "climate")';
COMMENT ON COLUMN codex_entity_field_definitions.field_type IS 'Field type: text, long_text, number, boolean, date, select, multi_select, entity_link, entity_multi_link, image, url, rich_text, json';
COMMENT ON COLUMN codex_entity_field_definitions.group_name IS 'Group/tab name for organizing fields in the UI';
COMMENT ON COLUMN codex_entity_field_definitions.options_json IS 'Options for select/multi_select fields (e.g. {"options":["Common","Rare","Legendary"]})';
COMMENT ON COLUMN codex_entity_field_definitions.relationship_type_id IS 'If this field represents a relationship, the relationship type to use';
COMMENT ON COLUMN codex_entity_field_definitions.preset_visibility IS 'JSONB controlling which presets show this field (e.g. {"litrpg":true,"standard_fantasy":false})';

-- Phase 1.6: Create codex_entity_field_values table
-- Stores actual field values for entities
-- Date: 2026-09-05

CREATE TABLE IF NOT EXISTS codex_entity_field_values (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  field_definition_id BIGINT NOT NULL REFERENCES codex_entity_field_definitions(id) ON DELETE CASCADE,
  value_text TEXT,
  value_number NUMERIC,
  value_boolean BOOLEAN,
  value_json JSONB,
  linked_entity_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  canon_status TEXT DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(entity_id, field_definition_id)
);

-- Indexes for navigation and filtering
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_entity ON codex_entity_field_values(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_def ON codex_entity_field_values(field_definition_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_linked ON codex_entity_field_values(linked_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_canon ON codex_entity_field_values(canon_status);

-- Composite index for primary query path: "show all field values for entity X"
CREATE INDEX IF NOT EXISTS idx_codex_entity_field_values_entity_def
  ON codex_entity_field_values(entity_id, field_definition_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION trg_codex_entity_field_values_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_codex_entity_field_values_updated_at
  BEFORE UPDATE ON codex_entity_field_values
  FOR EACH ROW EXECUTE FUNCTION trg_codex_entity_field_values_updated_at();

-- RLS (match existing pattern)
ALTER TABLE codex_entity_field_values ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_entity_field_values
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Comments
COMMENT ON TABLE codex_entity_field_values IS 'Stores actual field values for entities. Each value links an entity to a field definition.';
COMMENT ON COLUMN codex_entity_field_values.entity_id IS 'The entity this value belongs to';
COMMENT ON COLUMN codex_entity_field_values.field_definition_id IS 'The field definition this value satisfies';
COMMENT ON COLUMN codex_entity_field_values.value_text IS 'Text value (for text, long_text, select fields)';
COMMENT ON COLUMN codex_entity_field_values.value_number IS 'Numeric value (for number fields)';
COMMENT ON COLUMN codex_entity_field_values.value_boolean IS 'Boolean value (for boolean fields)';
COMMENT ON COLUMN codex_entity_field_values.value_json IS 'Complex value (for multi_select, rich_text, json fields)';
COMMENT ON COLUMN codex_entity_field_values.linked_entity_id IS 'Linked entity (for entity_link, entity_multi_link fields)';
COMMENT ON COLUMN codex_entity_field_values.canon_status IS 'Canon status: draft, provisional, canon, deprecated';

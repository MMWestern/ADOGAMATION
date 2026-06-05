-- Migration: Enable RLS on all new Codex tables
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

ALTER TABLE codex_entity_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_entity_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_relationship_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_entity_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_entity_revisions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_entity_types
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_entities
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_entity_projects
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_relationship_types
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_connections
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_tags
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_entity_tags
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON codex_entity_revisions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

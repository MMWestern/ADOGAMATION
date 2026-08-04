-- Lifecycle Engine: RLS policies for all 5 tables

ALTER TABLE lifecycle_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON lifecycle_templates
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

ALTER TABLE lifecycle_template_stages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON lifecycle_template_stages
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

ALTER TABLE project_lifecycles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON project_lifecycles
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

ALTER TABLE project_stage_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON project_stage_status
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

ALTER TABLE lifecycle_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON lifecycle_approvals
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

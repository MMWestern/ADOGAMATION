-- Enable RLS on new series metadata tables
-- Run after creating status_workflows and format_defaults tables

ALTER TABLE status_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE format_defaults ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON status_workflows
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON format_defaults
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

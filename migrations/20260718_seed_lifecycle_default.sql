-- Lifecycle Engine: Seed default template with 13 stages

INSERT INTO lifecycle_templates (name, description, is_default, sort_order)
VALUES ('Default Novel', 'Standard 13-stage novel publishing lifecycle from Story Seed to Evergreen.', TRUE, 0);

-- Get the template id (works in most SQL clients; in Supabase dashboard use the returned id)
-- Then insert stages using that template_id

INSERT INTO lifecycle_template_stages (template_id, stage_key, label, phase, is_required, sort_order, gate_conditions)
SELECT t.id, s.stage_key, s.label, s.phase, s.is_required, s.sort_order, s.gate_conditions::jsonb
FROM lifecycle_templates t
CROSS JOIN (VALUES
  ('story_seed',       'Story Seed',         'Pre-Production', true,  0,  '{}'),
  ('project',          'Project',            'Pre-Production', true,  1,  '{}'),
  ('validation',       'Validation',         'Pre-Production', true,  2,  '{"requires_summary": true}'),
  ('research',         'Research',           'Pre-Production', false, 3,  '{}'),
  ('codex',            'Codex',              'Pre-Production', true,  4,  '{"requires_codex_entries": true}'),
  ('planning',         'Planning',           'Production',     true,  5,  '{"requires_outline": true}'),
  ('draft_prep',       'Draft Preparation',  'Production',     true,  6,  '{"requires_outline": true}'),
  ('first_draft',      'First Draft',        'Production',     true,  7,  '{}'),
  ('revision',         'Revision',           'Production',     true,  8,  '{}'),
  ('development_edit', 'Development Edit',   'Production',     false, 9,  '{}'),
  ('serial_prep',      'Serial Preparation', 'Post-Production',false, 10, '{"requires_publish_date": true}'),
  ('publication',      'Publication',        'Post-Production',true,  11, '{}'),
  ('evergreen',        'Evergreen',          'Evergreen',      false, 12, '{}')
) AS s(stage_key, label, phase, is_required, sort_order, gate_conditions)
WHERE t.is_default = TRUE
  AND t.name = 'Default Novel'
  AND NOT EXISTS (
    SELECT 1 FROM lifecycle_template_stages lts WHERE lts.template_id = t.id
  );

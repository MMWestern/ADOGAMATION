-- Format Defaults: Maps format → schedule_template + marketing_template
-- Run in Supabase SQL editor

CREATE TABLE IF NOT EXISTS format_defaults (
  id BIGSERIAL PRIMARY KEY,
  format TEXT NOT NULL UNIQUE,
  schedule_template TEXT,
  marketing_template TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default mappings
INSERT INTO format_defaults (format, schedule_template, marketing_template) VALUES
  ('Novel', 'Novel (6wk)', 'Full Launch'),
  ('Novella', 'Novella (4wk)', 'Social Launch'),
  ('Novelette', 'Novella (4wk)', 'Social Launch'),
  ('Short Story', NULL, 'Newsletter Only'),
  ('Flash Fiction', NULL, NULL),
  ('Serial', NULL, NULL),
  ('Anthology', NULL, NULL),
  ('Screenplay', NULL, NULL),
  ('Stage Play', NULL, NULL),
  ('Poetry Collection', NULL, NULL),
  ('Graphic Novel', NULL, NULL),
  ('Web Serial', NULL, NULL),
  ('Chapbook', NULL, NULL)
ON CONFLICT (format) DO NOTHING;

-- Migration: Add outline JSONB column to projects table
-- Date: 2026-05-27
-- Author: opencode-agent

-- Add outline column as JSONB with empty object default
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS outline JSONB DEFAULT '{}'::jsonb;

-- Add index for efficient querying if needed later
CREATE INDEX IF NOT EXISTS idx_projects_outline
  ON projects USING GIN (outline jsonb_path_ops);

-- Comment for documentation
COMMENT ON COLUMN projects.outline IS 'Project outline tree: { acts: [{ id, title, children: [{ id, title, children: [{ id, title, purpose, pov, targetWordCount, mainPlotFunction, characterIds }] }] }] }';

-- Story Composition Editor (SCE) — Database Tables
-- Creates all tables for the visual story composition system

-- 1. Compositions — one per book
CREATE TABLE IF NOT EXISTS sce_compositions (
  id BIGSERIAL PRIMARY KEY,
  book_id BIGINT REFERENCES projects(id) ON DELETE CASCADE,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT DEFAULT 'Untitled Composition',
  structure_template TEXT DEFAULT 'standard_15',
  version INT DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_compositions_series ON sce_compositions(series_id);
CREATE INDEX IF NOT EXISTS idx_sce_compositions_book ON sce_compositions(book_id);

-- 2. States — 15 fixed states per composition
CREATE TABLE IF NOT EXISTS sce_states (
  id BIGSERIAL PRIMARY KEY,
  composition_id BIGINT NOT NULL REFERENCES sce_compositions(id) ON DELETE CASCADE,
  position INT NOT NULL,
  name TEXT NOT NULL,
  purpose TEXT,
  before_text TEXT,
  after_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_states_composition ON sce_states(composition_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sce_states_comp_pos ON sce_states(composition_id, position);

-- 3. Layers — visual tracks
CREATE TABLE IF NOT EXISTS sce_layers (
  id BIGSERIAL PRIMARY KEY,
  composition_id BIGINT NOT NULL REFERENCES sce_compositions(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#3b82f6',
  position INT DEFAULT 0,
  is_hidden BOOLEAN DEFAULT FALSE,
  is_solo BOOLEAN DEFAULT FALSE,
  is_locked BOOLEAN DEFAULT FALSE,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_layers_composition ON sce_layers(composition_id);

-- 4. Assets — reusable story ideas (Asset Bin)
CREATE TABLE IF NOT EXISTS sce_assets (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  what_changes TEXT,
  what_produces TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_assets_series ON sce_assets(series_id);

-- 5. Blocks — placed story blocks on the timeline
CREATE TABLE IF NOT EXISTS sce_blocks (
  id BIGSERIAL PRIMARY KEY,
  composition_id BIGINT NOT NULL REFERENCES sce_compositions(id) ON DELETE CASCADE,
  asset_id BIGINT REFERENCES sce_assets(id) ON DELETE SET NULL,
  layer_id BIGINT NOT NULL REFERENCES sce_layers(id) ON DELETE CASCADE,
  start_state INT NOT NULL,
  end_state INT NOT NULL,
  vertical_pos INT DEFAULT 0,
  short_title TEXT,
  description TEXT,
  before_text TEXT,
  what_happens TEXT,
  after_text TEXT,
  next_text TEXT,
  notes TEXT,
  is_detached BOOLEAN DEFAULT FALSE,
  is_parked BOOLEAN DEFAULT FALSE,
  is_later_book BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_blocks_composition ON sce_blocks(composition_id);
CREATE INDEX IF NOT EXISTS idx_sce_blocks_layer ON sce_blocks(layer_id);
CREATE INDEX IF NOT EXISTS idx_sce_blocks_asset ON sce_blocks(asset_id);
CREATE INDEX IF NOT EXISTS idx_sce_blocks_state ON sce_blocks(start_state, end_state);

-- 6. Connections — block relationships
CREATE TABLE IF NOT EXISTS sce_connections (
  id BIGSERIAL PRIMARY KEY,
  source_block_id BIGINT NOT NULL REFERENCES sce_blocks(id) ON DELETE CASCADE,
  target_block_id BIGINT NOT NULL REFERENCES sce_blocks(id) ON DELETE CASCADE,
  connection_type TEXT NOT NULL DEFAULT 'causes',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_connections_source ON sce_connections(source_block_id);
CREATE INDEX IF NOT EXISTS idx_sce_connections_target ON sce_connections(target_block_id);

-- RLS policies
ALTER TABLE sce_compositions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_layers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_connections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON sce_compositions FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_states FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_layers FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_assets FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_blocks FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_connections FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

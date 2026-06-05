-- Migration: Create codex calendars, events, and timelines
-- Date: 2026-06-05
-- Phase 8: Chronology support

CREATE TABLE IF NOT EXISTS codex_calendars (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  calendar_config JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_calendars_series ON codex_calendars(series_id);

CREATE TABLE IF NOT EXISTS codex_events (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  calendar_id BIGINT REFERENCES codex_calendars(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_sort_key BIGINT,
  end_sort_key BIGINT,
  display_date TEXT,
  is_date_approximate BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_codex_events_series ON codex_events(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_events_calendar ON codex_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_codex_events_deleted ON codex_events(deleted_at);

CREATE TABLE IF NOT EXISTS codex_event_entities (
  event_id BIGINT NOT NULL REFERENCES codex_events(id) ON DELETE CASCADE,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  role TEXT,
  PRIMARY KEY(event_id, entity_id)
);

CREATE TABLE IF NOT EXISTS codex_timelines (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  visibility TEXT NOT NULL DEFAULT 'private',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_timelines_series ON codex_timelines(series_id);

CREATE TABLE IF NOT EXISTS codex_timeline_events (
  timeline_id BIGINT NOT NULL REFERENCES codex_timelines(id) ON DELETE CASCADE,
  event_id BIGINT NOT NULL REFERENCES codex_events(id) ON DELETE CASCADE,
  sort_order INTEGER,
  notes TEXT,
  PRIMARY KEY(timeline_id, event_id)
);

-- RLS
ALTER TABLE codex_calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_event_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_timelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE codex_timeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON codex_calendars
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON codex_events
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON codex_event_entities
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON codex_timelines
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON codex_timeline_events
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

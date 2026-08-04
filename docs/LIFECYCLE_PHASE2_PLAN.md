# Lifecycle Engine — Phase 2 Plan

## Templates, Project Lifecycles, and Approval Gates

---

## Goal

Replace the Phase 1 derived-from-status calculation with explicit lifecycle tracking. Each project gets assigned a lifecycle template, and each stage is independently tracked with its own status, blockers, notes, and approval gates.

---

## New Supabase Tables

### 1. `lifecycle_templates`

Reusable workflow definitions. Seeded with a "Default Novel" template matching the current 13 stages.

```sql
CREATE TABLE IF NOT EXISTS lifecycle_templates (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_templates_default ON lifecycle_templates(is_default);
```

### 2. `lifecycle_template_stages`

Stages belonging to a template. Defines order, which are required, and what data gates each stage needs.

```sql
CREATE TABLE IF NOT EXISTS lifecycle_template_stages (
  id BIGSERIAL PRIMARY KEY,
  template_id BIGINT NOT NULL REFERENCES lifecycle_templates(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,           -- e.g. "story_seed", "first_draft"
  label TEXT NOT NULL,               -- e.g. "Story Seed", "First Draft"
  phase TEXT NOT NULL DEFAULT 'Pre-Production',  -- grouping label
  is_required BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  gate_conditions JSONB NOT NULL DEFAULT '{}',   -- e.g. {"requires_outline": true, "min_word_count": 60000}
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_template_stages_template ON lifecycle_template_stages(template_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_lifecycle_template_stages_key ON lifecycle_template_stages(template_id, stage_key);
```

### 3. `project_lifecycles`

Assigns a lifecycle template to a project. One active lifecycle per project.

```sql
CREATE TABLE IF NOT EXISTS project_lifecycles (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  template_id BIGINT NOT NULL REFERENCES lifecycle_templates(id),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_project_lifecycles_project ON project_lifecycles(project_id);
CREATE INDEX IF NOT EXISTS idx_project_lifecycles_template ON project_lifecycles(template_id);
```

### 4. `project_stage_status`

Per-stage state for each project. This is the core tracking table.

```sql
CREATE TABLE IF NOT EXISTS project_stage_status (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  lifecycle_id BIGINT NOT NULL REFERENCES project_lifecycles(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,           -- matches lifecycle_template_stages.stage_key
  status TEXT NOT NULL DEFAULT 'pending',  -- pending | in_progress | blocked | complete | skipped
  completed_at TIMESTAMPTZ,
  blocked_reason TEXT,
  notes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_project_stage_status_unique ON project_stage_status(project_id, stage_key);
CREATE INDEX IF NOT EXISTS idx_project_stage_status_lifecycle ON project_stage_status(lifecycle_id);
CREATE INDEX IF NOT EXISTS idx_project_stage_status_status ON project_stage_status(status);
```

### 5. `lifecycle_approvals`

Approval gates between stages. A stage can require approval before it can be marked complete.

```sql
CREATE TABLE IF NOT EXISTS lifecycle_approvals (
  id BIGSERIAL PRIMARY KEY,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  stage_key TEXT NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  decided_at TIMESTAMPTZ,
  decision TEXT,                     -- approved | rejected
  approver_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lifecycle_approvals_project ON lifecycle_approvals(project_id);
CREATE INDEX IF NOT EXISTS idx_lifecycle_approvals_stage ON lifecycle_approvals(stage_key);
```

### RLS (one migration file)

Same pattern as all other tables:
```sql
ALTER TABLE lifecycle_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON lifecycle_templates
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
-- repeat for all 5 tables
```

---

## New CRUD Operations

Add to `scripts/data-operations.html` (or a new `scripts/lifecycle-operations.html`):

| Operation | Method Name | Description |
|---|---|---|
| List templates | `listLifecycleTemplates` | Returns all templates with their stages |
| Get template | `getLifecycleTemplate` | Returns one template with stages |
| Save template | `saveLifecycleTemplate` | Insert or update template + stages (delete-all-reinsert for stages) |
| Delete template | `deleteLifecycleTemplate` | Soft-delete or cascade delete |
| Get project lifecycle | `getProjectLifecycle` | Returns lifecycle + all stage statuses for a project |
| Assign lifecycle | `assignProjectLifecycle` | Creates `project_lifecycles` row + initial `project_stage_status` rows for all stages |
| Update stage status | `updateProjectStageStatus` | Updates a single stage's status/blocked_reason/notes |
| Request approval | `requestLifecycleApproval` | Creates a `lifecycle_approvals` row |
| Decide approval | `decideLifecycleApproval` | Sets decision + decided_at |
| Get approvals | `getProjectApprovals` | Returns all approvals for a project |

---

## UI Changes

### Template Manager (new modal or section)

Accessible from the LIFECYCLE tab. Lists templates, allows creating/editing/deleting custom templates. Each template shows its stages in order with drag-to-reorder.

**Location**: A "Manage Templates" button in the LIFECYCLE tab header opens a modal.

### Lifecycle Assignment

When a project has no lifecycle assigned, the LIFECYCLE tab shows:
```
No lifecycle assigned to this project.
[Assign Default Novel Lifecycle] [Choose Template...]
```

Once assigned, the tab shows the full dashboard with real stage data.

### Stage Interaction

Each stage in the checklist becomes clickable:
- Click a stage to expand it and show:
  - Status dropdown (pending/in_progress/blocked/complete/skipped)
  - Blocked reason (if status = blocked)
  - Notes field
  - Approval status (if gate exists)

### Approval Gates

When a stage has a `gate_conditions` entry, the "Complete" action requires an approval. The UI shows:
```
Stage: First Draft
Status: [Complete ▾]
[Request Approval] → creates lifecycle_approvals row
[Approve] [Reject] → if user has approval rights
```

---

## Changes to Phase 1 Code

### `scripts/lifecycle.html`

**`calculateLifecycleStage()`** changes:
- If project has a `project_lifecycles` row, read stage statuses from `project_stage_status` instead of deriving from `project.status`
- If no lifecycle assigned, fall back to Phase 1 derived calculation

**`renderLifecycleDashboard()`** changes:
- Show template name and assignment status
- Render stages from real data when available
- Make stages interactive (click to expand/edit)
- Show approval status on gated stages

### New appState property

```javascript
lifecycle: {
  ...existing...,
  template: null,           // loaded lifecycle_templates row
  stages: [],               // loaded lifecycle_template_stages rows
  stageStatuses: [],        // loaded project_stage_status rows
  approvals: [],            // loaded lifecycle_approvals rows
  lifecycleId: null,        // active project_lifecycles.id
  isAssigned: false
}
```

---

## Data Flow

```
User opens LIFECYCLE tab
  → renderLifecycleDashboard()
    → callAppsScriptJson("getProjectLifecycle", [projectId])
      → Returns template + stages + stage_statuses in one call
    → If no lifecycle assigned:
        → Show assignment UI
    → If lifecycle assigned:
        → Render stages from project_stage_status
        → callAppsScriptJson("getProjectApprovals", [projectId])
        → Render approval gates

User clicks a stage
  → Expand stage detail
  → Show status dropdown, notes, blockers

User changes stage status
  → callAppsScriptJson("updateProjectStageStatus", [projectId, stageKey, status, notes, blockedReason])
  → Re-render checklist

User requests approval
  → callAppsScriptJson("requestLifecycleApproval", [projectId, stageKey])
  → Re-render stage with pending approval badge

User approves/rejects
  → callAppsScriptJson("decideLifecycleApproval", [approvalId, decision, notes])
  → If approved: auto-advance stage to complete
  → Re-render
```

---

## Seed Data

Insert a default template on first use (or via migration):

```sql
INSERT INTO lifecycle_templates (name, description, is_default, sort_order)
VALUES ('Default Novel', 'Standard 13-stage novel publishing lifecycle', TRUE, 0)
RETURNING id;

-- Then insert 13 stages into lifecycle_template_stages with that template_id
```

---

## Files to Create/Modify

| File | Action |
|---|---|
| `migrations/20260718_create_lifecycle_engine.sql` | New — all 5 tables + indexes + triggers |
| `migrations/20260718_enable_lifecycle_rls.sql` | New — RLS policies |
| `migrations/20260718_seed_lifecycle_default.sql` | New — default template + stages |
| `scripts/lifecycle-operations.html` | New — all CRUD operations via `_sbDefine` |
| `scripts/lifecycle.html` | Modify — use real data when assigned, interactive stages |
| `scripts/app-state.html` | Modify — expand `lifecycle` state |
| `scripts/el-cache.html` | Modify — add lifecycle modal elements |
| `Client.html` | Modify — add script include for `lifecycle-operations` |
| `Index.html` | Modify — add lifecycle template manager modal HTML |
| `Styles.html` | Modify — template manager + stage detail + approval styles |

---

## Development Order

1. Create migration SQL files (5 tables + RLS + seed)
2. Create `scripts/lifecycle-operations.html` with all CRUD operations
3. Add script include to `Client.html`
4. Expand `appState.lifecycle` with new fields
5. Add template manager modal HTML to `Index.html`
6. Add el-cache entries for modal elements
7. Update `scripts/lifecycle.html`:
   - Add lifecycle loading from Supabase
   - Add assignment UI when no lifecycle exists
   - Make stages interactive
   - Add approval request/decision flow
8. Add styles for template manager, stage detail, approvals
9. Test: assign lifecycle, update stages, request/approve

---

## Phase 2 Deliverables

- [ ] 5 new Supabase tables with RLS
- [ ] Default template seeded with 13 stages
- [ ] CRUD operations for templates, lifecycles, stages, approvals
- [ ] Template manager modal (create/edit/delete custom templates)
- [ ] Lifecycle assignment UI
- [ ] Interactive stage checklist (click to expand/edit)
- [ ] Stage status tracking (pending/in_progress/blocked/complete/skipped)
- [ ] Approval gate flow (request → decide → auto-advance)
- [ ] Fallback to Phase 1 derivation when no lifecycle assigned

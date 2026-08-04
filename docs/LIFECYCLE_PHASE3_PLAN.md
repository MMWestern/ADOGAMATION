# Lifecycle Engine — Phase 3 Plan

## Communication Drafting

---

## Goal

Make the communication queue interactive. Each queue item can generate an AI draft using the existing LLM infrastructure, store it for human review, and push approved content to the Marketing module.

---

## How It Works

```
Lifecycle stage reaches threshold
  → Communication queue populates (display-only)
  → User clicks "Generate Draft" on a queue item
  → System assembles context (project, outline, codex, stage info)
  → System calls LLM with a prompt template for that comm type
  → Draft stored as document_sections (doc_type="lifecycle_comms")
  → User reviews draft in a modal (edit, approve, reject)
  → Approved draft can push to Marketing module campaigns
```

---

## Prompt Templates

Each communication type has a prompt template that assembles project context:

| Type | System Prompt | Context Used |
|---|---|---|
| `newsletter` | "Write a newsletter for subscribers about this upcoming book..." | title, genre, summary, outline, publish_date |
| `social` | "Write a social media campaign post for this book..." | title, genre, summary, hook |
| `launch_email` | "Write a launch day email for this book..." | title, genre, summary, publish_date, pen_name |
| `patreon` | "Write a Patreon update for patrons about this book..." | title, genre, summary, behind-the-scenes notes |
| `royalroad` | "Write a Royal Road announcement for this book..." | title, genre, summary, chapter count |
| `website` | "Write a website article about this book..." | title, genre, summary, full outline |
| `arc` | "Write an ARC (Advance Review Copy) request email..." | title, genre, summary, publish_date |
| `release_summary` | "Write a release summary report..." | title, genre, summary, word count, publish_date, campaigns |

---

## Data Storage

Drafts stored as `document_sections` rows:

```
project_id: <project id>
doc_type: "lifecycle_comms"
section_key: "<comm_type>::<timestamp>"   e.g. "newsletter::1721312400000"
title: "Newsletter Draft"
markdown_content: <generated draft text>
word_count: <count>
sort_order: <timestamp-based>
```

This uses the existing `document_sections` table — no new tables needed.

---

## New CRUD Operations

Add to `scripts/lifecycle-operations.html`:

| Operation | Method Name | Description |
|---|---|---|
| List comms drafts | `listLifecycleCommsDrafts` | Returns all lifecycle_comms sections for a project |
| Save comms draft | `saveLifecycleCommsDraft` | Upserts a lifecycle_comms section |
| Delete comms draft | `deleteLifecycleCommsDraft` | Deletes a lifecycle_comms section |

These reuse the existing `document_sections` table via the existing `saveSupabaseProjectSectionDocumentJsonFromClient` pattern.

---

## UI Changes

### Communication Queue (updated)

Each queue item becomes interactive:

```
┌─────────────────────────────────────────────────────────┐
│ Communication Queue                                      │
│                                                          │
│ ○ Draft Newsletter                          [Generate]   │
│ ○ Draft Social Campaign                     [Generate]   │
│ ○ Draft Launch Email                        [Generate]   │
│ ● Draft Patreon Post — draft ready          [Review]     │
│ ○ Draft Royal Road Announcement             [Generate]   │
│ ○ Draft Website Update                      [Generate]   │
│ ○ Draft ARC Email                           [Generate]   │
│ ○ Draft Release Summary                     [Generate]   │
└─────────────────────────────────────────────────────────┘
```

- ○ = no draft yet (Generate button)
- ● = draft exists (Review button, shows "draft ready" badge)

### Draft Review Modal

```
┌──────────────────────────────────────────────────────────┐
│ Newsletter Draft                              × Close     │
│                                                           │
│ [Edit] [Approve] [Reject] [Delete]                        │
│                                                           │
│ ┌───────────────────────────────────────────────────────┐ │
│ │ Dear readers,                                         │ │
│ │                                                       │ │
│ │ I'm thrilled to announce that my upcoming novel...    │ │
│ │                                                       │ │
│ │ (editable textarea)                                   │ │
│ └───────────────────────────────────────────────────────┘ │
│                                                           │
│ Generated: Jul 18, 2026 3:24 PM                          │
│ Status: Draft                                             │
└──────────────────────────────────────────────────────────┘
```

### Push to Marketing

When a draft is approved, show a "Push to Marketing" button that:
- Creates or updates a campaign task in `projects.campaigns`
- Sets the task name to the comm type label
- Sets the task notes to the draft content summary

---

## Integration Points

1. **AI**: Uses `callEditorAI()` from `scripts/markdown-utils.html` — same as CHAT module
2. **Context**: Uses `buildChatContextContent()` pattern — assembles project metadata, outline, codex
3. **Storage**: Uses `document_sections` with `doc_type="lifecycle_comms"` — same pattern as draft/notes/fixes
4. **Marketing**: Mutates `project.campaigns` array — same pattern as auto-generated marketing campaigns

---

## Files to Modify

| File | Action |
|---|---|
| `scripts/lifecycle-operations.html` | Add 3 new CRUD operations for comms drafts |
| `scripts/lifecycle.html` | Make comms queue interactive, add draft generation, review modal logic |
| `Index.html` | Add draft review modal HTML |
| `scripts/el-cache.html` | Add draft review modal element cache entries |
| `Styles.html` | Add draft review modal + comms queue interactive styles |

No new tables needed — uses existing `document_sections`.

---

## Development Order

1. Add CRUD operations for comms drafts
2. Add prompt templates for each comm type
3. Update comms queue rendering to show Generate/Review buttons
4. Add draft generation flow (assemble context → call LLM → save to Supabase)
5. Add draft review modal HTML
6. Add draft review modal logic (load, edit, approve, reject, delete)
7. Add "Push to Marketing" flow
8. Add styles
9. Test

---

## Phase 3 Deliverables

- [ ] 3 new CRUD operations for comms drafts
- [ ] 8 prompt templates (one per comm type)
- [ ] Interactive comms queue with Generate/Review buttons
- [ ] AI draft generation using existing LLM infrastructure
- [ ] Drafts stored as document_sections (doc_type="lifecycle_comms")
- [ ] Draft review modal (edit, approve, reject, delete)
- [ ] "Push to Marketing" integration
- [ ] Status tracking (draft → reviewed → approved → published)

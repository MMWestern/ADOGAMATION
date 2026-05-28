# Deployment Guide — ADOGAMATION PRESS DASHBOARD

## Quick Reference

| Setting | Value |
|---------|-------|
| **Repo** | `github.com/MMWestern/ADOGAMATION` |
| **Framework** | None (static site) |
| **Build Command** | `node build.js` |
| **Output Directory** | `build` |
| **Node Version** | 18+ (auto-detected) |

## Vercel Environment Variables

Set in **Vercel → Settings → Environment Variables** (scoped to Production):

| Variable | Value | Notes |
|----------|-------|-------|
| `SUPABASE_URL` | `https://bmssizjfkowberhhpyff.supabase.co` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `sb_publishable_EKu02_P-UB2B1XsiEu0EVA_alsEMO3t` | Supabase publishable key |
| `COMFYUI_ENDPOINT` | *(optional)* | Local ComfyUI proxy for image gen (dev only) |

> After changing env vars, you **must redeploy** — Vercel doesn't hot-reload them.

## Local Development

```bash
npm run dev        # Starts dev server on http://localhost:3000
```

Requires a local `.env` file:
```
SUPABASE_URL=https://bmssizjfkowberhhpyff.supabase.co
SUPABASE_ANON_KEY=sb_publishable_EKu02_P-UB2B1XsiEu0EVA_alsEMO3t
COMFYUI_ENDPOINT=http://127.0.0.1:8188
```

## Architecture

```
Index.html          ← Entry point, includes Styles.html + Client.html
Client.html         ← All app logic (21k lines), Supabase CRUD via supabaseRunner Proxy
Styles.html         ← All CSS (11.5k lines)
build.js            ← Build script: processes HTML includes, copies assets, generates env.js
dev-server.js       ← Local dev server (Node http, port 3000)
api/env.js          ← Supabase credentials endpoint (not used in production, build generates env.js)
vercel.json         ← Vercel config: buildCommand + outputDirectory
data/               ← Story seed engine JSON
```

## Build Pipeline

`node build.js` does:
1. Cleans `build/` directory
2. Processes `<?!= include('...'); ?>` directives in HTML files
3. Outputs `index.html`, `Client.html`, `Styles.html` to `build/`
4. Copies static assets (JS, CSS, images, data) to `build/`
5. Generates `build/env.js` with Supabase credentials from environment variables

## Key Gotchas

- **`Index.html` must be lowercase** in build output — Vercel serves `index.html` not `Index.html`
- **`api/env.js` is gitignored** by `/env.js` pattern — the root `env.js` is for local dev only
- **`dist/` directory** is a legacy artifact with deep nesting on Windows — ignore it, use `build/`
- **`dev-server.js`** was renamed from `server.js` to prevent Vercel entrypoint detection
- **No `engines` field** in `package.json` — Vercel treats it as static, not Node.js server

## Supabase

- **Project**: `bmssizjfkowberhhpyff`
- **Dashboard**: `https://supabase.com/dashboard/project/bmssizjfkowberhhpyff`
- **Tables**: projects, series, documents, document_sections, image_assets, general_resources, series_characters, series_locations, series_continuity_entries, book_creator_pockets

## Redeploy

Push to `main` triggers auto-deploy. Manual: Vercel → Deployments → ⋯ → Redeploy.

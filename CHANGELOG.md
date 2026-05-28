# Changelog

## v1.0.0 (2026-05-28)

### Features
- Direct Supabase browser access (no Google Apps Script dependency)
- Project CRUD (create, read, update, delete)
- Series management with metadata
- Document sections (draft, outline, notes) with markdown content
- Image upload via Supabase Storage (project-images bucket)
- Image picker with lazy loading and caching
- AI settings stored in localStorage (LM Studio, Ollama, OpenRouter)
- AI completion via browser fetch to local providers
- Book Creator pockets from Supabase table
- Story Seed Engine from local JSON file
- ComfyUI image generation proxy
- Dark mode support
- Real-time status updates

### Technical
- Supabase direct browser access via UMD SDK
- supabaseRunner Proxy pattern for method interception
- _sbDefine pattern for incremental migration
- Dev server with no-cache headers
- Vercel deployment support

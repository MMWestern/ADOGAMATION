const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const DIST = path.join(ROOT, "dist");

// Clean dist (with retries for Windows long-path issues)
if (fs.existsSync(DIST)) {
  fs.rmSync(DIST, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
fs.mkdirSync(DIST, { recursive: true });

function readFile(filePath) {
  try { return fs.readFileSync(filePath, "utf8"); } catch { return null; }
}

function processIncludes(content) {
  return content.replace(/<\?!= include\(['"]([^'"]+)['"]\); \?>/g, (_, filename) => {
    const filePath = path.join(ROOT, filename + ".html");
    const included = readFile(filePath);
    if (included === null) {
      console.warn(`[WARN] Include not found: ${filename}.html`);
      return `<!-- MISSING: ${filename} -->`;
    }
    return included;
  });
}

const HTML_FILES = ["Index.html", "Client.html", "Styles.html"];
const STATIC_EXTS = new Set([".css", ".js", ".json", ".png", ".jpg", ".svg", ".ico", ".woff", ".woff2"]);
const SKIP_DIRS = new Set(["node_modules", ".git", "dist", ".env"]);

console.log("Building for Vercel...");

// Process HTML includes
console.log("Processing HTML includes...");
for (const htmlFile of HTML_FILES) {
  const srcPath = path.join(ROOT, htmlFile);
  const destPath = path.join(DIST, htmlFile);
  if (fs.existsSync(srcPath)) {
    const raw = readFile(srcPath);
    const processed = processIncludes(raw);
    fs.writeFileSync(destPath, processed, "utf8");
    console.log(`  ${htmlFile} -> dist/${htmlFile}`);
  } else {
    console.warn(`[WARN] ${htmlFile} not found`);
  }
}

// Copy static assets from specific subdirectories only
console.log("Copying static assets...");
function copyStaticAssets(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    if (SKIP_DIRS.has(entry.name)) continue;
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyStaticAssets(srcPath, destPath);
    } else if (STATIC_EXTS.has(path.extname(entry.name).toLowerCase())) {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}
copyStaticAssets(ROOT, DIST);

// Generate env.js with Supabase credentials from environment variables
console.log("Generating env.js...");
const supabaseKeys = Object.keys(process.env).filter(k => k.includes("SUPABASE"));
console.log("  SUPABASE env var keys found:", supabaseKeys.length ? supabaseKeys.join(", ") : "(none)");
const envUrl = process.env.SUPABASE_URL || "";
const envKey = process.env.SUPABASE_ANON_KEY || "";
const envJs = 'window.__SUPABASE_URL__=' + JSON.stringify(envUrl) + ';\n' +
              'window.__SUPABASE_ANON_KEY__=' + JSON.stringify(envKey) + ';\n';
fs.writeFileSync(path.join(DIST, "env.js"), envJs, "utf8");
console.log(`  env.js -> dist/env.js (url=${envUrl ? "set" : "EMPTY"}, key=${envKey ? "set" : "EMPTY"})`);

// Copy data files
const dataDir = path.join(ROOT, "data");
if (fs.existsSync(dataDir)) {
  const distData = path.join(DIST, "data");
  fs.mkdirSync(distData, { recursive: true });
  for (const f of fs.readdirSync(dataDir)) {
    fs.copyFileSync(path.join(dataDir, f), path.join(distData, f));
  }
}

console.log("Build complete. Output in dist/");

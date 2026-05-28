const fs = require("fs");
const path = require("path");

const ROOT = __dirname;

// Load .env
let envConfig = {};
try {
  const envRaw = fs.readFileSync(path.join(ROOT, ".env"), "utf8");
  envRaw.split("\n").forEach(line => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) return;
    const eqIdx = trimmed.indexOf("=");
    if (eqIdx === -1) return;
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim();
    if (key) envConfig[key] = val;
  });
} catch {
  console.warn("[WARN] No .env file found.");
}

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch {
    return null;
  }
}

function processIncludes(content) {
  return content.replace(/<\?!= include\(['"]([^'"]+)['"]\); \?>/g, (_, filename) => {
    const filePath = path.join(ROOT, filename + ".html");
    const included = readFile(filePath);
    if (included === null) {
      console.warn(`[WARN] Include not found: ${filename}.html`);
      return `<!-- MISSING INCLUDE: ${filename} -->`;
    }
    return included;
  });
}

// Generate env.js
const envJsContent = `window.__SUPABASE_URL__ = ${JSON.stringify(envConfig.SUPABASE_URL || "")};
window.__SUPABASE_ANON_KEY__ = ${JSON.stringify(envConfig.SUPABASE_ANON_KEY || "")};
`;
fs.mkdirSync(path.join(ROOT, "dist"), { recursive: true });
fs.writeFileSync(path.join(ROOT, "dist", "env.js"), envJsContent, "utf8");

// Build index.html
const indexPath = path.join(ROOT, "Index.html");
const raw = readFile(indexPath);
if (raw === null) {
  console.error("Index.html not found");
  process.exit(1);
}

const built = processIncludes(raw);
const outPath = path.join(ROOT, "dist", "index.html");
fs.writeFileSync(outPath, built, "utf8");

// Copy static assets
["Client.html", "Styles.html"].forEach((f) => {
  const src = path.join(ROOT, f);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, path.join(ROOT, "dist", f));
  }
});

console.log(`Built to ${outPath}`);

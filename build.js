const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const DIST = path.join(ROOT, "dist");

// Clean dist
if (fs.existsSync(DIST)) fs.rmSync(DIST, { recursive: true });
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

// Only copy these specific files/dirs
const HTML_FILES = ["Index.html", "Client.html", "Styles.html"];
const STATIC_DIRS = ["node_modules"];
const STATIC_FILES = [".css", ".js", ".json", ".png", ".jpg", ".svg", ".ico", ".woff", ".woff2"];

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

// Copy static assets (only from specific directories)
console.log("Copying static assets...");
function copyStaticAssets(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      // Skip node_modules and .git
      if (entry.name === "node_modules" || entry.name === ".git" || entry.name === "dist") continue;
      copyStaticAssets(srcPath, destPath);
    } else if (STATIC_FILES.includes(path.extname(entry.name).toLowerCase())) {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}
copyStaticAssets(ROOT, DIST);

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

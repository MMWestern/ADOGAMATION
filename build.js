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

// Copy static assets
const staticExts = [".css", ".js", ".json", ".png", ".jpg", ".svg", ".ico", ".woff", ".woff2"];
function copyDir(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else if (staticExts.includes(path.extname(entry.name).toLowerCase())) {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// Process and copy HTML files
function processHtml(src, dest) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      processHtml(srcPath, destPath);
    } else if (entry.name.endsWith(".html")) {
      const raw = readFile(srcPath);
      if (raw) {
        const processed = processIncludes(raw);
        fs.writeFileSync(destPath, processed, "utf8");
        console.log(`  ${entry.name} -> dist/${entry.name}`);
      }
    }
  }
}

console.log("Building for Vercel...");
console.log("Processing HTML includes...");
processHtml(ROOT, DIST);

console.log("Copying static assets...");
copyDir(ROOT, DIST);

// Copy data files
const dataDir = path.join(ROOT, "data");
if (fs.existsSync(dataDir)) {
  const distData = path.join(DIST, "data");
  fs.mkdirSync(distData, { recursive: true });
  for (const f of fs.readdirSync(dataDir)) {
    fs.copyFileSync(path.join(dataDir, f), path.join(distData, f));
  }
}

// Remove source HTML from dist (already processed)
for (const f of fs.readdirSync(DIST)) {
  if (f.endsWith(".html") && f !== "Index.html") {
    // Keep only Index.html (the processed one)
  }
}

console.log("Build complete. Output in dist/");

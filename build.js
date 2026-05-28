const fs = require("fs");
const path = require("path");

const ROOT = __dirname;

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

const indexPath = path.join(ROOT, "Index.html");
const raw = readFile(indexPath);
if (raw === null) {
  console.error("Index.html not found");
  process.exit(1);
}

const built = processIncludes(raw);
const outPath = path.join(ROOT, "dist", "index.html");
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, built, "utf8");

// Also copy static assets
["Client.html", "Styles.html"].forEach((f) => {
  const src = path.join(ROOT, f);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, path.join(ROOT, "dist", f));
  }
});

console.log(`Built to ${outPath}`);

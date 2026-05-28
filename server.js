const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = 3000;
const ROOT = __dirname;

const MIME = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "text/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

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
  console.warn("[WARN] No .env file found. Supabase calls will fail.");
}

const fileCache = new Map();

function readFile(filePath) {
  if (fileCache.has(filePath)) return fileCache.get(filePath);
  try {
    const content = fs.readFileSync(filePath, "utf8");
    fileCache.set(filePath, content);
    return content;
  } catch {
    return null;
  }
}

function processIncludes(content) {
  return content.replace(/<\?!= include\(['"]([^'"]+)['"]\); \?>/g, (_, filename) => {
    const filePath = path.join(ROOT, filename + ".html");
    const included = readFile(filePath);
    if (included === null) {
      console.warn(`[404] Include not found: ${filename}.html`);
      return `<!-- MISSING INCLUDE: ${filename} -->`;
    }
    return included;
  });
}

var ENV_JS_CONTENT = 'window.__SUPABASE_URL__=' + JSON.stringify(envConfig.SUPABASE_URL || '') + ';\n' +
  'window.__SUPABASE_ANON_KEY__=' + JSON.stringify(envConfig.SUPABASE_ANON_KEY || '') + ';\n';

const server = http.createServer((req, res) => {
  let urlPath = req.url.split("?")[0];
  if (urlPath === "/") urlPath = "/Index.html";
  if (urlPath === "/env.js") {
    res.writeHead(200, { "Content-Type": "application/javascript; charset=utf-8" });
    res.end(ENV_JS_CONTENT);
    return;
  }

  const filePath = path.join(ROOT, urlPath);
  const ext = path.extname(filePath);

  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  if (!fs.existsSync(filePath)) {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("Not found: " + urlPath);
    return;
  }

  if (ext === ".html") {
    const raw = readFile(filePath);
    if (raw === null) {
      res.writeHead(500);
      res.end("Error reading file");
      return;
    }
    const processed = processIncludes(raw);
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(processed);
  } else {
    const mime = MIME[ext] || "application/octet-stream";
    const content = fs.readFileSync(filePath);
    res.writeHead(200, { "Content-Type": mime });
    res.end(content);
  }
});

server.listen(PORT, () => {
  console.log(`Writing app dev server running at http://localhost:${PORT}`);
  console.log(`Serving from: ${ROOT}`);
  if (envConfig.SUPABASE_URL) {
    console.log("Supabase config loaded from .env");
  }
});

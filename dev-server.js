const http = require("http");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");

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
      console.warn(`[404] Include not found: ${filename}.html`);
      return `<!-- MISSING INCLUDE: ${filename} -->`;
    }
    return included;
  });
}

var ENV_JS_CONTENT = 'window.__SUPABASE_URL__=' + JSON.stringify(envConfig.SUPABASE_URL || '') + ';\n' +
  'window.__SUPABASE_ANON_KEY__=' + JSON.stringify(envConfig.SUPABASE_ANON_KEY || '') + ';\n';

const STORY_SEED_DATA_FILE = path.join(ROOT, "data", "story_seed_engine.json");

const NO_CACHE_HEADERS = {
  "Cache-Control": "no-cache, no-store, must-revalidate",
  "Pragma": "no-cache",
  "Expires": "0"
};

const server = http.createServer((req, res) => {
  let urlPath = req.url.split("?")[0];
  if (urlPath === "/") urlPath = "/Index.html";
  if (urlPath === "/env.js") {
    res.writeHead(200, Object.assign({ "Content-Type": "application/javascript; charset=utf-8" }, NO_CACHE_HEADERS));
    res.end(ENV_JS_CONTENT);
    return;
  }

  if (urlPath.startsWith("/api/comfy/")) {
    const comfyBase = (envConfig.COMFYUI_ENDPOINT || "http://127.0.0.1:8188").replace(/\/+$/, "");
    const comfyPath = urlPath.replace("/api/comfy", "") || "/";
    const comfyUrl = comfyBase + comfyPath + (req.url.includes("?") ? "?" + req.url.split("?")[1] : "");
    const proxyReq = http.request(comfyUrl, {
      method: req.method,
      headers: Object.assign({}, req.headers, { host: new URL(comfyUrl).host })
    }, function (proxyRes) {
      const headers = Object.assign({}, proxyRes.headers, {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, DELETE, PUT, OPTIONS, PATCH",
        "Access-Control-Allow-Headers": "Content-Type, Authorization"
      });
      res.writeHead(proxyRes.statusCode, headers);
      proxyRes.pipe(res);
    });
    proxyReq.on("error", function (err) {
      res.writeHead(502, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "ComfyUI proxy error: " + err.message }));
    });
    req.pipe(proxyReq);
    return;
  }

  if (req.method === "OPTIONS" && req.headers.origin) {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, DELETE, PUT, OPTIONS, PATCH",
      "Access-Control-Allow-Headers": "Content-Type, Authorization"
    });
    res.end();
    return;
  }

  if (urlPath === "/api/story-seed-engine") {
    try {
      const data = fs.readFileSync(STORY_SEED_DATA_FILE, "utf8");
      res.writeHead(200, Object.assign({ "Content-Type": "application/json; charset=utf-8" }, NO_CACHE_HEADERS));
      res.end(data);
    } catch {
      res.writeHead(200, Object.assign({ "Content-Type": "application/json; charset=utf-8" }, NO_CACHE_HEADERS));
      res.end(JSON.stringify({ ok: true, options: {}, engine: {}, sourceData: {}, rowCount: 0, warning: "data/story_seed_engine.json not found." }));
    }
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
    res.writeHead(404, Object.assign({ "Content-Type": "text/plain" }, NO_CACHE_HEADERS));
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
    res.writeHead(200, Object.assign({ "Content-Type": "text/html; charset=utf-8" }, NO_CACHE_HEADERS));
    res.end(processed);
  } else {
    const mime = MIME[ext] || "application/octet-stream";
    const content = fs.readFileSync(filePath);
    res.writeHead(200, Object.assign({ "Content-Type": mime }, NO_CACHE_HEADERS));
    res.end(content);
  }
});

server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log(`Writing app dev server running at ${url}`);
  console.log(`Serving from: ${ROOT}`);
  if (envConfig.SUPABASE_URL) {
    console.log("Supabase config loaded from .env");
  }
  // Auto-open browser
  const open = process.platform === "win32" ? "start" : process.platform === "darwin" ? "open" : "xdg-open";
  exec(`${open} ${url}`, (err) => {
    if (err) console.log(`Could not auto-open browser. Navigate to ${url} manually.`);
    else console.log("Browser opened.");
  });
});

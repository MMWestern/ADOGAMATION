const http = require("http");
const https = require("https");
const { URL } = require("url");

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, PUT, OPTIONS, PATCH");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    return res.status(204).end();
  }

  const comfyEndpoint = (req.headers["x-comfy-endpoint"] || process.env.COMFYUI_ENDPOINT || "").replace(/\/+$/, "");
  if (!comfyEndpoint) {
    return res.status(400).json({ error: "No ComfyUI endpoint configured. Set x-comfy-endpoint header or COMFYUI_ENDPOINT env var." });
  }

  const subPath = (req.query.path || "").replace(/^\/+/, "");
  const targetUrl = comfyEndpoint + (subPath ? "/" + subPath : "");

  try {
    const parsed = new URL(targetUrl);
    const transport = parsed.protocol === "https:" ? https : http;

    const proxyReq = transport.request(targetUrl, {
      method: req.method,
      headers: {
        "content-type": req.headers["content-type"] || "application/json",
        "accept": req.headers["accept"] || "*/*",
      },
    }, (proxyRes) => {
      res.status(proxyRes.statusCode);
      Object.entries(proxyRes.headers).forEach(([k, v]) => {
        if (k !== "transfer-encoding") res.setHeader(k, v);
      });
      const chunks = [];
      proxyRes.on("data", (chunk) => chunks.push(chunk));
      proxyRes.on("end", () => {
        const body = Buffer.concat(chunks);
        res.setHeader("content-length", body.length);
        res.end(body);
      });
    });

    proxyReq.on("error", (err) => {
      if (!res.headersSent) {
        res.status(502).json({ error: "ComfyUI connection failed: " + err.message });
      }
    });

    if (req.body) {
      const bodyStr = typeof req.body === "string" ? req.body : JSON.stringify(req.body);
      proxyReq.write(bodyStr);
    }
    proxyReq.end();
  } catch (err) {
    res.status(500).json({ error: "Proxy error: " + err.message });
  }
};

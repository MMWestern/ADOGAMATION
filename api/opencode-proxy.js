const https = require("https");
const http = require("http");

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, PUT, OPTIONS, PATCH");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, x-api-key");

  if (req.method === "OPTIONS") {
    return res.status(204).end();
  }

  const apiKey = req.headers["x-api-key"] || "";
  const subPath = (req.query.path || "").replace(/^\/+/, "");
  const targetUrl = "https://opencode.ai/zen/v1" + (subPath ? "/" + subPath : "");

  try {
    const headers = {
      "Content-Type": req.headers["content-type"] || "application/json",
    };
    if (apiKey) headers["Authorization"] = "Bearer " + apiKey;

    const proxyReq = https.request(targetUrl, {
      method: req.method,
      headers: headers,
    }, (proxyRes) => {
      res.status(proxyRes.statusCode);
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
        res.status(502).json({ error: "Opencode proxy error: " + err.message });
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

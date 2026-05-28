module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, DELETE, PUT, OPTIONS, PATCH");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, x-comfy-endpoint");

  if (req.method === "OPTIONS") {
    return res.status(204).end();
  }

  res.status(503).json({
    error: "ComfyUI is only available when running locally (http://localhost:3000). The Vercel server cannot reach your local ComfyUI instance."
  });
};

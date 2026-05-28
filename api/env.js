module.exports = function handler(req, res) {
  res.setHeader("Content-Type", "application/javascript; charset=utf-8");
  res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
  res.setHeader("Access-Control-Allow-Origin", "*");

  if (req.query && req.query.debug) {
    const envKeys = Object.keys(process.env).filter(k =>
      k.includes("SUPABASE") || k.includes("VERCEL") || k.includes("NODE")
    );
    return res.status(200).json({
      hasUrl: !!process.env.SUPABASE_URL,
      hasKey: !!process.env.SUPABASE_ANON_KEY,
      urlLength: (process.env.SUPABASE_URL || "").length,
      keyLength: (process.env.SUPABASE_ANON_KEY || "").length,
      matchingKeys: envKeys,
      nodeEnv: process.env.NODE_ENV,
      vercelEnv: process.env.VERCEL_ENV,
    });
  }

  const url = process.env.SUPABASE_URL || "";
  const key = process.env.SUPABASE_ANON_KEY || "";
  res.status(200).send(
    'window.__SUPABASE_URL__=' + JSON.stringify(url) + ';\n' +
    'window.__SUPABASE_ANON_KEY__=' + JSON.stringify(key) + ';\n'
  );
};

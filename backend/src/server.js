
const express = require("express");
const cors = require("cors");
const http = require("node:http");

const { getDatabaseConfigError, pool } = require("./db");
const { ensureDatabaseSchema } = require("./schema");
const { attachRealtime } = require("./realtime");

const app = express();
const port = Number(process.env.PORT || 5050);
const host = process.env.HOST || "127.0.0.1";

app.use(cors());
app.use(express.json({ limit: "5mb" }));

app.get("/", (req, res) => {
  res.json({ message: "Nway Love Vet Clinic API is running" });
});

app.get("/health", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW() AS server_time");
    res.json({
      status: "ok",
      database: "connected",
      serverTime: result.rows[0].server_time,
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      database: "disconnected",
      message: error.message,
    });
  }
});

require("./api").installApi(app, pool);

const server = http.createServer(app);
attachRealtime(server, pool);

async function start() {
  const configError = getDatabaseConfigError();
  if (configError) throw new Error(configError);
  await ensureDatabaseSchema();
  return server.listen(port, host, () => console.log(`Clinic API + realtime ready at http://${host}:${port}`));
}
if (require.main === module) {
  start().catch(error => { console.error('API startup failed:', error.message); pool.end(); process.exitCode = 1; });
}
module.exports = { app, server, pool, start };

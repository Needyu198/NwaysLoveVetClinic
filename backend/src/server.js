
const express = require("express");
const cors = require("cors");
const http = require("node:http");

const { getDatabaseConfigError, pool } = require("./db");
const { ensureDatabaseSchema } = require("./schema");
const { attachRealtime } = require("./realtime");
const {
  startAppointmentReminderScheduler,
  stopAppointmentReminderScheduler,
} = require("./appointmentReminders");
const { installApi, expirePendingMmqrPayments, processReceiptDeliveryJobs } = require('./api');

const app = express();
// Render terminates HTTPS at one trusted reverse proxy. This preserves the
// real client IP used by password-reset rate limiting.
app.set('trust proxy', 1);
const port = Number(process.env.PORT || 5050);
// Listen on every network interface by default so phones and other clinic
// devices can reach the API. Internet access still requires a public HTTPS
// deployment (or a tunnel) and must not expose PostgreSQL directly.
const host = process.env.HOST || "0.0.0.0";

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

installApi(app, pool);

const server = http.createServer(app);
attachRealtime(server, pool);

async function start() {
  const configError = getDatabaseConfigError();
  if (configError) throw new Error(configError);
  await ensureDatabaseSchema();
  startAppointmentReminderScheduler();
  const expirePayments = () => expirePendingMmqrPayments(pool).catch(error =>
    console.error('MMQR expiry worker failed:', error.message));
  await expirePayments();
  const mmqrExpiryTimer = setInterval(expirePayments, 60_000);
  mmqrExpiryTimer.unref();
  server.once('close', () => clearInterval(mmqrExpiryTimer));
  const deliverReceipts = () => processReceiptDeliveryJobs(pool).catch(error =>
    console.error('Receipt delivery worker failed:', error.message));
  const receiptDeliveryTimer = setInterval(deliverReceipts, 30_000);
  receiptDeliveryTimer.unref();
  server.once('close', () => clearInterval(receiptDeliveryTimer));
  return server.listen(port, host, () => console.log(`Clinic API + realtime ready at http://${host}:${port}`));
}
server.on('close', stopAppointmentReminderScheduler);
if (require.main === module) {
  start().catch(error => { console.error('API startup failed:', error); pool.end(); process.exitCode = 1; });
}
module.exports = { app, server, pool, start };

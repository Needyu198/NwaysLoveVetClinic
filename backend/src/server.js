require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
const port = Number(process.env.PORT || 5000);
const dbPassword =
  process.env.DB_PASSWORD && process.env.DB_PASSWORD.trim() !== ""
    ? process.env.DB_PASSWORD
    : undefined;

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || "NwayLoveVetClinicSever",
  user: process.env.DB_USER || "postgres",
  password: dbPassword,
  connectionTimeoutMillis: Number(process.env.DB_CONNECTION_TIMEOUT_MS || 5000),
});

app.use(cors());
app.use(express.json());

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

app.listen(port, async () => {
  console.log(`Server running on http://localhost:${port}`);

  try {
    await pool.query("SELECT 1");
    console.log("Connected to PostgreSQL database NwayLoveVetClinicSever");
  } catch (error) {
    console.error("PostgreSQL connection failed:", error.message);
  }
});

module.exports = { app, pool };

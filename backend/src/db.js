require("dotenv").config();

const { Pool } = require("pg");

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

module.exports = { pool };

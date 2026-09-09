require("dotenv").config({ path: require("node:path").join(__dirname, "../.env"), quiet: true });

const { Pool } = require("pg");

// A single connection string (Neon, Render, Supabase, etc.) takes priority.
// Fall back to the discrete DB_* variables for local development.
const connectionString = (process.env.DATABASE_URL || "").trim();

const dbUser = process.env.DB_USER || "postgres";
const dbPassword = process.env.DB_PASSWORD || "";

function getDatabaseConfigError() {
  // When a connection string is provided its own credentials are used, so the
  // discrete-variable check does not apply.
  if (connectionString) return null;

  if (dbUser === "postgres" && dbPassword.trim() === "") {
    return "DB_PASSWORD is required for PostgreSQL user 'postgres'. Add it to backend/.env or set DB_USER to a passwordless local role.";
  }

  return null;
}

// Hosted providers require TLS. Enable SSL automatically when a connection
// string asks for it (sslmode=require) or when DB_SSL=true is set explicitly.
const sslFromUrl = /[?&]sslmode=require/i.test(connectionString);
const sslEnabled = process.env.DB_SSL === "true" || sslFromUrl;

console.log(
  "Database:",
  connectionString ? "connection string" : "discrete DB_* vars",
  "| SSL enabled:",
  sslEnabled
);

const commonOptions = {
  ssl: sslEnabled
    ? { rejectUnauthorized: process.env.DB_SSL_STRICT === "true" }
    : false,
  connectionTimeoutMillis: Number(process.env.DB_CONNECTION_TIMEOUT_MS || 5000),
};

const pool = connectionString
  ? new Pool({ connectionString, ...commonOptions })
  : new Pool({
      host: process.env.DB_HOST || "localhost",
      port: Number(process.env.DB_PORT || 5432),
      database: process.env.DB_NAME || "NwayLoveVetClinicSever",
      user: dbUser,
      password: dbPassword,
      ...commonOptions,
    });

module.exports = { getDatabaseConfigError, pool };

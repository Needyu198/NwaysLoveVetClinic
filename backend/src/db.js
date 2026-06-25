require("dotenv").config();

const { Pool } = require("pg");

const dbUser = process.env.DB_USER || "postgres";
const dbPassword = process.env.DB_PASSWORD || "";

function getDatabaseConfigError() {
  if (dbUser === "postgres" && dbPassword.trim() === "") {
    return "DB_PASSWORD is required for PostgreSQL user 'postgres'. Add it to backend/.env or set DB_USER to a passwordless local role.";
  }

  return null;
}

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || "NwayLoveVetClinicSever",
  user: dbUser,
  password: dbPassword,
  connectionTimeoutMillis: Number(process.env.DB_CONNECTION_TIMEOUT_MS || 5000),
});

module.exports = { getDatabaseConfigError, pool };

const { pool } = require("./db");

async function ensureDatabaseSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS pet_owners (
      id SERIAL PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      full_name TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
}

module.exports = { ensureDatabaseSchema };

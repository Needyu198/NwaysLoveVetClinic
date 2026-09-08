const { pool } = require('./db');
const { resources } = require('./resources');
async function ensureDatabaseSchema(database = pool) {
  const client = await database.connect();
  try {
    await client.query('BEGIN');
    await client.query(`CREATE TABLE IF NOT EXISTS pet_owners (
      id SERIAL PRIMARY KEY, username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL, full_name TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
    await client.query(`CREATE TABLE IF NOT EXISTS app_accounts (
      id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL, full_name TEXT NOT NULL DEFAULT '',
      role TEXT NOT NULL CHECK(role IN ('petOwner','doctor','staff','systemAdmin')),
      active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
    const existingUsers = await client.query("SELECT to_regclass('app_users') AS table_name");
    if (existingUsers.rows[0].table_name) {
      await client.query(`INSERT INTO app_accounts(id,username,password_hash,full_name,role)
        SELECT 'user-' || id,username,password_hash,username,
          CASE role WHEN 'owner' THEN 'petOwner' WHEN 'admin' THEN 'systemAdmin' ELSE role END
        FROM app_users WHERE role IN ('owner','petOwner','admin','systemAdmin','doctor','staff')
        ON CONFLICT DO NOTHING`);
    }
    await client.query(`INSERT INTO app_accounts(id,username,password_hash,full_name,role)
      SELECT 'owner-' || id,username,password_hash,COALESCE(full_name,username),'petOwner'
      FROM pet_owners ON CONFLICT DO NOTHING`);
    await client.query(`CREATE TABLE IF NOT EXISTS app_sessions (
      token_hash TEXT PRIMARY KEY, account_id TEXT NOT NULL,
      role TEXT NOT NULL, expires_at TIMESTAMPTZ NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
    // Device tokens for Firebase Cloud Messaging push delivery.
    await client.query(`CREATE TABLE IF NOT EXISTS device_tokens (
      token TEXT PRIMARY KEY, account_id TEXT NOT NULL,
      platform TEXT NOT NULL DEFAULT 'unknown',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
    await client.query(`CREATE INDEX IF NOT EXISTS device_tokens_account_idx ON device_tokens(account_id)`);
    for (const table of Object.keys(resources)) {
      await client.query(`CREATE TABLE IF NOT EXISTS ${table} (
        id TEXT PRIMARY KEY, owner_id TEXT NOT NULL,
        data JSONB NOT NULL CHECK(jsonb_typeof(data) = 'object'),
        version INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`);
      await client.query(`CREATE INDEX IF NOT EXISTS ${table}_owner_idx ON ${table}(owner_id)`);
    }
    await client.query(`INSERT INTO user_directory(id,owner_id,data)
      SELECT 'account:' || id, id,
        jsonb_build_object('key','account:' || id,'value',jsonb_build_object(
          'id',id,'name',full_name,'email',username,'phone','','role',
          CASE role WHEN 'petOwner' THEN 'owner' WHEN 'systemAdmin' THEN 'admin' ELSE role END,
          'status',CASE WHEN active THEN 'active' ELSE 'suspended' END,
          'lastActive','', 'createdOn',created_at)) FROM app_accounts
      ON CONFLICT DO NOTHING`);
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally { client.release(); }
}
module.exports = { ensureDatabaseSchema };

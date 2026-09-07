const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const { ensureDatabaseSchema } = require('../src/schema');
const { pool } = require('../src/db');
async function main() {
  const [username, role, fullName = username] = process.argv.slice(2);
  const password = process.env.ACCOUNT_PASSWORD;
  if (!username || !['petOwner','doctor','staff','systemAdmin'].includes(role) || !password || password.length < 8) {
    throw new Error('Usage: ACCOUNT_PASSWORD=<8+ characters> npm run account:create -- <username> <petOwner|doctor|staff|systemAdmin> [full name]');
  }
  await ensureDatabaseSchema();
  await pool.query('INSERT INTO app_accounts(id,username,password_hash,full_name,role) VALUES($1,$2,$3,$4,$5)',
    [crypto.randomUUID(), username, await bcrypt.hash(password,12), fullName, role]);
  await ensureDatabaseSchema();
  console.log('Account created.');
}
main().catch(e => {console.error(e.message);process.exitCode=1}).finally(()=>pool.end());

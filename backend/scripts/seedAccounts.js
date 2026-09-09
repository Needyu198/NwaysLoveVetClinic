// Seeds the four default accounts (pet owner, doctor, staff, admin).
// Idempotent: existing usernames are updated in place (password + role + name),
// missing ones are inserted. Run against whichever database backend/.env (or the
// process environment) points to.
//
//   node scripts/seedAccounts.js            (uses backend/.env)
//   DB_HOST=... DB_PASSWORD=... node scripts/seedAccounts.js   (override, e.g. Render)
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const { ensureDatabaseSchema } = require('../src/schema');
const { pool } = require('../src/db');

const ACCOUNTS = [
  { username: 'petowner', password: 'Owner@123', role: 'petOwner', fullName: 'Pet Owner' },
  { username: 'doctor', password: 'Doctor@123', role: 'doctor', fullName: 'Doctor' },
  { username: 'staff', password: 'Staff@123', role: 'staff', fullName: 'Staff' },
  { username: 'admin', password: 'Admin@123', role: 'systemAdmin', fullName: 'Administrator' },
];

async function upsertAccount({ username, password, role, fullName }) {
  const passwordHash = await bcrypt.hash(password, 12);
  const existing = (
    await pool.query('SELECT id FROM app_accounts WHERE username = $1', [username])
  ).rows[0];
  if (existing) {
    await pool.query(
      'UPDATE app_accounts SET password_hash=$2, full_name=$3, role=$4, active=TRUE WHERE id=$1',
      [existing.id, passwordHash, fullName, role],
    );
    return `updated ${username} (${role})`;
  }
  await pool.query(
    'INSERT INTO app_accounts(id, username, password_hash, full_name, role) VALUES($1,$2,$3,$4,$5)',
    [crypto.randomUUID(), username, passwordHash, fullName, role],
  );
  return `created ${username} (${role})`;
}

async function main() {
  await ensureDatabaseSchema();
  for (const account of ACCOUNTS) {
    const result = await upsertAccount(account);
    console.log(result);
  }
  // Re-run schema sync so the accounts propagate into user_directory.
  await ensureDatabaseSchema();
  console.log('Seeding complete.');
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());

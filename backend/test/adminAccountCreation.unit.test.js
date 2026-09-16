const { test } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');
const { syncUserDirectoryAccount } = require('../src/api');

class FakeClient {
  constructor() {
    this.accounts = new Map();
  }

  async query(sql, params = []) {
    if (sql.includes('SELECT id FROM app_accounts WHERE id=$1')) {
      const account = this.accounts.get(params[0]);
      return { rows: account ? [{ id: account.id }] : [] };
    }
    if (sql.includes('SELECT 1 FROM app_accounts WHERE LOWER(username)=$1')) {
      const found = [...this.accounts.values()].some(
        account => account.username.toLowerCase() === params[0],
      );
      return { rows: found ? [{ exists: 1 }] : [] };
    }
    if (sql.startsWith('INSERT INTO app_accounts')) {
      const [id, username, password_hash, full_name, role, active] = params;
      this.accounts.set(id, {
        id, username, password_hash, full_name, role, active,
      });
      return { rows: [] };
    }
    if (sql.startsWith('UPDATE app_accounts SET full_name=')) {
      const account = this.accounts.get(params[0]);
      Object.assign(account, {
        full_name: params[1], role: params[2], active: params[3],
      });
      return { rows: [] };
    }
    throw new Error(`Unexpected SQL in fake database: ${sql}`);
  }
}

test('admin-created users receive hashed database logins for every assignable role', async () => {
  const database = new FakeClient();
  const created = [];
  for (const [role, databaseRole] of [
    ['owner', 'petOwner'],
    ['doctor', 'doctor'],
    ['staff', 'staff'],
  ]) {
    const value = {
      id: `new-${role}`,
      name: `New ${role}`,
      email: `${role}@clinic.test`,
      phone: '0912345678',
      role,
      status: 'pending',
      lastActive: 'Never',
      createdOn: new Date().toISOString(),
      password: 'Secure@123',
    };
    await syncUserDirectoryAccount(database, value, null, 'admin');
    assert.equal(value.password, undefined);
    const account = database.accounts.get(value.id);
    assert.equal(account.role, databaseRole);
    assert.equal(account.active, false);
    assert.equal(await bcrypt.compare('Secure@123', account.password_hash), true);
    created.push(value);
  }

  const doctor = created[1];
  doctor.status = 'active';
  await syncUserDirectoryAccount(
    database,
    doctor,
    { data: { value: { id: doctor.id } } },
    'admin',
  );
  assert.equal(database.accounts.get('new-doctor').active, true);

  const duplicate = {
    id: 'duplicate',
    name: 'Duplicate',
    email: 'DOCTOR@CLINIC.TEST',
    phone: '0912345678',
    role: 'staff',
    status: 'pending',
    password: 'Secure@123',
  };
  await assert.rejects(
    syncUserDirectoryAccount(database, duplicate, null, 'admin'),
    error => error.status === 409 && /already exists/.test(error.message),
  );
  assert.equal(database.accounts.has('duplicate'), false);
});

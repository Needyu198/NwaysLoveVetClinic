const { test } = require('node:test');
const assert = require('node:assert/strict');
const { findAccountByIdentifier } = require('../src/api');

class AccountLookupDatabase {
  constructor(accounts) {
    this.accounts = accounts;
  }

  async query(sql, params) {
    if (sql.includes('FROM app_accounts')) {
      const [identifier, phone] = params;
      return {
        rows: this.accounts.filter(account => account.active && (
          account.username.toLowerCase() === identifier ||
          account.email.toLowerCase() === identifier ||
          String(account.phone).replace(/[^0-9]/g, '') === phone
        )).slice(0, 2),
      };
    }
    if (sql.includes('FROM pet_owners')) return { rows: [] };
    throw new Error(`Unexpected SQL: ${sql}`);
  }
}

test('one registered account resolves by username, email, and normalized phone', async () => {
  const account = {
    id: 'account-1',
    username: 'happy.pet',
    email: 'owner@example.com',
    phone: '09 123-456-789',
    active: true,
    role: 'petOwner',
  };
  const database = new AccountLookupDatabase([account]);

  assert.equal(await findAccountByIdentifier(database, 'HAPPY.PET'), account);
  assert.equal(await findAccountByIdentifier(database, 'OWNER@EXAMPLE.COM'), account);
  assert.equal(await findAccountByIdentifier(database, '09-123 456 789'), account);
});

test('inactive, unknown, and ambiguous identifiers do not resolve', async () => {
  const database = new AccountLookupDatabase([
    { id: 'inactive', username: 'inactive', email: 'inactive@example.com', phone: '09111', active: false },
    { id: 'first', username: 'first', email: 'first@example.com', phone: '09222', active: true },
    { id: 'second', username: 'second', email: 'second@example.com', phone: '09222', active: true },
  ]);

  assert.equal(await findAccountByIdentifier(database, 'inactive'), null);
  assert.equal(await findAccountByIdentifier(database, 'unknown'), null);
  assert.equal(await findAccountByIdentifier(database, '09222'), null);
});

// Seeds sample owner data (pets + reminders) for the `petowner` account so the
// app has real database-backed content to show. Idempotent: records are keyed
// exactly the way the Flutter app keys them (`<accountId>:<suggested>`), so a
// re-run overwrites the same rows instead of duplicating.
//
//   node scripts/seedSampleData.js
//
// Requires the `petowner` account to already exist (run seed:accounts first).
const { ensureDatabaseSchema } = require('../src/schema');
const { pool } = require('../src/db');

const OWNER_USERNAME = 'petowner';

function iso(date) {
  return date.toISOString();
}

function daysFromNow(n) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(9, 0, 0, 0);
  return d;
}

// ---- Sample pets (matches ProfilePet.toDb) --------------------------------
const pets = [
  {
    name: 'Max',
    type: 'Dog',
    breed: 'Golden Retriever',
    sex: 'Male',
    dateOfBirth: iso(new Date('2021-04-12')),
    weightKg: 28.5,
    color: 'Golden',
    identifyingFeatures: 'White patch on chest',
    allergies: 'None known',
    conditions: 'None known',
    medicines: 'None',
    vaccination: 'Rabies, DHPP up to date',
    hasCustomPhoto: false,
    photoUrl: '',
  },
  {
    name: 'Bella',
    type: 'Cat',
    breed: 'Persian',
    sex: 'Female',
    dateOfBirth: iso(new Date('2022-08-03')),
    weightKg: 4.2,
    color: 'White',
    identifyingFeatures: 'Blue eyes, flat face',
    allergies: 'None known',
    conditions: 'None known',
    medicines: 'None',
    vaccination: 'FVRCP up to date',
    hasCustomPhoto: false,
    photoUrl: '',
  },
  {
    name: 'Luna',
    type: 'Dog',
    breed: 'Siberian Husky',
    sex: 'Female',
    dateOfBirth: iso(new Date('2020-11-20')),
    weightKg: 21.0,
    color: 'Grey and White',
    identifyingFeatures: 'One blue, one brown eye',
    allergies: 'Chicken',
    conditions: 'None known',
    medicines: 'None',
    vaccination: 'Rabies, DHPP up to date',
    hasCustomPhoto: false,
    photoUrl: '',
  },
];

// ---- Sample reminders (matches PetReminder.toDb) --------------------------
const reminders = [
  {
    id: 'REM-max-vaccine',
    title: "Max's annual rabies booster",
    type: 'vaccine',
    dateTime: iso(daysFromNow(14)),
    note: 'Bring previous vaccination card.',
    petName: 'Max',
    createdByStaff: false,
    completed: false,
  },
  {
    id: 'REM-bella-checkup',
    title: "Bella's dental check-up",
    type: 'checkup',
    dateTime: iso(daysFromNow(30)),
    note: 'Routine dental cleaning and check.',
    petName: 'Bella',
    createdByStaff: false,
    completed: false,
  },
  {
    id: 'REM-luna-medicine',
    title: "Luna's flea & tick medicine",
    type: 'medicine',
    dateTime: iso(daysFromNow(7)),
    note: 'Monthly chewable, give with food.',
    petName: 'Luna',
    createdByStaff: false,
    completed: false,
  },
];

async function upsertRecord(client, table, accountId, suggestedId, value) {
  const key = `${accountId}:${suggestedId}`;
  const data = { key, value };
  const existing = (
    await client.query(`SELECT id FROM ${table} WHERE id = $1`, [key])
  ).rows[0];
  if (existing) {
    await client.query(
      `UPDATE ${table} SET data = $2, version = version + 1, updated_at = NOW() WHERE id = $1`,
      [key, data],
    );
    return 'updated';
  }
  await client.query(
    `INSERT INTO ${table}(id, owner_id, data) VALUES($1, $2, $3)`,
    [key, accountId, data],
  );
  return 'inserted';
}

async function main() {
  await ensureDatabaseSchema();
  const account = (
    await pool.query('SELECT id FROM app_accounts WHERE username = $1', [OWNER_USERNAME])
  ).rows[0];
  if (!account) {
    throw new Error(`Account "${OWNER_USERNAME}" not found. Run: npm run seed:accounts`);
  }
  const accountId = account.id;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const pet of pets) {
      const suggested = `${pet.name}:${pet.dateOfBirth}`;
      const result = await upsertRecord(client, 'pets', accountId, suggested, pet);
      console.log(`pets      ${result}  ${pet.name}`);
    }
    for (const reminder of reminders) {
      const result = await upsertRecord(
        client,
        'reminders',
        accountId,
        reminder.id,
        reminder,
      );
      console.log(`reminders ${result}  ${reminder.title}`);
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  console.log('Sample data seeding complete.');
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());

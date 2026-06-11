const bcrypt = require("bcryptjs");

const { pool } = require("../src/db");
const { ensureDatabaseSchema } = require("../src/schema");

const petOwner = {
  username: "Lynn198",
  password: "123456",
  fullName: "Lynn",
};

async function seedPetOwner() {
  await ensureDatabaseSchema();

  const passwordHash = await bcrypt.hash(petOwner.password, 12);

  await pool.query(
    `
      INSERT INTO pet_owners (username, password_hash, full_name, updated_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (username)
      DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        full_name = EXCLUDED.full_name,
        updated_at = NOW()
    `,
    [petOwner.username, passwordHash, petOwner.fullName],
  );

  console.log(`Seeded pet owner account: ${petOwner.username}`);
}

seedPetOwner()
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });

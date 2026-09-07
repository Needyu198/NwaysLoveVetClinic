const { ensureDatabaseSchema } = require('../src/schema');
const { pool } = require('../src/db');
ensureDatabaseSchema().then(() => console.log('PostgreSQL feature tables are ready. Existing records preserved.'))
  .catch(e => { console.error(e.message); process.exitCode = 1; }).finally(() => pool.end());

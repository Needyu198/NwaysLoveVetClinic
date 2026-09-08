const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const { resources } = require('./resources');
const { broadcastChange } = require('./realtime');
const hash = token => crypto.createHash('sha256').update(token).digest('hex');
const fail = (status, message) => Object.assign(new Error(message), { status });
function installApi(app, pool) {
  const wrap = fn => async (req, res) => {
    try { await fn(req, res); } catch (e) {
      if (!e.status) console.error('Database request failed:', e.code || e.message);
      res.status(e.status || 503).json({ message: e.status ? e.message : 'Database unavailable. Please retry.' });
    }
  };
  app.post(['/auth/login', '/auth/pet-owner/login'], wrap(async (req, res) => {
    const username = String(req.body.username || '').trim();
    const password = String(req.body.password || '');
    if (!username || !password || username.length > 254 || password.length > 1024) throw fail(400, 'Username and password required.');
    let account = (await pool.query('SELECT * FROM app_accounts WHERE username = $1 AND active = TRUE', [username])).rows[0];
    if (!account) {
      const old = (await pool.query('SELECT * FROM pet_owners WHERE username = $1', [username])).rows[0];
      if (old) account = { ...old, id: `owner-${old.id}`, role: 'petOwner' };
    }
    if (!account || !(await bcrypt.compare(password, account.password_hash))) throw fail(401, 'Invalid username or password.');
    const token = crypto.randomBytes(32).toString('hex');
    await pool.query("INSERT INTO app_sessions(token_hash, account_id, role, expires_at) VALUES($1,$2,$3,NOW() + INTERVAL '12 hours')", [hash(token), account.id, account.role]);
    res.json({ token, account: { id: account.id, username: account.username, fullName: account.full_name, role: account.role } });
  }));
  app.use(['/data', '/auth/logout', '/devices'], async (req, res, next) => {
    try {
      const token = (req.headers.authorization || '').replace(/^Bearer /, '');
      const session = (await pool.query('SELECT s.* FROM app_sessions s JOIN app_accounts a ON a.id=s.account_id AND a.active AND a.role=s.role WHERE s.token_hash=$1 AND s.expires_at>NOW()', [hash(token)])).rows[0];
      if (!session) return res.status(401).json({ message: 'Please sign in again.' });
      req.session = session;
      next();
    } catch (_) { res.status(503).json({ message: 'Database unavailable.' }); }
  });
  app.post('/auth/logout', wrap(async (req, res) => {
    await pool.query('DELETE FROM app_sessions WHERE token_hash=$1', [req.session.token_hash]);
    res.json({ ok: true });
  }));
  // Register (or refresh) this device's FCM token for the signed-in account.
  app.post('/devices/register', wrap(async (req, res) => {
    const token = String(req.body.token || '').trim();
    const platform = String(req.body.platform || 'unknown').slice(0, 32);
    if (!token || token.length > 4096) throw fail(400, 'A device token is required.');
    await pool.query(
      `INSERT INTO device_tokens(token, account_id, platform) VALUES($1,$2,$3)
       ON CONFLICT (token) DO UPDATE SET account_id=EXCLUDED.account_id, platform=EXCLUDED.platform, updated_at=NOW()`,
      [token, req.session.account_id, platform],
    );
    res.json({ ok: true });
  }));
  // Remove this device's token (e.g. on logout / permission revoked).
  app.post('/devices/unregister', wrap(async (req, res) => {
    const token = String(req.body.token || '').trim();
    if (token) await pool.query('DELETE FROM device_tokens WHERE token=$1 AND account_id=$2', [token, req.session.account_id]);
    res.json({ ok: true });
  }));
  const policy = req => {
    const p = Object.hasOwn(resources, req.params.table) && resources[req.params.table];
    if (!p) throw fail(404, 'Unknown database table.');
    if (!p.roles.includes(req.session.role)) throw fail(403, 'Access denied.');
    return p;
  };
  const ownOnly = (p, session) => p.scope === 'private' || (p.scope === 'owner' && session.role === 'petOwner');
  app.get('/data/:table', wrap(async (req, res) => {
    const p = policy(req);
    if (req.params.table === 'clinic_directory') {
      const result = await pool.query(`SELECT id, id AS owner_id, 1 AS version,
        jsonb_build_object('key',id,'value',jsonb_build_object(
          'id',id,'name',COALESCE(NULLIF(full_name, ''),username),'role',role)) AS data
        FROM app_accounts WHERE active AND role IN ('doctor','staff') ORDER BY full_name,id`);
      return res.json({records:result.rows});
    }
    const restricted = ownOnly(p, req.session);
    const rows = await pool.query(`SELECT id, owner_id, data, version FROM ${req.params.table}${restricted ? ' WHERE owner_id=$1' : ''} ORDER BY created_at, id`, restricted ? [req.session.account_id] : []);
    res.json({ records: rows.rows });
  }));
  app.post('/data/:table/sync', wrap(async (req, res) => {
    const p = policy(req);
    if (!(p.writers || p.roles).includes(req.session.role)) throw fail(403, 'Read-only data.');
    const { changes = [], deletions = [] } = req.body;
    if (!Array.isArray(changes) || !Array.isArray(deletions) || changes.length + deletions.length > 1000) throw fail(400, 'Invalid batch.');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const saved = [];
      for (const item of [...changes, ...deletions.map(x => ({ ...x, deleting: true }))]) {
        if (typeof item.id !== 'string' || !item.id || item.id.length > 250 || !Number.isInteger(item.version) || item.version < 0) throw fail(400, 'Invalid record.');
        const existing = (await client.query(`SELECT * FROM ${req.params.table} WHERE id=$1 FOR UPDATE`, [item.id])).rows[0];
        if (existing && ownOnly(p, req.session) && existing.owner_id !== req.session.account_id) throw fail(403, 'Access denied.');
        if ((existing?.version || 0) !== item.version) throw fail(409, 'This record changed on another device. Reload before saving.');
        if (p.appendOnly && (existing || item.deleting)) throw fail(403, 'Audit entries cannot be changed or deleted.');
        if (item.deleting) {
          await client.query(`DELETE FROM ${req.params.table} WHERE id=$1`, [item.id]);
          continue;
        }
        if (!item.data || typeof item.data !== 'object' || Array.isArray(item.data)) throw fail(400, 'Invalid record data.');
        if (typeof item.data.key !== 'string' || !item.data.key || !item.data.value || typeof item.data.value !== 'object' || Array.isArray(item.data.value)) throw fail(400, 'Invalid record data.');
        if (existing && existing.data.key !== item.data.key) throw fail(400, 'Record key cannot change.');
        let ownerId = existing?.owner_id || req.session.account_id;
        if (!existing && p.scope === 'owner' && req.session.role !== 'petOwner' && item.ownerId) {
          const target = await client.query("SELECT id FROM app_accounts WHERE id=$1 AND role='petOwner'", [item.ownerId]);
          if (!target.rowCount) throw fail(400, 'Owner account not found.');
          ownerId = item.ownerId;
        }
        if (req.params.table === 'user_directory') {
          const value = item.data.value;
          const roles = {owner:'petOwner',doctor:'doctor',staff:'staff',admin:'systemAdmin'};
          if (!roles[value.role] || !['pending','active','suspended'].includes(value.status)) throw fail(400, 'Invalid user role or status.');
          if (value.id === req.session.account_id && (value.status !== 'active' || roles[value.role] !== 'systemAdmin')) throw fail(400, 'You cannot remove your own administrator access.');
          if (existing && value.id !== existing.data.value.id) throw fail(400, 'Account identity cannot change.');
          await client.query('UPDATE app_accounts SET full_name=$2,role=$3,active=$4 WHERE id=$1', [value.id,value.name,roles[value.role],value.status==='active']);
        }
        if (existing) {
          saved.push((await client.query(`UPDATE ${req.params.table} SET data=$2,version=version+1,updated_at=NOW() WHERE id=$1 RETURNING id,owner_id,data,version`, [item.id, item.data])).rows[0]);
        } else {
          saved.push((await client.query(`INSERT INTO ${req.params.table}(id,owner_id,data) VALUES($1,$2,$3) RETURNING id,owner_id,data,version`, [item.id, ownerId, item.data])).rows[0]);
        }
      }
      await client.query('COMMIT');
      // Notify connected clients that this table changed so they refresh live
      // (drives the real-time queue). Only emit when something actually changed.
      if (changes.length || deletions.length) broadcastChange(req.params.table);
      res.json({ records: saved });
    } catch (e) { await client.query('ROLLBACK'); if (e.code === '23505') throw fail(409, 'Record already exists. Reload before saving.'); throw e; }
    finally { client.release(); }
  }));
}
module.exports = { installApi };

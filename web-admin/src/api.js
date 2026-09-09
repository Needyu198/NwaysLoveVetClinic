// REST client for the Nway Love Vet Clinic backend, mirroring the Flutter
// ClinicApi / system-admin portal. Stores the session token in localStorage so
// a refresh keeps you signed in.

const BASE = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:5050';

const TOKEN_KEY = 'nways.admin.token';
const ACCOUNT_KEY = 'nways.admin.account';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getAccount() {
  const raw = localStorage.getItem(ACCOUNT_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function accountId() {
  return getAccount()?.id || '';
}

export function baseUrl() {
  return BASE;
}

export function formatMmk(amount) {
  const n = Number(amount) || 0;
  return `${n.toLocaleString('en-US')} MMK`;
}

// The Flutter app keys each synced record as "<accountId>:<itemId>".
export function recordKey(itemId) {
  return `${accountId()}:${itemId}`;
}

function setSession(token, account) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(ACCOUNT_KEY, JSON.stringify(account));
}

function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ACCOUNT_KEY);
}

async function request(method, path, body) {
  const token = getToken();
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(data.message || 'Request failed');
    err.status = res.status;
    throw err;
  }
  return data;
}

export async function login(username, password) {
  const data = await request('POST', '/auth/login', { username, password });
  setSession(data.token, data.account);
  return data.account;
}

export async function logout() {
  try {
    await request('POST', '/auth/logout');
  } finally {
    clearSession();
  }
}

// Read a data table. Records are { id, owner_id, data:{key,value}, version }.
export async function getTable(table) {
  const data = await request('GET', `/data/${table}`);
  return data.records || [];
}

// Persist changes/deletions for a table (optimistic version numbers).
export async function syncTable(table, changes = [], deletions = []) {
  return request('POST', `/data/${table}/sync`, { changes, deletions });
}

// Find an existing record in a table by its logical id (data.value.id).
function findByValueId(records, valueId) {
  return records.find(r => (r.data?.value?.id || '') === valueId) || null;
}

// ---- Users & Roles -------------------------------------------------------
// Roles map to the Flutter AdminUserRole enum names: owner|doctor|staff|admin.
export function rolePrefix(role) {
  return { owner: 'USR', doctor: 'DOC', staff: 'STF', admin: 'ADM' }[role] || 'USR';
}

// Create a new directory user. When `password` is provided the backend also
// provisions a real login (app_accounts row) — matching the Flutter admin.
export async function createUser({ name, email, phone, role, password }) {
  const id = `${rolePrefix(role)}-${Date.now()}`;
  const value = {
    id,
    name,
    email,
    phone,
    role,
    status: 'pending',
    lastActive: 'Never',
    createdOn: new Date().toISOString(),
  };
  if (password) value.password = password;
  return syncTable('user_directory', [
    { id: recordKey(id), version: 0, data: { key: recordKey(id), value } },
  ]);
}

// Update status/role of an existing directory record (activate/suspend/etc).
export async function updateUser(record, patch) {
  const value = { ...record.data.value, ...patch };
  delete value.password; // never resend a password on updates
  return syncTable('user_directory', [
    { id: record.id, version: record.version, data: { key: record.data.key, value } },
  ]);
}

// ---- Doctor verification -------------------------------------------------
export async function decideVerification(record, status, reason = '') {
  const value = { ...record.data.value, status, decisionReason: reason };
  return syncTable('doctor_verifications', [
    { id: record.id, version: record.version, data: { key: record.data.key, value } },
  ]);
}

// ---- Inventory approval --------------------------------------------------
export async function decideRestock(record, restockStatus) {
  const value = { ...record.data.value, restockStatus };
  return syncTable('inventory', [
    { id: record.id, version: record.version, data: { key: record.data.key, value } },
  ]);
}

// ---- Audit log -----------------------------------------------------------
// Append-only. Records a sensitive admin action so it shows in Audit Logs.
export async function recordAudit({ action, module, record, previousValue = '', newValue = '', reason = '' }) {
  const id = `AUD-${Date.now()}`;
  const account = getAccount();
  const value = {
    id,
    action,
    module,
    record,
    actor: account?.fullName || account?.username || 'Administrator',
    timestamp: new Date().toISOString(),
    previousValue,
    newValue,
    reason,
  };
  try {
    await syncTable('audit_logs', [
      { id: recordKey(id), version: 0, data: { key: recordKey(id), value } },
    ]);
  } catch (_) {
    // Audit is best-effort; never block the primary action on it.
  }
}

export { findByValueId };

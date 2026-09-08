// REST client for the Nway Love Vet Clinic backend, mirroring the Flutter
// ClinicApi. Stores the session token in localStorage so a refresh keeps you
// signed in.

const BASE =
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:5050';

const TOKEN_KEY = 'nways.staff.token';
const ACCOUNT_KEY = 'nways.staff.account';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getAccount() {
  const raw = localStorage.getItem(ACCOUNT_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function baseUrl() {
  return BASE;
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

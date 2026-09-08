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

export function accountId() {
  return getAccount()?.id || '';
}

export function baseUrl() {
  return BASE;
}

// Format an integer amount as "1,015 MMK" (matches the Flutter app).
export function formatMmk(amount) {
  const n = Number(amount) || 0;
  return `${n.toLocaleString('en-US')} MMK`;
}

// The Flutter app keys each synced record as "<accountId>:<itemId>".
// Web writes must use the same key so they map to the same logical record.
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

// Build the full InventoryItem.toDb() value shape the Flutter app expects.
export function buildInventoryValue(item) {
  return {
    id: item.id,
    name: item.name,
    category: item.category,
    quantity: item.quantity,
    reorderLevel: item.reorderLevel,
    unit: item.unit ?? 'pcs',
    expiresOn: item.expiresOn,
    sellingPrice: item.sellingPrice,
    purchasePrice: item.purchasePrice ?? 0,
    supplier: item.supplier ?? '',
    batchNumber: item.batchNumber ?? '',
    imageAsset: item.imageAsset ?? null,
    description: item.description ?? '',
    restockRequested: item.restockRequested ?? false,
    restockQuantity: item.restockQuantity ?? 0,
    restockNote: item.restockNote ?? '',
    restockStatus: item.restockStatus ?? '',
    lastAudit: item.lastAudit ?? 'No stock changes recorded',
    archived: item.archived ?? false,
    movements: item.movements ?? [],
  };
}

// Create or update an inventory record.
// `existing` is the raw record from getTable() when editing (has id + version).
export async function saveInventoryItem(item, existing) {
  const recordId = existing ? existing.id : recordKey(item.id);
  const version = existing ? existing.version : 0;
  return syncTable('inventory', [
    {
      id: recordId,
      version,
      data: { key: recordKey(item.id), value: buildInventoryValue(item) },
    },
  ]);
}

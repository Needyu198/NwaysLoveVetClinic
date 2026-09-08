import React, { useEffect, useState, useCallback } from 'react';
import { login, logout, getAccount, getTable } from './api.js';
import { connectRealtime } from './realtime.js';

// Staff-accessible resources (see backend/src/resources.js). These are the
// tables a 'staff' role may read.
const TABS = [
  { key: 'queue_entries', label: 'Queue' },
  { key: 'walk_in_appointments', label: 'Appointments' },
  { key: 'inventory', label: 'Inventory' },
  { key: 'payments', label: 'Payments' },
];

function LoginScreen({ onSignedIn }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e) {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      const account = await login(username.trim(), password);
      if (account.role !== 'staff' && account.role !== 'systemAdmin') {
        await logout();
        setError('This portal is for clinic staff and administrators.');
        return;
      }
      onSignedIn(account);
    } catch (err) {
      setError(err.message || 'Sign in failed.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <h1>Clinic Staff Portal</h1>
        <p>Nway's Love Vet Clinic</p>
        <label>Username</label>
        <input
          value={username}
          onChange={e => setUsername(e.target.value)}
          autoFocus
        />
        <label>Password</label>
        <input
          type="password"
          value={password}
          onChange={e => setPassword(e.target.value)}
        />
        <button className="btn-primary" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign In'}
        </button>
        {error && <div className="error">{error}</div>}
      </form>
    </div>
  );
}

function DataTable({ table }) {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      setRecords(await getTable(table));
      setError('');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [table]);

  useEffect(() => {
    setLoading(true);
    load();
  }, [load]);

  if (loading) return <div className="empty">Loading…</div>;
  if (error) return <div className="error">{error}</div>;
  if (records.length === 0) return <div className="empty">No records yet.</div>;

  // Derive columns from the union of value keys across records.
  const columns = Array.from(
    records.reduce((set, r) => {
      Object.keys(r.data?.value || {}).forEach(k => set.add(k));
      return set;
    }, new Set()),
  ).slice(0, 6);

  return (
    <div className="card">
      <table>
        <thead>
          <tr>
            {columns.map(c => (
              <th key={c}>{c}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {records.map(r => (
            <tr key={r.id}>
              {columns.map(c => (
                <td key={c}>{formatCell(r.data?.value?.[c])}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function formatCell(v) {
  if (v == null) return '';
  if (typeof v === 'object') return JSON.stringify(v);
  return String(v);
}

function Dashboard({ account, onSignOut }) {
  const [active, setActive] = useState(TABS[0].key);
  const [live, setLive] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    const disconnect = connectRealtime(changedTable => {
      // If the table currently shown changed, force a reload.
      setLive(true);
      if (changedTable === active) setRefreshKey(k => k + 1);
    });
    return disconnect;
  }, [active]);

  return (
    <div>
      <div className="app-header">
        <h1>Clinic Staff Portal</h1>
        <div>
          <span className="who">
            <span className={`live-dot ${live ? '' : 'off'}`} />
            {account.fullName || account.username} · {account.role}
          </span>
          <button className="tab" onClick={onSignOut}>
            Sign out
          </button>
        </div>
      </div>
      <div className="tabs">
        {TABS.map(t => (
          <button
            key={t.key}
            className={`tab ${active === t.key ? 'active' : ''}`}
            onClick={() => setActive(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>
      <div className="content">
        <DataTable key={`${active}-${refreshKey}`} table={active} />
      </div>
    </div>
  );
}

export default function App() {
  const [account, setAccount] = useState(getAccount());

  async function handleSignOut() {
    await logout();
    setAccount(null);
  }

  if (!account) return <LoginScreen onSignedIn={setAccount} />;
  return <Dashboard account={account} onSignOut={handleSignOut} />;
}

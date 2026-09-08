import React, { useEffect, useState } from 'react';
import { login, logout, getAccount } from './api.js';
import { connectRealtime } from './realtime.js';
import {
  DashboardView,
  AppointmentsView,
  WalkInView,
  QueueView,
  PaymentsView,
  InventoryView,
  MedicalRecordsView,
  HealthPostsView,
  MessagesView,
  ReportsView,
} from './views.jsx';

// The staff feature areas, mirroring the Flutter staff portal.
const NAV = [
  { key: 'dashboard', label: 'Dashboard', icon: '📊', View: DashboardView },
  { key: 'appointments', label: 'Appointments', icon: '📅', View: AppointmentsView },
  { key: 'queue', label: 'Queue', icon: '⏳', View: QueueView },
  { key: 'walkin', label: 'Walk-in', icon: '🚶', View: WalkInView },
  { key: 'payments', label: 'Payments', icon: '💳', View: PaymentsView },
  { key: 'inventory', label: 'Inventory', icon: '📦', View: InventoryView },
  { key: 'records', label: 'Medical Records', icon: '🩺', View: MedicalRecordsView },
  { key: 'posts', label: 'Health Posts', icon: '📝', View: HealthPostsView },
  { key: 'messages', label: 'Messages', icon: '💬', View: MessagesView },
  { key: 'reports', label: 'Reports', icon: '📈', View: ReportsView },
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
        <img className="login-logo" src="/logo.png" alt="Nway's Love Vet Clinic" />
        <h1>Clinic Staff Portal</h1>
        <p>Nway's Love Vet Clinic</p>
        <label>Username</label>
        <div className="field">
          <span className="field-icon">👤</span>
          <input
            value={username}
            onChange={e => setUsername(e.target.value)}
            placeholder="Enter your username"
            autoFocus
          />
        </div>
        <label>Password</label>
        <div className="field">
          <span className="field-icon">🔒</span>
          <input
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="Enter your password"
          />
        </div>
        <button className="btn-primary" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign In'}
        </button>
        {error && <div className="error">{error}</div>}
      </form>
    </div>
  );
}

function Portal({ account, onSignOut }) {
  const [active, setActive] = useState('dashboard');
  const [live, setLive] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    const disconnect = connectRealtime(() => {
      setLive(true);
      // Any table change bumps the refresh key so the active view reloads.
      setRefreshKey(k => k + 1);
    });
    return disconnect;
  }, []);

  const activeNav = NAV.find(n => n.key === active) || NAV[0];
  const ActiveView = activeNav.View;
  const initials = (account.fullName || account.username || '?')
    .trim()
    .split(/\s+/)
    .map(w => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <img className="brand-logo" src="/logo.png" alt="logo" />
          <div>
            <div className="brand-title">Nway's Love</div>
            <div className="brand-sub">Staff Portal</div>
          </div>
        </div>
        <nav>
          {NAV.map(n => (
            <button
              key={n.key}
              className={`nav-item ${active === n.key ? 'active' : ''}`}
              onClick={() => setActive(n.key)}
            >
              <span className="nav-icon">{n.icon}</span>
              {n.label}
            </button>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="avatar">{initials}</div>
          <div className="who">
            <div className="who-name">{account.fullName || account.username}</div>
            <div className="muted small">{account.role}</div>
          </div>
          <button className="icon-btn ghost" title="Sign out" onClick={onSignOut}>
            ⏻
          </button>
        </div>
      </aside>
      <main className="content">
        <header className="topbar">
          <div>
            <div className="topbar-title">{activeNav.label}</div>
            <div className="muted small">Nway's Love Vet Clinic</div>
          </div>
          <div className={`live-chip ${live ? 'on' : ''}`}>
            <span className={`live-dot ${live ? '' : 'off'}`} />
            {live ? 'Live' : 'Connecting…'}
          </div>
        </header>
        <div className="content-body">
          <ActiveView refreshKey={refreshKey} />
        </div>
      </main>
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
  return <Portal account={account} onSignOut={handleSignOut} />;
}

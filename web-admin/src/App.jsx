import React, { useEffect, useMemo, useState } from 'react';
import { login, logout, getAccount } from './api.js';
import { connectRealtime } from './realtime.js';
import {
  AdminDashboardView,
  UsersView,
  VerificationView,
  InventoryApprovalView,
  AuditLogsView,
} from './views.jsx';

// Admin feature areas, mirroring the Flutter system-admin portal.
const NAV_GROUPS = [
  {
    label: 'Main',
    items: [
      { key: 'dashboard', label: 'Dashboard', icon: '📊', sub: 'System overview', View: AdminDashboardView },
      { key: 'users', label: 'Users & Roles', icon: '👥', sub: 'Manage every account', View: UsersView },
    ],
  },
  {
    label: 'Governance',
    items: [
      { key: 'verification', label: 'Doctor Verification', icon: '✅', sub: 'Review applications', View: VerificationView },
      { key: 'inventory', label: 'Inventory Approval', icon: '📦', sub: 'Restock requests', View: InventoryApprovalView },
    ],
  },
  {
    label: 'System',
    items: [
      { key: 'audit', label: 'Audit Logs', icon: '📜', sub: 'Sensitive action trail', View: AuditLogsView },
    ],
  },
];

const ALL_NAV = NAV_GROUPS.flatMap(g => g.items);

function initialsOf(account) {
  return (account.fullName || account.username || '?')
    .trim()
    .split(/\s+/)
    .map(w => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

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
      if (account.role !== 'systemAdmin') {
        await logout();
        setError('This portal is for system administrators only.');
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
        <h1>Clinic Admin Portal</h1>
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
  const [query, setQuery] = useState('');

  useEffect(() => {
    const disconnect = connectRealtime(() => {
      setLive(true);
      setRefreshKey(k => k + 1);
    });
    return disconnect;
  }, []);

  const activeNav = useMemo(
    () => ALL_NAV.find(n => n.key === active) || ALL_NAV[0],
    [active],
  );
  const ActiveView = activeNav.View;
  const initials = initialsOf(account);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <img className="brand-logo" src="/logo.png" alt="logo" />
          <div>
            <div className="brand-title">Nway's Love</div>
            <div className="brand-sub">Admin Portal</div>
          </div>
        </div>
        <nav>
          {NAV_GROUPS.map(group => (
            <React.Fragment key={group.label}>
              <div className="nav-group-label">{group.label}</div>
              {group.items.map(n => (
                <button
                  key={n.key}
                  className={`nav-item ${active === n.key ? 'active' : ''}`}
                  onClick={() => setActive(n.key)}
                >
                  <span className="nav-icon">{n.icon}</span>
                  {n.label}
                </button>
              ))}
            </React.Fragment>
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
          <div className="search">
            <span className="field-icon">🔍</span>
            <input
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search or type a command"
            />
          </div>
          <div className="topbar-spacer" />
          <div className="topbar-right">
            <div className={`live-chip ${live ? 'on' : ''}`}>
              <span className={`live-dot ${live ? '' : 'off'}`} />
              {live ? 'Live' : 'Connecting…'}
            </div>
            <div className="topbar-avatar" title={account.fullName || account.username}>
              {initials}
            </div>
          </div>
        </header>
        <div className="content-body">
          <div className="page-head">
            <h1>{activeNav.label}</h1>
            <div className="sub">{activeNav.sub}</div>
          </div>
          <ActiveView refreshKey={refreshKey} query={query} />
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

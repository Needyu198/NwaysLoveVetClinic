import React, { useEffect, useMemo, useState } from 'react';
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
  PatientsView,
  EmergenciesView,
  HomeVisitsView,
  HealthPostsView,
  MessagesView,
  ReportsView,
  AccountView,
} from './views.jsx';
import {
  AdminDashboardView,
  UsersView,
  VerificationView,
  AuditLogsView,
  AccountView as AdminAccountView,
} from './adminViews.jsx';

// The staff feature areas, grouped like the reference dashboard sidebar.
const STAFF_NAV_GROUPS = [
  {
    label: 'Main',
    items: [
      { key: 'dashboard', label: 'Dashboard', icon: '📊', sub: "Today's clinic overview", View: DashboardView },
      { key: 'appointments', label: 'Appointments', icon: '📅', sub: 'Scheduled visits', View: AppointmentsView },
      { key: 'queue', label: 'Queue', icon: '⏳', sub: 'Live patient queue', View: QueueView },
      { key: 'walkin', label: 'Walk-in', icon: '🚶', sub: 'Walk-in registrations', View: WalkInView },
      { key: 'emergencies', label: 'Emergencies', icon: '🚨', sub: 'Urgent owner requests', View: EmergenciesView },
      { key: 'homevisits', label: 'Home Visits', icon: '🏠', sub: 'Coordinate mobile care', View: HomeVisitsView },
    ],
  },
  {
    label: 'Clinic',
    items: [
      { key: 'payments', label: 'Payments', icon: '💳', sub: 'Billing and revenue', View: PaymentsView },
      { key: 'inventory', label: 'Inventory', icon: '📦', sub: 'Stock and supplies', View: InventoryView },
      { key: 'records', label: 'Medical Records', icon: '🩺', sub: 'Patient histories', View: MedicalRecordsView },
      { key: 'patients', label: 'Patients', icon: '🐾', sub: 'Pet and owner directory', View: PatientsView },
      { key: 'posts', label: 'Health Posts', icon: '📝', sub: 'Published articles', View: HealthPostsView },
    ],
  },
  {
    label: 'System',
    items: [
      { key: 'messages', label: 'Messages', icon: '💬', sub: 'Owner conversations', View: MessagesView },
      { key: 'reports', label: 'Reports', icon: '📈', sub: 'Clinic analytics', View: ReportsView },
      { key: 'account', label: 'Account', icon: '⚙️', sub: 'Security and password', View: AccountView },
    ],
  },
];

const ADMIN_NAV_GROUPS = [
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
    ],
  },
  {
    label: 'System',
    items: [
      { key: 'audit', label: 'Audit Logs', icon: '📜', sub: 'Sensitive action trail', View: AuditLogsView },
      { key: 'account', label: 'Account', icon: '⚙️', sub: 'Security and password', View: AdminAccountView },
    ],
  },
];

const STAFF_NAV = STAFF_NAV_GROUPS.flatMap(group => group.items);
const ADMIN_NAV = ADMIN_NAV_GROUPS.flatMap(group => group.items);

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
      if (!['staff', 'systemAdmin'].includes(account.role)) {
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
        <h1>Clinic Management Portal</h1>
        <p>Sign in with your staff or administrator account</p>
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
  const isAdmin = account.role === 'systemAdmin';
  const navGroups = isAdmin ? ADMIN_NAV_GROUPS : STAFF_NAV_GROUPS;
  const allNav = isAdmin ? ADMIN_NAV : STAFF_NAV;
  const [active, setActive] = useState('dashboard');
  const [live, setLive] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);
  const [query, setQuery] = useState('');

  useEffect(() => {
    const disconnect = connectRealtime(() => {
      setRefreshKey(k => k + 1);
    }, setLive);
    return disconnect;
  }, []);

  const activeNav = useMemo(
    () => allNav.find(n => n.key === active) || allNav[0],
    [active, allNav],
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
            <div className="brand-sub">{isAdmin ? 'Admin Portal' : 'Staff Portal'}</div>
          </div>
        </div>
        <nav>
          {navGroups.map(group => (
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

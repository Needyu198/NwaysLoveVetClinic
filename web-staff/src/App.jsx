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
  const [showPassword, setShowPassword] = useState(false);
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
      <div className="login-shell">
        <section className="login-panel">
          <form className="login-card" onSubmit={submit}>
            <div className="login-brand">
              <img className="login-logo" src="/logo.png" alt="" />
              <div>
                <strong>Nway's Love</strong>
                <span>Veterinary Clinic</span>
              </div>
            </div>

            <div className="login-copy">
              <span className="login-eyebrow">Clinic management portal</span>
              <h1>Welcome back <span aria-hidden="true">👋</span></h1>
              <p>Enter your account details to continue to your workspace.</p>
            </div>

            <label htmlFor="username">Username or email</label>
            <div className="field">
              <span className="field-icon" aria-hidden="true">✉</span>
              <input
                id="username"
                value={username}
                onChange={e => setUsername(e.target.value)}
                placeholder="Enter your username"
                autoComplete="username"
                autoFocus
                required
              />
            </div>
            <label htmlFor="password">Password</label>
            <div className="field">
              <span className="field-icon" aria-hidden="true">◆</span>
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="Enter your password"
                autoComplete="current-password"
                required
              />
              <button
                className="password-toggle"
                type="button"
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                aria-pressed={showPassword}
                onClick={() => setShowPassword(value => !value)}
              >
                {showPassword ? '◉' : '◎'}
              </button>
            </div>

            <div className="login-role-note">
              <span aria-hidden="true">✓</span>
              Staff and administrator accounts use this same secure sign-in.
            </div>

            <button className="btn-primary login-submit" disabled={busy}>
              <span>{busy ? 'Signing in…' : 'Sign in to portal'}</span>
              {!busy && <span aria-hidden="true">→</span>}
            </button>
            {error && <div className="error login-error" role="alert">{error}</div>}
          </form>
        </section>

        <aside className="login-showcase" aria-label="Nway's Love Veterinary Clinic">
          <div className="showcase-orb orb-one" />
          <div className="showcase-orb orb-two" />
          <div className="showcase-copy">
            <span className="showcase-badge"><span /> Trusted clinic workspace</span>
            <h2>Care for every patient,<br />all in one place.</h2>
            <p>Appointments, records, inventory and clinic administration stay connected.</p>
          </div>
          <div className="showcase-pill pill-top">🩺 <span>Patient care</span></div>
          <div className="showcase-pill pill-bottom">🛡️ <span>Secure access</span></div>
          <img className="login-pets" src="/pets.png" alt="A group of clinic pets" />
        </aside>
      </div>
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
  const [navOpen, setNavOpen] = useState(false);

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
          <button
            className="mobile-menu-btn"
            type="button"
            aria-label="Toggle navigation"
            aria-expanded={navOpen}
            onClick={() => setNavOpen(value => !value)}
          >
            {navOpen ? '✕' : '☰'}
          </button>
        </div>
        <nav className={navOpen ? 'open' : ''}>
          {navGroups.map(group => (
            <React.Fragment key={group.label}>
              <div className="nav-group-label">{group.label}</div>
              {group.items.map(n => (
                <button
                  key={n.key}
                  className={`nav-item ${active === n.key ? 'active' : ''}`}
                  onClick={() => {
                    setActive(n.key);
                    setNavOpen(false);
                  }}
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
          <button className="icon-btn ghost" aria-label="Sign out" title="Sign out" onClick={onSignOut}>
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

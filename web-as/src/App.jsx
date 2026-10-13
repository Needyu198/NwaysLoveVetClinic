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

function LoginIcon({ name }) {
  const paths = {
    user: <><path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z" /><path d="M4.5 21a7.5 7.5 0 0 1 15 0" /></>,
    lock: <><rect x="5" y="10" width="14" height="11" rx="2.5" /><path d="M8.5 10V7.5a3.5 3.5 0 0 1 7 0V10M12 14.5v2.5" /></>,
    eye: <><path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6Z" /><circle cx="12" cy="12" r="2.5" /></>,
    eyeOff: <><path d="m3 3 18 18M10.6 6.2A8.9 8.9 0 0 1 12 6c6 0 9.5 6 9.5 6a15.4 15.4 0 0 1-2.1 2.8M6.2 6.2C3.8 7.9 2.5 12 2.5 12s3.5 6 9.5 6a9 9 0 0 0 3-.5M9.9 9.9a3 3 0 0 0 4.2 4.2" /></>,
    shield: <><path d="M12 3 5 6v5c0 4.6 2.9 8.2 7 10 4.1-1.8 7-5.4 7-10V6l-7-3Z" /><path d="m9.2 12 1.8 1.8 3.8-4" /></>,
    arrow: <><path d="M5 12h14M14 7l5 5-5 5" /></>,
    activity: <path d="M3 12h4l2.2-5 4.1 10 2.1-5H21" />,
    records: <><path d="M7 3h10a2 2 0 0 1 2 2v16H5V5a2 2 0 0 1 2-2Z" /><path d="M9 8h6M9 12h6M9 16h4" /></>,
  };
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      {paths[name]}
    </svg>
  );
}

function LoginScreen({ onSignedIn }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e) {
    e.preventDefault();
    if (!username.trim() || !password) {
      setError('Enter your username or email and password to continue.');
      return;
    }
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
          <form className="login-card" onSubmit={submit} noValidate>
            <div className="login-brand">
              <img className="login-logo" src="/logo.png" alt="Nway's Love Veterinary Clinic" />
              <div>
                <strong>Nway's Love</strong>
                <span>Veterinary Clinic · Management Portal</span>
              </div>
            </div>

            <div className="login-copy">
              <span className="login-eyebrow">Secure team access</span>
              <h1>Welcome back</h1>
              <p>Sign in to manage appointments, patient care and clinic operations.</p>
            </div>

            <div className="login-field-group">
              <label htmlFor="username">Username or email</label>
              <div className={`field ${error && !username.trim() ? 'invalid' : ''}`}>
                <span className="field-icon"><LoginIcon name="user" /></span>
                <input
                  id="username"
                  value={username}
                  onChange={e => { setUsername(e.target.value); setError(''); }}
                  placeholder="e.g. staff@nwayslove.com"
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck="false"
                  autoFocus
                  disabled={busy}
                  aria-invalid={Boolean(error && !username.trim())}
                />
              </div>
            </div>

            <div className="login-field-group">
              <div className="login-label-row">
                <label htmlFor="password">Password</label>
                <span>Case sensitive</span>
              </div>
              <div className={`field ${error && !password ? 'invalid' : ''}`}>
                <span className="field-icon"><LoginIcon name="lock" /></span>
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={e => { setPassword(e.target.value); setError(''); }}
                  placeholder="Enter your password"
                  autoComplete="current-password"
                  disabled={busy}
                  aria-invalid={Boolean(error && !password)}
                />
                <button
                  className="password-toggle"
                  type="button"
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  aria-pressed={showPassword}
                  onClick={() => setShowPassword(value => !value)}
                  disabled={busy}
                >
                  <LoginIcon name={showPassword ? 'eyeOff' : 'eye'} />
                </button>
              </div>
            </div>

            {error && <div className="error login-error" role="alert">{error}</div>}

            <button className="btn-primary login-submit" disabled={busy}>
              {busy ? <span className="login-spinner" aria-hidden="true" /> : <LoginIcon name="shield" />}
              <span>{busy ? 'Verifying account…' : 'Sign in securely'}</span>
              {!busy && <span className="submit-arrow"><LoginIcon name="arrow" /></span>}
            </button>

            <div className="login-role-note">
              <LoginIcon name="shield" />
              <span>For authorized clinic staff and system administrators only.</span>
            </div>

            <p className="login-help">Need access or having trouble signing in? <strong>Contact your system administrator.</strong></p>
          </form>
        </section>

        <aside className="login-showcase" aria-label="Nway's Love Veterinary Clinic">
          <div className="showcase-orb orb-one" />
          <div className="showcase-orb orb-two" />
          <div className="showcase-copy">
            <span className="showcase-badge"><span /> Clinic operations · Connected</span>
            <h2>Better care starts with a connected team.</h2>
            <p>Keep appointments, patient records, inventory and daily operations organized in one secure workspace.</p>
          </div>
          <div className="showcase-feature-list">
            <div><LoginIcon name="activity" /><span><strong>Live clinic workflow</strong><small>Appointments and queue updates</small></span></div>
            <div><LoginIcon name="records" /><span><strong>One patient record</strong><small>Clear history across the care team</small></span></div>
          </div>
          <div className="showcase-pill pill-top"><LoginIcon name="shield" /><span>Role-based access</span></div>
          <div className="showcase-pill pill-bottom"><span className="status-dot" /><span>Systems connected</span></div>
          <img className="login-pets" src="/pets.png" alt="A dog and cats cared for by the clinic" />
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

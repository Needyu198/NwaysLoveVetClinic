import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  getTable,
  syncTable,
  formatMmk,
  createUser,
  updateUser,
  decideVerification,
  decideRestock,
  recordAudit,
} from './api.js';

// Generic hook to load a table's records with a refresh trigger.
function useTable(table, refreshKey) {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      setRecords(await getTable(table));
      setError('');
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [table]);

  useEffect(() => {
    setLoading(true);
    load();
  }, [load, refreshKey]);

  return { records, loading, error, reload: load };
}

const val = r => r?.data?.value || {};

function StateWrap({ loading, error, empty, emptyText, children }) {
  if (loading) return <div className="muted pad">Loading…</div>;
  if (error) return <div className="error pad">{error}</div>;
  if (empty) return <div className="muted pad">{emptyText || 'No records yet.'}</div>;
  return children;
}

const ROLE_LABEL = {
  owner: 'Pet Owner',
  doctor: 'Doctor',
  staff: 'Staff',
  admin: 'Administrator',
  petOwner: 'Pet Owner',
  systemAdmin: 'Administrator',
};

function StatusPill({ status }) {
  const s = String(status || '').toLowerCase();
  const cls =
    s === 'active' || s === 'approved'
      ? 'ok'
      : s === 'suspended' || s === 'rejected'
        ? 'danger'
        : s === 'pending' || s === 'submitted' || s === 'underreview' || s === 'under review'
          ? 'warn'
          : 'muted';
  const label = status ? status[0].toUpperCase() + status.slice(1) : '—';
  return <span className={`pill ${cls}`}>{label}</span>;
}

// ---- Dashboard -----------------------------------------------------------

export function AdminDashboardView({ refreshKey }) {
  const users = useTable('user_directory', refreshKey);
  const verifs = useTable('doctor_verifications', refreshKey);
  const inv = useTable('inventory', refreshKey);
  const audit = useTable('audit_logs', refreshKey);

  const uv = users.records.map(val);
  const countRole = role => uv.filter(u => u.role === role).length;
  const pendingUsers = uv.filter(u => (u.status || '') === 'pending').length;
  const pendingVerifs = verifs.records
    .map(val)
    .filter(v => ['submitted', 'underReview'].includes(v.status)).length;
  const pendingRestock = inv.records
    .map(val)
    .filter(v => (v.restockStatus || '') === 'pending' || v.restockRequested).length;

  const cards = [
    { label: 'Total users', value: users.records.length, icon: '👥', tone: '' },
    { label: 'Pet owners', value: countRole('owner'), icon: '🐾', tone: 'orange' },
    { label: 'Doctors', value: countRole('doctor'), icon: '🩺', tone: 'purple' },
    { label: 'Staff', value: countRole('staff'), icon: '🧑\u200d⚕️', tone: '' },
    { label: 'Pending users', value: pendingUsers, icon: '⏳', tone: 'orange' },
    { label: 'Pending verifications', value: pendingVerifs, icon: '✅', tone: 'purple' },
    { label: 'Restock requests', value: pendingRestock, icon: '📦', tone: 'orange' },
    { label: 'Audit entries', value: audit.records.length, icon: '📜', tone: '' },
  ];

  return (
    <div className="stat-grid">
      {cards.map(c => (
        <div className="stat-card" key={c.label}>
          <div className={`stat-ico ${c.tone}`}>{c.icon}</div>
          <div className="stat-value">{c.value}</div>
          <div className="stat-label">{c.label}</div>
        </div>
      ))}
    </div>
  );
}

// ---- Users & Roles -------------------------------------------------------

function AddUserModal({ onClose, onSaved }) {
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'owner',
    password: '',
    confirm: '',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  async function submit(e) {
    e.preventDefault();
    setError('');
    if (!form.name.trim()) return setError('Full name is required.');
    if (!/^[\w.\-]+@[\w\-]+\.[\w.\-]+$/.test(form.email.trim()))
      return setError('Enter a valid email.');
    if (form.phone.trim().length < 6) return setError('Enter a valid phone number.');
    if (form.password.length < 8) return setError('Password must be at least 8 characters.');
    if (form.password !== form.confirm) return setError('Passwords do not match.');
    setBusy(true);
    try {
      await createUser({
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        role: form.role,
        password: form.password,
      });
      await recordAudit({
        action: 'Created account',
        module: 'Users and Roles',
        record: `${form.name.trim()} (${form.email.trim()})`,
        newValue: `${ROLE_LABEL[form.role]} • Pending`,
        reason: 'New account provisioned',
      });
      onSaved();
      onClose();
    } catch (err) {
      setError(err.message || 'Could not create the account.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="modal-backdrop" onMouseDown={e => e.target === e.currentTarget && onClose()}>
      <form className="modal" onSubmit={submit}>
        <div className="modal-head">
          <h2>Add User</h2>
          <button type="button" className="icon-btn" onClick={onClose}>✕</button>
        </div>
        <div className="muted small">Create a new account. New accounts start as Pending — activate to allow sign-in.</div>

        <div className="section">User information</div>
        <label>Full name</label>
        <input value={form.name} onChange={e => set('name', e.target.value)} autoFocus />
        <div className="form-grid">
          <div>
            <label>Email</label>
            <input value={form.email} onChange={e => set('email', e.target.value)} type="email" />
          </div>
          <div>
            <label>Phone</label>
            <input value={form.phone} onChange={e => set('phone', e.target.value)} />
          </div>
        </div>
        <label>Role</label>
        <select value={form.role} onChange={e => set('role', e.target.value)}>
          <option value="owner">Pet Owner</option>
          <option value="doctor">Doctor</option>
          <option value="staff">Staff</option>
        </select>

        <div className="section">Password</div>
        <div className="form-grid">
          <div>
            <label>Password</label>
            <input value={form.password} onChange={e => set('password', e.target.value)} type="password" />
          </div>
          <div>
            <label>Confirm password</label>
            <input value={form.confirm} onChange={e => set('confirm', e.target.value)} type="password" />
          </div>
        </div>

        {error && <div className="error">{error}</div>}
        <div className="form-actions">
          <button type="button" className="btn-ghost" onClick={onClose}>Cancel</button>
          <button className="btn-primary" disabled={busy}>{busy ? 'Creating…' : 'Create account'}</button>
        </div>
      </form>
    </div>
  );
}

export function UsersView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('user_directory', refreshKey);
  const [showAdd, setShowAdd] = useState(false);
  const [roleFilter, setRoleFilter] = useState('all');
  const [busyId, setBusyId] = useState('');

  const rows = useMemo(() => {
    const list = records.filter(r => {
      if (roleFilter === 'all') return true;
      return val(r).role === roleFilter;
    });
    return list;
  }, [records, roleFilter]);

  async function setStatus(record, status) {
    setBusyId(record.id);
    const prev = val(record).status;
    try {
      await updateUser(record, { status, lastActive: status === 'active' ? 'Today' : val(record).lastActive });
      await recordAudit({
        action: status === 'active' ? 'Activated account' : 'Suspended account',
        module: 'Users and Roles',
        record: `${val(record).name} (${val(record).id})`,
        previousValue: prev,
        newValue: status,
        reason: status === 'active' ? 'Account approved for sign-in' : 'Account access paused',
      });
      reload();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusyId('');
    }
  }

  const FILTERS = [
    ['all', 'All'],
    ['owner', 'Pet Owners'],
    ['doctor', 'Doctors'],
    ['staff', 'Staff'],
    ['admin', 'Admins'],
  ];

  return (
    <div>
      <div className="view-actions">
        <div style={{ display: 'flex', gap: 8, marginRight: 'auto' }}>
          {FILTERS.map(([k, label]) => (
            <button
              key={k}
              className={`btn-ghost ${roleFilter === k ? '' : ''}`}
              style={roleFilter === k ? { borderColor: 'var(--green)', color: 'var(--green-dark)' } : {}}
              onClick={() => setRoleFilter(k)}
            >
              {label}
            </button>
          ))}
        </div>
        <button className="btn-primary small" onClick={() => setShowAdd(true)}>+ Add User</button>
      </div>
      <StateWrap loading={loading} error={error} empty={rows.length === 0} emptyText="No accounts match this filter.">
        <div className="card">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Role</th>
                <th>Status</th>
                <th>Last active</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {rows.map(r => {
                const v = val(r);
                const status = String(v.status || '');
                return (
                  <tr key={r.id}>
                    <td style={{ fontWeight: 700 }}>{v.name}</td>
                    <td>{v.email}</td>
                    <td>{v.phone}</td>
                    <td>{ROLE_LABEL[v.role] || v.role}</td>
                    <td><StatusPill status={status} /></td>
                    <td className="muted">{v.lastActive || '—'}</td>
                    <td className="row-actions">
                      {status !== 'active' && (
                        <button className="link-btn" disabled={busyId === r.id} onClick={() => setStatus(r, 'active')}>
                          Activate
                        </button>
                      )}
                      {status !== 'suspended' && (
                        <button className="link-btn danger" disabled={busyId === r.id} onClick={() => setStatus(r, 'suspended')}>
                          Suspend
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </StateWrap>
      {showAdd && <AddUserModal onClose={() => setShowAdd(false)} onSaved={reload} />}
    </div>
  );
}

// ---- Doctor verification -------------------------------------------------

export function VerificationView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('doctor_verifications', refreshKey);
  const [busyId, setBusyId] = useState('');

  async function decide(record, status) {
    let reason = '';
    if (status === 'rejected') {
      reason = window.prompt('Reason for rejection:') || '';
      if (!reason.trim()) return;
    }
    setBusyId(record.id);
    try {
      await decideVerification(record, status, reason);
      await recordAudit({
        action: status === 'approved' ? 'Approved doctor' : 'Rejected doctor',
        module: 'Doctor Verification',
        record: `${val(record).name} (${val(record).id})`,
        previousValue: 'Pending',
        newValue: status === 'approved' ? 'Approved' : 'Rejected',
        reason: reason || 'Application reviewed',
      });
      reload();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusyId('');
    }
  }

  return (
    <StateWrap loading={loading} error={error} empty={records.length === 0} emptyText="No verification applications.">
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Doctor</th>
              <th>Specialty</th>
              <th>License</th>
              <th>Documents</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {records.map(r => {
              const v = val(r);
              const pending = ['submitted', 'underReview'].includes(v.status);
              return (
                <tr key={r.id}>
                  <td>
                    <div style={{ fontWeight: 700 }}>{v.name}</div>
                    <div className="muted small">{v.email}</div>
                  </td>
                  <td>{v.specialty}</td>
                  <td>{v.licenseNumber}</td>
                  <td className="muted small">{(v.documents || []).length} files</td>
                  <td><StatusPill status={v.status} /></td>
                  <td className="row-actions">
                    {pending ? (
                      <>
                        <button className="link-btn" disabled={busyId === r.id} onClick={() => decide(r, 'approved')}>
                          Approve
                        </button>
                        <button className="link-btn danger" disabled={busyId === r.id} onClick={() => decide(r, 'rejected')}>
                          Reject
                        </button>
                      </>
                    ) : (
                      <span className="muted small">{v.decisionReason || 'Decided'}</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </StateWrap>
  );
}

// ---- Inventory approval --------------------------------------------------

export function InventoryApprovalView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('inventory', refreshKey);
  const [busyId, setBusyId] = useState('');

  const requests = records.filter(r => {
    const v = val(r);
    return v.restockRequested || ['pending', 'approved', 'declined'].includes(v.restockStatus || '');
  });

  async function decide(record, restockStatus) {
    setBusyId(record.id);
    try {
      await decideRestock(record, restockStatus);
      await recordAudit({
        action: restockStatus === 'approved' ? 'Approved restock' : 'Declined restock',
        module: 'Inventory Approval',
        record: `${val(record).name}`,
        newValue: restockStatus,
        reason: 'Restock request reviewed',
      });
      reload();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusyId('');
    }
  }

  return (
    <StateWrap loading={loading} error={error} empty={requests.length === 0} emptyText="No restock requests.">
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Category</th>
              <th>In stock</th>
              <th>Requested qty</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {requests.map(r => {
              const v = val(r);
              const status = v.restockStatus || 'pending';
              const pending = status === 'pending' || (v.restockRequested && !v.restockStatus);
              return (
                <tr key={r.id}>
                  <td>
                    <div style={{ fontWeight: 700 }}>{v.name}</div>
                    {v.restockNote ? <div className="muted small">{v.restockNote}</div> : null}
                  </td>
                  <td>{v.category}</td>
                  <td>{v.quantity} {v.unit || ''}</td>
                  <td>{v.restockQuantity || '—'}</td>
                  <td><StatusPill status={status} /></td>
                  <td className="row-actions">
                    {pending ? (
                      <>
                        <button className="link-btn" disabled={busyId === r.id} onClick={() => decide(r, 'approved')}>
                          Approve
                        </button>
                        <button className="link-btn danger" disabled={busyId === r.id} onClick={() => decide(r, 'declined')}>
                          Decline
                        </button>
                      </>
                    ) : (
                      <span className="muted small">Reviewed</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </StateWrap>
  );
}

// ---- Audit logs ----------------------------------------------------------

export function AuditLogsView({ refreshKey }) {
  const { records, loading, error } = useTable('audit_logs', refreshKey);

  const sorted = [...records]
    .map(r => ({ id: r.id, v: val(r) }))
    .sort((a, b) => new Date(b.v.timestamp || 0) - new Date(a.v.timestamp || 0));

  return (
    <StateWrap loading={loading} error={error} empty={sorted.length === 0} emptyText="No audit entries recorded.">
      <div className="card">
        <table>
          <thead>
            <tr>
              <th>When</th>
              <th>Action</th>
              <th>Module</th>
              <th>Record</th>
              <th>Actor</th>
              <th>Change</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map(({ id, v }) => (
              <tr key={id}>
                <td className="muted small">
                  {v.timestamp ? new Date(v.timestamp).toLocaleString() : '—'}
                </td>
                <td style={{ fontWeight: 700 }}>{v.action}</td>
                <td>{v.module}</td>
                <td className="muted">{v.record}</td>
                <td>{v.actor}</td>
                <td className="small">
                  {v.previousValue || v.newValue
                    ? `${v.previousValue || '—'} → ${v.newValue || '—'}`
                    : ''}
                  {v.reason ? <div className="muted">{v.reason}</div> : null}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </StateWrap>
  );
}

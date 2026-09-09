import React, { useCallback, useEffect, useState } from 'react';
import { getTable, formatMmk, syncTable, recordKey } from './api.js';
import InventoryForm from './InventoryForm.jsx';

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

function StateWrap({ loading, error, empty, children }) {
  if (loading) return <div className="muted pad">Loading…</div>;
  if (error) return <div className="error pad">{error}</div>;
  if (empty) return <div className="muted pad">No records yet.</div>;
  return children;
}

function Table({ columns, rows, renderCell }) {
  return (
    <div className="card">
      <table>
        <thead>
          <tr>
            {columns.map(c => (
              <th key={c.key}>{c.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={r.id || i}>
              {columns.map(c => (
                <td key={c.key}>{renderCell(r, c)}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ---- Dashboard -----------------------------------------------------------

export function DashboardView({ refreshKey }) {
  const appts = useTable('walk_in_appointments', refreshKey);
  const queue = useTable('queue_entries', refreshKey);
  const pay = useTable('payments', refreshKey);
  const inv = useTable('inventory', refreshKey);

  const revenue = pay.records
    .map(val)
    .filter(v => (v.status || '').toLowerCase() === 'paid')
    .reduce((sum, v) => sum + (Number(v.amount) || 0), 0);
  const lowStock = inv.records
    .map(val)
    .filter(v => Number(v.quantity) <= Number(v.reorderLevel || 0)).length;

  const cards = [
    { label: 'Appointments', value: appts.records.length, icon: '📅', tone: '' },
    { label: 'In queue', value: queue.records.length, icon: '⏳', tone: 'orange' },
    { label: 'Payments', value: pay.records.length, icon: '💳', tone: 'purple' },
    { label: 'Revenue (paid)', value: formatMmk(revenue), icon: '💰', tone: '' },
    { label: 'Inventory items', value: inv.records.length, icon: '📦', tone: 'orange' },
    { label: 'Low stock', value: lowStock, icon: '⚠️', tone: 'purple' },
  ];

  return (
    <div>
      <div className="stat-grid">
        {cards.map(c => (
          <div className="stat-card" key={c.label}>
            <div className={`stat-ico ${c.tone}`}>{c.icon}</div>
            <div className="stat-value">{c.value}</div>
            <div className="stat-label">{c.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ---- Appointments / Walk-in ---------------------------------------------

function ApptView({ table, title, refreshKey }) {
  const { records, loading, error } = useTable(table, refreshKey);
  const columns = [
    { key: 'pet', label: 'Pet' },
    { key: 'owner', label: 'Owner' },
    { key: 'service', label: 'Service' },
    { key: 'doctor', label: 'Doctor' },
    { key: 'date', label: 'Date' },
    { key: 'time', label: 'Time' },
    { key: 'status', label: 'Status' },
  ];
  return (
    <div>
      <h1 className="view-title">{title}</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <Table
          columns={columns}
          rows={records}
          renderCell={(r, c) => {
            const v = val(r);
            if (c.key === 'date' && v.date) {
              return new Date(v.date).toLocaleDateString();
            }
            return String(v[c.key] ?? '');
          }}
        />
      </StateWrap>
    </div>
  );
}

export const AppointmentsView = props => (
  <ApptView table="walk_in_appointments" title="Appointments" {...props} />
);

export function WalkInView({ refreshKey }) {
  return <ApptView table="walk_in_appointments" title="Walk-in" refreshKey={refreshKey} />;
}

// ---- Queue ---------------------------------------------------------------

export function QueueView({ refreshKey }) {
  const { records, loading, error } = useTable('queue_entries', refreshKey);
  const columns = [
    { key: 'queueNumber', label: 'No.' },
    { key: 'pet', label: 'Pet' },
    { key: 'owner', label: 'Owner' },
    { key: 'service', label: 'Service' },
    { key: 'status', label: 'Status' },
  ];
  return (
    <div>
      <h1 className="view-title">Queue</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <Table
          columns={columns}
          rows={records}
          renderCell={(r, c) => String(val(r)[c.key] ?? '')}
        />
      </StateWrap>
    </div>
  );
}

// ---- Payments ------------------------------------------------------------

export function PaymentsView({ refreshKey }) {
  const { records, loading, error } = useTable('payments', refreshKey);
  const columns = [
    { key: 'owner', label: 'Owner' },
    { key: 'pet', label: 'Pet' },
    { key: 'amount', label: 'Amount' },
    { key: 'status', label: 'Status' },
  ];
  return (
    <div>
      <h1 className="view-title">Payments</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <Table
          columns={columns}
          rows={records}
          renderCell={(r, c) => {
            const v = val(r);
            if (c.key === 'amount') return formatMmk(v.amount);
            return String(v[c.key] ?? '');
          }}
        />
      </StateWrap>
    </div>
  );
}

// ---- Inventory (list + add/edit/delete) ---------------------------------

export function InventoryView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('inventory', refreshKey);
  const [editing, setEditing] = useState(null);
  const [showForm, setShowForm] = useState(false);

  const active = records.filter(r => !val(r).archived);

  async function remove(record) {
    if (!window.confirm(`Delete "${val(record).name}"?`)) return;
    try {
      await syncTable('inventory', [], [
        { id: record.id, version: record.version },
      ]);
      reload();
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div>
      <div className="view-actions">
        <span className="count-badge">{active.length} items</span>
        <button
          className="btn-primary small"
          onClick={() => {
            setEditing(null);
            setShowForm(true);
          }}
        >
          + Add New Item
        </button>
      </div>
      <StateWrap loading={loading} error={error} empty={active.length === 0}>
        <div className="card">
          <table>
            <thead>
              <tr>
                <th></th>
                <th>Name</th>
                <th>Category</th>
                <th>Stock</th>
                <th>Price</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {active.map(r => {
                const v = val(r);
                const low = Number(v.quantity) <= Number(v.reorderLevel || 0);
                return (
                  <tr key={r.id}>
                    <td>
                      {v.imageAsset && String(v.imageAsset).startsWith('data:') ? (
                        <img className="thumb" src={v.imageAsset} alt="" />
                      ) : (
                        <div className="thumb placeholder" />
                      )}
                    </td>
                    <td>
                      <div style={{ fontWeight: 700 }}>{v.name}</div>
                      {v.description ? (
                        <div className="muted small">{v.description}</div>
                      ) : null}
                    </td>
                    <td>{v.category}</td>
                    <td>
                      <span className={low ? 'pill danger' : 'pill ok'}>
                        {v.quantity} {v.unit || ''}
                      </span>
                    </td>
                    <td>{formatMmk(v.sellingPrice)}</td>
                    <td className="row-actions">
                      <button
                        className="link-btn"
                        onClick={() => {
                          setEditing(r);
                          setShowForm(true);
                        }}
                      >
                        Edit
                      </button>
                      <button className="link-btn danger" onClick={() => remove(r)}>
                        Delete
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </StateWrap>

      {showForm && (
        <InventoryForm
          existing={editing}
          onClose={() => setShowForm(false)}
          onSaved={reload}
        />
      )}
    </div>
  );
}

// ---- Medical records -----------------------------------------------------

export function MedicalRecordsView({ refreshKey }) {
  const { records, loading, error } = useTable('medical_records', refreshKey);
  const columns = [
    { key: 'petName', label: 'Pet' },
    { key: 'title', label: 'Title' },
    { key: 'category', label: 'Category' },
    { key: 'status', label: 'Status' },
    { key: 'date', label: 'Date' },
  ];
  return (
    <div>
      <h1 className="view-title">Medical Records</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <Table
          columns={columns}
          rows={records}
          renderCell={(r, c) => {
            const v = val(r);
            const raw = v[c.key];
            if (c.key === 'date' && raw) {
              const d = new Date(raw);
              return isNaN(d) ? String(raw) : d.toLocaleDateString();
            }
            return String(raw ?? '');
          }}
        />
      </StateWrap>
    </div>
  );
}

// ---- Health posts --------------------------------------------------------

export function HealthPostsView({ refreshKey }) {
  const { records, loading, error } = useTable('health_posts', refreshKey);
  return (
    <div>
      <h1 className="view-title">Health Posts</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card list">
          {records.map(r => {
            const v = val(r);
            return (
              <div className="list-row" key={r.id}>
                <div style={{ fontWeight: 700 }}>{v.title || 'Untitled'}</div>
                <div className="muted small">{v.body || v.summary || ''}</div>
              </div>
            );
          })}
        </div>
      </StateWrap>
    </div>
  );
}

// ---- Messages ------------------------------------------------------------

export function MessagesView({ refreshKey }) {
  const { records, loading, error } = useTable('clinic_messages', refreshKey);
  return (
    <div>
      <h1 className="view-title">Messages</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card list">
          {records.map(r => {
            const v = val(r);
            return (
              <div className="list-row" key={r.id}>
                <div style={{ fontWeight: 700 }}>{v.subject || v.from || 'Message'}</div>
                <div className="muted small">{v.message || v.body || ''}</div>
              </div>
            );
          })}
        </div>
      </StateWrap>
    </div>
  );
}

// ---- Reports -------------------------------------------------------------

export function ReportsView({ refreshKey }) {
  const pay = useTable('payments', refreshKey);
  const appts = useTable('walk_in_appointments', refreshKey);
  const queue = useTable('queue_entries', refreshKey);

  const paid = pay.records.map(val).filter(v => (v.status || '').toLowerCase() === 'paid');
  const revenue = paid.reduce((s, v) => s + (Number(v.amount) || 0), 0);
  const pending = pay.records.map(val).filter(v => (v.status || '').toLowerCase() !== 'paid').length;
  const completed = appts.records
    .map(val)
    .filter(v => (v.status || '').toLowerCase() === 'completed').length;
  const cancelled = appts.records
    .map(val)
    .filter(v => (v.status || '').toLowerCase() === 'cancelled').length;

  const rows = [
    ['Total revenue (paid)', formatMmk(revenue)],
    ['Payments received', String(paid.length)],
    ['Payments pending', String(pending)],
    ['Appointments total', String(appts.records.length)],
    ['Appointments completed', String(completed)],
    ['Appointments cancelled', String(cancelled)],
    ['Queue entries', String(queue.records.length)],
  ];

  return (
    <div>
      <h1 className="view-title">Reports</h1>
      <div className="card">
        <table>
          <tbody>
            {rows.map(([k, v]) => (
              <tr key={k}>
                <td style={{ fontWeight: 600 }}>{k}</td>
                <td style={{ textAlign: 'right', fontWeight: 800 }}>{v}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

import React, { useCallback, useEffect, useState } from 'react';
import {
  getTable,
  formatMmk,
  syncTable,
  updateRecord,
  createRecord,
  changePassword,
  getAccount,
} from './api.js';
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

async function notifyOwner(record, title, message) {
  if (!record?.owner_id) return;
  await createRecord('owner_notifications', {
    id: `NOTIF-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    title,
    message,
    createdAt: new Date().toISOString(),
    read: false,
  }, { ownerId: record.owner_id });
}

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
  const appts = useTable('appointments', refreshKey);
  const walkIns = useTable('walk_in_appointments', refreshKey);
  const queue = useTable('queue_entries', refreshKey);
  const pay = useTable('payments', refreshKey);
  const inv = useTable('inventory', refreshKey);

  const revenue = pay.records
    .map(val)
    .filter(v => (v.status || '').toLowerCase() === 'paid')
    .reduce((sum, v) => sum + (Number(v.amount) || 0), 0);
  const lowStock = inv.records
    .map(val)
    .filter(v => !v.archived && Number(v.quantity) <= Number(v.reorderLevel || 0)).length;
  const activeQueue = queue.records.map(val).filter(v => v.status !== 'completed').length;

  const cards = [
    { label: 'Appointments', value: appts.records.length + walkIns.records.length, icon: '📅', tone: '' },
    { label: 'In queue', value: activeQueue, icon: '⏳', tone: 'orange' },
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

function ApptView({ table, title, refreshKey, ownerBookings = false }) {
  const { records, loading, error, reload } = useTable(table, refreshKey);
  async function edit(record, action) {
    const v = val(record);
    let patch = {};
    if (action === 'confirm') patch.status = 'Confirmed';
    if (action === 'cancel') {
      const reason = window.prompt('Cancellation reason:');
      if (!reason) return;
      patch = ownerBookings
        ? {
            status: 'Cancelled',
            cancellation: {
              id: `CAN-${Date.now()}`,
              reason,
              additionalReason: '',
              cancelledAt: new Date().toISOString(),
              cancellationFee: 0,
              refundAmount: 0,
              refundStatus: 'notApplicable',
              initiatedBy: 'staff',
              notificationsSent: true,
            },
          }
        : { status: 'Cancelled' };
    }
    if (action === 'doctor') {
      const doctor = window.prompt('Doctor name:', v.veterinarian || v.doctor || '');
      if (!doctor) return;
      patch[ownerBookings ? 'veterinarian' : 'doctor'] = doctor;
    }
    if (action === 'reschedule') {
      const date = window.prompt('New date (YYYY-MM-DD):', String(v.date || '').slice(0, 10));
      const time = date && window.prompt('New time:', v.time || '');
      if (!date || !time) return;
      patch = { date: new Date(`${date}T00:00:00`).toISOString(), time, status: 'Confirmed' };
    }
    try {
      await updateRecord(table, record, patch);
      if (ownerBookings) {
        const pet = v.pet?.name || 'your pet';
        if (action === 'reschedule') {
          await notifyOwner(record, 'Appointment rescheduled', `${pet} is now booked for ${patch.time}. Please review the new time.`);
        } else if (action === 'doctor') {
          await notifyOwner(record, 'Doctor assigned', `${patch.veterinarian} has been assigned to ${pet}.`);
        } else if (patch.status) {
          const message = patch.status === 'Confirmed'
            ? `Your appointment for ${pet} has been confirmed.`
            : patch.status === 'Cancelled'
              ? `Your appointment for ${pet} was cancelled.`
              : `${pet}'s appointment is now "${patch.status}".`;
          await notifyOwner(record, 'Appointment update', message);
        }
      }
      reload();
    } catch (e) {
      alert(e.message);
    }
  }
  return (
    <div>
      <h1 className="view-title">{title}</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card"><table><thead><tr>
          <th>Pet</th><th>Owner</th><th>Service</th><th>Doctor</th>
          <th>Date</th><th>Time</th><th>Status</th><th>Actions</th>
        </tr></thead><tbody>{records.map(r => {
          const v = val(r);
          const pet = ownerBookings ? v.pet?.name : v.pet;
          const service = ownerBookings ? v.service?.name : v.service;
          const doctor = ownerBookings ? v.veterinarian : v.doctor;
          return <tr key={r.id}>
            <td>{pet || '—'}</td><td>{v.owner || r.owner_id}</td>
            <td>{service || '—'}</td><td>{doctor || 'Unassigned'}</td>
            <td>{v.date ? new Date(v.date).toLocaleDateString() : '—'}</td>
            <td>{v.time || '—'}</td><td><span className="pill muted">{v.status}</span></td>
            <td className="row-actions">
              {v.status === 'Pending' && <button className="link-btn" onClick={() => edit(r, 'confirm')}>Confirm</button>}
              <button className="link-btn" onClick={() => edit(r, 'doctor')}>Assign</button>
              {!['Completed', 'Cancelled'].includes(v.status) && <button className="link-btn" onClick={() => edit(r, 'reschedule')}>Reschedule</button>}
              {!['Completed', 'Cancelled'].includes(v.status) && <button className="link-btn danger" onClick={() => edit(r, 'cancel')}>Cancel</button>}
            </td>
          </tr>;
        })}</tbody></table></div>
      </StateWrap>
    </div>
  );
}

export const AppointmentsView = props => (
  <ApptView table="appointments" title="Appointments" ownerBookings {...props} />
);

export function WalkInView({ refreshKey }) {
  const [creating, setCreating] = useState(false);
  const [localRefresh, setLocalRefresh] = useState(0);
  async function register() {
    const owner = window.prompt('Owner name:');
    const pet = owner && window.prompt('Pet name:');
    const service = pet && window.prompt('Service:', 'General Checkup');
    const doctor = service && window.prompt('Available doctor:');
    if (!owner || !pet || !service || !doctor) return;
    setCreating(true);
    const now = new Date();
    try {
      await createRecord('walk_in_appointments', {
        id: `WALK-${Date.now()}`,
        pet, owner, phone: 'Not recorded', service, doctor,
        date: now.toISOString(),
        time: now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        reason: 'Walk-in registration', status: 'Waiting', priority: 'Normal',
        queueNumber: `Q${String(Date.now()).slice(-3)}`,
      });
      setLocalRefresh(k => k + 1);
    } catch (e) {
      alert(e.message);
    } finally {
      setCreating(false);
    }
  }
  return <div>
    <div className="view-actions"><button className="btn-primary small" disabled={creating} onClick={register}>+ Register Walk-in</button></div>
    <ApptView table="walk_in_appointments" title="Walk-in" refreshKey={`${refreshKey}-${localRefresh}`} />
  </div>;
}

// ---- Queue ---------------------------------------------------------------

export function QueueView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('queue_entries', refreshKey);
  const appointments = useTable('appointments', refreshKey);
  async function advance(record) {
    const v = val(record);
    const next = {
      waiting: 'called', almostTurn: 'called', called: 'inConsultation',
      inConsultation: 'completed', completed: 'completed',
    }[v.status] || 'called';
    const appointmentStatus = {
      called: 'Called', inConsultation: 'In Consultation', completed: 'Completed',
    }[next];
    const appointment = { ...v.appointment, status: appointmentStatus };
    const patch = {
      status: next,
      appointment,
      petsAhead: next === 'called' || next === 'inConsultation' || next === 'completed' ? 0 : v.petsAhead,
      estimatedWaitMinutes: next === 'called' || next === 'inConsultation' || next === 'completed' ? 0 : v.estimatedWaitMinutes,
      room: next === 'called' && !v.room ? 'Consultation Room 2' : v.room,
    };
    try {
      await updateRecord('queue_entries', record, patch);
      const source = appointments.records.find(a => val(a).id === appointment.id);
      if (source) await updateRecord('appointments', source, { status: appointmentStatus });
      const pet = appointment.pet?.name || 'your pet';
      const message = appointmentStatus === 'Called'
        ? `It is ${pet}'s turn. Please proceed to the room.`
        : appointmentStatus === 'In Consultation'
          ? `${pet}'s consultation has started.`
          : `${pet}'s visit is complete.`;
      await notifyOwner(record, 'Appointment update', message);
      reload();
      appointments.reload();
    } catch (e) { alert(e.message); }
  }
  return (
    <div>
      <h1 className="view-title">Queue</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card"><table><thead><tr>
          <th>No.</th><th>Pet</th><th>Service</th><th>Doctor</th><th>Status</th><th>Wait</th><th></th>
        </tr></thead><tbody>{records.map(r => { const v = val(r); const a = v.appointment || {}; return <tr key={r.id}>
          <td>{v.queueNumber}</td><td>{a.pet?.name || '—'}</td><td>{a.service?.name || '—'}</td>
          <td>{a.veterinarian || 'Unassigned'}</td><td>{v.status}</td><td>{v.estimatedWaitMinutes || 0} min</td>
          <td>{v.status !== 'completed' && <button className="link-btn" onClick={() => advance(r)}>{v.status === 'called' ? 'Start consultation' : v.status === 'inConsultation' ? 'Complete' : 'Call patient'}</button>}</td>
        </tr>; })}</tbody></table></div>
      </StateWrap>
    </div>
  );
}

// ---- Payments ------------------------------------------------------------

export function PaymentsView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('payments', refreshKey);
  async function markPaid(record) {
    const method = window.prompt('Payment method:', 'Cash');
    if (!method) return;
    try { await updateRecord('payments', record, { status: 'Paid', paymentMethod: method, paidAt: new Date().toISOString() }); reload(); }
    catch (e) { alert(e.message); }
  }
  return (
    <div>
      <h1 className="view-title">Payments</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card"><table><thead><tr><th>Invoice</th><th>Owner</th><th>Pet</th><th>Amount</th><th>Status</th><th></th></tr></thead>
          <tbody>{records.map(r => { const v = val(r); return <tr key={r.id}><td>{v.id}</td><td>{v.owner}</td><td>{v.pet}</td><td>{formatMmk(v.amount)}</td><td>{v.status}</td><td>{v.status !== 'Paid' && <button className="link-btn" onClick={() => markPaid(r)}>Confirm payment</button>}</td></tr>; })}</tbody>
        </table></div>
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

  async function moveStock(record, direction) {
    const v = val(record);
    const raw = window.prompt(`${direction === 'in' ? 'Stock in' : 'Stock out'} quantity:`, '1');
    const quantity = Number(raw);
    if (!Number.isInteger(quantity) || quantity <= 0) return;
    const next = direction === 'in' ? Number(v.quantity) + quantity : Number(v.quantity) - quantity;
    if (next < 0) return alert('Not enough stock.');
    const movement = {
      id: `MOV-${Date.now()}`,
      type: direction === 'in' ? 'Stock In' : 'Stock Out',
      quantity,
      previousBalance: Number(v.quantity),
      newBalance: next,
      reason: direction === 'in' ? 'Delivery received' : 'Clinic use',
      staff: getAccount()?.fullName || 'Staff',
      at: new Date().toISOString(),
      reference: '',
    };
    try {
      await updateRecord('inventory', record, {
        quantity: next,
        movements: [...(v.movements || []), movement],
        lastAudit: `${movement.type} ${direction === 'in' ? '+' : '-'}${quantity}`,
        ...(direction === 'in' && next > Number(v.reorderLevel) ? { restockRequested: false, restockStatus: 'Received' } : {}),
      });
      reload();
    } catch (e) { alert(e.message); }
  }

  async function requestRestock(record) {
    const quantity = Number(window.prompt('Requested quantity:', String(Math.max(1, Number(val(record).reorderLevel) * 2))));
    if (!Number.isInteger(quantity) || quantity <= 0) return;
    const note = window.prompt('Restock note:', 'Stock is at or below the reorder level.') || '';
    try {
      await updateRecord('inventory', record, {
        restockRequested: true, restockQuantity: quantity,
        restockNote: note, restockStatus: 'Pending Approval',
      });
      reload();
    } catch (e) { alert(e.message); }
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
                      <button className="link-btn" onClick={() => moveStock(r, 'in')}>Stock in</button>
                      <button className="link-btn" onClick={() => moveStock(r, 'out')}>Stock out</button>
                      {low && <button className="link-btn" onClick={() => requestRestock(r)}>Restock</button>}
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
  const { records, loading, error, reload } = useTable('clinic_messages', refreshKey);
  const [replying, setReplying] = useState('');
  async function resolve(record) {
    try { await updateRecord('clinic_messages', record, { status: 'read' }); reload(); }
    catch (e) { alert(e.message); }
  }
  async function reply(record) {
    const text = window.prompt('Reply to this pet owner:');
    if (!text?.trim()) return;
    setReplying(record.id);
    try {
      await createRecord('clinic_messages', {
        id: `STAFF-${Date.now()}`,
        text: text.trim(),
        createdAt: new Date().toISOString(),
        category: 'other',
        isFromStaff: true,
        petName: val(record).petName || null,
        status: 'read',
      }, { ownerId: record.owner_id });
      if (!val(record).isFromStaff) await updateRecord('clinic_messages', record, { status: 'read' });
      reload();
    } catch (e) { alert(e.message); }
    finally { setReplying(''); }
  }
  return (
    <div>
      <h1 className="view-title">Messages</h1>
      <StateWrap loading={loading} error={error} empty={records.length === 0}>
        <div className="card list">
          {records.map(r => {
            const v = val(r);
            return (
              <div className="list-row" key={r.id}>
                <div style={{ fontWeight: 700 }}>{v.isFromStaff ? 'Staff reply' : `${v.category || 'Other'} message`}</div>
                <div>{v.text || v.message || v.body || ''}</div>
                <div className="muted small">{v.petName ? `Pet: ${v.petName} • ` : ''}{v.createdAt ? new Date(v.createdAt).toLocaleString() : ''} • {v.status}</div>
                {!v.isFromStaff && <div className="row-actions">
                  <button className="link-btn" disabled={replying === r.id} onClick={() => reply(r)}>Reply</button>
                  {v.status !== 'read' && <button className="link-btn" onClick={() => resolve(r)}>Resolve</button>}
                </div>}
              </div>
            );
          })}
        </div>
      </StateWrap>
    </div>
  );
}

// ---- Patients, emergencies and home visits ------------------------------

export function PatientsView({ refreshKey, query = '' }) {
  const { records, loading, error } = useTable('pets', refreshKey);
  const q = query.trim().toLowerCase();
  const rows = records.filter(r => {
    const v = val(r);
    return !q || [v.name, v.type, v.breed, r.owner_id].some(x => String(x || '').toLowerCase().includes(q));
  });
  return <StateWrap loading={loading} error={error} empty={rows.length === 0}>
    <div className="card"><table><thead><tr><th>Pet</th><th>Species</th><th>Breed</th><th>Sex</th><th>Birth date</th><th>Owner ID</th></tr></thead>
      <tbody>{rows.map(r => { const v = val(r); return <tr key={r.id}><td style={{fontWeight:700}}>{v.name}</td><td>{v.type}</td><td>{v.breed}</td><td>{v.sex}</td><td>{v.dateOfBirth ? new Date(v.dateOfBirth).toLocaleDateString() : '—'}</td><td className="muted small">{r.owner_id}</td></tr>; })}</tbody>
    </table></div>
  </StateWrap>;
}

export function EmergenciesView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('emergency_requests', refreshKey);
  const nextAction = status => ({ submitted: ['Start review', 'underReview'], underReview: ['Assign & accept', 'accepted'], accepted: ['Mark arrived', 'checkedIn'] }[status]);
  async function advance(record) {
    const action = nextAction(val(record).status);
    if (!action) return;
    const patch = action[1] === 'underReview'
      ? { status: action[1], priority: 'High', clinicResponse: 'The clinic is reviewing this emergency request.' }
      : action[1] === 'accepted'
        ? { status: action[1], clinicResponse: 'A veterinarian has been assigned. Please travel to the clinic now.' }
        : { status: action[1], clinicResponse: 'The pet has arrived and is checked in.' };
    try { await updateRecord('emergency_requests', record, patch); reload(); }
    catch (e) { alert(e.message); }
  }
  return <StateWrap loading={loading} error={error} empty={records.length === 0}>
    <div className="card"><table><thead><tr><th>Pet</th><th>Symptoms</th><th>Contact</th><th>Priority</th><th>Status</th><th></th></tr></thead>
      <tbody>{records.map(r => { const v = val(r); const action = nextAction(v.status); return <tr key={r.id}><td><strong>{v.pet?.name}</strong><div className="muted small">{v.pet?.breed}</div></td><td>{(v.symptoms || []).join(', ')}</td><td><a href={`tel:${String(v.phone || '').replace(/[^0-9+]/g, '')}`}>{v.phone}</a></td><td>{v.priority}</td><td>{v.status}</td><td>{action && <button className="link-btn" onClick={() => advance(r)}>{action[0]}</button>}</td></tr>; })}</tbody>
    </table></div>
  </StateWrap>;
}

export function HomeVisitsView({ refreshKey }) {
  const { records, loading, error, reload } = useTable('home_visits', refreshKey);
  const next = { confirmed: 'onTheWay', onTheWay: 'arrived', arrived: 'consultation', consultation: 'treatmentProposed', treatmentProposed: 'completed' };
  async function assign(record) {
    const doctor = window.prompt('Assign veterinarian:', val(record).veterinarian || '');
    if (!doctor) return;
    try {
      const v = val(record);
      await updateRecord('home_visits', record, { veterinarian: doctor, status: v.status === 'confirmed' ? 'onTheWay' : v.status });
      await notifyOwner(record, 'Home visit doctor assigned', `${doctor} is assigned to ${v.pet?.name || 'your pet'}'s home visit and is on the way.`);
      reload();
    }
    catch (e) { alert(e.message); }
  }
  async function advance(record) {
    const status = next[val(record).status];
    if (!status) return;
    const patch = status === 'completed' ? {
      status,
      findings: 'General examination completed.',
      treatmentNotes: 'Supportive home care provided.',
      medicines: 'Follow the veterinarian dosage instructions.',
      recommendations: 'Monitor symptoms and contact the clinic if they worsen.',
    } : { status };
    try { await updateRecord('home_visits', record, patch); reload(); }
    catch (e) { alert(e.message); }
  }
  return <StateWrap loading={loading} error={error} empty={records.length === 0}>
    <div className="card"><table><thead><tr><th>Pet</th><th>Date</th><th>Address</th><th>Veterinarian</th><th>Status</th><th></th></tr></thead>
      <tbody>{records.map(r => { const v = val(r); return <tr key={r.id}><td>{v.pet?.name}</td><td>{v.date ? new Date(v.date).toLocaleDateString() : '—'} {v.time}</td><td>{v.address}</td><td>{v.veterinarian || 'Unassigned'}</td><td>{v.status}</td><td className="row-actions"><button className="link-btn" onClick={() => assign(r)}>Assign</button>{next[v.status] && <button className="link-btn" onClick={() => advance(r)}>Advance status</button>}</td></tr>; })}</tbody>
    </table></div>
  </StateWrap>;
}

export function AccountView() {
  const [current, setCurrent] = useState('');
  const [nextPassword, setNextPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [message, setMessage] = useState('');
  async function submit(e) {
    e.preventDefault(); setMessage('');
    if (nextPassword.length < 8) return setMessage('New password must be at least 8 characters.');
    if (nextPassword !== confirm) return setMessage('Passwords do not match.');
    try { await changePassword(current, nextPassword); setCurrent(''); setNextPassword(''); setConfirm(''); setMessage('Password updated.'); }
    catch (e) { setMessage(e.message); }
  }
  return <form className="card pad" onSubmit={submit} style={{maxWidth:560}}>
    <h2>Account security</h2><p className="muted">Update the password used by the mobile and web staff portals.</p>
    <label>Current password</label><input type="password" value={current} onChange={e => setCurrent(e.target.value)} required />
    <label>New password</label><input type="password" value={nextPassword} onChange={e => setNextPassword(e.target.value)} required />
    <label>Confirm new password</label><input type="password" value={confirm} onChange={e => setConfirm(e.target.value)} required />
    <button className="btn-primary">Update password</button>{message && <div className={message === 'Password updated.' ? 'muted pad' : 'error'}>{message}</div>}
  </form>;
}

// ---- Reports -------------------------------------------------------------

export function ReportsView({ refreshKey }) {
  const pay = useTable('payments', refreshKey);
  const appts = useTable('appointments', refreshKey);
  const walkIns = useTable('walk_in_appointments', refreshKey);
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
    ['Appointments total', String(appts.records.length + walkIns.records.length)],
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

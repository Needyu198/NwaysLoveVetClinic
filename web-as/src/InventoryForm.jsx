import React, { useRef, useState } from 'react';
import { saveInventoryItem } from './api.js';

// Matches the Flutter "Add New Item" form: photo, item name + category,
// description, stock (quantity), pricing (selling price). Writes a
// database-compatible inventory record.
const CATEGORIES = [
  'Pet Food',
  'Medicine',
  'Vaccines',
  'Medical Supplies',
  'Cleaning Supplies',
  'Accessories',
  'Other',
];

function readValue(record) {
  return record?.data?.value || {};
}

export default function InventoryForm({ existing, onClose, onSaved }) {
  const isEdit = !!existing;
  const current = readValue(existing);

  const [name, setName] = useState(current.name || '');
  const [category, setCategory] = useState(current.category || CATEGORIES[0]);
  const [description, setDescription] = useState(current.description || '');
  const [quantity, setQuantity] = useState(
    current.quantity != null ? String(current.quantity) : '',
  );
  const [sellingPrice, setSellingPrice] = useState(
    current.sellingPrice != null ? String(current.sellingPrice) : '',
  );
  // Photo stored as a base64 data URI (same as the Flutter app).
  const [imageData, setImageData] = useState(current.imageAsset || null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const fileRef = useRef(null);

  function pickPhoto(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError('Please choose a photo smaller than 2 MB.');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => setImageData(reader.result);
    reader.readAsDataURL(file);
  }

  async function submit(e) {
    e.preventDefault();
    setError('');
    const qty = parseInt(quantity, 10);
    const price = parseInt(sellingPrice, 10);
    if (!name.trim()) return setError('Item name is required.');
    if (!isEdit && (Number.isNaN(qty) || qty < 0)) {
      return setError('Enter a valid quantity.');
    }
    if (Number.isNaN(price) || price < 0) {
      return setError('Enter a valid selling price.');
    }

    setBusy(true);
    try {
      const id = isEdit ? current.id : `item-${Date.now()}`;
      const item = {
        ...current,
        id,
        name: name.trim(),
        category,
        description: description.trim(),
        // Quantity is locked when editing (matches Flutter).
        quantity: isEdit ? current.quantity : qty,
        reorderLevel: isEdit
          ? current.reorderLevel
          : Math.min(100, Math.max(1, Math.ceil(qty * 0.2))),
        unit: current.unit || 'pcs',
        sellingPrice: price,
        purchasePrice: current.purchasePrice ?? 0,
        expiresOn:
          current.expiresOn ||
          new Date(Date.now() + 365 * 864e5).toISOString(),
        imageAsset: imageData,
      };
      await saveInventoryItem(item, existing);
      onSaved?.();
      onClose?.();
    } catch (err) {
      setError(err.message || 'Could not save the item.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form
        className="modal"
        onClick={e => e.stopPropagation()}
        onSubmit={submit}
      >
        <div className="modal-head">
          <h2>{isEdit ? 'Edit Item' : 'Add New Item'}</h2>
          <button type="button" className="icon-btn" onClick={onClose}>
            ✕
          </button>
        </div>

        <div
          className="photo-picker"
          onClick={() => fileRef.current?.click()}
        >
          {imageData ? (
            <img src={imageData} alt="item" />
          ) : (
            <span>+ Add item photo</span>
          )}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            hidden
            onChange={pickPhoto}
          />
        </div>
        {imageData && (
          <div style={{ textAlign: 'center', marginTop: 6 }}>
            <button
              type="button"
              className="link-btn danger"
              onClick={() => setImageData(null)}
            >
              Remove photo
            </button>
          </div>
        )}

        <h3 className="section">Item information</h3>
        <label>Item name</label>
        <input value={name} onChange={e => setName(e.target.value)} />
        <label>Category</label>
        <select value={category} onChange={e => setCategory(e.target.value)}>
          {CATEGORIES.map(c => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <label>Description</label>
        <textarea
          rows={3}
          value={description}
          onChange={e => setDescription(e.target.value)}
        />

        <h3 className="section">Stock</h3>
        <label>{isEdit ? 'Quantity (locked)' : 'Initial quantity'}</label>
        <input
          type="number"
          value={quantity}
          disabled={isEdit}
          onChange={e => setQuantity(e.target.value)}
        />

        <h3 className="section">Pricing</h3>
        <label>Selling price (MMK)</label>
        <input
          type="number"
          value={sellingPrice}
          onChange={e => setSellingPrice(e.target.value)}
        />

        {error && <div className="error">{error}</div>}

        <button className="btn-primary" disabled={busy}>
          {busy ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Item'}
        </button>
      </form>
    </div>
  );
}

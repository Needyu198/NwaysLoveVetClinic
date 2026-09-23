import React, { useRef, useState } from 'react';
import { saveInventoryItem } from './api.js';

// Matches the Flutter product form and writes the same shared inventory record.
const CATEGORIES = ['Food', 'Medicine', 'Accessories'];
const PET_TYPES = ['Dog', 'Cat', 'All Pets'];
const IMAGE_LABELS = ['Main image', 'Package back', 'Product detail'];

function readValue(record) {
  return record?.data?.value || {};
}

export default function InventoryForm({ existing, onClose, onSaved }) {
  const isEdit = !!existing;
  const current = readValue(existing);

  const [name, setName] = useState(current.name || '');
  const [category, setCategory] = useState(
    CATEGORIES.includes(current.category) ? current.category : CATEGORIES[0],
  );
  const [subcategory, setSubcategory] = useState(current.subcategory || '');
  const [petType, setPetType] = useState(current.petType || PET_TYPES[0]);
  const [brand, setBrand] = useState(current.brand || '');
  const [description, setDescription] = useState(current.description || '');
  const [quantity, setQuantity] = useState(
    current.quantity != null ? String(current.quantity) : '5',
  );
  const [sellingPrice, setSellingPrice] = useState(
    current.sellingPrice != null ? String(current.sellingPrice) : '',
  );
  // Photos are base64 data URIs in the same ordered slots as the Flutter app.
  const [images, setImages] = useState(() => {
    const saved = Array.isArray(current.productImages)
      ? current.productImages.slice(0, 3)
      : [];
    while (saved.length < 3) saved.push(null);
    if (!saved[0] && current.imageAsset) saved[0] = current.imageAsset;
    return saved;
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const fileRefs = useRef([]);

  function pickPhoto(index, e) {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      setError('Please choose a photo smaller than 2 MB.');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setImages(previous =>
        previous.map((value, imageIndex) =>
          imageIndex === index ? reader.result : value,
        ),
      );
    };
    reader.readAsDataURL(file);
  }

  async function submit(e) {
    e.preventDefault();
    setError('');
    const qty = parseInt(quantity, 10);
    const price = parseInt(sellingPrice, 10);
    if (!name.trim()) return setError('Item name is required.');
    if (!subcategory.trim()) return setError('Subcategory is required.');
    if (!brand.trim()) return setError('Brand is required.');
    if (!isEdit && (Number.isNaN(qty) || qty < 0)) {
      return setError('Enter a valid quantity.');
    }
    if (Number.isNaN(price) || price < 0) {
      return setError('Enter a valid selling price.');
    }

    setBusy(true);
    try {
      const id = isEdit
        ? current.id
        : `PRD-${Date.now().toString(36).toUpperCase()}`;
      const item = {
        ...current,
        id,
        name: name.trim(),
        category,
        subcategory: subcategory.trim(),
        petType,
        brand: brand.trim(),
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
        imageAsset: images[0] || null,
        productImages: images.filter(Boolean),
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

        <h3 className="section">Item information</h3>
        <label>Product ID</label>
        <input
          value={current.id || 'Generated automatically when saved'}
          disabled
        />
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
        <label>Subcategory</label>
        <input
          value={subcategory}
          onChange={e => setSubcategory(e.target.value)}
        />
        <label>Pet type</label>
        <select value={petType} onChange={e => setPetType(e.target.value)}>
          {PET_TYPES.map(type => (
            <option key={type} value={type}>
              {type}
            </option>
          ))}
        </select>
        <label>Brand</label>
        <input value={brand} onChange={e => setBrand(e.target.value)} />
        <label>Description</label>
        <textarea
          rows={3}
          value={description}
          onChange={e => setDescription(e.target.value)}
        />

        <h3 className="section">Product images</h3>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
            gap: 8,
          }}
        >
          {IMAGE_LABELS.map((label, index) => (
            <div key={label} style={{ textAlign: 'center' }}>
              <div
                className="photo-picker"
                onClick={() => fileRefs.current[index]?.click()}
              >
                {images[index] ? (
                  <img src={images[index]} alt={label} />
                ) : (
                  <span>+ Add photo</span>
                )}
                <input
                  ref={element => {
                    fileRefs.current[index] = element;
                  }}
                  type="file"
                  accept="image/*"
                  hidden
                  onChange={event => pickPhoto(index, event)}
                />
              </div>
              <small>{label}</small>
              {images[index] && (
                <button
                  type="button"
                  className="link-btn danger"
                  onClick={() =>
                    setImages(previous =>
                      previous.map((value, imageIndex) =>
                        imageIndex === index ? null : value,
                      ),
                    )
                  }
                >
                  Remove
                </button>
              )}
            </div>
          ))}
        </div>

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

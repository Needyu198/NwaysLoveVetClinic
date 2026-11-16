// MyanmarPay merchant-presented QR, May 2023. TLV lengths count Unicode
// characters. The checksum covers the UTF-8 bytes through the final "6304".
function invalid(message) {
  throw Object.assign(new Error(message), { status: 503 });
}

function decodeFields(text) {
  const chars = Array.from(text);
  const fields = new Map();
  for (let pos = 0; pos < chars.length;) {
    const header = chars.slice(pos, pos + 4).join('');
    if (!/^\d{4}$/.test(header)) invalid('The merchant QR contains an invalid field.');
    const tag = header.slice(0, 2);
    const size = Number(header.slice(2));
    pos += 4;
    if (!size || pos + size > chars.length || fields.has(tag)) {
      invalid('The merchant QR has an invalid field length or duplicate field.');
    }
    fields.set(tag, chars.slice(pos, pos + size).join(''));
    pos += size;
  }
  return fields;
}

function encodeFields(fields) {
  return [...fields].sort(([a], [b]) => a.localeCompare(b)).map(([tag, value]) => {
    const size = Array.from(value).length;
    if (!size || size > 99) invalid('The merchant QR field is too long for this invoice.');
    return tag + String(size).padStart(2, '0') + value;
  }).join('');
}

function crc16(text) {
  let crc = 0xffff;
  for (const byte of Buffer.from(text, 'utf8')) {
    crc ^= byte << 8;
    for (let bit = 0; bit < 8; bit++) {
      crc = ((crc & 0x8000) ? (crc << 1) ^ 0x1021 : crc << 1) & 0xffff;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

function readMerchantQr(text) {
  if (typeof text !== 'string' || Buffer.byteLength(text) > 512 ||
      !text.startsWith('000201') || !/6304[0-9A-F]{4}$/.test(text) ||
      crc16(text.slice(0, -4)) !== text.slice(-4)) {
    invalid('Use the complete MyanmarPay merchant QR text with its original checksum.');
  }
  const fields = decodeFields(text);
  if (fields.get('53') !== '104' || fields.get('58') !== 'MM' ||
      !/^\d{4}$/.test(fields.get('52') || '') || !fields.has('59') || !fields.has('60')) {
    invalid('The QR must identify a Myanmar merchant and use MMK.');
  }
  const account = decodeFields(fields.get('26') || '');
  if (!account.get('00') || !account.get('01')) invalid('The QR is missing its MMQR merchant account.');
  return fields;
}

function invoiceMerchantQr(sticker, amount, reference) {
  if (!sticker) invalid('Clinic MMQR payments are not configured. Please choose another payment method.');
  const fields = readMerchantQr(sticker);
  if (fields.has('54') || (fields.has('01') && fields.get('01') !== '11')) {
    invalid('Configure the original reusable merchant sticker, without an invoice amount.');
  }
  if (!Number.isSafeInteger(amount) || amount <= 0 || amount.toFixed(2).length > 13) {
    throw Object.assign(new Error('The invoice amount is outside the supported MMQR range.'), { status: 400 });
  }
  if (['55', '56', '57'].some(tag => fields.has(tag))) {
    invalid('Use an acquiring provider for merchant QRs with tips or convenience fees.');
  }
  if (!/^[A-Za-z0-9-]{1,25}$/.test(reference)) invalid('Invalid MMQR invoice reference.');
  const additional = decodeFields(fields.get('62') || '');
  additional.set('01', reference); // Bill number. Preserve the terminal and store labels.
  fields.set('01', '12');
  fields.set('54', amount.toFixed(2));
  fields.set('62', encodeFields(additional));
  fields.delete('63');
  const body = encodeFields(fields) + '6304';
  if (Buffer.byteLength(body) + 4 > 512) invalid('The invoice QR exceeds the MyanmarPay size limit.');
  return body + crc16(body);
}

function checkProviderQr(payload, amount) {
  if (typeof payload !== 'string' || !payload.trim() || payload.startsWith('MMQR|')) {
    invalid('The payment provider did not return a wallet payment QR.');
  }
  // An acquiring adapter may also return an opaque, order-bound wallet token.
  // EMV payloads carry the amount explicitly and can be checked locally.
  if (payload.startsWith('000201')) {
    const fields = readMerchantQr(payload);
    const encoded = fields.get('54') || '';
    if (['55', '56', '57'].some(tag => fields.has(tag)) ||
        !/^\d+(?:\.\d{0,2})?$/.test(encoded) || Number(encoded) !== amount) {
      invalid('The payment provider QR does not contain the invoice amount.');
    }
  }
}

module.exports = { invoiceMerchantQr, checkProviderQr };

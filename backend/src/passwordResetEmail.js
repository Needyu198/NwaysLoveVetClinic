const resetEmailConfigured = () => Boolean(
  String(process.env.RESEND_API_KEY || '').trim() &&
  String(process.env.PASSWORD_RESET_FROM_EMAIL || '').trim(),
);

const escapeHtml = value => String(value || '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#39;');

async function sendPasswordResetEmail({ to, name, code }) {
  if (!resetEmailConfigured()) {
    throw new Error('Password-reset email delivery is not configured.');
  }
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: process.env.PASSWORD_RESET_FROM_EMAIL,
      to: [to],
      subject: "Nway's Love Vet Clinic password reset code",
      html: `<p>Hello ${escapeHtml(name || 'there')},</p>
        <p>Your password reset verification code is:</p>
        <p style="font-size:30px;font-weight:700;letter-spacing:6px">${escapeHtml(code)}</p>
        <p>This code expires in 10 minutes. If you did not request it, you can ignore this email.</p>`,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Password-reset email failed (${response.status}): ${details.slice(0, 300)}`);
  }
}

module.exports = { resetEmailConfigured, sendPasswordResetEmail };

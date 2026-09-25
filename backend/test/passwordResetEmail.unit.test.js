const { test } = require('node:test');
const assert = require('node:assert/strict');

test('password reset email uses configured sender without exposing HTML input', async () => {
  const previousKey = process.env.RESEND_API_KEY;
  const previousFrom = process.env.PASSWORD_RESET_FROM_EMAIL;
  const previousFetch = global.fetch;
  process.env.RESEND_API_KEY = 'test-key';
  process.env.PASSWORD_RESET_FROM_EMAIL = 'Clinic <no-reply@clinic.test>';
  let sent;
  global.fetch = async (url, options) => {
    sent = { url, options };
    return { ok: true, status: 200, text: async () => '' };
  };
  try {
    delete require.cache[require.resolve('../src/passwordResetEmail')];
    const { resetEmailConfigured, sendPasswordResetEmail } = require('../src/passwordResetEmail');
    assert.equal(resetEmailConfigured(), true);
    await sendPasswordResetEmail({
      to: 'owner@clinic.test',
      name: '<Owner>',
      code: '123456',
    });
    assert.equal(sent.url, 'https://api.resend.com/emails');
    assert.equal(sent.options.headers.Authorization, 'Bearer test-key');
    const body = JSON.parse(sent.options.body);
    assert.deepEqual(body.to, ['owner@clinic.test']);
    assert.match(body.html, /123456/);
    assert.match(body.html, /&lt;Owner&gt;/);
    assert.doesNotMatch(body.html, /Hello <Owner>/);
  } finally {
    global.fetch = previousFetch;
    if (previousKey == null) delete process.env.RESEND_API_KEY;
    else process.env.RESEND_API_KEY = previousKey;
    if (previousFrom == null) delete process.env.PASSWORD_RESET_FROM_EMAIL;
    else process.env.PASSWORD_RESET_FROM_EMAIL = previousFrom;
  }
});

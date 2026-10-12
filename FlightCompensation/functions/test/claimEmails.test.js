const test = require('node:test');
const assert = require('node:assert');
const { buildClaimEmails, validateClaim } = require('../claimEmails');

const uid = 'user123';
const ref = 'FC-ABCD2345';
function claim(overrides = {}) {
    return {
        userId: uid,
        claimReference: ref,
        status: 'submitted',
        claimType: 'airline',
        flight: { number: 'IB3166', airlineCode: 'IB', airlineName: 'Iberia', date: '2026-09-01T10:00:00Z', from: 'MAD', to: 'CDG', bookingReference: 'ABC123' },
        passenger: { firstName: 'Ana', lastName: 'Lopez', email: 'ana@example.com' },
        signature: { signedAt: '2026-09-10T10:00:00Z', documentSHA256: 'abc' },
        documents: { authorization: `claims/${uid}/${ref}/Authorization_${ref}.pdf` },
        ...overrides,
    };
}
const opts = { opsEmail: 'ops@co.com', companyName: 'Co S.L.', userEmail: 'ana@example.com', attachments: [] };

test('valid claim passes validation', () => {
    assert.deepStrictEqual(validateClaim(claim(), ref), []);
});

test('document outside the user folder is rejected', () => {
    const problems = validateClaim(claim({ documents: { authorization: `claims/otherUser/${ref}/x.pdf` } }), ref);
    assert.ok(problems.some((p) => p.includes('outside')));
});

test('path traversal is rejected', () => {
    const problems = validateClaim(claim({ documents: { authorization: `claims/${uid}/${ref}/../../x.pdf` } }), ref);
    assert.ok(problems.length > 0);
});

test('missing signature evidence is rejected', () => {
    assert.ok(validateClaim(claim({ signature: {} }), ref).includes('missing signature evidence'));
});

test('known airline gets an email and the claim is sent', () => {
    const { emails, status } = buildClaimEmails(claim(), ref, opts);
    assert.strictEqual(status, 'sent_to_airline');
    const airline = emails.find((m) => m.kind === 'airline');
    assert.deepStrictEqual(airline.to, ['reclamaciones@iberia.es']);
    assert.ok(airline.message.text.includes('ABC123'));
    assert.ok(emails.find((m) => m.kind === 'passenger'));
    assert.ok(emails.find((m) => m.kind === 'ops'));
});

test('test claims never email the real airline', () => {
    const { emails } = buildClaimEmails(claim({ isTest: true }), ref, opts);
    assert.deepStrictEqual(emails.find((m) => m.kind === 'airline').to, ['ops@co.com']);
});

test('web-form airlines and unknown airlines go to manual review', () => {
    for (const code of ['FR', 'ZZ']) {
        const { emails, status } = buildClaimEmails(claim({ flight: { ...claim().flight, airlineCode: code } }), ref, opts);
        assert.strictEqual(status, 'needs_review');
        assert.strictEqual(emails.find((m) => m.kind === 'airline'), undefined);
    }
});

test('AESA escalations are filed manually', () => {
    const { status } = buildClaimEmails(claim({ claimType: 'aesa' }), ref, opts);
    assert.strictEqual(status, 'needs_review');
});

test('forceManual skips the airline email', () => {
    const { emails, status } = buildClaimEmails(claim(), ref, { ...opts, forceManual: true });
    assert.strictEqual(status, 'needs_review');
    assert.strictEqual(emails.find((m) => m.kind === 'airline'), undefined);
});

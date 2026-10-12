// Run with `npm run test:rules` (starts the Firestore + Storage emulators).
const test = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, serverTimestamp } = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');

let env;
const ALICE = 'alice';
const BOB = 'bob';
const REF = 'FC-ABCD2345';

function claim(uid = ALICE, extra = {}) {
    return {
        userId: uid,
        claimReference: REF,
        status: 'submitted',
        claimType: 'airline',
        createdAt: serverTimestamp(),
        flight: { number: 'IB3166' },
        passenger: { firstName: 'A' },
        signature: { signedAt: 'x', documentSHA256: 'y' },
        documents: { authorization: `claims/${uid}/${REF}/a.pdf` },
        ...extra,
    };
}

test.before(async () => {
    env = await initializeTestEnvironment({
        projectId: 'demo-flighty',
        firestore: { rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8180 },
        storage: { rules: fs.readFileSync(path.join(__dirname, '../../storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 },
    });
});
test.after(async () => env && env.cleanup());

test('users can only read and write their own flights', async () => {
    const alice = env.authenticatedContext(ALICE).firestore();
    await assertSucceeds(setDoc(doc(alice, `users/${ALICE}/flights/f1`), { n: 1 }));
    await assertSucceeds(getDoc(doc(alice, `users/${ALICE}/flights/f1`)));
    await assertFails(getDoc(doc(alice, `users/${BOB}/flights/f1`)));
    await assertFails(setDoc(doc(alice, `users/${BOB}/flights/f1`), { n: 1 }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), `users/${ALICE}/flights/f1`)));
});

test('claims: owner creates once, nobody else reads, no client updates', async () => {
    const alice = env.authenticatedContext(ALICE).firestore();
    const bob = env.authenticatedContext(BOB).firestore();
    await assertFails(setDoc(doc(bob, `claims/${REF}`), claim(ALICE)));            // impersonation
    await assertFails(setDoc(doc(alice, `claims/${REF}`), claim(ALICE, { status: 'paid' })));
    await assertFails(setDoc(doc(alice, `claims/${REF}`), claim(ALICE, { payoutIban: 'X' }))); // unknown field
    await assertSucceeds(setDoc(doc(alice, `claims/${REF}`), claim(ALICE)));
    await assertSucceeds(getDoc(doc(alice, `claims/${REF}`)));
    await assertFails(getDoc(doc(bob, `claims/${REF}`)));
    await assertFails(updateDoc(doc(alice, `claims/${REF}`), { status: 'paid' }));
});

test('clients cannot write to the mail queue or unknown collections', async () => {
    const alice = env.authenticatedContext(ALICE).firestore();
    await assertFails(setDoc(doc(alice, 'mail/x'), { to: ['a@b.c'] }));
    await assertFails(setDoc(doc(alice, 'anything/x'), { a: 1 }));
});

test('storage: claim files are private and immutable', async () => {
    const alice = env.authenticatedContext(ALICE).storage();
    const bob = env.authenticatedContext(BOB).storage();
    const pdf = new Uint8Array([37, 80, 68, 70]);
    const file = `claims/${ALICE}/${REF}/a.pdf`;
    await assertSucceeds(uploadBytes(ref(alice, file), pdf, { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(alice, file), pdf, { contentType: 'application/pdf' })); // overwrite
    await assertFails(uploadBytes(ref(alice, `claims/${ALICE}/${REF}/x.exe`), pdf, { contentType: 'application/octet-stream' }));
    await assertFails(uploadBytes(ref(bob, `claims/${ALICE}/${REF}/b.pdf`), pdf, { contentType: 'application/pdf' }));
    await assertSucceeds(getBytes(ref(alice, file)));
    await assertFails(getBytes(ref(bob, file)));
});

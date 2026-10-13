const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineString } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { buildClaimEmails, validateClaim } = require('./claimEmails');

admin.initializeApp();

// Configure with `firebase functions:config` replacement: .env.<project> in this folder
// (see .env.example). Nothing secret lives here; email is sent by the Trigger Email extension.
const OPS_EMAIL = defineString('OPS_EMAIL', { default: 'claims@example.com' });
const COMPANY_NAME = defineString('COMPANY_NAME', { default: 'Flighty Compensation' });

/**
 * A passenger submitted a claim from the app (claims/{claimId}, see firestore.rules).
 * The app uploaded the signed PDFs to Storage first. Here we:
 *  1. validate the document and the file paths,
 *  2. pick the airline inbox server-side (the app can't choose recipients),
 *  3. queue the airline email, the passenger confirmation and an ops notification
 *     in the `mail` collection read by the Trigger Email extension,
 *  4. move the claim to `sent_to_airline` or `needs_review`.
 */
exports.onClaimCreated = onDocumentCreated('claims/{claimId}', async (event) => {
    const snap = event.data;
    if (!snap) return;
    const claimId = event.params.claimId;
    const claim = snap.data();

    const problems = validateClaim(claim, claimId);
    if (problems.length > 0) {
        logger.warn('Rejected claim', { claimId, problems });
        await snap.ref.update({ status: 'rejected_invalid', problems });
        return;
    }

    let userEmail = claim.passenger && claim.passenger.email;
    try {
        const user = await admin.auth().getUser(claim.userId);
        if (user.email) userEmail = user.email;
    } catch (err) {
        logger.warn('Could not load auth user, using claim email', { claimId, err: err.message });
    }

    const bucket = admin.storage().bucket();
    const attachments = [];
    for (const [kind, path] of Object.entries(claim.documents || {})) {
        // Only signed documents go to the airline; ID / boarding pass scans stay with ops.
        if (kind !== 'authorization' && kind !== 'airlineLetter') continue;
        const [buffer] = await bucket.file(path).download();
        attachments.push({
            filename: path.split('/').pop(),
            content: buffer.toString('base64'),
            encoding: 'base64',
            contentType: 'application/pdf',
        });
    }

    // Firestore documents are capped at 1 MiB; keep attachments well under it.
    const attachmentBytes = attachments.reduce((sum, a) => sum + a.content.length, 0);
    const tooLarge = attachmentBytes > 700 * 1024;
    if (tooLarge) logger.warn('Attachments too large for the mail queue, routing to ops', { claimId, attachmentBytes });

    const built = buildClaimEmails(claim, claimId, {
        forceManual: tooLarge,
        opsEmail: OPS_EMAIL.value(),
        companyName: COMPANY_NAME.value(),
        userEmail,
        attachments: tooLarge ? [] : attachments,
    });
    const emails = built.emails;
    const status = built.status;

    const db = admin.firestore();
    const batch = db.batch();
    for (const mail of emails) {
        batch.set(db.collection('mail').doc(`${claimId}_${mail.kind}`), {
            to: mail.to,
            cc: mail.cc || [],
            replyTo: mail.replyTo || OPS_EMAIL.value(),
            message: mail.message,
            claimReference: claimId,
            type: mail.kind,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    batch.update(snap.ref, {
        status,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    logger.info('Claim processed', { claimId, status, emails: emails.map((m) => m.kind) });
});

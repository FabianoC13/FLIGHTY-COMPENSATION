// Pure helpers for onClaimCreated (no Firebase imports) so they can be unit tested with `npm test`.
const airlines = require('./airlines');

// Airlines that ignore or bounce emailed claims from representatives and require their web form.
// Their claims go to ops for manual filing instead of an email the airline will never read.
const WEB_FORM_ONLY = new Set(['FR', 'RK', 'AL', 'U2', 'EC', 'DS', 'W6', 'W9', 'W4']);

const CLAIM_ID_PATTERN = /^FC-[A-Z0-9]{8,}$/;

function validateClaim(claim, claimId) {
    const problems = [];
    if (!claim || typeof claim !== 'object') return ['missing data'];
    if (!CLAIM_ID_PATTERN.test(claimId)) problems.push('bad claim reference');
    if (typeof claim.userId !== 'string' || claim.userId.length === 0) problems.push('missing userId');
    if (!['airline', 'aesa'].includes(claim.claimType)) problems.push('bad claimType');

    const f = claim.flight || {};
    for (const key of ['number', 'airlineCode', 'date', 'from', 'to']) {
        if (!f[key]) problems.push(`missing flight.${key}`);
    }
    const p = claim.passenger || {};
    for (const key of ['firstName', 'lastName', 'email']) {
        if (!p[key]) problems.push(`missing passenger.${key}`);
    }
    const s = claim.signature || {};
    if (!s.signedAt || !s.documentSHA256) problems.push('missing signature evidence');

    const docs = claim.documents || {};
    if (!docs.authorization) problems.push('missing signed authorization');
    const prefix = `claims/${claim.userId}/${claimId}/`;
    for (const [kind, path] of Object.entries(docs)) {
        if (typeof path !== 'string' || !path.startsWith(prefix) || path.includes('..')) {
            problems.push(`document ${kind} outside ${prefix}`);
        }
    }
    return problems;
}

function passengerName(claim) {
    return `${claim.passenger.firstName} ${claim.passenger.lastName}`.trim();
}

/**
 * Decide which emails to queue for a new claim and the claim's next status.
 * @returns {{emails: Array<{kind: string, to: string[], cc?: string[], replyTo?: string, message: object}>, status: string}}
 */
function buildClaimEmails(claim, claimId, { opsEmail, companyName, userEmail, attachments, forceManual = false }) {
    const code = String(claim.flight.airlineCode || '').toUpperCase();
    const airline = airlines[code];
    const name = passengerName(claim);
    const flight = claim.flight;
    const flightLabel = `${flight.number} ${flight.from}-${flight.to} on ${String(flight.date).slice(0, 10)}`;
    const emails = [];

    const canEmailAirline = !forceManual && claim.claimType === 'airline' && Boolean(airline) && !WEB_FORM_ONLY.has(code);
    let status = 'needs_review';

    if (canEmailAirline) {
        // Test claims from debug builds never reach a real airline.
        const to = claim.isTest ? [opsEmail] : [airline.email];
        emails.push({
            kind: 'airline',
            to,
            cc: [opsEmail],
            replyTo: opsEmail,
            message: {
                subject: `EC 261/2004 compensation claim - ${flightLabel} - ${name} - Ref ${claimId}`,
                text: [
                    'Dear Sir or Madam,',
                    '',
                    `${companyName} acts on behalf of ${name}, passenger on flight ${flightLabel}` +
                        (flight.bookingReference ? ` (booking reference ${flight.bookingReference})` : '') + '.',
                    '',
                    'Please find attached the formal claim for compensation under Regulation (EC) No 261/2004',
                    'and the passenger\'s signed authorisation and assignment of claim.',
                    '',
                    `Please reply to this address quoting reference ${claimId}. Under the attached authorisation,`,
                    'payment must be made to the account indicated in the claim letter.',
                    '',
                    'Kind regards,',
                    `${companyName} - Claims team`,
                ].join('\n'),
                attachments,
            },
        });
        status = 'sent_to_airline';
    }

    emails.push({
        kind: 'ops',
        to: [opsEmail],
        message: {
            subject: `[${status}] New claim ${claimId} - ${flightLabel}`,
            text: [
                `Claim ${claimId} by ${name} <${userEmail || claim.passenger.email}>`,
                `Type: ${claim.claimType}${claim.isTest ? ' (TEST)' : ''}`,
                `Airline: ${code} ${airline ? airline.name : '(no inbox on file)'}`,
                canEmailAirline ? 'Sent to the airline by email.'
                    : forceManual ? 'Attachments too large for the email queue: download them from Storage and file manually.'
                    : WEB_FORM_ONLY.has(code) ? 'Airline requires its web form: file it manually.'
                    : claim.claimType === 'aesa' ? 'Escalation to the national enforcement body (AESA): file it manually.'
                    : 'No airline inbox on file: find the right channel and file it manually.',
                `Eligibility: ${JSON.stringify(claim.eligibility || {})}`,
                `Disruption: ${JSON.stringify(claim.disruption || {})}`,
                `Documents: ${Object.values(claim.documents || {}).join(', ')}`,
            ].join('\n'),
            attachments,
        },
    });

    if (userEmail) {
        emails.push({
            kind: 'passenger',
            to: [userEmail],
            message: {
                subject: `We received your claim ${claimId} - flight ${flight.number}`,
                text: [
                    `Hi ${claim.passenger.firstName},`,
                    '',
                    `We have received your compensation claim for flight ${flightLabel}. Reference: ${claimId}.`,
                    canEmailAirline
                        ? `We have sent it to ${airline.name} on your behalf.`
                        : 'Our team is preparing it and will file it with the airline on your behalf.',
                    'Airlines usually answer within 2 to 8 weeks. We will email you at every step.',
                    '',
                    'A copy of the documents you signed is attached.',
                    '',
                    companyName,
                ].join('\n'),
                attachments,
            },
        });
    }

    return { emails, status };
}

module.exports = { buildClaimEmails, validateClaim, WEB_FORM_ONLY, CLAIM_ID_PATTERN };

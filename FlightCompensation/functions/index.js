const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure your email transporter (e.g., Gmail, SendGrid, etc.)
// For Gmail, use an App Password: https://myaccount.google.com/apppasswords
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'pepegallardo69420@gmail.com',
        pass: 'enme cwlr ctro jnjy'
    }
});

exports.onClaimCreated = functions.firestore
    .document('claims/{claimId}')
    .onCreate(async (snap, context) => {
        const claim = snap.data();
        const claimId = context.params.claimId;

        console.log(`New claim created: ${claimId}`);

        const mailOptions = {
            from: 'Claims Bot <claims@flightcompensation.app>',
            to: claim.airlineEmail || 'airline@example.com', // You should store airline email in Firestore
            cc: claim.userEmail,
            subject: `Formal Complaint - Flight ${claim.flightNumber} - Ref: ${claimId}`,
            text: `
        To whom it may concern,

        Please find the attached formal complaint for flight ${claim.flightNumber}.
        
        Passenger: ${claim.passengerName}
        Route: ${claim.route}
        Date: ${claim.submissionDate.toDate().toDateString()}

        Please process with urgency.
        
        Sincerely,
        Flighty Compensation Legal Team
      `,
            attachments: []
        };

        // Add attachments if URLs exist
        if (claim.masterDocURL) {
            mailOptions.attachments.push({
                filename: `Authorization-${claimId}.pdf`,
                path: claim.masterDocURL
            });
        }

        if (claim.airlineLetterURL) {
            mailOptions.attachments.push({
                filename: `Complaint-Letter-${claimId}.pdf`,
                path: claim.airlineLetterURL
            });
        }

        try {
            await transporter.sendMail(mailOptions);
            console.log('✅ Email sent successfully!');
            return snap.ref.update({ status: 'email_sent' });
        } catch (error) {
            console.error('❌ Error sending email:', error);
            return snap.ref.update({ status: 'email_failed', error: error.message });
        }
    });

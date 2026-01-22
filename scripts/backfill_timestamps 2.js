const admin = require('firebase-admin');
const path = require('path');

// Load Service Account from JSON file
// NOTE: You must have flighty-service-account.json in the same directory
const serviceAccountPath = path.join(__dirname, 'flighty-service-account.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function backfillCollection(collectionName, dateFieldSource) {
    console.log(`🚀 Starting backfill of "createdAt" fields in "${collectionName}"...`);
    const snapshot = await db.collection(collectionName).get();

    if (snapshot.empty) {
        console.log(`No documents found in "${collectionName}" collection.`);
        return;
    }

    const batch = db.batch();
    let count = 0;

    snapshot.forEach(doc => {
        const data = doc.data();

        // If createdAt already exists, skip
        if (data.createdAt) return;

        let timestamp = new Date();

        // Specific logic for each collection to find the best date source
        if (collectionName === 'mail') {
            if (data.delivery && data.delivery.startTime) {
                timestamp = data.delivery.startTime.toDate ? data.delivery.startTime.toDate() : new Date(data.delivery.startTime);
            }
        } else if (collectionName === 'claims') {
            if (data.submissionDate) {
                timestamp = data.submissionDate.toDate ? data.submissionDate.toDate() : new Date(data.submissionDate);
            }
        }

        batch.update(doc.ref, {
            createdAt: admin.firestore.Timestamp.fromDate(timestamp)
        });
        count++;
    });

    if (count > 0) {
        await batch.commit();
        console.log(`✅ Updated ${count} documents in "${collectionName}".`);
    } else {
        console.log(`✨ All documents in "${collectionName}" already have timestamps.`);
    }
}

async function run() {
    try {
        await backfillCollection('mail');
        await backfillCollection('claims');
        await backfillCollection('users');
    } catch (error) {
        console.error('❌ Error during backfill:', error);
    }
}

run().catch(console.error);

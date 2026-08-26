import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, deleteDoc, doc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyA85xttfjtpe_AFGNNbWOKSzfOxIS3zUMY",
  authDomain: "skiplaain.firebaseapp.com",
  projectId: "skiplaain",
  storageBucket: "skiplaain.firebasestorage.app",
  messagingSenderId: "171720765352",
  appId: "1:171720765352:web:620d49136ab21cacf1379d",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function clearCollection(colName) {
  console.log(`Fetching documents from collection: ${colName}...`);
  const snap = await getDocs(collection(db, colName));
  console.log(`Found ${snap.docs.length} documents in ${colName}. Deleting...`);
  
  for (const d of snap.docs) {
    await deleteDoc(doc(db, colName, d.id));
    console.log(`Deleted ${colName}/${d.id}`);
  }
  console.log(`Done clearing ${colName}.`);
}

async function run() {
  try {
    await clearCollection('partners');
    await clearCollection('customers');
    await clearCollection('memberships');
    await clearCollection('bookings');
    console.log('ALL SALON PARTNERS AND CUSTOMERS CLEARED SUCCESSFULLY!');
    process.exit(0);
  } catch (err) {
    console.error('Error clearing data:', err);
    process.exit(1);
  }
}

run();

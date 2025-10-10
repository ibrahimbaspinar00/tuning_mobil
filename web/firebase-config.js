// Firebase configuration for web
const firebaseConfig = {
  apiKey: "AIzaSyDummyKeyForDevelopment123456789",
  authDomain: "tuning-mobil-app.firebaseapp.com",
  projectId: "tuning-mobil-app",
  storageBucket: "tuning-mobil-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

export { db, storage };

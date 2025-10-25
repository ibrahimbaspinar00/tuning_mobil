// Firebase configuration for web
const firebaseConfig = {
  apiKey: "AIzaSyBzOhIsfrHYXJz_ffuP7wspOAy35PryuD0",
  authDomain: "tuning-app-789ce.firebaseapp.com",
  projectId: "tuning-app-789ce",
  storageBucket: "tuning-app-789ce.firebasestorage.app",
  messagingSenderId: "695605179145",
  appId: "1:695605179145:web:0131a14c4028ddd0c119d8",
  measurementId: "G-P3JRYNC411"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

export { db, storage };

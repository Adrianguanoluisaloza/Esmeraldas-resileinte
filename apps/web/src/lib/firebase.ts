import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

/**
 * Config del proyecto Firebase (reemplazar con los valores de tu proyecto en Firebase Console).
 * Solo variables PUBLIC_* — nunca secretos aquí.
 */
const firebaseConfig = {
  apiKey: "REEMPLAZAR_CON_FIREBASE_API_KEY",
  authDomain: "tu-proyecto.firebaseapp.com",
  projectId: "tu-proyecto",
  storageBucket: "tu-proyecto.firebasestorage.app",
  messagingSenderId: "000000000000",
  appId: "1:000000000000:web:0000000000000000000000",
};

let app: FirebaseApp;
if (getApps().length === 0) {
  app = initializeApp(firebaseConfig);
} else {
  app = getApps()[0]!;
}

export const auth = getAuth(app);
export const proveedorGoogle = new GoogleAuthProvider();
proveedorGoogle.setCustomParameters({ prompt: "select_account" });

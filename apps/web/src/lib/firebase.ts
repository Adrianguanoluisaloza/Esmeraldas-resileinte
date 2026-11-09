import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

/**
 * Config del proyecto Firebase: esmeralsrelesiente (644267053650).
 * Solo variables PUBLIC_* — nunca secretos aquí.
 * El apiKey de Firebase para web es público por diseño (Google lo documenta así);
 * la seguridad real está en las reglas de Firebase y en el backend que verifica el token.
 */
const firebaseConfig = {
  apiKey: "AIzaSyAciUc8fEt_QPj6inaZPR7Sfby60HBP-aQ",
  authDomain: "esmeralsrelesiente.firebaseapp.com",
  projectId: "esmeralsrelesiente",
  storageBucket: "esmeralsrelesiente.firebasestorage.app",
  messagingSenderId: "644267053650",
  appId: "1:644267053650:android:71bc72c7671c740865c58b",
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

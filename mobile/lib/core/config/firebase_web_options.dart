import 'package:firebase_core/firebase_core.dart';

/// Configuración de Firebase para ejecutar la app en el navegador.
/// Es la misma de la web del proyecto. Estos valores son públicos por diseño:
/// la seguridad está en el backend, que verifica el token.
const FirebaseOptions opcionesFirebaseWeb = FirebaseOptions(
  apiKey: 'AIzaSyAciUc8fEt_QPj6inaZPR7Sfby60HBP-aQ',
  authDomain: 'esmeralsrelesiente.firebaseapp.com',
  projectId: 'esmeralsrelesiente',
  storageBucket: 'esmeralsrelesiente.firebasestorage.app',
  messagingSenderId: '644267053650',
  appId: '1:644267053650:android:71bc72c7671c740865c58b',
);

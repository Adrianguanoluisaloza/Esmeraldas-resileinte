import 'package:firebase_core/firebase_core.dart';

/// Configuración de Firebase para ejecutar la app en el navegador.
/// Es la misma de la web del proyecto. Estos valores son públicos por diseño:
/// la seguridad está en el backend, que verifica el token.
const FirebaseOptions opcionesFirebaseWeb = FirebaseOptions(
  apiKey: 'REEMPLAZAR_CON_FIREBASE_API_KEY',
  authDomain: 'tu-proyecto.firebaseapp.com',
  projectId: 'tu-proyecto',
  storageBucket: 'tu-proyecto.firebasestorage.app',
  messagingSenderId: '000000000000',
  appId: '1:000000000000:web:0000000000000000000000',
);

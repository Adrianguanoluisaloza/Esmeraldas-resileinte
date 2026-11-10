# Prompt para Gemini: Google con Firebase en la app móvil

Pegar completo en Gemini, en el repositorio de Franco.

```text
Trabajas en la app Flutter de Esmeraldas Resiliente, carpeta mobile/, rama francopcontrol.
Antes de nada lee AGENTS.md, docs/orquestacion/TAREAS_MOVIL_FRANCO.md y contrato/openapi.yaml.

PROBLEMA
El botón de Google nunca funcionó contra el servidor: la app llama a POST /auth/google, y esa ruta no existe.
La ruta real es POST /auth/firebase. Recibe {"idToken": "<token de Firebase>"} y devuelve {token, usuario},
igual que POST /auth/login.

PREPARACIÓN
1. git fetch origin
2. git checkout origin/desarrollo-adrian -- contrato/openapi.yaml
3. Copia los dos archivos que te pasó Adrian, y no los subas nunca a Git:
   - google-services.json en mobile/android/app/google-services.json
   - franco.env en mobile/franco.env (agrega mobile/franco.env a .gitignore)

TAREAS
1. Firebase en Android: aplica el plugin com.google.gms.google-services en Gradle. Agrega firebase_core,
   firebase_auth y google_sign_in a pubspec.yaml. Llama a Firebase.initializeApp en main.dart.
2. Reemplaza GoogleAuthService, que hoy usa flutter_appauth, por este flujo:
   google_sign_in con serverClientId = AppConfig.googleClientId, luego GoogleAuthProvider.credential con el
   idToken de Google, luego FirebaseAuth.signInWithCredential, luego user.getIdToken(), luego POST /auth/firebase.
   Guarda el JWT de la respuesta exactamente igual que en el login normal. Elimina toda referencia a /auth/google.
   Si flutter_appauth ya no se usa, quítalo de pubspec.yaml.
3. Firebase se usa SOLO para Google. Correo y contraseña siguen contra nuestra API: POST /auth/login y
   POST /auth/registro. No uses createUserWithEmailAndPassword ni los correos de Firebase.
4. Agrega "Olvidé mi contraseña" en el login: pide el correo y llama POST /auth/recuperar con {"correo": "..."}.
   Responde 202 exista o no el correo. Muestra siempre: "Si ese correo tiene una cuenta, enviamos un enlace para
   crear una contraseña nueva." La contraseña nueva se crea en la web, no en la app.
5. Con MODO_DEMO=false no puede haber ningún respaldo a datos o cuentas de demo. Si Google falla, muestra un
   error claro. Si la persona cancela, vuelve al login sin mostrar error.
6. Saca las huellas con: cd mobile/android y ./gradlew signingReport. Entrega a Adrian los SHA-1 de debug y de
   release, y DETENTE hasta que él los registre en Firebase (paquete ec.esmeraldas.resiliente.mobile) y te pase
   un google-services.json nuevo. Sin eso Google falla con el error 10.

REGLAS
- Clean Architecture: Firebase y google_sign_in solo en data/. domain/ no los importa.
- presentation/ depende de domain/. La composición se hace en main.dart.
- No inventes campos fuera de contrato/openapi.yaml. No toques apps/api ni database.
- Cero emojis en la interfaz. Iconos de Material.
- Sin secretos en el repositorio ni dentro del código.
- Commits pequeños, uno por tarea. Actualiza bitacora.md y CHANGELOG.md al final.

VERIFICACIÓN (si falla algo, no subas)
- Pruebas con dobles, sin red ni Firebase real: Google correcto, Google cancelado, error de red y 401 del servidor.
- dart format --set-exit-if-changed lib test
- flutter analyze
- flutter test
- flutter build apk --release --dart-define-from-file=franco.env
- En el celular: entrar con Google, entrar con la cuenta de correo, crear un reporte en modo avión, activar la
  conexión y confirmar que el reporte aparece en el mapa del COE.
Si la ruta tiene la letra ñ y flutter analyze se cae, córrelo desde una unidad virtual creada con subst.

Al terminar dime qué cambió, qué probaste en el celular y qué no pudiste verificar.
```

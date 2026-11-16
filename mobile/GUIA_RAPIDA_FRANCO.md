# Guía de Conexión y Pruebas para Franco

> La URL del túnel de abajo es temporal. La forma vigente de conectar está en `docs/orquestacion/TAREAS_MOVIL_FRANCO.md` (M9 y M11).

Franco, este archivo contiene todo listo para que hagas `git pull` en tu celular o tu máquina y todo se sincronice con el backend en vivo.

---

## 1. Conexión del celular a la API

El backend ya está levantado y expuesto a través de un túnel seguro Cloudflare activo:

- **URL Pública del Backend:** `https://tunel-ejemplo.trycloudflare.com`
- **Comprobación rápida (navegador o terminal):**  
  `https://tunel-ejemplo.trycloudflare.com/salud`  
  Responde: `{"estado":"ok", ...}`

> [!NOTE]
> `AppConfig.apiBaseUrl` ya viene configurado para apuntar automáticamente a este túnel si compilas en Android/iOS físico.
> Si deseas forzar la URL explícitamente:
> ```bash
> flutter run --dart-define=API_BASE_URL=https://tunel-ejemplo.trycloudflare.com
> ```

---

## 2. Credenciales de Demostración (Hackathon)

Todas las cuentas demo usan la misma contraseña:

**Contraseña universal:** `demo-resiliente-2026`

| Rol | Correo | Función |
| :--- | :--- | :--- |
| **Administrador COE** | `admin@demo.esmeraldas-resiliente.ec` | Panel de mando, auditoría, usuarios |
| **Operador 911 / COE** | `operador@demo.esmeraldas-resiliente.ec` | Gestión de incidentes y asignación |
| **Ciudadano** | `ciudadano@demo.esmeraldas-resiliente.ec` | Reportar incidentes y ver albergues |
| **Sin cuenta / Offline** | *(Botón en login)* | Tocar **"Emergencia sin internet: reportar ahora"** |

---

## 3. Pasos para actualizar y correr en tu celular

1. **Hacer Pull de la rama:**
   ```bash
   git pull origin desarrollo-adrian
   ```
   *(o si estás en tu rama `desarrollofranco`, haz `git merge desarrollo-adrian`)*

2. **Obtener dependencias:**
   ```bash
   cd mobile
   flutter pub get
   ```

3. **Ejecutar en tu celular (conectado por USB o Wi-Fi):**
   ```bash
   flutter run
   ```

---

## 4. Cómo probar el flujo estrella del Hackathon (Offline-First)

1. **Reporte sin señal:**
   - Abre la app y toca *"Emergencia sin internet: reportar ahora"* (o activa el chip **Offline / Modo Avión** arriba a la derecha).
   - Toca el mapa para fijar el incidente (el mapa vectorial de Esmeraldas y el pin rojo funcionan 100% offline).
   - Completa el formulario de daños (afectados, necesidades: rescate, agua, etc.) y pulsa **Enviar reporte**.
   - Verás el mensaje: *"Reporte guardado en cola local. Se enviará al recuperar señal."*
   - En la pestaña **Mis reportes** verás el estado en **Pendiente**.

2. **Recuperación de señal y sincronización:**
   - Desactiva el modo avión (toca el chip para volver a **Online** o dale al botón **Sincronizar**).
   - El worker en segundo plano subirá el reporte de inmediato a la API.
   - En **Mis reportes** pasará a **Sincronizado**.
   - El operador del COE verá aparecer el incidente en el mapa de mando en tiempo real.

---

## 5. Panel Web del COE (para ver los reportes que envías desde el celular)

- Web pública: `https://esmeraldas-resiliente.eliasadrianlozadaguanoluisa.workers.dev`
- Panel COE: `/panel`
- Inicia sesión con: `operador@demo.esmeraldas-resiliente.ec` / `demo-resiliente-2026`

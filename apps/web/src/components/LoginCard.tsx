import React, { useState, useEffect } from 'react';
import {
  type RolUsuario,
  type UsuarioSesion,
  USUARIOS_DEMO,
  obtenerSesionActual,
  guardarSesion,
  cerrarSesion,
} from '../lib/auth';

interface Props {
  redirectUrl?: string;
}

export const LoginCard: React.FC<Props> = ({ redirectUrl = '/' }) => {
  const [esRegistro, setEsRegistro] = useState(false);
  const [nombre, setNombre] = useState('');
  const [correo, setCorreo] = useState('operador@coe911.gob.ec');
  const [password, setPassword] = useState('operador2026');
  const [rolSeleccionado, setRolSeleccionado] = useState<RolUsuario>('operador_911');
  const [mostrarPassword, setMostrarPassword] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sesionActiva, setSesionActiva] = useState<UsuarioSesion | null>(null);

  useEffect(() => {
    const sesion = obtenerSesionActual();
    if (sesion) {
      setSesionActiva(sesion);
    }
  }, []);

  const seleccionarDemo = (rol: RolUsuario) => {
    const demo = USUARIOS_DEMO[rol];
    setRolSeleccionado(rol);
    setCorreo(demo.correo);
    setPassword(demo.pass);
    setNombre(demo.usuario.nombre);
    setError(null);
  };

  const manejarEnvio = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setCargando(true);

    try {
      // Simulación de respuesta inmediata o llamada a API
      await new Promise((resolve) => setTimeout(resolve, 600));

      const usuarioFinal: UsuarioSesion = {
        id: `usr-${Date.now()}`,
        nombre: esRegistro ? nombre || 'Usuario Nuevo' : USUARIOS_DEMO[rolSeleccionado]?.usuario.nombre || correo.split('@')[0],
        correo: correo,
        rol: rolSeleccionado,
        creado_en: new Date().toISOString(),
      };

      guardarSesion({
        token: `mock-jwt-token-${Date.now()}`,
        usuario: usuarioFinal,
      });

      setSesionActiva(usuarioFinal);

      // Redirigir al panel de operaciones
      setTimeout(() => {
        window.location.href = redirectUrl;
      }, 500);
    } catch (err: any) {
      setError(err?.message || 'Error al autenticar. Verifique credenciales.');
    } finally {
      setCargando(false);
    }
  };

  const manejarCerrarSesion = () => {
    cerrarSesion();
    setSesionActiva(null);
  };

  if (sesionActiva) {
    return (
      <div className="login-card-container">
        <div className="login-card sesion-activa-card">
          <div className="sesion-avatar">
            {sesionActiva.rol === 'operador_911' ? '🛡️' : sesionActiva.rol === 'admin' ? '⚡' : '👤'}
          </div>
          <h2 className="login-titulo">Sesión Iniciada</h2>
          <p className="login-subtitulo">
            Bienvenido, <strong>{sesionActiva.nombre}</strong>
          </p>

          <div className="sesion-detalles">
            <div className="sesion-fila">
              <span>Correo:</span>
              <strong>{sesionActiva.correo}</strong>
            </div>
            <div className="sesion-fila">
              <span>Rol asignado:</span>
              <span className={`badge-rol-pill rol-${sesionActiva.rol}`}>
                {sesionActiva.rol.toUpperCase()}
              </span>
            </div>
          </div>

          <div className="sesion-acciones">
            <a href="/" className="btn-ir-panel">
              Ir al Centro de Mando 911 →
            </a>
            <button onClick={manejarCerrarSesion} className="btn-cerrar-sesion">
              Cerrar Sesión
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="login-card-container">
      {/* Esfera decorativa de fondo sutil tipo SaaS */}
      <div className="glow-sphere"></div>

      <div className="login-card">
        {/* Cabecera del Formulario */}
        <div className="login-header">
          <div className="logo-badge">
            <span className="logo-dot"></span>
            ESMERALDAS RESILIENTE
          </div>
          <h1 className="login-titulo">
            {esRegistro ? 'Crear Cuenta de Operador' : 'Centro de Operaciones 911'}
          </h1>
          <p className="login-subtitulo">
            {esRegistro
              ? 'Regístrate para colaborar en la gestión de emergencias'
              : 'Acceso seguro al panel de mando y gestión territorial'}
          </p>
        </div>

        {/* Selector de Acceso Rápido para Demostración */}
        <div className="demo-roles-seccion">
          <span className="demo-label">Acceso rápido para la demo:</span>
          <div className="demo-pills">
            <button
              type="button"
              onClick={() => seleccionarDemo('operador_911')}
              className={`demo-pill ${rolSeleccionado === 'operador_911' ? 'demo-pill-activo' : ''}`}
            >
              🛡️ Operador 911
            </button>
            <button
              type="button"
              onClick={() => seleccionarDemo('admin')}
              className={`demo-pill ${rolSeleccionado === 'admin' ? 'demo-pill-activo' : ''}`}
            >
              ⚡ Admin
            </button>
            <button
              type="button"
              onClick={() => seleccionarDemo('ciudadano')}
              className={`demo-pill ${rolSeleccionado === 'ciudadano' ? 'demo-pill-activo' : ''}`}
            >
              👥 Ciudadano
            </button>
          </div>
        </div>

        {/* Pestañas Iniciar Sesión / Registro */}
        <div className="auth-tabs">
          <button
            type="button"
            className={`auth-tab ${!esRegistro ? 'auth-tab-activo' : ''}`}
            onClick={() => {
              setEsRegistro(false);
              setError(null);
            }}
          >
            Iniciar Sesión
          </button>
          <button
            type="button"
            className={`auth-tab ${esRegistro ? 'auth-tab-activo' : ''}`}
            onClick={() => {
              setEsRegistro(true);
              setError(null);
            }}
          >
            Registrarse
          </button>
        </div>

        {error && <div className="login-error-alert">{error}</div>}

        {/* Formulario de Entrada */}
        <form onSubmit={manejarEnvio} className="login-form">
          {esRegistro && (
            <div className="form-group">
              <label className="form-label">Nombre Completo</label>
              <div className="input-wrapper">
                <span className="input-icon">👤</span>
                <input
                  type="text"
                  required
                  placeholder="Ej: Adrian Guanoluisa"
                  value={nombre}
                  onChange={(e) => setNombre(e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Correo Institucional / Personal</label>
            <div className="input-wrapper">
              <span className="input-icon">✉️</span>
              <input
                type="email"
                required
                placeholder="operador@coe911.gob.ec"
                value={correo}
                onChange={(e) => setCorreo(e.target.value)}
                className="form-input"
              />
            </div>
          </div>

          <div className="form-group">
            <div className="form-label-row">
              <label className="form-label">Contraseña</label>
              {!esRegistro && (
                <span className="form-hint">Escenario 06:00 listo</span>
              )}
            </div>
            <div className="input-wrapper">
              <span className="input-icon">🔒</span>
              <input
                type={mostrarPassword ? 'text' : 'password'}
                required
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="form-input"
              />
              <button
                type="button"
                onClick={() => setMostrarPassword(!mostrarPassword)}
                className="toggle-password-btn"
                title={mostrarPassword ? 'Ocultar' : 'Mostrar'}
              >
                {mostrarPassword ? '👁️' : '👁️‍🗨️'}
              </button>
            </div>
          </div>

          {esRegistro && (
            <div className="form-group">
              <label className="form-label">Rol de Usuario</label>
              <select
                value={rolSeleccionado}
                onChange={(e) => setRolSeleccionado(e.target.value as RolUsuario)}
                className="form-input form-select"
              >
                <option value="ciudadano">Ciudadano (Reportes y consulta)</option>
                <option value="operador_911">Operador 911 (Despacho y verificación)</option>
                <option value="admin">Administrador (Control total)</option>
              </select>
            </div>
          )}

          <button type="submit" disabled={cargando} className="btn-submit-auth">
            {cargando ? (
              <span className="btn-loading">
                <span className="mini-spinner"></span> Conectando...
              </span>
            ) : esRegistro ? (
              'Crear Cuenta y Entrar →'
            ) : (
              'Ingresar al Panel de Mando →'
            )}
          </button>
        </form>

        {/* Pie de seguridad */}
        <div className="login-footer">
          <div className="seguridad-item">
            <span>🛡️</span> Cifrado seguro de extremo a extremo
          </div>
          <div className="seguridad-item">
            <span>⚡</span> Protocolo offline-first resiliente
          </div>
        </div>
      </div>
    </div>
  );
};

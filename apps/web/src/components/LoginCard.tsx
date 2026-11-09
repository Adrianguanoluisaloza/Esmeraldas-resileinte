import React, { useState, useEffect } from 'react';
import { ErrorApi, login as loginApi, registro as registroApi } from '../lib/api';
import { inicioSegunRol } from '../config/navegacion';
import {
  ArrowRight,
  Eye,
  EyeOff,
  LockKeyhole,
  Mail,
  ShieldCheck,
  UserRound,
  UsersRound,
  Zap,
} from 'lucide-react';
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
  const [correo, setCorreo] = useState(USUARIOS_DEMO.operador_911.correo);
  const [password, setPassword] = useState(USUARIOS_DEMO.operador_911.pass);
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
      let respuesta;
      try {
        // API real (POST /auth/login o /auth/registro). El rol lo decide el servidor, nunca el formulario.
        respuesta = esRegistro ? await registroApi(nombre, correo, password) : await loginApi(correo, password);
      } catch (e) {
        // Solo si el servidor no responde se usa la sesión de demostración local (modo sin backend).
        if (!(e instanceof ErrorApi) || e.codigo !== 'SIN_CONEXION') throw e;
        const demo = USUARIOS_DEMO[rolSeleccionado];
        if (esRegistro || demo.correo !== correo || demo.pass !== password) throw e;
        respuesta = { token: `demo-sin-servidor-${Date.now()}`, usuario: demo.usuario };
      }

      guardarSesion(respuesta);
      setSesionActiva(respuesta.usuario);

      // Vuelve a la página que pidió el login, o al inicio según el rol.
      const volver = new URLSearchParams(window.location.search).get('volver');
      const destino = volver && volver.startsWith('/') && !volver.startsWith('//') ? volver : inicioSegunRol(respuesta.usuario.rol);
      window.location.href = redirectUrl !== '/' ? redirectUrl : destino;
    } catch (err) {
      setError(err instanceof ErrorApi ? err.message : 'Error al autenticar. Verifica tus datos.');
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
            {sesionActiva.rol === 'operador_911' ? (
              <ShieldCheck aria-hidden="true" />
            ) : sesionActiva.rol === 'admin' ? (
              <Zap aria-hidden="true" />
            ) : (
              <UserRound aria-hidden="true" />
            )}
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
              Ir al Centro de Mando 911 <ArrowRight aria-hidden="true" />
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
              <ShieldCheck aria-hidden="true" /> Operador 911
            </button>
            <button
              type="button"
              onClick={() => seleccionarDemo('admin')}
              className={`demo-pill ${rolSeleccionado === 'admin' ? 'demo-pill-activo' : ''}`}
            >
              <Zap aria-hidden="true" /> Admin
            </button>
            <button
              type="button"
              onClick={() => seleccionarDemo('ciudadano')}
              className={`demo-pill ${rolSeleccionado === 'ciudadano' ? 'demo-pill-activo' : ''}`}
            >
              <UsersRound aria-hidden="true" /> Ciudadano
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
                <span className="input-icon"><UserRound aria-hidden="true" /></span>
                <input
                  type="text"
                  required
                  placeholder="Tu nombre completo"
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
              <span className="input-icon"><Mail aria-hidden="true" /></span>
              <input
                type="email"
                required
                placeholder="tu.correo@ejemplo.com"
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
              <span className="input-icon"><LockKeyhole aria-hidden="true" /></span>
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
                {mostrarPassword ? <EyeOff aria-hidden="true" /> : <Eye aria-hidden="true" />}
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
            <ShieldCheck aria-hidden="true" /> Cifrado seguro de extremo a extremo
          </div>
          <div className="seguridad-item">
            <Zap aria-hidden="true" /> Protocolo offline-first resiliente
          </div>
        </div>
      </div>
    </div>
  );
};


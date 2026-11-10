import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/security/permisos.dart';
import '../../../../core/security/validadores.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../operaciones/data/repositories/operaciones_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// ============================================================================
// Usuarios (solo admin) — Cero emojis (M4)
// ============================================================================
class UsuariosAdminPage extends StatefulWidget {
  const UsuariosAdminPage({
    super.key,
    required this.repo,
    required this.sesion,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;

  @override
  State<UsuariosAdminPage> createState() => _UsuariosAdminPageState();
}

class _UsuariosAdminPageState extends State<UsuariosAdminPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  RolUsuario _rol = RolUsuario.operador911;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _crear() {
    if (!_formKey.currentState!.validate()) return;
    try {
      widget.repo.crearUsuario(
        widget.sesion,
        _nombreCtrl.text,
        _correoCtrl.text,
        _rol,
      );
      _nombreCtrl.clear();
      _correoCtrl.clear();
      _passCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado (contraseña en hash).')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.colorSemaforoRojo,
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (BuildContext context, _) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Crear usuario (solo admin)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreCtrl,
                        validator: Validadores.nombre,
                        decoration: const InputDecoration(hintText: 'Nombre'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _correoCtrl,
                        validator: Validadores.correo,
                        decoration: const InputDecoration(hintText: 'Correo'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        validator: Validadores.passwordNueva,
                        decoration: const InputDecoration(
                          hintText: 'Contraseña temporal fuerte',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<RolUsuario>(
                        initialValue: _rol,
                        items: RolUsuario.values
                            .map(
                              (r) => DropdownMenuItem<RolUsuario>(
                                value: r,
                                child: Text(AppTheme.etiquetaRol(r)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _rol = v!),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: _crear,
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Crear usuario'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...widget.repo.usuarios.map((UsuarioGestion u) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(
                      u.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${u.correo} · ${AppTheme.etiquetaRol(u.rol)} · ${u.activo ? "activo" : "desactivado"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: u.id == widget.sesion.id
                        ? const Text(
                            'Sesión actual',
                            style: TextStyle(fontSize: 11),
                          )
                        : u.activo
                        ? OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(96, 36),
                              foregroundColor: AppTheme.colorSemaforoRojo,
                              side: const BorderSide(color: Color(0xFFF9D5D5)),
                            ),
                            onPressed: () =>
                                widget.repo.alternarUsuario(widget.sesion, u),
                            child: const Text(
                              'Desactivar',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          )
                        : FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(96, 36),
                            ),
                            onPressed: () =>
                                widget.repo.alternarUsuario(widget.sesion, u),
                            child: const Text(
                              'Activar',
                              style: TextStyle(fontSize: 11.5),
                            ),
                          ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Permisos, Auditoría y Cuenta (cero emojis)
// ============================================================================
class SeguridadCuentaPage extends StatelessWidget {
  const SeguridadCuentaPage({
    super.key,
    required this.repo,
    required this.sesion,
    required this.onCerrarSesion,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;
  final VoidCallback onCerrarSesion;

  static const List<(String, Permiso)> _filas = <(String, Permiso)>[
    ('Crear reporte y foto', Permiso.reporteCrear),
    ('Ver todos los reportes', Permiso.reporteVerTodos),
    ('Cambiar estado / verificar', Permiso.reporteCambiarEstado),
    ('Editar cupos de albergues', Permiso.puntosEditar),
    ('Crear puntos de servicio', Permiso.puntosTodo),
    ('Emitir alertas', Permiso.alertasCrear),
    ('Gestionar usuarios', Permiso.usuariosGestionar),
    ('Ver auditoría', Permiso.auditoriaVer),
  ];

  @override
  Widget build(BuildContext context) {
    final bool veAuditoria = sesion.rol.puede(Permiso.auditoriaVer);
    return ListenableBuilder(
      listenable: repo,
      builder: (BuildContext context, _) {
        return ListView(
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.colorRol(sesion.rol)
                      .withValues(alpha: 0.14),
                  child: Icon(
                    Icons.verified_user,
                    color: AppTheme.colorRol(sesion.rol),
                  ),
                ),
                title: Text(
                  sesion.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${sesion.correo}\n${AppTheme.etiquetaRol(sesion.rol)} · Proveedor: ${sesion.proveedor}',
                ),
                isThreeLine: true,
                trailing: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.colorSemaforoRojo,
                  ),
                  onPressed: onCerrarSesion,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Salir'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Matriz de permisos por rol',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2.4),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                      },
                      children: <TableRow>[
                        const TableRow(
                          children: <Widget>[
                            Text(
                              'Acción',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Ciu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '911',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Adm',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        ..._filas.map(
                          ((String, Permiso) f) => TableRow(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  f.$1,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                              for (final RolUsuario r in RolUsuario.values)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    r.puede(f.$2) ? 'Sí' : 'No',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: r.puede(f.$2)
                                          ? AppTheme.colorSemaforoVerde
                                          : AppTheme.colorTextoApagado,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!veAuditoria)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.lock_outline, size: 30),
                      const SizedBox(height: 4),
                      const Text(
                        'Zona restringida a Administradores',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Si tu rol intenta ejecutar una acción sin permiso, se rechaza con 403 y queda en auditoría.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.colorTextoSecundario,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          try {
                            repo.exigir(sesion, Permiso.usuariosGestionar);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.colorSemaforoRojo,
                                content: Text(e.toString()),
                              ),
                            );
                          }
                        },
                        child: const Text('Probar acción prohibida (403)'),
                      ),
                    ],
                  ),
                ),
              )
            else ...<Widget>[
              const Text(
                'Auditoría de seguridad (solo admin)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Card(
                child: Column(
                  children: repo.auditoria.isEmpty
                      ? const <Widget>[
                          Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Sin eventos registrados aún.'),
                          ),
                        ]
                      : repo.auditoria
                            .take(25)
                            .map(
                              (EventoAuditoria a) => ListTile(
                                dense: true,
                                title: Text(
                                  '${a.evento} · ${a.detalle}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: a.critico
                                        ? AppTheme.colorSemaforoRojo
                                        : AppTheme.colorTexto,
                                  ),
                                ),
                                subtitle: Text(
                                  '${a.hora.toIso8601String().substring(11, 19)} UTC · ${a.usuario}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                            .toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

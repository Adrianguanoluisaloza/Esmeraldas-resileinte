import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../operaciones/data/repositories/operaciones_repository.dart';
import 'admin_pages.dart';

/// Pestaña única del administrador: usuarios y roles, y auditoría con la cuenta.
/// Equivale a "Usuarios y roles" de la web y deja la barra inferior en 5 opciones.
class AdministracionPage extends StatelessWidget {
  const AdministracionPage({
    super.key,
    required this.repo,
    required this.sesion,
    required this.onCerrarSesion,
  });

  final OperacionesRepository repo;
  final UsuarioSesion sesion;
  final VoidCallback onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const Material(
            color: AppTheme.colorSuperficie,
            child: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.group_outlined), text: 'Usuarios y roles'),
                Tab(
                  icon: Icon(Icons.policy_outlined),
                  text: 'Auditoría y cuenta',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                UsuariosAdminPage(repo: repo, sesion: sesion),
                SeguridadCuentaPage(
                  repo: repo,
                  sesion: sesion,
                  onCerrarSesion: onCerrarSesion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

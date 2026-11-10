import 'package:flutter/material.dart';

import '../../../../core/services/telephony_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/autoproteccion_esmeraldas.dart';
import '../../domain/entities/autoproteccion.dart';

/// Cuenta del ciudadano: perfil, contactos de emergencia y guía de autoprotección.
class CuentaCiudadanoPage extends StatelessWidget {
  const CuentaCiudadanoPage({
    super.key,
    required this.sesion,
    required this.sinCuenta,
    required this.onCerrarSesion,
    this.telephony = const TelephonyService(),
    this.contactos = contactosEmergenciaEsmeraldas,
    this.pautas = pautasInundacionDeslizamiento,
  });

  final UsuarioSesion sesion;
  final bool sinCuenta;
  final VoidCallback onCerrarSesion;
  final TelephonyService telephony;
  final List<ContactoEmergencia> contactos;
  final List<PautaAutoproteccion> pautas;

  Future<void> _llamar(BuildContext context, String numero) async {
    final bool abierto = await telephony.abrirMarcadorEmergencia(
      numero: numero,
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marca $numero desde tu teléfono.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: <Widget>[
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.colorCampo,
              child: Icon(Icons.person_outline, color: AppTheme.colorPrimario),
            ),
            title: Text(
              sesion.nombre,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(sinCuenta ? 'Sin cuenta' : sesion.correo),
            trailing: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: sinCuenta
                    ? AppTheme.colorPrimario
                    : AppTheme.colorSemaforoRojo,
              ),
              onPressed: onCerrarSesion,
              icon: Icon(sinCuenta ? Icons.login : Icons.logout, size: 18),
              label: Text(sinCuenta ? 'Ingresar' : 'Salir'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Titulo(
          icono: Icons.phone_in_talk_outlined,
          texto: 'Números de emergencia',
        ),
        const SizedBox(height: 6),
        ...contactos.map(
          (ContactoEmergencia c) => _TarjetaContacto(
            contacto: c,
            onLlamar: (String n) => _llamar(context, n),
          ),
        ),
        const SizedBox(height: 14),
        const _Titulo(
          icono: Icons.health_and_safety_outlined,
          texto: 'Autoprotección ante inundaciones y deslizamientos',
        ),
        const SizedBox(height: 6),
        ...pautas.map((PautaAutoproteccion p) => _TarjetaPauta(pauta: p)),
        const SizedBox(height: 8),
        const Text(
          'Pautas generales de autoprotección. Sigue siempre las indicaciones de la Secretaría '
          'Nacional de Gestión de Riesgos y del COE cantonal.',
          style: TextStyle(fontSize: 11, color: AppTheme.colorTextoApagado),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icono, size: 18, color: AppTheme.colorPrimario),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _TarjetaContacto extends StatelessWidget {
  const _TarjetaContacto({required this.contacto, required this.onLlamar});

  final ContactoEmergencia contacto;
  final ValueChanged<String> onLlamar;

  @override
  Widget build(BuildContext context) {
    final ContactoEmergencia c = contacto;
    final Widget numeros = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: c.numeros.map((String n) {
        if (c.verificado) {
          return FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.colorEmergencia,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => onLlamar(n),
            icon: const Icon(Icons.call, size: 18),
            label: Text(
              'Llamar al $n',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }
        return Chip(
          avatar: const Icon(Icons.phone_outlined, size: 16),
          label: Text(n),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: c.verificado ? AppTheme.colorEmergencia : AppTheme.colorBorde,
          width: c.verificado ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    c.institucion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (!c.verificado)
                  const Text(
                    'Por confirmar',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorSemaforoAmbar,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              c.detalle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.colorTextoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            numeros,
          ],
        ),
      ),
    );
  }
}

class _TarjetaPauta extends StatelessWidget {
  const _TarjetaPauta({required this.pauta});

  final PautaAutoproteccion pauta;

  static (String, IconData) _cabecera(MomentoRiesgo m) => switch (m) {
    MomentoRiesgo.antes => ('Antes', Icons.backpack_outlined),
    MomentoRiesgo.durante => ('Durante', Icons.warning_amber_rounded),
    MomentoRiesgo.despues => ('Después', Icons.home_repair_service_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final (String titulo, IconData icono) = _cabecera(pauta.momento);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: pauta.momento == MomentoRiesgo.durante,
        leading: Icon(icono, color: AppTheme.colorPrimario),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: pauta.pasos
            .map(
              (String paso) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppTheme.colorTextoSecundario,
                      ),
                    ),
                    Expanded(
                      child: Text(paso, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

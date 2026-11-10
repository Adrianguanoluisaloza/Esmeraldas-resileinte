import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/enums/app_enums.dart';
import 'package:mobile/core/security/permisos.dart';

void main() {
  test('El servidor puede devolver los roles de cada instituciÃ³n', () {
    expect(RolUsuario.fromValor('bomberos'), RolUsuario.bomberos);
    expect(RolUsuario.fromValor('policia'), RolUsuario.policia);
  });

  test('Las instituciones atienden reportes pero no emiten alertas', () {
    for (final RolUsuario r in <RolUsuario>[
      RolUsuario.bomberos,
      RolUsuario.policia,
    ]) {
      expect(r.puede(Permiso.reporteCambiarEstado), isTrue);
      expect(r.puede(Permiso.reporteVerTodos), isFalse);
      expect(r.puede(Permiso.alertasCrear), isFalse);
      expect(r.puede(Permiso.usuariosGestionar), isFalse);
    }
  });

  test('Cada instituciÃ³n tiene su competencia', () {
    expect(
      competenciaInstitucion[RolUsuario.bomberos],
      contains(TipoIncidente.inundacion),
    );
    expect(
      competenciaInstitucion[RolUsuario.policia],
      isNot(contains(TipoIncidente.inundacion)),
    );
    expect(competenciaInstitucion[RolUsuario.ciudadano], isNull);
  });
}

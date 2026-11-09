/// Fallos tipados del dominio para manejo explícito de errores sin exponer excepciones de infraestructura.
sealed class Failure {
  const Failure(this.mensaje);
  final String mensaje;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.mensaje = 'Sin conexión a internet.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.mensaje = 'Error temporal del servidor. Se reintentará luego.',
  ]);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.mensaje = 'Sesión expirada. Inicie sesión nuevamente.',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.mensaje);
}

final class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure([
    super.mensaje = 'Permiso de ubicación denegado o GPS desactivado.',
  ]);
}

final class StorageFailure extends Failure {
  const StorageFailure([
    super.mensaje = 'Error al guardar en el almacenamiento local.',
  ]);
}

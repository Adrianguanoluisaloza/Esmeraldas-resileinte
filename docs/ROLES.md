# Roles y permisos

El servidor aplica estas reglas en cada petición. Ocultar un botón en la web no es seguridad.

| Permiso | Ciudadano | ECU 911 (`operador_911`) | Bomberos | Policía | Administrador |
|---|---|---|---|---|---|
| Crear reportes | Sí | Sí | Sí | Sí | Sí |
| Ver reportes | Los suyos | Todos | Inundación, deslizamiento, personas atrapadas, daño de vivienda | Vía bloqueada, personas atrapadas | Todos |
| Cambiar estado de reportes | No | Todos | Los que ve | Los que ve | Todos |
| Mapa operativo | No | Sí | Sí | Sí | Sí |
| Emitir y cerrar alertas | No | Sí | No | No | Sí |
| Cambiar estado de vías | No | Sí | No | Sí | Sí |
| Registrar albergues y ajustar ocupación | No | Sí | No | No | Sí |
| Asistencia e inventario | No | Sí | No | No | Sí |
| Estadísticas | No | Sí | No | No | Sí |
| Asignar roles | No | No | No | No | Sí |

La competencia de cada institución está en `COMPETENCIA_INSTITUCION` (`apps/api/src/dominio/catalogos.ts`).
Los reportes de tipo "otro" los gestiona el ECU 911. Un cambio de rol se aplica cuando la persona vuelve a ingresar.

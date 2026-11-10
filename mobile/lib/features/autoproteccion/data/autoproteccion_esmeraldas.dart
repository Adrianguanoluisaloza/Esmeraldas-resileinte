import '../domain/entities/autoproteccion.dart';

/// Contactos de emergencia de Esmeraldas.
///
/// 911 es la línea única oficial de Ecuador (Decreto Ejecutivo 988 de 2011, ECU 911).
/// Los demás números se dejan "por confirmar" hasta verificarlos con cada institución.
const List<ContactoEmergencia> contactosEmergenciaEsmeraldas =
    <ContactoEmergencia>[
      ContactoEmergencia(
        institucion: 'ECU 911',
        numeros: <String>['911'],
        detalle: 'Línea única para toda emergencia. Coordina Bomberos, Policía, ambulancias y gestión de riesgos.',
        verificado: true,
      ),
      ContactoEmergencia(
        institucion: 'Cuerpo de Bomberos de Esmeraldas',
        numeros: <String>['102', '(06) 272-2101'],
        detalle: 'Incendios, rescates e inundaciones.',
        verificado: false,
      ),
      ContactoEmergencia(
        institucion: 'Policía Nacional (Subzona Esmeraldas)',
        numeros: <String>['101'],
        detalle: 'Seguridad y vías bloqueadas.',
        verificado: false,
      ),
      ContactoEmergencia(
        institucion: 'Cruz Roja Ecuatoriana (Junta Esmeraldas)',
        numeros: <String>['(06) 272-0648'],
        detalle: 'Primeros auxilios y apoyo a familias.',
        verificado: false,
      ),
    ];

/// Pautas generales de autoprotección ante inundaciones y deslizamientos.
const List<PautaAutoproteccion>
pautasInundacionDeslizamiento = <PautaAutoproteccion>[
  PautaAutoproteccion(
    momento: MomentoRiesgo.antes,
    pasos: <String>[
      'Identifica el albergue más cercano y la ruta para llegar (pestaña Albergues).',
      'Prepara una mochila de emergencia: agua, alimentos no perecibles, linterna, radio, botiquín, documentos en funda plástica y cargador.',
      'Acuerda con tu familia un punto de encuentro.',
    ],
  ),
  PautaAutoproteccion(
    momento: MomentoRiesgo.durante,
    pasos: <String>[
      'Desconecta los breakers y la llave de gas si es seguro hacerlo.',
      'No cruces calles anegadas ni ríos crecidos, ni a pie ni en vehículo.',
      'Aléjate de laderas, taludes y orillas del Esmeraldas y el Teaone.',
      'Si estás en peligro, llama al 911 o reporta desde esta app.',
    ],
  ),
  PautaAutoproteccion(
    momento: MomentoRiesgo.despues,
    pasos: <String>[
      'Espera que las autoridades confirmen que es seguro volver.',
      'Revisa daños en paredes, techo e instalación eléctrica antes de entrar.',
      'No consumas agua ni alimentos que estuvieron en contacto con la inundación.',
    ],
  ),
];

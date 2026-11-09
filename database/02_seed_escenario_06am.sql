-- Escenario oficial de simulación del reto: "Jueves, 06:00 AM".
-- TODOS los datos de este archivo son SIMULADOS (origen = 'simulado'). Polígonos, vías y cifras son
-- aproximaciones didácticas, no información oficial de SNGR, INAMHI ni GAD. Los teléfonos se dejan vacíos
-- a propósito para no publicar números inventados.
-- La misma semilla existe en apps/api/src/infraestructura/memoria/semilla.ts para el modo sin base.

-- Zonas de riesgo (polígonos aproximados) --------------------------------------------------------
INSERT INTO zonas_riesgo (id, nombre_sector, tipo_amenaza, nivel_riesgo, origen, fuente, geom) VALUES
('a1000000-0000-4000-8000-000000000001', 'Isla Piedad', 'inundacion', 'critico', 'simulado', 'Escenario hackathon',
  ST_GeomFromText('POLYGON((-79.6620 0.9735, -79.6545 0.9735, -79.6545 0.9800, -79.6620 0.9800, -79.6620 0.9735))', 4326)),
('a1000000-0000-4000-8000-000000000002', 'Barrio 20 de Noviembre', 'inundacion', 'alto', 'simulado', 'Escenario hackathon',
  ST_GeomFromText('POLYGON((-79.6730 0.9515, -79.6660 0.9515, -79.6660 0.9580, -79.6730 0.9580, -79.6730 0.9515))', 4326)),
('a1000000-0000-4000-8000-000000000003', 'Barrio Caliente (zona alta)', 'deslizamiento', 'alto', 'simulado', 'Escenario hackathon',
  ST_GeomFromText('POLYGON((-79.6650 0.9590, -79.6585 0.9590, -79.6585 0.9650, -79.6650 0.9650, -79.6650 0.9590))', 4326)),
('a1000000-0000-4000-8000-000000000004', 'Ribera del río Teaone (Tabiazo)', 'desbordamiento', 'critico', 'simulado', 'Escenario hackathon',
  ST_GeomFromText('POLYGON((-79.6400 0.9050, -79.6250 0.9050, -79.6250 0.9200, -79.6400 0.9200, -79.6400 0.9050))', 4326)),
('a1000000-0000-4000-8000-000000000005', 'El Arenal', 'inundacion', 'medio', 'simulado', 'Escenario hackathon',
  ST_GeomFromText('POLYGON((-79.6520 0.9670, -79.6460 0.9670, -79.6460 0.9725, -79.6520 0.9725, -79.6520 0.9670))', 4326));

-- Vías (líneas aproximadas) -----------------------------------------------------------------------
INSERT INTO vias (id, nombre, estado, origen, geom) VALUES
('a2000000-0000-4000-8000-000000000001', 'Acceso Puente Tachina', 'bloqueada', 'simulado',
  ST_GeomFromText('LINESTRING(-79.6450 0.9760, -79.6385 0.9824, -79.6320 0.9880)', 4326)),
('a2000000-0000-4000-8000-000000000002', 'Vía Esmeraldas - Tabiazo', 'parcial', 'simulado',
  ST_GeomFromText('LINESTRING(-79.6550 0.9450, -79.6450 0.9300, -79.6330 0.9120)', 4326)),
('a2000000-0000-4000-8000-000000000003', 'Av. Jaime Roldós (eje sur)', 'habilitada', 'simulado',
  ST_GeomFromText('LINESTRING(-79.6540 0.9700, -79.6600 0.9600, -79.6720 0.9520)', 4326)),
('a2000000-0000-4000-8000-000000000004', 'Malecón - Av. Kennedy', 'habilitada', 'simulado',
  ST_GeomFromText('LINESTRING(-79.6530 0.9640, -79.6490 0.9780, -79.6455 0.9902)', 4326));

-- Albergues y centros de salud --------------------------------------------------------------------
-- Evento 5 del escenario: el albergue UTLVTE está cerca del límite (112 de 120).
INSERT INTO puntos_servicio (id, nombre, tipo, telefono, direccion, capacidad, ocupacion, activo, geom) VALUES
('a3000000-0000-4000-8000-000000000001', 'Albergue temporal UTLVTE', 'albergue', '', 'Campus universitario', 120, 112, true,
  ST_SetSRID(ST_MakePoint(-79.6732, 0.9515), 4326)),
('a3000000-0000-4000-8000-000000000002', 'Coliseo Nubia Villacís', 'albergue', '', 'Centro de la ciudad', 200, 70, true,
  ST_SetSRID(ST_MakePoint(-79.6542, 0.9635), 4326)),
('a3000000-0000-4000-8000-000000000003', 'Unidad educativa Las Palmas', 'albergue', '', 'Las Palmas', 90, 20, true,
  ST_SetSRID(ST_MakePoint(-79.6470, 0.9880), 4326)),
('a3000000-0000-4000-8000-000000000004', 'Hospital Delfina Torres de Concha', 'centro_salud', '', 'Sector San Rafael', 150, 138, true,
  ST_SetSRID(ST_MakePoint(-79.6812, 0.9428), 4326)),
('a3000000-0000-4000-8000-000000000005', 'Centro de salud Las Palmas', 'centro_salud', '', 'Las Palmas', 40, 22, true,
  ST_SetSRID(ST_MakePoint(-79.6455, 0.9902), 4326));

-- Los 6 eventos del escenario como reportes simulados ----------------------------------------------
INSERT INTO reportes (id, usuario_id, origen, tipo, descripcion, gravedad, estado, geom, precision_m, sector,
  capturado_en, recibido_en, verificado, personas_afectadas, ninos, adultos_mayores, necesidades) VALUES
('a4000000-0000-4000-8000-000000000001', NULL, 'simulado', 'inundacion',
  'Evento 1. Acumulación de agua en calles y viviendas de barrios ribereños.', 'critica', 'pendiente',
  ST_SetSRID(ST_MakePoint(-79.6582, 0.9765), 4326), 6, 'Isla Piedad',
  '2026-11-12T11:00:00Z', '2026-11-12T11:02:00Z', false, 35, 12, 5, ARRAY['rescate', 'agua']),
('a4000000-0000-4000-8000-000000000002', NULL, 'simulado', 'inundacion',
  'Evento 2. Desbordamiento del río en comunidad rural con señal limitada.', 'critica', 'pendiente',
  ST_SetSRID(ST_MakePoint(-79.6320, 0.9120), 4326), 25, 'Ribera del río Teaone (Tabiazo)',
  '2026-11-12T10:55:00Z', '2026-11-12T11:20:00Z', false, 60, 20, 9, ARRAY['rescate', 'alimentos', 'agua']),
('a4000000-0000-4000-8000-000000000003', NULL, 'simulado', 'via_bloqueada',
  'Evento 3. Deslizamiento interrumpe la vía. Se requiere ruta alterna.', 'alta', 'en_proceso',
  ST_SetSRID(ST_MakePoint(-79.6385, 0.9824), 4326), 12, NULL,
  '2026-11-12T11:01:00Z', '2026-11-12T11:05:00Z', true, 0, 0, 0, ARRAY[]::TEXT[]),
('a4000000-0000-4000-8000-000000000004', NULL, 'simulado', 'personas_atrapadas',
  'Evento 4. Familias atrapadas en planta alta, piden evacuación.', 'critica', 'pendiente',
  ST_SetSRID(ST_MakePoint(-79.6695, 0.9548), 4326), 5, 'Barrio 20 de Noviembre',
  '2026-11-12T11:04:00Z', '2026-11-12T11:06:00Z', false, 14, 6, 3, ARRAY['rescate', 'medicinas']),
('a4000000-0000-4000-8000-000000000005', NULL, 'simulado', 'otro',
  'Evento 5. Albergue temporal UTLVTE cerca del límite de capacidad.', 'alta', 'en_proceso',
  ST_SetSRID(ST_MakePoint(-79.6732, 0.9515), 4326), 4, 'Barrio 20 de Noviembre',
  '2026-11-12T11:08:00Z', '2026-11-12T11:08:00Z', true, 112, 40, 15, ARRAY['alimentos', 'agua']),
('a4000000-0000-4000-8000-000000000006', NULL, 'simulado', 'otro',
  'Evento 6. Solicitud urgente de agua potable, alimentos y medicamentos.', 'alta', 'pendiente',
  ST_SetSRID(ST_MakePoint(-79.6490, 0.9700), 4326), 10, 'El Arenal',
  '2026-11-12T11:10:00Z', '2026-11-12T11:11:00Z', false, 22, 8, 4, ARRAY['agua', 'alimentos', 'medicinas']);

-- Alerta del escenario (simulada: el sistema no reemplaza los canales oficiales) -------------------
INSERT INTO alertas (id, sector, mensaje, nivel, origen) VALUES
('a5000000-0000-4000-8000-000000000001', 'Ribera del río Teaone (Tabiazo)',
  'Simulacro: crecida del río. Dirigirse a zonas altas y seguir indicaciones de las autoridades.', 'critica', 'simulada');

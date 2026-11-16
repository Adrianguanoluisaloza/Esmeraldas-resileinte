-- Semilla de ejemplo (datos minimos ilustrativos; reemplazar con capas y registros reales en despliegue).

INSERT INTO zonas_riesgo (id, nombre_sector, tipo_amenaza, nivel_riesgo, origen, fuente, geom) VALUES
('a1000000-0000-4000-8000-000000000001', 'Sector Ejemplo', 'inundacion', 'alto', 'simulado', 'Ejemplo',
  ST_GeomFromText('POLYGON((-79.660 0.970, -79.655 0.970, -79.655 0.975, -79.660 0.975, -79.660 0.970))', 4326));

INSERT INTO vias (id, nombre, estado, origen, geom) VALUES
('a2000000-0000-4000-8000-000000000001', 'Via Ejemplo', 'habilitada', 'simulado',
  ST_GeomFromText('LINESTRING(-79.655 0.975, -79.650 0.980)', 4326));

INSERT INTO puntos_servicio (id, nombre, tipo, telefono, direccion, capacidad, ocupacion, activo, geom) VALUES
('a3000000-0000-4000-8000-000000000001', 'Albergue Ejemplo', 'albergue', '', 'Direccion de ejemplo', 100, 10, true,
  ST_SetSRID(ST_MakePoint(-79.656, 0.972), 4326));

INSERT INTO reportes (id, usuario_id, origen, tipo, descripcion, gravedad, estado, geom, precision_m, sector,
  capturado_en, recibido_en, verificado, personas_afectadas, ninos, adultos_mayores, necesidades) VALUES
('a4000000-0000-4000-8000-000000000001', NULL, 'simulado', 'inundacion',
  'Reporte de ejemplo para validar esquema PostGIS.', 'media', 'pendiente',
  ST_SetSRID(ST_MakePoint(-79.658, 0.973), 4326), 10, 'Sector Ejemplo',
  '2026-11-12T11:00:00Z', '2026-11-12T11:02:00Z', false, 5, 1, 1, ARRAY['agua']);

INSERT INTO alertas (id, sector, mensaje, nivel, origen, vigente) VALUES
('a5000000-0000-4000-8000-000000000001', 'Sector Ejemplo',
  'Simulacro: mensaje de ejemplo.', 'media', 'simulada', true);

INSERT INTO inventario (necesidad, cantidad, unidad) VALUES
('agua', 100, 'unidades'),
('alimentos', 50, 'kits'),
('medicinas', 25, 'botiquines');

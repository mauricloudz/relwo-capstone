-- =====================================================================
-- RELWO - Datos de catalogo (semillas reales, no cuentas de prueba)
-- Tablas: vertical, modalidad, vertical_modalidad, tipo_ambiente,
--         tipo_problema, checklist_oficio_item, categoria_disputa,
--         regla_precio, parametro_operacion y comuna (40 comunas del
--         Gran Santiago, sin geometria).
-- Uso:    psql -U relwo -d relwo -f 03_datos_catalogo.sql
--         (ejecutar despues de 01_crear_tablas.sql y 02_usuarios_y_permisos.sql)
-- =====================================================================

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: categoria_disputa; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categoria_disputa (codigo, nombre, exige_evidencia, orden, activa) VALUES ('trabajo_incompleto', 'Trabajo incompleto', false, 1, true);
INSERT INTO public.categoria_disputa (codigo, nombre, exige_evidencia, orden, activa) VALUES ('dano_material', 'Daño material', true, 2, true);
INSERT INTO public.categoria_disputa (codigo, nombre, exige_evidencia, orden, activa) VALUES ('comportamiento', 'Comportamiento', false, 3, true);
INSERT INTO public.categoria_disputa (codigo, nombre, exige_evidencia, orden, activa) VALUES ('otro', 'Otro', false, 4, true);


--
-- Data for Name: vertical; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (1, 'limpieza', 'Limpieza del hogar', 'activo', true, 1, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Profesional de limpieza', NULL, '{}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (3, 'cerrajeria', 'Cerrajería', 'activo', true, 3, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Cerrajero', NULL, '{}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (5, 'jardineria', 'Jardinería', 'proximamente', true, 5, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Jardinero', NULL, '{}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (8, 'baby_sitter', 'Baby Sitter', 'proximamente', true, 6, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Baby sitter', NULL, '{}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (9, 'profesor_particular', 'Profesor particular', 'proximamente', true, 7, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Profesor particular', NULL, '{}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (2, 'gasfiteria', 'Gasfitería', 'activo', true, 2, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Gasfíter', 'gas', '{1,2,3}');
INSERT INTO public.vertical (id, codigo, nombre, estado, activable, orden, creado_en, tarifa_minima, tarifa_maxima, oficio, sec_ambito, sec_clases_aceptadas) VALUES (4, 'electricidad', 'Electricidad', 'proximamente', true, 4, '2026-10-17 01:46:41.98411-03', NULL, NULL, 'Electricista', 'electrico', '{}');


--
-- Data for Name: checklist_oficio_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (1, 1, 1, 'Trabajo finalizado', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (2, 1, 2, 'Zona de trabajo limpia', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (3, 1, 3, 'Materiales sobrantes retirados', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (4, 2, 1, 'Trabajo finalizado', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (5, 2, 2, 'Zona de trabajo limpia', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (6, 2, 3, 'Materiales sobrantes retirados', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (7, 3, 1, 'Trabajo finalizado', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (8, 3, 2, 'Zona de trabajo limpia', true);
INSERT INTO public.checklist_oficio_item (id, vertical_id, orden, texto, activo) VALUES (9, 3, 3, 'Materiales sobrantes retirados', true);


--
-- Data for Name: comuna; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (1, '13101', 'Santiago', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, true, false, NULL, '2026-10-17 01:47:39.376655-03', NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (2, '13102', 'Cerrillos', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (3, '13103', 'Cerro Navia', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (4, '13104', 'Conchalí', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (5, '13105', 'El Bosque', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (6, '13106', 'Estación Central', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (7, '13107', 'Huechuraba', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (8, '13108', 'Independencia', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (9, '13109', 'La Cisterna', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (10, '13110', 'La Florida', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (11, '13111', 'La Granja', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (12, '13112', 'La Pintana', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (13, '13113', 'La Reina', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (14, '13114', 'Las Condes', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, true, false, NULL, '2026-10-17 01:47:39.376655-03', NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (15, '13115', 'Lo Barnechea', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (16, '13116', 'Lo Espejo', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (17, '13117', 'Lo Prado', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (18, '13118', 'Macul', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (19, '13119', 'Maipú', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (20, '13120', 'Ñuñoa', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, true, false, NULL, '2026-10-17 01:47:39.376655-03', NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (21, '13121', 'Pedro Aguirre Cerda', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (22, '13122', 'Peñalolén', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (23, '13123', 'Providencia', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (24, '13124', 'Pudahuel', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (25, '13125', 'Quilicura', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (26, '13126', 'Quinta Normal', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (27, '13127', 'Recoleta', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (28, '13128', 'Renca', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (29, '13129', 'San Joaquín', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (30, '13130', 'San Miguel', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (31, '13131', 'San Ramón', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (32, '13132', 'Vitacura', NULL, 'Santiago', 'Metropolitana de Santiago', NULL, true, true, false, NULL, '2026-10-17 01:47:39.376655-03', NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (33, '13201', 'Puente Alto', NULL, 'Cordillera', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (34, '13301', 'Colina', NULL, 'Chacabuco', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (35, '13302', 'Lampa', NULL, 'Chacabuco', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (36, '13401', 'San Bernardo', NULL, 'Maipo', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (37, '13403', 'Calera de Tango', NULL, 'Maipo', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (38, '13601', 'Talagante', NULL, 'Talagante', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (39, '13604', 'Padre Hurtado', NULL, 'Talagante', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');
INSERT INTO public.comuna (id, codigo_cut, nombre, nombre_oficial, provincia, region, geom, visible, operativa, desactivada_manual, umbral_activacion, activada_en, fuente, creado_en) VALUES (40, '13605', 'Peñaflor', NULL, 'Talagante', 'Metropolitana de Santiago', NULL, true, false, false, NULL, NULL, NULL, '2026-10-17 01:47:39.376655-03');


--
-- Data for Name: modalidad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.modalidad (id, codigo, nombre, orden, activa, creado_en) VALUES (1, 'programado', 'Hora fija', 1, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.modalidad (id, codigo, nombre, orden, activa, creado_en) VALUES (2, 'urgente', 'Ahora', 2, true, '2026-10-17 01:46:41.98411-03');


--
-- Data for Name: parametro_operacion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_limpieza', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Limpieza del hogar (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_electricidad', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Electricidad (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_gasfiteria', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Gasfitería (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_cerrajeria', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Cerrajería (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_jardineria', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Jardinería (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('auto_aprobacion_cuentas', 'false', 'Aprueba de inmediato toda solicitud de registro nueva, sin pasar por la bandeja de administración. Es un interruptor de pruebas del MVP para demostrar el flujo de punta a punta sin aprobar cuentas a mano: en producción el servidor rechaza encenderlo (D-15).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('plazo_publicacion_minutos_programado', '2880', 'Minutos que permanece abierta la publicación de una solicitud programada antes de cerrar por plazo (RF-144).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('plazo_publicacion_minutos_urgente', '30', 'Minutos que permanece abierta la publicación de una solicitud urgente antes de cerrar por plazo (RF-144).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('rondas_maximas_publicacion', '3', 'Cuántas rondas de publicación se intentan antes de dejar la solicitud para asignación manual (D-63, RF-136).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('plazo_eleccion_minutos', '1440', 'Minutos que conserva el cliente para elegir entre las ofertas recibidas después de que la publicación cierra por plazo (D-64, RF-144).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('umbral_revision_registro_horas', NULL, 'Horas de antigüedad de una solicitud de registro a partir de las cuales la bandeja alerta que lleva demasiado sin revisarse (D-26). Vacío: sin alerta.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('umbral_comunas_activacion', NULL, 'Cuántos maestros con cobertura necesita una comuna para activarse por omisión, cuando no tiene un umbral propio (Tarea 3.5). Vacío: ninguna comuna se activa sola.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_aumento_cotizacion_pct', NULL, 'Porcentaje máximo en que la cotización en terreno puede superar el valor estimado de la oferta elegida (D-39). Vacío: sin tope.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('limite_gastos_imprevistos_por_servicio', NULL, 'Cuántos gastos imprevistos puede proponer el maestro en un mismo servicio (D-40). Vacío: sin límite.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('vigencia_aprobacion_terreno_minutos', NULL, 'Minutos que tiene el cliente para responder a una aprobación en terreno antes de que venza con efecto de rechazo tácito (D-42). Vacío: no vence.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('referencia_precio_ventana_dias', NULL, 'Días hacia atrás que abarca la ventana móvil con la que se calcula la referencia de precio que ve el cliente (D-65). Vacío: no se calcula.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('referencia_precio_muestra_minima', NULL, 'Cuántos servicios completados necesita una combinación de oficio, modalidad y comuna para que su referencia de precio se muestre (D-65). Vacío: no se muestra.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('evaluaciones_doble_ciego_dias', NULL, 'Días tras el cierre en que una evaluación se publica aunque la otra parte no haya evaluado (D-67). Vacío: se publica solo cuando existen las dos.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('bloqueo_umbral_incumplimientos', '3', 'Incumplimientos dentro de la ventana de observación a partir de los cuales se aplica un bloqueo temporal (D-66, adenda §19.4).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('bloqueo_ventana_dias', '90', 'Días de la ventana de observación en que se cuentan los incumplimientos (D-66, adenda §19.4).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('bloqueo_primero_dias', '7', 'Duración en días del primer bloqueo temporal (D-66, adenda §19.4).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('bloqueo_segundo_dias', '30', 'Duración en días del segundo bloqueo, por reincidencia dentro de la ventana (D-66, adenda §19.4).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('bloqueo_definitivo_reincidencias', '3', 'Reincidencias en doce meses a partir de las cuales el bloqueo pasa a definitivo, siempre con revisión humana (D-66, adenda §19.4).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('cobro_cancelacion_acuerdo_externo_pesos', NULL, 'Pesos que se cobran a quien cancela cuando se confirma un acuerdo fuera de la plataforma (adenda §19.4). Vacío: sin cobro.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('comprobante_gasto_obligatorio', 'false', 'Si el maestro debe adjuntar la fotografía de la boleta o factura para declarar un gasto imprevisto (D-82). Apagado, la fotografía es recomendada y el gasto se puede declarar sin ella.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_descartes_cliente', NULL, 'Cuántas ofertas puede descartar el cliente en una misma solicitud, contando todas las rondas, antes de que la publicación cierre y la solicitud escale a asignación manual (D-47, D-85). Vacío: sin tope, descartar no cierra nada.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('ia_presupuesto_mensual_llamadas', NULL, 'Cuántas consultas al modelo de inteligencia artificial se admiten en el mes calendario, sumando todas las cuentas y propósitos (D-86). Vacío: el agente está apagado y responde solo lo que no necesita modelo.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('ia_tope_diario_por_usuario', NULL, 'Cuántas consultas al modelo de inteligencia artificial puede hacer una misma cuenta en un día (D-86). Vacío: el agente está apagado.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tolerancia_total_comprobante_porcentaje', NULL, 'Porcentaje de diferencia admitido entre el total leído en la boleta o factura y el monto que el maestro declaró (D-80). Vacío: todo comprobante queda en revisión manual.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('ventana_fecha_comprobante_horas', NULL, 'Horas hacia atrás desde que se declaró el gasto dentro de las cuales tiene que estar la fecha de la boleta o factura (D-80). Vacío: todo comprobante queda en revisión manual.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('radio_llegada_metros', NULL, 'Metros de tolerancia entre la posición del maestro al pulsar «Llegué» y el domicilio (RF-147, D-31, D-43). Vacío: falla segura (D-56); la llegada responde 409 en vez de aceptarse sin comprobar la distancia, y el cliente puede confirmarla a mano.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('evidencia_termino_obligatoria', 'false', 'Si el maestro debe adjuntar al menos una fotografía de evidencia del trabajo terminado para declarar el término (RF-142). Apagado, la fotografía es recomendada y el término se puede declarar sin ella.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_baby_sitter', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Baby Sitter (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('tope_tarifa_visita_pesos_profesor_particular', '20000', 'Tope en pesos de la tarifa de visita que un maestro puede declarar en una oferta del oficio Profesor particular (D-69, RF-160).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('plazo_disputa_tras_cierre_dias', '7', 'Días después de que un servicio queda completado en que el cliente todavía puede abrir una disputa (D-108).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('sla_disputa_horas_habiles', '48', 'Horas hábiles —de lunes a viernes— que la torre de control se compromete a tardar en resolver una disputa desde su apertura (D-108).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('sec_reverificacion_dias', '30', 'Cada cuántos días el servidor vuelve a consultar en la SEC la licencia de oficio de cada maestro verificado (D-110).', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('sec_consultas_diarias_por_cuenta', '3', 'Cuántas veces puede una cuenta pedir, en 24 horas, que se consulte su licencia de oficio en la SEC. La reverificación programada no cuenta.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('antelacion_minima_programado_minutos', '120', 'Minutos de anticipación mínima entre la creación de una solicitud programada y el inicio de su ventana horaria. Vacío: sin mínimo, aunque el inicio no puede estar en el pasado.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('mensajes_por_minuto_por_cuenta', '20', 'Cuántos mensajes puede enviar una misma cuenta en un minuto, sumando todas sus conversaciones con la otra parte de un servicio (RF-153). Vacío: sin límite.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('minutos_antes_en_camino', '60', 'Minutos antes del inicio agendado de un servicio programado desde los que el maestro puede declarar «Voy en camino». Vacío: sin ventana. Las urgentes no la usan.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('hora_inicio_minima_programado', '8', 'Primera hora del día, en hora de Chile, a la que puede empezar un servicio programado (0 a 23). Vacío: sin límite por la mañana.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('hora_inicio_maxima_programado', '20', 'Última hora del día, en hora de Chile, a la que puede empezar un servicio programado (0 a 23), inclusiva en punto: con 20, las 20:00 sí y las 20:15 no. Vacío: sin límite por la noche.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('propuestas_cambio_hora_por_dia', '2', 'Cuántas propuestas de cambio de hora puede hacer el cliente de un mismo servicio en 24 horas. Vacío: sin límite.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('consultas_adelanto_por_dia', '1', 'Cuántas consultas «¿Puedo ir ahora?» puede hacer el maestro en un mismo servicio en 24 horas. Vacío: sin límite.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('ancho_rango_llegada_minutos', '20', 'Cuántos minutos dura el rango de hora de llegada que se muestra al cliente mientras el maestro va en camino (por ejemplo, entre 19:15 y 19:35). Vacío: no hay rango.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('velocidad_promedio_en_camino_kmh', '20', 'Velocidad promedio, en kilómetros por hora, con que se arma el rango de hora de llegada del maestro cuando no hay ruta por calles: distancia en línea recta al domicilio dividida por esta cifra. Vacío: sin ruta no hay rango de llegada.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('rutas_en_camino_por_servicio', '4', 'Cuántos cálculos de ruta por calles se piden a Google como máximo por servicio mientras el maestro va en camino —el primero, los de un atraso y los de un desvío—, incluidos los fallidos. Vacío: no se piden rutas.', NULL, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.parametro_operacion (clave, valor, descripcion, actualizado_por, actualizado_en) VALUES ('desvio_ruta_en_camino_metros', '200', 'A cuántos metros de la ruta guardada tiene que quedar la posición del maestro en camino para que se pida una ruta nueva, si pasaron al menos 60 segundos desde el último cálculo y queda cupo en el tope de rutas por servicio. La ruta guardada nunca se oculta. Vacío: no se recalcula por desvío.', NULL, '2026-10-17 01:46:41.98411-03');


--
-- Data for Name: regla_precio; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.regla_precio (id, vertical_id, comuna_id, modalidad_id, version, vigencia_desde, vigencia_hasta, moneda, parametros, pct_comision_cliente, pct_comision_prestador, cobro_cliente_habilitado, cobro_prestador_habilitado, creado_en) VALUES (1, NULL, NULL, 1, 1, '2026-10-17 01:46:41.98411-03', NULL, 'CLP', '{}', 7.50, 7.50, true, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.regla_precio (id, vertical_id, comuna_id, modalidad_id, version, vigencia_desde, vigencia_hasta, moneda, parametros, pct_comision_cliente, pct_comision_prestador, cobro_cliente_habilitado, cobro_prestador_habilitado, creado_en) VALUES (2, NULL, NULL, 2, 1, '2026-10-17 01:46:41.98411-03', NULL, 'CLP', '{}', 11.00, 7.50, true, true, '2026-10-17 01:46:41.98411-03');


--
-- Data for Name: tipo_ambiente; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipo_ambiente (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (1, 1, 'cocina', 'Cocina', 4, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_ambiente (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (2, 1, 'living', 'Living o comedor', 3, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_ambiente (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (3, 1, 'banos', 'Baños', 2, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_ambiente (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (4, 1, 'dormitorios', 'Dormitorios', 1, true, '2026-10-17 01:46:41.98411-03');


--
-- Data for Name: tipo_problema; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (1, 3, 'llave_quebrada', 'Llave quebrada', 3, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (2, 3, 'cambio_de_cerradura', 'Cambio de cerradura', 2, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (3, 3, 'fuera_de_casa', 'Quedé fuera de casa', 1, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (4, 2, 'otro', 'Otro', 5, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (5, 2, 'calefont', 'Calefont', 4, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (6, 2, 'wc', 'WC', 3, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (7, 2, 'griferia', 'Grifería', 2, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (8, 2, 'filtracion', 'Filtración', 1, true, '2026-10-17 01:46:41.98411-03');
INSERT INTO public.tipo_problema (id, vertical_id, codigo, nombre, orden, activo, creado_en) VALUES (9, 3, 'otro', 'Otro', 4, true, '2026-10-17 01:46:41.98411-03');


--
-- Data for Name: vertical_modalidad; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vertical_modalidad (vertical_id, modalidad_id, activa) VALUES (1, 1, true);
INSERT INTO public.vertical_modalidad (vertical_id, modalidad_id, activa) VALUES (2, 1, true);
INSERT INTO public.vertical_modalidad (vertical_id, modalidad_id, activa) VALUES (3, 1, true);
INSERT INTO public.vertical_modalidad (vertical_id, modalidad_id, activa) VALUES (2, 2, true);
INSERT INTO public.vertical_modalidad (vertical_id, modalidad_id, activa) VALUES (3, 2, true);


--
-- Name: checklist_oficio_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.checklist_oficio_item_id_seq', 9, true);


--
-- Name: comuna_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comuna_id_seq', 40, true);


--
-- Name: modalidad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.modalidad_id_seq', 2, true);


--
-- Name: regla_precio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.regla_precio_id_seq', 2, true);


--
-- Name: tipo_ambiente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_ambiente_id_seq', 4, true);


--
-- Name: tipo_problema_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_problema_id_seq', 9, true);


--
-- Name: vertical_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vertical_id_seq', 9, true);


--
-- PostgreSQL database dump complete
--



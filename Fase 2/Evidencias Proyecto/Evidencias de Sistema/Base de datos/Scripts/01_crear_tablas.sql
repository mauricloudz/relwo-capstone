-- =====================================================================
-- RELWO - Script de creacion de tablas (DDL)
-- Motor: PostgreSQL 17 con PostGIS
-- Contenido: 55 tablas, tipo enumerado estado_servicio, llaves primarias,
--            foraneas, restricciones CHECK y UNIQUE, indices, funciones y
--            disparadores (incluido el registro de auditoria de solo escritura).
-- Origen: generado con pg_dump --schema-only sobre una base creada desde cero
--         con las 69 migraciones del servidor,
--         estado al cierre del Sprint 7 (17-10-2026).
-- Uso:    psql -U relwo -d relwo -f 01_crear_tablas.sql
--         (ejecutar despues de 00_crear_base_y_usuarios.sql)
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS unaccent;

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--





--
-- Name: estado_servicio; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_servicio AS ENUM (
    'creada',
    'pagada_en_custodia',
    'confirmada',
    'en_ejecucion',
    'pendiente_cierre',
    'completada',
    'en_disputa',
    'cancelada'
);


--
-- Name: auditoria_es_de_solo_escritura(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auditoria_es_de_solo_escritura() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          RAISE EXCEPTION
              'auditoria es de solo escritura: % no esta permitido sobre un asiento', TG_OP
              USING ERRCODE = 'restrict_violation';
      END;
      $$;


--
-- Name: evento_producto_es_de_solo_escritura(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.evento_producto_es_de_solo_escritura() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          RAISE EXCEPTION
              'evento_producto es de solo escritura: % no esta permitido sobre un evento', TG_OP
              USING ERRCODE = 'restrict_violation';
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_mensajes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_mensajes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          PERFORM pg_notify('relwo_mensaje_cambio', NEW.servicio_id::text);
          PERFORM pg_notify('relwo_servicio_cambio', NEW.servicio_id::text || ':mensajes');
          RETURN NEW;
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_servicio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_servicio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          IF TG_OP = 'UPDATE'
             AND (to_jsonb(NEW) - 'posicion_maestro_lat' - 'posicion_maestro_lng' - 'posicion_maestro_en')
               = (to_jsonb(OLD) - 'posicion_maestro_lat' - 'posicion_maestro_lng' - 'posicion_maestro_en')
          THEN
              PERFORM pg_notify('relwo_servicio_cambio', NEW.id::text || ':posicion');
          ELSE
              PERFORM pg_notify('relwo_servicio_cambio', NEW.id::text);
          END IF;
          RETURN NEW;
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_servicio_hijo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          PERFORM pg_notify(
              'relwo_servicio_cambio',
              COALESCE(NEW.servicio_id, OLD.servicio_id)::text
          );
          RETURN COALESCE(NEW, OLD);
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_servicio_por_disputa(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_servicio_por_disputa() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
          id_servicio bigint;
      BEGIN
          SELECT servicio_id INTO id_servicio
            FROM disputa
           WHERE id = COALESCE(NEW.disputa_id, OLD.disputa_id);

          IF id_servicio IS NOT NULL THEN
              PERFORM pg_notify('relwo_servicio_cambio', id_servicio::text);
          END IF;

          RETURN COALESCE(NEW, OLD);
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_solicitud(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_solicitud() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          PERFORM pg_notify('relwo_solicitud_cambio', NEW.solicitud_id::text);
          RETURN NEW;
      END;
      $$;


--
-- Name: relwo_avisar_cambio_de_solicitud_por_oferta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.relwo_avisar_cambio_de_solicitud_por_oferta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
          id_solicitud bigint;
      BEGIN
          SELECT solicitud_id INTO id_solicitud
            FROM publicacion
           WHERE id = COALESCE(NEW.publicacion_id, OLD.publicacion_id);

          IF id_solicitud IS NOT NULL THEN
              PERFORM pg_notify('relwo_solicitud_cambio', id_solicitud::text);
          END IF;

          RETURN COALESCE(NEW, OLD);
      END;
      $$;


--
-- Name: servicio_estado_solo_por_transicion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.servicio_estado_solo_por_transicion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
          IF coalesce(current_setting('relwo.transicion_servicio', true), '') = '1' THEN
              RETURN NEW;
          END IF;

          IF TG_OP = 'INSERT' THEN
              IF NEW.estado <> 'creada' THEN
                  RAISE EXCEPTION
                      'RN-06: un servicio nace en creada; llegar a % es una transicion', NEW.estado
                      USING ERRCODE = '42501';
              END IF;
              RETURN NEW;
          END IF;

          IF NEW.estado IS DISTINCT FROM OLD.estado THEN
              RAISE EXCEPTION
                  'RN-06: solo el modulo servicios transiciona servicio.estado (% -> %)', OLD.estado, NEW.estado
                  USING ERRCODE = '42501';
          END IF;

          RETURN NEW;
      END;
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aprobacion_en_terreno; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aprobacion_en_terreno (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    tipo text DEFAULT 'gasto_adicional'::text NOT NULL,
    concepto text NOT NULL,
    monto_adicional bigint NOT NULL,
    motivo text,
    comprobante_storage_key text,
    comprobante_tipo text,
    estado text DEFAULT 'propuesta'::text NOT NULL,
    propuesta_por bigint NOT NULL,
    propuesta_en timestamp with time zone DEFAULT now() NOT NULL,
    vence_en timestamp with time zone,
    resuelta_en timestamp with time zone,
    respondida_por bigint,
    detalle_respuesta text,
    validacion_estado text,
    validacion_emisor text,
    validacion_fecha date,
    validacion_folio text,
    validacion_total bigint,
    validacion_detalle text,
    validada_en timestamp with time zone,
    validada_con text,
    CONSTRAINT ck_aprobacion_en_terreno_comprobante CHECK (((comprobante_storage_key IS NULL) OR (btrim(comprobante_storage_key) <> ''::text))),
    CONSTRAINT ck_aprobacion_en_terreno_concepto CHECK ((btrim(concepto) <> ''::text)),
    CONSTRAINT ck_aprobacion_en_terreno_estado CHECK ((estado = ANY (ARRAY['propuesta'::text, 'aprobada'::text, 'rechazada'::text, 'vencida'::text]))),
    CONSTRAINT ck_aprobacion_en_terreno_monto CHECK ((monto_adicional > 0)),
    CONSTRAINT ck_aprobacion_en_terreno_resolucion CHECK (((estado = 'propuesta'::text) = (resuelta_en IS NULL))),
    CONSTRAINT ck_aprobacion_en_terreno_tipo CHECK ((tipo = ANY (ARRAY['inicio'::text, 'gasto_adicional'::text]))),
    CONSTRAINT ck_aprobacion_en_terreno_validacion_estado CHECK (((validacion_estado IS NULL) OR (validacion_estado = ANY (ARRAY['validado'::text, 'revision_manual'::text, 'rechazado'::text])))),
    CONSTRAINT ck_aprobacion_en_terreno_validada_con CHECK (((validada_con IS NULL) OR (validada_con = ANY (ARRAY['reglas'::text, 'modelo'::text, 'torre'::text]))))
);


--
-- Name: aprobacion_en_terreno_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.aprobacion_en_terreno_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: aprobacion_en_terreno_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.aprobacion_en_terreno_id_seq OWNED BY public.aprobacion_en_terreno.id;


--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria (
    id bigint NOT NULL,
    actor_id bigint NOT NULL,
    accion text NOT NULL,
    entidad text NOT NULL,
    entidad_id bigint,
    motivo text,
    detalle jsonb,
    ocurrido_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_auditoria_accion_no_vacia CHECK ((btrim(accion) <> ''::text)),
    CONSTRAINT ck_auditoria_entidad_no_vacia CHECK ((btrim(entidad) <> ''::text))
);


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditoria_id_seq OWNED BY public.auditoria.id;


--
-- Name: bloqueo_temporal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bloqueo_temporal (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    motivo text NOT NULL,
    vigente_desde timestamp with time zone DEFAULT now() NOT NULL,
    vigente_hasta timestamp with time zone NOT NULL,
    creado_por text DEFAULT 'sistema'::text NOT NULL,
    levantado_en timestamp with time zone,
    levantado_por bigint,
    motivo_levantamiento text,
    CONSTRAINT ck_bloqueo_temporal_levantamiento CHECK (((levantado_en IS NULL) = (motivo_levantamiento IS NULL))),
    CONSTRAINT ck_bloqueo_temporal_vigencia CHECK ((vigente_hasta > vigente_desde))
);


--
-- Name: bloqueo_temporal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bloqueo_temporal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bloqueo_temporal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bloqueo_temporal_id_seq OWNED BY public.bloqueo_temporal.id;


--
-- Name: cancelacion_servicio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancelacion_servicio (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    origen text NOT NULL,
    motivo text NOT NULL,
    momento_del_flujo text NOT NULL,
    detalle text,
    diagnostico text,
    republicada boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cancelacion_servicio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cancelacion_servicio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cancelacion_servicio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cancelacion_servicio_id_seq OWNED BY public.cancelacion_servicio.id;


--
-- Name: cargo_gastos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cargo_gastos (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    monto_total bigint NOT NULL,
    cantidad_gastos smallint NOT NULL,
    estado text NOT NULL,
    referencia_pasarela text,
    intentos smallint DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_cargo_gastos_estado CHECK ((estado = ANY (ARRAY['cobrado'::text, 'rechazado'::text]))),
    CONSTRAINT ck_cargo_gastos_monto CHECK ((monto_total > 0)),
    CONSTRAINT ck_cargo_gastos_referencia CHECK (((estado = 'cobrado'::text) = (referencia_pasarela IS NOT NULL)))
);


--
-- Name: cargo_gastos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cargo_gastos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cargo_gastos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cargo_gastos_id_seq OWNED BY public.cargo_gastos.id;


--
-- Name: cargo_visita; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cargo_visita (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    oferta_difusion_id bigint NOT NULL,
    motivo text NOT NULL,
    monto_maestro bigint NOT NULL,
    monto_comision bigint NOT NULL,
    monto_cliente bigint NOT NULL,
    referencia_pasarela text,
    eximido_por bigint,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cargo_visita_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cargo_visita_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cargo_visita_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cargo_visita_id_seq OWNED BY public.cargo_visita.id;


--
-- Name: categoria_disputa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categoria_disputa (
    codigo text NOT NULL,
    nombre text NOT NULL,
    exige_evidencia boolean DEFAULT false NOT NULL,
    orden smallint NOT NULL,
    activa boolean DEFAULT true NOT NULL
);


--
-- Name: checklist_oficio_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.checklist_oficio_item (
    id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    orden smallint NOT NULL,
    texto text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: checklist_oficio_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.checklist_oficio_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: checklist_oficio_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.checklist_oficio_item_id_seq OWNED BY public.checklist_oficio_item.id;


--
-- Name: cobertura_vertical_comuna; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cobertura_vertical_comuna (
    vertical_id bigint NOT NULL,
    comuna_id bigint NOT NULL,
    activo boolean DEFAULT false NOT NULL
);


--
-- Name: codigo_cierre; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.codigo_cierre (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    codigo character(3) NOT NULL,
    usado boolean DEFAULT false NOT NULL,
    usado_en timestamp with time zone,
    intentos smallint DEFAULT 0 NOT NULL,
    bloqueado boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_codigo_cierre_formato CHECK ((codigo ~ '^[0-9]{3}$'::text)),
    CONSTRAINT ck_codigo_cierre_intentos CHECK (((intentos >= 0) AND (intentos <= 3))),
    CONSTRAINT ck_codigo_cierre_uso CHECK (((usado AND (usado_en IS NOT NULL)) OR ((NOT usado) AND (usado_en IS NULL))))
);


--
-- Name: codigo_cierre_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.codigo_cierre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: codigo_cierre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.codigo_cierre_id_seq OWNED BY public.codigo_cierre.id;


--
-- Name: comuna; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comuna (
    id bigint NOT NULL,
    codigo_cut text NOT NULL,
    nombre text NOT NULL,
    nombre_oficial text,
    provincia text,
    region text,
    geom public.geometry(MultiPolygon,4326),
    visible boolean DEFAULT false NOT NULL,
    operativa boolean DEFAULT false NOT NULL,
    desactivada_manual boolean DEFAULT false NOT NULL,
    umbral_activacion smallint,
    activada_en timestamp with time zone,
    fuente text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_comuna_activada_en_coherente CHECK (((operativa AND (activada_en IS NOT NULL)) OR ((NOT operativa) AND (activada_en IS NULL)))),
    CONSTRAINT ck_comuna_codigo_cut_no_vacio CHECK ((btrim(codigo_cut) <> ''::text)),
    CONSTRAINT ck_comuna_geom_con_fuente CHECK (((geom IS NULL) OR (fuente IS NOT NULL))),
    CONSTRAINT ck_comuna_nombre_no_vacio CHECK ((btrim(nombre) <> ''::text)),
    CONSTRAINT ck_comuna_umbral_positivo CHECK (((umbral_activacion IS NULL) OR (umbral_activacion > 0)))
);


--
-- Name: comuna_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comuna_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comuna_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comuna_id_seq OWNED BY public.comuna.id;


--
-- Name: consulta_adelanto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consulta_adelanto (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    autor_id bigint NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    resuelta_por bigint,
    CONSTRAINT ck_consulta_adelanto_estado CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'caducada'::text]))),
    CONSTRAINT ck_consulta_adelanto_resuelta CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL)))
);


--
-- Name: consulta_adelanto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consulta_adelanto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consulta_adelanto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consulta_adelanto_id_seq OWNED BY public.consulta_adelanto.id;


--
-- Name: consulta_sec; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consulta_sec (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    ambito text NOT NULL,
    resultado text NOT NULL,
    clase text,
    tipo text,
    origen text DEFAULT 'envio'::text NOT NULL,
    consultado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_consulta_sec_ambito CHECK ((ambito = ANY (ARRAY['gas'::text, 'electrico'::text]))),
    CONSTRAINT ck_consulta_sec_origen CHECK ((origen = ANY (ARRAY['envio'::text, 'reverificacion'::text]))),
    CONSTRAINT ck_consulta_sec_resultado CHECK ((resultado = ANY (ARRAY['vigente'::text, 'sin_licencia'::text, 'no_reconocida'::text, 'sin_respuesta'::text])))
);


--
-- Name: consulta_sec_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consulta_sec_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consulta_sec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consulta_sec_id_seq OWNED BY public.consulta_sec.id;


--
-- Name: conversacion_soporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversacion_soporte (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    estado text DEFAULT 'abierta'::text NOT NULL,
    motivo_derivacion text,
    derivada_en timestamp with time zone,
    cerrada_en timestamp with time zone,
    cerrada_por bigint,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_conversacion_soporte_cerrada CHECK (((estado = 'cerrada'::text) = (cerrada_en IS NOT NULL))),
    CONSTRAINT ck_conversacion_soporte_derivada CHECK (((estado <> 'derivada'::text) OR (derivada_en IS NOT NULL))),
    CONSTRAINT ck_conversacion_soporte_estado CHECK ((estado = ANY (ARRAY['abierta'::text, 'derivada'::text, 'cerrada'::text])))
);


--
-- Name: conversacion_soporte_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversacion_soporte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversacion_soporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversacion_soporte_id_seq OWNED BY public.conversacion_soporte.id;


--
-- Name: cotizacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cotizacion (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    regla_precio_id bigint NOT NULL,
    monto_servicio bigint NOT NULL,
    pct_comision_cliente numeric(5,2) DEFAULT 0 NOT NULL,
    monto_comision_cliente bigint DEFAULT 0 NOT NULL,
    cobro_cliente_habilitado boolean DEFAULT true NOT NULL,
    pct_comision_prestador numeric(5,2) DEFAULT 0 NOT NULL,
    monto_comision_prestador bigint DEFAULT 0 NOT NULL,
    cobro_prestador_habilitado boolean DEFAULT true NOT NULL,
    monto_total bigint NOT NULL,
    monto_prestador bigint NOT NULL,
    desglose jsonb NOT NULL,
    version_regla integer NOT NULL,
    vigencia_hasta timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_cotizacion_comisiones_no_negativas CHECK (((monto_comision_cliente >= 0) AND (monto_comision_prestador >= 0))),
    CONSTRAINT ck_cotizacion_monto_servicio CHECK ((monto_servicio > 0)),
    CONSTRAINT ck_cotizacion_no_negativo CHECK ((monto_prestador >= 0)),
    CONSTRAINT ck_cotizacion_prestador CHECK ((monto_prestador = (monto_servicio - monto_comision_prestador))),
    CONSTRAINT ck_cotizacion_total CHECK ((monto_total = (monto_servicio + monto_comision_cliente)))
);


--
-- Name: cotizacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cotizacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cotizacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cotizacion_id_seq OWNED BY public.cotizacion.id;


--
-- Name: dispositivo_push; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispositivo_push (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    token text NOT NULL,
    plataforma text NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    ultimo_envio_en timestamp with time zone,
    invalidado_en timestamp with time zone,
    CONSTRAINT ck_dispositivo_push_plataforma CHECK ((plataforma = ANY (ARRAY['android'::text, 'ios'::text]))),
    CONSTRAINT ck_dispositivo_push_token CHECK ((btrim(token) <> ''::text))
);


--
-- Name: dispositivo_push_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dispositivo_push_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dispositivo_push_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dispositivo_push_id_seq OWNED BY public.dispositivo_push.id;


--
-- Name: disputa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disputa (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    abierta_por bigint NOT NULL,
    categoria text NOT NULL,
    descripcion text NOT NULL,
    estado text DEFAULT 'abierta'::text NOT NULL,
    sla_vence_en timestamp with time zone NOT NULL,
    resuelto_por bigint,
    resolucion text,
    resuelta_en timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    asignada_a bigint,
    asignada_en timestamp with time zone,
    respuesta_maestro text,
    respuesta_maestro_en timestamp with time zone,
    motivo_resolucion text,
    monto_reembolsado bigint,
    CONSTRAINT ck_disputa_descripcion_no_vacia CHECK ((btrim(descripcion) <> ''::text)),
    CONSTRAINT ck_disputa_estado CHECK ((estado = ANY (ARRAY['abierta'::text, 'asignada'::text, 'resuelta'::text]))),
    CONSTRAINT ck_disputa_monto_reembolsado CHECK ((monto_reembolsado > 0)),
    CONSTRAINT ck_disputa_resolucion CHECK ((resolucion = ANY (ARRAY['liberar'::text, 'reembolso_total'::text, 'reembolso_parcial'::text])))
);


--
-- Name: disputa_evidencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disputa_evidencia (
    id bigint NOT NULL,
    disputa_id bigint NOT NULL,
    storage_key text NOT NULL,
    tipo_contenido text NOT NULL,
    orden smallint NOT NULL,
    subido_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: disputa_evidencia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disputa_evidencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disputa_evidencia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disputa_evidencia_id_seq OWNED BY public.disputa_evidencia.id;


--
-- Name: disputa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disputa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disputa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disputa_id_seq OWNED BY public.disputa.id;


--
-- Name: evaluacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evaluacion (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    evaluador text NOT NULL,
    puntuacion smallint NOT NULL,
    resena text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    publicada_en timestamp with time zone,
    recomienda boolean,
    destacados jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT evaluacion_puntuacion_check CHECK (((puntuacion >= 1) AND (puntuacion <= 5)))
);


--
-- Name: evaluacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evaluacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evaluacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evaluacion_id_seq OWNED BY public.evaluacion.id;


--
-- Name: evento_producto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_producto (
    id bigint NOT NULL,
    tipo text NOT NULL,
    usuario_id bigint,
    solicitud_id bigint,
    servicio_id bigint,
    vertical_id bigint,
    comuna_id bigint,
    payload jsonb,
    ocurrido_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_evento_producto_tipo CHECK ((tipo = ANY (ARRAY['solicitud_iniciada'::text, 'ofertas_vistas'::text, 'pago_confirmado'::text, 'servicio_completado'::text, 'recontratacion'::text])))
);


--
-- Name: evento_producto_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_producto_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_producto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_producto_id_seq OWNED BY public.evento_producto.id;


--
-- Name: fotografia_servicio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fotografia_servicio (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    prestador_usuario_id bigint NOT NULL,
    tipo text NOT NULL,
    storage_key text NOT NULL,
    tipo_contenido text NOT NULL,
    orden smallint DEFAULT 1 NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fotografia_servicio_tipo_check CHECK ((tipo = ANY (ARRAY['inicial'::text, 'evidencia'::text])))
);


--
-- Name: fotografia_servicio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fotografia_servicio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fotografia_servicio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fotografia_servicio_id_seq OWNED BY public.fotografia_servicio.id;


--
-- Name: hogar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hogar (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    alias text,
    tipo_vivienda text,
    direccion text NOT NULL,
    comuna_id bigint,
    geom_punto public.geometry(Point,4326),
    m2 integer,
    dormitorios integer,
    banos integer,
    principal boolean DEFAULT false NOT NULL,
    archivado_en timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    pisos integer,
    mascotas jsonb DEFAULT '[]'::jsonb NOT NULL,
    notas_generales text,
    instrucciones_acceso text,
    contacto_referencia_nombre text,
    contacto_referencia_telefono text,
    CONSTRAINT ck_hogar_archivado_no_principal CHECK (((archivado_en IS NULL) OR (NOT principal))),
    CONSTRAINT ck_hogar_direccion_no_vacia CHECK ((btrim(direccion) <> ''::text)),
    CONSTRAINT ck_hogar_medidas_no_negativas CHECK ((((m2 IS NULL) OR (m2 >= 0)) AND ((dormitorios IS NULL) OR (dormitorios >= 0)) AND ((banos IS NULL) OR (banos >= 0))))
);


--
-- Name: hogar_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hogar_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hogar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hogar_id_seq OWNED BY public.hogar.id;


--
-- Name: incumplimiento_uso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incumplimiento_uso (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    tipo text NOT NULL,
    detalle text,
    origen text DEFAULT 'sistema'::text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: incumplimiento_uso_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.incumplimiento_uso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incumplimiento_uso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.incumplimiento_uso_id_seq OWNED BY public.incumplimiento_uso.id;


--
-- Name: intento_sensible; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intento_sensible (
    id bigint NOT NULL,
    accion text NOT NULL,
    clave text NOT NULL,
    exito boolean NOT NULL,
    ocurrido_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_intento_sensible_accion CHECK ((btrim(accion) <> ''::text)),
    CONSTRAINT ck_intento_sensible_clave CHECK ((btrim(clave) <> ''::text))
);


--
-- Name: intento_sensible_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.intento_sensible_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intento_sensible_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.intento_sensible_id_seq OWNED BY public.intento_sensible.id;


--
-- Name: interes_demanda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interes_demanda (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    comuna_id bigint,
    origen text NOT NULL,
    motivo text,
    anotado_en timestamp with time zone DEFAULT now() NOT NULL,
    retirado_en timestamp with time zone,
    CONSTRAINT ck_interes_demanda_motivo CHECK (((motivo IS NULL) OR (motivo = ANY (ARRAY['con_cobertura'::text, 'comuna_no_operativa'::text, 'sin_maestros_disponibles'::text, 'sin_comuna_resuelta'::text])))),
    CONSTRAINT ck_interes_demanda_origen CHECK ((origen = ANY (ARRAY['vertical_proximamente'::text, 'sin_cobertura_efectiva'::text])))
);


--
-- Name: interes_demanda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.interes_demanda_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interes_demanda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.interes_demanda_id_seq OWNED BY public.interes_demanda.id;


--
-- Name: llamada_ia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.llamada_ia (
    id bigint NOT NULL,
    usuario_id bigint,
    proposito text NOT NULL,
    proveedor text NOT NULL,
    modelo text NOT NULL,
    tokens_entrada integer DEFAULT 0 NOT NULL,
    tokens_salida integer DEFAULT 0 NOT NULL,
    resultado text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    vueltas_herramienta integer DEFAULT 0 NOT NULL,
    CONSTRAINT ck_llamada_ia_proposito CHECK ((proposito = ANY (ARRAY['soporte'::text, 'validacion_comprobante'::text]))),
    CONSTRAINT ck_llamada_ia_resultado CHECK ((resultado = ANY (ARRAY['respondida'::text, 'truncada'::text, 'fallida'::text]))),
    CONSTRAINT ck_llamada_ia_tokens CHECK (((tokens_entrada >= 0) AND (tokens_salida >= 0))),
    CONSTRAINT ck_llamada_ia_vueltas CHECK ((vueltas_herramienta >= 0))
);


--
-- Name: llamada_ia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.llamada_ia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: llamada_ia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.llamada_ia_id_seq OWNED BY public.llamada_ia.id;


--
-- Name: mensaje; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mensaje (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    autor_id bigint NOT NULL,
    rol_autor text NOT NULL,
    texto text NOT NULL,
    clave_envio uuid NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    consulta_adelanto_id bigint,
    CONSTRAINT ck_mensaje_rol_autor CHECK ((rol_autor = ANY (ARRAY['cliente'::text, 'prestador'::text]))),
    CONSTRAINT ck_mensaje_texto_largo CHECK (((char_length(texto) <= 2000) AND (btrim(texto, ' 	

'::text) <> ''::text)))
);


--
-- Name: mensaje_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mensaje_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mensaje_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mensaje_id_seq OWNED BY public.mensaje.id;


--
-- Name: mensaje_lectura; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mensaje_lectura (
    servicio_id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    ultimo_mensaje_leido_id bigint NOT NULL,
    leido_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: mensaje_soporte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mensaje_soporte (
    id bigint NOT NULL,
    conversacion_id bigint NOT NULL,
    autor text NOT NULL,
    nivel text,
    texto text NOT NULL,
    autor_usuario_id bigint,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_mensaje_soporte_autor CHECK ((autor = ANY (ARRAY['usuario'::text, 'agente'::text, 'soporte'::text]))),
    CONSTRAINT ck_mensaje_soporte_nivel CHECK (((nivel IS NULL) OR (nivel = ANY (ARRAY['guiado'::text, 'modelo'::text, 'humano'::text])))),
    CONSTRAINT ck_mensaje_soporte_nivel_de_respuesta CHECK (((autor = 'usuario'::text) = (nivel IS NULL))),
    CONSTRAINT ck_mensaje_soporte_persona CHECK (((autor = 'soporte'::text) = (autor_usuario_id IS NOT NULL)))
);


--
-- Name: mensaje_soporte_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mensaje_soporte_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mensaje_soporte_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mensaje_soporte_id_seq OWNED BY public.mensaje_soporte.id;


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modalidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modalidad (
    id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    orden smallint DEFAULT 0 NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_modalidad_codigo_no_vacio CHECK ((btrim(codigo) <> ''::text)),
    CONSTRAINT ck_modalidad_nombre_no_vacio CHECK ((btrim(nombre) <> ''::text))
);


--
-- Name: modalidad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modalidad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modalidad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modalidad_id_seq OWNED BY public.modalidad.id;


--
-- Name: oferta_difusion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oferta_difusion (
    id bigint NOT NULL,
    publicacion_id bigint NOT NULL,
    prestador_id bigint NOT NULL,
    estado text DEFAULT 'cotizada'::text NOT NULL,
    estimado_base bigint NOT NULL,
    tarifa_visita bigint DEFAULT 0 NOT NULL,
    tipo_trabajo_id bigint,
    desglose jsonb NOT NULL,
    distancia_m integer,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    retirada_en timestamp with time zone
);


--
-- Name: oferta_difusion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oferta_difusion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oferta_difusion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oferta_difusion_id_seq OWNED BY public.oferta_difusion.id;


--
-- Name: pago; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pago (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    orden smallint DEFAULT 0 NOT NULL,
    estado_pago text NOT NULL,
    modelo text,
    proveedor text,
    token_referencia text,
    id_transaccion text,
    monto bigint NOT NULL,
    comision_cliente bigint DEFAULT 0 NOT NULL,
    comision_prestador bigint DEFAULT 0 NOT NULL,
    monto_reembolsado bigint DEFAULT 0 NOT NULL,
    moneda text DEFAULT 'CLP'::text NOT NULL,
    idempotency_key text NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    comision_cliente_revertida bigint DEFAULT 0 NOT NULL,
    comision_prestador_revertida bigint DEFAULT 0 NOT NULL,
    CONSTRAINT ck_pago_comisiones CHECK (((comision_cliente >= 0) AND (comision_prestador >= 0))),
    CONSTRAINT ck_pago_comisiones_revertidas CHECK (((comision_cliente_revertida >= 0) AND (comision_prestador_revertida >= 0))),
    CONSTRAINT ck_pago_estado CHECK ((estado_pago = ANY (ARRAY['autorizado'::text, 'retenido_custodia'::text, 'retenido_disputa'::text, 'liberado'::text, 'reembolsado'::text]))),
    CONSTRAINT ck_pago_modelo CHECK (((modelo IS NULL) OR (modelo = ANY (ARRAY['A'::text, 'B'::text])))),
    CONSTRAINT ck_pago_monto CHECK ((monto > 0)),
    CONSTRAINT ck_pago_orden CHECK ((orden >= 0)),
    CONSTRAINT ck_pago_reembolso CHECK (((monto_reembolsado >= 0) AND (monto_reembolsado <= monto)))
);


--
-- Name: pago_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pago_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pago_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pago_id_seq OWNED BY public.pago.id;


--
-- Name: parametro_operacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parametro_operacion (
    clave text NOT NULL,
    valor jsonb,
    descripcion text NOT NULL,
    actualizado_por bigint,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: prestador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prestador (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    anios_experiencia integer,
    descripcion text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    disponible boolean DEFAULT true NOT NULL,
    CONSTRAINT ck_prestador_anios_experiencia CHECK (((anios_experiencia IS NULL) OR (anios_experiencia >= 0)))
);


--
-- Name: prestador_cobertura_comuna; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prestador_cobertura_comuna (
    prestador_id bigint NOT NULL,
    comuna_id bigint NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    declarada_en timestamp with time zone DEFAULT now() NOT NULL,
    aprobada_por bigint
);


--
-- Name: prestador_disponibilidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prestador_disponibilidad (
    id bigint NOT NULL,
    prestador_id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    disponible boolean DEFAULT false NOT NULL,
    acepta_urgencia boolean DEFAULT false NOT NULL,
    ventanas jsonb,
    actualizado_en timestamp with time zone DEFAULT now() NOT NULL,
    acepta_urgencia_24_7 boolean DEFAULT false NOT NULL
);


--
-- Name: prestador_disponibilidad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prestador_disponibilidad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prestador_disponibilidad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prestador_disponibilidad_id_seq OWNED BY public.prestador_disponibilidad.id;


--
-- Name: prestador_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prestador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prestador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prestador_id_seq OWNED BY public.prestador.id;


--
-- Name: propuesta_cambio_hora; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.propuesta_cambio_hora (
    id bigint NOT NULL,
    servicio_id bigint NOT NULL,
    propuesta_por text NOT NULL,
    autor_id bigint NOT NULL,
    nuevo_inicio timestamp with time zone NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    resuelta_por bigint,
    CONSTRAINT ck_propuesta_cambio_hora_estado CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'retirada'::text, 'caducada'::text]))),
    CONSTRAINT ck_propuesta_cambio_hora_propuesta_por CHECK ((propuesta_por = 'cliente'::text)),
    CONSTRAINT ck_propuesta_cambio_hora_resuelta CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL)))
);


--
-- Name: propuesta_cambio_hora_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.propuesta_cambio_hora_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: propuesta_cambio_hora_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.propuesta_cambio_hora_id_seq OWNED BY public.propuesta_cambio_hora.id;


--
-- Name: publicacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publicacion (
    id bigint NOT NULL,
    solicitud_id bigint NOT NULL,
    estado text DEFAULT 'abierta'::text NOT NULL,
    motivo_cierre text,
    vence_en timestamp with time zone NOT NULL,
    ronda integer DEFAULT 1 NOT NULL,
    motivo_apertura text DEFAULT 'original'::text NOT NULL,
    alertados_n integer DEFAULT 0 NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    cerrada_en timestamp with time zone,
    eleccion_vence_en timestamp with time zone
);


--
-- Name: publicacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.publicacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publicacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.publicacion_id_seq OWNED BY public.publicacion.id;


--
-- Name: referencia_precio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.referencia_precio (
    id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    modalidad_id bigint NOT NULL,
    comuna_id bigint,
    valor bigint NOT NULL,
    origen text NOT NULL,
    muestra_n integer DEFAULT 0 NOT NULL,
    vigente_desde timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_referencia_precio_valor_positivo CHECK ((valor > 0))
);


--
-- Name: referencia_precio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.referencia_precio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: referencia_precio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.referencia_precio_id_seq OWNED BY public.referencia_precio.id;


--
-- Name: regla_precio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regla_precio (
    id bigint NOT NULL,
    vertical_id bigint,
    comuna_id bigint,
    modalidad_id bigint,
    version integer NOT NULL,
    vigencia_desde timestamp with time zone DEFAULT now() NOT NULL,
    vigencia_hasta timestamp with time zone,
    moneda text DEFAULT 'CLP'::text NOT NULL,
    parametros jsonb DEFAULT '{}'::jsonb NOT NULL,
    pct_comision_cliente numeric(5,2) DEFAULT 0 NOT NULL,
    pct_comision_prestador numeric(5,2) DEFAULT 0 NOT NULL,
    cobro_cliente_habilitado boolean DEFAULT false NOT NULL,
    cobro_prestador_habilitado boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_regla_precio_pct_cliente CHECK (((pct_comision_cliente >= (0)::numeric) AND (pct_comision_cliente <= (100)::numeric))),
    CONSTRAINT ck_regla_precio_pct_prestador CHECK (((pct_comision_prestador >= (0)::numeric) AND (pct_comision_prestador <= (100)::numeric))),
    CONSTRAINT ck_regla_precio_version CHECK ((version > 0)),
    CONSTRAINT ck_regla_precio_vigencia CHECK (((vigencia_hasta IS NULL) OR (vigencia_hasta > vigencia_desde)))
);


--
-- Name: regla_precio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regla_precio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regla_precio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regla_precio_id_seq OWNED BY public.regla_precio.id;


--
-- Name: restablecimiento_contrasena; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restablecimiento_contrasena (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    destino text NOT NULL,
    codigo_hash text NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    intentos smallint DEFAULT 0 NOT NULL,
    usado_en timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_restablecimiento_codigo CHECK ((btrim(codigo_hash) <> ''::text)),
    CONSTRAINT ck_restablecimiento_destino CHECK ((btrim(destino) <> ''::text)),
    CONSTRAINT ck_restablecimiento_intentos CHECK ((intentos >= 0))
);


--
-- Name: restablecimiento_contrasena_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.restablecimiento_contrasena_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: restablecimiento_contrasena_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.restablecimiento_contrasena_id_seq OWNED BY public.restablecimiento_contrasena.id;


--
-- Name: servicio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicio (
    id bigint NOT NULL,
    solicitud_id bigint NOT NULL,
    prestador_id bigint,
    estado public.estado_servicio DEFAULT 'creada'::public.estado_servicio NOT NULL,
    subestado text,
    fecha_agenda timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    en_camino_en timestamp with time zone,
    llegada_en timestamp with time zone,
    llegada_distancia_metros integer,
    llegada_validada boolean,
    llegada_fallida_en timestamp with time zone,
    llegada_confirmada_por bigint,
    posicion_maestro_lat double precision,
    posicion_maestro_lng double precision,
    posicion_maestro_en timestamp with time zone,
    completada_en timestamp with time zone,
    aviso_en_camino_enviado_en timestamp with time zone,
    adelanto_autorizado_en timestamp with time zone,
    ruta_en_camino public.geometry(LineString,4326),
    ruta_en_camino_polilinea text,
    ruta_en_camino_distancia_metros integer,
    ruta_en_camino_duracion_segundos integer,
    ruta_en_camino_calculada_en timestamp with time zone,
    rutas_en_camino_calculadas smallint DEFAULT 0 NOT NULL,
    llegada_estimada_desde timestamp(3) with time zone,
    llegada_estimada_hasta timestamp(3) with time zone,
    CONSTRAINT ck_servicio_prestador_asignado CHECK (((estado <> ALL (ARRAY['confirmada'::public.estado_servicio, 'pagada_en_custodia'::public.estado_servicio, 'en_ejecucion'::public.estado_servicio, 'pendiente_cierre'::public.estado_servicio, 'completada'::public.estado_servicio])) OR (prestador_id IS NOT NULL))),
    CONSTRAINT ck_servicio_subestado CHECK (((subestado IS NULL) OR (subestado = ANY (ARRAY['pendiente_asignacion'::text, 'en_camino'::text, 'prestador_llego'::text, 'reprogramada'::text, 'pago_liberado'::text, 'reembolsada'::text]))))
);


--
-- Name: servicio_checklist_marca; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicio_checklist_marca (
    servicio_id bigint NOT NULL,
    item_id bigint NOT NULL,
    marcado boolean NOT NULL,
    marcada_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: servicio_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.servicio_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: servicio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.servicio_id_seq OWNED BY public.servicio.id;


--
-- Name: sesion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sesion (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    token_hash text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocada_en timestamp with time zone,
    CONSTRAINT ck_sesion_token_hash_no_vacio CHECK ((btrim(token_hash) <> ''::text)),
    CONSTRAINT ck_sesion_vigencia CHECK ((expira_en > creada_en))
);


--
-- Name: sesion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sesion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sesion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sesion_id_seq OWNED BY public.sesion.id;


--
-- Name: solicitud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solicitud (
    id bigint NOT NULL,
    cliente_id bigint NOT NULL,
    hogar_id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    modalidad_id bigint NOT NULL,
    frecuencia text DEFAULT 'una_vez'::text NOT NULL,
    ventana_horaria tstzrange,
    notas text,
    canal_entrada text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    tipo_problema_id bigint,
    ambientes jsonb,
    CONSTRAINT ck_solicitud_frecuencia CHECK ((frecuencia = ANY (ARRAY['una_vez'::text, 'quincenal'::text, 'semanal'::text]))),
    CONSTRAINT ck_solicitud_notas_no_vacia CHECK (((notas IS NULL) OR (btrim(notas) <> ''::text))),
    CONSTRAINT ck_solicitud_ventana_no_vacia CHECK (((ventana_horaria IS NULL) OR (NOT isempty(ventana_horaria))))
);


--
-- Name: solicitud_fotografia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solicitud_fotografia (
    id bigint NOT NULL,
    solicitud_id bigint NOT NULL,
    storage_key text NOT NULL,
    orden smallint DEFAULT 1 NOT NULL,
    subida_en timestamp with time zone DEFAULT now() NOT NULL,
    sin_ubicacion_verificada boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_solicitud_fotografia_orden CHECK ((orden >= 1)),
    CONSTRAINT ck_solicitud_fotografia_storage_key CHECK ((btrim(storage_key) <> ''::text))
);


--
-- Name: solicitud_fotografia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solicitud_fotografia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solicitud_fotografia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solicitud_fotografia_id_seq OWNED BY public.solicitud_fotografia.id;


--
-- Name: solicitud_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solicitud_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solicitud_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solicitud_id_seq OWNED BY public.solicitud.id;


--
-- Name: solicitud_registro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solicitud_registro (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    tipo text NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    motivo text,
    resuelta_por bigint,
    resuelta_en timestamp with time zone,
    resolucion_automatica boolean DEFAULT false NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_solicitud_registro_actor CHECK (((estado = 'pendiente'::text) OR resolucion_automatica OR (resuelta_por IS NOT NULL))),
    CONSTRAINT ck_solicitud_registro_automatica_no_pendiente CHECK (((NOT resolucion_automatica) OR (estado <> 'pendiente'::text))),
    CONSTRAINT ck_solicitud_registro_automatica_sin_actor CHECK (((NOT resolucion_automatica) OR (resuelta_por IS NULL))),
    CONSTRAINT ck_solicitud_registro_estado CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aprobada'::text, 'rechazada'::text]))),
    CONSTRAINT ck_solicitud_registro_fecha_resolucion CHECK ((((estado = 'pendiente'::text) AND (resuelta_en IS NULL)) OR ((estado <> 'pendiente'::text) AND (resuelta_en IS NOT NULL)))),
    CONSTRAINT ck_solicitud_registro_motivo_rechazo CHECK (((estado <> 'rechazada'::text) OR ((motivo IS NOT NULL) AND (btrim(motivo) <> ''::text)))),
    CONSTRAINT ck_solicitud_registro_tipo CHECK ((tipo = ANY (ARRAY['cliente'::text, 'prestador'::text])))
);


--
-- Name: solicitud_registro_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solicitud_registro_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solicitud_registro_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solicitud_registro_id_seq OWNED BY public.solicitud_registro.id;


--
-- Name: tipo_ambiente; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_ambiente (
    id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    orden smallint DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_ambiente_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_ambiente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_ambiente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_ambiente_id_seq OWNED BY public.tipo_ambiente.id;


--
-- Name: tipo_problema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_problema (
    id bigint NOT NULL,
    vertical_id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    orden smallint DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_problema_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_problema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_problema_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_problema_id_seq OWNED BY public.tipo_problema.id;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id bigint NOT NULL,
    nombre text NOT NULL,
    email text,
    telefono text,
    estado_habilitacion text DEFAULT 'pendiente_aprobacion'::text NOT NULL,
    motivo_habilitacion text,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    apellidos text,
    foto_storage_key text,
    contrasena_hash text,
    canal_verificado text,
    canal_verificado_en timestamp with time zone,
    rut text,
    actividad_vista_en timestamp with time zone,
    CONSTRAINT ck_usuario_algun_contacto CHECK (((id = 0) OR (email IS NOT NULL) OR (telefono IS NOT NULL))),
    CONSTRAINT ck_usuario_canal_verificado CHECK (((canal_verificado IS NULL) OR (canal_verificado = ANY (ARRAY['correo'::text, 'telefono'::text])))),
    CONSTRAINT ck_usuario_canal_verificado_fecha CHECK ((((canal_verificado IS NULL) AND (canal_verificado_en IS NULL)) OR ((canal_verificado IS NOT NULL) AND (canal_verificado_en IS NOT NULL)))),
    CONSTRAINT ck_usuario_contrasena_hash_no_vacia CHECK (((contrasena_hash IS NULL) OR (btrim(contrasena_hash) <> ''::text))),
    CONSTRAINT ck_usuario_estado_habilitacion CHECK ((estado_habilitacion = ANY (ARRAY['pendiente_aprobacion'::text, 'aprobada'::text, 'rechazada'::text, 'suspendida'::text]))),
    CONSTRAINT ck_usuario_motivo_habilitacion CHECK (((estado_habilitacion <> ALL (ARRAY['rechazada'::text, 'suspendida'::text])) OR ((motivo_habilitacion IS NOT NULL) AND (btrim(motivo_habilitacion) <> ''::text)))),
    CONSTRAINT ck_usuario_motivo_solo_si_corresponde CHECK (((estado_habilitacion = ANY (ARRAY['rechazada'::text, 'suspendida'::text])) OR (motivo_habilitacion IS NULL))),
    CONSTRAINT ck_usuario_rut CHECK ((rut ~ '^[0-9]{7,8}-[0-9K]$'::text))
);


--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- Name: usuario_rol; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario_rol (
    usuario_id bigint NOT NULL,
    rol text NOT NULL,
    CONSTRAINT ck_usuario_rol_rol CHECK ((rol = ANY (ARRAY['cliente'::text, 'prestador'::text, 'admin'::text])))
);


--
-- Name: verificacion_canal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verificacion_canal (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    canal text NOT NULL,
    destino text NOT NULL,
    codigo_hash text NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    intentos smallint DEFAULT 0 NOT NULL,
    verificado_en timestamp with time zone,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_verificacion_canal CHECK ((canal = ANY (ARRAY['correo'::text, 'telefono'::text]))),
    CONSTRAINT ck_verificacion_codigo CHECK ((btrim(codigo_hash) <> ''::text)),
    CONSTRAINT ck_verificacion_destino CHECK ((btrim(destino) <> ''::text)),
    CONSTRAINT ck_verificacion_intentos CHECK ((intentos >= 0)),
    CONSTRAINT ck_verificacion_vigencia CHECK ((expira_en > creado_en))
);


--
-- Name: verificacion_canal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.verificacion_canal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: verificacion_canal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.verificacion_canal_id_seq OWNED BY public.verificacion_canal.id;


--
-- Name: verificacion_capa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verificacion_capa (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    capa text NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    fuente text,
    referencia_externa text,
    motivo text,
    vigente_hasta timestamp with time zone,
    verificado_en timestamp with time zone,
    verificado_por bigint,
    enviada_en timestamp with time zone DEFAULT now() NOT NULL,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_verificacion_capa_capa CHECK ((capa = ANY (ARRAY['identidad'::text, 'antecedentes'::text, 'referencias'::text, 'oficio'::text]))),
    CONSTRAINT ck_verificacion_capa_estado CHECK ((estado = ANY (ARRAY['pendiente'::text, 'verificada'::text, 'ilegible'::text, 'rechazada'::text]))),
    CONSTRAINT ck_verificacion_capa_fuente CHECK (((fuente IS NULL) OR (fuente = ANY (ARRAY['manual'::text, 'externo'::text, 'doble_de_prueba'::text])))),
    CONSTRAINT ck_verificacion_capa_motivo CHECK (((motivo IS NULL) OR (estado = ANY (ARRAY['ilegible'::text, 'rechazada'::text])))),
    CONSTRAINT ck_verificacion_capa_resolutor CHECK (((NOT ((fuente = 'manual'::text) AND (estado <> 'pendiente'::text))) OR (verificado_por IS NOT NULL))),
    CONSTRAINT ck_verificacion_capa_resuelta CHECK (((estado = 'pendiente'::text) = (verificado_en IS NULL)))
);


--
-- Name: verificacion_capa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.verificacion_capa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: verificacion_capa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.verificacion_capa_id_seq OWNED BY public.verificacion_capa.id;


--
-- Name: vertical; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertical (
    id bigint NOT NULL,
    codigo text NOT NULL,
    nombre text NOT NULL,
    estado text DEFAULT 'activo'::text NOT NULL,
    activable boolean DEFAULT true NOT NULL,
    orden smallint DEFAULT 0 NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    tarifa_minima bigint,
    tarifa_maxima bigint,
    oficio text,
    sec_ambito text,
    sec_clases_aceptadas text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT ck_vertical_codigo_no_vacio CHECK ((btrim(codigo) <> ''::text)),
    CONSTRAINT ck_vertical_estado CHECK ((estado = ANY (ARRAY['activo'::text, 'proximamente'::text, 'inactivo'::text]))),
    CONSTRAINT ck_vertical_nombre_no_vacio CHECK ((btrim(nombre) <> ''::text)),
    CONSTRAINT ck_vertical_rango_tarifa CHECK (((tarifa_minima IS NULL) OR (tarifa_maxima IS NULL) OR (tarifa_maxima >= tarifa_minima))),
    CONSTRAINT ck_vertical_sec_ambito CHECK ((sec_ambito = ANY (ARRAY['gas'::text, 'electrico'::text]))),
    CONSTRAINT ck_vertical_tarifa_maxima CHECK (((tarifa_maxima IS NULL) OR (tarifa_maxima > 0))),
    CONSTRAINT ck_vertical_tarifa_minima CHECK (((tarifa_minima IS NULL) OR (tarifa_minima > 0)))
);


--
-- Name: vertical_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vertical_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vertical_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vertical_id_seq OWNED BY public.vertical.id;


--
-- Name: vertical_modalidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vertical_modalidad (
    vertical_id bigint NOT NULL,
    modalidad_id bigint NOT NULL,
    activa boolean DEFAULT true NOT NULL
);


--
-- Name: aprobacion_en_terreno id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobacion_en_terreno ALTER COLUMN id SET DEFAULT nextval('public.aprobacion_en_terreno_id_seq'::regclass);


--
-- Name: auditoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id SET DEFAULT nextval('public.auditoria_id_seq'::regclass);


--
-- Name: bloqueo_temporal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloqueo_temporal ALTER COLUMN id SET DEFAULT nextval('public.bloqueo_temporal_id_seq'::regclass);


--
-- Name: cancelacion_servicio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelacion_servicio ALTER COLUMN id SET DEFAULT nextval('public.cancelacion_servicio_id_seq'::regclass);


--
-- Name: cargo_gastos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_gastos ALTER COLUMN id SET DEFAULT nextval('public.cargo_gastos_id_seq'::regclass);


--
-- Name: cargo_visita id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita ALTER COLUMN id SET DEFAULT nextval('public.cargo_visita_id_seq'::regclass);


--
-- Name: checklist_oficio_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_oficio_item ALTER COLUMN id SET DEFAULT nextval('public.checklist_oficio_item_id_seq'::regclass);


--
-- Name: codigo_cierre id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigo_cierre ALTER COLUMN id SET DEFAULT nextval('public.codigo_cierre_id_seq'::regclass);


--
-- Name: comuna id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comuna ALTER COLUMN id SET DEFAULT nextval('public.comuna_id_seq'::regclass);


--
-- Name: consulta_adelanto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_adelanto ALTER COLUMN id SET DEFAULT nextval('public.consulta_adelanto_id_seq'::regclass);


--
-- Name: consulta_sec id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_sec ALTER COLUMN id SET DEFAULT nextval('public.consulta_sec_id_seq'::regclass);


--
-- Name: conversacion_soporte id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversacion_soporte ALTER COLUMN id SET DEFAULT nextval('public.conversacion_soporte_id_seq'::regclass);


--
-- Name: cotizacion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion ALTER COLUMN id SET DEFAULT nextval('public.cotizacion_id_seq'::regclass);


--
-- Name: dispositivo_push id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivo_push ALTER COLUMN id SET DEFAULT nextval('public.dispositivo_push_id_seq'::regclass);


--
-- Name: disputa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa ALTER COLUMN id SET DEFAULT nextval('public.disputa_id_seq'::regclass);


--
-- Name: disputa_evidencia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa_evidencia ALTER COLUMN id SET DEFAULT nextval('public.disputa_evidencia_id_seq'::regclass);


--
-- Name: evaluacion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluacion ALTER COLUMN id SET DEFAULT nextval('public.evaluacion_id_seq'::regclass);


--
-- Name: evento_producto id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto ALTER COLUMN id SET DEFAULT nextval('public.evento_producto_id_seq'::regclass);


--
-- Name: fotografia_servicio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotografia_servicio ALTER COLUMN id SET DEFAULT nextval('public.fotografia_servicio_id_seq'::regclass);


--
-- Name: hogar id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hogar ALTER COLUMN id SET DEFAULT nextval('public.hogar_id_seq'::regclass);


--
-- Name: incumplimiento_uso id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incumplimiento_uso ALTER COLUMN id SET DEFAULT nextval('public.incumplimiento_uso_id_seq'::regclass);


--
-- Name: intento_sensible id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intento_sensible ALTER COLUMN id SET DEFAULT nextval('public.intento_sensible_id_seq'::regclass);


--
-- Name: interes_demanda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interes_demanda ALTER COLUMN id SET DEFAULT nextval('public.interes_demanda_id_seq'::regclass);


--
-- Name: llamada_ia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.llamada_ia ALTER COLUMN id SET DEFAULT nextval('public.llamada_ia_id_seq'::regclass);


--
-- Name: mensaje id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje ALTER COLUMN id SET DEFAULT nextval('public.mensaje_id_seq'::regclass);


--
-- Name: mensaje_soporte id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_soporte ALTER COLUMN id SET DEFAULT nextval('public.mensaje_soporte_id_seq'::regclass);


--
-- Name: modalidad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modalidad ALTER COLUMN id SET DEFAULT nextval('public.modalidad_id_seq'::regclass);


--
-- Name: oferta_difusion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oferta_difusion ALTER COLUMN id SET DEFAULT nextval('public.oferta_difusion_id_seq'::regclass);


--
-- Name: pago id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago ALTER COLUMN id SET DEFAULT nextval('public.pago_id_seq'::regclass);


--
-- Name: prestador id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador ALTER COLUMN id SET DEFAULT nextval('public.prestador_id_seq'::regclass);


--
-- Name: prestador_disponibilidad id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_disponibilidad ALTER COLUMN id SET DEFAULT nextval('public.prestador_disponibilidad_id_seq'::regclass);


--
-- Name: propuesta_cambio_hora id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propuesta_cambio_hora ALTER COLUMN id SET DEFAULT nextval('public.propuesta_cambio_hora_id_seq'::regclass);


--
-- Name: publicacion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicacion ALTER COLUMN id SET DEFAULT nextval('public.publicacion_id_seq'::regclass);


--
-- Name: referencia_precio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio ALTER COLUMN id SET DEFAULT nextval('public.referencia_precio_id_seq'::regclass);


--
-- Name: regla_precio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio ALTER COLUMN id SET DEFAULT nextval('public.regla_precio_id_seq'::regclass);


--
-- Name: restablecimiento_contrasena id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restablecimiento_contrasena ALTER COLUMN id SET DEFAULT nextval('public.restablecimiento_contrasena_id_seq'::regclass);


--
-- Name: servicio id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio ALTER COLUMN id SET DEFAULT nextval('public.servicio_id_seq'::regclass);


--
-- Name: sesion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sesion ALTER COLUMN id SET DEFAULT nextval('public.sesion_id_seq'::regclass);


--
-- Name: solicitud id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud ALTER COLUMN id SET DEFAULT nextval('public.solicitud_id_seq'::regclass);


--
-- Name: solicitud_fotografia id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_fotografia ALTER COLUMN id SET DEFAULT nextval('public.solicitud_fotografia_id_seq'::regclass);


--
-- Name: solicitud_registro id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_registro ALTER COLUMN id SET DEFAULT nextval('public.solicitud_registro_id_seq'::regclass);


--
-- Name: tipo_ambiente id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_ambiente ALTER COLUMN id SET DEFAULT nextval('public.tipo_ambiente_id_seq'::regclass);


--
-- Name: tipo_problema id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_problema ALTER COLUMN id SET DEFAULT nextval('public.tipo_problema_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- Name: verificacion_canal id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_canal ALTER COLUMN id SET DEFAULT nextval('public.verificacion_canal_id_seq'::regclass);


--
-- Name: verificacion_capa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_capa ALTER COLUMN id SET DEFAULT nextval('public.verificacion_capa_id_seq'::regclass);


--
-- Name: vertical id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical ALTER COLUMN id SET DEFAULT nextval('public.vertical_id_seq'::regclass);


--
-- Name: aprobacion_en_terreno aprobacion_en_terreno_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobacion_en_terreno
    ADD CONSTRAINT aprobacion_en_terreno_pkey PRIMARY KEY (id);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: bloqueo_temporal bloqueo_temporal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloqueo_temporal
    ADD CONSTRAINT bloqueo_temporal_pkey PRIMARY KEY (id);


--
-- Name: cancelacion_servicio cancelacion_servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelacion_servicio
    ADD CONSTRAINT cancelacion_servicio_pkey PRIMARY KEY (id);


--
-- Name: cargo_gastos cargo_gastos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_gastos
    ADD CONSTRAINT cargo_gastos_pkey PRIMARY KEY (id);


--
-- Name: cargo_gastos cargo_gastos_servicio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_gastos
    ADD CONSTRAINT cargo_gastos_servicio_id_key UNIQUE (servicio_id);


--
-- Name: cargo_visita cargo_visita_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita
    ADD CONSTRAINT cargo_visita_pkey PRIMARY KEY (id);


--
-- Name: cargo_visita cargo_visita_servicio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita
    ADD CONSTRAINT cargo_visita_servicio_id_key UNIQUE (servicio_id);


--
-- Name: categoria_disputa categoria_disputa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categoria_disputa
    ADD CONSTRAINT categoria_disputa_pkey PRIMARY KEY (codigo);


--
-- Name: checklist_oficio_item checklist_oficio_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_oficio_item
    ADD CONSTRAINT checklist_oficio_item_pkey PRIMARY KEY (id);


--
-- Name: checklist_oficio_item checklist_oficio_item_vertical_id_orden_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_oficio_item
    ADD CONSTRAINT checklist_oficio_item_vertical_id_orden_key UNIQUE (vertical_id, orden);


--
-- Name: cobertura_vertical_comuna cobertura_vertical_comuna_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cobertura_vertical_comuna
    ADD CONSTRAINT cobertura_vertical_comuna_pkey PRIMARY KEY (vertical_id, comuna_id);


--
-- Name: codigo_cierre codigo_cierre_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigo_cierre
    ADD CONSTRAINT codigo_cierre_pkey PRIMARY KEY (id);


--
-- Name: codigo_cierre codigo_cierre_servicio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigo_cierre
    ADD CONSTRAINT codigo_cierre_servicio_id_key UNIQUE (servicio_id);


--
-- Name: comuna comuna_codigo_cut_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_codigo_cut_key UNIQUE (codigo_cut);


--
-- Name: comuna comuna_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_pkey PRIMARY KEY (id);


--
-- Name: consulta_adelanto consulta_adelanto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_adelanto
    ADD CONSTRAINT consulta_adelanto_pkey PRIMARY KEY (id);


--
-- Name: consulta_sec consulta_sec_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_sec
    ADD CONSTRAINT consulta_sec_pkey PRIMARY KEY (id);


--
-- Name: conversacion_soporte conversacion_soporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversacion_soporte
    ADD CONSTRAINT conversacion_soporte_pkey PRIMARY KEY (id);


--
-- Name: cotizacion cotizacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_pkey PRIMARY KEY (id);


--
-- Name: cotizacion cotizacion_servicio_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_servicio_id_key UNIQUE (servicio_id);


--
-- Name: dispositivo_push dispositivo_push_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivo_push
    ADD CONSTRAINT dispositivo_push_pkey PRIMARY KEY (id);


--
-- Name: dispositivo_push dispositivo_push_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivo_push
    ADD CONSTRAINT dispositivo_push_token_key UNIQUE (token);


--
-- Name: disputa_evidencia disputa_evidencia_disputa_id_orden_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa_evidencia
    ADD CONSTRAINT disputa_evidencia_disputa_id_orden_key UNIQUE (disputa_id, orden);


--
-- Name: disputa_evidencia disputa_evidencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa_evidencia
    ADD CONSTRAINT disputa_evidencia_pkey PRIMARY KEY (id);


--
-- Name: disputa disputa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_pkey PRIMARY KEY (id);


--
-- Name: evaluacion evaluacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluacion
    ADD CONSTRAINT evaluacion_pkey PRIMARY KEY (id);


--
-- Name: evaluacion evaluacion_servicio_id_evaluador_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluacion
    ADD CONSTRAINT evaluacion_servicio_id_evaluador_key UNIQUE (servicio_id, evaluador);


--
-- Name: evento_producto evento_producto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_pkey PRIMARY KEY (id);


--
-- Name: fotografia_servicio fotografia_servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotografia_servicio
    ADD CONSTRAINT fotografia_servicio_pkey PRIMARY KEY (id);


--
-- Name: hogar hogar_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hogar
    ADD CONSTRAINT hogar_pkey PRIMARY KEY (id);


--
-- Name: incumplimiento_uso incumplimiento_uso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incumplimiento_uso
    ADD CONSTRAINT incumplimiento_uso_pkey PRIMARY KEY (id);


--
-- Name: intento_sensible intento_sensible_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intento_sensible
    ADD CONSTRAINT intento_sensible_pkey PRIMARY KEY (id);


--
-- Name: interes_demanda interes_demanda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interes_demanda
    ADD CONSTRAINT interes_demanda_pkey PRIMARY KEY (id);


--
-- Name: llamada_ia llamada_ia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.llamada_ia
    ADD CONSTRAINT llamada_ia_pkey PRIMARY KEY (id);


--
-- Name: mensaje_lectura mensaje_lectura_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_lectura
    ADD CONSTRAINT mensaje_lectura_pkey PRIMARY KEY (servicio_id, usuario_id);


--
-- Name: mensaje mensaje_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje
    ADD CONSTRAINT mensaje_pkey PRIMARY KEY (id);


--
-- Name: mensaje_soporte mensaje_soporte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_soporte
    ADD CONSTRAINT mensaje_soporte_pkey PRIMARY KEY (id);


--
-- Name: modalidad modalidad_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modalidad
    ADD CONSTRAINT modalidad_codigo_key UNIQUE (codigo);


--
-- Name: modalidad modalidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modalidad
    ADD CONSTRAINT modalidad_pkey PRIMARY KEY (id);


--
-- Name: oferta_difusion oferta_difusion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oferta_difusion
    ADD CONSTRAINT oferta_difusion_pkey PRIMARY KEY (id);


--
-- Name: oferta_difusion oferta_difusion_publicacion_id_prestador_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oferta_difusion
    ADD CONSTRAINT oferta_difusion_publicacion_id_prestador_id_key UNIQUE (publicacion_id, prestador_id);


--
-- Name: pago pago_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: pago pago_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_pkey PRIMARY KEY (id);


--
-- Name: parametro_operacion parametro_operacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parametro_operacion
    ADD CONSTRAINT parametro_operacion_pkey PRIMARY KEY (clave);


--
-- Name: prestador_cobertura_comuna prestador_cobertura_comuna_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_cobertura_comuna
    ADD CONSTRAINT prestador_cobertura_comuna_pkey PRIMARY KEY (prestador_id, comuna_id);


--
-- Name: prestador_disponibilidad prestador_disponibilidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_disponibilidad
    ADD CONSTRAINT prestador_disponibilidad_pkey PRIMARY KEY (id);


--
-- Name: prestador_disponibilidad prestador_disponibilidad_prestador_id_vertical_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_disponibilidad
    ADD CONSTRAINT prestador_disponibilidad_prestador_id_vertical_id_key UNIQUE (prestador_id, vertical_id);


--
-- Name: prestador prestador_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador
    ADD CONSTRAINT prestador_pkey PRIMARY KEY (id);


--
-- Name: prestador prestador_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador
    ADD CONSTRAINT prestador_usuario_id_key UNIQUE (usuario_id);


--
-- Name: propuesta_cambio_hora propuesta_cambio_hora_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propuesta_cambio_hora
    ADD CONSTRAINT propuesta_cambio_hora_pkey PRIMARY KEY (id);


--
-- Name: publicacion publicacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicacion
    ADD CONSTRAINT publicacion_pkey PRIMARY KEY (id);


--
-- Name: publicacion publicacion_solicitud_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicacion
    ADD CONSTRAINT publicacion_solicitud_id_key UNIQUE (solicitud_id);


--
-- Name: referencia_precio referencia_precio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio
    ADD CONSTRAINT referencia_precio_pkey PRIMARY KEY (id);


--
-- Name: regla_precio regla_precio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio
    ADD CONSTRAINT regla_precio_pkey PRIMARY KEY (id);


--
-- Name: restablecimiento_contrasena restablecimiento_contrasena_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restablecimiento_contrasena
    ADD CONSTRAINT restablecimiento_contrasena_pkey PRIMARY KEY (id);


--
-- Name: servicio_checklist_marca servicio_checklist_marca_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_checklist_marca
    ADD CONSTRAINT servicio_checklist_marca_pkey PRIMARY KEY (servicio_id, item_id);


--
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id);


--
-- Name: sesion sesion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sesion
    ADD CONSTRAINT sesion_pkey PRIMARY KEY (id);


--
-- Name: sesion sesion_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sesion
    ADD CONSTRAINT sesion_token_hash_key UNIQUE (token_hash);


--
-- Name: solicitud_fotografia solicitud_fotografia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_fotografia
    ADD CONSTRAINT solicitud_fotografia_pkey PRIMARY KEY (id);


--
-- Name: solicitud solicitud_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_pkey PRIMARY KEY (id);


--
-- Name: solicitud_registro solicitud_registro_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_registro
    ADD CONSTRAINT solicitud_registro_pkey PRIMARY KEY (id);


--
-- Name: tipo_ambiente tipo_ambiente_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_ambiente
    ADD CONSTRAINT tipo_ambiente_pkey PRIMARY KEY (id);


--
-- Name: tipo_problema tipo_problema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_problema
    ADD CONSTRAINT tipo_problema_pkey PRIMARY KEY (id);


--
-- Name: mensaje uq_mensaje_autor_clave_envio; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje
    ADD CONSTRAINT uq_mensaje_autor_clave_envio UNIQUE (autor_id, clave_envio);


--
-- Name: referencia_precio uq_referencia_precio_alcance_origen; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio
    ADD CONSTRAINT uq_referencia_precio_alcance_origen UNIQUE NULLS NOT DISTINCT (vertical_id, modalidad_id, comuna_id, origen);


--
-- Name: tipo_ambiente uq_tipo_ambiente_vertical_codigo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_ambiente
    ADD CONSTRAINT uq_tipo_ambiente_vertical_codigo UNIQUE (vertical_id, codigo);


--
-- Name: tipo_problema uq_tipo_problema_vertical_codigo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_problema
    ADD CONSTRAINT uq_tipo_problema_vertical_codigo UNIQUE (vertical_id, codigo);


--
-- Name: usuario uq_usuario_rut; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT uq_usuario_rut UNIQUE (rut);


--
-- Name: verificacion_capa uq_verificacion_capa_usuario_capa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_capa
    ADD CONSTRAINT uq_verificacion_capa_usuario_capa UNIQUE (usuario_id, capa);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario_rol usuario_rol_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_pkey PRIMARY KEY (usuario_id, rol);


--
-- Name: usuario usuario_telefono_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_telefono_key UNIQUE (telefono);


--
-- Name: hogar ux_hogar_cliente_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hogar
    ADD CONSTRAINT ux_hogar_cliente_id UNIQUE (cliente_id, id);


--
-- Name: regla_precio ux_regla_precio_alcance; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio
    ADD CONSTRAINT ux_regla_precio_alcance UNIQUE NULLS NOT DISTINCT (vertical_id, comuna_id, modalidad_id, version);


--
-- Name: solicitud_fotografia ux_solicitud_fotografia_objeto; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_fotografia
    ADD CONSTRAINT ux_solicitud_fotografia_objeto UNIQUE (solicitud_id, storage_key);


--
-- Name: verificacion_canal verificacion_canal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_canal
    ADD CONSTRAINT verificacion_canal_pkey PRIMARY KEY (id);


--
-- Name: verificacion_capa verificacion_capa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_capa
    ADD CONSTRAINT verificacion_capa_pkey PRIMARY KEY (id);


--
-- Name: vertical vertical_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical
    ADD CONSTRAINT vertical_codigo_key UNIQUE (codigo);


--
-- Name: vertical_modalidad vertical_modalidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical_modalidad
    ADD CONSTRAINT vertical_modalidad_pkey PRIMARY KEY (vertical_id, modalidad_id);


--
-- Name: vertical vertical_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical
    ADD CONSTRAINT vertical_pkey PRIMARY KEY (id);


--
-- Name: idx_aprobacion_en_terreno_revision_manual; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aprobacion_en_terreno_revision_manual ON public.aprobacion_en_terreno USING btree (servicio_id) WHERE (validacion_estado = 'revision_manual'::text);


--
-- Name: idx_aprobacion_en_terreno_servicio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aprobacion_en_terreno_servicio ON public.aprobacion_en_terreno USING btree (servicio_id, estado);


--
-- Name: idx_aprobacion_en_terreno_vencimiento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aprobacion_en_terreno_vencimiento ON public.aprobacion_en_terreno USING btree (vence_en) WHERE ((estado = 'propuesta'::text) AND (vence_en IS NOT NULL));


--
-- Name: idx_auditoria_actor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_actor ON public.auditoria USING btree (actor_id, ocurrido_en DESC);


--
-- Name: idx_auditoria_entidad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_entidad ON public.auditoria USING btree (entidad, entidad_id, ocurrido_en DESC);


--
-- Name: idx_bloqueo_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bloqueo_vigente ON public.bloqueo_temporal USING btree (usuario_id, vigente_hasta);


--
-- Name: idx_cancelacion_por_servicio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancelacion_por_servicio ON public.cancelacion_servicio USING btree (servicio_id);


--
-- Name: idx_cobertura_comuna; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cobertura_comuna ON public.prestador_cobertura_comuna USING btree (comuna_id, activa);


--
-- Name: idx_cobertura_vertical_comuna_inverso; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cobertura_vertical_comuna_inverso ON public.cobertura_vertical_comuna USING btree (comuna_id, activo);


--
-- Name: idx_comuna_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comuna_geom ON public.comuna USING gist (geom);


--
-- Name: idx_comuna_visible_operativa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comuna_visible_operativa ON public.comuna USING btree (visible, operativa);


--
-- Name: idx_consulta_sec_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_consulta_sec_usuario ON public.consulta_sec USING btree (usuario_id, consultado_en);


--
-- Name: idx_conversacion_soporte_derivadas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversacion_soporte_derivadas ON public.conversacion_soporte USING btree (derivada_en) WHERE (estado = 'derivada'::text);


--
-- Name: idx_conversacion_soporte_viva; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_conversacion_soporte_viva ON public.conversacion_soporte USING btree (usuario_id) WHERE (estado <> 'cerrada'::text);


--
-- Name: idx_disponibilidad; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_disponibilidad ON public.prestador_disponibilidad USING btree (vertical_id, disponible);


--
-- Name: idx_dispositivo_push_usuario_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispositivo_push_usuario_vigente ON public.dispositivo_push USING btree (usuario_id) WHERE (invalidado_en IS NULL);


--
-- Name: idx_disputa_asignada; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_disputa_asignada ON public.disputa USING btree (asignada_a, estado);


--
-- Name: idx_disputa_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_disputa_estado ON public.disputa USING btree (estado, sla_vence_en);


--
-- Name: idx_evento_producto_comuna; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_producto_comuna ON public.evento_producto USING btree (comuna_id, vertical_id);


--
-- Name: idx_evento_producto_solicitud; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_producto_solicitud ON public.evento_producto USING btree (solicitud_id);


--
-- Name: idx_evento_producto_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_producto_tipo ON public.evento_producto USING btree (tipo, ocurrido_en);


--
-- Name: idx_evento_producto_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evento_producto_usuario ON public.evento_producto USING btree (usuario_id, tipo);


--
-- Name: idx_hogar_cliente_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hogar_cliente_vigente ON public.hogar USING btree (cliente_id) WHERE (archivado_en IS NULL);


--
-- Name: idx_hogar_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hogar_geom ON public.hogar USING gist (geom_punto);


--
-- Name: idx_incumplimiento_uso_usuario_creado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incumplimiento_uso_usuario_creado ON public.incumplimiento_uso USING btree (usuario_id, creado_en);


--
-- Name: idx_intento_sensible_ventana; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_intento_sensible_ventana ON public.intento_sensible USING btree (accion, clave, ocurrido_en DESC);


--
-- Name: idx_interes_demanda_de_la_cuenta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interes_demanda_de_la_cuenta ON public.interes_demanda USING btree (usuario_id) WHERE (retirado_en IS NULL);


--
-- Name: idx_interes_demanda_tablero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interes_demanda_tablero ON public.interes_demanda USING btree (vertical_id, comuna_id) WHERE (retirado_en IS NULL);


--
-- Name: idx_interes_demanda_vigente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_interes_demanda_vigente ON public.interes_demanda USING btree (usuario_id, vertical_id, comuna_id) NULLS NOT DISTINCT WHERE (retirado_en IS NULL);


--
-- Name: idx_llamada_ia_creada_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_llamada_ia_creada_en ON public.llamada_ia USING btree (creada_en);


--
-- Name: idx_llamada_ia_usuario_creada_en; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_llamada_ia_usuario_creada_en ON public.llamada_ia USING btree (usuario_id, creada_en) WHERE (usuario_id IS NOT NULL);


--
-- Name: idx_mensaje_autor_creado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensaje_autor_creado ON public.mensaje USING btree (autor_id, creado_en);


--
-- Name: idx_mensaje_servicio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensaje_servicio_id ON public.mensaje USING btree (servicio_id, id);


--
-- Name: idx_mensaje_soporte_conversacion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mensaje_soporte_conversacion ON public.mensaje_soporte USING btree (conversacion_id, creado_en);


--
-- Name: idx_oferta_elegida; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_oferta_elegida ON public.oferta_difusion USING btree (publicacion_id) WHERE (estado = 'elegida'::text);


--
-- Name: idx_oferta_por_prestador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_oferta_por_prestador ON public.oferta_difusion USING btree (prestador_id, estado);


--
-- Name: idx_pago_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pago_estado ON public.pago USING btree (estado_pago, creado_en);


--
-- Name: idx_regla_precio_vigencia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_regla_precio_vigencia ON public.regla_precio USING btree (vigencia_desde DESC, vigencia_hasta);


--
-- Name: idx_servicio_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicio_estado ON public.servicio USING btree (estado, creado_en);


--
-- Name: idx_servicio_prestador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicio_prestador ON public.servicio USING btree (prestador_id, estado, creado_en DESC);


--
-- Name: idx_sesion_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sesion_usuario ON public.sesion USING btree (usuario_id, expira_en DESC);


--
-- Name: idx_solicitud_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_solicitud_cliente ON public.solicitud USING btree (cliente_id, creado_en DESC);


--
-- Name: idx_solicitud_fotografia_solicitud; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_solicitud_fotografia_solicitud ON public.solicitud_fotografia USING btree (solicitud_id, orden);


--
-- Name: idx_solicitud_registro_bandeja; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_solicitud_registro_bandeja ON public.solicitud_registro USING btree (tipo, estado, creado_en DESC);


--
-- Name: idx_solicitud_tipo_problema; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_solicitud_tipo_problema ON public.solicitud USING btree (tipo_problema_id);


--
-- Name: idx_solicitud_vertical; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_solicitud_vertical ON public.solicitud USING btree (vertical_id, creado_en DESC);


--
-- Name: idx_tipo_ambiente_vertical; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tipo_ambiente_vertical ON public.tipo_ambiente USING btree (vertical_id);


--
-- Name: idx_tipo_problema_vertical; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tipo_problema_vertical ON public.tipo_problema USING btree (vertical_id);


--
-- Name: idx_usuario_rol_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuario_rol_rol ON public.usuario_rol USING btree (rol);


--
-- Name: idx_verificacion_capa_pendientes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verificacion_capa_pendientes ON public.verificacion_capa USING btree (enviada_en) WHERE (estado = 'pendiente'::text);


--
-- Name: idx_verificacion_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verificacion_usuario ON public.verificacion_canal USING btree (usuario_id, creado_en DESC);


--
-- Name: ix_consulta_adelanto_servicio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_consulta_adelanto_servicio ON public.consulta_adelanto USING btree (servicio_id, creada_en, id);


--
-- Name: ix_fotografia_servicio_servicio_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_fotografia_servicio_servicio_id ON public.fotografia_servicio USING btree (servicio_id);


--
-- Name: ix_propuesta_cambio_hora_servicio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_propuesta_cambio_hora_servicio ON public.propuesta_cambio_hora USING btree (servicio_id, creada_en, id);


--
-- Name: uq_disputa_abierta_por_servicio; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_disputa_abierta_por_servicio ON public.disputa USING btree (servicio_id) WHERE (estado <> 'resuelta'::text);


--
-- Name: uq_evento_producto_servicio_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_evento_producto_servicio_tipo ON public.evento_producto USING btree (servicio_id, tipo) WHERE (servicio_id IS NOT NULL);


--
-- Name: ux_consulta_adelanto_una_pendiente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_consulta_adelanto_una_pendiente ON public.consulta_adelanto USING btree (servicio_id) WHERE (estado = 'pendiente'::text);


--
-- Name: ux_hogar_principal_por_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_hogar_principal_por_cliente ON public.hogar USING btree (cliente_id) WHERE (principal AND (archivado_en IS NULL));


--
-- Name: ux_pago_servicio_orden; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_pago_servicio_orden ON public.pago USING btree (servicio_id, orden);


--
-- Name: ux_propuesta_cambio_hora_una_pendiente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_propuesta_cambio_hora_una_pendiente ON public.propuesta_cambio_hora USING btree (servicio_id) WHERE (estado = 'pendiente'::text);


--
-- Name: ux_restablecimiento_contrasena_vivo; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_restablecimiento_contrasena_vivo ON public.restablecimiento_contrasena USING btree (usuario_id) WHERE (usado_en IS NULL);


--
-- Name: ux_servicio_solicitud; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_servicio_solicitud ON public.servicio USING btree (solicitud_id) WHERE (estado <> 'cancelada'::public.estado_servicio);


--
-- Name: ux_solicitud_registro_pendiente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_solicitud_registro_pendiente ON public.solicitud_registro USING btree (usuario_id, tipo) WHERE (estado = 'pendiente'::text);


--
-- Name: ux_verificacion_viva; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_verificacion_viva ON public.verificacion_canal USING btree (usuario_id) WHERE (verificado_en IS NULL);


--
-- Name: auditoria trg_auditoria_sin_modificar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_sin_modificar BEFORE DELETE OR UPDATE ON public.auditoria FOR EACH ROW EXECUTE FUNCTION public.auditoria_es_de_solo_escritura();


--
-- Name: auditoria trg_auditoria_sin_truncar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_auditoria_sin_truncar BEFORE TRUNCATE ON public.auditoria FOR EACH STATEMENT EXECUTE FUNCTION public.auditoria_es_de_solo_escritura();


--
-- Name: mensaje trg_aviso_mensaje; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_mensaje AFTER INSERT ON public.mensaje FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_mensajes();


--
-- Name: mensaje_lectura trg_aviso_mensaje_lectura; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_mensaje_lectura AFTER INSERT OR UPDATE ON public.mensaje_lectura FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_mensajes();


--
-- Name: servicio trg_aviso_servicio; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio AFTER INSERT OR UPDATE ON public.servicio FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio();


--
-- Name: aprobacion_en_terreno trg_aviso_servicio_aprobacion_en_terreno; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_aprobacion_en_terreno AFTER INSERT OR DELETE OR UPDATE ON public.aprobacion_en_terreno FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: cancelacion_servicio trg_aviso_servicio_cancelacion_servicio; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_cancelacion_servicio AFTER INSERT OR DELETE OR UPDATE ON public.cancelacion_servicio FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: cargo_gastos trg_aviso_servicio_cargo_gastos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_cargo_gastos AFTER INSERT OR DELETE OR UPDATE ON public.cargo_gastos FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: cargo_visita trg_aviso_servicio_cargo_visita; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_cargo_visita AFTER INSERT OR DELETE OR UPDATE ON public.cargo_visita FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: codigo_cierre trg_aviso_servicio_codigo_cierre; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_codigo_cierre AFTER INSERT OR DELETE OR UPDATE ON public.codigo_cierre FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: consulta_adelanto trg_aviso_servicio_consulta_adelanto; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_consulta_adelanto AFTER INSERT OR DELETE OR UPDATE ON public.consulta_adelanto FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: cotizacion trg_aviso_servicio_cotizacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_cotizacion AFTER INSERT OR DELETE OR UPDATE ON public.cotizacion FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: disputa trg_aviso_servicio_disputa; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_disputa AFTER INSERT OR DELETE OR UPDATE ON public.disputa FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: disputa_evidencia trg_aviso_servicio_disputa_evidencia; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_disputa_evidencia AFTER INSERT OR DELETE OR UPDATE ON public.disputa_evidencia FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_por_disputa();


--
-- Name: evaluacion trg_aviso_servicio_evaluacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_evaluacion AFTER INSERT OR DELETE OR UPDATE ON public.evaluacion FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: fotografia_servicio trg_aviso_servicio_fotografia_servicio; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_fotografia_servicio AFTER INSERT OR DELETE OR UPDATE ON public.fotografia_servicio FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: pago trg_aviso_servicio_pago; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_pago AFTER INSERT OR DELETE OR UPDATE ON public.pago FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: propuesta_cambio_hora trg_aviso_servicio_propuesta_cambio_hora; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_propuesta_cambio_hora AFTER INSERT OR DELETE OR UPDATE ON public.propuesta_cambio_hora FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: servicio_checklist_marca trg_aviso_servicio_servicio_checklist_marca; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_servicio_servicio_checklist_marca AFTER INSERT OR DELETE OR UPDATE ON public.servicio_checklist_marca FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_servicio_hijo();


--
-- Name: oferta_difusion trg_aviso_solicitud_oferta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_solicitud_oferta AFTER INSERT OR DELETE OR UPDATE ON public.oferta_difusion FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_solicitud_por_oferta();


--
-- Name: publicacion trg_aviso_solicitud_publicacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_aviso_solicitud_publicacion AFTER INSERT OR UPDATE ON public.publicacion FOR EACH ROW EXECUTE FUNCTION public.relwo_avisar_cambio_de_solicitud();


--
-- Name: evento_producto trg_evento_producto_sin_modificar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_evento_producto_sin_modificar BEFORE DELETE OR UPDATE ON public.evento_producto FOR EACH ROW EXECUTE FUNCTION public.evento_producto_es_de_solo_escritura();


--
-- Name: evento_producto trg_evento_producto_sin_truncar; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_evento_producto_sin_truncar BEFORE TRUNCATE ON public.evento_producto FOR EACH STATEMENT EXECUTE FUNCTION public.evento_producto_es_de_solo_escritura();


--
-- Name: servicio trg_servicio_estado_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_servicio_estado_insert BEFORE INSERT ON public.servicio FOR EACH ROW EXECUTE FUNCTION public.servicio_estado_solo_por_transicion();


--
-- Name: servicio trg_servicio_estado_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_servicio_estado_update BEFORE UPDATE OF estado ON public.servicio FOR EACH ROW EXECUTE FUNCTION public.servicio_estado_solo_por_transicion();


--
-- Name: aprobacion_en_terreno aprobacion_en_terreno_propuesta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobacion_en_terreno
    ADD CONSTRAINT aprobacion_en_terreno_propuesta_por_fkey FOREIGN KEY (propuesta_por) REFERENCES public.usuario(id);


--
-- Name: aprobacion_en_terreno aprobacion_en_terreno_respondida_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobacion_en_terreno
    ADD CONSTRAINT aprobacion_en_terreno_respondida_por_fkey FOREIGN KEY (respondida_por) REFERENCES public.usuario(id);


--
-- Name: aprobacion_en_terreno aprobacion_en_terreno_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobacion_en_terreno
    ADD CONSTRAINT aprobacion_en_terreno_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: auditoria auditoria_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.usuario(id);


--
-- Name: bloqueo_temporal bloqueo_temporal_levantado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloqueo_temporal
    ADD CONSTRAINT bloqueo_temporal_levantado_por_fkey FOREIGN KEY (levantado_por) REFERENCES public.usuario(id);


--
-- Name: bloqueo_temporal bloqueo_temporal_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bloqueo_temporal
    ADD CONSTRAINT bloqueo_temporal_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: cancelacion_servicio cancelacion_servicio_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelacion_servicio
    ADD CONSTRAINT cancelacion_servicio_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: cargo_gastos cargo_gastos_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_gastos
    ADD CONSTRAINT cargo_gastos_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: cargo_visita cargo_visita_eximido_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita
    ADD CONSTRAINT cargo_visita_eximido_por_fkey FOREIGN KEY (eximido_por) REFERENCES public.usuario(id);


--
-- Name: cargo_visita cargo_visita_oferta_difusion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita
    ADD CONSTRAINT cargo_visita_oferta_difusion_id_fkey FOREIGN KEY (oferta_difusion_id) REFERENCES public.oferta_difusion(id);


--
-- Name: cargo_visita cargo_visita_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cargo_visita
    ADD CONSTRAINT cargo_visita_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: checklist_oficio_item checklist_oficio_item_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.checklist_oficio_item
    ADD CONSTRAINT checklist_oficio_item_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: cobertura_vertical_comuna cobertura_vertical_comuna_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cobertura_vertical_comuna
    ADD CONSTRAINT cobertura_vertical_comuna_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: cobertura_vertical_comuna cobertura_vertical_comuna_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cobertura_vertical_comuna
    ADD CONSTRAINT cobertura_vertical_comuna_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: codigo_cierre codigo_cierre_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codigo_cierre
    ADD CONSTRAINT codigo_cierre_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: consulta_adelanto consulta_adelanto_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_adelanto
    ADD CONSTRAINT consulta_adelanto_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.usuario(id);


--
-- Name: consulta_adelanto consulta_adelanto_resuelta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_adelanto
    ADD CONSTRAINT consulta_adelanto_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES public.usuario(id);


--
-- Name: consulta_adelanto consulta_adelanto_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_adelanto
    ADD CONSTRAINT consulta_adelanto_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: consulta_sec consulta_sec_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_sec
    ADD CONSTRAINT consulta_sec_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: consulta_sec consulta_sec_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consulta_sec
    ADD CONSTRAINT consulta_sec_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: conversacion_soporte conversacion_soporte_cerrada_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversacion_soporte
    ADD CONSTRAINT conversacion_soporte_cerrada_por_fkey FOREIGN KEY (cerrada_por) REFERENCES public.usuario(id);


--
-- Name: conversacion_soporte conversacion_soporte_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversacion_soporte
    ADD CONSTRAINT conversacion_soporte_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: cotizacion cotizacion_regla_precio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_regla_precio_id_fkey FOREIGN KEY (regla_precio_id) REFERENCES public.regla_precio(id);


--
-- Name: cotizacion cotizacion_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cotizacion
    ADD CONSTRAINT cotizacion_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: dispositivo_push dispositivo_push_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispositivo_push
    ADD CONSTRAINT dispositivo_push_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;


--
-- Name: disputa disputa_abierta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_abierta_por_fkey FOREIGN KEY (abierta_por) REFERENCES public.usuario(id);


--
-- Name: disputa disputa_asignada_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_asignada_a_fkey FOREIGN KEY (asignada_a) REFERENCES public.usuario(id);


--
-- Name: disputa disputa_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_categoria_fkey FOREIGN KEY (categoria) REFERENCES public.categoria_disputa(codigo);


--
-- Name: disputa_evidencia disputa_evidencia_disputa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa_evidencia
    ADD CONSTRAINT disputa_evidencia_disputa_id_fkey FOREIGN KEY (disputa_id) REFERENCES public.disputa(id) ON DELETE CASCADE;


--
-- Name: disputa disputa_resuelto_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_resuelto_por_fkey FOREIGN KEY (resuelto_por) REFERENCES public.usuario(id);


--
-- Name: disputa disputa_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disputa
    ADD CONSTRAINT disputa_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: evaluacion evaluacion_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evaluacion
    ADD CONSTRAINT evaluacion_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: evento_producto evento_producto_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: evento_producto evento_producto_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: evento_producto evento_producto_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES public.solicitud(id);


--
-- Name: evento_producto evento_producto_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: evento_producto evento_producto_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_producto
    ADD CONSTRAINT evento_producto_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: mensaje fk_mensaje_consulta_adelanto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje
    ADD CONSTRAINT fk_mensaje_consulta_adelanto FOREIGN KEY (consulta_adelanto_id) REFERENCES public.consulta_adelanto(id);


--
-- Name: solicitud fk_solicitud_hogar_del_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT fk_solicitud_hogar_del_cliente FOREIGN KEY (cliente_id, hogar_id) REFERENCES public.hogar(cliente_id, id);


--
-- Name: solicitud fk_solicitud_modalidad_del_vertical; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT fk_solicitud_modalidad_del_vertical FOREIGN KEY (vertical_id, modalidad_id) REFERENCES public.vertical_modalidad(vertical_id, modalidad_id);


--
-- Name: fotografia_servicio fotografia_servicio_prestador_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotografia_servicio
    ADD CONSTRAINT fotografia_servicio_prestador_usuario_id_fkey FOREIGN KEY (prestador_usuario_id) REFERENCES public.usuario(id);


--
-- Name: fotografia_servicio fotografia_servicio_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotografia_servicio
    ADD CONSTRAINT fotografia_servicio_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id) ON DELETE CASCADE;


--
-- Name: hogar hogar_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hogar
    ADD CONSTRAINT hogar_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.usuario(id);


--
-- Name: hogar hogar_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hogar
    ADD CONSTRAINT hogar_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: incumplimiento_uso incumplimiento_uso_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incumplimiento_uso
    ADD CONSTRAINT incumplimiento_uso_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: incumplimiento_uso incumplimiento_uso_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incumplimiento_uso
    ADD CONSTRAINT incumplimiento_uso_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: interes_demanda interes_demanda_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interes_demanda
    ADD CONSTRAINT interes_demanda_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: interes_demanda interes_demanda_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interes_demanda
    ADD CONSTRAINT interes_demanda_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: interes_demanda interes_demanda_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interes_demanda
    ADD CONSTRAINT interes_demanda_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: llamada_ia llamada_ia_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.llamada_ia
    ADD CONSTRAINT llamada_ia_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: mensaje mensaje_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje
    ADD CONSTRAINT mensaje_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.usuario(id);


--
-- Name: mensaje_lectura mensaje_lectura_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_lectura
    ADD CONSTRAINT mensaje_lectura_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: mensaje_lectura mensaje_lectura_ultimo_mensaje_leido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_lectura
    ADD CONSTRAINT mensaje_lectura_ultimo_mensaje_leido_id_fkey FOREIGN KEY (ultimo_mensaje_leido_id) REFERENCES public.mensaje(id);


--
-- Name: mensaje_lectura mensaje_lectura_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_lectura
    ADD CONSTRAINT mensaje_lectura_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: mensaje mensaje_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje
    ADD CONSTRAINT mensaje_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: mensaje_soporte mensaje_soporte_autor_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_soporte
    ADD CONSTRAINT mensaje_soporte_autor_usuario_id_fkey FOREIGN KEY (autor_usuario_id) REFERENCES public.usuario(id);


--
-- Name: mensaje_soporte mensaje_soporte_conversacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mensaje_soporte
    ADD CONSTRAINT mensaje_soporte_conversacion_id_fkey FOREIGN KEY (conversacion_id) REFERENCES public.conversacion_soporte(id);


--
-- Name: oferta_difusion oferta_difusion_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oferta_difusion
    ADD CONSTRAINT oferta_difusion_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestador(id);


--
-- Name: oferta_difusion oferta_difusion_publicacion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oferta_difusion
    ADD CONSTRAINT oferta_difusion_publicacion_id_fkey FOREIGN KEY (publicacion_id) REFERENCES public.publicacion(id);


--
-- Name: pago pago_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pago
    ADD CONSTRAINT pago_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: parametro_operacion parametro_operacion_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parametro_operacion
    ADD CONSTRAINT parametro_operacion_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuario(id);


--
-- Name: prestador_cobertura_comuna prestador_cobertura_comuna_aprobada_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_cobertura_comuna
    ADD CONSTRAINT prestador_cobertura_comuna_aprobada_por_fkey FOREIGN KEY (aprobada_por) REFERENCES public.usuario(id);


--
-- Name: prestador_cobertura_comuna prestador_cobertura_comuna_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_cobertura_comuna
    ADD CONSTRAINT prestador_cobertura_comuna_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: prestador_cobertura_comuna prestador_cobertura_comuna_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_cobertura_comuna
    ADD CONSTRAINT prestador_cobertura_comuna_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestador(id);


--
-- Name: prestador_disponibilidad prestador_disponibilidad_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_disponibilidad
    ADD CONSTRAINT prestador_disponibilidad_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestador(id);


--
-- Name: prestador_disponibilidad prestador_disponibilidad_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador_disponibilidad
    ADD CONSTRAINT prestador_disponibilidad_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: prestador prestador_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestador
    ADD CONSTRAINT prestador_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: propuesta_cambio_hora propuesta_cambio_hora_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propuesta_cambio_hora
    ADD CONSTRAINT propuesta_cambio_hora_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.usuario(id);


--
-- Name: propuesta_cambio_hora propuesta_cambio_hora_resuelta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propuesta_cambio_hora
    ADD CONSTRAINT propuesta_cambio_hora_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES public.usuario(id);


--
-- Name: propuesta_cambio_hora propuesta_cambio_hora_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.propuesta_cambio_hora
    ADD CONSTRAINT propuesta_cambio_hora_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id);


--
-- Name: publicacion publicacion_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicacion
    ADD CONSTRAINT publicacion_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES public.solicitud(id);


--
-- Name: referencia_precio referencia_precio_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio
    ADD CONSTRAINT referencia_precio_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: referencia_precio referencia_precio_modalidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio
    ADD CONSTRAINT referencia_precio_modalidad_id_fkey FOREIGN KEY (modalidad_id) REFERENCES public.modalidad(id);


--
-- Name: referencia_precio referencia_precio_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.referencia_precio
    ADD CONSTRAINT referencia_precio_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: regla_precio regla_precio_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio
    ADD CONSTRAINT regla_precio_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id);


--
-- Name: regla_precio regla_precio_modalidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio
    ADD CONSTRAINT regla_precio_modalidad_id_fkey FOREIGN KEY (modalidad_id) REFERENCES public.modalidad(id);


--
-- Name: regla_precio regla_precio_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regla_precio
    ADD CONSTRAINT regla_precio_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: restablecimiento_contrasena restablecimiento_contrasena_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restablecimiento_contrasena
    ADD CONSTRAINT restablecimiento_contrasena_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;


--
-- Name: servicio_checklist_marca servicio_checklist_marca_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_checklist_marca
    ADD CONSTRAINT servicio_checklist_marca_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.checklist_oficio_item(id);


--
-- Name: servicio_checklist_marca servicio_checklist_marca_servicio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio_checklist_marca
    ADD CONSTRAINT servicio_checklist_marca_servicio_id_fkey FOREIGN KEY (servicio_id) REFERENCES public.servicio(id) ON DELETE CASCADE;


--
-- Name: servicio servicio_llegada_confirmada_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_llegada_confirmada_por_fkey FOREIGN KEY (llegada_confirmada_por) REFERENCES public.usuario(id);


--
-- Name: servicio servicio_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestador(id);


--
-- Name: servicio servicio_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicio
    ADD CONSTRAINT servicio_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES public.solicitud(id);


--
-- Name: sesion sesion_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sesion
    ADD CONSTRAINT sesion_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;


--
-- Name: solicitud solicitud_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.usuario(id);


--
-- Name: solicitud_fotografia solicitud_fotografia_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_fotografia
    ADD CONSTRAINT solicitud_fotografia_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES public.solicitud(id) ON DELETE CASCADE;


--
-- Name: solicitud solicitud_hogar_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_hogar_id_fkey FOREIGN KEY (hogar_id) REFERENCES public.hogar(id);


--
-- Name: solicitud solicitud_modalidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_modalidad_id_fkey FOREIGN KEY (modalidad_id) REFERENCES public.modalidad(id);


--
-- Name: solicitud_registro solicitud_registro_resuelta_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_registro
    ADD CONSTRAINT solicitud_registro_resuelta_por_fkey FOREIGN KEY (resuelta_por) REFERENCES public.usuario(id);


--
-- Name: solicitud_registro solicitud_registro_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud_registro
    ADD CONSTRAINT solicitud_registro_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: solicitud solicitud_tipo_problema_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_tipo_problema_id_fkey FOREIGN KEY (tipo_problema_id) REFERENCES public.tipo_problema(id);


--
-- Name: solicitud solicitud_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT solicitud_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: tipo_ambiente tipo_ambiente_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_ambiente
    ADD CONSTRAINT tipo_ambiente_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: tipo_problema tipo_problema_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_problema
    ADD CONSTRAINT tipo_problema_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- Name: usuario_rol usuario_rol_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_rol
    ADD CONSTRAINT usuario_rol_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: verificacion_canal verificacion_canal_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_canal
    ADD CONSTRAINT verificacion_canal_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id) ON DELETE CASCADE;


--
-- Name: verificacion_capa verificacion_capa_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_capa
    ADD CONSTRAINT verificacion_capa_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: verificacion_capa verificacion_capa_verificado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verificacion_capa
    ADD CONSTRAINT verificacion_capa_verificado_por_fkey FOREIGN KEY (verificado_por) REFERENCES public.usuario(id);


--
-- Name: vertical_modalidad vertical_modalidad_modalidad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical_modalidad
    ADD CONSTRAINT vertical_modalidad_modalidad_id_fkey FOREIGN KEY (modalidad_id) REFERENCES public.modalidad(id);


--
-- Name: vertical_modalidad vertical_modalidad_vertical_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vertical_modalidad
    ADD CONSTRAINT vertical_modalidad_vertical_id_fkey FOREIGN KEY (vertical_id) REFERENCES public.vertical(id);


--
-- PostgreSQL database dump complete
--



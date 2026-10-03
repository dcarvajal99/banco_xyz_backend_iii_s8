-- Resultado de la migracion de bank_legacy_data (semanas 1 a 3): pg_dump del esquema public de la base de la semana 6
-- (carga semana_3, ejecucion COMPLETED). Se carga con scripts/preparar_base.sh.
--
-- PostgreSQL database dump
--

\restrict qBrkEt5Sn3VMCBgz9qRzS7UONBtstAVtX2QrccSaPFneQ2blJpDUsUf9bcFFvDn

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
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: batch_job_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_job_execution (
    job_execution_id bigint NOT NULL,
    version bigint,
    job_instance_id bigint NOT NULL,
    create_time timestamp without time zone NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    status character varying(10),
    exit_code character varying(2500),
    exit_message character varying(2500),
    last_updated timestamp without time zone
);


--
-- Name: batch_job_execution_context; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_job_execution_context (
    job_execution_id bigint NOT NULL,
    short_context character varying(2500) NOT NULL,
    serialized_context text
);


--
-- Name: batch_job_execution_params; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_job_execution_params (
    job_execution_id bigint NOT NULL,
    parameter_name character varying(100) NOT NULL,
    parameter_type character varying(100) NOT NULL,
    parameter_value character varying(2500),
    identifying character(1) NOT NULL
);


--
-- Name: batch_job_execution_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batch_job_execution_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_job_instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_job_instance (
    job_instance_id bigint NOT NULL,
    version bigint,
    job_name character varying(100) NOT NULL,
    job_key character varying(32) NOT NULL
);


--
-- Name: batch_job_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batch_job_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_step_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_step_execution (
    step_execution_id bigint NOT NULL,
    version bigint NOT NULL,
    step_name character varying(100) NOT NULL,
    job_execution_id bigint NOT NULL,
    create_time timestamp without time zone NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    status character varying(10),
    commit_count bigint,
    read_count bigint,
    filter_count bigint,
    write_count bigint,
    read_skip_count bigint,
    write_skip_count bigint,
    process_skip_count bigint,
    rollback_count bigint,
    exit_code character varying(2500),
    exit_message character varying(2500),
    last_updated timestamp without time zone
);


--
-- Name: batch_step_execution_context; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batch_step_execution_context (
    step_execution_id bigint NOT NULL,
    short_context character varying(2500) NOT NULL,
    serialized_context text
);


--
-- Name: batch_step_execution_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batch_step_execution_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cuenta_interes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cuenta_interes (
    id bigint NOT NULL,
    anomalia boolean NOT NULL,
    cuenta_id bigint NOT NULL,
    edad integer NOT NULL,
    interes numeric(18,2) NOT NULL,
    job_execution_id bigint NOT NULL,
    nombre character varying(120) NOT NULL,
    observacion character varying(255),
    procesado_en timestamp(6) without time zone NOT NULL,
    saldo_final numeric(18,2) NOT NULL,
    saldo_inicial numeric(18,2) NOT NULL,
    tasa_mensual numeric(8,5) NOT NULL,
    tipo character varying(20) NOT NULL
);


--
-- Name: cuenta_interes_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cuenta_interes_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estado_cuenta_anual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estado_cuenta_anual (
    id bigint NOT NULL,
    anio integer NOT NULL,
    cantidad_movimientos bigint NOT NULL,
    cuenta_id bigint NOT NULL,
    generado_en timestamp(6) without time zone NOT NULL,
    job_execution_id bigint NOT NULL,
    movimientos_con_anomalia bigint NOT NULL,
    primera_fecha date,
    saldo_neto numeric(18,2) NOT NULL,
    total_cargos numeric(18,2) NOT NULL,
    total_depositos numeric(18,2) NOT NULL,
    ultima_fecha date
);


--
-- Name: estado_cuenta_anual_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estado_cuenta_anual_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movimiento_anual; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimiento_anual (
    id bigint NOT NULL,
    anio integer NOT NULL,
    anomalia boolean NOT NULL,
    cuenta_id bigint NOT NULL,
    descripcion character varying(255) NOT NULL,
    fecha date NOT NULL,
    job_execution_id bigint NOT NULL,
    monto numeric(18,2) NOT NULL,
    observacion character varying(255),
    procesado_en timestamp(6) without time zone NOT NULL,
    tipo_transaccion character varying(20) NOT NULL
);


--
-- Name: movimiento_anual_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movimiento_anual_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: registro_rechazado; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.registro_rechazado (
    id bigint NOT NULL,
    archivo character varying(60) NOT NULL,
    clasificacion character varying(20) NOT NULL,
    contenido character varying(500) NOT NULL,
    job_execution_id bigint NOT NULL,
    job_nombre character varying(80) NOT NULL,
    motivo character varying(255) NOT NULL,
    numero_linea integer NOT NULL,
    registrado_en timestamp(6) without time zone NOT NULL
);


--
-- Name: registro_rechazado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.registro_rechazado_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: resumen_diario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resumen_diario (
    id bigint NOT NULL,
    cantidad_anomalias bigint NOT NULL,
    cantidad_transacciones bigint NOT NULL,
    fecha date NOT NULL,
    generado_en timestamp(6) without time zone NOT NULL,
    job_execution_id bigint NOT NULL,
    monto_maximo numeric(18,2) NOT NULL,
    total_creditos numeric(18,2) NOT NULL,
    total_debitos numeric(18,2) NOT NULL
);


--
-- Name: resumen_diario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.resumen_diario_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaccion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaccion (
    id bigint NOT NULL,
    anomalia boolean NOT NULL,
    fecha date NOT NULL,
    id_origen bigint NOT NULL,
    job_execution_id bigint NOT NULL,
    monto numeric(15,2) NOT NULL,
    observacion character varying(255),
    procesado_en timestamp(6) without time zone NOT NULL,
    tipo character varying(20) NOT NULL
);


--
-- Name: transaccion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaccion_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Data for Name: batch_job_execution; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_job_execution (job_execution_id, version, job_instance_id, create_time, start_time, end_time, status, exit_code, exit_message, last_updated) FROM stdin;
1	2	1	2026-09-20 21:44:16.78474	2026-09-20 21:44:16.808486	2026-09-20 21:44:19.178511	COMPLETED	COMPLETED		2026-09-20 21:44:19.193599
\.


--
-- Data for Name: batch_job_execution_context; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_job_execution_context (job_execution_id, short_context, serialized_context) FROM stdin;
1	{"@class":"java.util.HashMap","banco.tasaOmision":0.407,"banco.motivoCalidad":"Tasa de omision 40.7% sobre 3000 filas leidas (1221 omitidas). Umbrales: alerta 10.0%, rechazo 80.0%.","batch.version":"5.2.6","banco.veredictoCalidad":"CALIDAD_DEGRADADA"}	\N
\.


--
-- Data for Name: batch_job_execution_params; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_job_execution_params (job_execution_id, parameter_name, parameter_type, parameter_value, identifying) FROM stdin;
1	carpetaEntrada	java.lang.String	data/semana_3	Y
1	carpetaSalida	java.lang.String	salida	Y
1	ejecucion	java.lang.String	2026-09-20T21:44:16.768962	Y
\.


--
-- Data for Name: batch_job_instance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_job_instance (job_instance_id, version, job_name, job_key) FROM stdin;
1	0	migracionCompletaJob	c2aed37d82b75fb1427e7eafffd63047
\.


--
-- Data for Name: batch_step_execution; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_step_execution (step_execution_id, version, step_name, job_execution_id, create_time, start_time, end_time, status, commit_count, read_count, filter_count, write_count, read_skip_count, write_skip_count, process_skip_count, rollback_count, exit_code, exit_message, last_updated) FROM stdin;
5	3	exportarRechazadosStep	1	2026-09-20 21:44:18.984673	2026-09-20 21:44:18.986172	2026-09-20 21:44:19.067757	COMPLETED	1	0	0	1230	0	0	0	0	COMPLETED		2026-09-20 21:44:19.069316
1	3	limpiezaDeReintentoStep	1	2026-09-20 21:44:16.817051	2026-09-20 21:44:16.838919	2026-09-20 21:44:16.86968	COMPLETED	1	0	0	0	0	0	0	0	COMPLETED		2026-09-20 21:44:16.871631
6	3	cuarentenaAvisoStep	1	2026-09-20 21:44:19.074842	2026-09-20 21:44:19.076525	2026-09-20 21:44:19.080864	COMPLETED	1	0	0	1	0	0	0	0	COMPLETED		2026-09-20 21:44:19.081697
2	203	procesarMovimientosAnualesStep	1	2026-09-20 21:44:16.881127	2026-09-20 21:44:16.893834	2026-09-20 21:44:18.14424	COMPLETED	201	1000	0	952	0	0	48	48	COMPLETED		2026-09-20 21:44:18.151453
7	3	generarResumenDiarioStep	1	2026-09-20 21:44:19.092212	2026-09-20 21:44:19.093893	2026-09-20 21:44:19.127054	COMPLETED	1	0	0	267	0	0	0	0	COMPLETED		2026-09-20 21:44:19.128555
8	3	generarResumenInteresesStep	1	2026-09-20 21:44:19.132764	2026-09-20 21:44:19.134552	2026-09-20 21:44:19.145548	COMPLETED	1	0	0	327	0	0	0	0	COMPLETED		2026-09-20 21:44:19.146649
9	3	compilarEstadosCuentaStep	1	2026-09-20 21:44:19.150036	2026-09-20 21:44:19.151446	2026-09-20 21:44:19.175023	COMPLETED	1	0	0	20	0	0	0	0	COMPLETED		2026-09-20 21:44:19.176364
3	203	procesarInteresesStep	1	2026-09-20 21:44:16.881851	2026-09-20 21:44:16.894095	2026-09-20 21:44:18.978705	COMPLETED	201	1000	9	327	0	0	664	664	COMPLETED		2026-09-20 21:44:18.980295
4	203	procesarTransaccionesStep	1	2026-09-20 21:44:16.881831	2026-09-20 21:44:16.8942	2026-09-20 21:44:18.759766	COMPLETED	201	1000	0	491	0	0	509	509	COMPLETED		2026-09-20 21:44:18.7612
\.


--
-- Data for Name: batch_step_execution_context; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.batch_step_execution_context (step_execution_id, short_context, serialized_context) FROM stdin;
1	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.LimpiezaDeReintentoTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
2	{"@class":"java.util.HashMap","banco.itemsPorSegundo":"801.9","banco.repartoPorHilo":"batch-flujo-2=201","batch.taskletType":"org.springframework.batch.core.step.item.ChunkOrientedTasklet","banco.chunks":201,"banco.hilosUsados":1,"batch.version":"5.2.6","banco.pasoDeMigracion":"procesarMovimientosAnualesStep","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep","banco.tamanoChunk":5}	\N
4	{"@class":"java.util.HashMap","banco.itemsPorSegundo":"537.3","banco.repartoPorHilo":"batch-flujo-3=201","batch.taskletType":"org.springframework.batch.core.step.item.ChunkOrientedTasklet","banco.chunks":201,"banco.hilosUsados":1,"batch.version":"5.2.6","banco.pasoDeMigracion":"procesarTransaccionesStep","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep","banco.tamanoChunk":5}	\N
3	{"@class":"java.util.HashMap","banco.itemsPorSegundo":"480.5","banco.repartoPorHilo":"batch-flujo-1=201","batch.taskletType":"org.springframework.batch.core.step.item.ChunkOrientedTasklet","banco.chunks":201,"banco.hilosUsados":1,"batch.version":"5.2.6","banco.pasoDeMigracion":"procesarInteresesStep","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep","banco.tamanoChunk":5}	\N
5	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.ExportarRechazadosTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
6	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.CuarentenaCalidadTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
7	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.ResumenDiarioTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
8	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.ResumenInteresesTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
9	{"@class":"java.util.HashMap","batch.taskletType":"com.bancoxyz.batch.tasklet.EstadosCuentaAnualesTasklet","batch.version":"5.2.6","batch.stepType":"org.springframework.batch.core.step.tasklet.TaskletStep"}	\N
\.


--
-- Data for Name: cuenta_interes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cuenta_interes (id, anomalia, cuenta_id, edad, interes, job_execution_id, nombre, observacion, procesado_en, saldo_final, saldo_inicial, tasa_mensual, tipo) FROM stdin;
1	f	106	40	180.00	1	Jane Smith	\N	2026-09-20 21:44:16.929405	12180.00	12000.00	0.01500	prestamo
2	f	122	40	63.00	1	Bob Johnson	\N	2026-09-20 21:44:16.929504	7063.00	7000.00	0.00900	hipoteca
3	f	124	35	108.00	1	Bob Johnson	\N	2026-09-20 21:44:16.984727	12108.00	12000.00	0.00900	hipoteca
4	f	133	40	180.00	1	Steve Rogers	\N	2026-09-20 21:44:16.984923	12180.00	12000.00	0.01500	prestamo
5	f	130	45	108.00	1	Diana Prince	\N	2026-09-20 21:44:17.001221	12108.00	12000.00	0.00900	hipoteca
6	f	137	30	60.00	1	Steve Rogers	\N	2026-09-20 21:44:17.00128	12060.00	12000.00	0.00500	ahorro
7	f	127	30	25.00	1	Bob Johnson	\N	2026-09-20 21:44:17.001351	5025.00	5000.00	0.00500	ahorro
8	f	109	45	63.00	1	Charlie Green	\N	2026-09-20 21:44:17.034062	7063.00	7000.00	0.00900	hipoteca
9	f	113	45	150.00	1	Alice Brown	\N	2026-09-20 21:44:17.050971	10150.00	10000.00	0.01500	prestamo
10	f	111	30	75.00	1	Diana Prince	\N	2026-09-20 21:44:17.051062	5075.00	5000.00	0.01500	prestamo
11	f	105	25	150.00	1	Diana Prince	\N	2026-09-20 21:44:17.063152	10150.00	10000.00	0.01500	prestamo
12	t	143	30	60.00	1	Steve Rogers	Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.085681	12060.00	12000.00	0.00500	ahorro
13	t	133	45	90.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.085733	10090.00	10000.00	0.00900	hipoteca
14	f	136	40	45.00	1	Steve Rogers	\N	2026-09-20 21:44:17.108603	5045.00	5000.00	0.00900	hipoteca
15	t	133	40	120.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.108672	8120.00	8000.00	0.01500	prestamo
16	f	126	35	180.00	1	Bob Johnson	\N	2026-09-20 21:44:17.121782	12180.00	12000.00	0.01500	prestamo
17	f	118	40	120.00	1	John Doe	\N	2026-09-20 21:44:17.148419	8120.00	8000.00	0.01500	prestamo
18	f	108	45	120.00	1	John Doe	\N	2026-09-20 21:44:17.148451	8120.00	8000.00	0.01500	prestamo
19	t	122	25	180.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.163952	12180.00	12000.00	0.01500	prestamo
20	t	133	25	90.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.177231	10090.00	10000.00	0.00900	hipoteca
21	t	110	45	63.00	1	Charlie Green	Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.193583	7063.00	7000.00	0.00900	hipoteca
22	f	140	40	35.00	1	Steve Rogers	\N	2026-09-20 21:44:17.214856	7035.00	7000.00	0.00500	ahorro
23	f	128	35	40.00	1	Jane Smith	\N	2026-09-20 21:44:17.214874	8040.00	8000.00	0.00500	ahorro
24	t	106	40	63.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.230831	7063.00	7000.00	0.00900	hipoteca
25	t	132	30	90.00	1	Sin identificar	Titular sin identificar en el archivo legacy	2026-09-20 21:44:17.230856	10090.00	10000.00	0.00900	hipoteca
26	t	105	40	120.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.2673	8120.00	8000.00	0.01500	prestamo
27	t	111	35	45.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.282843	5045.00	5000.00	0.00900	hipoteca
28	f	134	30	150.00	1	Alice Brown	\N	2026-09-20 21:44:17.283182	10150.00	10000.00	0.01500	prestamo
29	t	124	25	150.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.283273	10150.00	10000.00	0.01500	prestamo
30	f	147	40	60.00	1	Alice Brown	\N	2026-09-20 21:44:17.283309	12060.00	12000.00	0.00500	ahorro
31	f	121	35	75.00	1	Steve Rogers	\N	2026-09-20 21:44:17.294713	5075.00	5000.00	0.01500	prestamo
32	t	106	30	35.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.424817	7035.00	7000.00	0.00500	ahorro
33	f	120	40	45.00	1	Jane Smith	\N	2026-09-20 21:44:17.424889	5045.00	5000.00	0.00900	hipoteca
34	t	130	45	75.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.438902	5075.00	5000.00	0.01500	prestamo
35	f	123	25	25.00	1	Bob Johnson	\N	2026-09-20 21:44:17.470487	5025.00	5000.00	0.00500	ahorro
36	f	141	35	40.00	1	Steve Rogers	\N	2026-09-20 21:44:17.470506	8040.00	8000.00	0.00500	ahorro
37	f	146	30	35.00	1	Charlie Green	\N	2026-09-20 21:44:17.470516	7035.00	7000.00	0.00500	ahorro
38	t	124	45	60.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.482276	12060.00	12000.00	0.00500	ahorro
39	f	112	25	72.00	1	Bob Johnson	\N	2026-09-20 21:44:17.482289	8072.00	8000.00	0.00900	hipoteca
40	t	116	25	180.00	1	Sin identificar	Titular sin identificar en el archivo legacy	2026-09-20 21:44:17.494382	12180.00	12000.00	0.01500	prestamo
41	t	107	30	108.00	1	Sin identificar	Titular sin identificar en el archivo legacy	2026-09-20 21:44:17.494394	12108.00	12000.00	0.00900	hipoteca
42	t	134	45	63.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.506985	7063.00	7000.00	0.00900	hipoteca
43	t	143	40	45.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.522103	5045.00	5000.00	0.00900	hipoteca
44	f	115	25	63.00	1	Steve Rogers	\N	2026-09-20 21:44:17.522114	7063.00	7000.00	0.00900	hipoteca
45	t	141	30	120.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.535573	8120.00	8000.00	0.01500	prestamo
46	t	120	40	75.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.549603	5075.00	5000.00	0.01500	prestamo
47	t	140	25	25.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.549617	5025.00	5000.00	0.00500	ahorro
48	t	130	45	150.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.549636	10150.00	10000.00	0.01500	prestamo
49	t	130	35	45.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.558802	5045.00	5000.00	0.00900	hipoteca
50	t	126	25	63.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.558813	7063.00	7000.00	0.00900	hipoteca
51	f	119	25	90.00	1	Diana Prince	\N	2026-09-20 21:44:17.571624	10090.00	10000.00	0.00900	hipoteca
52	t	147	25	180.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.571641	12180.00	12000.00	0.01500	prestamo
53	f	150	40	40.00	1	Bob Johnson	\N	2026-09-20 21:44:17.603297	8040.00	8000.00	0.00500	ahorro
54	t	122	45	180.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.603307	12180.00	12000.00	0.01500	prestamo
55	t	140	30	35.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.603324	7035.00	7000.00	0.00500	ahorro
56	f	144	45	40.00	1	Alice Brown	\N	2026-09-20 21:44:17.614281	8040.00	8000.00	0.00500	ahorro
57	f	101	35	40.00	1	Diana Prince	\N	2026-09-20 21:44:17.614319	8040.00	8000.00	0.00500	ahorro
58	t	132	30	63.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.614346	7063.00	7000.00	0.00900	hipoteca
59	t	119	40	120.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.623589	8120.00	8000.00	0.01500	prestamo
60	t	127	45	25.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.623605	5025.00	5000.00	0.00500	ahorro
61	t	150	45	180.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.623615	12180.00	12000.00	0.01500	prestamo
62	f	148	25	40.00	1	Jane Smith	\N	2026-09-20 21:44:17.633501	8040.00	8000.00	0.00500	ahorro
63	t	109	45	75.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.633552	5075.00	5000.00	0.01500	prestamo
64	f	131	45	35.00	1	Alice Brown	\N	2026-09-20 21:44:17.646051	7035.00	7000.00	0.00500	ahorro
65	t	121	35	108.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.646128	12108.00	12000.00	0.00900	hipoteca
66	t	134	30	60.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.660264	12060.00	12000.00	0.00500	ahorro
67	t	133	30	35.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.674514	7035.00	7000.00	0.00500	ahorro
68	t	119	35	45.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.706462	5045.00	5000.00	0.00900	hipoteca
69	t	118	45	90.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.706564	10090.00	10000.00	0.00900	hipoteca
70	t	143	40	108.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.722116	12108.00	12000.00	0.00900	hipoteca
71	t	124	25	72.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.722126	8072.00	8000.00	0.00900	hipoteca
72	t	141	35	63.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.754383	7063.00	7000.00	0.00900	hipoteca
73	t	140	30	72.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.754405	8072.00	8000.00	0.00900	hipoteca
74	t	110	30	120.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.754416	8120.00	8000.00	0.01500	prestamo
75	t	107	40	150.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.766716	10150.00	10000.00	0.01500	prestamo
76	t	124	30	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.766725	7105.00	7000.00	0.01500	prestamo
77	t	123	35	108.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.766734	12108.00	12000.00	0.00900	hipoteca
78	t	111	35	25.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.777278	5025.00	5000.00	0.00500	ahorro
79	t	126	40	35.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.792617	7035.00	7000.00	0.00500	ahorro
80	t	101	40	180.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.792625	12180.00	12000.00	0.01500	prestamo
81	t	119	40	50.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.792639	10050.00	10000.00	0.00500	ahorro
82	t	102	35	108.00	1	Bob Johnson	Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.802969	12108.00	12000.00	0.00900	hipoteca
83	t	134	35	180.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.803005	12180.00	12000.00	0.01500	prestamo
84	t	110	40	35.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.813855	7035.00	7000.00	0.00500	ahorro
85	f	117	40	35.00	1	Bob Johnson	\N	2026-09-20 21:44:17.829416	7035.00	7000.00	0.00500	ahorro
86	t	111	40	108.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.829435	12108.00	12000.00	0.00900	hipoteca
87	t	107	45	108.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.844504	12108.00	12000.00	0.00900	hipoteca
88	f	103	45	120.00	1	Diana Prince	\N	2026-09-20 21:44:17.844535	8120.00	8000.00	0.01500	prestamo
89	t	109	45	45.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.844548	5045.00	5000.00	0.00900	hipoteca
90	t	122	30	40.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.84456	8040.00	8000.00	0.00500	ahorro
91	t	129	40	35.00	1	Steve Rogers	Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:17.865008	7035.00	7000.00	0.00500	ahorro
92	f	138	45	35.00	1	Jane Smith	\N	2026-09-20 21:44:17.865017	7035.00	7000.00	0.00500	ahorro
93	t	129	45	35.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.875771	7035.00	7000.00	0.00500	ahorro
94	t	106	35	60.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.875779	12060.00	12000.00	0.00500	ahorro
95	t	133	45	60.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.888684	12060.00	12000.00	0.00500	ahorro
96	f	114	45	90.00	1	Steve Rogers	\N	2026-09-20 21:44:17.888804	10090.00	10000.00	0.00900	hipoteca
97	f	135	45	180.00	1	Alice Brown	\N	2026-09-20 21:44:17.888846	12180.00	12000.00	0.01500	prestamo
98	t	102	30	108.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.899268	12108.00	12000.00	0.00900	hipoteca
99	t	104	25	50.00	1	Sin identificar	Titular sin identificar en el archivo legacy	2026-09-20 21:44:17.899275	10050.00	10000.00	0.00500	ahorro
100	t	141	45	63.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.910934	7063.00	7000.00	0.00900	hipoteca
101	t	115	35	25.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.910941	5025.00	5000.00	0.00500	ahorro
102	f	149	25	45.00	1	Diana Prince	\N	2026-09-20 21:44:17.933398	5045.00	5000.00	0.00900	hipoteca
103	t	138	40	25.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.93341	5025.00	5000.00	0.00500	ahorro
104	t	149	40	180.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.943209	12180.00	12000.00	0.01500	prestamo
105	t	118	35	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.943228	7105.00	7000.00	0.01500	prestamo
106	t	129	45	180.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.96511	12180.00	12000.00	0.01500	prestamo
107	t	126	45	25.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.965117	5025.00	5000.00	0.00500	ahorro
108	t	115	35	63.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.976161	7063.00	7000.00	0.00900	hipoteca
109	t	134	45	35.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.988015	7035.00	7000.00	0.00500	ahorro
110	t	115	35	150.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.988096	10150.00	10000.00	0.01500	prestamo
111	t	113	25	72.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.988181	8072.00	8000.00	0.00900	hipoteca
112	t	132	45	45.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.995832	5045.00	5000.00	0.00900	hipoteca
113	t	101	45	63.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.99584	7063.00	7000.00	0.00900	hipoteca
114	t	123	35	150.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.995847	10150.00	10000.00	0.01500	prestamo
115	t	140	40	108.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:17.995853	12108.00	12000.00	0.00900	hipoteca
116	t	127	30	40.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.013382	8040.00	8000.00	0.00500	ahorro
117	t	121	25	45.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.044431	5045.00	5000.00	0.00900	hipoteca
118	t	143	35	180.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.044438	12180.00	12000.00	0.01500	prestamo
119	t	133	35	75.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.054612	5075.00	5000.00	0.01500	prestamo
120	t	108	25	45.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.063426	5045.00	5000.00	0.00900	hipoteca
121	t	107	35	72.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.063433	8072.00	8000.00	0.00900	hipoteca
122	t	107	45	150.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.072012	10150.00	10000.00	0.01500	prestamo
123	t	102	35	45.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.07202	5045.00	5000.00	0.00900	hipoteca
124	t	112	25	25.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.072038	5025.00	5000.00	0.00500	ahorro
125	t	150	40	35.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.089519	7035.00	7000.00	0.00500	ahorro
126	t	149	40	40.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.097535	8040.00	8000.00	0.00500	ahorro
127	t	109	25	72.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.097548	8072.00	8000.00	0.00900	hipoteca
128	t	144	30	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.099379	8072.00	8000.00	0.00900	hipoteca
129	t	114	35	25.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.105052	5025.00	5000.00	0.00500	ahorro
130	t	118	45	50.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.113637	10050.00	10000.00	0.00500	ahorro
131	t	133	35	75.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.121641	5075.00	5000.00	0.01500	prestamo
132	t	115	45	90.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.121652	10090.00	10000.00	0.00900	hipoteca
133	t	145	35	45.00	1	John Doe	Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.128959	5045.00	5000.00	0.00900	hipoteca
134	t	141	35	150.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.128966	10150.00	10000.00	0.01500	prestamo
135	t	130	25	120.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.144584	8120.00	8000.00	0.01500	prestamo
136	t	104	30	180.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.144597	12180.00	12000.00	0.01500	prestamo
137	t	101	35	150.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.152614	10150.00	10000.00	0.01500	prestamo
138	t	136	40	35.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.160653	7035.00	7000.00	0.00500	ahorro
139	t	122	45	90.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.160691	10090.00	10000.00	0.00900	hipoteca
140	t	121	45	105.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.160699	7105.00	7000.00	0.01500	prestamo
141	t	134	45	150.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.160705	10150.00	10000.00	0.01500	prestamo
142	t	133	35	45.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.165877	5045.00	5000.00	0.00900	hipoteca
143	t	138	45	105.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.18949	7105.00	7000.00	0.01500	prestamo
144	t	112	30	50.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.196659	10050.00	10000.00	0.00500	ahorro
145	t	118	40	105.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.203879	7105.00	7000.00	0.01500	prestamo
146	t	120	30	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.211386	7105.00	7000.00	0.01500	prestamo
147	t	141	25	60.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.221056	12060.00	12000.00	0.00500	ahorro
148	t	113	45	63.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.221063	7063.00	7000.00	0.00900	hipoteca
149	t	102	40	60.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.22107	12060.00	12000.00	0.00500	ahorro
150	t	136	25	75.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.226958	5075.00	5000.00	0.01500	prestamo
151	t	105	40	40.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.253156	8040.00	8000.00	0.00500	ahorro
152	t	122	40	25.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.253162	5025.00	5000.00	0.00500	ahorro
153	t	134	25	75.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.26768	5075.00	5000.00	0.01500	prestamo
154	t	150	35	35.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.267686	7035.00	7000.00	0.00500	ahorro
155	t	140	40	40.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.267694	8040.00	8000.00	0.00500	ahorro
156	t	147	25	105.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.271998	7105.00	7000.00	0.01500	prestamo
157	t	110	35	63.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.272004	7063.00	7000.00	0.00900	hipoteca
158	t	140	35	75.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.277499	5075.00	5000.00	0.01500	prestamo
159	t	112	30	120.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.277516	8120.00	8000.00	0.01500	prestamo
160	t	102	45	120.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.277524	8120.00	8000.00	0.01500	prestamo
161	t	131	45	45.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.277534	5045.00	5000.00	0.00900	hipoteca
162	t	104	25	150.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.27754	10150.00	10000.00	0.01500	prestamo
163	t	138	45	120.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.280451	8120.00	8000.00	0.01500	prestamo
164	t	121	35	72.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.280461	8072.00	8000.00	0.00900	hipoteca
165	t	130	25	75.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.280467	5075.00	5000.00	0.01500	prestamo
166	t	136	40	75.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.285501	5075.00	5000.00	0.01500	prestamo
167	t	105	45	150.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.285508	10150.00	10000.00	0.01500	prestamo
168	t	135	25	60.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.291774	12060.00	12000.00	0.00500	ahorro
169	t	126	45	25.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.29178	5025.00	5000.00	0.00500	ahorro
170	t	101	25	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.291787	8072.00	8000.00	0.00900	hipoteca
171	t	138	30	60.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.295985	12060.00	12000.00	0.00500	ahorro
172	t	101	30	72.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.295993	8072.00	8000.00	0.00900	hipoteca
173	t	129	45	40.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.296005	8040.00	8000.00	0.00500	ahorro
174	t	138	30	180.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.300897	12180.00	12000.00	0.01500	prestamo
175	t	137	45	90.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.300903	10090.00	10000.00	0.00900	hipoteca
176	t	123	25	25.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.300913	5025.00	5000.00	0.00500	ahorro
177	t	122	45	90.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.305552	10090.00	10000.00	0.00900	hipoteca
178	t	102	40	75.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.305558	5075.00	5000.00	0.01500	prestamo
179	t	132	45	72.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.321699	8072.00	8000.00	0.00900	hipoteca
180	t	123	35	108.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.321722	12108.00	12000.00	0.00900	hipoteca
181	f	139	40	50.00	1	Charlie Green	\N	2026-09-20 21:44:18.327269	10050.00	10000.00	0.00500	ahorro
182	t	145	35	108.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.333902	12108.00	12000.00	0.00900	hipoteca
183	t	101	35	108.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.34074	12108.00	12000.00	0.00900	hipoteca
184	t	121	30	63.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.340746	7063.00	7000.00	0.00900	hipoteca
185	t	145	35	180.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.340755	12180.00	12000.00	0.01500	prestamo
186	t	147	30	40.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.344981	8040.00	8000.00	0.00500	ahorro
187	t	115	45	72.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.344987	8072.00	8000.00	0.00900	hipoteca
188	t	143	30	50.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.351037	10050.00	10000.00	0.00500	ahorro
189	t	120	30	35.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.357801	7035.00	7000.00	0.00500	ahorro
190	t	110	25	90.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.357811	10090.00	10000.00	0.00900	hipoteca
191	t	134	30	90.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.363176	10090.00	10000.00	0.00900	hipoteca
192	t	126	40	75.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.369724	5075.00	5000.00	0.01500	prestamo
193	t	105	35	150.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.37691	10150.00	10000.00	0.01500	prestamo
194	t	133	45	150.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.38388	10150.00	10000.00	0.01500	prestamo
195	t	106	25	72.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.390531	8072.00	8000.00	0.00900	hipoteca
196	t	105	25	120.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.390543	8120.00	8000.00	0.01500	prestamo
197	t	141	30	120.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.397136	8120.00	8000.00	0.01500	prestamo
198	t	143	40	40.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.397146	8040.00	8000.00	0.00500	ahorro
199	t	110	25	45.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.405328	5045.00	5000.00	0.00900	hipoteca
200	t	129	25	150.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.405334	10150.00	10000.00	0.01500	prestamo
201	t	150	35	90.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.413976	10090.00	10000.00	0.00900	hipoteca
202	t	146	40	35.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.424371	7035.00	7000.00	0.00500	ahorro
203	t	108	35	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.424379	8072.00	8000.00	0.00900	hipoteca
204	t	150	30	63.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.430524	7063.00	7000.00	0.00900	hipoteca
205	t	133	25	150.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.443948	10150.00	10000.00	0.01500	prestamo
206	t	135	45	50.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.449147	10050.00	10000.00	0.00500	ahorro
207	t	120	45	63.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.455667	7063.00	7000.00	0.00900	hipoteca
208	t	149	25	50.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.455678	10050.00	10000.00	0.00500	ahorro
209	t	123	40	108.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.468174	12108.00	12000.00	0.00900	hipoteca
210	t	144	45	50.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.46818	10050.00	10000.00	0.00500	ahorro
211	t	148	30	35.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.468184	7035.00	7000.00	0.00500	ahorro
212	t	139	35	50.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.471852	10050.00	10000.00	0.00500	ahorro
213	t	107	25	150.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.471861	10150.00	10000.00	0.01500	prestamo
214	t	113	45	120.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.471867	8120.00	8000.00	0.01500	prestamo
215	f	142	25	35.00	1	Bob Johnson	\N	2026-09-20 21:44:18.476335	7035.00	7000.00	0.00500	ahorro
216	t	135	40	180.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.476343	12180.00	12000.00	0.01500	prestamo
217	t	106	25	120.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.483224	8120.00	8000.00	0.01500	prestamo
218	t	121	45	40.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.48323	8040.00	8000.00	0.00500	ahorro
219	t	150	40	180.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.483238	12180.00	12000.00	0.01500	prestamo
220	t	140	25	105.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.489373	7105.00	7000.00	0.01500	prestamo
221	t	148	25	150.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.48938	10150.00	10000.00	0.01500	prestamo
222	t	111	45	75.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.496605	5075.00	5000.00	0.01500	prestamo
223	t	113	35	75.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.504514	5075.00	5000.00	0.01500	prestamo
224	t	142	25	150.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.504595	10150.00	10000.00	0.01500	prestamo
225	t	116	40	63.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.523384	7063.00	7000.00	0.00900	hipoteca
226	t	129	35	150.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.523392	10150.00	10000.00	0.01500	prestamo
227	t	105	45	108.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.53082	12108.00	12000.00	0.00900	hipoteca
228	t	114	35	35.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.530826	7035.00	7000.00	0.00500	ahorro
229	t	145	45	105.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.530831	7105.00	7000.00	0.01500	prestamo
230	t	121	45	108.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.530839	12108.00	12000.00	0.00900	hipoteca
231	t	111	30	50.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.536409	10050.00	10000.00	0.00500	ahorro
232	t	139	45	72.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.547598	8072.00	8000.00	0.00900	hipoteca
233	t	119	40	75.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.547605	5075.00	5000.00	0.01500	prestamo
234	t	146	40	45.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.557171	5045.00	5000.00	0.00900	hipoteca
235	t	129	45	90.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.567192	10090.00	10000.00	0.00900	hipoteca
236	t	102	35	150.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.57693	10150.00	10000.00	0.01500	prestamo
237	t	149	25	72.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.586594	8072.00	8000.00	0.00900	hipoteca
238	t	142	25	50.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.595787	10050.00	10000.00	0.00500	ahorro
239	t	105	25	150.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.595796	10150.00	10000.00	0.01500	prestamo
240	f	125	35	75.00	1	Diana Prince	\N	2026-09-20 21:44:18.604746	5075.00	5000.00	0.01500	prestamo
241	t	123	25	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.604754	7105.00	7000.00	0.01500	prestamo
242	t	137	40	35.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.613146	7035.00	7000.00	0.00500	ahorro
243	t	143	40	120.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.622469	8120.00	8000.00	0.01500	prestamo
244	t	137	40	45.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.632413	5045.00	5000.00	0.00900	hipoteca
245	t	118	35	60.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.642262	12060.00	12000.00	0.00500	ahorro
246	t	132	35	45.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.650531	5045.00	5000.00	0.00900	hipoteca
247	t	145	30	60.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.655908	12060.00	12000.00	0.00500	ahorro
248	t	142	45	63.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.661824	7063.00	7000.00	0.00900	hipoteca
249	t	128	40	40.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.682396	8040.00	8000.00	0.00500	ahorro
250	t	121	40	108.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.702719	12108.00	12000.00	0.00900	hipoteca
251	t	149	45	25.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.702826	5025.00	5000.00	0.00500	ahorro
252	t	134	40	180.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.710734	12180.00	12000.00	0.01500	prestamo
253	t	140	30	120.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.718469	8120.00	8000.00	0.01500	prestamo
254	t	122	30	50.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.718481	10050.00	10000.00	0.00500	ahorro
255	t	136	35	150.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.718488	10150.00	10000.00	0.01500	prestamo
256	t	102	35	45.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.718494	5045.00	5000.00	0.00900	hipoteca
257	t	117	45	25.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.723083	5025.00	5000.00	0.00500	ahorro
258	t	128	30	150.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.723088	10150.00	10000.00	0.01500	prestamo
259	t	123	35	35.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.723093	7035.00	7000.00	0.00500	ahorro
260	t	149	25	35.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.739907	7035.00	7000.00	0.00500	ahorro
261	t	124	35	108.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.739913	12108.00	12000.00	0.00900	hipoteca
262	t	106	25	40.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.739917	8040.00	8000.00	0.00500	ahorro
263	t	129	35	75.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.746692	5075.00	5000.00	0.01500	prestamo
264	t	113	35	25.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.746702	5025.00	5000.00	0.00500	ahorro
265	t	135	40	120.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.746709	8120.00	8000.00	0.01500	prestamo
266	t	116	30	63.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.753958	7063.00	7000.00	0.00900	hipoteca
267	t	147	45	72.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.75397	8072.00	8000.00	0.00900	hipoteca
268	t	106	35	50.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.753978	10050.00	10000.00	0.00500	ahorro
269	t	122	35	50.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.753984	10050.00	10000.00	0.00500	ahorro
270	t	114	40	108.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.757901	12108.00	12000.00	0.00900	hipoteca
271	t	133	25	180.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.757907	12180.00	12000.00	0.01500	prestamo
272	t	102	30	108.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.757912	12108.00	12000.00	0.00900	hipoteca
273	t	120	40	45.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.763117	5045.00	5000.00	0.00900	hipoteca
274	t	107	25	45.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.763123	5045.00	5000.00	0.00900	hipoteca
275	t	103	30	35.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.769423	7035.00	7000.00	0.00500	ahorro
276	t	107	25	72.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.769428	8072.00	8000.00	0.00900	hipoteca
277	t	128	35	105.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.77541	7105.00	7000.00	0.01500	prestamo
278	t	108	25	120.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.775418	8120.00	8000.00	0.01500	prestamo
279	t	108	35	75.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.780588	5075.00	5000.00	0.01500	prestamo
280	t	110	30	35.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.780614	7035.00	7000.00	0.00500	ahorro
281	t	114	35	40.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.785268	8040.00	8000.00	0.00500	ahorro
282	t	132	45	180.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.785274	12180.00	12000.00	0.01500	prestamo
283	t	104	25	150.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.7911	10150.00	10000.00	0.01500	prestamo
284	t	125	25	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.791106	7105.00	7000.00	0.01500	prestamo
285	t	136	35	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.791111	8072.00	8000.00	0.00900	hipoteca
286	t	106	40	120.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.795427	8120.00	8000.00	0.01500	prestamo
287	t	109	40	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.809789	7105.00	7000.00	0.01500	prestamo
288	t	130	30	25.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.833468	5025.00	5000.00	0.00500	ahorro
289	t	106	35	180.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.833473	12180.00	12000.00	0.01500	prestamo
290	t	122	40	50.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.840382	10050.00	10000.00	0.00500	ahorro
291	t	101	30	90.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.840389	10090.00	10000.00	0.00900	hipoteca
292	t	128	30	75.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.840399	5075.00	5000.00	0.01500	prestamo
293	t	119	35	75.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.844462	5075.00	5000.00	0.01500	prestamo
294	t	108	45	25.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.84447	5025.00	5000.00	0.00500	ahorro
295	t	124	45	150.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.849145	10150.00	10000.00	0.01500	prestamo
296	t	123	25	50.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.849155	10050.00	10000.00	0.00500	ahorro
297	t	146	25	108.00	1	Sin identificar	Titular sin identificar en el archivo legacy; La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.8538	12108.00	12000.00	0.00900	hipoteca
298	t	115	40	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.85969	8072.00	8000.00	0.00900	hipoteca
299	t	135	30	150.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.859696	10150.00	10000.00	0.01500	prestamo
300	t	149	25	120.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.864206	8120.00	8000.00	0.01500	prestamo
301	t	108	35	50.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.864211	10050.00	10000.00	0.00500	ahorro
302	t	115	35	75.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.868755	5075.00	5000.00	0.01500	prestamo
303	t	150	25	72.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.868767	8072.00	8000.00	0.00900	hipoteca
304	t	113	45	72.00	1	Jane Smith	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.868773	8072.00	8000.00	0.00900	hipoteca
305	t	101	30	108.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.868779	12108.00	12000.00	0.00900	hipoteca
306	t	110	25	150.00	1	Charlie Green	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.871693	10150.00	10000.00	0.01500	prestamo
307	t	140	30	105.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.87667	7105.00	7000.00	0.01500	prestamo
308	t	130	45	108.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.882055	12108.00	12000.00	0.00900	hipoteca
309	t	122	30	25.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.88206	5025.00	5000.00	0.00500	ahorro
310	t	144	45	35.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.882064	7035.00	7000.00	0.00500	ahorro
311	t	132	25	25.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.885408	5025.00	5000.00	0.00500	ahorro
312	t	141	25	120.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.889613	8120.00	8000.00	0.01500	prestamo
313	t	128	40	60.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.889618	12060.00	12000.00	0.00500	ahorro
314	t	122	40	50.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.889622	10050.00	10000.00	0.00500	ahorro
315	t	104	25	45.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.893213	5045.00	5000.00	0.00900	hipoteca
316	t	128	35	40.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.89322	8040.00	8000.00	0.00500	ahorro
317	t	113	35	72.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.893224	8072.00	8000.00	0.00900	hipoteca
318	t	104	45	63.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.896842	7063.00	7000.00	0.00900	hipoteca
319	t	109	40	108.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.959763	12108.00	12000.00	0.00900	hipoteca
320	t	129	45	25.00	1	Alice Brown	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.959769	5025.00	5000.00	0.00500	ahorro
321	t	141	40	75.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.959774	5075.00	5000.00	0.01500	prestamo
322	t	111	35	90.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.964755	10090.00	10000.00	0.00900	hipoteca
323	t	123	45	25.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.970587	5025.00	5000.00	0.00500	ahorro
324	t	105	35	50.00	1	Steve Rogers	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.970592	10050.00	10000.00	0.00500	ahorro
325	t	117	30	180.00	1	Diana Prince	La cuenta aparece mas de una vez en el archivo con datos distintos	2026-09-20 21:44:18.975089	12180.00	12000.00	0.01500	prestamo
326	t	106	35	25.00	1	John Doe	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.975093	5025.00	5000.00	0.00500	ahorro
327	t	134	35	90.00	1	Bob Johnson	La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta	2026-09-20 21:44:18.975099	10090.00	10000.00	0.00900	hipoteca
\.


--
-- Data for Name: estado_cuenta_anual; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.estado_cuenta_anual (id, anio, cantidad_movimientos, cuenta_id, generado_en, job_execution_id, movimientos_con_anomalia, primera_fecha, saldo_neto, total_cargos, total_depositos, ultima_fecha) FROM stdin;
1	2024	44	101	2026-09-20 21:44:19.163655	1	7	2024-01-07	12900.00	25100.00	38000.00	2024-12-26
2	2024	51	102	2026-09-20 21:44:19.163585	1	3	2024-01-14	-31000.00	55200.00	24200.00	2024-12-28
3	2024	39	103	2026-09-20 21:44:19.163553	1	5	2024-01-17	-49700.00	61900.00	12200.00	2024-12-23
4	2024	51	104	2026-09-20 21:44:19.163602	1	5	2024-01-04	-39200.00	56500.00	17300.00	2024-11-17
5	2024	56	105	2026-09-20 21:44:19.163581	1	4	2024-01-04	-26000.00	53100.00	27100.00	2024-12-13
6	2024	58	106	2026-09-20 21:44:19.163594	1	6	2024-01-29	-30500.00	60800.00	30300.00	2024-12-16
7	2024	54	107	2026-09-20 21:44:19.163626	1	8	2024-01-02	-29400.00	58300.00	28900.00	2024-12-30
8	2024	51	108	2026-09-20 21:44:19.163598	1	6	2024-01-05	-41400.00	59600.00	18200.00	2024-12-22
9	2024	48	109	2026-09-20 21:44:19.163579	1	2	2024-01-21	-3700.00	43800.00	40100.00	2024-12-05
10	2024	46	110	2026-09-20 21:44:19.163572	1	3	2024-01-14	-25800.00	44400.00	18600.00	2024-12-24
11	2024	44	111	2026-09-20 21:44:19.163592	1	2	2024-01-18	-18300.00	49900.00	31600.00	2024-12-27
12	2024	47	112	2026-09-20 21:44:19.163622	1	4	2024-01-09	-20900.00	51400.00	30500.00	2024-12-27
13	2024	37	113	2026-09-20 21:44:19.163614	1	5	2024-01-11	-13300.00	37900.00	24600.00	2024-12-28
14	2024	55	114	2026-09-20 21:44:19.163605	1	7	2024-01-22	-39300.00	65000.00	25700.00	2024-12-29
15	2024	43	115	2026-09-20 21:44:19.163646	1	6	2024-01-05	-19900.00	38500.00	18600.00	2024-12-28
16	2024	55	116	2026-09-20 21:44:19.163604	1	5	2024-01-03	-20300.00	61200.00	40900.00	2024-12-24
17	2024	38	117	2026-09-20 21:44:19.163613	1	4	2024-01-11	-15600.00	42300.00	26700.00	2024-12-08
18	2024	50	118	2026-09-20 21:44:19.163621	1	6	2024-01-06	-27000.00	60300.00	33300.00	2024-12-28
19	2024	48	119	2026-09-20 21:44:19.163606	1	4	2024-01-29	-31500.00	56100.00	24600.00	2024-12-23
20	2024	37	120	2026-09-20 21:44:19.163582	1	1	2024-01-13	-21700.00	42200.00	20500.00	2024-12-28
\.


--
-- Data for Name: movimiento_anual; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.movimiento_anual (id, anio, anomalia, cuenta_id, descripcion, fecha, job_execution_id, monto, observacion, procesado_en, tipo_transaccion) FROM stdin;
1	2024	f	103	Retiro parcial	2024-03-08	1	3000.00	Fecha normalizada desde el formato legacy '08-03-2024'	2026-09-20 21:44:16.929445	deposito
2	2024	f	110	Sin descripcion	2024-07-24	1	-1500.00	Fecha normalizada desde el formato legacy '24-07-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:16.929601	retiro
3	2024	f	109	Ingreso mensual	2024-03-18	1	3000.00	Fecha normalizada desde el formato legacy '2024/03/18'	2026-09-20 21:44:16.929735	deposito
4	2024	f	105	Ingreso navideño	2024-03-24	1	1000.00	Fecha normalizada desde el formato legacy '24/03/2024'	2026-09-20 21:44:16.929876	deposito
5	2024	f	120	Sin descripcion	2024-02-26	1	-1000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:16.977633	compra
6	2024	f	102	Sin descripcion	2024-12-18	1	-3000.00	Fecha normalizada desde el formato legacy '18-12-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:16.977756	compra
7	2024	f	105	Ingreso extra	2024-06-21	1	-3000.00	Fecha normalizada desde el formato legacy '2024/06/21'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.977855	compra
8	2024	f	111	Ingreso mensual	2024-09-16	1	-2500.00	Fecha normalizada desde el formato legacy '2024/09/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.977951	compra
9	2024	t	106	Ingreso navideño	2024-02-12	1	100.00	Fecha normalizada desde el formato legacy '12/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.978055	deposito
10	2024	f	106	Ingreso extra	2024-06-21	1	2000.00	Fecha normalizada desde el formato legacy '21-06-2024'	2026-09-20 21:44:16.98407	deposito
11	2024	f	106	Ingreso navideño	2024-07-11	1	-1500.00	Fecha normalizada desde el formato legacy '2024/07/11'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.984273	compra
12	2024	f	108	Ingreso mensual	2024-02-15	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.984363	compra
13	2024	f	110	Ingreso mensual	2024-11-13	1	-500.00	Fecha normalizada desde el formato legacy '13/11/2024'	2026-09-20 21:44:16.984511	compra
14	2024	f	109	Compra en tienda	2024-12-04	1	-1000.00	Fecha normalizada desde el formato legacy '04/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.984606	retiro
15	2024	f	102	Sin descripcion	2024-04-19	1	2000.00	Fecha normalizada desde el formato legacy '19-04-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:16.990119	deposito
16	2024	f	108	Retiro parcial	2024-07-19	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.99022	retiro
17	2024	f	104	Compra en tienda	2024-08-26	1	-2500.00	Fecha normalizada desde el formato legacy '26-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.990304	retiro
18	2024	f	120	Compra en tienda	2024-03-09	1	-3000.00	Fecha normalizada desde el formato legacy '09-03-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.990393	retiro
19	2024	f	109	Ingreso mensual	2024-05-02	1	3000.00	Fecha normalizada desde el formato legacy '2024/05/02'	2026-09-20 21:44:16.990477	deposito
20	2024	f	116	Compra en tienda	2024-12-24	1	-2500.00	Fecha normalizada desde el formato legacy '2024/12/24'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.996582	compra
21	2024	f	114	Ingreso mensual	2024-07-08	1	-5000.00	Fecha normalizada desde el formato legacy '08/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.996686	compra
22	2024	f	119	Ingreso extra	2024-08-15	1	-1500.00	Fecha normalizada desde el formato legacy '2024/08/15'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.996772	retiro
23	2024	f	103	Retiro parcial	2024-10-05	1	-1000.00	Fecha normalizada desde el formato legacy '05-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:16.996862	compra
24	2024	f	102	Ingreso navideño	2024-09-30	1	2000.00	Fecha normalizada desde el formato legacy '2024/09/30'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:16.997239	deposito
25	2024	f	119	Ingreso mensual	2024-07-25	1	-500.00	Fecha normalizada desde el formato legacy '25/07/2024'	2026-09-20 21:44:17.004715	retiro
26	2024	f	103	Compra en tienda	2024-08-11	1	-1000.00	Fecha normalizada desde el formato legacy '11-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.004811	pago
27	2024	f	103	Retiro parcial	2024-12-19	1	-5000.00	Fecha normalizada desde el formato legacy '2024/12/19'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.0049	compra
28	2024	f	111	Retiro parcial	2024-03-10	1	-500.00	\N	2026-09-20 21:44:17.004975	retiro
29	2024	f	111	Ingreso navideño	2024-04-26	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.005048	retiro
30	2024	f	108	Ingreso extra	2024-12-22	1	1000.00	\N	2026-09-20 21:44:17.011704	deposito
31	2024	t	117	Ingreso extra	2024-01-11	1	1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.01179	deposito
32	2024	f	113	Compra en tienda	2024-01-24	1	-5000.00	Fecha normalizada desde el formato legacy '24/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.011893	compra
33	2024	f	109	Retiro parcial	2024-11-20	1	-1000.00	Fecha normalizada desde el formato legacy '20-11-2024'	2026-09-20 21:44:17.011977	retiro
34	2024	t	113	Ingreso navideño	2024-01-25	1	500.00	Fecha normalizada desde el formato legacy '25-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.012059	deposito
35	2024	f	109	Ingreso extra	2024-10-15	1	-500.00	Fecha normalizada desde el formato legacy '15/10/2024'	2026-09-20 21:44:17.019545	retiro
36	2024	f	103	Ingreso extra	2024-05-09	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.019661	retiro
37	2024	f	114	Ingreso mensual	2024-09-30	1	1000.00	Fecha normalizada desde el formato legacy '30-09-2024'	2026-09-20 21:44:17.01975	deposito
38	2024	f	120	Retiro parcial	2024-01-13	1	1000.00	Fecha normalizada desde el formato legacy '13/01/2024'	2026-09-20 21:44:17.019835	deposito
39	2024	f	113	Ingreso mensual	2024-02-29	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.019908	retiro
40	2024	f	109	Sin descripcion	2024-11-27	1	2000.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.025722	deposito
41	2024	f	117	Ingreso navideño	2024-05-30	1	1000.00	Fecha normalizada desde el formato legacy '30-05-2024'	2026-09-20 21:44:17.025827	deposito
42	2024	f	118	Ingreso navideño	2024-09-01	1	-100.00	\N	2026-09-20 21:44:17.025897	retiro
43	2024	f	112	Retiro parcial	2024-04-01	1	-3000.00	Fecha normalizada desde el formato legacy '2024/04/01'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.026138	retiro
44	2024	f	105	Ingreso mensual	2024-01-17	1	-500.00	\N	2026-09-20 21:44:17.026211	compra
45	2024	f	116	Compra en tienda	2024-11-22	1	-2500.00	Fecha normalizada desde el formato legacy '2024/11/22'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.032354	compra
46	2024	f	108	Ingreso extra	2024-05-14	1	3000.00	\N	2026-09-20 21:44:17.032424	deposito
47	2024	f	111	Compra en tienda	2024-07-19	1	-100.00	\N	2026-09-20 21:44:17.032491	compra
48	2024	f	107	Compra en tienda	2024-11-30	1	3000.00	\N	2026-09-20 21:44:17.032561	deposito
49	2024	f	111	Ingreso navideño	2024-09-25	1	2000.00	Fecha normalizada desde el formato legacy '2024/09/25'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.032662	deposito
50	2024	t	107	Sin descripcion	2024-02-29	1	500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.039315	deposito
51	2024	f	114	Compra en tienda	2024-04-23	1	-2000.00	Fecha normalizada desde el formato legacy '23-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.039414	retiro
52	2024	f	109	Sin descripcion	2024-03-09	1	3000.00	Fecha normalizada desde el formato legacy '2024/03/09'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.039484	deposito
53	2024	f	104	Ingreso navideño	2024-11-01	1	-500.00	Fecha normalizada desde el formato legacy '2024/11/01'	2026-09-20 21:44:17.039555	retiro
54	2024	f	104	Ingreso mensual	2024-02-02	1	-100.00	\N	2026-09-20 21:44:17.046964	retiro
55	2024	f	113	Retiro parcial	2024-05-02	1	-100.00	Fecha normalizada desde el formato legacy '02/05/2024'	2026-09-20 21:44:17.04707	retiro
56	2024	f	113	Retiro parcial	2024-01-11	1	3000.00	Fecha normalizada desde el formato legacy '11-01-2024'	2026-09-20 21:44:17.047139	deposito
57	2024	f	105	Ingreso mensual	2024-12-01	1	2000.00	Fecha normalizada desde el formato legacy '01/12/2024'	2026-09-20 21:44:17.047211	deposito
58	2024	f	109	Compra en tienda	2024-07-05	1	-500.00	Fecha normalizada desde el formato legacy '05-07-2024'	2026-09-20 21:44:17.047281	retiro
59	2024	f	106	Compra en tienda	2024-04-06	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/06'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.052895	retiro
60	2024	f	116	Sin descripcion	2024-06-25	1	-2000.00	Fecha normalizada desde el formato legacy '25/06/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.052967	retiro
61	2024	f	114	Retiro parcial	2024-09-04	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.05302	compra
62	2024	t	110	Compra en tienda	2024-02-15	1	0.00	Fecha normalizada desde el formato legacy '2024/02/15'; Monto no positivo	2026-09-20 21:44:17.053076	deposito
63	2024	f	109	Sin descripcion	2024-11-26	1	-2000.00	Fecha normalizada desde el formato legacy '2024/11/26'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.053171	retiro
64	2024	f	118	Sin descripcion	2024-05-19	1	-2000.00	Fecha normalizada desde el formato legacy '2024/05/19'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.058579	retiro
65	2024	f	112	Retiro parcial	2024-07-23	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.058635	compra
66	2024	f	120	Compra en tienda	2024-08-18	1	1500.00	\N	2026-09-20 21:44:17.058688	deposito
67	2024	f	102	Retiro parcial	2024-10-16	1	2500.00	Fecha normalizada desde el formato legacy '16-10-2024'	2026-09-20 21:44:17.058809	deposito
68	2024	f	103	Retiro parcial	2024-05-07	1	-2000.00	Fecha normalizada desde el formato legacy '07-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.077374	compra
69	2024	f	115	Compra en tienda	2024-08-15	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.077432	compra
70	2024	f	107	Ingreso extra	2024-09-28	1	-500.00	Fecha normalizada desde el formato legacy '28/09/2024'	2026-09-20 21:44:17.077493	retiro
71	2024	f	116	Ingreso extra	2024-02-15	1	3000.00	Fecha normalizada desde el formato legacy '2024/02/15'	2026-09-20 21:44:17.077544	deposito
72	2024	f	120	Ingreso extra	2024-10-27	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.08523	retiro
73	2024	f	119	Compra en tienda	2024-07-19	1	-2000.00	Fecha normalizada desde el formato legacy '19-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.08538	compra
74	2024	f	118	Sin descripcion	2024-12-09	1	-3000.00	Fecha normalizada desde el formato legacy '2024/12/09'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.085453	retiro
75	2024	f	115	Compra en tienda	2024-10-13	1	-2000.00	Fecha normalizada desde el formato legacy '13-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.08552	compra
76	2024	f	101	Retiro parcial	2024-02-16	1	-100.00	Fecha normalizada desde el formato legacy '16/02/2024'	2026-09-20 21:44:17.08558	compra
77	2024	f	118	Ingreso mensual	2024-04-27	1	-2000.00	Fecha normalizada desde el formato legacy '27/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.08995	retiro
78	2024	f	110	Ingreso extra	2024-02-11	1	-100.00	Fecha normalizada desde el formato legacy '11-02-2024'	2026-09-20 21:44:17.090023	compra
79	2024	t	118	Ingreso navideño	2024-03-05	1	0.00	Monto no positivo	2026-09-20 21:44:17.09007	retiro
80	2024	f	106	Sin descripcion	2024-08-29	1	-2000.00	Fecha normalizada desde el formato legacy '29/08/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.090129	pago
81	2024	f	105	Retiro parcial	2024-03-03	1	-2500.00	Fecha normalizada desde el formato legacy '03/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.090203	retiro
82	2024	f	107	Compra en tienda	2024-11-09	1	-1000.00	Fecha normalizada desde el formato legacy '09-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.108053	retiro
83	2024	f	119	Sin descripcion	2024-06-11	1	-500.00	Fecha normalizada desde el formato legacy '11/06/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.108121	compra
84	2024	f	105	Retiro parcial	2024-04-01	1	1000.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.108201	deposito
85	2024	t	116	Sin descripcion	2024-02-09	1	100.00	Fecha normalizada desde el formato legacy '09-02-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.108261	deposito
86	2024	f	114	Compra en tienda	2024-02-20	1	3000.00	Fecha normalizada desde el formato legacy '2024/02/20'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.108318	deposito
87	2024	f	113	Sin descripcion	2024-04-27	1	-3000.00	Fecha normalizada desde el formato legacy '27/04/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.113932	retiro
88	2024	f	110	Compra en tienda	2024-03-02	1	2000.00	Fecha normalizada desde el formato legacy '02/03/2024'	2026-09-20 21:44:17.113999	deposito
89	2024	f	101	Retiro parcial	2024-02-19	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.114043	compra
90	2024	f	102	Sin descripcion	2024-11-23	1	1000.00	Fecha normalizada desde el formato legacy '23-11-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.114089	deposito
91	2024	f	112	Sin descripcion	2024-03-08	1	-2500.00	Fecha normalizada desde el formato legacy '08/03/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.114142	retiro
92	2024	f	111	Ingreso extra	2024-03-25	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.119093	retiro
93	2024	f	114	Ingreso mensual	2024-02-14	1	-3000.00	Fecha normalizada desde el formato legacy '14/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.119179	retiro
94	2024	f	112	Retiro parcial	2024-10-17	1	-500.00	Fecha normalizada desde el formato legacy '2024/10/17'	2026-09-20 21:44:17.119225	retiro
95	2024	f	108	Retiro parcial	2024-01-05	1	-500.00	Fecha normalizada desde el formato legacy '05-01-2024'	2026-09-20 21:44:17.119269	pago
96	2024	f	116	Compra en tienda	2024-08-02	1	-500.00	Fecha normalizada desde el formato legacy '02/08/2024'	2026-09-20 21:44:17.126145	compra
97	2024	f	107	Ingreso navideño	2024-06-22	1	-3000.00	Fecha normalizada desde el formato legacy '2024/06/22'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.126202	retiro
98	2024	f	105	Ingreso extra	2024-06-04	1	-500.00	\N	2026-09-20 21:44:17.126245	pago
99	2024	f	106	Ingreso mensual	2024-07-28	1	2000.00	\N	2026-09-20 21:44:17.126284	deposito
100	2024	f	119	Sin descripcion	2024-03-24	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.126322	compra
101	2024	f	103	Ingreso extra	2024-09-24	1	-500.00	\N	2026-09-20 21:44:17.141989	retiro
102	2024	f	107	Ingreso mensual	2024-10-26	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.142039	retiro
103	2024	f	114	Ingreso extra	2024-02-13	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.142076	compra
104	2024	f	116	Ingreso extra	2024-08-09	1	-500.00	Fecha normalizada desde el formato legacy '2024/08/09'	2026-09-20 21:44:17.142126	compra
105	2024	f	114	Sin descripcion	2024-04-14	1	2000.00	Fecha normalizada desde el formato legacy '14-04-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.142201	deposito
106	2024	f	118	Compra en tienda	2024-08-26	1	-5000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.148707	compra
107	2024	f	101	Retiro parcial	2024-01-07	1	2500.00	\N	2026-09-20 21:44:17.148753	deposito
108	2024	f	118	Sin descripcion	2024-08-04	1	-3000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.14879	compra
109	2024	f	106	Sin descripcion	2024-08-27	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.148825	deposito
110	2024	f	120	Compra en tienda	2024-05-24	1	-500.00	\N	2026-09-20 21:44:17.148862	retiro
111	2024	f	104	Ingreso navideño	2024-11-07	1	-1000.00	Fecha normalizada desde el formato legacy '2024/11/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.152638	compra
112	2024	f	115	Ingreso navideño	2024-06-17	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.152738	compra
113	2024	f	110	Ingreso extra	2024-02-17	1	-2500.00	Fecha normalizada desde el formato legacy '17-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.152793	compra
114	2024	f	107	Sin descripcion	2024-01-28	1	-1500.00	Fecha normalizada desde el formato legacy '2024/01/28'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.153219	retiro
115	2024	f	102	Retiro parcial	2024-11-24	1	-100.00	Fecha normalizada desde el formato legacy '2024/11/24'	2026-09-20 21:44:17.153354	retiro
116	2024	f	106	Ingreso navideño	2024-10-23	1	-500.00	Fecha normalizada desde el formato legacy '2024/10/23'	2026-09-20 21:44:17.163385	compra
117	2024	f	106	Sin descripcion	2024-08-31	1	-2500.00	Fecha normalizada desde el formato legacy '2024/08/31'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.163437	compra
118	2024	f	114	Ingreso extra	2024-10-01	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.163475	compra
119	2024	f	119	Sin descripcion	2024-05-21	1	-1500.00	Fecha normalizada desde el formato legacy '2024/05/21'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.163512	retiro
120	2024	f	109	Ingreso extra	2024-05-21	1	-3000.00	Fecha normalizada desde el formato legacy '21/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.16356	retiro
121	2024	f	120	Sin descripcion	2024-12-17	1	-1500.00	Fecha normalizada desde el formato legacy '17/12/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.169493	retiro
122	2024	f	120	Ingreso navideño	2024-12-28	1	-500.00	Fecha normalizada desde el formato legacy '2024/12/28'	2026-09-20 21:44:17.169543	retiro
123	2024	f	106	Ingreso extra	2024-11-20	1	-100.00	Fecha normalizada desde el formato legacy '20-11-2024'	2026-09-20 21:44:17.169586	pago
124	2024	f	101	Ingreso navideño	2024-07-16	1	-2500.00	Fecha normalizada desde el formato legacy '2024/07/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.169626	retiro
125	2024	f	109	Ingreso navideño	2024-11-12	1	-100.00	Fecha normalizada desde el formato legacy '12/11/2024'	2026-09-20 21:44:17.175796	compra
126	2024	f	103	Sin descripcion	2024-03-15	1	-5000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.175853	compra
127	2024	f	118	Ingreso mensual	2024-12-08	1	-1000.00	Fecha normalizada desde el formato legacy '08/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.175894	retiro
128	2024	f	107	Sin descripcion	2024-12-30	1	-500.00	Fecha normalizada desde el formato legacy '2024/12/30'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.175925	retiro
129	2024	f	107	Ingreso mensual	2024-07-17	1	-2000.00	Fecha normalizada desde el formato legacy '17-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.175955	retiro
130	2024	f	118	Ingreso navideño	2024-03-05	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.180403	compra
131	2024	f	116	Ingreso navideño	2024-11-23	1	-2000.00	Fecha normalizada desde el formato legacy '23-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.180454	compra
132	2024	f	103	Ingreso extra	2024-03-19	1	-3000.00	Fecha normalizada desde el formato legacy '19/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.180505	compra
133	2024	f	110	Sin descripcion	2024-06-22	1	-2000.00	Fecha normalizada desde el formato legacy '2024/06/22'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.180538	pago
134	2024	f	105	Ingreso extra	2024-10-26	1	-1000.00	Fecha normalizada desde el formato legacy '26-10-2024'	2026-09-20 21:44:17.188557	compra
135	2024	f	114	Compra en tienda	2024-04-16	1	2000.00	\N	2026-09-20 21:44:17.188615	deposito
136	2024	f	103	Sin descripcion	2024-10-29	1	-2500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.188647	compra
137	2024	f	111	Compra en tienda	2024-03-03	1	-2000.00	Fecha normalizada desde el formato legacy '03/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.188684	compra
138	2024	f	104	Sin descripcion	2024-09-06	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.188716	retiro
139	2024	t	118	Sin descripcion	2024-08-13	1	500.00	Fecha normalizada desde el formato legacy '2024/08/13'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.192744	deposito
140	2024	f	110	Retiro parcial	2024-11-27	1	-2000.00	Fecha normalizada desde el formato legacy '27/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.192813	retiro
141	2024	f	114	Ingreso navideño	2024-05-07	1	-3000.00	Fecha normalizada desde el formato legacy '07-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.19285	retiro
142	2024	t	113	Ingreso extra	2024-09-30	1	500.00	Fecha normalizada desde el formato legacy '30/09/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.192887	deposito
143	2024	f	106	Retiro parcial	2024-11-26	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.192912	pago
144	2024	f	116	Ingreso navideño	2024-04-19	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.19673	pago
145	2024	f	117	Sin descripcion	2024-06-25	1	2500.00	Fecha normalizada desde el formato legacy '25-06-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.196776	deposito
146	2024	f	106	Sin descripcion	2024-04-03	1	-2000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.196808	retiro
147	2024	f	105	Ingreso navideño	2024-09-21	1	-3000.00	Fecha normalizada desde el formato legacy '21/09/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.196841	retiro
148	2024	f	120	Ingreso mensual	2024-09-16	1	1500.00	Fecha normalizada desde el formato legacy '2024/09/16'	2026-09-20 21:44:17.196865	deposito
149	2024	f	103	Ingreso mensual	2024-01-27	1	-2000.00	Fecha normalizada desde el formato legacy '27-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.208502	retiro
150	2024	f	114	Sin descripcion	2024-07-04	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.208548	compra
151	2024	f	106	Ingreso extra	2024-04-26	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.208575	compra
152	2024	f	109	Sin descripcion	2024-11-10	1	-2500.00	Fecha normalizada desde el formato legacy '2024/11/10'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.208604	retiro
153	2024	f	119	Ingreso extra	2024-05-21	1	-1000.00	Fecha normalizada desde el formato legacy '21/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.208636	compra
154	2024	f	110	Retiro parcial	2024-08-19	1	-2500.00	Fecha normalizada desde el formato legacy '19/08/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.213315	retiro
155	2024	f	106	Compra en tienda	2024-10-02	1	-1500.00	Fecha normalizada desde el formato legacy '2024/10/02'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.21339	retiro
156	2024	f	116	Ingreso navideño	2024-06-17	1	1500.00	Fecha normalizada desde el formato legacy '17/06/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.213496	deposito
157	2024	f	109	Compra en tienda	2024-05-20	1	-500.00	Fecha normalizada desde el formato legacy '2024/05/20'	2026-09-20 21:44:17.213539	compra
158	2024	f	107	Sin descripcion	2024-09-26	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.213568	compra
159	2024	f	110	Ingreso navideño	2024-02-14	1	2500.00	Fecha normalizada desde el formato legacy '2024/02/14'	2026-09-20 21:44:17.217716	deposito
160	2024	f	105	Compra en tienda	2024-09-09	1	-500.00	\N	2026-09-20 21:44:17.217754	compra
161	2024	f	104	Ingreso mensual	2024-11-09	1	-3000.00	Fecha normalizada desde el formato legacy '2024/11/09'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.217781	compra
162	2024	f	114	Ingreso navideño	2024-05-22	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.217802	compra
163	2024	f	116	Ingreso navideño	2024-11-14	1	2500.00	Fecha normalizada desde el formato legacy '2024/11/14'	2026-09-20 21:44:17.217825	deposito
164	2024	f	102	Compra en tienda	2024-02-08	1	3000.00	Fecha normalizada desde el formato legacy '08/02/2024'	2026-09-20 21:44:17.220623	deposito
165	2024	f	105	Ingreso navideño	2024-05-10	1	-2500.00	Fecha normalizada desde el formato legacy '10/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.220663	retiro
166	2024	f	107	Ingreso extra	2024-11-16	1	1500.00	Fecha normalizada desde el formato legacy '2024/11/16'	2026-09-20 21:44:17.220695	deposito
167	2024	t	114	Compra en tienda	2024-10-30	1	0.00	Fecha normalizada desde el formato legacy '30/10/2024'; Monto no positivo	2026-09-20 21:44:17.220724	retiro
168	2024	f	102	Retiro parcial	2024-08-12	1	2500.00	Fecha normalizada desde el formato legacy '2024/08/12'	2026-09-20 21:44:17.220758	deposito
169	2024	t	115	Ingreso mensual	2024-10-25	1	0.00	Fecha normalizada desde el formato legacy '25-10-2024'; Monto no positivo	2026-09-20 21:44:17.230306	deposito
170	2024	t	107	Compra en tienda	2024-11-26	1	500.00	Fecha normalizada desde el formato legacy '26-11-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.230372	deposito
171	2024	f	109	Ingreso mensual	2024-12-05	1	-2500.00	Fecha normalizada desde el formato legacy '05/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.230408	retiro
172	2024	f	119	Ingreso extra	2024-02-18	1	-1000.00	Fecha normalizada desde el formato legacy '18/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.230437	pago
173	2024	f	103	Ingreso navideño	2024-10-29	1	-2500.00	Fecha normalizada desde el formato legacy '2024/10/29'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.230461	compra
174	2024	f	103	Ingreso mensual	2024-07-05	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.235048	retiro
175	2024	f	112	Ingreso mensual	2024-12-16	1	-100.00	\N	2026-09-20 21:44:17.235134	compra
176	2024	f	117	Sin descripcion	2024-02-01	1	-100.00	Fecha normalizada desde el formato legacy '01/02/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.235187	retiro
177	2024	f	107	Retiro parcial	2024-12-06	1	2500.00	Fecha normalizada desde el formato legacy '06-12-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.235246	deposito
178	2024	f	108	Retiro parcial	2024-07-17	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.235268	retiro
179	2024	f	116	Retiro parcial	2024-09-15	1	-3000.00	Fecha normalizada desde el formato legacy '2024/09/15'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.240513	compra
180	2024	f	115	Ingreso extra	2024-04-22	1	-1500.00	Fecha normalizada desde el formato legacy '2024/04/22'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.240558	compra
181	2024	f	102	Compra en tienda	2024-09-24	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.240589	retiro
182	2024	f	114	Ingreso navideño	2024-10-20	1	-100.00	\N	2026-09-20 21:44:17.240636	compra
183	2024	f	113	Ingreso navideño	2024-04-05	1	1000.00	\N	2026-09-20 21:44:17.240672	deposito
184	2024	f	117	Ingreso mensual	2024-11-17	1	3000.00	Fecha normalizada desde el formato legacy '17/11/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.254212	deposito
185	2024	f	110	Retiro parcial	2024-09-11	1	1000.00	Fecha normalizada desde el formato legacy '11/09/2024'	2026-09-20 21:44:17.254265	deposito
186	2024	f	104	Ingreso extra	2024-03-01	1	-500.00	\N	2026-09-20 21:44:17.254297	retiro
187	2024	f	102	Compra en tienda	2024-12-28	1	-500.00	\N	2026-09-20 21:44:17.254315	retiro
188	2024	f	119	Ingreso extra	2024-10-28	1	-2000.00	Fecha normalizada desde el formato legacy '2024/10/28'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.254335	retiro
189	2024	f	104	Compra en tienda	2024-07-19	1	-1000.00	Fecha normalizada desde el formato legacy '19/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.259046	retiro
190	2024	f	110	Retiro parcial	2024-02-23	1	1000.00	Fecha normalizada desde el formato legacy '2024/02/23'	2026-09-20 21:44:17.259082	deposito
191	2024	f	114	Ingreso extra	2024-02-07	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.259102	retiro
192	2024	t	109	Ingreso extra	2024-09-11	1	100.00	Fecha normalizada desde el formato legacy '2024/09/11'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.259162	deposito
193	2024	f	107	Sin descripcion	2024-07-02	1	2500.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.259187	deposito
194	2024	f	101	Ingreso mensual	2024-07-09	1	-1000.00	Fecha normalizada desde el formato legacy '2024/07/09'	2026-09-20 21:44:17.262911	retiro
195	2024	f	114	Ingreso mensual	2024-10-01	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.262945	compra
196	2024	f	114	Sin descripcion	2024-07-09	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.262963	compra
197	2024	f	116	Compra en tienda	2024-06-15	1	-3000.00	Fecha normalizada desde el formato legacy '15/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.262986	retiro
198	2024	f	117	Ingreso mensual	2024-02-10	1	-2500.00	Fecha normalizada desde el formato legacy '10-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.263063	compra
199	2024	f	104	Compra en tienda	2024-01-11	1	-1000.00	Fecha normalizada desde el formato legacy '11-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.267892	retiro
200	2024	f	117	Compra en tienda	2024-03-27	1	1500.00	Fecha normalizada desde el formato legacy '27-03-2024'	2026-09-20 21:44:17.267931	deposito
201	2024	f	119	Ingreso mensual	2024-09-25	1	1000.00	Fecha normalizada desde el formato legacy '25/09/2024'	2026-09-20 21:44:17.267961	deposito
202	2024	f	112	Ingreso navideño	2024-08-25	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.267983	compra
203	2024	f	107	Compra en tienda	2024-01-24	1	3000.00	Fecha normalizada desde el formato legacy '24-01-2024'	2026-09-20 21:44:17.268004	deposito
204	2024	f	115	Sin descripcion	2024-02-22	1	-3000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.273753	pago
205	2024	f	119	Sin descripcion	2024-07-11	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.273808	deposito
206	2024	f	117	Ingreso extra	2024-09-27	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.273849	pago
207	2024	f	120	Compra en tienda	2024-09-01	1	1500.00	Fecha normalizada desde el formato legacy '2024/09/01'	2026-09-20 21:44:17.273882	deposito
208	2024	f	110	Ingreso mensual	2024-04-26	1	-3000.00	Fecha normalizada desde el formato legacy '2024/04/26'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.273905	compra
209	2024	f	114	Ingreso mensual	2024-03-03	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.279014	compra
210	2024	f	111	Ingreso extra	2024-07-08	1	-2500.00	Fecha normalizada desde el formato legacy '08-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.279051	compra
211	2024	t	108	Compra en tienda	2024-08-16	1	100.00	Fecha normalizada desde el formato legacy '16-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.279075	deposito
212	2024	f	106	Sin descripcion	2024-12-16	1	2500.00	Fecha normalizada desde el formato legacy '16-12-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.279105	deposito
213	2024	f	117	Ingreso navideño	2024-08-07	1	-3000.00	Fecha normalizada desde el formato legacy '07-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.279127	compra
214	2024	f	108	Ingreso navideño	2024-12-20	1	-100.00	Fecha normalizada desde el formato legacy '20-12-2024'	2026-09-20 21:44:17.285772	compra
215	2024	f	103	Retiro parcial	2024-05-06	1	-2000.00	Fecha normalizada desde el formato legacy '2024/05/06'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.285817	compra
216	2024	f	106	Compra en tienda	2024-02-22	1	-500.00	Fecha normalizada desde el formato legacy '22-02-2024'	2026-09-20 21:44:17.285846	retiro
217	2024	f	118	Ingreso mensual	2024-01-30	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.285865	retiro
218	2024	f	117	Compra en tienda	2024-02-15	1	-100.00	\N	2026-09-20 21:44:17.28588	retiro
219	2024	t	107	Retiro parcial	2024-07-01	1	100.00	Fecha normalizada desde el formato legacy '01-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.290363	deposito
220	2024	f	116	Compra en tienda	2024-03-23	1	2000.00	\N	2026-09-20 21:44:17.290401	deposito
221	2024	t	113	Sin descripcion	2024-12-04	1	500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.290417	deposito
222	2024	f	105	Ingreso navideño	2024-08-03	1	1500.00	Fecha normalizada desde el formato legacy '03-08-2024'	2026-09-20 21:44:17.290437	deposito
223	2024	f	115	Ingreso extra	2024-11-17	1	-500.00	Fecha normalizada desde el formato legacy '2024/11/17'	2026-09-20 21:44:17.301589	compra
224	2024	f	107	Sin descripcion	2024-03-07	1	3000.00	Fecha normalizada desde el formato legacy '2024/03/07'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.301632	deposito
225	2024	f	106	Compra en tienda	2024-06-26	1	1000.00	Fecha normalizada desde el formato legacy '26/06/2024'	2026-09-20 21:44:17.301736	deposito
226	2024	f	118	Compra en tienda	2024-04-12	1	-500.00	\N	2026-09-20 21:44:17.301795	compra
227	2024	f	120	Sin descripcion	2024-02-14	1	2500.00	Fecha normalizada desde el formato legacy '2024/02/14'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.301823	deposito
228	2024	f	111	Sin descripcion	2024-06-07	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.306515	compra
229	2024	f	119	Compra en tienda	2024-08-03	1	-5000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.306611	compra
230	2024	f	108	Ingreso extra	2024-01-18	1	-2000.00	Fecha normalizada desde el formato legacy '18-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.306654	compra
231	2024	t	101	Retiro parcial	2024-10-16	1	100.00	Fecha normalizada desde el formato legacy '2024/10/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.306682	deposito
232	2024	t	115	Ingreso extra	2024-06-22	1	500.00	Fecha normalizada desde el formato legacy '22/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.306838	deposito
233	2024	f	105	Ingreso navideño	2024-04-15	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.312775	retiro
234	2024	f	112	Ingreso mensual	2024-03-23	1	1000.00	\N	2026-09-20 21:44:17.312799	deposito
235	2024	t	118	Sin descripcion	2024-08-25	1	100.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.312818	deposito
236	2024	f	107	Ingreso navideño	2024-10-24	1	-2500.00	Fecha normalizada desde el formato legacy '24/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.312929	retiro
237	2024	f	120	Ingreso navideño	2024-10-30	1	1000.00	Fecha normalizada desde el formato legacy '30/10/2024'	2026-09-20 21:44:17.415332	deposito
238	2024	f	111	Compra en tienda	2024-02-15	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.415364	retiro
239	2024	f	108	Ingreso extra	2024-12-12	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.415406	compra
240	2024	f	108	Ingreso extra	2024-12-12	1	-100.00	Fecha normalizada desde el formato legacy '12-12-2024'	2026-09-20 21:44:17.415445	compra
241	2024	f	104	Sin descripcion	2024-07-10	1	-1500.00	Fecha normalizada desde el formato legacy '10/07/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.425974	compra
242	2024	f	102	Ingreso navideño	2024-02-09	1	-1500.00	Fecha normalizada desde el formato legacy '09-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.426164	retiro
243	2024	f	103	Sin descripcion	2024-09-24	1	1500.00	Fecha normalizada desde el formato legacy '2024/09/24'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.426249	deposito
244	2024	f	112	Ingreso navideño	2024-06-12	1	3000.00	Fecha normalizada desde el formato legacy '12-06-2024'	2026-09-20 21:44:17.426293	deposito
245	2024	f	112	Sin descripcion	2024-04-01	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/01'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.433586	compra
246	2024	f	108	Sin descripcion	2024-12-08	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.43362	retiro
247	2024	f	108	Sin descripcion	2024-09-30	1	-500.00	Fecha normalizada desde el formato legacy '30-09-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.433643	retiro
248	2024	f	106	Retiro parcial	2024-07-20	1	2500.00	Fecha normalizada desde el formato legacy '2024/07/20'	2026-09-20 21:44:17.433664	deposito
249	2024	f	102	Sin descripcion	2024-04-29	1	-2000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.433677	retiro
250	2024	f	113	Retiro parcial	2024-07-20	1	-2500.00	Fecha normalizada desde el formato legacy '20-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.438999	compra
326	2024	f	106	Compra en tienda	2024-03-23	1	-2000.00	Fecha normalizada desde el formato legacy '2024/03/23'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.518842	compra
251	2024	f	119	Sin descripcion	2024-10-24	1	-2000.00	Fecha normalizada desde el formato legacy '24-10-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.439168	compra
252	2024	f	107	Sin descripcion	2024-03-18	1	-5000.00	Fecha normalizada desde el formato legacy '2024/03/18'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.439346	compra
253	2024	f	108	Retiro parcial	2024-02-21	1	1500.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.439734	deposito
254	2024	f	120	Compra en tienda	2024-03-24	1	-2000.00	Fecha normalizada desde el formato legacy '24/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.439869	retiro
255	2024	f	112	Compra en tienda	2024-07-05	1	1000.00	Fecha normalizada desde el formato legacy '05-07-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.444975	deposito
256	2024	f	104	Retiro parcial	2024-01-07	1	-1000.00	Fecha normalizada desde el formato legacy '07/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.445076	compra
257	2024	f	112	Sin descripcion	2024-12-11	1	-3000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.445102	retiro
258	2024	f	110	Ingreso extra	2024-11-03	1	-100.00	Fecha normalizada desde el formato legacy '03/11/2024'	2026-09-20 21:44:17.445148	compra
259	2024	f	113	Sin descripcion	2024-12-28	1	2000.00	Fecha normalizada desde el formato legacy '28-12-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.451906	deposito
260	2024	f	116	Ingreso mensual	2024-11-02	1	2000.00	Fecha normalizada desde el formato legacy '02-11-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.45197	deposito
261	2024	f	106	Compra en tienda	2024-02-02	1	-1500.00	Fecha normalizada desde el formato legacy '02-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.451995	compra
262	2024	f	114	Sin descripcion	2024-05-30	1	-2500.00	Fecha normalizada desde el formato legacy '30/05/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.452017	compra
263	2024	f	113	Compra en tienda	2024-12-11	1	1500.00	Fecha normalizada desde el formato legacy '2024/12/11'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.45204	deposito
264	2024	f	107	Ingreso mensual	2024-02-16	1	-2500.00	Fecha normalizada desde el formato legacy '16-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.45708	compra
265	2024	t	102	Sin descripcion	2024-03-11	1	100.00	Fecha normalizada desde el formato legacy '11-03-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.45715	deposito
266	2024	f	108	Retiro parcial	2024-03-13	1	2000.00	Fecha normalizada desde el formato legacy '13-03-2024'	2026-09-20 21:44:17.457179	deposito
267	2024	f	101	Retiro parcial	2024-03-22	1	-2000.00	Fecha normalizada desde el formato legacy '22/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.457201	retiro
268	2024	f	105	Retiro parcial	2024-04-03	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.457216	retiro
269	2024	f	105	Ingreso navideño	2024-08-14	1	-1000.00	Fecha normalizada desde el formato legacy '14-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.462625	retiro
270	2024	f	103	Retiro parcial	2024-07-23	1	-3000.00	Fecha normalizada desde el formato legacy '23/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.462661	compra
271	2024	f	109	Ingreso navideño	2024-01-21	1	2000.00	Fecha normalizada desde el formato legacy '2024/01/21'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.4627	deposito
272	2024	f	103	Compra en tienda	2024-02-12	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.462717	compra
273	2024	f	120	Sin descripcion	2024-02-03	1	-2500.00	Fecha normalizada desde el formato legacy '2024/02/03'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.462733	retiro
274	2024	f	102	Retiro parcial	2024-11-01	1	-100.00	Fecha normalizada desde el formato legacy '01-11-2024'	2026-09-20 21:44:17.466575	compra
275	2024	f	111	Ingreso mensual	2024-02-16	1	-2000.00	Fecha normalizada desde el formato legacy '16-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.46662	retiro
276	2024	f	104	Ingreso mensual	2024-08-08	1	-100.00	Fecha normalizada desde el formato legacy '08-08-2024'	2026-09-20 21:44:17.466643	compra
277	2024	f	106	Ingreso mensual	2024-09-27	1	-100.00	\N	2026-09-20 21:44:17.466657	compra
278	2024	f	106	Retiro parcial	2024-04-04	1	-2500.00	Fecha normalizada desde el formato legacy '04/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.466677	compra
279	2024	f	117	Ingreso mensual	2024-08-29	1	-1000.00	Fecha normalizada desde el formato legacy '29-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.471154	retiro
280	2024	f	116	Ingreso mensual	2024-05-13	1	-1000.00	Fecha normalizada desde el formato legacy '2024/05/13'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.471178	retiro
281	2024	f	106	Retiro parcial	2024-05-04	1	-500.00	Fecha normalizada desde el formato legacy '2024/05/04'	2026-09-20 21:44:17.471195	compra
282	2024	f	105	Ingreso mensual	2024-12-13	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.471207	compra
283	2024	f	120	Sin descripcion	2024-03-04	1	-2500.00	Fecha normalizada desde el formato legacy '04/03/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.471225	compra
284	2024	f	104	Ingreso navideño	2024-10-10	1	-2500.00	Fecha normalizada desde el formato legacy '2024/10/10'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.475545	retiro
285	2024	t	116	Compra en tienda	2024-11-01	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.47557	deposito
286	2024	f	101	Compra en tienda	2024-06-03	1	2000.00	Fecha normalizada desde el formato legacy '03-06-2024'	2026-09-20 21:44:17.47559	deposito
287	2024	f	118	Ingreso mensual	2024-08-19	1	-1500.00	Fecha normalizada desde el formato legacy '19/08/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.475611	compra
367	2024	f	111	Compra en tienda	2024-05-10	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.581281	retiro
288	2024	f	106	Sin descripcion	2024-09-03	1	-3000.00	Fecha normalizada desde el formato legacy '03-09-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.475632	compra
289	2024	f	101	Ingreso mensual	2024-09-25	1	2500.00	Fecha normalizada desde el formato legacy '25-09-2024'	2026-09-20 21:44:17.480392	deposito
290	2024	t	101	Sin descripcion	2024-12-26	1	100.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.480431	deposito
291	2024	f	118	Retiro parcial	2024-04-18	1	3000.00	\N	2026-09-20 21:44:17.480449	deposito
292	2024	f	111	Ingreso navideño	2024-03-28	1	5000.00	Fecha normalizada desde el formato legacy '28-03-2024'	2026-09-20 21:44:17.480468	deposito
293	2024	f	118	Ingreso mensual	2024-10-11	1	-3000.00	Fecha normalizada desde el formato legacy '2024/10/11'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.480485	compra
294	2024	f	109	Compra en tienda	2024-11-09	1	-2000.00	Fecha normalizada desde el formato legacy '2024/11/09'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.485662	retiro
295	2024	f	109	Sin descripcion	2024-10-31	1	-5000.00	Fecha normalizada desde el formato legacy '31/10/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.485703	retiro
296	2024	f	108	Ingreso mensual	2024-01-26	1	-3000.00	Fecha normalizada desde el formato legacy '2024/01/26'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.485722	retiro
297	2024	f	114	Ingreso mensual	2024-10-29	1	-2500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.485744	retiro
298	2024	f	111	Compra en tienda	2024-07-30	1	3000.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.48578	deposito
299	2024	f	110	Retiro parcial	2024-11-15	1	-100.00	Fecha normalizada desde el formato legacy '2024/11/15'	2026-09-20 21:44:17.490963	compra
300	2024	f	116	Ingreso navideño	2024-01-17	1	-100.00	Fecha normalizada desde el formato legacy '17-01-2024'	2026-09-20 21:44:17.491146	retiro
301	2024	f	101	Compra en tienda	2024-02-04	1	2500.00	Fecha normalizada desde el formato legacy '04/02/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.491253	deposito
302	2024	f	106	Sin descripcion	2024-07-25	1	-1500.00	Fecha normalizada desde el formato legacy '25-07-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.491276	compra
303	2024	f	107	Ingreso extra	2024-08-11	1	-100.00	Fecha normalizada desde el formato legacy '11/08/2024'	2026-09-20 21:44:17.4913	retiro
304	2024	f	104	Retiro parcial	2024-07-30	1	-3000.00	Fecha normalizada desde el formato legacy '30/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.497102	compra
305	2024	f	115	Ingreso mensual	2024-10-31	1	-1500.00	Fecha normalizada desde el formato legacy '31/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.497133	compra
306	2024	f	111	Ingreso mensual	2024-04-09	1	-2500.00	Fecha normalizada desde el formato legacy '09-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.49715	retiro
307	2024	f	114	Ingreso extra	2024-02-21	1	-500.00	Fecha normalizada desde el formato legacy '21-02-2024'	2026-09-20 21:44:17.497168	pago
308	2024	f	104	Compra en tienda	2024-01-31	1	-1500.00	Fecha normalizada desde el formato legacy '31-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.504468	retiro
309	2024	f	117	Ingreso mensual	2024-08-26	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/26'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.504545	deposito
310	2024	f	114	Ingreso extra	2024-10-03	1	-3000.00	Fecha normalizada desde el formato legacy '2024/10/03'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.504587	compra
311	2024	f	101	Sin descripcion	2024-03-07	1	-100.00	Fecha normalizada desde el formato legacy '07-03-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.504604	retiro
312	2024	f	102	Ingreso extra	2024-12-24	1	-3000.00	Fecha normalizada desde el formato legacy '2024/12/24'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.504639	pago
313	2024	f	119	Compra en tienda	2024-07-27	1	-500.00	Fecha normalizada desde el formato legacy '27/07/2024'	2026-09-20 21:44:17.509144	retiro
314	2024	f	116	Sin descripcion	2024-10-31	1	-3000.00	Fecha normalizada desde el formato legacy '2024/10/31'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.509191	retiro
315	2024	f	108	Compra en tienda	2024-10-23	1	-2000.00	Fecha normalizada desde el formato legacy '23/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.509213	retiro
316	2024	f	118	Ingreso extra	2024-01-19	1	-5000.00	Fecha normalizada desde el formato legacy '19/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.509297	retiro
317	2024	f	112	Ingreso navideño	2024-11-22	1	-2000.00	Fecha normalizada desde el formato legacy '22/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.509326	compra
318	2024	f	101	Sin descripcion	2024-01-17	1	-100.00	Fecha normalizada desde el formato legacy '2024/01/17'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.513837	pago
319	2024	f	117	Ingreso mensual	2024-09-05	1	2000.00	Fecha normalizada desde el formato legacy '05-09-2024'	2026-09-20 21:44:17.513924	deposito
320	2024	f	108	Sin descripcion	2024-06-30	1	-2500.00	Fecha normalizada desde el formato legacy '2024/06/30'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.513958	compra
321	2024	f	109	Sin descripcion	2024-01-22	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.513985	retiro
322	2024	f	104	Ingreso navideño	2024-05-26	1	2500.00	Fecha normalizada desde el formato legacy '26/05/2024'	2026-09-20 21:44:17.514004	deposito
323	2024	t	108	Retiro parcial	2024-10-31	1	500.00	Fecha normalizada desde el formato legacy '31/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.518723	deposito
324	2024	f	109	Ingreso navideño	2024-10-21	1	2500.00	Fecha normalizada desde el formato legacy '21-10-2024'	2026-09-20 21:44:17.51881	deposito
325	2024	f	115	Sin descripcion	2024-07-12	1	-1500.00	Fecha normalizada desde el formato legacy '2024/07/12'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.518828	compra
451	2024	f	108	Compra en tienda	2024-11-23	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.67276	retiro
327	2024	f	115	Sin descripcion	2024-06-19	1	-2000.00	Fecha normalizada desde el formato legacy '19/06/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.518858	compra
328	2024	t	113	Ingreso mensual	2024-06-13	1	500.00	Fecha normalizada desde el formato legacy '13/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.523502	deposito
329	2024	f	109	Retiro parcial	2024-02-12	1	-100.00	Fecha normalizada desde el formato legacy '12/02/2024'	2026-09-20 21:44:17.523528	compra
330	2024	f	104	Ingreso extra	2024-03-19	1	-500.00	Fecha normalizada desde el formato legacy '2024/03/19'	2026-09-20 21:44:17.523543	retiro
331	2024	f	110	Ingreso mensual	2024-11-25	1	-2000.00	Fecha normalizada desde el formato legacy '2024/11/25'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.523559	compra
332	2024	f	104	Sin descripcion	2024-07-16	1	-1000.00	Fecha normalizada desde el formato legacy '16-07-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.523573	compra
333	2024	f	120	Compra en tienda	2024-10-03	1	2500.00	Fecha normalizada desde el formato legacy '03-10-2024'	2026-09-20 21:44:17.527452	deposito
334	2024	f	120	Compra en tienda	2024-12-21	1	-500.00	Fecha normalizada desde el formato legacy '2024/12/21'	2026-09-20 21:44:17.527495	compra
335	2024	f	103	Ingreso navideño	2024-07-29	1	-3000.00	Fecha normalizada desde el formato legacy '29-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.527513	compra
336	2024	f	107	Ingreso mensual	2024-04-09	1	1000.00	Fecha normalizada desde el formato legacy '09/04/2024'	2026-09-20 21:44:17.527529	deposito
337	2024	f	115	Ingreso mensual	2024-12-22	1	-100.00	Fecha normalizada desde el formato legacy '2024/12/22'	2026-09-20 21:44:17.527541	retiro
338	2024	f	108	Ingreso extra	2024-09-22	1	-500.00	Fecha normalizada desde el formato legacy '22-09-2024'	2026-09-20 21:44:17.532028	retiro
339	2024	f	111	Ingreso extra	2024-12-04	1	1000.00	Fecha normalizada desde el formato legacy '04/12/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.532075	deposito
340	2024	f	110	Sin descripcion	2024-07-08	1	-2000.00	Fecha normalizada desde el formato legacy '2024/07/08'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.532092	retiro
341	2024	f	116	Retiro parcial	2024-10-07	1	-3000.00	Fecha normalizada desde el formato legacy '2024/10/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.532108	compra
342	2024	f	103	Ingreso navideño	2024-09-02	1	-1500.00	Fecha normalizada desde el formato legacy '02-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.532123	retiro
343	2024	t	108	Ingreso mensual	2024-03-12	1	500.00	Fecha normalizada desde el formato legacy '12-03-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.536677	deposito
344	2024	f	113	Ingreso mensual	2024-09-14	1	2000.00	Fecha normalizada desde el formato legacy '14-09-2024'	2026-09-20 21:44:17.536703	deposito
345	2024	f	118	Ingreso mensual	2024-09-01	1	-100.00	\N	2026-09-20 21:44:17.536717	compra
346	2024	f	112	Ingreso navideño	2024-06-12	1	-500.00	Fecha normalizada desde el formato legacy '12-06-2024'	2026-09-20 21:44:17.536732	retiro
347	2024	f	119	Ingreso navideño	2024-12-23	1	-500.00	Fecha normalizada desde el formato legacy '23-12-2024'	2026-09-20 21:44:17.536747	compra
348	2024	f	112	Ingreso mensual	2024-07-17	1	-100.00	Fecha normalizada desde el formato legacy '17-07-2024'	2026-09-20 21:44:17.541214	retiro
349	2024	t	115	Ingreso extra	2024-04-04	1	100.00	Fecha normalizada desde el formato legacy '2024/04/04'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.541242	deposito
350	2024	f	120	Sin descripcion	2024-07-10	1	-3000.00	Fecha normalizada desde el formato legacy '2024/07/10'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.541257	compra
351	2024	f	104	Retiro parcial	2024-04-02	1	1500.00	Fecha normalizada desde el formato legacy '2024/04/02'	2026-09-20 21:44:17.541269	deposito
352	2024	f	109	Sin descripcion	2024-01-21	1	2000.00	Fecha normalizada desde el formato legacy '21/01/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.549242	deposito
353	2024	f	118	Sin descripcion	2024-06-15	1	-3000.00	Fecha normalizada desde el formato legacy '15-06-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.549271	retiro
354	2024	f	105	Ingreso extra	2024-04-21	1	-1500.00	Fecha normalizada desde el formato legacy '21/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.549295	retiro
355	2024	f	103	Sin descripcion	2024-03-10	1	-3000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.54931	compra
356	2024	f	104	Ingreso extra	2024-05-23	1	-1500.00	Fecha normalizada desde el formato legacy '23-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.55598	compra
357	2024	f	119	Ingreso mensual	2024-05-22	1	1000.00	\N	2026-09-20 21:44:17.555992	deposito
358	2024	f	116	Ingreso mensual	2024-09-12	1	3000.00	Fecha normalizada desde el formato legacy '12-09-2024'	2026-09-20 21:44:17.556016	deposito
359	2024	f	116	Ingreso extra	2024-10-06	1	-2500.00	Fecha normalizada desde el formato legacy '2024/10/06'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.556029	retiro
360	2024	f	116	Ingreso extra	2024-09-22	1	2000.00	Fecha normalizada desde el formato legacy '22/09/2024'	2026-09-20 21:44:17.563132	deposito
361	2024	f	107	Retiro parcial	2024-08-08	1	-500.00	Fecha normalizada desde el formato legacy '08/08/2024'	2026-09-20 21:44:17.563149	compra
362	2024	f	110	Ingreso extra	2024-12-13	1	1000.00	Fecha normalizada desde el formato legacy '13-12-2024'	2026-09-20 21:44:17.563179	deposito
363	2024	f	102	Ingreso mensual	2024-05-23	1	-500.00	Fecha normalizada desde el formato legacy '2024/05/23'	2026-09-20 21:44:17.563192	pago
364	2024	f	113	Ingreso navideño	2024-12-03	1	-2000.00	Fecha normalizada desde el formato legacy '03/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.570459	retiro
365	2024	f	114	Sin descripcion	2024-05-14	1	-3000.00	Fecha normalizada desde el formato legacy '2024/05/14'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.570577	retiro
366	2024	f	110	Compra en tienda	2024-05-01	1	-2500.00	Fecha normalizada desde el formato legacy '2024/05/01'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.570676	retiro
368	2024	f	103	Sin descripcion	2024-07-15	1	-3000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.581403	pago
369	2024	f	102	Sin descripcion	2024-08-03	1	-1000.00	Fecha normalizada desde el formato legacy '2024/08/03'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.581475	pago
370	2024	f	112	Ingreso navideño	2024-11-25	1	1500.00	Fecha normalizada desde el formato legacy '25-11-2024'	2026-09-20 21:44:17.581515	deposito
371	2024	f	117	Retiro parcial	2024-04-27	1	-3000.00	Fecha normalizada desde el formato legacy '27-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.581549	compra
372	2024	f	110	Compra en tienda	2024-08-11	1	-500.00	Fecha normalizada desde el formato legacy '2024/08/11'	2026-09-20 21:44:17.586561	compra
373	2024	f	116	Ingreso mensual	2024-12-06	1	-2000.00	Fecha normalizada desde el formato legacy '06/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.586579	retiro
374	2024	f	112	Sin descripcion	2024-08-26	1	-1500.00	Fecha normalizada desde el formato legacy '2024/08/26'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.586591	retiro
375	2024	t	107	Ingreso mensual	2024-03-09	1	500.00	Fecha normalizada desde el formato legacy '09/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.586606	deposito
376	2024	f	117	Ingreso mensual	2024-03-07	1	-3000.00	Fecha normalizada desde el formato legacy '2024/03/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.595523	retiro
377	2024	f	101	Ingreso mensual	2024-10-06	1	1500.00	Fecha normalizada desde el formato legacy '06-10-2024'	2026-09-20 21:44:17.595552	deposito
378	2024	f	116	Ingreso navideño	2024-01-03	1	2500.00	\N	2026-09-20 21:44:17.595568	deposito
379	2024	f	117	Ingreso extra	2024-12-08	1	-3000.00	Fecha normalizada desde el formato legacy '2024/12/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.595583	retiro
380	2024	f	108	Ingreso extra	2024-11-02	1	2500.00	Fecha normalizada desde el formato legacy '2024/11/02'	2026-09-20 21:44:17.595595	deposito
381	2024	f	102	Sin descripcion	2024-02-14	1	-3000.00	Fecha normalizada desde el formato legacy '2024/02/14'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.601039	retiro
382	2024	f	119	Ingreso navideño	2024-10-24	1	1000.00	Fecha normalizada desde el formato legacy '24/10/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.601082	deposito
383	2024	f	118	Sin descripcion	2024-03-26	1	-1500.00	Fecha normalizada desde el formato legacy '26-03-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.601098	compra
384	2024	f	102	Ingreso mensual	2024-10-12	1	-1500.00	Fecha normalizada desde el formato legacy '2024/10/12'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.60113	retiro
385	2024	f	110	Retiro parcial	2024-01-14	1	-1500.00	Fecha normalizada desde el formato legacy '14-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.601143	pago
386	2024	f	111	Retiro parcial	2024-11-04	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.605323	retiro
387	2024	f	109	Ingreso extra	2024-02-13	1	-500.00	Fecha normalizada desde el formato legacy '2024/02/13'	2026-09-20 21:44:17.605337	pago
388	2024	f	109	Retiro parcial	2024-10-18	1	-1000.00	Fecha normalizada desde el formato legacy '2024/10/18'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.605357	compra
389	2024	f	105	Retiro parcial	2024-01-12	1	1000.00	Fecha normalizada desde el formato legacy '12/01/2024'	2026-09-20 21:44:17.605372	deposito
390	2024	t	103	Compra en tienda	2024-12-08	1	500.00	Fecha normalizada desde el formato legacy '08-12-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.612555	deposito
391	2024	f	115	Sin descripcion	2024-12-28	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.612586	deposito
392	2024	f	116	Ingreso navideño	2024-04-05	1	-500.00	Fecha normalizada desde el formato legacy '2024/04/05'	2026-09-20 21:44:17.612618	compra
393	2024	t	107	Retiro parcial	2024-05-31	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.612629	deposito
394	2024	f	101	Ingreso navideño	2024-12-22	1	2500.00	Fecha normalizada desde el formato legacy '22/12/2024'	2026-09-20 21:44:17.612644	deposito
395	2024	f	104	Ingreso mensual	2024-11-05	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.61825	pago
396	2024	f	110	Ingreso mensual	2024-11-23	1	-1500.00	Fecha normalizada desde el formato legacy '23/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.618333	compra
397	2024	f	101	Ingreso extra	2024-04-26	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.618369	compra
398	2024	f	115	Compra en tienda	2024-11-13	1	-2000.00	Fecha normalizada desde el formato legacy '13/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.618408	compra
399	2024	f	101	Ingreso extra	2024-06-12	1	2000.00	Fecha normalizada desde el formato legacy '12-06-2024'	2026-09-20 21:44:17.61844	deposito
400	2024	f	109	Ingreso mensual	2024-07-14	1	2000.00	Fecha normalizada desde el formato legacy '14-07-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.622929	deposito
401	2024	f	101	Sin descripcion	2024-11-22	1	-1000.00	Fecha normalizada desde el formato legacy '22-11-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.622961	retiro
402	2024	t	106	Ingreso extra	2024-09-26	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.622975	deposito
403	2024	f	119	Compra en tienda	2024-10-18	1	-100.00	\N	2026-09-20 21:44:17.622988	retiro
404	2024	f	102	Retiro parcial	2024-08-24	1	-500.00	Fecha normalizada desde el formato legacy '24/08/2024'	2026-09-20 21:44:17.623005	retiro
405	2024	f	113	Ingreso mensual	2024-02-27	1	1000.00	\N	2026-09-20 21:44:17.628843	deposito
406	2024	f	108	Ingreso extra	2024-07-17	1	-3000.00	Fecha normalizada desde el formato legacy '17/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.628875	compra
407	2024	f	112	Sin descripcion	2024-01-20	1	-5000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.628889	retiro
408	2024	f	119	Sin descripcion	2024-07-01	1	2000.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.6289	deposito
409	2024	f	117	Compra en tienda	2024-03-29	1	-2000.00	Fecha normalizada desde el formato legacy '2024/03/29'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.628915	compra
410	2024	f	113	Compra en tienda	2024-03-09	1	-100.00	\N	2026-09-20 21:44:17.632684	compra
411	2024	f	111	Sin descripcion	2024-10-31	1	-500.00	Fecha normalizada desde el formato legacy '2024/10/31'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.632716	retiro
412	2024	f	120	Compra en tienda	2024-04-15	1	-1000.00	Fecha normalizada desde el formato legacy '15-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.632731	pago
413	2024	f	112	Ingreso extra	2024-10-06	1	2000.00	\N	2026-09-20 21:44:17.632742	deposito
414	2024	f	102	Ingreso mensual	2024-05-26	1	-2500.00	Fecha normalizada desde el formato legacy '2024/05/26'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.632754	pago
415	2024	f	105	Ingreso mensual	2024-05-24	1	-3000.00	Fecha normalizada desde el formato legacy '24/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.638196	compra
416	2024	f	107	Sin descripcion	2024-03-03	1	-1500.00	Fecha normalizada desde el formato legacy '03/03/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.638216	retiro
417	2024	t	105	Retiro parcial	2024-05-13	1	100.00	Fecha normalizada desde el formato legacy '13-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.638246	deposito
418	2024	f	106	Sin descripcion	2024-01-29	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.638256	deposito
419	2024	f	104	Sin descripcion	2024-06-24	1	-1000.00	Fecha normalizada desde el formato legacy '2024/06/24'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.644827	retiro
420	2024	f	109	Sin descripcion	2024-08-30	1	3000.00	Fecha normalizada desde el formato legacy '30-08-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.644896	deposito
421	2024	f	118	Ingreso extra	2024-12-17	1	2500.00	Fecha normalizada desde el formato legacy '17/12/2024'	2026-09-20 21:44:17.644928	deposito
422	2024	f	104	Ingreso navideño	2024-04-15	1	-3000.00	Fecha normalizada desde el formato legacy '15/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.64495	compra
423	2024	f	107	Retiro parcial	2024-05-02	1	2500.00	Fecha normalizada desde el formato legacy '2024/05/02'	2026-09-20 21:44:17.644964	deposito
424	2024	f	118	Sin descripcion	2024-11-14	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.649216	retiro
425	2024	f	102	Retiro parcial	2024-10-04	1	-500.00	Fecha normalizada desde el formato legacy '04/10/2024'	2026-09-20 21:44:17.649248	compra
426	2024	f	114	Compra en tienda	2024-04-23	1	1500.00	\N	2026-09-20 21:44:17.649261	deposito
427	2024	f	119	Ingreso navideño	2024-11-18	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.649271	retiro
428	2024	f	111	Compra en tienda	2024-01-25	1	2500.00	Fecha normalizada desde el formato legacy '25/01/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.649308	deposito
429	2024	f	117	Ingreso extra	2024-09-13	1	-1500.00	Fecha normalizada desde el formato legacy '13-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.654237	pago
430	2024	f	102	Ingreso extra	2024-05-11	1	-100.00	Fecha normalizada desde el formato legacy '11/05/2024'	2026-09-20 21:44:17.654393	retiro
431	2024	f	112	Ingreso navideño	2024-05-30	1	-100.00	\N	2026-09-20 21:44:17.654422	pago
432	2024	f	106	Compra en tienda	2024-07-20	1	-2000.00	Fecha normalizada desde el formato legacy '2024/07/20'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.654549	compra
433	2024	f	103	Sin descripcion	2024-12-23	1	-2500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.65459	retiro
434	2024	f	120	Retiro parcial	2024-02-07	1	1500.00	\N	2026-09-20 21:44:17.65881	deposito
435	2024	f	120	Sin descripcion	2024-01-16	1	-2000.00	Fecha normalizada desde el formato legacy '16/01/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.658931	compra
436	2024	f	109	Compra en tienda	2024-11-14	1	1500.00	\N	2026-09-20 21:44:17.658978	deposito
437	2024	t	113	Ingreso navideño	2024-09-08	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.659003	deposito
438	2024	f	109	Retiro parcial	2024-03-10	1	3000.00	Fecha normalizada desde el formato legacy '10-03-2024'	2026-09-20 21:44:17.659058	deposito
439	2024	f	106	Ingreso navideño	2024-02-22	1	-1000.00	Fecha normalizada desde el formato legacy '22/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.663896	compra
440	2024	f	105	Ingreso mensual	2024-07-10	1	-3000.00	Fecha normalizada desde el formato legacy '10-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.663918	retiro
441	2024	f	102	Ingreso extra	2024-12-09	1	1500.00	Fecha normalizada desde el formato legacy '09/12/2024'	2026-09-20 21:44:17.663936	deposito
442	2024	f	119	Sin descripcion	2024-08-17	1	-2500.00	Fecha normalizada desde el formato legacy '17-08-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.663953	compra
443	2024	f	120	Ingreso navideño	2024-05-15	1	-500.00	\N	2026-09-20 21:44:17.663965	retiro
444	2024	t	110	Sin descripcion	2024-11-15	1	0.00	Fecha normalizada desde el formato legacy '2024/11/15'; Monto no positivo; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.667851	deposito
445	2024	f	114	Compra en tienda	2024-12-29	1	2000.00	Fecha normalizada desde el formato legacy '29/12/2024'	2026-09-20 21:44:17.667903	deposito
446	2024	f	102	Sin descripcion	2024-10-06	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.667917	retiro
447	2024	f	109	Retiro parcial	2024-06-25	1	2500.00	\N	2026-09-20 21:44:17.667928	deposito
448	2024	f	104	Sin descripcion	2024-08-09	1	-3000.00	Fecha normalizada desde el formato legacy '09-08-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.667943	compra
449	2024	f	115	Ingreso extra	2024-01-23	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.672724	compra
450	2024	f	119	Sin descripcion	2024-08-08	1	-1000.00	Fecha normalizada desde el formato legacy '08/08/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.672749	compra
452	2024	f	112	Compra en tienda	2024-06-01	1	-3000.00	Fecha normalizada desde el formato legacy '01/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.672777	retiro
453	2024	f	104	Ingreso navideño	2024-01-13	1	-3000.00	Fecha normalizada desde el formato legacy '13-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.679401	compra
454	2024	f	117	Retiro parcial	2024-04-25	1	-100.00	Fecha normalizada desde el formato legacy '25/04/2024'	2026-09-20 21:44:17.679496	compra
455	2024	f	115	Sin descripcion	2024-11-24	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.679531	retiro
456	2024	f	112	Ingreso mensual	2024-08-09	1	1500.00	Fecha normalizada desde el formato legacy '09-08-2024'	2026-09-20 21:44:17.67957	deposito
457	2024	f	114	Sin descripcion	2024-06-08	1	-2000.00	Fecha normalizada desde el formato legacy '2024/06/08'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.679597	retiro
458	2024	f	120	Retiro parcial	2024-04-03	1	-2000.00	Fecha normalizada desde el formato legacy '2024/04/03'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.683851	compra
459	2024	f	113	Sin descripcion	2024-10-29	1	2000.00	Fecha normalizada desde el formato legacy '29/10/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.68387	deposito
460	2024	f	115	Ingreso extra	2024-03-10	1	3000.00	Fecha normalizada desde el formato legacy '2024/03/10'	2026-09-20 21:44:17.683883	deposito
461	2024	f	117	Ingreso navideño	2024-11-07	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.683892	compra
462	2024	f	114	Retiro parcial	2024-04-16	1	-1500.00	Fecha normalizada desde el formato legacy '2024/04/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.683904	compra
463	2024	f	104	Ingreso mensual	2024-01-04	1	1000.00	Fecha normalizada desde el formato legacy '04/01/2024'	2026-09-20 21:44:17.6879	deposito
464	2024	f	113	Compra en tienda	2024-12-02	1	2000.00	Fecha normalizada desde el formato legacy '02/12/2024'	2026-09-20 21:44:17.687916	deposito
465	2024	f	106	Ingreso mensual	2024-06-28	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.68793	retiro
466	2024	t	101	Compra en tienda	2024-08-24	1	0.00	Fecha normalizada desde el formato legacy '2024/08/24'; Monto no positivo	2026-09-20 21:44:17.687944	compra
467	2024	f	105	Ingreso navideño	2024-05-29	1	3000.00	Fecha normalizada desde el formato legacy '2024/05/29'	2026-09-20 21:44:17.6932	deposito
468	2024	f	115	Sin descripcion	2024-03-01	1	-1000.00	Fecha normalizada desde el formato legacy '01/03/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.693225	retiro
469	2024	f	104	Compra en tienda	2024-07-03	1	2000.00	Fecha normalizada desde el formato legacy '2024/07/03'	2026-09-20 21:44:17.693238	deposito
470	2024	f	120	Retiro parcial	2024-02-12	1	-1500.00	Fecha normalizada desde el formato legacy '2024/02/12'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.693251	compra
471	2024	f	112	Ingreso navideño	2024-04-06	1	-1500.00	Fecha normalizada desde el formato legacy '2024/04/06'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.693262	compra
472	2024	f	120	Ingreso mensual	2024-07-28	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.698826	retiro
473	2024	f	110	Ingreso navideño	2024-06-20	1	-500.00	\N	2026-09-20 21:44:17.698878	retiro
474	2024	f	115	Ingreso mensual	2024-04-25	1	-100.00	Fecha normalizada desde el formato legacy '25-04-2024'	2026-09-20 21:44:17.698913	retiro
475	2024	f	111	Ingreso navideño	2024-09-25	1	-2500.00	Fecha normalizada desde el formato legacy '25-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.698927	compra
476	2024	f	102	Sin descripcion	2024-03-30	1	-3000.00	Fecha normalizada desde el formato legacy '30/03/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.698943	compra
477	2024	f	116	Compra en tienda	2024-05-15	1	-1000.00	Fecha normalizada desde el formato legacy '15/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.705675	retiro
478	2024	f	105	Ingreso navideño	2024-01-29	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.705715	compra
479	2024	f	110	Ingreso navideño	2024-04-17	1	-3000.00	Fecha normalizada desde el formato legacy '17/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.705787	compra
480	2024	t	108	Ingreso navideño	2024-11-21	1	500.00	Fecha normalizada desde el formato legacy '2024/11/21'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.70585	deposito
481	2024	f	105	Retiro parcial	2024-04-20	1	-500.00	Fecha normalizada desde el formato legacy '2024/04/20'	2026-09-20 21:44:17.705872	retiro
482	2024	f	110	Ingreso navideño	2024-11-01	1	-500.00	Fecha normalizada desde el formato legacy '2024/11/01'	2026-09-20 21:44:17.712486	retiro
483	2024	f	108	Sin descripcion	2024-04-01	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/01'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.712665	retiro
484	2024	f	120	Ingreso mensual	2024-07-13	1	1500.00	Fecha normalizada desde el formato legacy '2024/07/13'	2026-09-20 21:44:17.712745	deposito
485	2024	f	117	Ingreso navideño	2024-04-27	1	1500.00	Fecha normalizada desde el formato legacy '27/04/2024'	2026-09-20 21:44:17.712778	deposito
486	2024	f	120	Sin descripcion	2024-12-27	1	-100.00	Fecha normalizada desde el formato legacy '2024/12/27'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.712797	compra
487	2024	t	104	Sin descripcion	2024-07-07	1	100.00	Fecha normalizada desde el formato legacy '2024/07/07'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.718584	deposito
488	2024	f	111	Ingreso extra	2024-08-15	1	1500.00	Fecha normalizada desde el formato legacy '15/08/2024'	2026-09-20 21:44:17.718702	deposito
489	2024	f	106	Compra en tienda	2024-08-27	1	2000.00	Fecha normalizada desde el formato legacy '27-08-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.718793	deposito
490	2024	f	109	Retiro parcial	2024-08-29	1	-2500.00	Fecha normalizada desde el formato legacy '29-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.718823	retiro
491	2024	f	105	Sin descripcion	2024-07-01	1	-1500.00	Fecha normalizada desde el formato legacy '2024/07/01'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.72658	compra
492	2024	f	112	Ingreso extra	2024-07-18	1	1000.00	Fecha normalizada desde el formato legacy '18-07-2024'	2026-09-20 21:44:17.726602	deposito
493	2024	t	117	Ingreso navideño	2024-11-15	1	0.00	Fecha normalizada desde el formato legacy '15/11/2024'; Monto no positivo	2026-09-20 21:44:17.72667	deposito
494	2024	f	103	Sin descripcion	2024-10-11	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.726774	deposito
495	2024	f	102	Ingreso extra	2024-10-20	1	3000.00	Fecha normalizada desde el formato legacy '20/10/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.726928	deposito
496	2024	f	102	Ingreso extra	2024-03-02	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.732081	compra
497	2024	f	115	Ingreso extra	2024-03-13	1	-1500.00	Fecha normalizada desde el formato legacy '13-03-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.732095	compra
498	2024	f	108	Retiro parcial	2024-10-01	1	-1000.00	Fecha normalizada desde el formato legacy '2024/10/01'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.732107	retiro
499	2024	f	116	Compra en tienda	2024-05-28	1	-3000.00	Fecha normalizada desde el formato legacy '28-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.732125	compra
500	2024	f	104	Ingreso mensual	2024-08-13	1	-500.00	Fecha normalizada desde el formato legacy '13-08-2024'	2026-09-20 21:44:17.739616	retiro
501	2024	f	119	Ingreso navideño	2024-09-19	1	-500.00	Fecha normalizada desde el formato legacy '19-09-2024'	2026-09-20 21:44:17.739632	retiro
502	2024	f	114	Sin descripcion	2024-11-03	1	-2000.00	Fecha normalizada desde el formato legacy '03/11/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.739646	retiro
503	2024	f	108	Ingreso mensual	2024-02-03	1	-2500.00	Fecha normalizada desde el formato legacy '03-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.739673	retiro
504	2024	f	109	Sin descripcion	2024-06-20	1	3000.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.747237	deposito
505	2024	f	106	Ingreso extra	2024-03-25	1	-2000.00	Fecha normalizada desde el formato legacy '25/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.747266	compra
506	2024	f	106	Ingreso mensual	2024-08-22	1	-500.00	Fecha normalizada desde el formato legacy '22/08/2024'	2026-09-20 21:44:17.747286	compra
507	2024	f	115	Sin descripcion	2024-10-24	1	-1000.00	Fecha normalizada desde el formato legacy '24/10/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.747303	retiro
508	2024	f	102	Compra en tienda	2024-10-01	1	-500.00	Fecha normalizada desde el formato legacy '01-10-2024'	2026-09-20 21:44:17.747317	compra
509	2024	f	119	Ingreso extra	2024-12-13	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.752558	retiro
510	2024	f	106	Retiro parcial	2024-06-25	1	1000.00	Fecha normalizada desde el formato legacy '25/06/2024'	2026-09-20 21:44:17.752642	deposito
511	2024	f	105	Retiro parcial	2024-04-10	1	-500.00	Fecha normalizada desde el formato legacy '10/04/2024'	2026-09-20 21:44:17.75269	retiro
512	2024	f	115	Sin descripcion	2024-02-22	1	1500.00	Fecha normalizada desde el formato legacy '2024/02/22'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.75274	deposito
513	2024	f	113	Ingreso extra	2024-08-30	1	-2000.00	Fecha normalizada desde el formato legacy '2024/08/30'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.752768	retiro
514	2024	f	115	Ingreso mensual	2024-04-24	1	2000.00	Fecha normalizada desde el formato legacy '2024/04/24'	2026-09-20 21:44:17.757405	deposito
515	2024	f	106	Compra en tienda	2024-01-30	1	-500.00	Fecha normalizada desde el formato legacy '30/01/2024'	2026-09-20 21:44:17.757449	retiro
516	2024	f	118	Sin descripcion	2024-06-19	1	3000.00	Fecha normalizada desde el formato legacy '19-06-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.757464	deposito
517	2024	f	113	Ingreso navideño	2024-06-09	1	3000.00	Fecha normalizada desde el formato legacy '09-06-2024'	2026-09-20 21:44:17.757477	deposito
518	2024	f	110	Ingreso extra	2024-03-24	1	-100.00	Fecha normalizada desde el formato legacy '24-03-2024'	2026-09-20 21:44:17.75749	compra
519	2024	f	107	Retiro parcial	2024-03-29	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.761524	retiro
520	2024	f	112	Ingreso navideño	2024-04-29	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/29'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.76156	retiro
521	2024	f	102	Sin descripcion	2024-05-18	1	-1000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.761573	compra
522	2024	f	102	Ingreso navideño	2024-06-26	1	-100.00	\N	2026-09-20 21:44:17.761584	retiro
523	2024	f	101	Sin descripcion	2024-03-07	1	3000.00	Fecha normalizada desde el formato legacy '07/03/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.761604	deposito
524	2024	f	111	Retiro parcial	2024-10-06	1	1500.00	Fecha normalizada desde el formato legacy '06-10-2024'	2026-09-20 21:44:17.766981	deposito
525	2024	f	112	Sin descripcion	2024-08-07	1	-3000.00	Fecha normalizada desde el formato legacy '07-08-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.767063	retiro
526	2024	t	112	Compra en tienda	2024-09-06	1	0.00	Fecha normalizada desde el formato legacy '2024/09/06'; Monto no positivo	2026-09-20 21:44:17.76714	deposito
527	2024	f	118	Ingreso mensual	2024-10-03	1	3000.00	Fecha normalizada desde el formato legacy '03-10-2024'	2026-09-20 21:44:17.767183	deposito
528	2024	f	118	Sin descripcion	2024-05-12	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.767256	pago
529	2024	f	116	Sin descripcion	2024-11-14	1	3000.00	Fecha normalizada desde el formato legacy '14/11/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.772321	deposito
530	2024	f	110	Retiro parcial	2024-03-07	1	-100.00	Fecha normalizada desde el formato legacy '07/03/2024'	2026-09-20 21:44:17.772354	retiro
531	2024	f	116	Ingreso navideño	2024-04-28	1	1000.00	Fecha normalizada desde el formato legacy '28-04-2024'	2026-09-20 21:44:17.77237	deposito
532	2024	t	116	Ingreso extra	2024-10-12	1	100.00	Fecha normalizada desde el formato legacy '12-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.772457	deposito
533	2024	f	118	Compra en tienda	2024-04-07	1	1000.00	Fecha normalizada desde el formato legacy '07/04/2024'	2026-09-20 21:44:17.772554	deposito
534	2024	f	118	Sin descripcion	2024-01-19	1	-1000.00	Fecha normalizada desde el formato legacy '19-01-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.777363	retiro
535	2024	f	111	Retiro parcial	2024-07-07	1	2500.00	Fecha normalizada desde el formato legacy '07-07-2024'	2026-09-20 21:44:17.777388	deposito
536	2024	f	118	Ingreso navideño	2024-07-14	1	3000.00	\N	2026-09-20 21:44:17.777402	deposito
537	2024	f	117	Sin descripcion	2024-09-04	1	-5000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.777413	retiro
538	2024	f	102	Ingreso navideño	2024-08-09	1	-3000.00	Fecha normalizada desde el formato legacy '09-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.777429	compra
539	2024	f	118	Compra en tienda	2024-01-06	1	-3000.00	Fecha normalizada desde el formato legacy '06-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.782973	compra
540	2024	f	120	Ingreso extra	2024-11-18	1	-2000.00	Fecha normalizada desde el formato legacy '18-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.783018	retiro
541	2024	f	108	Sin descripcion	2024-06-21	1	-2500.00	Fecha normalizada desde el formato legacy '21/06/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.783038	retiro
542	2024	f	105	Sin descripcion	2024-07-04	1	1000.00	Fecha normalizada desde el formato legacy '04/07/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.783053	deposito
543	2024	f	101	Ingreso extra	2024-08-01	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.783063	retiro
544	2024	f	110	Sin descripcion	2024-08-05	1	1000.00	Fecha normalizada desde el formato legacy '05/08/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.788235	deposito
545	2024	f	107	Sin descripcion	2024-04-03	1	-500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.788252	retiro
546	2024	f	104	Ingreso mensual	2024-08-29	1	-2500.00	Fecha normalizada desde el formato legacy '2024/08/29'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.788266	retiro
547	2024	t	108	Ingreso mensual	2024-11-17	1	100.00	Fecha normalizada desde el formato legacy '2024/11/17'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.788279	deposito
548	2024	f	103	Ingreso mensual	2024-05-08	1	-1000.00	Fecha normalizada desde el formato legacy '2024/05/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.788291	compra
549	2024	f	102	Ingreso extra	2024-03-13	1	-100.00	Fecha normalizada desde el formato legacy '13-03-2024'	2026-09-20 21:44:17.793187	compra
550	2024	f	102	Ingreso mensual	2024-10-11	1	-1500.00	Fecha normalizada desde el formato legacy '2024/10/11'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.793198	retiro
551	2024	f	101	Ingreso navideño	2024-04-20	1	-100.00	Fecha normalizada desde el formato legacy '2024/04/20'	2026-09-20 21:44:17.793209	compra
552	2024	f	114	Ingreso extra	2024-04-13	1	-100.00	Fecha normalizada desde el formato legacy '2024/04/13'	2026-09-20 21:44:17.79328	compra
553	2024	f	105	Ingreso navideño	2024-02-14	1	-100.00	Fecha normalizada desde el formato legacy '14/02/2024'	2026-09-20 21:44:17.800142	retiro
554	2024	f	112	Sin descripcion	2024-09-27	1	2000.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.800168	deposito
555	2024	t	119	Retiro parcial	2024-02-16	1	500.00	Fecha normalizada desde el formato legacy '16-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.800186	deposito
556	2024	f	101	Sin descripcion	2024-04-08	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.800197	retiro
557	2024	f	118	Sin descripcion	2024-08-01	1	2500.00	Fecha normalizada desde el formato legacy '01/08/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.800218	deposito
558	2024	f	108	Retiro parcial	2024-04-17	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.805456	compra
559	2024	f	106	Ingreso extra	2024-03-15	1	-2500.00	Fecha normalizada desde el formato legacy '15/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.805555	compra
560	2024	f	105	Ingreso extra	2024-01-12	1	-1500.00	Fecha normalizada desde el formato legacy '12/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.805579	retiro
561	2024	f	102	Ingreso mensual	2024-04-03	1	-3000.00	Fecha normalizada desde el formato legacy '03-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.805593	retiro
562	2024	t	106	Sin descripcion	2024-12-11	1	100.00	Fecha normalizada desde el formato legacy '11-12-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.805608	deposito
563	2024	f	112	Ingreso navideño	2024-10-16	1	-100.00	Fecha normalizada desde el formato legacy '2024/10/16'	2026-09-20 21:44:17.809327	retiro
564	2024	f	106	Ingreso extra	2024-02-22	1	-1500.00	Fecha normalizada desde el formato legacy '22-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.809351	compra
565	2024	t	120	Retiro parcial	2024-08-06	1	500.00	Fecha normalizada desde el formato legacy '06-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.809367	deposito
566	2024	t	105	Ingreso navideño	2024-11-30	1	500.00	Fecha normalizada desde el formato legacy '30/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.809382	deposito
567	2024	t	103	Ingreso navideño	2024-09-04	1	500.00	Fecha normalizada desde el formato legacy '04-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.809394	deposito
568	2024	f	115	Retiro parcial	2024-07-26	1	-500.00	Fecha normalizada desde el formato legacy '26/07/2024'	2026-09-20 21:44:17.813352	compra
569	2024	f	104	Retiro parcial	2024-10-01	1	-500.00	Fecha normalizada desde el formato legacy '01/10/2024'	2026-09-20 21:44:17.813377	pago
570	2024	f	109	Ingreso extra	2024-03-18	1	-500.00	Fecha normalizada desde el formato legacy '18-03-2024'	2026-09-20 21:44:17.813392	compra
571	2024	f	118	Retiro parcial	2024-09-12	1	-100.00	Fecha normalizada desde el formato legacy '12/09/2024'	2026-09-20 21:44:17.813407	compra
572	2024	f	111	Compra en tienda	2024-08-05	1	-100.00	Fecha normalizada desde el formato legacy '05/08/2024'	2026-09-20 21:44:17.813421	retiro
573	2024	f	103	Ingreso mensual	2024-10-26	1	-2000.00	Fecha normalizada desde el formato legacy '26-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.819111	compra
574	2024	f	109	Ingreso navideño	2024-02-17	1	1000.00	Fecha normalizada desde el formato legacy '17-02-2024'	2026-09-20 21:44:17.819125	deposito
575	2024	t	114	Retiro parcial	2024-08-10	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.819133	deposito
576	2024	f	115	Ingreso mensual	2024-09-14	1	-100.00	Fecha normalizada desde el formato legacy '2024/09/14'	2026-09-20 21:44:17.819172	compra
577	2024	f	114	Ingreso navideño	2024-02-19	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.826401	retiro
578	2024	f	104	Ingreso mensual	2024-04-02	1	-100.00	\N	2026-09-20 21:44:17.826509	retiro
579	2024	f	106	Ingreso navideño	2024-12-07	1	-2500.00	Fecha normalizada desde el formato legacy '07-12-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.826555	retiro
580	2024	f	108	Ingreso navideño	2024-01-29	1	-3000.00	Fecha normalizada desde el formato legacy '29-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.826572	retiro
581	2024	f	101	Compra en tienda	2024-01-17	1	-100.00	Fecha normalizada desde el formato legacy '17/01/2024'	2026-09-20 21:44:17.826587	retiro
582	2024	f	116	Ingreso mensual	2024-05-25	1	3000.00	Fecha normalizada desde el formato legacy '2024/05/25'	2026-09-20 21:44:17.831766	deposito
583	2024	f	110	Retiro parcial	2024-12-24	1	-3000.00	Fecha normalizada desde el formato legacy '24/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.831795	retiro
584	2024	f	102	Ingreso navideño	2024-10-10	1	-100.00	\N	2026-09-20 21:44:17.831806	retiro
585	2024	t	106	Retiro parcial	2024-07-12	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.831826	deposito
586	2024	f	114	Ingreso navideño	2024-03-26	1	2000.00	\N	2026-09-20 21:44:17.839603	deposito
587	2024	f	105	Ingreso mensual	2024-06-07	1	2000.00	\N	2026-09-20 21:44:17.83963	deposito
588	2024	f	120	Sin descripcion	2024-02-27	1	-5000.00	Fecha normalizada desde el formato legacy '27-02-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.83968	retiro
589	2024	f	119	Ingreso navideño	2024-07-25	1	-2500.00	Fecha normalizada desde el formato legacy '2024/07/25'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.839747	retiro
590	2024	f	106	Ingreso navideño	2024-08-31	1	-100.00	Fecha normalizada desde el formato legacy '31/08/2024'	2026-09-20 21:44:17.846008	compra
591	2024	f	103	Sin descripcion	2024-06-25	1	1500.00	Fecha normalizada desde el formato legacy '25-06-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.846028	deposito
592	2024	f	112	Ingreso extra	2024-12-01	1	-2000.00	Fecha normalizada desde el formato legacy '01/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.846045	compra
593	2024	t	106	Sin descripcion	2024-04-10	1	500.00	Fecha normalizada desde el formato legacy '10/04/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.84606	deposito
594	2024	f	109	Compra en tienda	2024-05-11	1	-3000.00	Fecha normalizada desde el formato legacy '11-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.846072	retiro
595	2024	f	114	Ingreso mensual	2024-12-22	1	1500.00	Fecha normalizada desde el formato legacy '22/12/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.850172	deposito
596	2024	f	105	Ingreso navideño	2024-12-09	1	-1500.00	Fecha normalizada desde el formato legacy '09/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.850214	retiro
597	2024	f	109	Ingreso navideño	2024-07-20	1	1500.00	Fecha normalizada desde el formato legacy '20/07/2024'	2026-09-20 21:44:17.850233	deposito
598	2024	f	109	Ingreso mensual	2024-11-11	1	-3000.00	Fecha normalizada desde el formato legacy '11-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.850247	compra
599	2024	f	105	Retiro parcial	2024-04-18	1	-3000.00	Fecha normalizada desde el formato legacy '2024/04/18'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.85026	pago
600	2024	f	114	Sin descripcion	2024-12-10	1	1500.00	Fecha normalizada desde el formato legacy '10-12-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.854416	deposito
601	2024	f	105	Ingreso extra	2024-05-23	1	-100.00	\N	2026-09-20 21:44:17.854434	compra
602	2024	f	103	Retiro parcial	2024-04-03	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/03'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.854447	compra
603	2024	f	102	Ingreso navideño	2024-04-23	1	-2000.00	Fecha normalizada desde el formato legacy '23-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.85446	compra
604	2024	f	101	Ingreso extra	2024-06-30	1	1500.00	\N	2026-09-20 21:44:17.85447	deposito
605	2024	f	106	Retiro parcial	2024-01-29	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.858861	compra
606	2024	f	105	Sin descripcion	2024-12-04	1	-1000.00	Fecha normalizada desde el formato legacy '04-12-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.858888	compra
607	2024	f	105	Retiro parcial	2024-01-27	1	2000.00	Fecha normalizada desde el formato legacy '27-01-2024'	2026-09-20 21:44:17.858903	deposito
608	2024	f	105	Ingreso extra	2024-08-16	1	2500.00	Fecha normalizada desde el formato legacy '16-08-2024'	2026-09-20 21:44:17.858919	deposito
609	2024	t	117	Compra en tienda	2024-08-02	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.858927	deposito
610	2024	f	113	Compra en tienda	2024-10-29	1	-2000.00	Fecha normalizada desde el formato legacy '29/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.863935	compra
611	2024	f	104	Retiro parcial	2024-02-17	1	1500.00	Fecha normalizada desde el formato legacy '17/02/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.863959	deposito
612	2024	f	118	Sin descripcion	2024-02-18	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.863968	deposito
613	2024	f	117	Retiro parcial	2024-11-17	1	1500.00	Fecha normalizada desde el formato legacy '2024/11/17'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.863999	deposito
614	2024	f	105	Ingreso extra	2024-11-28	1	1500.00	Fecha normalizada desde el formato legacy '28/11/2024'	2026-09-20 21:44:17.869692	deposito
615	2024	t	103	Retiro parcial	2024-05-09	1	500.00	Fecha normalizada desde el formato legacy '09-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.869705	deposito
616	2024	f	108	Retiro parcial	2024-09-03	1	-1000.00	Fecha normalizada desde el formato legacy '03-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.869727	compra
617	2024	f	114	Sin descripcion	2024-10-10	1	-1500.00	Fecha normalizada desde el formato legacy '2024/10/10'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.869738	compra
618	2024	f	118	Ingreso extra	2024-02-07	1	-3000.00	Fecha normalizada desde el formato legacy '2024/02/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.878065	compra
619	2024	f	107	Ingreso mensual	2024-12-12	1	-2000.00	Fecha normalizada desde el formato legacy '2024/12/12'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.878139	retiro
620	2024	f	103	Compra en tienda	2024-04-22	1	-100.00	Fecha normalizada desde el formato legacy '22-04-2024'	2026-09-20 21:44:17.878209	compra
621	2024	f	102	Ingreso mensual	2024-04-16	1	1500.00	Fecha normalizada desde el formato legacy '16/04/2024'	2026-09-20 21:44:17.878271	deposito
622	2024	f	101	Ingreso extra	2024-09-05	1	2500.00	Fecha normalizada desde el formato legacy '05/09/2024'	2026-09-20 21:44:17.878307	deposito
623	2024	f	117	Ingreso extra	2024-03-01	1	3000.00	\N	2026-09-20 21:44:17.882723	deposito
624	2024	f	107	Retiro parcial	2024-08-28	1	-500.00	Fecha normalizada desde el formato legacy '28-08-2024'	2026-09-20 21:44:17.882751	pago
625	2024	f	119	Ingreso navideño	2024-05-13	1	2000.00	Fecha normalizada desde el formato legacy '2024/05/13'	2026-09-20 21:44:17.882764	deposito
626	2024	t	104	Sin descripcion	2024-10-01	1	100.00	Fecha normalizada desde el formato legacy '01/10/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.882778	deposito
627	2024	f	107	Retiro parcial	2024-06-18	1	-2000.00	Fecha normalizada desde el formato legacy '2024/06/18'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.882789	compra
628	2024	f	112	Ingreso navideño	2024-05-11	1	-1500.00	Fecha normalizada desde el formato legacy '2024/05/11'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.886649	pago
629	2024	f	101	Ingreso extra	2024-04-29	1	3000.00	Fecha normalizada desde el formato legacy '29-04-2024'	2026-09-20 21:44:17.886676	deposito
630	2024	f	107	Sin descripcion	2024-10-31	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:17.886687	retiro
631	2024	f	117	Ingreso extra	2024-05-21	1	1500.00	\N	2026-09-20 21:44:17.886697	deposito
632	2024	f	119	Retiro parcial	2024-02-13	1	-3000.00	Fecha normalizada desde el formato legacy '13/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.886712	retiro
633	2024	f	102	Ingreso mensual	2024-03-07	1	-2500.00	Fecha normalizada desde el formato legacy '07/03/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.892627	retiro
634	2024	f	106	Ingreso extra	2024-12-04	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.892643	retiro
635	2024	f	116	Sin descripcion	2024-08-20	1	1500.00	Fecha normalizada desde el formato legacy '2024/08/20'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.892655	deposito
636	2024	f	115	Sin descripcion	2024-10-24	1	-1500.00	Fecha normalizada desde el formato legacy '24-10-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.892672	retiro
637	2024	f	119	Compra en tienda	2024-09-11	1	-2000.00	Fecha normalizada desde el formato legacy '11-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.899656	compra
638	2024	f	112	Compra en tienda	2024-03-19	1	1500.00	Fecha normalizada desde el formato legacy '2024/03/19'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.899701	deposito
639	2024	t	119	Compra en tienda	2024-02-11	1	0.00	Fecha normalizada desde el formato legacy '2024/02/11'; Monto no positivo	2026-09-20 21:44:17.899721	deposito
640	2024	f	111	Ingreso mensual	2024-06-29	1	2500.00	\N	2026-09-20 21:44:17.899732	deposito
641	2024	f	115	Ingreso navideño	2024-11-03	1	-1000.00	Fecha normalizada desde el formato legacy '03-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.899746	compra
642	2024	f	101	Ingreso navideño	2024-11-11	1	-1000.00	Fecha normalizada desde el formato legacy '11/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.903477	compra
643	2024	f	113	Ingreso navideño	2024-02-29	1	2000.00	Fecha normalizada desde el formato legacy '29-02-2024'	2026-09-20 21:44:17.903584	deposito
644	2024	f	109	Retiro parcial	2024-05-24	1	-1000.00	Fecha normalizada desde el formato legacy '24-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.903642	retiro
645	2024	f	116	Sin descripcion	2024-07-11	1	-500.00	Fecha normalizada desde el formato legacy '11/07/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.9037	compra
646	2024	f	111	Compra en tienda	2024-09-26	1	-500.00	\N	2026-09-20 21:44:17.903724	retiro
647	2024	f	117	Compra en tienda	2024-01-13	1	-1000.00	Fecha normalizada desde el formato legacy '2024/01/13'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.90797	retiro
648	2024	t	114	Ingreso navideño	2024-09-23	1	100.00	Fecha normalizada desde el formato legacy '2024/09/23'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.907997	deposito
649	2024	f	113	Compra en tienda	2024-09-02	1	3000.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.908036	deposito
650	2024	f	108	Ingreso extra	2024-11-07	1	-2500.00	Fecha normalizada desde el formato legacy '2024/11/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.908051	retiro
651	2024	f	113	Sin descripcion	2024-05-11	1	-2500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.908061	compra
652	2024	f	116	Ingreso extra	2024-06-30	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.911974	retiro
653	2024	f	110	Ingreso extra	2024-07-13	1	3000.00	Fecha normalizada desde el formato legacy '13-07-2024'	2026-09-20 21:44:17.912016	deposito
654	2024	f	116	Ingreso navideño	2024-06-27	1	5000.00	Fecha normalizada desde el formato legacy '27/06/2024'	2026-09-20 21:44:17.912074	deposito
655	2024	f	108	Sin descripcion	2024-11-14	1	-3000.00	Fecha normalizada desde el formato legacy '2024/11/14'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.912096	compra
774	2024	f	105	Ingreso extra	2024-02-15	1	1000.00	Fecha normalizada desde el formato legacy '2024/02/15'	2026-09-20 21:44:18.008781	deposito
656	2024	f	118	Retiro parcial	2024-10-07	1	-3000.00	Fecha normalizada desde el formato legacy '07-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.912112	compra
657	2024	f	104	Retiro parcial	2024-05-31	1	-1500.00	Fecha normalizada desde el formato legacy '31-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.915109	retiro
658	2024	f	104	Sin descripcion	2024-08-30	1	-100.00	Fecha normalizada desde el formato legacy '30-08-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.915128	retiro
659	2024	f	118	Sin descripcion	2024-04-04	1	-2000.00	Fecha normalizada desde el formato legacy '04/04/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.915143	retiro
660	2024	f	116	Sin descripcion	2024-08-28	1	2500.00	Fecha normalizada desde el formato legacy '28/08/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.915157	deposito
661	2024	f	111	Sin descripcion	2024-01-18	1	-2500.00	Fecha normalizada desde el formato legacy '2024/01/18'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.915168	compra
662	2024	f	116	Ingreso extra	2024-11-18	1	-3000.00	Fecha normalizada desde el formato legacy '2024/11/18'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.91914	retiro
663	2024	f	103	Ingreso extra	2024-06-03	1	-100.00	Fecha normalizada desde el formato legacy '2024/06/03'	2026-09-20 21:44:17.919174	compra
664	2024	f	114	Sin descripcion	2024-09-01	1	-2500.00	Fecha normalizada desde el formato legacy '01/09/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.919193	retiro
665	2024	f	110	Ingreso mensual	2024-11-03	1	-500.00	\N	2026-09-20 21:44:17.919204	compra
666	2024	f	112	Ingreso extra	2024-01-12	1	1500.00	Fecha normalizada desde el formato legacy '12-01-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.919243	deposito
667	2024	f	109	Retiro parcial	2024-06-20	1	-1000.00	Fecha normalizada desde el formato legacy '2024/06/20'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.922592	retiro
668	2024	f	117	Sin descripcion	2024-07-20	1	-2500.00	Fecha normalizada desde el formato legacy '20-07-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.92261	retiro
669	2024	f	119	Compra en tienda	2024-08-20	1	2500.00	Fecha normalizada desde el formato legacy '20/08/2024'	2026-09-20 21:44:17.922624	deposito
670	2024	f	110	Sin descripcion	2024-11-21	1	-100.00	Fecha normalizada desde el formato legacy '21/11/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.922638	retiro
671	2024	f	115	Ingreso navideño	2024-04-08	1	-1000.00	Fecha normalizada desde el formato legacy '2024/04/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.922648	compra
672	2024	f	119	Ingreso extra	2024-04-11	1	-2000.00	Fecha normalizada desde el formato legacy '2024/04/11'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.926644	pago
673	2024	f	101	Compra en tienda	2024-01-30	1	3000.00	Fecha normalizada desde el formato legacy '30-01-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.926682	deposito
674	2024	f	116	Ingreso extra	2024-03-08	1	-2000.00	Fecha normalizada desde el formato legacy '2024/03/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.926694	compra
675	2024	f	102	Retiro parcial	2024-08-13	1	-5000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.926703	compra
676	2024	f	118	Retiro parcial	2024-03-14	1	3000.00	Fecha normalizada desde el formato legacy '14/03/2024'	2026-09-20 21:44:17.932695	deposito
677	2024	t	118	Ingreso navideño	2024-04-21	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.932721	deposito
678	2024	t	112	Sin descripcion	2024-02-08	1	500.00	Fecha normalizada desde el formato legacy '2024/02/08'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.932739	deposito
679	2024	f	116	Sin descripcion	2024-07-05	1	-2000.00	Fecha normalizada desde el formato legacy '2024/07/05'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.932797	retiro
680	2024	f	115	Sin descripcion	2024-09-17	1	-2500.00	Fecha normalizada desde el formato legacy '17/09/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.932824	compra
681	2024	f	106	Ingreso navideño	2024-06-15	1	-2500.00	Fecha normalizada desde el formato legacy '15/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.937078	compra
682	2024	f	114	Retiro parcial	2024-10-22	1	-1500.00	Fecha normalizada desde el formato legacy '2024/10/22'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.937235	retiro
683	2024	f	108	Retiro parcial	2024-12-17	1	1000.00	\N	2026-09-20 21:44:17.937252	deposito
684	2024	f	111	Sin descripcion	2024-10-22	1	3000.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.937286	deposito
685	2024	f	108	Ingreso extra	2024-04-17	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.937296	retiro
686	2024	f	111	Sin descripcion	2024-06-24	1	-1000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.940383	compra
687	2024	t	101	Sin descripcion	2024-06-20	1	100.00	Fecha normalizada desde el formato legacy '2024/06/20'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.940405	deposito
688	2024	t	104	Sin descripcion	2024-05-08	1	100.00	Fecha normalizada desde el formato legacy '08-05-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.940423	deposito
689	2024	f	118	Ingreso navideño	2024-11-08	1	-500.00	Fecha normalizada desde el formato legacy '2024/11/08'	2026-09-20 21:44:17.940438	compra
690	2024	f	102	Retiro parcial	2024-01-14	1	-1500.00	Fecha normalizada desde el formato legacy '14-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.940453	compra
691	2024	f	105	Ingreso extra	2024-03-07	1	1000.00	\N	2026-09-20 21:44:17.943637	deposito
692	2024	t	105	Ingreso mensual	2024-04-26	1	500.00	Fecha normalizada desde el formato legacy '26/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.943661	deposito
693	2024	f	111	Ingreso mensual	2024-04-18	1	-100.00	Fecha normalizada desde el formato legacy '18-04-2024'	2026-09-20 21:44:17.943676	compra
694	2024	f	107	Retiro parcial	2024-12-14	1	-1500.00	Fecha normalizada desde el formato legacy '2024/12/14'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.943688	compra
695	2024	f	104	Ingreso mensual	2024-08-12	1	1000.00	\N	2026-09-20 21:44:17.943697	deposito
696	2024	f	106	Compra en tienda	2024-11-22	1	2500.00	Fecha normalizada desde el formato legacy '22-11-2024'	2026-09-20 21:44:17.947028	deposito
697	2024	f	105	Ingreso mensual	2024-04-29	1	-100.00	\N	2026-09-20 21:44:17.947041	compra
698	2024	f	110	Compra en tienda	2024-07-02	1	-2500.00	Fecha normalizada desde el formato legacy '02-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.947055	pago
699	2024	f	117	Ingreso extra	2024-06-13	1	-1500.00	Fecha normalizada desde el formato legacy '13-06-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.947068	retiro
700	2024	f	116	Ingreso extra	2024-11-13	1	-1500.00	Fecha normalizada desde el formato legacy '13/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.947082	compra
701	2024	t	104	Ingreso navideño	2024-07-28	1	500.00	Fecha normalizada desde el formato legacy '28/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.950978	deposito
702	2024	f	114	Compra en tienda	2024-12-05	1	-1500.00	Fecha normalizada desde el formato legacy '05/12/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.951006	retiro
703	2024	t	114	Ingreso mensual	2024-11-14	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.951018	deposito
704	2024	f	109	Retiro parcial	2024-05-15	1	2500.00	Fecha normalizada desde el formato legacy '15/05/2024'	2026-09-20 21:44:17.951043	deposito
705	2024	f	111	Ingreso mensual	2024-07-21	1	-1500.00	Fecha normalizada desde el formato legacy '21/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.951059	retiro
706	2024	f	106	Ingreso navideño	2024-10-12	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.955953	compra
707	2024	f	119	Retiro parcial	2024-09-20	1	-2500.00	Fecha normalizada desde el formato legacy '2024/09/20'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.955985	compra
708	2024	f	115	Ingreso extra	2024-04-13	1	3000.00	Fecha normalizada desde el formato legacy '13-04-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.956026	deposito
709	2024	f	113	Sin descripcion	2024-11-08	1	-1500.00	Fecha normalizada desde el formato legacy '08/11/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.956044	compra
710	2024	f	111	Ingreso mensual	2024-09-26	1	-1000.00	Fecha normalizada desde el formato legacy '26-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.956058	retiro
711	2024	f	110	Sin descripcion	2024-08-03	1	-1000.00	Fecha normalizada desde el formato legacy '2024/08/03'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.959541	compra
712	2024	f	110	Compra en tienda	2024-09-09	1	-100.00	\N	2026-09-20 21:44:17.959558	retiro
713	2024	t	103	Retiro parcial	2024-06-05	1	100.00	Fecha normalizada desde el formato legacy '05/06/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.959593	deposito
714	2024	f	107	Ingreso extra	2024-03-19	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.959603	compra
715	2024	f	101	Compra en tienda	2024-08-04	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.959613	compra
716	2024	f	111	Ingreso extra	2024-05-01	1	1500.00	Fecha normalizada desde el formato legacy '2024/05/01'	2026-09-20 21:44:17.962967	deposito
717	2024	f	109	Ingreso mensual	2024-09-23	1	-500.00	Fecha normalizada desde el formato legacy '23-09-2024'	2026-09-20 21:44:17.96299	retiro
718	2024	f	104	Ingreso navideño	2024-05-23	1	-3000.00	Fecha normalizada desde el formato legacy '23/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.963009	compra
719	2024	f	110	Sin descripcion	2024-03-10	1	-100.00	Fecha normalizada desde el formato legacy '10-03-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.963024	retiro
720	2024	t	105	Ingreso extra	2024-05-16	1	500.00	Fecha normalizada desde el formato legacy '2024/05/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.963037	deposito
721	2024	f	115	Ingreso extra	2024-11-29	1	1000.00	\N	2026-09-20 21:44:17.967618	deposito
722	2024	f	103	Compra en tienda	2024-01-17	1	-100.00	Fecha normalizada desde el formato legacy '17/01/2024'	2026-09-20 21:44:17.967687	compra
723	2024	t	103	Ingreso mensual	2024-09-28	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.967705	deposito
724	2024	f	111	Ingreso extra	2024-02-09	1	-3000.00	Fecha normalizada desde el formato legacy '2024/02/09'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.967723	retiro
725	2024	t	119	Sin descripcion	2024-01-29	1	0.00	Fecha normalizada desde el formato legacy '2024/01/29'; Monto no positivo; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.967744	deposito
726	2024	f	116	Sin descripcion	2024-02-16	1	-2000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.971614	compra
727	2024	f	107	Sin descripcion	2024-11-27	1	-2500.00	Fecha normalizada desde el formato legacy '27-11-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.971688	retiro
728	2024	f	102	Retiro parcial	2024-11-14	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.971703	compra
729	2024	f	116	Ingreso mensual	2024-04-06	1	3000.00	Fecha normalizada desde el formato legacy '2024/04/06'	2026-09-20 21:44:17.971718	deposito
730	2024	f	116	Ingreso extra	2024-02-14	1	1000.00	Fecha normalizada desde el formato legacy '14-02-2024'	2026-09-20 21:44:17.971731	deposito
731	2024	f	107	Sin descripcion	2024-12-26	1	2000.00	Fecha normalizada desde el formato legacy '2024/12/26'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.975691	deposito
732	2024	f	114	Ingreso navideño	2024-05-20	1	-1000.00	Fecha normalizada desde el formato legacy '20/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.975714	retiro
733	2024	f	117	Ingreso extra	2024-07-11	1	-2500.00	Fecha normalizada desde el formato legacy '11/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.975732	compra
734	2024	t	114	Ingreso navideño	2024-04-10	1	500.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.975767	deposito
735	2024	f	102	Compra en tienda	2024-09-08	1	2000.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:17.975781	deposito
736	2024	f	105	Sin descripcion	2024-09-28	1	-2500.00	Fecha normalizada desde el formato legacy '2024/09/28'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.9791	compra
737	2024	f	120	Compra en tienda	2024-09-15	1	-500.00	Fecha normalizada desde el formato legacy '15/09/2024'	2026-09-20 21:44:17.979135	retiro
738	2024	f	101	Sin descripcion	2024-01-09	1	-1500.00	Fecha normalizada desde el formato legacy '09-01-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.979152	compra
739	2024	f	108	Sin descripcion	2024-11-17	1	-100.00	Fecha normalizada desde el formato legacy '17/11/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.979168	retiro
740	2024	f	111	Ingreso extra	2024-06-08	1	-3000.00	Fecha normalizada desde el formato legacy '2024/06/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.979226	retiro
741	2024	f	116	Ingreso navideño	2024-10-15	1	-100.00	Fecha normalizada desde el formato legacy '2024/10/15'	2026-09-20 21:44:17.982894	compra
742	2024	f	119	Ingreso navideño	2024-07-16	1	2500.00	Fecha normalizada desde el formato legacy '16/07/2024'	2026-09-20 21:44:17.982926	deposito
743	2024	f	116	Ingreso navideño	2024-02-01	1	-3000.00	Fecha normalizada desde el formato legacy '01-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.982944	retiro
744	2024	f	106	Ingreso extra	2024-03-12	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.982996	compra
745	2024	f	119	Retiro parcial	2024-09-23	1	-2000.00	Fecha normalizada desde el formato legacy '23-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.983018	compra
746	2024	t	106	Ingreso extra	2024-11-11	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.986919	deposito
747	2024	f	118	Ingreso mensual	2024-03-03	1	-1500.00	Fecha normalizada desde el formato legacy '03-03-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.986953	retiro
748	2024	f	106	Ingreso mensual	2024-07-01	1	-3000.00	Fecha normalizada desde el formato legacy '01-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.986968	compra
749	2024	f	116	Retiro parcial	2024-10-29	1	-3000.00	Fecha normalizada desde el formato legacy '29/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.986983	compra
750	2024	t	115	Ingreso navideño	2024-06-24	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.986992	deposito
751	2024	f	108	Ingreso navideño	2024-07-08	1	-100.00	\N	2026-09-20 21:44:17.991347	retiro
752	2024	f	110	Ingreso extra	2024-08-08	1	-500.00	Fecha normalizada desde el formato legacy '2024/08/08'	2026-09-20 21:44:17.991358	compra
753	2024	f	101	Compra en tienda	2024-07-20	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.991366	retiro
754	2024	f	102	Ingreso mensual	2024-07-20	1	-1500.00	Fecha normalizada desde el formato legacy '2024/07/20'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.991387	compra
755	2024	f	108	Compra en tienda	2024-04-16	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.996863	compra
756	2024	f	103	Sin descripcion	2024-09-29	1	-100.00	Fecha normalizada desde el formato legacy '2024/09/29'; Descripcion vacia completada por el proceso	2026-09-20 21:44:17.996882	compra
757	2024	f	107	Ingreso mensual	2024-10-10	1	2000.00	Fecha normalizada desde el formato legacy '2024/10/10'	2026-09-20 21:44:17.996894	deposito
758	2024	t	107	Ingreso mensual	2024-01-24	1	500.00	Fecha normalizada desde el formato legacy '24-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:17.996906	deposito
759	2024	f	112	Sin descripcion	2024-09-02	1	-1500.00	Fecha normalizada desde el formato legacy '02/09/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.000056	compra
760	2024	f	106	Ingreso navideño	2024-06-17	1	2000.00	Fecha normalizada desde el formato legacy '17/06/2024'	2026-09-20 21:44:18.000073	deposito
761	2024	f	101	Compra en tienda	2024-11-23	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.000083	compra
762	2024	f	107	Ingreso mensual	2024-05-05	1	-3000.00	Fecha normalizada desde el formato legacy '2024/05/05'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.000094	compra
763	2024	f	115	Ingreso extra	2024-08-12	1	-2000.00	Fecha normalizada desde el formato legacy '12-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.000107	retiro
764	2024	f	101	Ingreso extra	2024-06-28	1	1500.00	Fecha normalizada desde el formato legacy '2024/06/28'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.003033	deposito
765	2024	f	112	Retiro parcial	2024-08-24	1	3000.00	Fecha normalizada desde el formato legacy '24/08/2024'	2026-09-20 21:44:18.003059	deposito
766	2024	t	116	Sin descripcion	2024-06-08	1	500.00	Fecha normalizada desde el formato legacy '08-06-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.003075	deposito
767	2024	f	107	Retiro parcial	2024-02-14	1	-1500.00	Fecha normalizada desde el formato legacy '14-02-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.003091	compra
768	2024	t	119	Ingreso mensual	2024-09-29	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.003146	deposito
769	2024	f	110	Ingreso mensual	2024-05-30	1	-2500.00	Fecha normalizada desde el formato legacy '30/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.005809	compra
770	2024	f	112	Retiro parcial	2024-03-20	1	3000.00	Fecha normalizada desde el formato legacy '20-03-2024'	2026-09-20 21:44:18.005837	deposito
771	2024	f	114	Ingreso navideño	2024-07-26	1	-2000.00	Fecha normalizada desde el formato legacy '26-07-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.005853	compra
772	2024	f	106	Sin descripcion	2024-10-19	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.005864	retiro
773	2024	f	107	Sin descripcion	2024-05-05	1	2500.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:18.005874	deposito
775	2024	f	106	Ingreso mensual	2024-03-18	1	1500.00	Fecha normalizada desde el formato legacy '18-03-2024'	2026-09-20 21:44:18.008819	deposito
776	2024	f	104	Compra en tienda	2024-03-16	1	-2000.00	Fecha normalizada desde el formato legacy '16-03-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.00885	compra
777	2024	f	113	Ingreso navideño	2024-08-16	1	-2000.00	Fecha normalizada desde el formato legacy '16/08/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.008988	compra
778	2024	f	112	Ingreso extra	2024-01-09	1	-5000.00	Fecha normalizada desde el formato legacy '09/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.00907	compra
779	2024	f	113	Ingreso extra	2024-10-09	1	-500.00	Fecha normalizada desde el formato legacy '09/10/2024'	2026-09-20 21:44:18.012748	compra
780	2024	f	105	Retiro parcial	2024-02-06	1	-100.00	Fecha normalizada desde el formato legacy '2024/02/06'	2026-09-20 21:44:18.012783	retiro
781	2024	f	107	Sin descripcion	2024-10-17	1	-2500.00	Fecha normalizada desde el formato legacy '2024/10/17'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.012805	pago
782	2024	f	101	Retiro parcial	2024-04-03	1	-1500.00	Fecha normalizada desde el formato legacy '03-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.012831	pago
783	2024	f	105	Retiro parcial	2024-02-18	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.012843	retiro
784	2024	f	102	Sin descripcion	2024-07-28	1	-1000.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.015606	retiro
785	2024	f	116	Ingreso navideño	2024-03-19	1	-500.00	Fecha normalizada desde el formato legacy '19/03/2024'	2026-09-20 21:44:18.015646	compra
786	2024	f	102	Retiro parcial	2024-12-06	1	2500.00	Fecha normalizada desde el formato legacy '06/12/2024'	2026-09-20 21:44:18.015666	deposito
787	2024	f	101	Sin descripcion	2024-08-31	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/31'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.01568	deposito
788	2024	f	120	Ingreso navideño	2024-03-21	1	2500.00	\N	2026-09-20 21:44:18.015691	deposito
789	2024	f	114	Ingreso extra	2024-06-06	1	-2000.00	Fecha normalizada desde el formato legacy '2024/06/06'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.017896	retiro
790	2024	f	110	Compra en tienda	2024-06-06	1	-100.00	Fecha normalizada desde el formato legacy '2024/06/06'	2026-09-20 21:44:18.017913	compra
791	2024	f	107	Compra en tienda	2024-12-16	1	-3000.00	Fecha normalizada desde el formato legacy '16-12-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.017927	compra
792	2024	f	116	Ingreso mensual	2024-06-12	1	1500.00	Fecha normalizada desde el formato legacy '2024/06/12'	2026-09-20 21:44:18.017939	deposito
793	2024	f	115	Ingreso navideño	2024-09-27	1	2500.00	Fecha normalizada desde el formato legacy '27/09/2024'	2026-09-20 21:44:18.017954	deposito
794	2024	f	104	Compra en tienda	2024-05-30	1	-2500.00	Fecha normalizada desde el formato legacy '2024/05/30'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.020813	retiro
795	2024	t	109	Compra en tienda	2024-07-15	1	0.00	Fecha normalizada desde el formato legacy '15-07-2024'; Monto no positivo	2026-09-20 21:44:18.020853	compra
796	2024	f	118	Ingreso extra	2024-05-22	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.020864	retiro
797	2024	f	119	Retiro parcial	2024-08-06	1	1000.00	Fecha normalizada desde el formato legacy '06-08-2024'	2026-09-20 21:44:18.020878	deposito
798	2024	f	108	Compra en tienda	2024-10-12	1	-100.00	Fecha normalizada desde el formato legacy '2024/10/12'	2026-09-20 21:44:18.020889	pago
799	2024	f	103	Ingreso navideño	2024-10-03	1	-1500.00	Fecha normalizada desde el formato legacy '03/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.023391	compra
800	2024	f	108	Sin descripcion	2024-12-01	1	-1000.00	Fecha normalizada desde el formato legacy '01-12-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.023414	retiro
801	2024	f	106	Ingreso navideño	2024-05-30	1	2500.00	Fecha normalizada desde el formato legacy '30/05/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.023451	deposito
802	2024	f	101	Sin descripcion	2024-01-12	1	-500.00	Fecha normalizada desde el formato legacy '12-01-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.023466	compra
803	2024	f	109	Ingreso navideño	2024-08-05	1	-3000.00	Fecha normalizada desde el formato legacy '05-08-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.023492	compra
804	2024	f	115	Sin descripcion	2024-01-10	1	-2500.00	Fecha normalizada desde el formato legacy '10-01-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.026283	compra
805	2024	t	101	Ingreso mensual	2024-05-25	1	100.00	Fecha normalizada desde el formato legacy '2024/05/25'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.026299	deposito
806	2024	t	114	Ingreso mensual	2024-01-22	1	500.00	Fecha normalizada desde el formato legacy '2024/01/22'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.026332	deposito
807	2024	f	107	Ingreso extra	2024-01-02	1	-2000.00	Fecha normalizada desde el formato legacy '02-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.026346	retiro
808	2024	f	119	Ingreso navideño	2024-09-09	1	2000.00	Fecha normalizada desde el formato legacy '09-09-2024'	2026-09-20 21:44:18.030066	deposito
809	2024	f	120	Ingreso mensual	2024-02-07	1	-100.00	Fecha normalizada desde el formato legacy '2024/02/07'	2026-09-20 21:44:18.030076	retiro
810	2024	f	101	Ingreso navideño	2024-09-02	1	3000.00	Fecha normalizada desde el formato legacy '2024/09/02'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.030094	deposito
811	2024	t	101	Sin descripcion	2024-09-30	1	500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.037147	deposito
812	2024	f	106	Sin descripcion	2024-09-15	1	2000.00	Fecha normalizada desde el formato legacy '15/09/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.037161	deposito
813	2024	f	110	Sin descripcion	2024-05-26	1	-3000.00	Fecha normalizada desde el formato legacy '26/05/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.037175	retiro
814	2024	f	105	Sin descripcion	2024-09-23	1	-1000.00	Fecha normalizada desde el formato legacy '23/09/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.037188	compra
815	2024	f	109	Ingreso extra	2024-04-03	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.044783	compra
816	2024	t	107	Retiro parcial	2024-08-29	1	100.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.04482	deposito
817	2024	f	111	Sin descripcion	2024-10-29	1	-2500.00	Fecha normalizada desde el formato legacy '29-10-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.044841	retiro
818	2024	f	117	Retiro parcial	2024-03-11	1	2500.00	Fecha normalizada desde el formato legacy '11/03/2024'	2026-09-20 21:44:18.044856	deposito
819	2024	f	112	Sin descripcion	2024-06-21	1	-1500.00	Fecha normalizada desde el formato legacy '21-06-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.044871	retiro
820	2024	f	105	Ingreso extra	2024-02-21	1	-1000.00	Fecha normalizada desde el formato legacy '2024/02/21'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.04734	compra
821	2024	f	107	Sin descripcion	2024-12-03	1	-500.00	Fecha normalizada desde el formato legacy '03-12-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.047362	compra
822	2024	f	108	Retiro parcial	2024-12-20	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.047372	retiro
823	2024	f	105	Sin descripcion	2024-04-22	1	-500.00	Fecha normalizada desde el formato legacy '22-04-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.047385	retiro
824	2024	f	107	Compra en tienda	2024-02-18	1	-2000.00	Fecha normalizada desde el formato legacy '18/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.047403	pago
825	2024	f	118	Compra en tienda	2024-10-27	1	2500.00	Fecha normalizada desde el formato legacy '2024/10/27'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.051388	deposito
826	2024	f	102	Sin descripcion	2024-05-30	1	-3000.00	Fecha normalizada desde el formato legacy '2024/05/30'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.051408	retiro
827	2024	f	103	Retiro parcial	2024-04-20	1	2000.00	Fecha normalizada desde el formato legacy '20/04/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.05143	deposito
828	2024	f	119	Ingreso extra	2024-06-25	1	-2500.00	Fecha normalizada desde el formato legacy '25-06-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.051444	compra
829	2024	f	111	Sin descripcion	2024-08-08	1	-3000.00	Fecha normalizada desde el formato legacy '2024/08/08'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.055985	compra
830	2024	f	108	Ingreso extra	2024-01-27	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.05601	retiro
831	2024	f	107	Compra en tienda	2024-05-11	1	-3000.00	Fecha normalizada desde el formato legacy '11-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.056028	retiro
832	2024	t	101	Sin descripcion	2024-11-24	1	100.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.056038	deposito
833	2024	f	104	Ingreso extra	2024-06-20	1	-500.00	\N	2026-09-20 21:44:18.056049	compra
834	2024	f	109	Compra en tienda	2024-08-19	1	-500.00	\N	2026-09-20 21:44:18.059668	retiro
835	2024	f	108	Ingreso mensual	2024-12-20	1	2500.00	Fecha normalizada desde el formato legacy '20-12-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.059702	deposito
836	2024	f	104	Ingreso extra	2024-01-18	1	-5000.00	Fecha normalizada desde el formato legacy '18-01-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.059714	retiro
837	2024	f	113	Retiro parcial	2024-05-02	1	-100.00	\N	2026-09-20 21:44:18.059722	compra
838	2024	f	114	Ingreso mensual	2024-02-15	1	3000.00	Fecha normalizada desde el formato legacy '15-02-2024'	2026-09-20 21:44:18.06348	deposito
839	2024	f	104	Compra en tienda	2024-09-19	1	2500.00	Fecha normalizada desde el formato legacy '19-09-2024'	2026-09-20 21:44:18.063493	deposito
840	2024	f	105	Sin descripcion	2024-08-07	1	2500.00	Fecha normalizada desde el formato legacy '07-08-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.063506	deposito
841	2024	f	108	Ingreso navideño	2024-11-19	1	-2000.00	Fecha normalizada desde el formato legacy '19/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.06352	retiro
842	2024	t	108	Sin descripcion	2024-01-22	1	500.00	Fecha normalizada desde el formato legacy '22-01-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.066992	deposito
843	2024	f	114	Compra en tienda	2024-02-21	1	1000.00	Fecha normalizada desde el formato legacy '2024/02/21'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.06703	deposito
844	2024	f	109	Compra en tienda	2024-02-07	1	-2000.00	Fecha normalizada desde el formato legacy '2024/02/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.067057	compra
845	2024	f	111	Ingreso mensual	2024-04-29	1	5000.00	\N	2026-09-20 21:44:18.067072	deposito
846	2024	f	117	Ingreso navideño	2024-11-25	1	-3000.00	Fecha normalizada desde el formato legacy '25-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.067092	retiro
847	2024	t	112	Retiro parcial	2024-08-30	1	500.00	Fecha normalizada desde el formato legacy '2024/08/30'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.071885	deposito
848	2024	f	112	Retiro parcial	2024-11-06	1	2000.00	Fecha normalizada desde el formato legacy '2024/11/06'	2026-09-20 21:44:18.071909	deposito
849	2024	f	101	Ingreso mensual	2024-04-22	1	-2500.00	Fecha normalizada desde el formato legacy '22/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.071927	compra
850	2024	f	107	Ingreso mensual	2024-06-16	1	-2500.00	Fecha normalizada desde el formato legacy '2024/06/16'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.07194	retiro
851	2024	f	114	Ingreso extra	2024-05-17	1	-100.00	\N	2026-09-20 21:44:18.071949	compra
852	2024	f	113	Ingreso extra	2024-02-13	1	-3000.00	Fecha normalizada desde el formato legacy '13/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.075399	pago
853	2024	f	118	Compra en tienda	2024-10-23	1	-1500.00	Fecha normalizada desde el formato legacy '23-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.075412	retiro
854	2024	f	106	Ingreso navideño	2024-10-28	1	-2500.00	Fecha normalizada desde el formato legacy '28-10-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.075425	retiro
855	2024	f	105	Ingreso extra	2024-01-08	1	-100.00	Fecha normalizada desde el formato legacy '08/01/2024'	2026-09-20 21:44:18.075439	compra
856	2024	f	112	Ingreso mensual	2024-02-26	1	3000.00	Fecha normalizada desde el formato legacy '26-02-2024'	2026-09-20 21:44:18.079895	deposito
857	2024	t	110	Sin descripcion	2024-04-03	1	100.00	Fecha normalizada desde el formato legacy '03/04/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.07992	deposito
858	2024	f	111	Sin descripcion	2024-02-16	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.079931	retiro
859	2024	f	119	Ingreso navideño	2024-04-30	1	-2500.00	Fecha normalizada desde el formato legacy '30/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.079946	compra
860	2024	f	117	Sin descripcion	2024-07-31	1	-1000.00	Fecha normalizada desde el formato legacy '31-07-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.079959	compra
861	2024	f	115	Retiro parcial	2024-10-17	1	-100.00	Fecha normalizada desde el formato legacy '17-10-2024'	2026-09-20 21:44:18.083187	retiro
862	2024	f	120	Retiro parcial	2024-05-01	1	-3000.00	Fecha normalizada desde el formato legacy '01-05-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.083203	compra
863	2024	f	119	Retiro parcial	2024-10-26	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.083221	compra
864	2024	f	105	Ingreso navideño	2024-10-07	1	-100.00	Fecha normalizada desde el formato legacy '07-10-2024'	2026-09-20 21:44:18.083233	compra
865	2024	t	116	Retiro parcial	2024-09-06	1	100.00	Fecha normalizada desde el formato legacy '06-09-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.087906	deposito
866	2024	t	118	Ingreso extra	2024-04-12	1	100.00	Fecha normalizada desde el formato legacy '12/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.087936	deposito
867	2024	f	118	Sin descripcion	2024-12-28	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.087949	compra
868	2024	f	113	Compra en tienda	2024-11-21	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.08796	retiro
869	2024	f	104	Retiro parcial	2024-08-25	1	1500.00	Fecha normalizada desde el formato legacy '25/08/2024'	2026-09-20 21:44:18.087976	deposito
870	2024	f	117	Retiro parcial	2024-04-20	1	1000.00	Fecha normalizada desde el formato legacy '20/04/2024'	2026-09-20 21:44:18.090394	deposito
871	2024	f	110	Ingreso navideño	2024-07-08	1	1500.00	Fecha normalizada desde el formato legacy '2024/07/08'	2026-09-20 21:44:18.090409	deposito
872	2024	f	113	Sin descripcion	2024-09-03	1	-3000.00	Fecha normalizada desde el formato legacy '03-09-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.090423	retiro
873	2024	t	115	Retiro parcial	2024-01-10	1	1000.00	Fecha normalizada desde el formato legacy '2024/01/10'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.090436	deposito
874	2024	f	102	Sin descripcion	2024-05-11	1	-2000.00	Fecha normalizada desde el formato legacy '11-05-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.090448	retiro
875	2024	f	108	Compra en tienda	2024-02-20	1	-100.00	\N	2026-09-20 21:44:18.0928	retiro
876	2024	f	107	Sin descripcion	2024-12-21	1	-1500.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.092817	compra
877	2024	t	102	Compra en tienda	2024-12-17	1	100.00	Fecha normalizada desde el formato legacy '17-12-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.092839	deposito
878	2024	f	115	Sin descripcion	2024-04-30	1	-2500.00	Fecha normalizada desde el formato legacy '2024/04/30'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.092852	compra
879	2024	f	114	Compra en tienda	2024-11-17	1	-100.00	Fecha normalizada desde el formato legacy '2024/11/17'	2026-09-20 21:44:18.092862	compra
880	2024	f	106	Ingreso navideño	2024-06-08	1	-2500.00	Fecha normalizada desde el formato legacy '2024/06/08'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.094805	compra
881	2024	f	117	Compra en tienda	2024-07-20	1	-500.00	\N	2026-09-20 21:44:18.094819	compra
882	2024	t	111	Ingreso extra	2024-03-11	1	500.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.094862	deposito
883	2024	f	116	Sin descripcion	2024-05-14	1	-3000.00	Fecha normalizada desde el formato legacy '14/05/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.094879	compra
884	2024	f	113	Ingreso mensual	2024-05-09	1	-2500.00	Fecha normalizada desde el formato legacy '2024/05/09'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.094892	compra
885	2024	f	120	Sin descripcion	2024-08-12	1	-500.00	Fecha normalizada desde el formato legacy '12-08-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.097772	retiro
886	2024	f	116	Ingreso navideño	2024-07-28	1	-1000.00	\N	2026-09-20 21:44:18.097786	compra
887	2024	f	104	Ingreso navideño	2024-11-17	1	-2000.00	Fecha normalizada desde el formato legacy '2024/11/17'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.0978	retiro
888	2024	f	108	Compra en tienda	2024-09-22	1	1000.00	\N	2026-09-20 21:44:18.097809	deposito
889	2024	f	117	Ingreso mensual	2024-02-01	1	1500.00	Fecha normalizada desde el formato legacy '2024/02/01'	2026-09-20 21:44:18.09782	deposito
890	2024	t	115	Sin descripcion	2024-02-09	1	0.00	Fecha normalizada desde el formato legacy '09-02-2024'; Monto no positivo; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.10127	compra
891	2024	t	111	Compra en tienda	2024-04-27	1	100.00	Fecha normalizada desde el formato legacy '27-04-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.101282	deposito
892	2024	t	104	Ingreso navideño	2024-08-10	1	500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.101291	deposito
893	2024	t	107	Ingreso navideño	2024-01-15	1	100.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.101304	deposito
894	2024	t	114	Sin descripcion	2024-02-19	1	500.00	Fecha normalizada desde el formato legacy '19-02-2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.106094	deposito
895	2024	f	110	Sin descripcion	2024-09-10	1	2500.00	Fecha normalizada desde el formato legacy '2024/09/10'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.106122	deposito
896	2024	f	116	Compra en tienda	2024-10-07	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.106135	retiro
897	2024	f	112	Compra en tienda	2024-11-09	1	1000.00	Fecha normalizada desde el formato legacy '09/11/2024'	2026-09-20 21:44:18.106151	deposito
898	2024	f	101	Ingreso extra	2024-01-25	1	1000.00	Fecha normalizada desde el formato legacy '2024/01/25'	2026-09-20 21:44:18.106163	deposito
899	2024	f	119	Sin descripcion	2024-06-04	1	-3000.00	Fecha normalizada desde el formato legacy '04/06/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.109311	compra
900	2024	f	105	Retiro parcial	2024-01-11	1	-2500.00	Fecha normalizada desde el formato legacy '11/01/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.109329	pago
901	2024	f	119	Compra en tienda	2024-05-26	1	-1000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.109338	compra
902	2024	f	119	Sin descripcion	2024-10-27	1	2500.00	Fecha normalizada desde el formato legacy '27/10/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.109353	deposito
903	2024	t	102	Ingreso navideño	2024-07-16	1	500.00	Fecha normalizada desde el formato legacy '16/07/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.109368	deposito
904	2024	f	112	Ingreso navideño	2024-02-12	1	-2000.00	Fecha normalizada desde el formato legacy '12/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.113046	retiro
905	2024	f	115	Sin descripcion	2024-01-05	1	-1500.00	Fecha normalizada desde el formato legacy '05/01/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.113069	compra
906	2024	f	113	Ingreso extra	2024-11-13	1	-2000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.113103	pago
907	2024	f	111	Ingreso mensual	2024-12-27	1	-500.00	Fecha normalizada desde el formato legacy '27/12/2024'	2026-09-20 21:44:18.113125	compra
908	2024	f	120	Ingreso extra	2024-11-02	1	3000.00	Fecha normalizada desde el formato legacy '02-11-2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.113216	deposito
909	2024	f	114	Ingreso extra	2024-11-13	1	-2500.00	Fecha normalizada desde el formato legacy '13-11-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.11588	compra
910	2024	f	115	Ingreso mensual	2024-12-01	1	-100.00	Fecha normalizada desde el formato legacy '2024/12/01'	2026-09-20 21:44:18.115898	pago
911	2024	f	107	Ingreso navideño	2024-05-13	1	-1000.00	Fecha normalizada desde el formato legacy '13/05/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.115912	compra
912	2024	f	108	Ingreso extra	2024-09-25	1	1500.00	Fecha normalizada desde el formato legacy '25/09/2024'	2026-09-20 21:44:18.115926	deposito
913	2024	f	114	Ingreso mensual	2024-08-31	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/31'	2026-09-20 21:44:18.115939	deposito
914	2024	f	102	Sin descripcion	2024-02-09	1	-100.00	Descripcion vacia completada por el proceso	2026-09-20 21:44:18.118919	compra
915	2024	f	114	Ingreso mensual	2024-04-02	1	-2000.00	Fecha normalizada desde el formato legacy '02/04/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.118933	retiro
916	2024	f	118	Ingreso mensual	2024-08-17	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/17'	2026-09-20 21:44:18.118963	deposito
917	2024	f	116	Sin descripcion	2024-07-16	1	-3000.00	Fecha normalizada desde el formato legacy '16/07/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.11903	retiro
918	2024	f	112	Retiro parcial	2024-10-01	1	1000.00	\N	2026-09-20 21:44:18.122652	deposito
919	2024	f	107	Retiro parcial	2024-04-21	1	1000.00	\N	2026-09-20 21:44:18.12267	deposito
920	2024	f	114	Sin descripcion	2024-05-30	1	-2000.00	Fecha normalizada desde el formato legacy '2024/05/30'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.122692	compra
921	2024	f	118	Ingreso extra	2024-12-04	1	-1000.00	Fecha normalizada desde el formato legacy '04-12-2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.12271	retiro
922	2024	f	120	Retiro parcial	2024-06-05	1	-1000.00	Fecha normalizada desde el formato legacy '05/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.122727	compra
923	2024	f	113	Sin descripcion	2024-01-11	1	-100.00	Fecha normalizada desde el formato legacy '11/01/2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.125407	compra
924	2024	f	109	Compra en tienda	2024-03-22	1	1500.00	Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.125446	deposito
925	2024	f	113	Ingreso navideño	2024-11-07	1	-500.00	\N	2026-09-20 21:44:18.125458	compra
926	2024	f	105	Ingreso navideño	2024-01-04	1	-1000.00	Fecha normalizada desde el formato legacy '2024/01/04'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.125471	retiro
927	2024	f	118	Compra en tienda	2024-04-03	1	3000.00	Fecha normalizada desde el formato legacy '2024/04/03'	2026-09-20 21:44:18.125482	deposito
928	2024	f	108	Retiro parcial	2024-06-13	1	-1000.00	Fecha normalizada desde el formato legacy '2024/06/13'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.128762	compra
929	2024	f	105	Retiro parcial	2024-02-11	1	-1500.00	Fecha normalizada desde el formato legacy '11/02/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.128786	pago
930	2024	f	109	Ingreso mensual	2024-11-09	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.128797	compra
931	2024	f	118	Ingreso navideño	2024-11-11	1	-3000.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.128807	compra
932	2024	f	111	Ingreso navideño	2024-06-20	1	-100.00	Fecha normalizada desde el formato legacy '20/06/2024'	2026-09-20 21:44:18.128823	compra
933	2024	t	112	Sin descripcion	2024-11-13	1	500.00	Fecha normalizada desde el formato legacy '13/11/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.131655	deposito
934	2024	f	111	Ingreso mensual	2024-12-11	1	-1500.00	Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.13168	pago
935	2024	f	109	Compra en tienda	2024-01-27	1	1000.00	Fecha normalizada desde el formato legacy '27/01/2024'	2026-09-20 21:44:18.131699	deposito
936	2024	f	115	Compra en tienda	2024-02-14	1	1000.00	Fecha normalizada desde el formato legacy '2024/02/14'	2026-09-20 21:44:18.131712	deposito
937	2024	f	110	Retiro parcial	2024-11-13	1	-2500.00	Fecha normalizada desde el formato legacy '13/11/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.131728	compra
938	2024	f	103	Ingreso mensual	2024-06-20	1	-3000.00	Fecha normalizada desde el formato legacy '20/06/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.134173	retiro
939	2024	f	104	Ingreso mensual	2024-10-20	1	-1500.00	Fecha normalizada desde el formato legacy '20/10/2024'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.134193	compra
940	2024	f	112	Ingreso navideño	2024-12-27	1	-1000.00	\N	2026-09-20 21:44:18.134205	retiro
941	2024	f	106	Ingreso extra	2024-04-23	1	-500.00	\N	2026-09-20 21:44:18.134214	compra
942	2024	f	119	Ingreso navideño	2024-02-07	1	-3000.00	Fecha normalizada desde el formato legacy '2024/02/07'; Signo del monto corregido segun el tipo de movimiento	2026-09-20 21:44:18.134225	compra
943	2024	f	119	Sin descripcion	2024-12-15	1	1500.00	Fecha normalizada desde el formato legacy '2024/12/15'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.136984	deposito
944	2024	f	110	Compra en tienda	2024-04-12	1	3000.00	Fecha normalizada desde el formato legacy '12/04/2024'; Tipo normalizado desde la escritura con tilde del archivo legacy: 'depósito'	2026-09-20 21:44:18.137042	deposito
945	2024	f	104	Sin descripcion	2024-10-23	1	-100.00	Fecha normalizada desde el formato legacy '2024/10/23'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.137058	compra
946	2024	f	112	Retiro parcial	2024-12-20	1	-500.00	Fecha normalizada desde el formato legacy '20/12/2024'	2026-09-20 21:44:18.137074	retiro
947	2024	f	119	Sin descripcion	2024-02-17	1	2500.00	Fecha normalizada desde el formato legacy '17-02-2024'; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.137088	deposito
948	2024	f	104	Ingreso navideño	2024-01-08	1	2500.00	Fecha normalizada desde el formato legacy '08-01-2024'	2026-09-20 21:44:18.139767	deposito
949	2024	t	118	Sin descripcion	2024-04-28	1	100.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.139783	deposito
950	2024	t	117	Sin descripcion	2024-10-28	1	100.00	Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.139794	deposito
951	2024	f	105	Retiro parcial	2024-09-12	1	2500.00	Fecha normalizada desde el formato legacy '12-09-2024'	2026-09-20 21:44:18.139809	deposito
952	2024	f	118	Sin descripcion	2024-05-20	1	-2000.00	Fecha normalizada desde el formato legacy '20/05/2024'; Signo del monto corregido segun el tipo de movimiento; Descripcion vacia completada por el proceso	2026-09-20 21:44:18.139851	pago
\.


--
-- Data for Name: registro_rechazado; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.registro_rechazado (id, archivo, clasificacion, contenido, job_execution_id, job_nombre, motivo, numero_linea, registrado_en) FROM stdin;
1	cuentas_anuales.csv	OMITIDO	120,2024/04/11,compra,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	6	2026-09-20 21:44:16.956704
31	cuentas_anuales.csv	OMITIDO	102,2024/11/05,retiro,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	53	2026-09-20 21:44:17.042176
39	cuentas_anuales.csv	OMITIDO	104,2024/07/31,deposito,,Compra en tienda	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	70	2026-09-20 21:44:17.060566
46	cuentas_anuales.csv	OMITIDO	117,2024-01-12,retiro,,Ingreso extra	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	72	2026-09-20 21:44:17.079453
60	cuentas_anuales.csv	OMITIDO	117,2024-05-18,deposito,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	98	2026-09-20 21:44:17.121509
78	cuentas_anuales.csv	OMITIDO	103,2024-07-12,deposito,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	127	2026-09-20 21:44:17.171014
83	cuentas_anuales.csv	OMITIDO	114,2024/10/16,retiro,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	137	2026-09-20 21:44:17.181786
124	cuentas_anuales.csv	OMITIDO	107,21-03-2024,deposito,,Compra en tienda	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	228	2026-09-20 21:44:17.295158
135	cuentas_anuales.csv	OMITIDO	107,08/12/2024,compra,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	246	2026-09-20 21:44:17.315678
143	cuentas_anuales.csv	OMITIDO	106,19/10/2024,deposito,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	249	2026-09-20 21:44:17.418657
146	cuentas_anuales.csv	OMITIDO	105,2024-08-11,deposito,,Compra en tienda	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	256	2026-09-20 21:44:17.427943
155	cuentas_anuales.csv	OMITIDO	108,2024-09-29,deposito,,Ingreso extra	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	271	2026-09-20 21:44:17.446736
181	cuentas_anuales.csv	OMITIDO	119,2024/02/29,compra,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	318	2026-09-20 21:44:17.498511
202	cuentas_anuales.csv	OMITIDO	105,17/12/2024,retiro,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	363	2026-09-20 21:44:17.5427
207	cuentas_anuales.csv	OMITIDO	104,2024-07-17,compra,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	371	2026-09-20 21:44:17.551735
210	cuentas_anuales.csv	OMITIDO	111,04/05/2024,deposito,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	374	2026-09-20 21:44:17.557911
215	cuentas_anuales.csv	OMITIDO	117,01-11-2024,deposito,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	379	2026-09-20 21:44:17.56445
219	cuentas_anuales.csv	OMITIDO	120,2024-07-26,retiro,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	382	2026-09-20 21:44:17.572731
221	cuentas_anuales.csv	OMITIDO	102,2024/08/30,retiro,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	385	2026-09-20 21:44:17.575273
228	cuentas_anuales.csv	OMITIDO	107,15-06-2024,compra,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	396	2026-09-20 21:44:17.588345
237	cuentas_anuales.csv	OMITIDO	114,2024-03-16,compra,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	409	2026-09-20 21:44:17.607469
253	cuentas_anuales.csv	OMITIDO	118,09/06/2024,retiro,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	439	2026-09-20 21:44:17.63955
269	cuentas_anuales.csv	OMITIDO	116,2024/03/10,retiro,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	472	2026-09-20 21:44:17.67471
279	cuentas_anuales.csv	OMITIDO	104,31/05/2024,retiro,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	491	2026-09-20 21:44:17.689157
294	cuentas_anuales.csv	OMITIDO	113,13/12/2024,compra,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	516	2026-09-20 21:44:17.720096
300	cuentas_anuales.csv	OMITIDO	102,2024/12/27,retiro,,Compra en tienda	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	526	2026-09-20 21:44:17.733395
305	cuentas_anuales.csv	OMITIDO	116,04-04-2024,compra,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	530	2026-09-20 21:44:17.741607
330	cuentas_anuales.csv	OMITIDO	105,2024/03/11,retiro,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	581	2026-09-20 21:44:17.795189
345	cuentas_anuales.csv	OMITIDO	109,2024-09-03,retiro,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	605	2026-09-20 21:44:17.820605
351	cuentas_anuales.csv	OMITIDO	118,11/01/2024,retiro,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	613	2026-09-20 21:44:17.832905
357	cuentas_anuales.csv	OMITIDO	114,2024/09/16,compra,,Ingreso extra	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	621	2026-09-20 21:44:17.841163
371	cuentas_anuales.csv	OMITIDO	107,08-05-2024,compra,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	645	2026-09-20 21:44:17.864845
376	cuentas_anuales.csv	OMITIDO	112,2024/03/15,compra,,Ingreso extra	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	649	2026-09-20 21:44:17.871417
387	cuentas_anuales.csv	OMITIDO	113,2024/09/13,retiro,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	667	2026-09-20 21:44:17.893725
409	cuentas_anuales.csv	OMITIDO	103,13-09-2024,compra,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	707	2026-09-20 21:44:17.927355
447	cuentas_anuales.csv	OMITIDO	110,08-02-2024,compra,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	790	2026-09-20 21:44:17.992771
450	cuentas_anuales.csv	OMITIDO	105,01/09/2024,deposito,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	793	2026-09-20 21:44:17.997393
478	cuentas_anuales.csv	OMITIDO	114,2024-05-18,deposito,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	842	2026-09-20 21:44:18.02709
480	cuentas_anuales.csv	OMITIDO	112,2024/08/11,deposito,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	849	2026-09-20 21:44:18.030748
483	cuentas_anuales.csv	OMITIDO	107,2024-02-07,deposito,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	851	2026-09-20 21:44:18.032657
2	intereses.csv	OMITIDO	137,Bob Johnson,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	2	2026-09-20 21:44:16.956758
4	intereses.csv	OMITIDO	114,Unknown,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	3	2026-09-20 21:44:16.973477
6	intereses.csv	OMITIDO	133,Alice Brown,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	4	2026-09-20 21:44:16.976419
9	intereses.csv	OMITIDO	108,Jane Smith,12000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	7	2026-09-20 21:44:16.986585
10	intereses.csv	OMITIDO	138,Steve Rogers,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	9	2026-09-20 21:44:16.988601
12	intereses.csv	OMITIDO	113,Charlie Green,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	10	2026-09-20 21:44:16.991454
14	intereses.csv	OMITIDO	102,Alice Brown,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	12	2026-09-20 21:44:17.004089
15	intereses.csv	OMITIDO	145,Charlie Green,8000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	15	2026-09-20 21:44:17.006774
18	intereses.csv	OMITIDO	117,Steve Rogers,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	17	2026-09-20 21:44:17.015052
19	intereses.csv	OMITIDO	128,Diana Prince,7000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	18	2026-09-20 21:44:17.01825
20	intereses.csv	OMITIDO	147,Alice Brown,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	19	2026-09-20 21:44:17.02129
21	intereses.csv	OMITIDO	148,John Doe,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	20	2026-09-20 21:44:17.024111
23	intereses.csv	OMITIDO	142,Steve Rogers,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	21	2026-09-20 21:44:17.026492
26	intereses.csv	OMITIDO	103,Jane Smith,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	23	2026-09-20 21:44:17.035278
27	intereses.csv	OMITIDO	110,Unknown,5000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	24	2026-09-20 21:44:17.038817
29	intereses.csv	OMITIDO	111,Diana Prince,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	25	2026-09-20 21:44:17.041389
33	intereses.csv	OMITIDO	136,Charlie Green,8000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	26	2026-09-20 21:44:17.044247
35	intereses.csv	OMITIDO	146,Steve Rogers,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	27	2026-09-20 21:44:17.052129
37	intereses.csv	OMITIDO	134,Charlie Green,8000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	28	2026-09-20 21:44:17.054671
38	intereses.csv	OMITIDO	107,Alice Brown,,25,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	30	2026-09-20 21:44:17.056727
41	intereses.csv	OMITIDO	103,Jane Smith,7000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	32	2026-09-20 21:44:17.064111
43	intereses.csv	OMITIDO	110,Jane Smith,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	33	2026-09-20 21:44:17.073947
44	intereses.csv	OMITIDO	116,Diana Prince,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	34	2026-09-20 21:44:17.076761
45	intereses.csv	OMITIDO	141,Unknown,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	36	2026-09-20 21:44:17.079199
49	intereses.csv	OMITIDO	120,John Doe,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	37	2026-09-20 21:44:17.086859
50	intereses.csv	OMITIDO	140,John Doe,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	39	2026-09-20 21:44:17.088416
51	intereses.csv	OMITIDO	107,Diana Prince,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	40	2026-09-20 21:44:17.090375
54	intereses.csv	OMITIDO	150,Charlie Green,,40,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	43	2026-09-20 21:44:17.110057
55	intereses.csv	OMITIDO	137,Steve Rogers,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	44	2026-09-20 21:44:17.112339
56	intereses.csv	OMITIDO	126,Jane Smith,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	45	2026-09-20 21:44:17.115357
61	intereses.csv	OMITIDO	104,Steve Rogers,8000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	48	2026-09-20 21:44:17.122632
62	intereses.csv	OMITIDO	143,Charlie Green,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	49	2026-09-20 21:44:17.124893
63	intereses.csv	OMITIDO	133,Steve Rogers,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	50	2026-09-20 21:44:17.127191
65	intereses.csv	OMITIDO	121,Alice Brown,12000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	51	2026-09-20 21:44:17.140709
68	intereses.csv	OMITIDO	104,Jane Smith,12000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	53	2026-09-20 21:44:17.149586
69	intereses.csv	OMITIDO	127,John Doe,5000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	54	2026-09-20 21:44:17.151231
70	intereses.csv	OMITIDO	123,Diana Prince,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	56	2026-09-20 21:44:17.153353
73	intereses.csv	OMITIDO	138,Alice Brown,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	57	2026-09-20 21:44:17.165014
76	intereses.csv	OMITIDO	121,Steve Rogers,8000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	58	2026-09-20 21:44:17.167513
3	transacciones.csv	OMITIDO	3,2024-04-09,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	4	2026-09-20 21:44:16.95682
5	transacciones.csv	OMITIDO	4,04/05/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	5	2026-09-20 21:44:16.97348
7	transacciones.csv	OMITIDO	7,2024-13-01,700,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	8	2026-09-20 21:44:16.983717
8	transacciones.csv	OMITIDO	9,07-04-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	10	2026-09-20 21:44:16.986294
11	transacciones.csv	OMITIDO	10,2024/10/15,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	11	2026-09-20 21:44:16.988853
13	transacciones.csv	OMITIDO	15,01/06/2024,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	16	2026-09-20 21:44:16.999963
16	transacciones.csv	OMITIDO	16,2024-04-27,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	17	2026-09-20 21:44:17.009954
17	transacciones.csv	OMITIDO	17,18/12/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	18	2026-09-20 21:44:17.013195
22	transacciones.csv	OMITIDO	22,2024/06/05,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	23	2026-09-20 21:44:17.024188
24	transacciones.csv	OMITIDO	23,2024-13-01,1000,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	24	2026-09-20 21:44:17.026766
25	transacciones.csv	OMITIDO	25,09/11/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	26	2026-09-20 21:44:17.029938
28	transacciones.csv	OMITIDO	28,2024-09-03,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	29	2026-09-20 21:44:17.039425
30	transacciones.csv	OMITIDO	29,27-05-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	30	2026-09-20 21:44:17.041447
32	transacciones.csv	OMITIDO	30,09/02/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	31	2026-09-20 21:44:17.043834
34	transacciones.csv	OMITIDO	31,2024/04/11,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	32	2026-09-20 21:44:17.051771
36	transacciones.csv	OMITIDO	32,2024/01/01,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	33	2026-09-20 21:44:17.053789
40	transacciones.csv	OMITIDO	39,18/11/2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	40	2026-09-20 21:44:17.06121
42	transacciones.csv	OMITIDO	40,2024-13-01,3000,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	41	2026-09-20 21:44:17.073929
47	transacciones.csv	OMITIDO	43,2024-12-06,-100,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	44	2026-09-20 21:44:17.082533
48	transacciones.csv	OMITIDO	45,23/08/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	46	2026-09-20 21:44:17.084991
52	transacciones.csv	OMITIDO	47,30-11-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	48	2026-09-20 21:44:17.093132
53	transacciones.csv	OMITIDO	50,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	51	2026-09-20 21:44:17.107779
57	transacciones.csv	OMITIDO	52,16/03/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	53	2026-09-20 21:44:17.116265
58	transacciones.csv	OMITIDO	53,02/07/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	54	2026-09-20 21:44:17.118668
59	transacciones.csv	OMITIDO	54,21-02-2024,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	55	2026-09-20 21:44:17.120974
64	transacciones.csv	OMITIDO	57,27/07/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	58	2026-09-20 21:44:17.128476
66	transacciones.csv	OMITIDO	60,2024-04-04,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	61	2026-09-20 21:44:17.141167
67	transacciones.csv	OMITIDO	65,16/10/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	66	2026-09-20 21:44:17.149363
71	transacciones.csv	OMITIDO	66,2024-05-28,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	67	2026-09-20 21:44:17.156766
72	transacciones.csv	OMITIDO	68,2024-01-11,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	69	2026-09-20 21:44:17.163117
74	transacciones.csv	OMITIDO	69,29/09/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	70	2026-09-20 21:44:17.165273
75	transacciones.csv	OMITIDO	70,2024/09/18,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	71	2026-09-20 21:44:17.166921
77	intereses.csv	OMITIDO	107,Charlie Green,10000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	59	2026-09-20 21:44:17.169574
79	intereses.csv	OMITIDO	119,John Doe,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	60	2026-09-20 21:44:17.172186
80	transacciones.csv	OMITIDO	72,2024-03-01,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	73	2026-09-20 21:44:17.173974
81	transacciones.csv	OMITIDO	74,30/07/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	75	2026-09-20 21:44:17.175697
82	intereses.csv	OMITIDO	132,Jane Smith,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	62	2026-09-20 21:44:17.178028
84	intereses.csv	OMITIDO	137,Bob Johnson,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	63	2026-09-20 21:44:17.185088
85	intereses.csv	OMITIDO	139,Bob Johnson,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	64	2026-09-20 21:44:17.187159
86	transacciones.csv	OMITIDO	77,2024-13-01,3000,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	78	2026-09-20 21:44:17.188117
88	transacciones.csv	OMITIDO	79,02/06/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	80	2026-09-20 21:44:17.190493
89	transacciones.csv	OMITIDO	80,16-04-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	81	2026-09-20 21:44:17.191844
92	transacciones.csv	OMITIDO	81,2024/06/18,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	82	2026-09-20 21:44:17.198016
95	transacciones.csv	OMITIDO	86,2024-11-04,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	87	2026-09-20 21:44:17.21228
96	transacciones.csv	OMITIDO	87,2024/10/22,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	88	2026-09-20 21:44:17.214581
98	transacciones.csv	OMITIDO	90,28/07/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	91	2026-09-20 21:44:17.216531
102	transacciones.csv	OMITIDO	98,2024-07-05,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	99	2026-09-20 21:44:17.232895
104	transacciones.csv	OMITIDO	100,15-06-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	101	2026-09-20 21:44:17.235586
107	transacciones.csv	OMITIDO	105,2024-12-13,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	106	2026-09-20 21:44:17.242707
110	transacciones.csv	OMITIDO	107,16/01/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	108	2026-09-20 21:44:17.258145
112	transacciones.csv	OMITIDO	108,2024/02/28,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	109	2026-09-20 21:44:17.260814
114	transacciones.csv	OMITIDO	109,2024-09-15,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	110	2026-09-20 21:44:17.262664
116	transacciones.csv	OMITIDO	114,01-02-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	115	2026-09-20 21:44:17.269765
120	transacciones.csv	OMITIDO	116,2024-10-03,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	117	2026-09-20 21:44:17.279547
121	transacciones.csv	OMITIDO	118,27/08/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	119	2026-09-20 21:44:17.282677
123	transacciones.csv	OMITIDO	119,06-12-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	120	2026-09-20 21:44:17.285524
126	transacciones.csv	OMITIDO	122,2024-08-26,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	123	2026-09-20 21:44:17.296017
127	transacciones.csv	OMITIDO	124,2024/08/22,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	125	2026-09-20 21:44:17.298369
131	transacciones.csv	OMITIDO	127,2024-04-09,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	128	2026-09-20 21:44:17.308227
132	transacciones.csv	OMITIDO	128,2024-07-26,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	129	2026-09-20 21:44:17.310844
134	transacciones.csv	OMITIDO	129,14-11-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	130	2026-09-20 21:44:17.31388
138	transacciones.csv	OMITIDO	132,2024-12-10,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	133	2026-09-20 21:44:17.359491
139	transacciones.csv	OMITIDO	133,21-07-2024,500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	134	2026-09-20 21:44:17.41225
142	transacciones.csv	OMITIDO	135,02/03/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	136	2026-09-20 21:44:17.417113
144	transacciones.csv	OMITIDO	136,2024/10/27,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	137	2026-09-20 21:44:17.427154
148	transacciones.csv	OMITIDO	137,17-06-2024,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	138	2026-09-20 21:44:17.430007
150	transacciones.csv	OMITIDO	138,2024-13-01,1000,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	139	2026-09-20 21:44:17.43276
153	transacciones.csv	OMITIDO	146,01-07-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	147	2026-09-20 21:44:17.445957
156	transacciones.csv	OMITIDO	148,2024-03-30,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	149	2026-09-20 21:44:17.448538
158	transacciones.csv	OMITIDO	149,02/11/2024,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	150	2026-09-20 21:44:17.45045
159	transacciones.csv	OMITIDO	150,2024-13-01,1500,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	151	2026-09-20 21:44:17.453081
163	transacciones.csv	OMITIDO	152,25/10/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	153	2026-09-20 21:44:17.46027
165	transacciones.csv	OMITIDO	155,22/12/2024,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	156	2026-09-20 21:44:17.462422
167	transacciones.csv	OMITIDO	160,03/08/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	161	2026-09-20 21:44:17.469342
170	transacciones.csv	OMITIDO	163,30-11-2024,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	164	2026-09-20 21:44:17.477747
171	transacciones.csv	OMITIDO	164,04-03-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	165	2026-09-20 21:44:17.480328
172	transacciones.csv	OMITIDO	165,2024-08-30,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	166	2026-09-20 21:44:17.482943
87	intereses.csv	OMITIDO	102,Alice Brown,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	65	2026-09-20 21:44:17.189102
90	intereses.csv	OMITIDO	141,Bob Johnson,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	67	2026-09-20 21:44:17.194477
91	intereses.csv	OMITIDO	140,Bob Johnson,8000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	68	2026-09-20 21:44:17.196481
93	intereses.csv	OMITIDO	126,Alice Brown,12000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	69	2026-09-20 21:44:17.20768
94	intereses.csv	OMITIDO	123,John Doe,12000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	71	2026-09-20 21:44:17.20999
97	intereses.csv	OMITIDO	107,Diana Prince,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	74	2026-09-20 21:44:17.216065
99	intereses.csv	OMITIDO	107,Unknown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	75	2026-09-20 21:44:17.218111
100	intereses.csv	OMITIDO	120,Bob Johnson,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	76	2026-09-20 21:44:17.219549
101	intereses.csv	OMITIDO	111,Charlie Green,12000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	77	2026-09-20 21:44:17.232465
103	intereses.csv	OMITIDO	120,Unknown,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	79	2026-09-20 21:44:17.234146
105	intereses.csv	OMITIDO	137,Alice Brown,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	81	2026-09-20 21:44:17.236216
106	intereses.csv	OMITIDO	119,Bob Johnson,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	82	2026-09-20 21:44:17.242158
108	intereses.csv	OMITIDO	136,Charlie Green,10000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	83	2026-09-20 21:44:17.253529
109	intereses.csv	OMITIDO	130,Charlie Green,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	84	2026-09-20 21:44:17.255567
111	intereses.csv	OMITIDO	137,John Doe,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	85	2026-09-20 21:44:17.258155
113	intereses.csv	OMITIDO	102,Bob Johnson,8000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	86	2026-09-20 21:44:17.261118
115	intereses.csv	OMITIDO	114,Charlie Green,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	87	2026-09-20 21:44:17.268152
117	intereses.csv	OMITIDO	112,Steve Rogers,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	88	2026-09-20 21:44:17.270231
118	intereses.csv	OMITIDO	140,Jane Smith,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	89	2026-09-20 21:44:17.272394
119	intereses.csv	OMITIDO	110,Charlie Green,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	90	2026-09-20 21:44:17.275374
122	intereses.csv	OMITIDO	149,Bob Johnson,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	94	2026-09-20 21:44:17.285351
125	intereses.csv	OMITIDO	122,Bob Johnson,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	97	2026-09-20 21:44:17.296004
128	intereses.csv	OMITIDO	102,Jane Smith,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	98	2026-09-20 21:44:17.298881
129	intereses.csv	OMITIDO	138,John Doe,12000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	99	2026-09-20 21:44:17.301624
130	intereses.csv	OMITIDO	139,Alice Brown,5000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	101	2026-09-20 21:44:17.303801
133	intereses.csv	OMITIDO	136,Alice Brown,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	102	2026-09-20 21:44:17.312731
136	intereses.csv	OMITIDO	103,Charlie Green,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	103	2026-09-20 21:44:17.315984
137	intereses.csv	OMITIDO	147,Bob Johnson,7000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	104	2026-09-20 21:44:17.356909
140	intereses.csv	OMITIDO	127,Alice Brown,7000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	105	2026-09-20 21:44:17.412333
141	intereses.csv	OMITIDO	149,Alice Brown,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	106	2026-09-20 21:44:17.416643
145	intereses.csv	OMITIDO	115,Charlie Green,8000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	107	2026-09-20 21:44:17.427174
147	intereses.csv	OMITIDO	131,Steve Rogers,8000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	108	2026-09-20 21:44:17.429663
149	intereses.csv	OMITIDO	148,Bob Johnson,,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	109	2026-09-20 21:44:17.432393
151	intereses.csv	OMITIDO	108,Jane Smith,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	112	2026-09-20 21:44:17.440469
152	intereses.csv	OMITIDO	113,Jane Smith,10000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	114	2026-09-20 21:44:17.443079
154	intereses.csv	OMITIDO	135,Charlie Green,12000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	115	2026-09-20 21:44:17.446479
157	intereses.csv	OMITIDO	150,Steve Rogers,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	116	2026-09-20 21:44:17.448815
160	intereses.csv	OMITIDO	123,Diana Prince,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	117	2026-09-20 21:44:17.454833
161	intereses.csv	OMITIDO	146,Jane Smith,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	118	2026-09-20 21:44:17.457267
162	intereses.csv	OMITIDO	105,Steve Rogers,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	119	2026-09-20 21:44:17.459633
164	intereses.csv	OMITIDO	127,Diana Prince,,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	120	2026-09-20 21:44:17.46206
166	intereses.csv	OMITIDO	113,Charlie Green,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	121	2026-09-20 21:44:17.464565
168	intereses.csv	OMITIDO	145,Diana Prince,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	122	2026-09-20 21:44:17.471863
169	intereses.csv	OMITIDO	142,John Doe,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	124	2026-09-20 21:44:17.475506
173	intereses.csv	OMITIDO	133,John Doe,12000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	127	2026-09-20 21:44:17.483365
174	intereses.csv	OMITIDO	128,John Doe,,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	128	2026-09-20 21:44:17.485472
175	intereses.csv	OMITIDO	126,Diana Prince,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	131	2026-09-20 21:44:17.488442
178	intereses.csv	OMITIDO	149,Alice Brown,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	132	2026-09-20 21:44:17.495758
180	intereses.csv	OMITIDO	111,Unknown,5000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	134	2026-09-20 21:44:17.4981
182	intereses.csv	OMITIDO	121,John Doe,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	136	2026-09-20 21:44:17.500804
185	intereses.csv	OMITIDO	123,Bob Johnson,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	137	2026-09-20 21:44:17.508165
187	intereses.csv	OMITIDO	108,Alice Brown,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	138	2026-09-20 21:44:17.510517
188	intereses.csv	OMITIDO	121,John Doe,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	139	2026-09-20 21:44:17.512545
189	intereses.csv	OMITIDO	108,Jane Smith,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	141	2026-09-20 21:44:17.515701
192	intereses.csv	OMITIDO	115,Bob Johnson,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	143	2026-09-20 21:44:17.524213
194	intereses.csv	OMITIDO	135,Diana Prince,7000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	144	2026-09-20 21:44:17.526098
196	intereses.csv	OMITIDO	137,Steve Rogers,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	146	2026-09-20 21:44:17.52903
198	intereses.csv	OMITIDO	112,John Doe,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	148	2026-09-20 21:44:17.53661
199	intereses.csv	OMITIDO	111,John Doe,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	149	2026-09-20 21:44:17.53915
201	intereses.csv	OMITIDO	121,John Doe,,150,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	150	2026-09-20 21:44:17.541594
203	intereses.csv	OMITIDO	117,Bob Johnson,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	151	2026-09-20 21:44:17.54389
206	intereses.csv	OMITIDO	120,Diana Prince,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	152	2026-09-20 21:44:17.55108
208	intereses.csv	OMITIDO	129,John Doe,12000,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	155	2026-09-20 21:44:17.552982
212	intereses.csv	OMITIDO	122,Jane Smith,5000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	157	2026-09-20 21:44:17.559781
213	intereses.csv	OMITIDO	138,Diana Prince,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	158	2026-09-20 21:44:17.561773
214	intereses.csv	OMITIDO	145,Steve Rogers,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	161	2026-09-20 21:44:17.564223
220	intereses.csv	OMITIDO	107,Steve Rogers,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	162	2026-09-20 21:44:17.573846
222	intereses.csv	OMITIDO	146,Jane Smith,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	165	2026-09-20 21:44:17.576071
223	intereses.csv	OMITIDO	116,Steve Rogers,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	166	2026-09-20 21:44:17.57878
226	intereses.csv	OMITIDO	123,Alice Brown,,25,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	167	2026-09-20 21:44:17.585473
227	intereses.csv	OMITIDO	103,Alice Brown,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	168	2026-09-20 21:44:17.587659
230	intereses.csv	OMITIDO	140,John Doe,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	169	2026-09-20 21:44:17.590848
232	intereses.csv	OMITIDO	120,Charlie Green,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	170	2026-09-20 21:44:17.593974
233	intereses.csv	OMITIDO	105,Jane Smith,7000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	171	2026-09-20 21:44:17.596594
235	intereses.csv	OMITIDO	132,Bob Johnson,5000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	173	2026-09-20 21:44:17.604728
238	intereses.csv	OMITIDO	120,Alice Brown,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	175	2026-09-20 21:44:17.607963
241	intereses.csv	OMITIDO	143,Charlie Green,5000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	177	2026-09-20 21:44:17.61586
243	intereses.csv	OMITIDO	123,Steve Rogers,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	178	2026-09-20 21:44:17.618089
245	intereses.csv	OMITIDO	123,Bob Johnson,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	182	2026-09-20 21:44:17.624872
176	transacciones.csv	OMITIDO	167,23/02/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	168	2026-09-20 21:44:17.490038
177	transacciones.csv	OMITIDO	169,2024/03/05,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	170	2026-09-20 21:44:17.492837
179	transacciones.csv	OMITIDO	170,2024/09/07,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	171	2026-09-20 21:44:17.495785
183	transacciones.csv	OMITIDO	171,14-05-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	172	2026-09-20 21:44:17.50452
184	transacciones.csv	OMITIDO	174,2024-10-26,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	175	2026-09-20 21:44:17.506879
186	transacciones.csv	OMITIDO	175,24-09-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	176	2026-09-20 21:44:17.509034
190	transacciones.csv	OMITIDO	176,2024-06-07,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	177	2026-09-20 21:44:17.516111
191	transacciones.csv	OMITIDO	180,28/05/2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	181	2026-09-20 21:44:17.518446
193	transacciones.csv	OMITIDO	181,2024/09/08,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	182	2026-09-20 21:44:17.525993
195	transacciones.csv	OMITIDO	185,2024-13-01,1000,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	186	2026-09-20 21:44:17.528738
197	transacciones.csv	OMITIDO	186,2024-01-04,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	187	2026-09-20 21:44:17.53661
200	transacciones.csv	OMITIDO	189,2024-01-17,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	190	2026-09-20 21:44:17.53915
204	transacciones.csv	OMITIDO	191,26-07-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	192	2026-09-20 21:44:17.546527
205	transacciones.csv	OMITIDO	193,2024-01-16,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	194	2026-09-20 21:44:17.54891
209	transacciones.csv	OMITIDO	199,01/06/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	200	2026-09-20 21:44:17.555737
211	transacciones.csv	OMITIDO	200,2024/10/13,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	201	2026-09-20 21:44:17.5582
216	transacciones.csv	OMITIDO	202,09-01-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	203	2026-09-20 21:44:17.566018
217	transacciones.csv	OMITIDO	203,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	204	2026-09-20 21:44:17.568014
218	transacciones.csv	OMITIDO	205,07-08-2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	206	2026-09-20 21:44:17.570184
224	transacciones.csv	OMITIDO	208,2024/01/29,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	209	2026-09-20 21:44:17.579479
225	transacciones.csv	OMITIDO	209,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	210	2026-09-20 21:44:17.581364
229	transacciones.csv	OMITIDO	211,2024-04-18,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	212	2026-09-20 21:44:17.588971
231	transacciones.csv	OMITIDO	214,2024/04/15,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	215	2026-09-20 21:44:17.591294
234	transacciones.csv	OMITIDO	216,2024-03-05,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	217	2026-09-20 21:44:17.599998
236	transacciones.csv	OMITIDO	221,19-06-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	222	2026-09-20 21:44:17.606731
239	transacciones.csv	OMITIDO	225,2024/04/01,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	226	2026-09-20 21:44:17.609681
240	transacciones.csv	OMITIDO	228,2024-07-12,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	229	2026-09-20 21:44:17.615806
242	transacciones.csv	OMITIDO	229,22-10-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	230	2026-09-20 21:44:17.618103
244	transacciones.csv	OMITIDO	230,13/01/2024,-100,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	231	2026-09-20 21:44:17.621035
247	transacciones.csv	OMITIDO	231,2024/12/25,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	232	2026-09-20 21:44:17.628249
248	transacciones.csv	OMITIDO	232,04/02/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	233	2026-09-20 21:44:17.630442
249	transacciones.csv	OMITIDO	235,07-04-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	236	2026-09-20 21:44:17.632076
254	transacciones.csv	OMITIDO	242,24-07-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	243	2026-09-20 21:44:17.643474
255	transacciones.csv	OMITIDO	244,2024-07-23,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	245	2026-09-20 21:44:17.645985
258	transacciones.csv	OMITIDO	247,13/05/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	248	2026-09-20 21:44:17.652652
260	transacciones.csv	OMITIDO	248,10-12-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	249	2026-09-20 21:44:17.655422
261	transacciones.csv	OMITIDO	249,19/06/2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	250	2026-09-20 21:44:17.657506
264	transacciones.csv	OMITIDO	253,02-09-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	254	2026-09-20 21:44:17.664815
266	transacciones.csv	OMITIDO	254,2024/10/26,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	255	2026-09-20 21:44:17.667031
246	intereses.csv	OMITIDO	135,Steve Rogers,10000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	183	2026-09-20 21:44:17.627539
250	intereses.csv	OMITIDO	104,Jane Smith,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	187	2026-09-20 21:44:17.63491
251	intereses.csv	OMITIDO	110,Charlie Green,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	188	2026-09-20 21:44:17.636724
252	intereses.csv	OMITIDO	145,Steve Rogers,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	191	2026-09-20 21:44:17.63884
256	intereses.csv	OMITIDO	109,Steve Rogers,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	192	2026-09-20 21:44:17.647499
257	intereses.csv	OMITIDO	132,John Doe,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	193	2026-09-20 21:44:17.650183
259	intereses.csv	OMITIDO	150,Alice Brown,10000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	195	2026-09-20 21:44:17.652695
262	intereses.csv	OMITIDO	145,Alice Brown,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	197	2026-09-20 21:44:17.661705
263	intereses.csv	OMITIDO	148,Alice Brown,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	198	2026-09-20 21:44:17.664254
265	intereses.csv	OMITIDO	120,Charlie Green,7000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	199	2026-09-20 21:44:17.666511
267	intereses.csv	OMITIDO	103,Bob Johnson,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	201	2026-09-20 21:44:17.669189
270	intereses.csv	OMITIDO	137,Alice Brown,,45,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	202	2026-09-20 21:44:17.675632
272	intereses.csv	OMITIDO	140,Alice Brown,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	203	2026-09-20 21:44:17.677711
274	intereses.csv	OMITIDO	114,Bob Johnson,5000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	205	2026-09-20 21:44:17.679778
275	intereses.csv	OMITIDO	114,Steve Rogers,5000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	206	2026-09-20 21:44:17.682468
278	intereses.csv	FILTRADO	140,John Doe,,45,-1	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	209	2026-09-20 21:44:17.688349
281	intereses.csv	OMITIDO	105,Diana Prince,5000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	207	2026-09-20 21:44:17.690593
282	intereses.csv	OMITIDO	116,Alice Brown,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	208	2026-09-20 21:44:17.692434
283	intereses.csv	OMITIDO	142,Alice Brown,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	210	2026-09-20 21:44:17.694572
285	intereses.csv	OMITIDO	125,Jane Smith,12000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	211	2026-09-20 21:44:17.697887
289	intereses.csv	OMITIDO	114,Charlie Green,7000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	213	2026-09-20 21:44:17.708041
290	intereses.csv	OMITIDO	112,John Doe,12000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	214	2026-09-20 21:44:17.711443
292	intereses.csv	OMITIDO	128,Jane Smith,7000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	215	2026-09-20 21:44:17.714964
296	intereses.csv	OMITIDO	150,Jane Smith,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	217	2026-09-20 21:44:17.724017
297	intereses.csv	OMITIDO	129,Charlie Green,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	218	2026-09-20 21:44:17.72657
298	intereses.csv	OMITIDO	127,Steve Rogers,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	221	2026-09-20 21:44:17.72962
301	intereses.csv	OMITIDO	125,Charlie Green,12000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	222	2026-09-20 21:44:17.736726
303	intereses.csv	OMITIDO	126,Diana Prince,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	223	2026-09-20 21:44:17.739432
306	intereses.csv	OMITIDO	118,Bob Johnson,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	224	2026-09-20 21:44:17.741608
307	intereses.csv	OMITIDO	114,Alice Brown,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	225	2026-09-20 21:44:17.743958
308	intereses.csv	OMITIDO	114,Charlie Green,10000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	226	2026-09-20 21:44:17.746332
310	intereses.csv	OMITIDO	138,Diana Prince,7000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	227	2026-09-20 21:44:17.756193
312	intereses.csv	OMITIDO	140,Steve Rogers,12000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	231	2026-09-20 21:44:17.758901
315	intereses.csv	OMITIDO	144,Charlie Green,7000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	235	2026-09-20 21:44:17.768069
317	intereses.csv	OMITIDO	132,Alice Brown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	236	2026-09-20 21:44:17.770523
321	intereses.csv	OMITIDO	122,Jane Smith,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	237	2026-09-20 21:44:17.779011
323	intereses.csv	OMITIDO	116,Alice Brown,12000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	238	2026-09-20 21:44:17.781236
324	intereses.csv	OMITIDO	129,Unknown,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	240	2026-09-20 21:44:17.783358
325	intereses.csv	OMITIDO	117,Steve Rogers,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	241	2026-09-20 21:44:17.786638
268	transacciones.csv	OMITIDO	258,2024/01/06,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	259	2026-09-20 21:44:17.674498
271	transacciones.csv	OMITIDO	259,04-05-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	260	2026-09-20 21:44:17.676628
273	transacciones.csv	OMITIDO	260,2024-03-23,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	261	2026-09-20 21:44:17.678185
276	transacciones.csv	OMITIDO	262,02/09/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	263	2026-09-20 21:44:17.684807
277	transacciones.csv	OMITIDO	263,02-07-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	264	2026-09-20 21:44:17.68704
280	transacciones.csv	OMITIDO	264,2024-13-01,1500,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	265	2026-09-20 21:44:17.689417
284	transacciones.csv	OMITIDO	266,02-11-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	267	2026-09-20 21:44:17.696876
286	transacciones.csv	OMITIDO	267,2024/04/06,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	268	2026-09-20 21:44:17.699521
287	transacciones.csv	OMITIDO	269,2024/07/27,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	270	2026-09-20 21:44:17.702674
288	transacciones.csv	OMITIDO	270,2024-13-01,1200,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	271	2026-09-20 21:44:17.706065
291	transacciones.csv	OMITIDO	271,2024-03-18,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	272	2026-09-20 21:44:17.714623
293	transacciones.csv	OMITIDO	272,2024/09/04,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	273	2026-09-20 21:44:17.717898
295	transacciones.csv	OMITIDO	273,26/04/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	274	2026-09-20 21:44:17.7204
299	transacciones.csv	OMITIDO	279,2024-02-24,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	280	2026-09-20 21:44:17.729831
302	transacciones.csv	OMITIDO	282,08/08/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	283	2026-09-20 21:44:17.738186
304	transacciones.csv	OMITIDO	285,13/12/2024,1500,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	286	2026-09-20 21:44:17.74114
309	transacciones.csv	OMITIDO	291,2024-04-17,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	292	2026-09-20 21:44:17.753902
311	transacciones.csv	OMITIDO	293,18/10/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	294	2026-09-20 21:44:17.756702
313	transacciones.csv	OMITIDO	294,2024/07/01,700,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	295	2026-09-20 21:44:17.759365
314	transacciones.csv	OMITIDO	295,2024-06-12,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	296	2026-09-20 21:44:17.761406
316	transacciones.csv	OMITIDO	296,09/12/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	297	2026-09-20 21:44:17.769604
318	transacciones.csv	OMITIDO	297,2024-08-19,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	298	2026-09-20 21:44:17.772514
319	transacciones.csv	OMITIDO	298,2024-13-01,700,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	299	2026-09-20 21:44:17.775423
320	transacciones.csv	OMITIDO	299,2024-10-10,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	300	2026-09-20 21:44:17.778274
322	transacciones.csv	OMITIDO	300,2024-03-28,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	301	2026-09-20 21:44:17.780858
326	transacciones.csv	OMITIDO	302,16/10/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	303	2026-09-20 21:44:17.789107
327	transacciones.csv	OMITIDO	304,03-03-2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	305	2026-09-20 21:44:17.791459
328	transacciones.csv	OMITIDO	305,18-10-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	306	2026-09-20 21:44:17.793837
332	transacciones.csv	OMITIDO	306,2024-07-08,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	307	2026-09-20 21:44:17.802514
334	transacciones.csv	OMITIDO	307,02/01/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	308	2026-09-20 21:44:17.804836
336	transacciones.csv	OMITIDO	308,2024-13-01,,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	309	2026-09-20 21:44:17.806708
338	transacciones.csv	OMITIDO	310,14/12/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	311	2026-09-20 21:44:17.80843
339	transacciones.csv	OMITIDO	311,2024-13-01,1000,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	312	2026-09-20 21:44:17.81533
341	transacciones.csv	OMITIDO	312,24/06/2024,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	313	2026-09-20 21:44:17.817572
343	transacciones.csv	OMITIDO	313,16/10/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	314	2026-09-20 21:44:17.819819
346	transacciones.csv	OMITIDO	314,22/03/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	315	2026-09-20 21:44:17.822318
348	transacciones.csv	OMITIDO	315,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	316	2026-09-20 21:44:17.824512
350	transacciones.csv	OMITIDO	316,2024/04/01,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	317	2026-09-20 21:44:17.832288
417	intereses.csv	OMITIDO	112,Jane Smith,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	307	2026-09-20 21:44:17.944129
329	intereses.csv	OMITIDO	147,John Doe,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	244	2026-09-20 21:44:17.794005
331	intereses.csv	OMITIDO	144,John Doe,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	246	2026-09-20 21:44:17.796395
333	intereses.csv	OMITIDO	123,Steve Rogers,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	247	2026-09-20 21:44:17.804066
335	intereses.csv	OMITIDO	122,Charlie Green,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	248	2026-09-20 21:44:17.805906
337	intereses.csv	OMITIDO	106,Diana Prince,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	250	2026-09-20 21:44:17.808055
340	intereses.csv	OMITIDO	125,Steve Rogers,,100,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	252	2026-09-20 21:44:17.81533
342	intereses.csv	OMITIDO	139,Alice Brown,12000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	254	2026-09-20 21:44:17.817605
344	intereses.csv	OMITIDO	115,Alice Brown,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	255	2026-09-20 21:44:17.819822
347	intereses.csv	OMITIDO	106,Diana Prince,5000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	256	2026-09-20 21:44:17.822805
349	intereses.csv	OMITIDO	114,Steve Rogers,7000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	257	2026-09-20 21:44:17.831164
352	intereses.csv	OMITIDO	103,Charlie Green,,30,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	259	2026-09-20 21:44:17.833882
355	intereses.csv	OMITIDO	109,Diana Prince,,40,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	260	2026-09-20 21:44:17.837966
359	intereses.csv	OMITIDO	102,Jane Smith,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	263	2026-09-20 21:44:17.845456
362	intereses.csv	OMITIDO	137,John Doe,10000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	267	2026-09-20 21:44:17.851696
363	intereses.csv	OMITIDO	136,Diana Prince,,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	268	2026-09-20 21:44:17.853728
364	intereses.csv	OMITIDO	123,John Doe,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	269	2026-09-20 21:44:17.855869
366	intereses.csv	OMITIDO	106,Alice Brown,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	270	2026-09-20 21:44:17.857827
368	intereses.csv	OMITIDO	123,Alice Brown,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	271	2026-09-20 21:44:17.859526
372	intereses.csv	OMITIDO	142,John Doe,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	273	2026-09-20 21:44:17.865746
373	intereses.csv	OMITIDO	122,Diana Prince,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	275	2026-09-20 21:44:17.867615
374	intereses.csv	OMITIDO	126,Charlie Green,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	276	2026-09-20 21:44:17.869982
377	intereses.csv	OMITIDO	121,Bob Johnson,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	279	2026-09-20 21:44:17.877673
379	intereses.csv	OMITIDO	149,Charlie Green,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	280	2026-09-20 21:44:17.880489
381	intereses.csv	OMITIDO	143,Diana Prince,,40,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	281	2026-09-20 21:44:17.883295
384	intereses.csv	OMITIDO	121,Charlie Green,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	282	2026-09-20 21:44:17.890526
386	intereses.csv	OMITIDO	116,John Doe,12000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	283	2026-09-20 21:44:17.893552
390	intereses.csv	OMITIDO	145,Jane Smith,,25,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	289	2026-09-20 21:44:17.900232
391	intereses.csv	OMITIDO	138,Alice Brown,,45,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	290	2026-09-20 21:44:17.902761
393	intereses.csv	OMITIDO	114,John Doe,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	291	2026-09-20 21:44:17.90566
395	intereses.csv	OMITIDO	101,Steve Rogers,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	294	2026-09-20 21:44:17.912312
397	intereses.csv	OMITIDO	128,Diana Prince,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	295	2026-09-20 21:44:17.913993
399	intereses.csv	OMITIDO	120,Alice Brown,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	296	2026-09-20 21:44:17.915263
401	intereses.csv	OMITIDO	150,Unknown,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	297	2026-09-20 21:44:17.920226
403	intereses.csv	OMITIDO	121,Alice Brown,5000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	298	2026-09-20 21:44:17.921807
405	intereses.csv	OMITIDO	114,Bob Johnson,8000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	299	2026-09-20 21:44:17.924286
407	intereses.csv	OMITIDO	117,Alice Brown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	300	2026-09-20 21:44:17.925913
410	intereses.csv	OMITIDO	147,Diana Prince,8000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	301	2026-09-20 21:44:17.92754
412	intereses.csv	OMITIDO	109,Bob Johnson,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	302	2026-09-20 21:44:17.935154
414	intereses.csv	OMITIDO	112,Diana Prince,10000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	303	2026-09-20 21:44:17.937071
415	intereses.csv	OMITIDO	120,Alice Brown,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	305	2026-09-20 21:44:17.938869
353	transacciones.csv	OMITIDO	317,19-01-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	318	2026-09-20 21:44:17.834493
354	transacciones.csv	OMITIDO	318,2024-06-04,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	319	2026-09-20 21:44:17.837833
356	transacciones.csv	OMITIDO	319,2024-05-08,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	320	2026-09-20 21:44:17.840185
358	transacciones.csv	OMITIDO	320,29/02/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	321	2026-09-20 21:44:17.842387
360	transacciones.csv	OMITIDO	322,2024-01-28,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	323	2026-09-20 21:44:17.848099
361	transacciones.csv	OMITIDO	324,23/09/2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	325	2026-09-20 21:44:17.850443
365	transacciones.csv	OMITIDO	326,2024/12/15,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	327	2026-09-20 21:44:17.856641
367	transacciones.csv	OMITIDO	327,30-04-2024,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	328	2026-09-20 21:44:17.858229
369	transacciones.csv	OMITIDO	329,2024-05-02,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	330	2026-09-20 21:44:17.860404
370	transacciones.csv	OMITIDO	330,04/12/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	331	2026-09-20 21:44:17.86264
375	transacciones.csv	OMITIDO	333,22-02-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	334	2026-09-20 21:44:17.870132
378	transacciones.csv	OMITIDO	336,2024/03/14,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	337	2026-09-20 21:44:17.879022
380	transacciones.csv	OMITIDO	338,2024/06/19,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	339	2026-09-20 21:44:17.881181
382	transacciones.csv	OMITIDO	339,06-06-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	340	2026-09-20 21:44:17.883736
383	transacciones.csv	OMITIDO	341,2024-01-28,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	342	2026-09-20 21:44:17.89045
385	transacciones.csv	OMITIDO	342,08-07-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	343	2026-09-20 21:44:17.893152
388	transacciones.csv	OMITIDO	343,08-01-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	344	2026-09-20 21:44:17.895243
389	transacciones.csv	OMITIDO	345,19/11/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	346	2026-09-20 21:44:17.897615
392	transacciones.csv	OMITIDO	346,2024/10/12,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	347	2026-09-20 21:44:17.905222
394	transacciones.csv	OMITIDO	347,20-05-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	348	2026-09-20 21:44:17.907279
396	transacciones.csv	OMITIDO	352,02/02/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	353	2026-09-20 21:44:17.913364
398	transacciones.csv	OMITIDO	353,18-04-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	354	2026-09-20 21:44:17.914494
400	transacciones.csv	OMITIDO	354,10/01/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	355	2026-09-20 21:44:17.915845
402	transacciones.csv	OMITIDO	357,2024-13-01,1000,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	358	2026-09-20 21:44:17.921444
404	transacciones.csv	OMITIDO	358,2024/10/10,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	359	2026-09-20 21:44:17.923827
406	transacciones.csv	OMITIDO	359,04/08/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	360	2026-09-20 21:44:17.925553
408	transacciones.csv	OMITIDO	360,23-04-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	361	2026-09-20 21:44:17.927355
411	transacciones.csv	OMITIDO	361,08/05/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	362	2026-09-20 21:44:17.934043
413	transacciones.csv	OMITIDO	363,2024/01/09,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	364	2026-09-20 21:44:17.936142
416	transacciones.csv	OMITIDO	369,2024/09/29,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	370	2026-09-20 21:44:17.941317
419	transacciones.csv	OMITIDO	374,2024/07/25,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	375	2026-09-20 21:44:17.948063
423	transacciones.csv	OMITIDO	377,25/05/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	378	2026-09-20 21:44:17.954578
425	transacciones.csv	OMITIDO	379,2024/03/09,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	380	2026-09-20 21:44:17.956736
428	transacciones.csv	OMITIDO	381,25/06/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	382	2026-09-20 21:44:17.961737
429	transacciones.csv	OMITIDO	382,04/07/2024,500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	383	2026-09-20 21:44:17.963556
430	transacciones.csv	OMITIDO	383,26-01-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	384	2026-09-20 21:44:17.96568
432	transacciones.csv	OMITIDO	384,2024/05/30,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	385	2026-09-20 21:44:17.968485
434	transacciones.csv	OMITIDO	385,27-07-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	386	2026-09-20 21:44:17.970358
436	transacciones.csv	OMITIDO	386,2024/01/01,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	387	2026-09-20 21:44:17.976722
418	intereses.csv	OMITIDO	141,Alice Brown,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	309	2026-09-20 21:44:17.9462
420	intereses.csv	OMITIDO	149,Steve Rogers,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	310	2026-09-20 21:44:17.948127
421	intereses.csv	OMITIDO	132,Bob Johnson,7000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	312	2026-09-20 21:44:17.951786
422	intereses.csv	OMITIDO	141,Alice Brown,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	313	2026-09-20 21:44:17.953912
424	intereses.csv	OMITIDO	123,Unknown,7000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	314	2026-09-20 21:44:17.956147
426	intereses.csv	OMITIDO	118,John Doe,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	315	2026-09-20 21:44:17.958104
427	intereses.csv	OMITIDO	138,Jane Smith,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	316	2026-09-20 21:44:17.960217
431	intereses.csv	OMITIDO	123,Alice Brown,8000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	317	2026-09-20 21:44:17.966266
433	intereses.csv	OMITIDO	144,Charlie Green,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	319	2026-09-20 21:44:17.968995
435	intereses.csv	OMITIDO	136,Steve Rogers,12000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	321	2026-09-20 21:44:17.970919
437	intereses.csv	OMITIDO	105,John Doe,10000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	322	2026-09-20 21:44:17.9768
438	intereses.csv	OMITIDO	147,John Doe,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	324	2026-09-20 21:44:17.978442
440	intereses.csv	OMITIDO	145,Bob Johnson,,35,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	325	2026-09-20 21:44:17.980991
442	intereses.csv	OMITIDO	138,Charlie Green,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	326	2026-09-20 21:44:17.983013
444	intereses.csv	OMITIDO	123,Charlie Green,5000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	328	2026-09-20 21:44:17.989564
446	intereses.csv	OMITIDO	146,Bob Johnson,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	330	2026-09-20 21:44:17.991557
449	intereses.csv	OMITIDO	105,Diana Prince,7000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	336	2026-09-20 21:44:17.996528
452	intereses.csv	OMITIDO	128,Steve Rogers,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	337	2026-09-20 21:44:17.999901
453	intereses.csv	OMITIDO	113,Unknown,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	338	2026-09-20 21:44:18.002468
455	intereses.csv	OMITIDO	106,Charlie Green,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	339	2026-09-20 21:44:18.004207
457	intereses.csv	OMITIDO	116,Diana Prince,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	340	2026-09-20 21:44:18.005935
458	intereses.csv	OMITIDO	140,John Doe,,30,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	341	2026-09-20 21:44:18.007742
462	intereses.csv	OMITIDO	110,Alice Brown,7000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	343	2026-09-20 21:44:18.014019
463	intereses.csv	OMITIDO	115,Diana Prince,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	344	2026-09-20 21:44:18.015312
464	intereses.csv	OMITIDO	138,Charlie Green,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	345	2026-09-20 21:44:18.016739
466	intereses.csv	OMITIDO	150,Diana Prince,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	346	2026-09-20 21:44:18.018165
469	intereses.csv	OMITIDO	101,Steve Rogers,5000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	347	2026-09-20 21:44:18.021128
471	intereses.csv	OMITIDO	105,Alice Brown,,25,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	348	2026-09-20 21:44:18.022608
472	intereses.csv	OMITIDO	150,Steve Rogers,,25,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	349	2026-09-20 21:44:18.023584
474	intereses.csv	OMITIDO	137,Charlie Green,7000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	350	2026-09-20 21:44:18.025084
476	intereses.csv	OMITIDO	124,John Doe,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	351	2026-09-20 21:44:18.026454
479	intereses.csv	OMITIDO	132,John Doe,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	352	2026-09-20 21:44:18.029879
481	intereses.csv	OMITIDO	113,Alice Brown,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	353	2026-09-20 21:44:18.031515
484	intereses.csv	OMITIDO	119,Steve Rogers,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	354	2026-09-20 21:44:18.033566
486	intereses.csv	OMITIDO	113,Charlie Green,7000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	355	2026-09-20 21:44:18.035566
487	intereses.csv	OMITIDO	146,Charlie Green,8000,25,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	356	2026-09-20 21:44:18.038921
492	intereses.csv	OMITIDO	118,Jane Smith,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	359	2026-09-20 21:44:18.045294
493	intereses.csv	OMITIDO	144,Diana Prince,8000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	360	2026-09-20 21:44:18.0469
494	intereses.csv	OMITIDO	127,John Doe,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	361	2026-09-20 21:44:18.048592
439	transacciones.csv	OMITIDO	387,2024/07/10,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	388	2026-09-20 21:44:17.978873
441	transacciones.csv	OMITIDO	388,2024/09/14,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	389	2026-09-20 21:44:17.981461
443	transacciones.csv	OMITIDO	389,2024-11-19,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	390	2026-09-20 21:44:17.983468
445	transacciones.csv	OMITIDO	393,2024-13-01,800,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	394	2026-09-20 21:44:17.990414
448	transacciones.csv	OMITIDO	396,23-05-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	397	2026-09-20 21:44:17.996479
451	transacciones.csv	OMITIDO	398,2024-05-09,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	399	2026-09-20 21:44:17.997902
454	transacciones.csv	OMITIDO	402,2024/07/16,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	403	2026-09-20 21:44:18.002642
456	transacciones.csv	OMITIDO	404,2024-10-13,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	405	2026-09-20 21:44:18.004601
459	transacciones.csv	OMITIDO	406,24/03/2024,700,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	407	2026-09-20 21:44:18.01039
460	transacciones.csv	OMITIDO	407,2024-09-21,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	408	2026-09-20 21:44:18.011946
461	transacciones.csv	OMITIDO	410,23-11-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	411	2026-09-20 21:44:18.013345
465	transacciones.csv	OMITIDO	412,06-12-2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	413	2026-09-20 21:44:18.017598
467	transacciones.csv	OMITIDO	413,2024/10/21,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	414	2026-09-20 21:44:18.018575
468	transacciones.csv	OMITIDO	414,2024-08-07,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	415	2026-09-20 21:44:18.020223
470	transacciones.csv	OMITIDO	415,2024/06/29,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	416	2026-09-20 21:44:18.021375
473	transacciones.csv	OMITIDO	416,2024-11-17,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	417	2026-09-20 21:44:18.024706
475	transacciones.csv	OMITIDO	417,2024/06/19,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	418	2026-09-20 21:44:18.02561
477	transacciones.csv	OMITIDO	418,2024-12-28,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	419	2026-09-20 21:44:18.027037
482	transacciones.csv	OMITIDO	423,2024/08/28,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	424	2026-09-20 21:44:18.031517
485	transacciones.csv	OMITIDO	425,09/01/2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	426	2026-09-20 21:44:18.033974
489	transacciones.csv	OMITIDO	427,2024/12/27,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	428	2026-09-20 21:44:18.041023
490	transacciones.csv	OMITIDO	429,2024-09-27,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	430	2026-09-20 21:44:18.042932
491	transacciones.csv	OMITIDO	430,2024-05-07,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	431	2026-09-20 21:44:18.04479
495	transacciones.csv	OMITIDO	431,2024/05/04,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	432	2026-09-20 21:44:18.049393
496	transacciones.csv	OMITIDO	433,2024-11-18,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	434	2026-09-20 21:44:18.051425
499	transacciones.csv	OMITIDO	434,2024/05/03,1500,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	435	2026-09-20 21:44:18.05297
500	transacciones.csv	OMITIDO	435,2024/11/20,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	436	2026-09-20 21:44:18.054754
504	transacciones.csv	OMITIDO	437,2024/02/28,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	438	2026-09-20 21:44:18.060353
506	transacciones.csv	OMITIDO	438,2024-10-18,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	439	2026-09-20 21:44:18.062225
507	transacciones.csv	OMITIDO	440,28/07/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	441	2026-09-20 21:44:18.063651
512	transacciones.csv	OMITIDO	443,11/05/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	444	2026-09-20 21:44:18.068612
513	transacciones.csv	OMITIDO	444,2024-04-19,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	445	2026-09-20 21:44:18.070961
515	transacciones.csv	OMITIDO	445,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	446	2026-09-20 21:44:18.073001
518	transacciones.csv	OMITIDO	446,2024-07-11,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	447	2026-09-20 21:44:18.077668
520	transacciones.csv	OMITIDO	448,08-06-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	449	2026-09-20 21:44:18.079014
524	transacciones.csv	OMITIDO	451,02/07/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	452	2026-09-20 21:44:18.083649
526	transacciones.csv	OMITIDO	453,2024-13-01,800,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	454	2026-09-20 21:44:18.085572
528	transacciones.csv	OMITIDO	455,29/02/2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	456	2026-09-20 21:44:18.086862
530	transacciones.csv	OMITIDO	456,18-10-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	457	2026-09-20 21:44:18.090817
488	cuentas_anuales.csv	OMITIDO	118,20/05/2024,retiro,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	856	2026-09-20 21:44:18.04009
497	cuentas_anuales.csv	OMITIDO	101,01-09-2024,compra,,	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	867	2026-09-20 21:44:18.052118
505	cuentas_anuales.csv	OMITIDO	101,27-05-2024,deposito,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	878	2026-09-20 21:44:18.060511
508	cuentas_anuales.csv	OMITIDO	102,29/11/2024,compra,,Compra en tienda	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	886	2026-09-20 21:44:18.064349
517	cuentas_anuales.csv	OMITIDO	116,18/12/2024,deposito,,Ingreso navideño	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	901	2026-09-20 21:44:18.076724
525	cuentas_anuales.csv	OMITIDO	107,06/04/2024,retiro,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	909	2026-09-20 21:44:18.084169
540	cuentas_anuales.csv	OMITIDO	117,19-04-2024,retiro,,Retiro parcial	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	940	2026-09-20 21:44:18.102117
556	cuentas_anuales.csv	OMITIDO	111,07-03-2024,deposito,,Ingreso mensual	1	estadosCuentaAnualesJob	Monto vacio o no numerico: '' [hilo=batch-flujo-2]	966	2026-09-20 21:44:18.119809
498	intereses.csv	FILTRADO	120,John Doe,,,-1	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	362	2026-09-20 21:44:18.052731
501	intereses.csv	OMITIDO	114,Jane Smith,12000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	364	2026-09-20 21:44:18.0554
502	intereses.csv	OMITIDO	139,Charlie Green,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	365	2026-09-20 21:44:18.057227
503	intereses.csv	OMITIDO	132,Alice Brown,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	366	2026-09-20 21:44:18.059211
509	intereses.csv	OMITIDO	107,Bob Johnson,8000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	369	2026-09-20 21:44:18.064354
510	intereses.csv	OMITIDO	118,Charlie Green,5000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	370	2026-09-20 21:44:18.065482
511	intereses.csv	OMITIDO	149,Steve Rogers,,150,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	371	2026-09-20 21:44:18.066379
514	intereses.csv	OMITIDO	128,Diana Prince,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	373	2026-09-20 21:44:18.072947
516	intereses.csv	OMITIDO	127,Charlie Green,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	375	2026-09-20 21:44:18.07475
519	intereses.csv	OMITIDO	120,Jane Smith,5000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	377	2026-09-20 21:44:18.078815
521	intereses.csv	OMITIDO	146,John Doe,,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	378	2026-09-20 21:44:18.080315
522	intereses.csv	OMITIDO	132,Bob Johnson,8000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	379	2026-09-20 21:44:18.081953
523	intereses.csv	OMITIDO	112,Jane Smith,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	380	2026-09-20 21:44:18.083503
527	intereses.csv	OMITIDO	129,Steve Rogers,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	381	2026-09-20 21:44:18.085805
529	intereses.csv	OMITIDO	136,Bob Johnson,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	382	2026-09-20 21:44:18.09013
531	intereses.csv	OMITIDO	134,Diana Prince,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	383	2026-09-20 21:44:18.091432
533	intereses.csv	OMITIDO	105,Jane Smith,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	384	2026-09-20 21:44:18.092948
534	intereses.csv	OMITIDO	112,Bob Johnson,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	385	2026-09-20 21:44:18.094187
537	intereses.csv	FILTRADO	147,John Doe,,30,ahorro	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	390	2026-09-20 21:44:18.097581
538	intereses.csv	OMITIDO	111,Steve Rogers,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	387	2026-09-20 21:44:18.100699
543	intereses.csv	OMITIDO	120,Bob Johnson,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	392	2026-09-20 21:44:18.105637
544	intereses.csv	OMITIDO	133,John Doe,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	393	2026-09-20 21:44:18.107247
545	intereses.csv	OMITIDO	114,Steve Rogers,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	395	2026-09-20 21:44:18.108688
547	intereses.csv	OMITIDO	132,Diana Prince,7000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	396	2026-09-20 21:44:18.110114
551	intereses.csv	OMITIDO	147,Unknown,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	397	2026-09-20 21:44:18.114159
553	intereses.csv	OMITIDO	104,Steve Rogers,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	398	2026-09-20 21:44:18.115381
554	intereses.csv	OMITIDO	108,Alice Brown,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	399	2026-09-20 21:44:18.116606
555	intereses.csv	OMITIDO	126,Unknown,12000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	400	2026-09-20 21:44:18.118137
559	intereses.csv	OMITIDO	110,John Doe,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	402	2026-09-20 21:44:18.122127
560	intereses.csv	OMITIDO	116,Steve Rogers,7000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	403	2026-09-20 21:44:18.123238
561	intereses.csv	OMITIDO	107,John Doe,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	404	2026-09-20 21:44:18.124804
564	intereses.csv	OMITIDO	134,Diana Prince,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	407	2026-09-20 21:44:18.129639
565	intereses.csv	OMITIDO	103,John Doe,,45,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	410	2026-09-20 21:44:18.130903
566	intereses.csv	OMITIDO	117,Alice Brown,10000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	411	2026-09-20 21:44:18.132285
569	intereses.csv	OMITIDO	106,Diana Prince,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	412	2026-09-20 21:44:18.135142
571	intereses.csv	OMITIDO	128,Jane Smith,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	413	2026-09-20 21:44:18.136389
572	intereses.csv	OMITIDO	103,Jane Smith,7000,25,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	414	2026-09-20 21:44:18.137858
573	intereses.csv	OMITIDO	120,Jane Smith,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	415	2026-09-20 21:44:18.139619
575	intereses.csv	OMITIDO	109,Alice Brown,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	416	2026-09-20 21:44:18.141179
532	transacciones.csv	OMITIDO	460,21-08-2024,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	461	2026-09-20 21:44:18.092144
535	transacciones.csv	OMITIDO	461,2024-13-01,700,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	462	2026-09-20 21:44:18.095281
536	transacciones.csv	OMITIDO	462,2024-13-01,1500,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	463	2026-09-20 21:44:18.096817
539	transacciones.csv	OMITIDO	466,2024/11/30,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	467	2026-09-20 21:44:18.101863
541	transacciones.csv	OMITIDO	469,2024/12/03,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	470	2026-09-20 21:44:18.10369
542	transacciones.csv	OMITIDO	470,2024/09/19,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	471	2026-09-20 21:44:18.105249
546	transacciones.csv	OMITIDO	471,04/12/2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	472	2026-09-20 21:44:18.108969
548	transacciones.csv	OMITIDO	472,2024-13-01,,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	473	2026-09-20 21:44:18.110751
549	transacciones.csv	OMITIDO	473,15/08/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	474	2026-09-20 21:44:18.11212
550	transacciones.csv	OMITIDO	474,2024-13-01,1200,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	475	2026-09-20 21:44:18.113594
552	transacciones.csv	OMITIDO	475,2024/12/28,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	476	2026-09-20 21:44:18.114841
557	transacciones.csv	OMITIDO	476,2024/07/06,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	477	2026-09-20 21:44:18.119939
558	transacciones.csv	OMITIDO	479,07-12-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	480	2026-09-20 21:44:18.121364
562	transacciones.csv	OMITIDO	482,2024-02-04,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	483	2026-09-20 21:44:18.126328
563	transacciones.csv	OMITIDO	485,17-11-2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	486	2026-09-20 21:44:18.12835
567	transacciones.csv	OMITIDO	486,17-09-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	487	2026-09-20 21:44:18.132718
568	transacciones.csv	OMITIDO	488,11/12/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	489	2026-09-20 21:44:18.134291
570	transacciones.csv	OMITIDO	490,26/07/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	491	2026-09-20 21:44:18.135479
574	transacciones.csv	OMITIDO	491,2024/03/31,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	492	2026-09-20 21:44:18.140364
576	transacciones.csv	OMITIDO	492,2024/11/07,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	493	2026-09-20 21:44:18.141826
577	transacciones.csv	OMITIDO	493,2024-08-29,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	494	2026-09-20 21:44:18.142743
579	transacciones.csv	OMITIDO	496,2024/09/14,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	497	2026-09-20 21:44:18.146605
581	transacciones.csv	OMITIDO	497,2024/04/20,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	498	2026-09-20 21:44:18.148448
583	transacciones.csv	OMITIDO	498,2024-13-01,1500,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	499	2026-09-20 21:44:18.149843
584	transacciones.csv	OMITIDO	500,2024/04/24,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	501	2026-09-20 21:44:18.151084
587	transacciones.csv	OMITIDO	501,2024-03-24,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	502	2026-09-20 21:44:18.156011
589	transacciones.csv	OMITIDO	503,14-02-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	504	2026-09-20 21:44:18.15731
592	transacciones.csv	OMITIDO	506,2024-06-10,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	507	2026-09-20 21:44:18.161955
593	transacciones.csv	OMITIDO	507,05-04-2024,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	508	2026-09-20 21:44:18.16387
596	transacciones.csv	OMITIDO	511,22/02/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	512	2026-09-20 21:44:18.169433
598	transacciones.csv	OMITIDO	513,2024/01/10,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	514	2026-09-20 21:44:18.170488
600	transacciones.csv	OMITIDO	514,20/10/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	515	2026-09-20 21:44:18.171399
603	transacciones.csv	OMITIDO	516,21/08/2024,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	517	2026-09-20 21:44:18.17563
605	transacciones.csv	OMITIDO	517,17/04/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	518	2026-09-20 21:44:18.17708
607	transacciones.csv	OMITIDO	518,02/03/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	519	2026-09-20 21:44:18.17796
609	transacciones.csv	OMITIDO	519,24-08-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	520	2026-09-20 21:44:18.17887
611	transacciones.csv	OMITIDO	522,2024-06-12,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	523	2026-09-20 21:44:18.182298
613	transacciones.csv	OMITIDO	523,2024/02/03,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	524	2026-09-20 21:44:18.18345
729	intereses.csv	OMITIDO	110,Steve Rogers,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	541	2026-09-20 21:44:18.309043
578	intereses.csv	OMITIDO	135,Charlie Green,12000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	417	2026-09-20 21:44:18.145293
580	intereses.csv	OMITIDO	129,Diana Prince,,30,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	418	2026-09-20 21:44:18.147224
582	intereses.csv	OMITIDO	130,John Doe,,40,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	419	2026-09-20 21:44:18.149123
585	intereses.csv	OMITIDO	144,Steve Rogers,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	422	2026-09-20 21:44:18.153439
586	intereses.csv	OMITIDO	120,Jane Smith,,25,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	423	2026-09-20 21:44:18.154939
588	intereses.csv	OMITIDO	102,Jane Smith,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	425	2026-09-20 21:44:18.156217
590	intereses.csv	OMITIDO	145,Alice Brown,,100,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	426	2026-09-20 21:44:18.157536
591	intereses.csv	OMITIDO	137,Jane Smith,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	431	2026-09-20 21:44:18.161892
594	intereses.csv	OMITIDO	130,Alice Brown,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	432	2026-09-20 21:44:18.166649
595	intereses.csv	OMITIDO	116,Alice Brown,12000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	433	2026-09-20 21:44:18.168125
597	intereses.csv	OMITIDO	126,Bob Johnson,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	435	2026-09-20 21:44:18.169831
599	intereses.csv	OMITIDO	129,Jane Smith,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	436	2026-09-20 21:44:18.170757
601	intereses.csv	FILTRADO	110,Alice Brown,7000,,-1	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	440	2026-09-20 21:44:18.173715
602	intereses.csv	OMITIDO	138,Unknown,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	437	2026-09-20 21:44:18.175101
604	intereses.csv	OMITIDO	148,Unknown,5000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	438	2026-09-20 21:44:18.176813
606	intereses.csv	OMITIDO	124,Steve Rogers,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	439	2026-09-20 21:44:18.17764
608	intereses.csv	OMITIDO	139,Jane Smith,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	441	2026-09-20 21:44:18.178533
610	intereses.csv	OMITIDO	107,Alice Brown,7000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	442	2026-09-20 21:44:18.181725
612	intereses.csv	OMITIDO	142,Steve Rogers,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	443	2026-09-20 21:44:18.183125
614	intereses.csv	OMITIDO	113,John Doe,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	444	2026-09-20 21:44:18.183985
616	intereses.csv	OMITIDO	107,Alice Brown,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	445	2026-09-20 21:44:18.184837
618	intereses.csv	OMITIDO	140,Charlie Green,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	446	2026-09-20 21:44:18.185637
620	intereses.csv	OMITIDO	113,Alice Brown,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	447	2026-09-20 21:44:18.189979
622	intereses.csv	OMITIDO	114,Bob Johnson,7000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	448	2026-09-20 21:44:18.190975
624	intereses.csv	OMITIDO	102,Bob Johnson,5000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	449	2026-09-20 21:44:18.192035
625	intereses.csv	OMITIDO	143,Charlie Green,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	451	2026-09-20 21:44:18.193004
628	intereses.csv	OMITIDO	103,Jane Smith,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	452	2026-09-20 21:44:18.197189
629	intereses.csv	OMITIDO	107,Alice Brown,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	453	2026-09-20 21:44:18.198112
630	intereses.csv	OMITIDO	107,Bob Johnson,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	455	2026-09-20 21:44:18.198977
632	intereses.csv	OMITIDO	142,Steve Rogers,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	456	2026-09-20 21:44:18.200291
634	intereses.csv	OMITIDO	148,Charlie Green,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	457	2026-09-20 21:44:18.204839
636	intereses.csv	OMITIDO	144,Bob Johnson,10000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	458	2026-09-20 21:44:18.206022
637	intereses.csv	OMITIDO	114,Steve Rogers,10000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	460	2026-09-20 21:44:18.207034
638	intereses.csv	OMITIDO	103,Jane Smith,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	461	2026-09-20 21:44:18.208386
640	intereses.csv	OMITIDO	150,Diana Prince,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	462	2026-09-20 21:44:18.211995
642	intereses.csv	OMITIDO	125,John Doe,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	463	2026-09-20 21:44:18.213034
644	intereses.csv	OMITIDO	150,Jane Smith,8000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	464	2026-09-20 21:44:18.215059
645	intereses.csv	OMITIDO	123,John Doe,5000,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	465	2026-09-20 21:44:18.216864
649	intereses.csv	OMITIDO	138,Bob Johnson,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	467	2026-09-20 21:44:18.221785
650	intereses.csv	OMITIDO	137,Jane Smith,7000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	471	2026-09-20 21:44:18.223289
615	transacciones.csv	OMITIDO	524,2024-11-12,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	525	2026-09-20 21:44:18.184218
617	transacciones.csv	OMITIDO	525,2024-13-01,700,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	526	2026-09-20 21:44:18.185111
619	transacciones.csv	OMITIDO	526,26/03/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	527	2026-09-20 21:44:18.188835
621	transacciones.csv	OMITIDO	528,13/06/2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	529	2026-09-20 21:44:18.19011
623	transacciones.csv	OMITIDO	530,2024/07/10,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	531	2026-09-20 21:44:18.19127
626	transacciones.csv	OMITIDO	534,2024-05-15,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	535	2026-09-20 21:44:18.194915
627	transacciones.csv	OMITIDO	535,19-10-2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	536	2026-09-20 21:44:18.196343
631	transacciones.csv	OMITIDO	537,2024/08/25,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	538	2026-09-20 21:44:18.199354
633	transacciones.csv	OMITIDO	542,07/01/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	543	2026-09-20 21:44:18.2034
635	transacciones.csv	OMITIDO	543,2024-13-01,1500,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	544	2026-09-20 21:44:18.205412
639	transacciones.csv	OMITIDO	549,05/11/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	550	2026-09-20 21:44:18.209083
641	transacciones.csv	OMITIDO	551,11-03-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	552	2026-09-20 21:44:18.212435
643	transacciones.csv	OMITIDO	552,2024-06-01,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	553	2026-09-20 21:44:18.21371
646	transacciones.csv	OMITIDO	557,06/09/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	558	2026-09-20 21:44:18.219087
647	transacciones.csv	OMITIDO	558,2024-10-21,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	559	2026-09-20 21:44:18.220383
648	transacciones.csv	OMITIDO	559,2024-12-26,-200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	560	2026-09-20 21:44:18.221785
651	transacciones.csv	OMITIDO	560,2024-13-01,-200,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	561	2026-09-20 21:44:18.223575
652	transacciones.csv	OMITIDO	561,2024-01-05,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	562	2026-09-20 21:44:18.227634
654	transacciones.csv	OMITIDO	565,2024/11/11,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	566	2026-09-20 21:44:18.229154
658	transacciones.csv	OMITIDO	569,05-06-2024,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	570	2026-09-20 21:44:18.233485
659	transacciones.csv	OMITIDO	570,2024-03-20,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	571	2026-09-20 21:44:18.235053
665	transacciones.csv	OMITIDO	576,11/04/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	577	2026-09-20 21:44:18.242384
666	transacciones.csv	OMITIDO	578,05-12-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	579	2026-09-20 21:44:18.24338
667	transacciones.csv	OMITIDO	579,2024-05-01,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	580	2026-09-20 21:44:18.244935
669	transacciones.csv	OMITIDO	580,2024/11/28,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	581	2026-09-20 21:44:18.245961
673	transacciones.csv	OMITIDO	582,20/03/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	583	2026-09-20 21:44:18.249463
675	transacciones.csv	OMITIDO	583,22-02-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	584	2026-09-20 21:44:18.25065
676	transacciones.csv	OMITIDO	584,09/01/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	585	2026-09-20 21:44:18.251952
680	transacciones.csv	OMITIDO	594,2024-12-17,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	595	2026-09-20 21:44:18.256879
681	transacciones.csv	OMITIDO	595,2024-13-01,1000,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	596	2026-09-20 21:44:18.258027
685	transacciones.csv	OMITIDO	596,2024-09-27,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	597	2026-09-20 21:44:18.261793
687	transacciones.csv	OMITIDO	598,06-04-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	599	2026-09-20 21:44:18.26339
689	transacciones.csv	OMITIDO	599,2024-13-01,700,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	600	2026-09-20 21:44:18.264375
690	transacciones.csv	OMITIDO	600,09/02/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	601	2026-09-20 21:44:18.265732
693	transacciones.csv	OMITIDO	601,2024-11-16,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	602	2026-09-20 21:44:18.269366
694	transacciones.csv	OMITIDO	603,2024-13-01,-200,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	604	2026-09-20 21:44:18.270663
695	transacciones.csv	OMITIDO	605,2024/07/30,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	606	2026-09-20 21:44:18.271887
699	transacciones.csv	OMITIDO	606,16-05-2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	607	2026-09-20 21:44:18.275738
653	intereses.csv	OMITIDO	103,Diana Prince,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	472	2026-09-20 21:44:18.227634
655	intereses.csv	OMITIDO	145,Steve Rogers,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	474	2026-09-20 21:44:18.22944
656	intereses.csv	OMITIDO	138,John Doe,10000,25,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	475	2026-09-20 21:44:18.231207
657	intereses.csv	OMITIDO	117,Diana Prince,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	476	2026-09-20 21:44:18.232367
660	intereses.csv	FILTRADO	108,John Doe,8000,45,prestamo	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	480	2026-09-20 21:44:18.236173
661	intereses.csv	OMITIDO	131,Bob Johnson,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	477	2026-09-20 21:44:18.23824
662	intereses.csv	OMITIDO	132,Unknown,12000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	478	2026-09-20 21:44:18.239247
663	intereses.csv	OMITIDO	146,Bob Johnson,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	479	2026-09-20 21:44:18.240425
664	intereses.csv	OMITIDO	112,Jane Smith,5000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	481	2026-09-20 21:44:18.241719
668	intereses.csv	OMITIDO	119,Steve Rogers,5000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	482	2026-09-20 21:44:18.245478
670	intereses.csv	OMITIDO	137,Alice Brown,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	483	2026-09-20 21:44:18.246402
671	intereses.csv	OMITIDO	127,Charlie Green,7000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	484	2026-09-20 21:44:18.247388
672	intereses.csv	OMITIDO	109,Unknown,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	485	2026-09-20 21:44:18.248623
674	intereses.csv	OMITIDO	118,John Doe,,40,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	486	2026-09-20 21:44:18.249883
677	intereses.csv	OMITIDO	121,John Doe,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	487	2026-09-20 21:44:18.253881
678	intereses.csv	OMITIDO	119,John Doe,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	489	2026-09-20 21:44:18.254815
679	intereses.csv	OMITIDO	122,Diana Prince,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	491	2026-09-20 21:44:18.256083
682	intereses.csv	OMITIDO	113,John Doe,12000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	492	2026-09-20 21:44:18.259405
683	intereses.csv	OMITIDO	131,Bob Johnson,7000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	493	2026-09-20 21:44:18.26054
684	intereses.csv	OMITIDO	111,Steve Rogers,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	494	2026-09-20 21:44:18.261442
686	intereses.csv	OMITIDO	114,Diana Prince,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	495	2026-09-20 21:44:18.262742
688	intereses.csv	OMITIDO	139,Charlie Green,5000,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	496	2026-09-20 21:44:18.264018
691	intereses.csv	OMITIDO	103,John Doe,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	499	2026-09-20 21:44:18.268248
692	intereses.csv	OMITIDO	108,Alice Brown,5000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	500	2026-09-20 21:44:18.269346
696	intereses.csv	OMITIDO	143,Charlie Green,10000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	504	2026-09-20 21:44:18.272808
697	intereses.csv	OMITIDO	137,Bob Johnson,5000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	505	2026-09-20 21:44:18.273792
698	intereses.csv	OMITIDO	124,John Doe,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	506	2026-09-20 21:44:18.274538
702	intereses.csv	OMITIDO	128,Diana Prince,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	512	2026-09-20 21:44:18.281244
704	intereses.csv	OMITIDO	133,Alice Brown,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	513	2026-09-20 21:44:18.282708
706	intereses.csv	OMITIDO	143,Diana Prince,,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	517	2026-09-20 21:44:18.28615
709	intereses.csv	OMITIDO	116,Diana Prince,,30,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	518	2026-09-20 21:44:18.287844
710	intereses.csv	OMITIDO	107,Alice Brown,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	521	2026-09-20 21:44:18.288871
713	intereses.csv	OMITIDO	111,John Doe,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	525	2026-09-20 21:44:18.292394
714	intereses.csv	OMITIDO	121,Steve Rogers,12000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	526	2026-09-20 21:44:18.293837
717	intereses.csv	OMITIDO	116,Bob Johnson,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	528	2026-09-20 21:44:18.29677
719	intereses.csv	OMITIDO	133,John Doe,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	530	2026-09-20 21:44:18.297907
721	intereses.csv	OMITIDO	127,Diana Prince,7000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	533	2026-09-20 21:44:18.301633
723	intereses.csv	OMITIDO	115,Jane Smith,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	535	2026-09-20 21:44:18.302764
725	intereses.csv	OMITIDO	109,Diana Prince,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	537	2026-09-20 21:44:18.306292
727	intereses.csv	OMITIDO	135,John Doe,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	539	2026-09-20 21:44:18.307889
700	transacciones.csv	OMITIDO	610,2024-13-01,,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	611	2026-09-20 21:44:18.277039
701	transacciones.csv	OMITIDO	611,2024-11-24,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	612	2026-09-20 21:44:18.281161
703	transacciones.csv	OMITIDO	614,2024-01-05,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	615	2026-09-20 21:44:18.282345
705	transacciones.csv	OMITIDO	615,2024-11-25,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	616	2026-09-20 21:44:18.283341
707	transacciones.csv	OMITIDO	616,2024-08-03,500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	617	2026-09-20 21:44:18.286241
708	transacciones.csv	OMITIDO	617,17/09/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	618	2026-09-20 21:44:18.287621
711	transacciones.csv	OMITIDO	622,2024-07-08,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	623	2026-09-20 21:44:18.290674
712	transacciones.csv	OMITIDO	625,2024-05-15,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	626	2026-09-20 21:44:18.291752
715	transacciones.csv	OMITIDO	626,2024/04/12,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	627	2026-09-20 21:44:18.29528
716	transacciones.csv	OMITIDO	628,28-06-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	629	2026-09-20 21:44:18.29607
718	transacciones.csv	OMITIDO	629,26/12/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	630	2026-09-20 21:44:18.29755
720	transacciones.csv	OMITIDO	630,20/10/2024,1500,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	631	2026-09-20 21:44:18.298631
722	transacciones.csv	OMITIDO	632,2024/02/11,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	633	2026-09-20 21:44:18.302154
724	transacciones.csv	OMITIDO	635,2024-13-01,1500,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	636	2026-09-20 21:44:18.303189
726	transacciones.csv	OMITIDO	637,2024-07-01,700,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	638	2026-09-20 21:44:18.306433
728	transacciones.csv	OMITIDO	638,20-11-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	639	2026-09-20 21:44:18.308059
730	transacciones.csv	OMITIDO	643,27-06-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	644	2026-09-20 21:44:18.311539
732	transacciones.csv	OMITIDO	644,18/05/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	645	2026-09-20 21:44:18.312764
734	transacciones.csv	OMITIDO	645,26/08/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	646	2026-09-20 21:44:18.31376
738	transacciones.csv	OMITIDO	648,2024-02-21,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	649	2026-09-20 21:44:18.318385
739	transacciones.csv	OMITIDO	651,2024-13-01,,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	652	2026-09-20 21:44:18.322035
743	transacciones.csv	OMITIDO	657,30-04-2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	658	2026-09-20 21:44:18.325362
744	transacciones.csv	OMITIDO	658,14-10-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	659	2026-09-20 21:44:18.326495
745	transacciones.csv	OMITIDO	660,2024-07-17,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	661	2026-09-20 21:44:18.32764
749	transacciones.csv	OMITIDO	663,25-02-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	664	2026-09-20 21:44:18.330787
751	transacciones.csv	OMITIDO	664,2024-02-17,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	665	2026-09-20 21:44:18.331672
752	transacciones.csv	OMITIDO	665,2024-04-13,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	666	2026-09-20 21:44:18.332869
755	transacciones.csv	OMITIDO	666,2024/04/25,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	667	2026-09-20 21:44:18.337164
757	transacciones.csv	OMITIDO	668,2024-02-21,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	669	2026-09-20 21:44:18.338088
759	transacciones.csv	OMITIDO	671,17-05-2024,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	672	2026-09-20 21:44:18.341273
762	transacciones.csv	OMITIDO	672,2024-13-01,-200,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	673	2026-09-20 21:44:18.342871
763	transacciones.csv	OMITIDO	674,08/10/2024,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	675	2026-09-20 21:44:18.343789
764	transacciones.csv	OMITIDO	675,10/11/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	676	2026-09-20 21:44:18.344914
768	transacciones.csv	OMITIDO	676,07-08-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	677	2026-09-20 21:44:18.348029
769	transacciones.csv	OMITIDO	677,2024/09/02,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	678	2026-09-20 21:44:18.349324
770	transacciones.csv	OMITIDO	678,26-08-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	679	2026-09-20 21:44:18.350349
771	transacciones.csv	OMITIDO	679,19-04-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	680	2026-09-20 21:44:18.351237
773	transacciones.csv	OMITIDO	680,2024-13-01,1500,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	681	2026-09-20 21:44:18.352387
777	transacciones.csv	OMITIDO	681,2024-13-01,1000,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	682	2026-09-20 21:44:18.355794
731	intereses.csv	OMITIDO	112,Jane Smith,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	542	2026-09-20 21:44:18.311796
733	intereses.csv	OMITIDO	132,Bob Johnson,10000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	543	2026-09-20 21:44:18.313045
735	intereses.csv	OMITIDO	104,Jane Smith,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	544	2026-09-20 21:44:18.314147
736	intereses.csv	OMITIDO	120,Steve Rogers,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	545	2026-09-20 21:44:18.315858
737	intereses.csv	OMITIDO	126,Alice Brown,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	546	2026-09-20 21:44:18.317745
740	intereses.csv	OMITIDO	124,Steve Rogers,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	547	2026-09-20 21:44:18.322217
741	intereses.csv	OMITIDO	127,Charlie Green,5000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	548	2026-09-20 21:44:18.32307
742	intereses.csv	OMITIDO	131,Jane Smith,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	550	2026-09-20 21:44:18.323846
746	intereses.csv	OMITIDO	134,John Doe,8000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	552	2026-09-20 21:44:18.328061
747	intereses.csv	OMITIDO	114,Steve Rogers,,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	553	2026-09-20 21:44:18.32922
748	intereses.csv	OMITIDO	111,Bob Johnson,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	554	2026-09-20 21:44:18.33024
750	intereses.csv	OMITIDO	133,John Doe,10000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	556	2026-09-20 21:44:18.331148
753	intereses.csv	OMITIDO	147,Charlie Green,10000,150,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	557	2026-09-20 21:44:18.334451
754	intereses.csv	OMITIDO	104,Diana Prince,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	559	2026-09-20 21:44:18.33619
756	intereses.csv	OMITIDO	115,Diana Prince,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	560	2026-09-20 21:44:18.337241
758	intereses.csv	OMITIDO	144,Bob Johnson,12000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	561	2026-09-20 21:44:18.338442
760	intereses.csv	OMITIDO	134,Charlie Green,12000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	563	2026-09-20 21:44:18.341408
761	intereses.csv	OMITIDO	114,Steve Rogers,7000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	565	2026-09-20 21:44:18.342626
765	intereses.csv	OMITIDO	117,Alice Brown,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	568	2026-09-20 21:44:18.345543
766	intereses.csv	OMITIDO	131,Charlie Green,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	569	2026-09-20 21:44:18.34666
767	intereses.csv	OMITIDO	109,Jane Smith,5000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	571	2026-09-20 21:44:18.347831
772	intereses.csv	OMITIDO	126,Alice Brown,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	572	2026-09-20 21:44:18.351545
774	intereses.csv	OMITIDO	114,Diana Prince,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	574	2026-09-20 21:44:18.352764
775	intereses.csv	OMITIDO	139,Steve Rogers,,,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	575	2026-09-20 21:44:18.35429
776	intereses.csv	OMITIDO	149,Bob Johnson,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	576	2026-09-20 21:44:18.355236
780	intereses.csv	OMITIDO	119,Steve Rogers,5000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	577	2026-09-20 21:44:18.358218
781	intereses.csv	OMITIDO	104,Steve Rogers,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	578	2026-09-20 21:44:18.359476
782	intereses.csv	OMITIDO	128,John Doe,8000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	579	2026-09-20 21:44:18.360361
785	intereses.csv	OMITIDO	116,John Doe,12000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	582	2026-09-20 21:44:18.363672
787	intereses.csv	OMITIDO	133,Steve Rogers,,150,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	583	2026-09-20 21:44:18.364462
788	intereses.csv	OMITIDO	135,Bob Johnson,7000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	584	2026-09-20 21:44:18.365123
789	intereses.csv	OMITIDO	142,Jane Smith,8000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	585	2026-09-20 21:44:18.366178
793	intereses.csv	OMITIDO	118,Charlie Green,12000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	587	2026-09-20 21:44:18.370355
794	intereses.csv	OMITIDO	134,Alice Brown,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	588	2026-09-20 21:44:18.371231
795	intereses.csv	OMITIDO	120,Charlie Green,7000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	589	2026-09-20 21:44:18.372216
797	intereses.csv	OMITIDO	132,Alice Brown,12000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	590	2026-09-20 21:44:18.373421
801	intereses.csv	OMITIDO	143,Alice Brown,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	592	2026-09-20 21:44:18.377382
802	intereses.csv	OMITIDO	104,Steve Rogers,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	593	2026-09-20 21:44:18.378377
804	intereses.csv	OMITIDO	141,Jane Smith,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	594	2026-09-20 21:44:18.379488
778	transacciones.csv	OMITIDO	684,2024/11/04,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	685	2026-09-20 21:44:18.357131
779	transacciones.csv	OMITIDO	685,2024-12-20,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	686	2026-09-20 21:44:18.358035
783	transacciones.csv	OMITIDO	686,2024/11/01,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	687	2026-09-20 21:44:18.361584
784	transacciones.csv	OMITIDO	687,12-12-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	688	2026-09-20 21:44:18.362998
786	transacciones.csv	OMITIDO	688,2024/08/17,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	689	2026-09-20 21:44:18.36409
790	transacciones.csv	OMITIDO	692,15-09-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	693	2026-09-20 21:44:18.36663
791	transacciones.csv	OMITIDO	693,2024/02/13,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	694	2026-09-20 21:44:18.367918
792	transacciones.csv	OMITIDO	695,2024/10/20,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	696	2026-09-20 21:44:18.369676
796	transacciones.csv	OMITIDO	696,11-05-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	697	2026-09-20 21:44:18.372693
798	transacciones.csv	OMITIDO	697,2024-02-01,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	698	2026-09-20 21:44:18.373685
799	transacciones.csv	OMITIDO	698,29-09-2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	699	2026-09-20 21:44:18.374815
800	transacciones.csv	OMITIDO	699,2024-12-10,800,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	700	2026-09-20 21:44:18.375854
803	transacciones.csv	OMITIDO	701,01/02/2024,3000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	702	2026-09-20 21:44:18.378875
805	transacciones.csv	OMITIDO	702,2024-13-01,,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	703	2026-09-20 21:44:18.379741
807	transacciones.csv	OMITIDO	703,2024-05-05,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	704	2026-09-20 21:44:18.380741
808	transacciones.csv	OMITIDO	704,2024-02-19,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	705	2026-09-20 21:44:18.38169
810	transacciones.csv	OMITIDO	709,01/05/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	710	2026-09-20 21:44:18.385426
814	transacciones.csv	OMITIDO	711,2024/12/06,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	712	2026-09-20 21:44:18.387615
815	transacciones.csv	OMITIDO	712,2024/09/11,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	713	2026-09-20 21:44:18.388674
816	transacciones.csv	OMITIDO	713,2024/07/12,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	714	2026-09-20 21:44:18.389602
817	transacciones.csv	OMITIDO	714,21/06/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	715	2026-09-20 21:44:18.390601
819	transacciones.csv	OMITIDO	715,2024/07/07,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	716	2026-09-20 21:44:18.391625
822	transacciones.csv	OMITIDO	716,2024-13-01,-200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	717	2026-09-20 21:44:18.394686
823	transacciones.csv	OMITIDO	717,2024/03/22,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	718	2026-09-20 21:44:18.3962
824	transacciones.csv	OMITIDO	718,2024/08/25,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	719	2026-09-20 21:44:18.39816
827	transacciones.csv	OMITIDO	719,2024/09/04,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	720	2026-09-20 21:44:18.399898
829	transacciones.csv	OMITIDO	720,27-11-2024,1500,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	721	2026-09-20 21:44:18.401229
831	transacciones.csv	OMITIDO	721,2024-05-25,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	722	2026-09-20 21:44:18.40653
833	transacciones.csv	OMITIDO	722,2024-13-01,1200,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	723	2026-09-20 21:44:18.407965
835	transacciones.csv	OMITIDO	724,2024-13-01,1200,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	725	2026-09-20 21:44:18.409884
836	transacciones.csv	OMITIDO	725,06/02/2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	726	2026-09-20 21:44:18.411918
839	transacciones.csv	OMITIDO	728,09/12/2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	729	2026-09-20 21:44:18.419141
842	transacciones.csv	OMITIDO	731,2024/09/04,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	732	2026-09-20 21:44:18.423779
843	transacciones.csv	OMITIDO	733,18-03-2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	734	2026-09-20 21:44:18.42491
847	transacciones.csv	OMITIDO	736,11-05-2024,1500,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	737	2026-09-20 21:44:18.428414
848	transacciones.csv	OMITIDO	737,17/03/2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	738	2026-09-20 21:44:18.429664
850	transacciones.csv	OMITIDO	738,30/06/2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	739	2026-09-20 21:44:18.430845
851	transacciones.csv	OMITIDO	739,2024-03-20,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	740	2026-09-20 21:44:18.431978
806	intereses.csv	OMITIDO	106,Alice Brown,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	595	2026-09-20 21:44:18.380389
809	intereses.csv	OMITIDO	150,Bob Johnson,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	597	2026-09-20 21:44:18.384665
811	intereses.csv	OMITIDO	149,Charlie Green,12000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	599	2026-09-20 21:44:18.385746
812	intereses.csv	OMITIDO	112,Diana Prince,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	600	2026-09-20 21:44:18.386489
813	intereses.csv	OMITIDO	142,Bob Johnson,,100,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	601	2026-09-20 21:44:18.387518
818	intereses.csv	OMITIDO	131,Steve Rogers,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	603	2026-09-20 21:44:18.391154
820	intereses.csv	OMITIDO	102,John Doe,12000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	604	2026-09-20 21:44:18.392296
821	intereses.csv	OMITIDO	137,Alice Brown,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	606	2026-09-20 21:44:18.393482
825	intereses.csv	OMITIDO	143,Unknown,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	607	2026-09-20 21:44:18.398162
826	intereses.csv	OMITIDO	140,Steve Rogers,5000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	609	2026-09-20 21:44:18.399609
828	intereses.csv	OMITIDO	124,Jane Smith,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	610	2026-09-20 21:44:18.400871
830	intereses.csv	OMITIDO	118,John Doe,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	614	2026-09-20 21:44:18.405993
832	intereses.csv	OMITIDO	142,Jane Smith,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	615	2026-09-20 21:44:18.407351
834	intereses.csv	OMITIDO	114,Diana Prince,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	616	2026-09-20 21:44:18.409364
837	intereses.csv	OMITIDO	104,Jane Smith,,25,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	617	2026-09-20 21:44:18.415026
838	intereses.csv	OMITIDO	130,Steve Rogers,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	618	2026-09-20 21:44:18.41729
840	intereses.csv	OMITIDO	139,Alice Brown,12000,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	619	2026-09-20 21:44:18.419809
841	intereses.csv	OMITIDO	120,Jane Smith,,40,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	621	2026-09-20 21:44:18.421556
844	intereses.csv	OMITIDO	119,Unknown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	622	2026-09-20 21:44:18.42504
845	intereses.csv	OMITIDO	128,Alice Brown,5000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	623	2026-09-20 21:44:18.426558
846	intereses.csv	OMITIDO	125,John Doe,,40,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	625	2026-09-20 21:44:18.427686
849	intereses.csv	FILTRADO	115,Bob Johnson,8000,45,hipoteca	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	631	2026-09-20 21:44:18.430557
852	intereses.csv	OMITIDO	140,Diana Prince,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	627	2026-09-20 21:44:18.432213
853	intereses.csv	OMITIDO	138,Unknown,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	629	2026-09-20 21:44:18.433538
854	intereses.csv	OMITIDO	113,Diana Prince,8000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	630	2026-09-20 21:44:18.434341
857	intereses.csv	OMITIDO	139,Jane Smith,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	632	2026-09-20 21:44:18.436831
858	intereses.csv	OMITIDO	147,John Doe,8000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	633	2026-09-20 21:44:18.437805
860	intereses.csv	OMITIDO	109,John Doe,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	634	2026-09-20 21:44:18.439039
861	intereses.csv	OMITIDO	106,Bob Johnson,7000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	635	2026-09-20 21:44:18.440423
862	intereses.csv	OMITIDO	140,Bob Johnson,,150,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	636	2026-09-20 21:44:18.441298
865	intereses.csv	OMITIDO	137,Diana Prince,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	637	2026-09-20 21:44:18.444417
866	intereses.csv	OMITIDO	127,John Doe,8000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	639	2026-09-20 21:44:18.445402
868	intereses.csv	OMITIDO	116,Bob Johnson,12000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	640	2026-09-20 21:44:18.446446
870	intereses.csv	OMITIDO	107,Jane Smith,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	641	2026-09-20 21:44:18.447178
872	intereses.csv	OMITIDO	117,John Doe,,100,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	642	2026-09-20 21:44:18.449626
874	intereses.csv	OMITIDO	118,John Doe,,100,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	643	2026-09-20 21:44:18.450861
875	intereses.csv	OMITIDO	129,Alice Brown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	644	2026-09-20 21:44:18.451948
876	intereses.csv	OMITIDO	116,Charlie Green,12000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	646	2026-09-20 21:44:18.453377
879	intereses.csv	OMITIDO	107,Diana Prince,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	647	2026-09-20 21:44:18.456132
880	intereses.csv	OMITIDO	105,Alice Brown,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	648	2026-09-20 21:44:18.457263
855	transacciones.csv	OMITIDO	741,2024-13-01,1200,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	742	2026-09-20 21:44:18.435601
856	transacciones.csv	OMITIDO	742,14-05-2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	743	2026-09-20 21:44:18.436813
859	transacciones.csv	OMITIDO	745,2024/12/23,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	746	2026-09-20 21:44:18.438052
863	transacciones.csv	OMITIDO	746,2024/06/08,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	747	2026-09-20 21:44:18.441612
864	transacciones.csv	OMITIDO	749,2024/06/20,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	750	2026-09-20 21:44:18.442779
867	transacciones.csv	OMITIDO	751,2024-11-13,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	752	2026-09-20 21:44:18.445744
869	transacciones.csv	OMITIDO	752,02-05-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	753	2026-09-20 21:44:18.446846
871	transacciones.csv	OMITIDO	755,2024-13-01,1200,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	756	2026-09-20 21:44:18.447567
873	transacciones.csv	OMITIDO	758,2024-06-14,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	759	2026-09-20 21:44:18.450114
877	transacciones.csv	OMITIDO	763,2024/07/23,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	764	2026-09-20 21:44:18.453978
878	transacciones.csv	OMITIDO	765,2024-06-26,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	766	2026-09-20 21:44:18.454809
881	transacciones.csv	OMITIDO	768,25/12/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	769	2026-09-20 21:44:18.457528
883	transacciones.csv	OMITIDO	769,25-11-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	770	2026-09-20 21:44:18.45875
885	transacciones.csv	OMITIDO	771,24/12/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	772	2026-09-20 21:44:18.462136
887	transacciones.csv	OMITIDO	772,05-09-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	773	2026-09-20 21:44:18.462993
889	transacciones.csv	OMITIDO	773,19/03/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	774	2026-09-20 21:44:18.464106
891	transacciones.csv	OMITIDO	775,06-04-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	776	2026-09-20 21:44:18.465155
893	transacciones.csv	OMITIDO	780,2024-02-16,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	781	2026-09-20 21:44:18.468626
896	transacciones.csv	OMITIDO	781,2024/01/12,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	782	2026-09-20 21:44:18.471665
898	transacciones.csv	OMITIDO	782,18-11-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	783	2026-09-20 21:44:18.472731
900	transacciones.csv	OMITIDO	784,2024-08-09,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	785	2026-09-20 21:44:18.474137
901	transacciones.csv	OMITIDO	785,07-05-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	786	2026-09-20 21:44:18.47507
904	transacciones.csv	OMITIDO	786,2024-08-25,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	787	2026-09-20 21:44:18.47915
905	transacciones.csv	OMITIDO	788,31/10/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	789	2026-09-20 21:44:18.480333
907	transacciones.csv	OMITIDO	792,2024-07-08,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	793	2026-09-20 21:44:18.483671
909	transacciones.csv	OMITIDO	793,2024/12/04,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	794	2026-09-20 21:44:18.484986
911	transacciones.csv	OMITIDO	794,30-12-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	795	2026-09-20 21:44:18.486382
913	transacciones.csv	OMITIDO	796,2024/01/16,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	797	2026-09-20 21:44:18.490018
915	transacciones.csv	OMITIDO	799,2024-13-01,3000,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	800	2026-09-20 21:44:18.491377
917	transacciones.csv	OMITIDO	800,2024/01/27,-100,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	801	2026-09-20 21:44:18.492454
918	transacciones.csv	OMITIDO	801,14/01/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	802	2026-09-20 21:44:18.497214
921	transacciones.csv	OMITIDO	803,12-02-2024,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	804	2026-09-20 21:44:18.498697
923	transacciones.csv	OMITIDO	804,11/07/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	805	2026-09-20 21:44:18.500063
925	transacciones.csv	OMITIDO	805,17-10-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	806	2026-09-20 21:44:18.501563
926	transacciones.csv	OMITIDO	806,14/01/2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	807	2026-09-20 21:44:18.505642
929	transacciones.csv	OMITIDO	809,2024-01-18,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	810	2026-09-20 21:44:18.50781
931	transacciones.csv	OMITIDO	810,13/10/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	811	2026-09-20 21:44:18.509757
933	transacciones.csv	OMITIDO	812,20-05-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	813	2026-09-20 21:44:18.514216
935	transacciones.csv	OMITIDO	813,2024-03-17,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	814	2026-09-20 21:44:18.516116
882	intereses.csv	OMITIDO	137,Steve Rogers,7000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	651	2026-09-20 21:44:18.45829
884	intereses.csv	OMITIDO	138,John Doe,7000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	652	2026-09-20 21:44:18.461648
886	intereses.csv	OMITIDO	142,Bob Johnson,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	653	2026-09-20 21:44:18.462739
888	intereses.csv	OMITIDO	136,Alice Brown,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	654	2026-09-20 21:44:18.46364
890	intereses.csv	OMITIDO	104,Diana Prince,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	655	2026-09-20 21:44:18.464753
892	intereses.csv	OMITIDO	138,Charlie Green,7000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	656	2026-09-20 21:44:18.465696
894	intereses.csv	OMITIDO	149,Alice Brown,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	659	2026-09-20 21:44:18.468668
895	intereses.csv	OMITIDO	109,Diana Prince,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	661	2026-09-20 21:44:18.46985
897	intereses.csv	OMITIDO	116,Diana Prince,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	662	2026-09-20 21:44:18.472321
899	intereses.csv	OMITIDO	119,John Doe,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	663	2026-09-20 21:44:18.473608
902	intereses.csv	OMITIDO	114,Alice Brown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	667	2026-09-20 21:44:18.477084
903	intereses.csv	OMITIDO	127,Alice Brown,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	668	2026-09-20 21:44:18.47915
906	intereses.csv	OMITIDO	116,John Doe,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	669	2026-09-20 21:44:18.480641
908	intereses.csv	OMITIDO	125,Diana Prince,5000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	672	2026-09-20 21:44:18.483906
910	intereses.csv	OMITIDO	138,John Doe,10000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	675	2026-09-20 21:44:18.485318
912	intereses.csv	OMITIDO	148,Steve Rogers,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	679	2026-09-20 21:44:18.490018
914	intereses.csv	OMITIDO	141,Bob Johnson,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	680	2026-09-20 21:44:18.491022
916	intereses.csv	OMITIDO	105,John Doe,,35,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	681	2026-09-20 21:44:18.492201
919	intereses.csv	OMITIDO	105,Diana Prince,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	682	2026-09-20 21:44:18.497214
920	intereses.csv	OMITIDO	103,Unknown,7000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	683	2026-09-20 21:44:18.498443
922	intereses.csv	OMITIDO	148,Steve Rogers,5000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	684	2026-09-20 21:44:18.499806
924	intereses.csv	OMITIDO	109,Diana Prince,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	685	2026-09-20 21:44:18.501091
927	intereses.csv	OMITIDO	148,Steve Rogers,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	689	2026-09-20 21:44:18.505699
928	intereses.csv	OMITIDO	144,Jane Smith,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	690	2026-09-20 21:44:18.507379
930	intereses.csv	OMITIDO	103,Bob Johnson,,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	691	2026-09-20 21:44:18.509452
932	intereses.csv	OMITIDO	114,Alice Brown,8000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	692	2026-09-20 21:44:18.5132
934	intereses.csv	OMITIDO	129,Steve Rogers,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	693	2026-09-20 21:44:18.514922
936	intereses.csv	OMITIDO	123,Steve Rogers,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	694	2026-09-20 21:44:18.516332
938	intereses.csv	OMITIDO	107,Jane Smith,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	695	2026-09-20 21:44:18.517933
939	intereses.csv	OMITIDO	134,Steve Rogers,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	696	2026-09-20 21:44:18.519153
941	intereses.csv	OMITIDO	113,Diana Prince,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	697	2026-09-20 21:44:18.52409
943	intereses.csv	OMITIDO	127,Diana Prince,5000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	699	2026-09-20 21:44:18.52529
945	intereses.csv	OMITIDO	125,Diana Prince,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	700	2026-09-20 21:44:18.526613
946	intereses.csv	OMITIDO	106,Bob Johnson,5000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	705	2026-09-20 21:44:18.531671
949	intereses.csv	OMITIDO	134,Steve Rogers,8000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	707	2026-09-20 21:44:18.537504
951	intereses.csv	OMITIDO	131,Bob Johnson,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	708	2026-09-20 21:44:18.539327
953	intereses.csv	OMITIDO	131,John Doe,10000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	709	2026-09-20 21:44:18.541102
954	intereses.csv	OMITIDO	129,Alice Brown,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	710	2026-09-20 21:44:18.542643
956	intereses.csv	OMITIDO	125,Jane Smith,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	713	2026-09-20 21:44:18.548479
937	transacciones.csv	OMITIDO	815,2024/11/19,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	816	2026-09-20 21:44:18.517658
940	transacciones.csv	OMITIDO	816,2024/01/28,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	817	2026-09-20 21:44:18.522756
942	transacciones.csv	OMITIDO	817,2024/07/10,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	818	2026-09-20 21:44:18.52467
944	transacciones.csv	OMITIDO	819,13/06/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	820	2026-09-20 21:44:18.525713
947	transacciones.csv	OMITIDO	821,2024-04-07,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	822	2026-09-20 21:44:18.531727
948	transacciones.csv	OMITIDO	825,2024-05-14,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	826	2026-09-20 21:44:18.533164
950	transacciones.csv	OMITIDO	828,2024-05-23,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	829	2026-09-20 21:44:18.53847
952	transacciones.csv	OMITIDO	829,2024-13-01,3000,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	830	2026-09-20 21:44:18.539807
955	transacciones.csv	OMITIDO	835,2024-13-01,1500,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	836	2026-09-20 21:44:18.545995
958	transacciones.csv	OMITIDO	837,2024/07/10,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	838	2026-09-20 21:44:18.551739
960	transacciones.csv	OMITIDO	838,2024-13-01,,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	839	2026-09-20 21:44:18.553352
961	transacciones.csv	OMITIDO	841,2024/08/15,0,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	842	2026-09-20 21:44:18.55822
964	transacciones.csv	OMITIDO	845,31-08-2024,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	846	2026-09-20 21:44:18.559544
967	transacciones.csv	OMITIDO	846,2024-08-30,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	847	2026-09-20 21:44:18.564718
970	transacciones.csv	OMITIDO	851,23/03/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	852	2026-09-20 21:44:18.570775
972	transacciones.csv	OMITIDO	852,2024-13-01,1000,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	853	2026-09-20 21:44:18.57253
974	transacciones.csv	OMITIDO	853,03-07-2024,700,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	854	2026-09-20 21:44:18.573686
976	transacciones.csv	OMITIDO	858,12-11-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	859	2026-09-20 21:44:18.578189
978	transacciones.csv	OMITIDO	860,2024/02/08,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	861	2026-09-20 21:44:18.579714
981	transacciones.csv	OMITIDO	862,24/07/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	863	2026-09-20 21:44:18.584835
982	transacciones.csv	OMITIDO	863,2024-13-01,-200,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	864	2026-09-20 21:44:18.586467
986	transacciones.csv	OMITIDO	867,12-03-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	868	2026-09-20 21:44:18.590968
988	transacciones.csv	OMITIDO	868,2024/11/20,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	869	2026-09-20 21:44:18.592935
989	transacciones.csv	OMITIDO	870,2024-06-23,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	871	2026-09-20 21:44:18.594253
992	transacciones.csv	OMITIDO	873,2024-12-23,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	874	2026-09-20 21:44:18.600309
994	transacciones.csv	OMITIDO	874,2024-12-20,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	875	2026-09-20 21:44:18.601994
995	transacciones.csv	OMITIDO	875,01/09/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	876	2026-09-20 21:44:18.603545
998	transacciones.csv	OMITIDO	877,19-03-2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	878	2026-09-20 21:44:18.608234
1000	transacciones.csv	OMITIDO	878,2024-01-08,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	879	2026-09-20 21:44:18.609722
1001	transacciones.csv	OMITIDO	879,2024/07/05,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	880	2026-09-20 21:44:18.61136
1004	transacciones.csv	OMITIDO	881,06/11/2024,-100,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	882	2026-09-20 21:44:18.615495
1006	transacciones.csv	OMITIDO	882,2024-07-08,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	883	2026-09-20 21:44:18.617164
1008	transacciones.csv	OMITIDO	883,2024/04/03,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	884	2026-09-20 21:44:18.619172
1010	transacciones.csv	OMITIDO	888,2024/12/25,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	889	2026-09-20 21:44:18.623735
1014	transacciones.csv	OMITIDO	891,2024/12/24,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	892	2026-09-20 21:44:18.628799
1015	transacciones.csv	OMITIDO	893,2024-11-06,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	894	2026-09-20 21:44:18.630124
1016	transacciones.csv	OMITIDO	894,30/10/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	895	2026-09-20 21:44:18.632333
1021	transacciones.csv	OMITIDO	896,2024-13-01,1500,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	897	2026-09-20 21:44:18.639404
1022	transacciones.csv	OMITIDO	901,2024/06/22,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	902	2026-09-20 21:44:18.642739
957	intereses.csv	OMITIDO	124,Diana Prince,10000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	714	2026-09-20 21:44:18.550201
959	intereses.csv	OMITIDO	144,John Doe,,25,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	716	2026-09-20 21:44:18.552939
962	intereses.csv	OMITIDO	114,Alice Brown,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	718	2026-09-20 21:44:18.55822
963	intereses.csv	OMITIDO	113,Bob Johnson,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	719	2026-09-20 21:44:18.559491
965	intereses.csv	OMITIDO	127,Charlie Green,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	720	2026-09-20 21:44:18.560839
966	intereses.csv	OMITIDO	124,John Doe,12000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	721	2026-09-20 21:44:18.562212
968	intereses.csv	OMITIDO	139,Jane Smith,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	722	2026-09-20 21:44:18.568085
969	intereses.csv	OMITIDO	108,Steve Rogers,5000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	723	2026-09-20 21:44:18.569855
971	intereses.csv	OMITIDO	136,John Doe,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	724	2026-09-20 21:44:18.571923
973	intereses.csv	OMITIDO	123,John Doe,7000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	726	2026-09-20 21:44:18.573127
975	intereses.csv	OMITIDO	103,John Doe,7000,150,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	727	2026-09-20 21:44:18.577661
977	intereses.csv	OMITIDO	140,Bob Johnson,,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	728	2026-09-20 21:44:18.579475
979	intereses.csv	OMITIDO	129,John Doe,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	729	2026-09-20 21:44:18.581013
980	intereses.csv	OMITIDO	142,Charlie Green,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	731	2026-09-20 21:44:18.582646
983	intereses.csv	OMITIDO	110,Bob Johnson,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	732	2026-09-20 21:44:18.587359
984	intereses.csv	OMITIDO	142,Alice Brown,12000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	734	2026-09-20 21:44:18.588772
985	intereses.csv	OMITIDO	130,Unknown,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	735	2026-09-20 21:44:18.590661
987	intereses.csv	OMITIDO	111,Steve Rogers,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	736	2026-09-20 21:44:18.59248
990	intereses.csv	OMITIDO	107,John Doe,,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	737	2026-09-20 21:44:18.596432
991	intereses.csv	OMITIDO	144,John Doe,10000,,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	738	2026-09-20 21:44:18.598495
993	intereses.csv	OMITIDO	111,John Doe,,45,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	740	2026-09-20 21:44:18.600931
996	intereses.csv	OMITIDO	125,Alice Brown,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	742	2026-09-20 21:44:18.605827
997	intereses.csv	OMITIDO	122,Charlie Green,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	744	2026-09-20 21:44:18.607523
999	intereses.csv	OMITIDO	137,Diana Prince,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	745	2026-09-20 21:44:18.608966
1002	intereses.csv	OMITIDO	138,Steve Rogers,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	747	2026-09-20 21:44:18.613809
1003	intereses.csv	OMITIDO	123,Unknown,10000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	749	2026-09-20 21:44:18.615493
1005	intereses.csv	OMITIDO	122,Alice Brown,5000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	750	2026-09-20 21:44:18.616736
1007	intereses.csv	OMITIDO	139,Charlie Green,,25,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	751	2026-09-20 21:44:18.618584
1009	intereses.csv	OMITIDO	110,Diana Prince,8000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	752	2026-09-20 21:44:18.623338
1011	intereses.csv	OMITIDO	137,Jane Smith,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	753	2026-09-20 21:44:18.625299
1012	intereses.csv	OMITIDO	139,Charlie Green,7000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	754	2026-09-20 21:44:18.627077
1013	intereses.csv	OMITIDO	132,Charlie Green,5000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	755	2026-09-20 21:44:18.62834
1017	intereses.csv	OMITIDO	144,Alice Brown,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	757	2026-09-20 21:44:18.633162
1018	intereses.csv	OMITIDO	148,Alice Brown,8000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	758	2026-09-20 21:44:18.634843
1019	intereses.csv	OMITIDO	106,Diana Prince,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	759	2026-09-20 21:44:18.637362
1020	intereses.csv	OMITIDO	106,Charlie Green,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	761	2026-09-20 21:44:18.639195
1023	intereses.csv	OMITIDO	107,Jane Smith,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	763	2026-09-20 21:44:18.642739
1024	intereses.csv	OMITIDO	143,Bob Johnson,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	764	2026-09-20 21:44:18.643686
1026	intereses.csv	OMITIDO	140,Diana Prince,5000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	765	2026-09-20 21:44:18.644793
1025	transacciones.csv	OMITIDO	902,30/01/2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	903	2026-09-20 21:44:18.644007
1028	transacciones.csv	OMITIDO	906,19/01/2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	907	2026-09-20 21:44:18.647687
1029	transacciones.csv	OMITIDO	909,2024-13-01,800,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	910	2026-09-20 21:44:18.649039
1031	transacciones.csv	OMITIDO	910,08/08/2024,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	911	2026-09-20 21:44:18.64994
1035	transacciones.csv	OMITIDO	913,06/04/2024,500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	914	2026-09-20 21:44:18.653398
1036	transacciones.csv	OMITIDO	915,2024/01/21,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	916	2026-09-20 21:44:18.654661
1039	transacciones.csv	OMITIDO	916,2024-12-24,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	917	2026-09-20 21:44:18.657847
1041	transacciones.csv	OMITIDO	917,2024-13-01,800,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	918	2026-09-20 21:44:18.65881
1043	transacciones.csv	OMITIDO	918,22-01-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	919	2026-09-20 21:44:18.659797
1045	transacciones.csv	OMITIDO	921,24/09/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	922	2026-09-20 21:44:18.662817
1047	transacciones.csv	OMITIDO	923,20-12-2024,,desconocido	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	924	2026-09-20 21:44:18.66364
1049	transacciones.csv	OMITIDO	924,30-10-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	925	2026-09-20 21:44:18.664482
1051	transacciones.csv	OMITIDO	925,04/11/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	926	2026-09-20 21:44:18.665413
1053	transacciones.csv	OMITIDO	926,2024-01-23,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	927	2026-09-20 21:44:18.668926
1055	transacciones.csv	OMITIDO	927,2024-13-01,,credito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	928	2026-09-20 21:44:18.669992
1057	transacciones.csv	OMITIDO	928,2024/04/14,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	929	2026-09-20 21:44:18.670818
1060	transacciones.csv	OMITIDO	931,08-12-2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	932	2026-09-20 21:44:18.67374
1062	transacciones.csv	OMITIDO	933,01-08-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	934	2026-09-20 21:44:18.674659
1063	transacciones.csv	OMITIDO	934,02/08/2024,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	935	2026-09-20 21:44:18.676006
1065	transacciones.csv	OMITIDO	935,26/08/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	936	2026-09-20 21:44:18.677038
1069	transacciones.csv	OMITIDO	938,08-10-2024,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	939	2026-09-20 21:44:18.680453
1072	transacciones.csv	OMITIDO	941,14-01-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	942	2026-09-20 21:44:18.684422
1074	transacciones.csv	OMITIDO	944,2024/07/20,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	945	2026-09-20 21:44:18.68575
1077	transacciones.csv	OMITIDO	949,15-09-2024,1000,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	950	2026-09-20 21:44:18.689672
1081	transacciones.csv	OMITIDO	951,2024-06-07,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	952	2026-09-20 21:44:18.692247
1083	transacciones.csv	OMITIDO	954,2024/02/10,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	955	2026-09-20 21:44:18.693353
1085	transacciones.csv	OMITIDO	956,2024/12/01,,credito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	957	2026-09-20 21:44:18.696803
1087	transacciones.csv	OMITIDO	957,30/12/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	958	2026-09-20 21:44:18.698019
1089	transacciones.csv	OMITIDO	959,2024-06-25,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	960	2026-09-20 21:44:18.698873
1091	transacciones.csv	OMITIDO	960,2024/03/29,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	961	2026-09-20 21:44:18.699829
1094	transacciones.csv	OMITIDO	961,20-10-2024,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	962	2026-09-20 21:44:18.703741
1095	transacciones.csv	OMITIDO	965,2024/08/12,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	966	2026-09-20 21:44:18.706206
1098	transacciones.csv	OMITIDO	969,2024/04/15,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	970	2026-09-20 21:44:18.70955
1099	transacciones.csv	OMITIDO	970,2024-02-14,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	971	2026-09-20 21:44:18.710723
1103	transacciones.csv	OMITIDO	972,03/12/2024,1000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	973	2026-09-20 21:44:18.713845
1105	transacciones.csv	OMITIDO	973,2024-13-01,,debito	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	974	2026-09-20 21:44:18.714914
1106	transacciones.csv	OMITIDO	975,2024-04-07,1200,desconocido	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'desconocido' [hilo=batch-flujo-3]	976	2026-09-20 21:44:18.716128
1108	transacciones.csv	OMITIDO	976,2024-02-09,800,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	977	2026-09-20 21:44:18.720931
1109	transacciones.csv	OMITIDO	977,2024-05-21,3000,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	978	2026-09-20 21:44:18.722841
1027	intereses.csv	OMITIDO	114,Bob Johnson,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	766	2026-09-20 21:44:18.645888
1030	intereses.csv	FILTRADO	109,Diana Prince,7000,25,-1	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	767	2026-09-20 21:44:18.64948
1032	intereses.csv	OMITIDO	110,Steve Rogers,,25,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	769	2026-09-20 21:44:18.650947
1033	intereses.csv	OMITIDO	139,Diana Prince,12000,100,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	770	2026-09-20 21:44:18.652173
1034	intereses.csv	OMITIDO	150,Diana Prince,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	771	2026-09-20 21:44:18.653246
1037	intereses.csv	OMITIDO	102,Charlie Green,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	772	2026-09-20 21:44:18.656313
1038	intereses.csv	OMITIDO	107,Jane Smith,,100,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	774	2026-09-20 21:44:18.657153
1040	intereses.csv	OMITIDO	144,Charlie Green,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	775	2026-09-20 21:44:18.658152
1042	intereses.csv	OMITIDO	116,Steve Rogers,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	776	2026-09-20 21:44:18.659244
1044	intereses.csv	OMITIDO	135,Bob Johnson,,40,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	777	2026-09-20 21:44:18.662318
1046	intereses.csv	OMITIDO	139,Charlie Green,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	778	2026-09-20 21:44:18.663231
1048	intereses.csv	OMITIDO	138,Bob Johnson,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	779	2026-09-20 21:44:18.664003
1050	intereses.csv	OMITIDO	123,Jane Smith,8000,40,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	781	2026-09-20 21:44:18.664981
1052	intereses.csv	OMITIDO	127,Jane Smith,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	782	2026-09-20 21:44:18.667967
1054	intereses.csv	OMITIDO	145,Bob Johnson,12000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	783	2026-09-20 21:44:18.669714
1056	intereses.csv	OMITIDO	128,Jane Smith,,45,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	784	2026-09-20 21:44:18.670565
1058	intereses.csv	OMITIDO	133,John Doe,12000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	785	2026-09-20 21:44:18.671312
1059	intereses.csv	OMITIDO	145,Jane Smith,7000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	786	2026-09-20 21:44:18.672092
1061	intereses.csv	OMITIDO	145,Charlie Green,10000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	787	2026-09-20 21:44:18.674635
1064	intereses.csv	OMITIDO	124,Steve Rogers,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	788	2026-09-20 21:44:18.676351
1066	intereses.csv	OMITIDO	140,Charlie Green,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	789	2026-09-20 21:44:18.677322
1067	intereses.csv	OMITIDO	114,Bob Johnson,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	790	2026-09-20 21:44:18.678122
1068	intereses.csv	OMITIDO	101,Bob Johnson,8000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	791	2026-09-20 21:44:18.679037
1070	intereses.csv	OMITIDO	128,Jane Smith,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	792	2026-09-20 21:44:18.683179
1071	intereses.csv	OMITIDO	111,Jane Smith,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	794	2026-09-20 21:44:18.684187
1073	intereses.csv	OMITIDO	145,Steve Rogers,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	795	2026-09-20 21:44:18.68543
1075	intereses.csv	OMITIDO	114,Steve Rogers,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	796	2026-09-20 21:44:18.686611
1076	intereses.csv	OMITIDO	119,John Doe,12000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	797	2026-09-20 21:44:18.689138
1078	intereses.csv	OMITIDO	101,Bob Johnson,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	798	2026-09-20 21:44:18.690197
1079	intereses.csv	OMITIDO	107,Unknown,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	799	2026-09-20 21:44:18.691002
1080	intereses.csv	OMITIDO	105,Steve Rogers,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	800	2026-09-20 21:44:18.691755
1082	intereses.csv	OMITIDO	104,John Doe,,45,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	801	2026-09-20 21:44:18.69271
1084	intereses.csv	OMITIDO	122,Bob Johnson,10000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	802	2026-09-20 21:44:18.69557
1086	intereses.csv	OMITIDO	128,Steve Rogers,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	803	2026-09-20 21:44:18.697222
1088	intereses.csv	OMITIDO	117,Jane Smith,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	804	2026-09-20 21:44:18.698289
1090	intereses.csv	OMITIDO	135,Alice Brown,8000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	805	2026-09-20 21:44:18.699188
1092	intereses.csv	OMITIDO	149,Alice Brown,,35,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	806	2026-09-20 21:44:18.700073
1093	intereses.csv	OMITIDO	125,Bob Johnson,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	808	2026-09-20 21:44:18.703721
1096	intereses.csv	OMITIDO	126,John Doe,10000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	809	2026-09-20 21:44:18.706486
1097	intereses.csv	OMITIDO	138,Bob Johnson,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	810	2026-09-20 21:44:18.707729
1100	intereses.csv	OMITIDO	102,Jane Smith,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	813	2026-09-20 21:44:18.711451
1101	intereses.csv	OMITIDO	120,Diana Prince,12000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	814	2026-09-20 21:44:18.712333
1102	intereses.csv	OMITIDO	101,Bob Johnson,10000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	815	2026-09-20 21:44:18.713111
1104	intereses.csv	OMITIDO	121,Alice Brown,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	816	2026-09-20 21:44:18.71455
1107	intereses.csv	OMITIDO	127,Bob Johnson,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	817	2026-09-20 21:44:18.719262
1110	intereses.csv	OMITIDO	108,John Doe,,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	825	2026-09-20 21:44:18.724388
1112	intereses.csv	OMITIDO	134,John Doe,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	826	2026-09-20 21:44:18.725982
1114	intereses.csv	OMITIDO	105,Alice Brown,,30,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	827	2026-09-20 21:44:18.72976
1116	intereses.csv	OMITIDO	138,Diana Prince,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	828	2026-09-20 21:44:18.73178
1118	intereses.csv	OMITIDO	113,Bob Johnson,5000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	829	2026-09-20 21:44:18.73292
1120	intereses.csv	OMITIDO	134,Steve Rogers,5000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	830	2026-09-20 21:44:18.734104
1121	intereses.csv	OMITIDO	147,Steve Rogers,10000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	831	2026-09-20 21:44:18.73612
1124	intereses.csv	OMITIDO	149,Alice Brown,10000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	834	2026-09-20 21:44:18.740904
1126	intereses.csv	OMITIDO	131,Charlie Green,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	836	2026-09-20 21:44:18.742638
1128	intereses.csv	OMITIDO	111,Alice Brown,8000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	837	2026-09-20 21:44:18.747706
1130	intereses.csv	OMITIDO	121,Charlie Green,,45,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	839	2026-09-20 21:44:18.750266
1132	intereses.csv	OMITIDO	129,Steve Rogers,10000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	842	2026-09-20 21:44:18.754695
1134	intereses.csv	OMITIDO	106,John Doe,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	847	2026-09-20 21:44:18.758672
1135	intereses.csv	OMITIDO	108,Diana Prince,5000,25,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	851	2026-09-20 21:44:18.760022
1136	intereses.csv	OMITIDO	104,John Doe,7000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	853	2026-09-20 21:44:18.764243
1137	intereses.csv	OMITIDO	117,Bob Johnson,5000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	855	2026-09-20 21:44:18.765366
1138	intereses.csv	OMITIDO	141,Jane Smith,12000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	856	2026-09-20 21:44:18.766401
1139	intereses.csv	OMITIDO	115,Alice Brown,12000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	857	2026-09-20 21:44:18.770194
1140	intereses.csv	OMITIDO	113,Steve Rogers,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	860	2026-09-20 21:44:18.771383
1141	intereses.csv	OMITIDO	101,Bob Johnson,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	861	2026-09-20 21:44:18.773094
1142	intereses.csv	OMITIDO	138,Charlie Green,12000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	862	2026-09-20 21:44:18.775948
1143	intereses.csv	OMITIDO	146,Steve Rogers,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	864	2026-09-20 21:44:18.776926
1144	intereses.csv	OMITIDO	109,Bob Johnson,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	865	2026-09-20 21:44:18.777838
1145	intereses.csv	OMITIDO	135,Jane Smith,12000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	867	2026-09-20 21:44:18.781112
1146	intereses.csv	OMITIDO	142,Bob Johnson,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	869	2026-09-20 21:44:18.781937
1147	intereses.csv	OMITIDO	102,Steve Rogers,7000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	870	2026-09-20 21:44:18.782846
1148	intereses.csv	OMITIDO	110,Unknown,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	872	2026-09-20 21:44:18.786079
1149	intereses.csv	OMITIDO	145,Diana Prince,8000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	875	2026-09-20 21:44:18.78735
1150	intereses.csv	OMITIDO	108,Diana Prince,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	876	2026-09-20 21:44:18.788313
1151	intereses.csv	OMITIDO	111,Charlie Green,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	878	2026-09-20 21:44:18.791775
1152	intereses.csv	OMITIDO	147,Bob Johnson,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	881	2026-09-20 21:44:18.792669
1153	intereses.csv	OMITIDO	116,Steve Rogers,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	882	2026-09-20 21:44:18.79601
1154	intereses.csv	OMITIDO	111,Jane Smith,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	884	2026-09-20 21:44:18.796939
1111	transacciones.csv	OMITIDO	978,2024/04/08,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	979	2026-09-20 21:44:18.725228
1113	transacciones.csv	OMITIDO	980,2024-06-22,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	981	2026-09-20 21:44:18.726493
1115	transacciones.csv	OMITIDO	982,2024-06-08,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	983	2026-09-20 21:44:18.730927
1117	transacciones.csv	OMITIDO	983,2024-05-23,1500,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	984	2026-09-20 21:44:18.732313
1119	transacciones.csv	OMITIDO	984,07/05/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	985	2026-09-20 21:44:18.733446
1122	transacciones.csv	OMITIDO	986,13/05/2024,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	987	2026-09-20 21:44:18.73857
1123	transacciones.csv	OMITIDO	987,13/10/2024,,debito	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	988	2026-09-20 21:44:18.740191
1125	transacciones.csv	OMITIDO	988,11-12-2024,1200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	989	2026-09-20 21:44:18.742024
1127	transacciones.csv	OMITIDO	993,2024-13-01,700,invalid	1	reporteTransaccionesDiariasJob	Fecha ilegible o inexistente: 2024-13-01 [hilo=batch-flujo-3]	994	2026-09-20 21:44:18.747559
1129	transacciones.csv	OMITIDO	994,2024-06-09,700,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	995	2026-09-20 21:44:18.749639
1131	transacciones.csv	OMITIDO	997,2024-06-14,-200,invalid	1	reporteTransaccionesDiariasJob	Tipo fuera del catalogo permitido: 'invalid' [hilo=batch-flujo-3]	998	2026-09-20 21:44:18.754644
1133	transacciones.csv	OMITIDO	998,14-01-2024,,invalid	1	reporteTransaccionesDiariasJob	Monto vacio o no numerico: '' [hilo=batch-flujo-3]	999	2026-09-20 21:44:18.755874
1155	intereses.csv	OMITIDO	143,Jane Smith,10000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	885	2026-09-20 21:44:18.798017
1156	intereses.csv	OMITIDO	123,Diana Prince,,25,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	886	2026-09-20 21:44:18.798838
1157	intereses.csv	OMITIDO	127,Steve Rogers,12000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	887	2026-09-20 21:44:18.801854
1158	intereses.csv	OMITIDO	137,Diana Prince,10000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	888	2026-09-20 21:44:18.802864
1159	intereses.csv	OMITIDO	121,John Doe,7000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	889	2026-09-20 21:44:18.803841
1160	intereses.csv	OMITIDO	106,Steve Rogers,,35,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	890	2026-09-20 21:44:18.804787
1161	intereses.csv	OMITIDO	146,Diana Prince,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	891	2026-09-20 21:44:18.805885
1162	intereses.csv	OMITIDO	105,John Doe,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	892	2026-09-20 21:44:18.810295
1163	intereses.csv	OMITIDO	142,Alice Brown,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	894	2026-09-20 21:44:18.811262
1164	intereses.csv	OMITIDO	114,Jane Smith,,150,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	895	2026-09-20 21:44:18.812404
1165	intereses.csv	OMITIDO	126,Diana Prince,5000,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	896	2026-09-20 21:44:18.813686
1166	intereses.csv	OMITIDO	113,Diana Prince,5000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	897	2026-09-20 21:44:18.816754
1167	intereses.csv	OMITIDO	118,Steve Rogers,,45,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	898	2026-09-20 21:44:18.817922
1168	intereses.csv	OMITIDO	119,Jane Smith,,35,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	899	2026-09-20 21:44:18.818943
1169	intereses.csv	OMITIDO	138,Steve Rogers,5000,,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	900	2026-09-20 21:44:18.819894
1170	intereses.csv	OMITIDO	135,Alice Brown,,45,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	901	2026-09-20 21:44:18.821592
1171	intereses.csv	OMITIDO	112,Steve Rogers,,40,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	902	2026-09-20 21:44:18.826644
1172	intereses.csv	OMITIDO	115,John Doe,8000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	903	2026-09-20 21:44:18.828049
1173	intereses.csv	OMITIDO	125,Bob Johnson,7000,150,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 150 (rango permitido 18-99) [hilo=batch-flujo-1]	904	2026-09-20 21:44:18.829333
1174	intereses.csv	OMITIDO	131,Bob Johnson,10000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	905	2026-09-20 21:44:18.830231
1175	intereses.csv	OMITIDO	122,John Doe,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	906	2026-09-20 21:44:18.831058
1176	intereses.csv	OMITIDO	126,John Doe,10000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	908	2026-09-20 21:44:18.834136
1177	intereses.csv	OMITIDO	139,Alice Brown,7000,35,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	910	2026-09-20 21:44:18.835976
1178	intereses.csv	OMITIDO	136,Bob Johnson,,,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	911	2026-09-20 21:44:18.837326
1179	intereses.csv	OMITIDO	136,Steve Rogers,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	912	2026-09-20 21:44:18.841076
1180	intereses.csv	OMITIDO	147,Steve Rogers,12000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	915	2026-09-20 21:44:18.842182
1181	intereses.csv	OMITIDO	142,Charlie Green,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	917	2026-09-20 21:44:18.845034
1182	intereses.csv	OMITIDO	143,Jane Smith,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	918	2026-09-20 21:44:18.845905
1183	intereses.csv	OMITIDO	111,John Doe,12000,100,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	920	2026-09-20 21:44:18.846743
1184	intereses.csv	OMITIDO	121,Alice Brown,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	922	2026-09-20 21:44:18.849706
1185	intereses.csv	OMITIDO	107,John Doe,,45,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	923	2026-09-20 21:44:18.850812
1186	intereses.csv	OMITIDO	125,Alice Brown,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	924	2026-09-20 21:44:18.851619
1187	intereses.csv	OMITIDO	116,Diana Prince,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	927	2026-09-20 21:44:18.85437
1188	intereses.csv	OMITIDO	122,Jane Smith,,35,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	929	2026-09-20 21:44:18.855424
1189	intereses.csv	OMITIDO	101,Jane Smith,12000,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	930	2026-09-20 21:44:18.856702
1190	intereses.csv	OMITIDO	103,Bob Johnson,7000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	931	2026-09-20 21:44:18.85757
1191	intereses.csv	OMITIDO	111,John Doe,12000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	932	2026-09-20 21:44:18.860319
1192	intereses.csv	OMITIDO	121,Bob Johnson,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	933	2026-09-20 21:44:18.861199
1193	intereses.csv	OMITIDO	114,Diana Prince,8000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	936	2026-09-20 21:44:18.86192
1194	intereses.csv	OMITIDO	141,Steve Rogers,,40,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	939	2026-09-20 21:44:18.864777
1195	intereses.csv	OMITIDO	129,Steve Rogers,7000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	940	2026-09-20 21:44:18.865637
1196	intereses.csv	OMITIDO	108,Jane Smith,8000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	941	2026-09-20 21:44:18.866483
1197	intereses.csv	OMITIDO	142,Diana Prince,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	943	2026-09-20 21:44:18.869684
1198	intereses.csv	OMITIDO	105,Alice Brown,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	947	2026-09-20 21:44:18.872028
1199	intereses.csv	OMITIDO	127,Charlie Green,8000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	948	2026-09-20 21:44:18.872774
1200	intereses.csv	OMITIDO	149,Bob Johnson,10000,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	949	2026-09-20 21:44:18.873494
1201	intereses.csv	OMITIDO	134,Diana Prince,,45,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	950	2026-09-20 21:44:18.874332
1202	intereses.csv	OMITIDO	148,Charlie Green,12000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	952	2026-09-20 21:44:18.877266
1203	intereses.csv	OMITIDO	115,Bob Johnson,,30,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	953	2026-09-20 21:44:18.878656
1204	intereses.csv	OMITIDO	135,John Doe,10000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	954	2026-09-20 21:44:18.87939
1205	intereses.csv	OMITIDO	113,Jane Smith,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	956	2026-09-20 21:44:18.880123
1206	intereses.csv	OMITIDO	108,Jane Smith,,35,ahorro	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	957	2026-09-20 21:44:18.882486
1207	intereses.csv	OMITIDO	132,Unknown,5000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	961	2026-09-20 21:44:18.883249
1208	intereses.csv	OMITIDO	108,Charlie Green,8000,,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	962	2026-09-20 21:44:18.885736
1209	intereses.csv	OMITIDO	130,John Doe,12000,30,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	964	2026-09-20 21:44:18.886463
1210	intereses.csv	OMITIDO	104,Bob Johnson,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	965	2026-09-20 21:44:18.887162
1211	intereses.csv	OMITIDO	102,Alice Brown,12000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	966	2026-09-20 21:44:18.887856
1212	intereses.csv	OMITIDO	129,Bob Johnson,7000,,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: '' [hilo=batch-flujo-1]	967	2026-09-20 21:44:18.890275
1213	intereses.csv	OMITIDO	123,Charlie Green,,,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	971	2026-09-20 21:44:18.891198
1214	intereses.csv	OMITIDO	107,Diana Prince,5000,45,unknown	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: 'unknown' [hilo=batch-flujo-1]	973	2026-09-20 21:44:18.893659
1215	intereses.csv	OMITIDO	117,Alice Brown,,45,hipoteca	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	976	2026-09-20 21:44:18.894506
1216	intereses.csv	FILTRADO	123,Alice Brown,,25,hipoteca	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	981	2026-09-20 21:44:18.896886
1217	intereses.csv	OMITIDO	129,Jane Smith,,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	977	2026-09-20 21:44:18.900394
1218	intereses.csv	OMITIDO	133,John Doe,7000,150,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	978	2026-09-20 21:44:18.925472
1219	intereses.csv	OMITIDO	113,Jane Smith,,25,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	979	2026-09-20 21:44:18.952142
1220	intereses.csv	OMITIDO	146,Charlie Green,12000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	984	2026-09-20 21:44:18.960642
1221	intereses.csv	OMITIDO	127,Diana Prince,8000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	986	2026-09-20 21:44:18.962285
1222	intereses.csv	FILTRADO	119,John Doe,10000,100,-1	1	calculoInteresesMensualesJob	Registro duplicado, ya procesado en esta ejecucion: fila identica	991	2026-09-20 21:44:18.964799
1223	intereses.csv	OMITIDO	116,Diana Prince,7000,100,ahorro	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	987	2026-09-20 21:44:18.966284
1224	intereses.csv	OMITIDO	126,Charlie Green,7000,100,hipoteca	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	988	2026-09-20 21:44:18.967366
1225	intereses.csv	OMITIDO	135,Alice Brown,7000,,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	989	2026-09-20 21:44:18.968282
1226	intereses.csv	OMITIDO	129,Unknown,7000,35,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	993	2026-09-20 21:44:18.971081
1227	intereses.csv	OMITIDO	116,Alice Brown,10000,30,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	995	2026-09-20 21:44:18.972013
1228	intereses.csv	OMITIDO	101,Charlie Green,8000,100,prestamo	1	calculoInteresesMensualesJob	Edad fuera del rango permitido: 100 (rango permitido 18-99) [hilo=batch-flujo-1]	996	2026-09-20 21:44:18.972875
1229	intereses.csv	OMITIDO	139,Charlie Green,,25,-1	1	calculoInteresesMensualesJob	Tipo fuera del catalogo permitido: '-1' [hilo=batch-flujo-1]	999	2026-09-20 21:44:18.97555
1230	intereses.csv	OMITIDO	114,Steve Rogers,,100,prestamo	1	calculoInteresesMensualesJob	Saldo vacio o no numerico: '' [hilo=batch-flujo-1]	1000	2026-09-20 21:44:18.976289
\.


--
-- Data for Name: resumen_diario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resumen_diario (id, cantidad_anomalias, cantidad_transacciones, fecha, generado_en, job_execution_id, monto_maximo, total_creditos, total_debitos) FROM stdin;
1	0	2	2024-01-01	2026-09-20 21:44:19.106022	1	1200.00	800.00	1200.00
2	0	1	2024-01-02	2026-09-20 21:44:19.106479	1	700.00	700.00	0.00
3	1	2	2024-01-04	2026-09-20 21:44:19.10629	1	800.00	800.00	0.00
4	1	1	2024-01-06	2026-09-20 21:44:19.106332	1	3000.00	0.00	3000.00
5	0	1	2024-01-07	2026-09-20 21:44:19.106309	1	700.00	700.00	0.00
6	0	1	2024-01-08	2026-09-20 21:44:19.106451	1	800.00	800.00	0.00
7	1	1	2024-01-09	2026-09-20 21:44:19.106003	1	3000.00	0.00	3000.00
8	0	1	2024-01-12	2026-09-20 21:44:19.1064	1	1000.00	0.00	1000.00
9	0	1	2024-01-13	2026-09-20 21:44:19.10637	1	1000.00	1000.00	0.00
10	1	3	2024-01-14	2026-09-20 21:44:19.106387	1	800.00	800.00	800.00
11	0	3	2024-01-15	2026-09-20 21:44:19.106327	1	700.00	1200.00	700.00
12	0	1	2024-01-17	2026-09-20 21:44:19.106464	1	800.00	800.00	0.00
13	1	3	2024-01-19	2026-09-20 21:44:19.106264	1	1000.00	1600.00	1000.00
14	1	1	2024-01-20	2026-09-20 21:44:19.106485	1	0.00	0.00	0.00
15	2	4	2024-01-21	2026-09-20 21:44:19.106037	1	3000.00	5500.00	3000.00
16	0	3	2024-01-22	2026-09-20 21:44:19.106262	1	1500.00	2200.00	800.00
17	1	1	2024-01-25	2026-09-20 21:44:19.106416	1	3000.00	3000.00	0.00
18	0	1	2024-01-26	2026-09-20 21:44:19.106388	1	1000.00	1000.00	0.00
19	2	3	2024-01-27	2026-09-20 21:44:19.105997	1	3000.00	3000.00	1200.00
20	1	2	2024-01-28	2026-09-20 21:44:19.106013	1	1500.00	0.00	1500.00
21	1	1	2024-01-29	2026-09-20 21:44:19.106047	1	0.00	0.00	0.00
22	0	1	2024-01-30	2026-09-20 21:44:19.106343	1	500.00	500.00	0.00
23	1	2	2024-01-31	2026-09-20 21:44:19.10628	1	1000.00	1000.00	0.00
24	1	2	2024-02-02	2026-09-20 21:44:19.106167	1	3000.00	3000.00	1200.00
25	1	1	2024-02-06	2026-09-20 21:44:19.106436	1	0.00	0.00	0.00
26	1	1	2024-02-07	2026-09-20 21:44:19.106073	1	0.00	0.00	0.00
27	2	5	2024-02-08	2026-09-20 21:44:19.106001	1	3000.00	1800.00	3800.00
28	0	3	2024-02-09	2026-09-20 21:44:19.106098	1	1200.00	0.00	2700.00
29	1	2	2024-02-10	2026-09-20 21:44:19.106124	1	1200.00	0.00	1200.00
30	0	1	2024-02-11	2026-09-20 21:44:19.10646	1	1000.00	0.00	1000.00
31	0	1	2024-02-15	2026-09-20 21:44:19.10599	1	1500.00	0.00	1500.00
32	0	2	2024-02-16	2026-09-20 21:44:19.106103	1	1200.00	1200.00	700.00
33	0	1	2024-02-17	2026-09-20 21:44:19.106333	1	800.00	0.00	800.00
34	1	2	2024-02-18	2026-09-20 21:44:19.105982	1	1200.00	1200.00	0.00
35	2	2	2024-02-19	2026-09-20 21:44:19.106453	1	3000.00	3000.00	0.00
36	1	2	2024-02-21	2026-09-20 21:44:19.106117	1	3000.00	3000.00	1200.00
37	0	1	2024-02-24	2026-09-20 21:44:19.106405	1	800.00	0.00	800.00
38	0	2	2024-02-27	2026-09-20 21:44:19.106	1	1000.00	1000.00	700.00
39	0	1	2024-02-28	2026-09-20 21:44:19.106418	1	1000.00	1000.00	0.00
40	1	2	2024-02-29	2026-09-20 21:44:19.106424	1	3000.00	1200.00	3000.00
41	0	2	2024-03-01	2026-09-20 21:44:19.1061	1	1500.00	0.00	2300.00
42	0	2	2024-03-02	2026-09-20 21:44:19.106065	1	1500.00	800.00	1500.00
43	1	2	2024-03-03	2026-09-20 21:44:19.106393	1	500.00	500.00	0.00
44	1	4	2024-03-04	2026-09-20 21:44:19.106064	1	800.00	1500.00	800.00
45	1	2	2024-03-05	2026-09-20 21:44:19.106161	1	1200.00	1200.00	0.00
46	0	5	2024-03-07	2026-09-20 21:44:19.10604	1	1500.00	2500.00	2000.00
47	1	1	2024-03-09	2026-09-20 21:44:19.106032	1	0.00	0.00	0.00
48	1	1	2024-03-10	2026-09-20 21:44:19.106106	1	0.00	0.00	0.00
49	0	2	2024-03-11	2026-09-20 21:44:19.106048	1	1200.00	0.00	2000.00
50	0	1	2024-03-12	2026-09-20 21:44:19.106441	1	1500.00	1500.00	0.00
51	0	1	2024-03-13	2026-09-20 21:44:19.106006	1	1000.00	1000.00	0.00
52	0	3	2024-03-14	2026-09-20 21:44:19.106175	1	1500.00	2200.00	1500.00
53	0	5	2024-03-15	2026-09-20 21:44:19.106087	1	1500.00	4500.00	500.00
54	0	2	2024-03-16	2026-09-20 21:44:19.106019	1	1000.00	700.00	1000.00
55	1	1	2024-03-17	2026-09-20 21:44:19.106285	1	0.00	0.00	0.00
56	0	1	2024-03-18	2026-09-20 21:44:19.106401	1	800.00	0.00	800.00
57	0	1	2024-03-20	2026-09-20 21:44:19.106396	1	1000.00	1000.00	0.00
58	0	1	2024-03-22	2026-09-20 21:44:19.106154	1	700.00	0.00	700.00
59	0	2	2024-03-23	2026-09-20 21:44:19.106151	1	1200.00	0.00	2200.00
60	0	1	2024-03-26	2026-09-20 21:44:19.106278	1	1200.00	1200.00	0.00
61	1	1	2024-03-29	2026-09-20 21:44:19.106061	1	3000.00	3000.00	0.00
62	1	1	2024-03-30	2026-09-20 21:44:19.106153	1	0.00	0.00	0.00
63	1	4	2024-03-31	2026-09-20 21:44:19.106166	1	1500.00	1800.00	1500.00
64	2	2	2024-04-01	2026-09-20 21:44:19.106281	1	0.00	0.00	0.00
65	0	1	2024-04-02	2026-09-20 21:44:19.106035	1	1500.00	1500.00	0.00
66	1	2	2024-04-03	2026-09-20 21:44:19.105955	1	1200.00	1200.00	0.00
67	1	1	2024-04-04	2026-09-20 21:44:19.106373	1	3000.00	3000.00	0.00
68	2	4	2024-04-06	2026-09-20 21:44:19.106051	1	1000.00	2600.00	0.00
69	2	3	2024-04-08	2026-09-20 21:44:19.106415	1	3000.00	1000.00	3000.00
70	0	1	2024-04-10	2026-09-20 21:44:19.106227	1	1000.00	0.00	1000.00
71	0	1	2024-04-11	2026-09-20 21:44:19.106413	1	1200.00	1200.00	0.00
72	1	2	2024-04-13	2026-09-20 21:44:19.105976	1	3000.00	4500.00	0.00
73	0	1	2024-04-14	2026-09-20 21:44:19.106341	1	1500.00	1500.00	0.00
74	0	1	2024-04-15	2026-09-20 21:44:19.10629	1	700.00	700.00	0.00
75	2	5	2024-04-16	2026-09-20 21:44:19.106036	1	3000.00	4000.00	2000.00
76	0	1	2024-04-18	2026-09-20 21:44:19.106314	1	800.00	800.00	0.00
77	1	1	2024-04-20	2026-09-20 21:44:19.106467	1	0.00	0.00	0.00
78	0	1	2024-04-22	2026-09-20 21:44:19.106128	1	1500.00	1500.00	0.00
79	1	2	2024-04-23	2026-09-20 21:44:19.106099	1	1200.00	0.00	1200.00
80	1	1	2024-04-24	2026-09-20 21:44:19.10602	1	3000.00	3000.00	0.00
81	0	1	2024-04-25	2026-09-20 21:44:19.106113	1	800.00	0.00	800.00
82	0	1	2024-04-26	2026-09-20 21:44:19.106318	1	1200.00	0.00	1200.00
83	0	1	2024-04-27	2026-09-20 21:44:19.106486	1	1500.00	0.00	1500.00
84	1	1	2024-04-28	2026-09-20 21:44:19.106385	1	0.00	0.00	0.00
85	1	2	2024-04-29	2026-09-20 21:44:19.106111	1	1200.00	0.00	1200.00
86	1	3	2024-04-30	2026-09-20 21:44:19.106284	1	1500.00	1500.00	1000.00
87	1	1	2024-05-01	2026-09-20 21:44:19.106444	1	0.00	0.00	0.00
88	1	1	2024-05-04	2026-09-20 21:44:19.106456	1	3000.00	3000.00	0.00
89	1	1	2024-05-05	2026-09-20 21:44:19.106483	1	0.00	0.00	0.00
90	0	1	2024-05-10	2026-09-20 21:44:19.106017	1	800.00	800.00	0.00
91	0	1	2024-05-12	2026-09-20 21:44:19.106033	1	800.00	0.00	800.00
92	0	1	2024-05-15	2026-09-20 21:44:19.106344	1	1000.00	1000.00	0.00
93	0	2	2024-05-16	2026-09-20 21:44:19.106297	1	1200.00	1200.00	700.00
94	1	2	2024-05-17	2026-09-20 21:44:19.10608	1	3000.00	4200.00	0.00
95	1	4	2024-05-19	2026-09-20 21:44:19.105983	1	1200.00	1800.00	1200.00
96	0	1	2024-05-24	2026-09-20 21:44:19.106133	1	800.00	800.00	0.00
97	2	4	2024-05-25	2026-09-20 21:44:19.106085	1	800.00	0.00	2300.00
98	0	1	2024-05-26	2026-09-20 21:44:19.106067	1	500.00	0.00	500.00
99	1	3	2024-05-27	2026-09-20 21:44:19.106046	1	3000.00	1000.00	4000.00
100	0	1	2024-05-28	2026-09-20 21:44:19.106459	1	700.00	0.00	700.00
101	1	4	2024-05-29	2026-09-20 21:44:19.106322	1	1200.00	700.00	2200.00
102	0	2	2024-05-30	2026-09-20 21:44:19.106265	1	1000.00	1000.00	800.00
103	0	2	2024-05-31	2026-09-20 21:44:19.106276	1	1500.00	2200.00	0.00
104	0	1	2024-06-01	2026-09-20 21:44:19.106247	1	1500.00	1500.00	0.00
105	1	2	2024-06-02	2026-09-20 21:44:19.106122	1	800.00	800.00	0.00
106	1	1	2024-06-04	2026-09-20 21:44:19.106476	1	3000.00	3000.00	0.00
107	0	1	2024-06-05	2026-09-20 21:44:19.106455	1	500.00	0.00	500.00
108	0	1	2024-06-07	2026-09-20 21:44:19.106443	1	1200.00	1200.00	0.00
109	0	2	2024-06-08	2026-09-20 21:44:19.106404	1	1500.00	1500.00	700.00
110	0	2	2024-06-09	2026-09-20 21:44:19.106004	1	1000.00	1000.00	700.00
111	1	1	2024-06-10	2026-09-20 21:44:19.106411	1	3000.00	0.00	3000.00
112	0	1	2024-06-11	2026-09-20 21:44:19.106466	1	1500.00	1500.00	0.00
113	0	2	2024-06-12	2026-09-20 21:44:19.105981	1	1200.00	700.00	1200.00
114	0	1	2024-06-13	2026-09-20 21:44:19.106091	1	800.00	0.00	800.00
115	0	1	2024-06-14	2026-09-20 21:44:19.106398	1	700.00	700.00	0.00
116	2	4	2024-06-15	2026-09-20 21:44:19.106114	1	1500.00	0.00	4000.00
117	1	1	2024-06-16	2026-09-20 21:44:19.106323	1	0.00	0.00	0.00
118	1	2	2024-06-17	2026-09-20 21:44:19.105958	1	3000.00	0.00	3800.00
119	1	2	2024-06-19	2026-09-20 21:44:19.106427	1	1500.00	0.00	1500.00
120	1	3	2024-06-22	2026-09-20 21:44:19.106315	1	3000.00	500.00	4000.00
121	1	1	2024-06-23	2026-09-20 21:44:19.106478	1	3000.00	3000.00	0.00
122	0	2	2024-06-26	2026-09-20 21:44:19.10613	1	700.00	0.00	1200.00
123	0	3	2024-06-27	2026-09-20 21:44:19.106389	1	1200.00	700.00	1700.00
124	1	1	2024-06-28	2026-09-20 21:44:19.106421	1	0.00	0.00	0.00
125	2	6	2024-06-29	2026-09-20 21:44:19.105993	1	1200.00	2900.00	2200.00
126	1	2	2024-06-30	2026-09-20 21:44:19.10593	1	3000.00	3000.00	1000.00
127	2	2	2024-07-02	2026-09-20 21:44:19.105996	1	0.00	0.00	0.00
128	1	2	2024-07-03	2026-09-20 21:44:19.106115	1	1000.00	0.00	1000.00
129	0	1	2024-07-05	2026-09-20 21:44:19.106038	1	800.00	0.00	800.00
130	1	3	2024-07-06	2026-09-20 21:44:19.106287	1	800.00	800.00	800.00
131	0	2	2024-07-08	2026-09-20 21:44:19.106139	1	1000.00	800.00	1000.00
132	1	4	2024-07-09	2026-09-20 21:44:19.106182	1	1200.00	2700.00	0.00
133	0	1	2024-07-10	2026-09-20 21:44:19.106337	1	1200.00	1200.00	0.00
134	1	2	2024-07-11	2026-09-20 21:44:19.105993	1	3000.00	4000.00	0.00
135	0	1	2024-07-12	2026-09-20 21:44:19.106326	1	1200.00	0.00	1200.00
136	0	2	2024-07-13	2026-09-20 21:44:19.106165	1	1500.00	2300.00	0.00
137	2	4	2024-07-14	2026-09-20 21:44:19.106056	1	3000.00	700.00	3700.00
138	0	1	2024-07-15	2026-09-20 21:44:19.106409	1	800.00	0.00	800.00
139	0	1	2024-07-17	2026-09-20 21:44:19.105977	1	500.00	0.00	500.00
140	0	3	2024-07-20	2026-09-20 21:44:19.105975	1	1200.00	700.00	1900.00
141	0	1	2024-07-21	2026-09-20 21:44:19.106041	1	1500.00	1500.00	0.00
142	1	2	2024-07-22	2026-09-20 21:44:19.106174	1	700.00	0.00	700.00
143	0	1	2024-07-23	2026-09-20 21:44:19.106488	1	700.00	0.00	700.00
144	2	4	2024-07-24	2026-09-20 21:44:19.106049	1	1200.00	0.00	3400.00
145	1	4	2024-07-25	2026-09-20 21:44:19.105987	1	1500.00	4200.00	1000.00
146	0	2	2024-07-26	2026-09-20 21:44:19.106088	1	1500.00	0.00	2300.00
147	1	5	2024-07-27	2026-09-20 21:44:19.106021	1	3000.00	1900.00	5000.00
148	1	4	2024-07-28	2026-09-20 21:44:19.10598	1	3000.00	2500.00	3800.00
149	0	2	2024-07-29	2026-09-20 21:44:19.105992	1	1000.00	1500.00	0.00
150	2	2	2024-07-30	2026-09-20 21:44:19.105969	1	3000.00	0.00	6000.00
151	0	1	2024-07-31	2026-09-20 21:44:19.106008	1	700.00	0.00	700.00
152	1	2	2024-08-01	2026-09-20 21:44:19.105991	1	800.00	800.00	0.00
153	0	1	2024-08-02	2026-09-20 21:44:19.106484	1	1200.00	0.00	1200.00
154	0	2	2024-08-03	2026-09-20 21:44:19.10626	1	1500.00	1500.00	1000.00
155	0	1	2024-08-06	2026-09-20 21:44:19.106273	1	1200.00	0.00	1200.00
156	0	1	2024-08-07	2026-09-20 21:44:19.106377	1	1500.00	1500.00	0.00
157	2	2	2024-08-08	2026-09-20 21:44:19.106092	1	0.00	0.00	0.00
158	0	4	2024-08-09	2026-09-20 21:44:19.105995	1	1500.00	2200.00	1700.00
159	1	1	2024-08-10	2026-09-20 21:44:19.10634	1	3000.00	3000.00	0.00
160	1	2	2024-08-11	2026-09-20 21:44:19.106417	1	800.00	0.00	800.00
161	2	3	2024-08-12	2026-09-20 21:44:19.106137	1	3000.00	3000.00	800.00
162	1	1	2024-08-13	2026-09-20 21:44:19.106475	1	0.00	0.00	0.00
163	2	3	2024-08-14	2026-09-20 21:44:19.106005	1	3000.00	1400.00	3000.00
164	0	1	2024-08-15	2026-09-20 21:44:19.106412	1	1500.00	0.00	1500.00
165	1	2	2024-08-16	2026-09-20 21:44:19.105979	1	3000.00	800.00	3000.00
166	1	5	2024-08-17	2026-09-20 21:44:19.106028	1	3000.00	0.00	7200.00
167	0	1	2024-08-19	2026-09-20 21:44:19.106045	1	700.00	0.00	700.00
168	1	3	2024-08-20	2026-09-20 21:44:19.105988	1	1200.00	800.00	1200.00
169	1	1	2024-08-21	2026-09-20 21:44:19.106271	1	0.00	0.00	0.00
170	1	3	2024-08-22	2026-09-20 21:44:19.106054	1	1200.00	0.00	2000.00
171	1	1	2024-08-24	2026-09-20 21:44:19.106074	1	0.00	0.00	0.00
172	0	1	2024-08-26	2026-09-20 21:44:19.106313	1	1500.00	0.00	1500.00
173	0	1	2024-08-27	2026-09-20 21:44:19.106414	1	1500.00	1500.00	0.00
174	0	2	2024-08-28	2026-09-20 21:44:19.106105	1	800.00	1300.00	0.00
175	0	1	2024-08-29	2026-09-20 21:44:19.106386	1	1500.00	0.00	1500.00
176	0	1	2024-08-31	2026-09-20 21:44:19.106168	1	1200.00	0.00	1200.00
177	0	2	2024-09-01	2026-09-20 21:44:19.106068	1	1500.00	0.00	2700.00
178	0	1	2024-09-02	2026-09-20 21:44:19.106306	1	1200.00	0.00	1200.00
179	1	1	2024-09-03	2026-09-20 21:44:19.106145	1	0.00	0.00	0.00
180	0	1	2024-09-04	2026-09-20 21:44:19.106172	1	700.00	0.00	700.00
181	0	2	2024-09-06	2026-09-20 21:44:19.105999	1	1000.00	700.00	1000.00
182	0	1	2024-09-08	2026-09-20 21:44:19.106422	1	800.00	0.00	800.00
183	2	3	2024-09-09	2026-09-20 21:44:19.106201	1	500.00	500.00	0.00
184	1	2	2024-09-13	2026-09-20 21:44:19.106016	1	700.00	700.00	0.00
185	1	1	2024-09-15	2026-09-20 21:44:19.106288	1	0.00	0.00	0.00
186	0	3	2024-09-16	2026-09-20 21:44:19.106052	1	1500.00	2000.00	700.00
187	1	1	2024-09-17	2026-09-20 21:44:19.106018	1	3000.00	0.00	3000.00
188	0	1	2024-09-18	2026-09-20 21:44:19.106428	1	1200.00	1200.00	0.00
189	1	2	2024-09-19	2026-09-20 21:44:19.106089	1	3000.00	3000.00	700.00
190	0	1	2024-09-20	2026-09-20 21:44:19.106148	1	1000.00	1000.00	0.00
191	1	1	2024-09-21	2026-09-20 21:44:19.106044	1	0.00	0.00	0.00
192	0	1	2024-09-23	2026-09-20 21:44:19.106403	1	1000.00	0.00	1000.00
193	0	2	2024-09-25	2026-09-20 21:44:19.106039	1	1200.00	2200.00	0.00
194	2	2	2024-09-26	2026-09-20 21:44:19.106378	1	3000.00	3000.00	0.00
195	0	1	2024-09-27	2026-09-20 21:44:19.106142	1	800.00	800.00	0.00
196	1	1	2024-09-28	2026-09-20 21:44:19.106104	1	0.00	0.00	0.00
197	0	2	2024-09-29	2026-09-20 21:44:19.106058	1	700.00	700.00	700.00
198	0	3	2024-09-30	2026-09-20 21:44:19.10618	1	1000.00	1700.00	800.00
199	1	3	2024-10-01	2026-09-20 21:44:19.106107	1	3000.00	5700.00	0.00
200	2	3	2024-10-02	2026-09-20 21:44:19.106177	1	3000.00	0.00	3700.00
201	0	1	2024-10-03	2026-09-20 21:44:19.106149	1	1500.00	1500.00	0.00
202	0	1	2024-10-04	2026-09-20 21:44:19.106316	1	800.00	0.00	800.00
203	0	2	2024-10-05	2026-09-20 21:44:19.105974	1	1500.00	1500.00	1200.00
204	0	1	2024-10-06	2026-09-20 21:44:19.106406	1	800.00	800.00	0.00
205	1	1	2024-10-08	2026-09-20 21:44:19.10616	1	3000.00	0.00	3000.00
206	1	2	2024-10-09	2026-09-20 21:44:19.106118	1	3000.00	1200.00	3000.00
207	1	4	2024-10-10	2026-09-20 21:44:19.1064	1	3000.00	1500.00	5500.00
208	0	1	2024-10-11	2026-09-20 21:44:19.10641	1	1000.00	1000.00	0.00
209	1	1	2024-10-13	2026-09-20 21:44:19.106408	1	3000.00	0.00	3000.00
210	1	2	2024-10-14	2026-09-20 21:44:19.106442	1	1000.00	0.00	2000.00
211	1	2	2024-10-15	2026-09-20 21:44:19.10631	1	3000.00	3000.00	500.00
212	2	5	2024-10-16	2026-09-20 21:44:19.106135	1	1500.00	700.00	3700.00
213	0	1	2024-10-17	2026-09-20 21:44:19.106121	1	800.00	0.00	800.00
214	1	1	2024-10-18	2026-09-20 21:44:19.106331	1	3000.00	0.00	3000.00
215	1	1	2024-10-19	2026-09-20 21:44:19.10615	1	3000.00	3000.00	0.00
216	0	2	2024-10-21	2026-09-20 21:44:19.106163	1	700.00	700.00	700.00
217	1	2	2024-10-22	2026-09-20 21:44:19.106075	1	3000.00	700.00	3000.00
218	1	1	2024-10-23	2026-09-20 21:44:19.106277	1	0.00	0.00	0.00
219	0	2	2024-10-24	2026-09-20 21:44:19.106072	1	1200.00	1200.00	700.00
220	1	1	2024-10-25	2026-09-20 21:44:19.106481	1	0.00	0.00	0.00
221	1	1	2024-10-26	2026-09-20 21:44:19.105995	1	3000.00	0.00	3000.00
222	0	1	2024-10-27	2026-09-20 21:44:19.106375	1	1500.00	0.00	1500.00
223	0	2	2024-10-29	2026-09-20 21:44:19.106446	1	1500.00	0.00	2300.00
224	0	1	2024-10-30	2026-09-20 21:44:19.10644	1	1500.00	1500.00	0.00
225	2	3	2024-10-31	2026-09-20 21:44:19.106301	1	3000.00	3000.00	500.00
226	0	1	2024-11-01	2026-09-20 21:44:19.106084	1	1500.00	0.00	1500.00
227	0	1	2024-11-04	2026-09-20 21:44:19.106455	1	1500.00	1500.00	0.00
228	1	1	2024-11-05	2026-09-20 21:44:19.10633	1	3000.00	3000.00	0.00
229	0	2	2024-11-06	2026-09-20 21:44:19.106171	1	1500.00	700.00	1500.00
230	1	2	2024-11-07	2026-09-20 21:44:19.106024	1	3000.00	1000.00	3000.00
231	1	1	2024-11-08	2026-09-20 21:44:19.106308	1	0.00	0.00	0.00
232	0	1	2024-11-09	2026-09-20 21:44:19.106413	1	1000.00	1000.00	0.00
233	0	3	2024-11-10	2026-09-20 21:44:19.106007	1	1000.00	1500.00	1000.00
234	1	3	2024-11-11	2026-09-20 21:44:19.105968	1	1500.00	3500.00	0.00
235	0	1	2024-11-12	2026-09-20 21:44:19.106268	1	700.00	700.00	0.00
236	2	3	2024-11-13	2026-09-20 21:44:19.105985	1	700.00	0.00	700.00
237	1	1	2024-11-14	2026-09-20 21:44:19.106347	1	3000.00	3000.00	0.00
238	2	2	2024-11-15	2026-09-20 21:44:19.106094	1	3000.00	0.00	3000.00
239	1	1	2024-11-16	2026-09-20 21:44:19.106014	1	0.00	0.00	0.00
240	0	3	2024-11-17	2026-09-20 21:44:19.106144	1	1200.00	0.00	2700.00
241	1	2	2024-11-18	2026-09-20 21:44:19.106293	1	1500.00	3000.00	0.00
242	1	1	2024-11-19	2026-09-20 21:44:19.106057	1	3000.00	0.00	3000.00
243	1	1	2024-11-20	2026-09-20 21:44:19.106096	1	3000.00	0.00	3000.00
244	1	3	2024-11-22	2026-09-20 21:44:19.106338	1	1500.00	0.00	2700.00
245	1	2	2024-11-23	2026-09-20 21:44:19.106317	1	1000.00	0.00	1000.00
246	1	1	2024-11-25	2026-09-20 21:44:19.106015	1	0.00	0.00	0.00
247	1	2	2024-11-26	2026-09-20 21:44:19.106129	1	1000.00	1000.00	0.00
248	0	2	2024-11-29	2026-09-20 21:44:19.10638	1	1200.00	0.00	2000.00
249	2	2	2024-11-30	2026-09-20 21:44:19.105978	1	0.00	0.00	0.00
250	0	1	2024-12-01	2026-09-20 21:44:19.106425	1	700.00	0.00	700.00
251	0	1	2024-12-02	2026-09-20 21:44:19.106181	1	1000.00	1000.00	0.00
252	0	2	2024-12-04	2026-09-20 21:44:19.106093	1	1000.00	0.00	1800.00
253	0	2	2024-12-07	2026-09-20 21:44:19.106391	1	1200.00	1200.00	1000.00
254	0	1	2024-12-09	2026-09-20 21:44:19.106472	1	1000.00	1000.00	0.00
255	0	1	2024-12-10	2026-09-20 21:44:19.106178	1	1000.00	0.00	1000.00
256	1	2	2024-12-11	2026-09-20 21:44:19.105983	1	3000.00	1200.00	3000.00
257	2	4	2024-12-12	2026-09-20 21:44:19.105986	1	700.00	0.00	1200.00
258	0	1	2024-12-14	2026-09-20 21:44:19.106457	1	1500.00	1500.00	0.00
259	1	1	2024-12-16	2026-09-20 21:44:19.106131	1	3000.00	0.00	3000.00
260	1	1	2024-12-17	2026-09-20 21:44:19.10617	1	0.00	0.00	0.00
261	1	2	2024-12-18	2026-09-20 21:44:19.106027	1	3000.00	3800.00	0.00
262	1	3	2024-12-20	2026-09-20 21:44:19.106109	1	3000.00	4700.00	0.00
263	0	1	2024-12-22	2026-09-20 21:44:19.106026	1	1000.00	1000.00	0.00
264	0	1	2024-12-26	2026-09-20 21:44:19.106184	1	1200.00	0.00	1200.00
265	0	1	2024-12-27	2026-09-20 21:44:19.106452	1	1200.00	0.00	1200.00
266	1	2	2024-12-29	2026-09-20 21:44:19.10609	1	700.00	700.00	0.00
267	3	5	2024-12-30	2026-09-20 21:44:19.105984	1	3000.00	3000.00	3800.00
\.


--
-- Data for Name: transaccion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaccion (id, anomalia, fecha, id_origen, job_execution_id, monto, observacion, procesado_en, tipo) FROM stdin;
1	t	2024-06-30	1	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:16.928711	credito
2	f	2024-04-03	2	1	1200.00	Fecha normalizada desde el formato legacy '03-04-2024'	2026-09-20 21:44:16.9288	credito
3	f	2024-06-17	5	1	800.00	Fecha normalizada desde el formato legacy '17-06-2024'	2026-09-20 21:44:16.928903	debito
4	f	2024-11-11	6	1	1500.00	Fecha normalizada desde el formato legacy '11/11/2024'	2026-09-20 21:44:16.981954	credito
5	t	2024-07-30	8	1	3000.00	Fecha normalizada desde el formato legacy '30-07-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:16.982089	debito
6	f	2024-10-05	11	1	1200.00	Fecha normalizada desde el formato legacy '2024/10/05'	2026-09-20 21:44:16.997133	debito
7	f	2024-07-20	12	1	1200.00	Fecha normalizada desde el formato legacy '20/07/2024'	2026-09-20 21:44:16.997219	debito
8	t	2024-04-13	13	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:16.997285	credito
9	f	2024-07-17	14	1	500.00	Fecha normalizada desde el formato legacy '17/07/2024'	2026-09-20 21:44:16.997369	debito
10	t	2024-11-30	18	1	-100.00	Monto no positivo	2026-09-20 21:44:17.007511	credito
11	f	2024-08-16	19	1	800.00	Fecha normalizada desde el formato legacy '16/08/2024'	2026-09-20 21:44:17.007612	credito
12	t	2024-07-28	20	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.007682	debito
13	f	2024-06-12	21	1	700.00	Fecha normalizada desde el formato legacy '12-06-2024'	2026-09-20 21:44:17.022028	credito
14	t	2024-02-18	24	1	0.00	Fecha normalizada desde el formato legacy '18/02/2024'; Monto no positivo	2026-09-20 21:44:17.022236	credito
15	f	2024-05-19	26	1	1200.00	Fecha normalizada desde el formato legacy '19/05/2024'	2026-09-20 21:44:17.037727	debito
16	f	2024-12-11	27	1	1200.00	\N	2026-09-20 21:44:17.037806	credito
17	f	2024-12-30	33	1	1500.00	Fecha normalizada desde el formato legacy '30/12/2024'	2026-09-20 21:44:17.049641	credito
18	t	2024-11-13	34	1	-200.00	Fecha normalizada desde el formato legacy '13-11-2024'; Monto no positivo	2026-09-20 21:44:17.049738	credito
19	t	2024-12-12	35	1	-100.00	Fecha normalizada desde el formato legacy '2024/12/12'; Monto no positivo	2026-09-20 21:44:17.049827	credito
20	f	2024-07-25	36	1	1500.00	Fecha normalizada desde el formato legacy '25-07-2024'	2026-09-20 21:44:17.059621	credito
21	f	2024-08-20	37	1	800.00	\N	2026-09-20 21:44:17.059673	credito
22	f	2024-02-15	38	1	1500.00	Fecha normalizada desde el formato legacy '2024/02/15'	2026-09-20 21:44:17.059724	debito
23	f	2024-08-01	41	1	800.00	Fecha normalizada desde el formato legacy '01/08/2024'	2026-09-20 21:44:17.081024	credito
24	f	2024-07-29	42	1	500.00	Fecha normalizada desde el formato legacy '29/07/2024'	2026-09-20 21:44:17.081098	credito
25	f	2024-07-11	44	1	1000.00	Fecha normalizada desde el formato legacy '2024/07/11'	2026-09-20 21:44:17.081157	credito
26	f	2024-06-29	46	1	1200.00	Fecha normalizada desde el formato legacy '2024/06/29'	2026-09-20 21:44:17.091328	debito
27	f	2024-08-09	48	1	1500.00	\N	2026-09-20 21:44:17.091369	credito
28	t	2024-10-26	49	1	3000.00	Fecha normalizada desde el formato legacy '2024/10/26'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.091422	debito
29	t	2024-07-02	51	1	-200.00	Fecha normalizada desde el formato legacy '02/07/2024'; Monto no positivo	2026-09-20 21:44:17.114806	credito
30	t	2024-01-27	55	1	3000.00	Fecha normalizada desde el formato legacy '27-01-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.114867	credito
31	f	2024-09-06	56	1	1000.00	Fecha normalizada desde el formato legacy '06-09-2024'	2026-09-20 21:44:17.1266	debito
32	f	2024-02-27	58	1	1000.00	Fecha normalizada desde el formato legacy '2024/02/27'	2026-09-20 21:44:17.126702	credito
33	f	2024-02-08	59	1	800.00	Fecha normalizada desde el formato legacy '08/02/2024'	2026-09-20 21:44:17.126972	credito
34	t	2024-01-09	61	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.147248	debito
35	f	2024-06-09	62	1	1000.00	\N	2026-09-20 21:44:17.147393	credito
36	f	2024-08-14	63	1	700.00	\N	2026-09-20 21:44:17.14749	credito
37	f	2024-03-13	64	1	1000.00	Fecha normalizada desde el formato legacy '13-03-2024'	2026-09-20 21:44:17.147558	credito
38	f	2024-11-10	67	1	800.00	Fecha normalizada desde el formato legacy '10-11-2024'	2026-09-20 21:44:17.155777	credito
39	f	2024-07-31	71	1	700.00	Fecha normalizada desde el formato legacy '2024/07/31'	2026-09-20 21:44:17.172676	debito
40	f	2024-07-29	73	1	1000.00	Fecha normalizada desde el formato legacy '29-07-2024'	2026-09-20 21:44:17.172739	credito
41	f	2024-01-28	75	1	1500.00	Fecha normalizada desde el formato legacy '28-01-2024'	2026-09-20 21:44:17.172799	debito
42	t	2024-11-16	76	1	-200.00	Fecha normalizada desde el formato legacy '16/11/2024'; Monto no positivo	2026-09-20 21:44:17.186595	credito
43	t	2024-11-25	78	1	-200.00	Fecha normalizada desde el formato legacy '2024/11/25'; Monto no positivo	2026-09-20 21:44:17.186783	credito
44	f	2024-09-13	82	1	700.00	Fecha normalizada desde el formato legacy '13/09/2024'	2026-09-20 21:44:17.19653	credito
45	f	2024-05-10	83	1	800.00	Fecha normalizada desde el formato legacy '10-05-2024'	2026-09-20 21:44:17.19657	credito
46	t	2024-09-17	84	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.196597	debito
47	f	2024-03-16	85	1	1000.00	Fecha normalizada desde el formato legacy '2024/03/16'	2026-09-20 21:44:17.196622	debito
48	t	2024-04-24	88	1	3000.00	Fecha normalizada desde el formato legacy '2024/04/24'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.211325	credito
49	f	2024-07-27	89	1	800.00	Fecha normalizada desde el formato legacy '27/07/2024'	2026-09-20 21:44:17.211367	debito
50	f	2024-01-01	91	1	800.00	Fecha normalizada desde el formato legacy '01-01-2024'	2026-09-20 21:44:17.220259	credito
51	f	2024-01-27	92	1	1200.00	Fecha normalizada desde el formato legacy '27/01/2024'	2026-09-20 21:44:17.220294	debito
52	t	2024-11-07	93	1	3000.00	Fecha normalizada desde el formato legacy '07-11-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.220318	debito
53	t	2024-08-01	94	1	-200.00	Fecha normalizada desde el formato legacy '01-08-2024'; Monto no positivo	2026-09-20 21:44:17.220341	credito
54	f	2024-12-22	95	1	1000.00	Fecha normalizada desde el formato legacy '22/12/2024'	2026-09-20 21:44:17.220374	credito
55	f	2024-12-18	96	1	800.00	Fecha normalizada desde el formato legacy '2024/12/18'	2026-09-20 21:44:17.231745	credito
56	f	2024-08-17	97	1	500.00	Fecha normalizada desde el formato legacy '17/08/2024'	2026-09-20 21:44:17.231775	debito
57	t	2024-03-09	99	1	-200.00	Fecha normalizada desde el formato legacy '2024/03/09'; Monto no positivo	2026-09-20 21:44:17.2318	credito
58	f	2024-05-12	101	1	800.00	Fecha normalizada desde el formato legacy '12-05-2024'	2026-09-20 21:44:17.241296	debito
59	t	2024-11-13	102	1	-200.00	Fecha normalizada desde el formato legacy '13-11-2024'; Monto no positivo	2026-09-20 21:44:17.241318	debito
60	f	2024-04-02	103	1	1500.00	Fecha normalizada desde el formato legacy '2024/04/02'	2026-09-20 21:44:17.241336	credito
61	f	2024-04-16	104	1	1000.00	\N	2026-09-20 21:44:17.241349	credito
62	f	2024-01-21	106	1	1000.00	Fecha normalizada desde el formato legacy '2024/01/21'	2026-09-20 21:44:17.256709	credito
63	f	2024-07-05	110	1	800.00	Fecha normalizada desde el formato legacy '05/07/2024'	2026-09-20 21:44:17.256741	debito
64	f	2024-09-25	111	1	1000.00	Fecha normalizada desde el formato legacy '25-09-2024'	2026-09-20 21:44:17.268284	credito
65	f	2024-03-07	112	1	800.00	\N	2026-09-20 21:44:17.268299	credito
66	f	2024-07-21	113	1	1500.00	Fecha normalizada desde el formato legacy '21/07/2024'	2026-09-20 21:44:17.268317	credito
67	f	2024-07-20	115	1	700.00	Fecha normalizada desde el formato legacy '2024/07/20'	2026-09-20 21:44:17.268345	debito
68	f	2024-11-10	117	1	700.00	Fecha normalizada desde el formato legacy '10-11-2024'	2026-09-20 21:44:17.277773	credito
69	t	2024-09-21	120	1	-200.00	Fecha normalizada desde el formato legacy '21-09-2024'; Monto no positivo	2026-09-20 21:44:17.277908	credito
70	f	2024-08-19	121	1	700.00	Fecha normalizada desde el formato legacy '2024/08/19'	2026-09-20 21:44:17.294517	debito
71	t	2024-05-27	123	1	3000.00	Fecha normalizada desde el formato legacy '2024/05/27'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.294552	debito
72	t	2024-01-29	125	1	-200.00	Fecha normalizada desde el formato legacy '2024/01/29'; Monto no positivo	2026-09-20 21:44:17.294586	credito
73	f	2024-03-11	126	1	800.00	Fecha normalizada desde el formato legacy '2024/03/11'	2026-09-20 21:44:17.305978	debito
74	f	2024-07-24	130	1	1200.00	Fecha normalizada desde el formato legacy '2024/07/24'	2026-09-20 21:44:17.306008	debito
75	f	2024-07-25	131	1	1000.00	\N	2026-09-20 21:44:17.35826	debito
76	f	2024-04-06	134	1	800.00	Fecha normalizada desde el formato legacy '2024/04/06'	2026-09-20 21:44:17.358303	credito
77	f	2024-09-16	139	1	700.00	\N	2026-09-20 21:44:17.424491	debito
78	f	2024-08-22	140	1	1200.00	Fecha normalizada desde el formato legacy '22/08/2024'	2026-09-20 21:44:17.42463	debito
79	t	2024-07-14	141	1	3000.00	Fecha normalizada desde el formato legacy '14/07/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.438374	debito
80	t	2024-11-19	142	1	3000.00	Fecha normalizada desde el formato legacy '19-11-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.438404	debito
81	f	2024-09-29	143	1	700.00	\N	2026-09-20 21:44:17.438466	credito
82	t	2024-12-30	144	1	3000.00	Fecha normalizada desde el formato legacy '30/12/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.438491	debito
83	f	2024-01-01	145	1	1200.00	Fecha normalizada desde el formato legacy '2024/01/01'	2026-09-20 21:44:17.438509	debito
84	t	2024-03-29	147	1	3000.00	Fecha normalizada desde el formato legacy '2024/03/29'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.444667	credito
85	t	2024-12-18	151	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.458936	credito
86	f	2024-07-28	153	1	1000.00	Fecha normalizada desde el formato legacy '2024/07/28'	2026-09-20 21:44:17.458956	credito
87	f	2024-03-04	154	1	800.00	\N	2026-09-20 21:44:17.458969	credito
88	f	2024-03-02	156	1	1500.00	\N	2026-09-20 21:44:17.467875	debito
89	t	2024-08-17	157	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.467889	debito
90	f	2024-05-26	158	1	500.00	Fecha normalizada desde el formato legacy '26-05-2024'	2026-09-20 21:44:17.467909	debito
91	f	2024-09-01	159	1	1200.00	Fecha normalizada desde el formato legacy '01/09/2024'	2026-09-20 21:44:17.467927	debito
92	f	2024-07-28	161	1	1500.00	Fecha normalizada desde el formato legacy '28/07/2024'	2026-09-20 21:44:17.476336	credito
93	t	2024-12-11	162	1	3000.00	Fecha normalizada desde el formato legacy '11-12-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.476353	debito
94	t	2024-04-06	166	1	800.00	Fecha normalizada desde el formato legacy '2024/04/06'; Posible duplicado por contenido	2026-09-20 21:44:17.48883	credito
95	f	2024-10-24	168	1	1200.00	\N	2026-09-20 21:44:17.488844	credito
96	t	2024-02-07	172	1	0.00	Monto no positivo	2026-09-20 21:44:17.503331	debito
97	t	2024-08-24	173	1	-100.00	Fecha normalizada desde el formato legacy '24-08-2024'; Monto no positivo	2026-09-20 21:44:17.503346	debito
98	t	2024-10-22	177	1	3000.00	Fecha normalizada desde el formato legacy '22/10/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.514697	debito
99	t	2024-05-17	178	1	3000.00	Fecha normalizada desde el formato legacy '2024/05/17'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.514737	credito
100	t	2024-07-11	179	1	3000.00	Fecha normalizada desde el formato legacy '2024/07/11'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.514803	credito
101	f	2024-03-02	182	1	800.00	Fecha normalizada desde el formato legacy '2024/03/02'	2026-09-20 21:44:17.524212	credito
102	t	2024-01-21	183	1	3000.00	Fecha normalizada desde el formato legacy '21-01-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.524233	credito
103	f	2024-11-01	184	1	1500.00	Fecha normalizada desde el formato legacy '01-11-2024'	2026-09-20 21:44:17.524246	debito
104	f	2024-05-25	187	1	800.00	Fecha normalizada desde el formato legacy '2024/05/25'	2026-09-20 21:44:17.534957	debito
105	f	2024-03-15	188	1	500.00	Fecha normalizada desde el formato legacy '2024/03/15'	2026-09-20 21:44:17.534974	debito
106	f	2024-07-26	190	1	1500.00	Fecha normalizada desde el formato legacy '26/07/2024'	2026-09-20 21:44:17.534998	debito
107	f	2024-09-19	192	1	700.00	\N	2026-09-20 21:44:17.545203	debito
108	t	2024-12-29	194	1	-200.00	Fecha normalizada desde el formato legacy '2024/12/29'; Monto no positivo	2026-09-20 21:44:17.545227	credito
109	f	2024-06-13	195	1	800.00	Fecha normalizada desde el formato legacy '13-06-2024'	2026-09-20 21:44:17.545246	debito
110	t	2024-08-08	196	1	-200.00	Fecha normalizada desde el formato legacy '08-08-2024'; Monto no positivo	2026-09-20 21:44:17.554426	credito
111	f	2024-02-18	197	1	1200.00	Fecha normalizada desde el formato legacy '18-02-2024'	2026-09-20 21:44:17.55444	credito
112	f	2024-12-04	198	1	800.00	\N	2026-09-20 21:44:17.554449	debito
113	t	2024-11-15	201	1	-200.00	Fecha normalizada desde el formato legacy '15-11-2024'; Monto no positivo	2026-09-20 21:44:17.564946	credito
114	f	2024-04-16	204	1	1200.00	Fecha normalizada desde el formato legacy '2024/04/16'	2026-09-20 21:44:17.56496	debito
115	t	2024-11-20	206	1	3000.00	Fecha normalizada desde el formato legacy '2024/11/20'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.577644	debito
116	t	2024-02-08	207	1	3000.00	Fecha normalizada desde el formato legacy '08/02/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.577708	debito
117	f	2024-02-09	210	1	700.00	Fecha normalizada desde el formato legacy '2024/02/09'	2026-09-20 21:44:17.577833	debito
118	f	2024-04-23	212	1	1200.00	Fecha normalizada desde el formato legacy '23/04/2024'	2026-09-20 21:44:17.587734	debito
119	t	2024-07-30	213	1	3000.00	Fecha normalizada desde el formato legacy '30/07/2024'; Monto atipico sobre el umbral de revision (2500); Posible duplicado por contenido	2026-09-20 21:44:17.587838	debito
120	f	2024-03-01	215	1	1500.00	Fecha normalizada desde el formato legacy '01/03/2024'	2026-09-20 21:44:17.587912	debito
121	f	2024-03-16	217	1	700.00	\N	2026-09-20 21:44:17.598072	credito
122	f	2024-02-16	218	1	1200.00	Fecha normalizada desde el formato legacy '2024/02/16'	2026-09-20 21:44:17.598096	credito
123	t	2024-09-28	219	1	0.00	Monto no positivo	2026-09-20 21:44:17.598223	credito
124	f	2024-08-28	220	1	500.00	Fecha normalizada desde el formato legacy '28/08/2024'	2026-09-20 21:44:17.598287	credito
125	t	2024-03-10	222	1	-100.00	Monto no positivo	2026-09-20 21:44:17.604645	debito
126	t	2024-10-01	223	1	3000.00	Fecha normalizada desde el formato legacy '2024/10/01'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.604658	credito
127	f	2024-12-20	224	1	500.00	Fecha normalizada desde el formato legacy '2024/12/20'	2026-09-20 21:44:17.604669	credito
128	t	2024-04-29	226	1	-200.00	Fecha normalizada desde el formato legacy '2024/04/29'; Monto no positivo	2026-09-20 21:44:17.614468	debito
129	f	2024-04-25	227	1	800.00	Fecha normalizada desde el formato legacy '25-04-2024'	2026-09-20 21:44:17.614487	debito
130	f	2024-06-15	233	1	1000.00	Fecha normalizada desde el formato legacy '15-06-2024'	2026-09-20 21:44:17.626448	debito
131	t	2024-07-03	234	1	-200.00	Fecha normalizada desde el formato legacy '2024/07/03'; Monto no positivo	2026-09-20 21:44:17.62646	credito
132	f	2024-06-29	236	1	1000.00	\N	2026-09-20 21:44:17.637473	debito
133	f	2024-02-21	237	1	1200.00	Fecha normalizada desde el formato legacy '21-02-2024'	2026-09-20 21:44:17.637505	debito
134	f	2024-10-09	238	1	1200.00	Fecha normalizada desde el formato legacy '2024/10/09'	2026-09-20 21:44:17.637523	credito
135	f	2024-03-04	239	1	800.00	Fecha normalizada desde el formato legacy '04-03-2024'	2026-09-20 21:44:17.637537	debito
136	t	2024-06-17	240	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.637556	debito
137	f	2024-03-07	241	1	1000.00	Fecha normalizada desde el formato legacy '07/03/2024'	2026-09-20 21:44:17.641966	credito
138	f	2024-10-17	243	1	800.00	Fecha normalizada desde el formato legacy '2024/10/17'	2026-09-20 21:44:17.641977	debito
139	f	2024-06-02	245	1	800.00	Fecha normalizada desde el formato legacy '02-06-2024'	2026-09-20 21:44:17.641995	credito
140	f	2024-02-10	246	1	1200.00	Fecha normalizada desde el formato legacy '10-02-2024'	2026-09-20 21:44:17.651512	debito
141	f	2024-02-09	250	1	1200.00	Fecha normalizada desde el formato legacy '2024/02/09'	2026-09-20 21:44:17.651532	debito
142	t	2024-07-14	251	1	-200.00	Fecha normalizada desde el formato legacy '14/07/2024'; Monto no positivo	2026-09-20 21:44:17.663616	debito
143	f	2024-05-25	252	1	700.00	Fecha normalizada desde el formato legacy '2024/05/25'	2026-09-20 21:44:17.663627	debito
144	t	2024-07-02	255	1	-100.00	Fecha normalizada desde el formato legacy '02-07-2024'; Monto no positivo	2026-09-20 21:44:17.663648	credito
145	f	2024-04-22	256	1	1500.00	\N	2026-09-20 21:44:17.673343	credito
146	f	2024-11-26	257	1	1000.00	Fecha normalizada desde el formato legacy '26/11/2024'	2026-09-20 21:44:17.673356	credito
147	f	2024-06-26	261	1	500.00	Fecha normalizada desde el formato legacy '26/06/2024'	2026-09-20 21:44:17.683738	debito
148	t	2024-12-16	265	1	3000.00	Fecha normalizada desde el formato legacy '16/12/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.683763	debito
149	f	2024-05-24	268	1	800.00	\N	2026-09-20 21:44:17.694563	credito
150	f	2024-01-21	274	1	1500.00	Fecha normalizada desde el formato legacy '21/01/2024'	2026-09-20 21:44:17.713395	credito
151	f	2024-08-09	275	1	700.00	Fecha normalizada desde el formato legacy '2024/08/09'	2026-09-20 21:44:17.713417	credito
152	f	2024-10-16	276	1	700.00	Fecha normalizada desde el formato legacy '16/10/2024'	2026-09-20 21:44:17.726842	debito
153	t	2024-08-12	277	1	-100.00	Fecha normalizada desde el formato legacy '12-08-2024'; Monto no positivo	2026-09-20 21:44:17.726972	credito
154	t	2024-05-25	278	1	-200.00	Fecha normalizada desde el formato legacy '25/05/2024'; Monto no positivo	2026-09-20 21:44:17.727076	debito
155	f	2024-07-27	280	1	1200.00	Fecha normalizada desde el formato legacy '27-07-2024'	2026-09-20 21:44:17.727153	credito
156	f	2024-07-08	281	1	800.00	Fecha normalizada desde el formato legacy '2024/07/08'	2026-09-20 21:44:17.736294	credito
157	t	2024-08-08	283	1	0.00	Fecha normalizada desde el formato legacy '08/08/2024'; Monto no positivo	2026-09-20 21:44:17.736311	debito
158	t	2024-07-25	284	1	1500.00	Fecha normalizada desde el formato legacy '25-07-2024'; Posible duplicado por contenido	2026-09-20 21:44:17.736322	credito
159	f	2024-09-27	286	1	800.00	Fecha normalizada desde el formato legacy '27-09-2024'	2026-09-20 21:44:17.747046	credito
160	f	2024-11-17	287	1	800.00	Fecha normalizada desde el formato legacy '2024/11/17'	2026-09-20 21:44:17.747073	debito
161	t	2024-09-03	288	1	-200.00	Monto no positivo	2026-09-20 21:44:17.747084	debito
162	t	2024-08-14	289	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/14'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.747098	debito
163	f	2024-06-15	290	1	1500.00	\N	2026-09-20 21:44:17.747107	debito
164	f	2024-09-20	292	1	1000.00	Fecha normalizada desde el formato legacy '2024/09/20'	2026-09-20 21:44:17.752655	credito
165	f	2024-10-03	301	1	1500.00	\N	2026-09-20 21:44:17.787879	credito
166	t	2024-10-19	303	1	3000.00	Fecha normalizada desde el formato legacy '19-10-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.787894	credito
167	f	2024-03-23	309	1	1000.00	Fecha normalizada desde el formato legacy '2024/03/23'	2026-09-20 21:44:17.801338	debito
168	t	2024-03-30	321	1	-200.00	Monto no positivo	2026-09-20 21:44:17.847202	debito
169	f	2024-07-27	323	1	700.00	Fecha normalizada desde el formato legacy '27/07/2024'	2026-09-20 21:44:17.847218	credito
170	f	2024-03-22	325	1	700.00	Fecha normalizada desde el formato legacy '22/03/2024'	2026-09-20 21:44:17.84724	debito
171	f	2024-11-10	328	1	1000.00	\N	2026-09-20 21:44:17.855581	debito
172	f	2024-11-13	331	1	700.00	Fecha normalizada desde el formato legacy '13-11-2024'	2026-09-20 21:44:17.868844	debito
173	t	2024-10-16	332	1	-200.00	Fecha normalizada desde el formato legacy '2024/10/16'; Monto no positivo	2026-09-20 21:44:17.86886	credito
174	t	2024-08-16	334	1	3000.00	Fecha normalizada desde el formato legacy '16-08-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.868887	debito
175	f	2024-08-17	335	1	1000.00	Fecha normalizada desde el formato legacy '2024/08/17'	2026-09-20 21:44:17.868898	debito
176	t	2024-10-08	337	1	3000.00	Fecha normalizada desde el formato legacy '08-10-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.877524	debito
177	t	2024-03-05	340	1	-200.00	Fecha normalizada desde el formato legacy '2024/03/05'; Monto no positivo	2026-09-20 21:44:17.877545	debito
178	f	2024-10-21	344	1	700.00	\N	2026-09-20 21:44:17.889089	credito
179	f	2024-07-13	348	1	1500.00	Fecha normalizada desde el formato legacy '13/07/2024'	2026-09-20 21:44:17.903887	credito
180	f	2024-03-31	349	1	800.00	Fecha normalizada desde el formato legacy '31/03/2024'	2026-09-20 21:44:17.904052	credito
181	f	2024-02-02	350	1	1200.00	Fecha normalizada desde el formato legacy '02-02-2024'	2026-09-20 21:44:17.904172	debito
182	f	2024-08-31	351	1	1200.00	Fecha normalizada desde el formato legacy '31-08-2024'	2026-09-20 21:44:17.912656	debito
183	f	2024-03-15	355	1	800.00	Fecha normalizada desde el formato legacy '2024/03/15'	2026-09-20 21:44:17.91267	credito
184	t	2024-12-17	356	1	-200.00	Fecha normalizada desde el formato legacy '17-12-2024'; Monto no positivo	2026-09-20 21:44:17.92076	debito
185	f	2024-11-06	362	1	1500.00	Fecha normalizada desde el formato legacy '06/11/2024'	2026-09-20 21:44:17.932853	debito
186	f	2024-09-04	364	1	700.00	Fecha normalizada desde el formato legacy '04-09-2024'	2026-09-20 21:44:17.932873	debito
187	f	2024-10-01	365	1	1200.00	Fecha normalizada desde el formato legacy '2024/10/01'	2026-09-20 21:44:17.932886	credito
188	f	2024-07-22	366	1	700.00	Fecha normalizada desde el formato legacy '22-07-2024'	2026-09-20 21:44:17.940426	debito
189	f	2024-03-14	367	1	1500.00	Fecha normalizada desde el formato legacy '14-03-2024'	2026-09-20 21:44:17.940442	debito
190	f	2024-07-26	368	1	800.00	Fecha normalizada desde el formato legacy '26-07-2024'	2026-09-20 21:44:17.940457	debito
191	t	2024-10-02	370	1	3000.00	Fecha normalizada desde el formato legacy '02/10/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:17.940484	debito
192	f	2024-12-10	371	1	1000.00	Fecha normalizada desde el formato legacy '10-12-2024'	2026-09-20 21:44:17.947123	debito
193	f	2024-08-20	372	1	1200.00	\N	2026-09-20 21:44:17.947139	debito
194	f	2024-09-30	373	1	800.00	Fecha normalizada desde el formato legacy '30-09-2024'	2026-09-20 21:44:17.947152	debito
195	f	2024-12-02	375	1	1000.00	Fecha normalizada desde el formato legacy '02-12-2024'	2026-09-20 21:44:17.947194	credito
196	f	2024-07-09	376	1	1200.00	\N	2026-09-20 21:44:17.95344	credito
197	f	2024-05-19	378	1	800.00	Fecha normalizada desde el formato legacy '19-05-2024'	2026-09-20 21:44:17.953463	credito
198	f	2024-12-26	380	1	1200.00	Fecha normalizada desde el formato legacy '26-12-2024'	2026-09-20 21:44:17.953488	debito
199	f	2024-12-20	390	1	1200.00	\N	2026-09-20 21:44:17.975624	credito
200	f	2024-09-09	391	1	500.00	Fecha normalizada desde el formato legacy '09/09/2024'	2026-09-20 21:44:17.988822	credito
201	f	2024-04-10	392	1	1000.00	\N	2026-09-20 21:44:17.988831	debito
202	f	2024-03-14	394	1	1500.00	Fecha normalizada desde el formato legacy '2024/03/14'	2026-09-20 21:44:17.988851	credito
203	t	2024-07-09	395	1	-200.00	Monto no positivo	2026-09-20 21:44:17.988859	debito
204	f	2024-02-16	397	1	700.00	\N	2026-09-20 21:44:17.995569	debito
205	f	2024-06-01	399	1	1500.00	Fecha normalizada desde el formato legacy '01/06/2024'	2026-09-20 21:44:17.995588	credito
206	f	2024-07-03	400	1	1000.00	Fecha normalizada desde el formato legacy '03/07/2024'	2026-09-20 21:44:17.995603	debito
207	f	2024-12-12	401	1	700.00	Fecha normalizada desde el formato legacy '2024/12/12'	2026-09-20 21:44:18.001268	debito
208	f	2024-06-29	403	1	500.00	Fecha normalizada desde el formato legacy '29-06-2024'	2026-09-20 21:44:18.001384	credito
209	f	2024-08-03	405	1	1500.00	Fecha normalizada desde el formato legacy '03-08-2024'	2026-09-20 21:44:18.001463	credito
210	t	2024-12-30	408	1	-200.00	Monto no positivo	2026-09-20 21:44:18.009163	debito
211	f	2024-01-22	409	1	800.00	Fecha normalizada desde el formato legacy '22/01/2024'	2026-09-20 21:44:18.009241	debito
212	t	2024-12-12	411	1	-200.00	Fecha normalizada desde el formato legacy '12-12-2024'; Monto no positivo	2026-09-20 21:44:18.017185	debito
213	f	2024-01-19	419	1	800.00	\N	2026-09-20 21:44:18.024227	credito
214	f	2024-05-30	420	1	1000.00	Fecha normalizada desde el formato legacy '30/05/2024'	2026-09-20 21:44:18.024251	credito
215	t	2024-09-09	421	1	-200.00	Fecha normalizada desde el formato legacy '09-09-2024'; Monto no positivo	2026-09-20 21:44:18.030736	credito
216	t	2024-09-09	422	1	-200.00	Monto no positivo; Posible duplicado por contenido	2026-09-20 21:44:18.030745	credito
217	f	2024-11-12	424	1	700.00	Fecha normalizada desde el formato legacy '2024/11/12'	2026-09-20 21:44:18.030763	credito
218	f	2024-08-28	426	1	800.00	\N	2026-09-20 21:44:18.039885	credito
219	f	2024-08-09	428	1	700.00	\N	2026-09-20 21:44:18.039892	debito
220	f	2024-06-30	432	1	1000.00	Fecha normalizada desde el formato legacy '30-06-2024'	2026-09-20 21:44:18.048582	debito
221	t	2024-08-21	436	1	-100.00	Fecha normalizada desde el formato legacy '21-08-2024'; Monto no positivo	2026-09-20 21:44:18.059304	debito
222	f	2024-03-15	439	1	1200.00	Fecha normalizada desde el formato legacy '15-03-2024'	2026-09-20 21:44:18.059319	credito
223	f	2024-12-04	441	1	1000.00	\N	2026-09-20 21:44:18.067626	debito
224	f	2024-08-06	442	1	1200.00	Fecha normalizada desde el formato legacy '06-08-2024'	2026-09-20 21:44:18.06765	debito
225	f	2024-02-08	447	1	1000.00	Fecha normalizada desde el formato legacy '08-02-2024'	2026-09-20 21:44:18.077199	credito
226	t	2024-05-19	449	1	-200.00	Fecha normalizada desde el formato legacy '2024/05/19'; Monto no positivo	2026-09-20 21:44:18.077213	credito
227	f	2024-03-07	450	1	1500.00	Fecha normalizada desde el formato legacy '2024/03/07'	2026-09-20 21:44:18.077224	debito
228	f	2024-05-31	452	1	700.00	Fecha normalizada desde el formato legacy '31/05/2024'	2026-09-20 21:44:18.082768	credito
229	t	2024-10-23	454	1	-200.00	Monto no positivo	2026-09-20 21:44:18.082776	debito
230	f	2024-03-26	457	1	1200.00	Fecha normalizada desde el formato legacy '26/03/2024'	2026-09-20 21:44:18.09007	credito
231	t	2024-10-02	458	1	-100.00	Fecha normalizada desde el formato legacy '02-10-2024'; Monto no positivo	2026-09-20 21:44:18.090082	debito
232	f	2024-01-31	459	1	1000.00	Fecha normalizada desde el formato legacy '31/01/2024'	2026-09-20 21:44:18.090095	credito
233	t	2024-04-01	463	1	-100.00	Fecha normalizada desde el formato legacy '2024/04/01'; Monto no positivo	2026-09-20 21:44:18.094784	debito
234	f	2024-07-24	464	1	1000.00	Fecha normalizada desde el formato legacy '2024/07/24'	2026-09-20 21:44:18.094801	debito
235	f	2024-03-04	465	1	700.00	\N	2026-09-20 21:44:18.094812	credito
236	f	2024-04-30	467	1	1500.00	\N	2026-09-20 21:44:18.101209	credito
237	t	2024-03-17	468	1	-200.00	Fecha normalizada desde el formato legacy '17-03-2024'; Monto no positivo	2026-09-20 21:44:18.101224	debito
238	f	2024-07-09	477	1	800.00	Fecha normalizada desde el formato legacy '09-07-2024'	2026-09-20 21:44:18.119137	credito
239	t	2024-07-06	478	1	0.00	Fecha normalizada desde el formato legacy '06/07/2024'; Monto no positivo	2026-09-20 21:44:18.11915	credito
240	f	2024-06-09	480	1	700.00	Fecha normalizada desde el formato legacy '2024/06/09'	2026-09-20 21:44:18.119163	debito
241	t	2024-09-15	481	1	-100.00	Fecha normalizada desde el formato legacy '15/09/2024'; Monto no positivo	2026-09-20 21:44:18.125433	credito
242	f	2024-11-07	483	1	1000.00	\N	2026-09-20 21:44:18.125443	credito
243	f	2024-04-15	484	1	700.00	\N	2026-09-20 21:44:18.125451	credito
244	f	2024-01-04	487	1	800.00	Fecha normalizada desde el formato legacy '04-01-2024'	2026-09-20 21:44:18.132235	credito
245	t	2024-11-15	489	1	3000.00	Fecha normalizada desde el formato legacy '15/11/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.132251	debito
246	t	2024-11-26	494	1	-200.00	Fecha normalizada desde el formato legacy '26-11-2024'; Monto no positivo	2026-09-20 21:44:18.13971	debito
247	f	2024-11-18	495	1	1500.00	Fecha normalizada desde el formato legacy '18/11/2024'	2026-09-20 21:44:18.139727	credito
248	f	2024-05-16	499	1	1200.00	Fecha normalizada desde el formato legacy '16-05-2024'	2026-09-20 21:44:18.145916	credito
249	t	2024-02-10	502	1	-100.00	Fecha normalizada desde el formato legacy '10/02/2024'; Monto no positivo	2026-09-20 21:44:18.155413	credito
250	f	2024-09-16	504	1	500.00	Fecha normalizada desde el formato legacy '16-09-2024'	2026-09-20 21:44:18.155435	credito
251	f	2024-07-08	505	1	1000.00	\N	2026-09-20 21:44:18.155446	debito
252	f	2024-11-06	508	1	700.00	Fecha normalizada desde el formato legacy '06-11-2024'	2026-09-20 21:44:18.160462	credito
253	f	2024-10-31	509	1	500.00	Fecha normalizada desde el formato legacy '2024/10/31'	2026-09-20 21:44:18.160477	debito
254	t	2024-02-21	510	1	3000.00	Fecha normalizada desde el formato legacy '21/02/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.160492	credito
255	t	2024-08-14	512	1	700.00	Fecha normalizada desde el formato legacy '2024/08/14'; Posible duplicado por contenido	2026-09-20 21:44:18.168541	credito
256	f	2024-07-14	515	1	700.00	Fecha normalizada desde el formato legacy '14-07-2024'	2026-09-20 21:44:18.168569	debito
257	f	2024-09-02	520	1	1200.00	Fecha normalizada desde el formato legacy '2024/09/02'	2026-09-20 21:44:18.17478	debito
258	f	2024-10-01	521	1	1500.00	Fecha normalizada desde el formato legacy '01-10-2024'	2026-09-20 21:44:18.181819	credito
259	f	2024-05-17	527	1	1200.00	Fecha normalizada desde el formato legacy '17/05/2024'	2026-09-20 21:44:18.188038	credito
260	t	2024-11-08	529	1	-100.00	Fecha normalizada desde el formato legacy '08/11/2024'; Monto no positivo	2026-09-20 21:44:18.18805	credito
261	f	2024-01-07	531	1	700.00	\N	2026-09-20 21:44:18.194189	credito
262	t	2024-10-15	532	1	3000.00	Fecha normalizada desde el formato legacy '15/10/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.194202	credito
263	t	2024-11-18	533	1	1500.00	Fecha normalizada desde el formato legacy '18/11/2024'; Posible duplicado por contenido	2026-09-20 21:44:18.194214	credito
264	f	2024-09-30	536	1	700.00	Fecha normalizada desde el formato legacy '2024/09/30'	2026-09-20 21:44:18.198823	credito
265	t	2024-08-22	538	1	-200.00	Fecha normalizada desde el formato legacy '22-08-2024'; Monto no positivo	2026-09-20 21:44:18.198845	credito
266	f	2024-08-26	539	1	1500.00	Fecha normalizada desde el formato legacy '26-08-2024'	2026-09-20 21:44:18.198859	debito
267	f	2024-04-18	540	1	800.00	Fecha normalizada desde el formato legacy '18-04-2024'	2026-09-20 21:44:18.19887	credito
268	t	2024-06-22	541	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.202416	debito
269	f	2024-10-04	544	1	800.00	\N	2026-09-20 21:44:18.202435	debito
270	f	2024-11-23	545	1	1000.00	Fecha normalizada desde el formato legacy '23-11-2024'	2026-09-20 21:44:18.202482	debito
271	f	2024-04-26	546	1	1200.00	Fecha normalizada desde el formato legacy '26-04-2024'	2026-09-20 21:44:18.20853	debito
272	f	2024-09-25	547	1	1200.00	Fecha normalizada desde el formato legacy '2024/09/25'	2026-09-20 21:44:18.20854	credito
273	f	2024-08-17	548	1	1500.00	\N	2026-09-20 21:44:18.208547	debito
274	t	2024-05-25	550	1	800.00	Fecha normalizada desde el formato legacy '25/05/2024'; Posible duplicado por contenido	2026-09-20 21:44:18.208593	debito
275	f	2024-10-16	553	1	1500.00	Fecha normalizada desde el formato legacy '16-10-2024'	2026-09-20 21:44:18.211901	debito
276	f	2024-06-29	554	1	1200.00	\N	2026-09-20 21:44:18.21191	credito
277	f	2024-05-29	555	1	700.00	\N	2026-09-20 21:44:18.211917	credito
278	t	2024-06-16	556	1	-200.00	Monto no positivo	2026-09-20 21:44:18.218394	credito
279	t	2024-01-19	562	1	800.00	Fecha normalizada desde el formato legacy '19-01-2024'; Posible duplicado por contenido	2026-09-20 21:44:18.227055	credito
280	f	2024-08-17	563	1	1200.00	Fecha normalizada desde el formato legacy '2024/08/17'	2026-09-20 21:44:18.227064	debito
281	f	2024-07-06	564	1	800.00	Fecha normalizada desde el formato legacy '06/07/2024'	2026-09-20 21:44:18.227076	credito
282	f	2024-07-12	566	1	1200.00	Fecha normalizada desde el formato legacy '2024/07/12'	2026-09-20 21:44:18.232997	debito
283	f	2024-01-15	567	1	700.00	\N	2026-09-20 21:44:18.233003	credito
284	f	2024-03-11	568	1	1200.00	\N	2026-09-20 21:44:18.233009	debito
285	f	2024-06-12	571	1	1200.00	Fecha normalizada desde el formato legacy '12-06-2024'	2026-09-20 21:44:18.23895	debito
286	t	2024-11-05	572	1	3000.00	Fecha normalizada desde el formato legacy '2024/11/05'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.238968	credito
287	t	2024-06-29	573	1	1200.00	Fecha normalizada desde el formato legacy '29-06-2024'; Posible duplicado por contenido	2026-09-20 21:44:18.238981	credito
288	t	2024-10-18	574	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.23899	debito
289	t	2024-01-06	575	1	3000.00	Fecha normalizada desde el formato legacy '06-01-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.239001	debito
290	f	2024-02-17	577	1	800.00	Fecha normalizada desde el formato legacy '2024/02/17'	2026-09-20 21:44:18.241835	debito
291	t	2024-01-21	581	1	3000.00	Fecha normalizada desde el formato legacy '21-01-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.248755	debito
292	f	2024-11-17	585	1	1200.00	Fecha normalizada desde el formato legacy '2024/11/17'	2026-09-20 21:44:18.248768	debito
293	t	2024-01-31	586	1	-200.00	Fecha normalizada desde el formato legacy '31-01-2024'; Monto no positivo	2026-09-20 21:44:18.254091	credito
294	f	2024-07-10	587	1	1200.00	Fecha normalizada desde el formato legacy '2024/07/10'	2026-09-20 21:44:18.254106	credito
295	f	2024-11-22	588	1	1200.00	Fecha normalizada desde el formato legacy '22/11/2024'	2026-09-20 21:44:18.25412	debito
296	f	2024-12-30	589	1	800.00	Fecha normalizada desde el formato legacy '2024/12/30'	2026-09-20 21:44:18.25413	debito
297	f	2024-10-05	590	1	1500.00	Fecha normalizada desde el formato legacy '05-10-2024'	2026-09-20 21:44:18.25414	credito
298	t	2024-08-10	591	1	3000.00	Fecha normalizada desde el formato legacy '10-08-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.256171	credito
299	f	2024-04-14	592	1	1500.00	Fecha normalizada desde el formato legacy '14-04-2024'	2026-09-20 21:44:18.256182	credito
300	f	2024-03-05	593	1	1200.00	Fecha normalizada desde el formato legacy '05-03-2024'	2026-09-20 21:44:18.256192	credito
301	f	2024-01-30	597	1	500.00	\N	2026-09-20 21:44:18.261237	credito
302	t	2024-06-29	602	1	-200.00	Fecha normalizada desde el formato legacy '29-06-2024'; Monto no positivo	2026-09-20 21:44:18.268507	credito
303	f	2024-05-15	604	1	1000.00	\N	2026-09-20 21:44:18.268514	credito
304	f	2024-10-02	607	1	700.00	\N	2026-09-20 21:44:18.27518	debito
305	f	2024-05-27	608	1	1000.00	Fecha normalizada desde el formato legacy '27/05/2024'	2026-09-20 21:44:18.275192	debito
306	t	2024-11-14	609	1	3000.00	Fecha normalizada desde el formato legacy '2024/11/14'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.27521	credito
307	f	2024-01-15	612	1	500.00	\N	2026-09-20 21:44:18.280484	credito
308	f	2024-11-17	613	1	700.00	\N	2026-09-20 21:44:18.280491	debito
309	t	2024-06-15	618	1	-100.00	Fecha normalizada desde el formato legacy '15/06/2024'; Monto no positivo	2026-09-20 21:44:18.28566	credito
310	f	2024-09-30	619	1	1000.00	Fecha normalizada desde el formato legacy '2024/09/30'	2026-09-20 21:44:18.285672	credito
311	f	2024-01-13	620	1	1000.00	\N	2026-09-20 21:44:18.28568	credito
312	f	2024-03-23	621	1	1200.00	\N	2026-09-20 21:44:18.290103	debito
313	f	2024-03-01	623	1	800.00	\N	2026-09-20 21:44:18.29011	debito
314	t	2024-04-04	624	1	3000.00	Fecha normalizada desde el formato legacy '04-04-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.290121	credito
315	f	2024-12-29	627	1	700.00	Fecha normalizada desde el formato legacy '2024/12/29'	2026-09-20 21:44:18.29486	credito
316	f	2024-09-16	631	1	1500.00	Fecha normalizada desde el formato legacy '16/09/2024'	2026-09-20 21:44:18.30162	credito
317	f	2024-10-27	633	1	1500.00	\N	2026-09-20 21:44:18.301627	debito
318	t	2024-06-15	634	1	1500.00	Fecha normalizada desde el formato legacy '15-06-2024'; Posible duplicado por contenido	2026-09-20 21:44:18.301637	debito
319	f	2024-08-07	636	1	1500.00	Fecha normalizada desde el formato legacy '07/08/2024'	2026-09-20 21:44:18.30572	credito
320	t	2024-09-26	639	1	-200.00	Fecha normalizada desde el formato legacy '26-09-2024'; Monto no positivo	2026-09-20 21:44:18.305734	credito
321	t	2024-10-09	640	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.305742	debito
322	f	2024-11-29	641	1	1200.00	Fecha normalizada desde el formato legacy '29-11-2024'	2026-09-20 21:44:18.310936	debito
323	f	2024-03-14	642	1	700.00	Fecha normalizada desde el formato legacy '2024/03/14'	2026-09-20 21:44:18.310944	credito
324	f	2024-07-20	646	1	700.00	Fecha normalizada desde el formato legacy '2024/07/20'	2026-09-20 21:44:18.317796	credito
325	f	2024-08-09	647	1	1000.00	\N	2026-09-20 21:44:18.317806	debito
326	t	2024-04-16	649	1	-200.00	Fecha normalizada desde el formato legacy '16/04/2024'; Monto no positivo	2026-09-20 21:44:18.317832	debito
327	t	2024-10-31	650	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.317842	credito
328	t	2024-04-28	652	1	-200.00	Fecha normalizada desde el formato legacy '28/04/2024'; Monto no positivo	2026-09-20 21:44:18.321321	debito
329	f	2024-08-29	653	1	1500.00	\N	2026-09-20 21:44:18.321335	debito
330	f	2024-04-16	654	1	800.00	Fecha normalizada desde el formato legacy '16/04/2024'	2026-09-20 21:44:18.321349	debito
331	t	2024-01-14	655	1	-200.00	Fecha normalizada desde el formato legacy '14-01-2024'; Monto no positivo	2026-09-20 21:44:18.321362	credito
332	f	2024-10-21	656	1	700.00	Fecha normalizada desde el formato legacy '21/10/2024'	2026-09-20 21:44:18.324906	debito
333	f	2024-01-26	659	1	1000.00	Fecha normalizada desde el formato legacy '2024/01/26'	2026-09-20 21:44:18.324915	credito
334	f	2024-06-27	661	1	1200.00	Fecha normalizada desde el formato legacy '27/06/2024'	2026-09-20 21:44:18.330389	debito
335	f	2024-03-07	662	1	700.00	\N	2026-09-20 21:44:18.330395	credito
336	f	2024-07-14	667	1	700.00	\N	2026-09-20 21:44:18.336701	credito
337	t	2024-10-16	669	1	1500.00	Fecha normalizada desde el formato legacy '16/10/2024'; Posible duplicado por contenido	2026-09-20 21:44:18.336717	debito
338	f	2024-12-07	670	1	1200.00	\N	2026-09-20 21:44:18.336724	credito
339	t	2024-04-30	673	1	-200.00	Monto no positivo	2026-09-20 21:44:18.340723	credito
340	f	2024-01-22	682	1	700.00	Fecha normalizada desde el formato legacy '2024/01/22'	2026-09-20 21:44:18.355337	credito
341	f	2024-03-03	683	1	500.00	\N	2026-09-20 21:44:18.355344	credito
342	f	2024-06-22	689	1	1000.00	\N	2026-09-20 21:44:18.361045	debito
343	t	2024-01-27	690	1	-200.00	Fecha normalizada desde el formato legacy '2024/01/27'; Monto no positivo	2026-09-20 21:44:18.361056	debito
344	f	2024-02-09	691	1	800.00	Fecha normalizada desde el formato legacy '09/02/2024'	2026-09-20 21:44:18.366185	debito
345	f	2024-04-06	694	1	1000.00	\N	2026-09-20 21:44:18.366192	credito
346	f	2024-04-30	700	1	1000.00	Fecha normalizada desde el formato legacy '30/04/2024'	2026-09-20 21:44:18.372294	debito
347	f	2024-10-16	705	1	700.00	Fecha normalizada desde el formato legacy '16/10/2024'	2026-09-20 21:44:18.378498	credito
348	f	2024-03-20	706	1	1000.00	Fecha normalizada desde el formato legacy '20-03-2024'	2026-09-20 21:44:18.38486	credito
349	f	2024-01-14	707	1	800.00	\N	2026-09-20 21:44:18.384871	debito
350	f	2024-06-14	708	1	700.00	Fecha normalizada desde el formato legacy '2024/06/14'	2026-09-20 21:44:18.384882	credito
351	f	2024-10-24	710	1	700.00	Fecha normalizada desde el formato legacy '24/10/2024'	2026-09-20 21:44:18.384899	debito
352	t	2024-04-03	723	1	-200.00	Fecha normalizada desde el formato legacy '03-04-2024'; Monto no positivo	2026-09-20 21:44:18.405701	debito
353	f	2024-10-10	726	1	1500.00	Fecha normalizada desde el formato legacy '10-10-2024'	2026-09-20 21:44:18.417523	credito
354	f	2024-01-12	727	1	1000.00	Fecha normalizada desde el formato legacy '12-01-2024'	2026-09-20 21:44:18.417595	debito
355	t	2024-04-06	729	1	0.00	Monto no positivo	2026-09-20 21:44:18.417667	credito
356	f	2024-03-18	730	1	800.00	Fecha normalizada desde el formato legacy '18-03-2024'	2026-09-20 21:44:18.417692	debito
357	f	2024-11-11	732	1	1000.00	Fecha normalizada desde el formato legacy '2024/11/11'	2026-09-20 21:44:18.42317	credito
358	f	2024-04-13	734	1	1500.00	\N	2026-09-20 21:44:18.423181	credito
359	f	2024-09-23	735	1	1000.00	Fecha normalizada desde el formato legacy '23/09/2024'	2026-09-20 21:44:18.423195	debito
360	f	2024-06-08	740	1	700.00	\N	2026-09-20 21:44:18.427777	debito
361	f	2024-01-15	743	1	700.00	\N	2026-09-20 21:44:18.435093	debito
362	f	2024-02-24	744	1	800.00	Fecha normalizada desde el formato legacy '24-02-2024'	2026-09-20 21:44:18.435104	debito
363	f	2024-03-31	747	1	1000.00	Fecha normalizada desde el formato legacy '31-03-2024'	2026-09-20 21:44:18.4411	credito
364	f	2024-10-06	748	1	800.00	Fecha normalizada desde el formato legacy '06/10/2024'	2026-09-20 21:44:18.441112	credito
365	t	2024-03-03	750	1	-200.00	Fecha normalizada desde el formato legacy '03-03-2024'; Monto no positivo	2026-09-20 21:44:18.441124	debito
366	t	2024-10-13	753	1	3000.00	Fecha normalizada desde el formato legacy '13/10/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.445398	debito
367	f	2024-09-01	754	1	1500.00	Fecha normalizada desde el formato legacy '01-09-2024'	2026-09-20 21:44:18.445409	debito
368	f	2024-07-15	756	1	800.00	Fecha normalizada desde el formato legacy '15/07/2024'	2026-09-20 21:44:18.449386	debito
369	f	2024-10-11	757	1	1000.00	Fecha normalizada desde el formato legacy '11-10-2024'	2026-09-20 21:44:18.449397	credito
370	f	2024-03-31	759	1	1500.00	\N	2026-09-20 21:44:18.449408	debito
371	f	2024-07-28	760	1	800.00	\N	2026-09-20 21:44:18.449415	debito
372	t	2024-06-10	761	1	3000.00	Fecha normalizada desde el formato legacy '2024/06/10'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.453434	debito
373	f	2024-08-15	762	1	1500.00	Fecha normalizada desde el formato legacy '2024/08/15'	2026-09-20 21:44:18.453443	debito
374	f	2024-11-09	764	1	1000.00	Fecha normalizada desde el formato legacy '09-11-2024'	2026-09-20 21:44:18.453453	credito
375	f	2024-04-11	766	1	1200.00	Fecha normalizada desde el formato legacy '11/04/2024'	2026-09-20 21:44:18.457013	credito
376	f	2024-01-22	767	1	1500.00	\N	2026-09-20 21:44:18.457022	credito
377	f	2024-08-27	770	1	1500.00	\N	2026-09-20 21:44:18.457036	credito
378	f	2024-04-08	774	1	1000.00	Fecha normalizada desde el formato legacy '08/04/2024'	2026-09-20 21:44:18.461699	credito
379	f	2024-07-13	776	1	800.00	Fecha normalizada desde el formato legacy '13-07-2024'	2026-09-20 21:44:18.467966	credito
380	t	2024-01-25	777	1	3000.00	Fecha normalizada desde el formato legacy '25/01/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.467979	credito
381	f	2024-08-11	778	1	800.00	\N	2026-09-20 21:44:18.467986	debito
382	t	2024-03-31	779	1	-200.00	Fecha normalizada desde el formato legacy '31-03-2024'; Monto no positivo	2026-09-20 21:44:18.467996	debito
383	f	2024-02-28	783	1	1000.00	Fecha normalizada desde el formato legacy '28/02/2024'	2026-09-20 21:44:18.471206	credito
384	f	2024-05-19	787	1	1000.00	\N	2026-09-20 21:44:18.478317	credito
385	f	2024-05-27	789	1	1000.00	Fecha normalizada desde el formato legacy '27/05/2024'	2026-09-20 21:44:18.478351	credito
386	t	2024-11-11	790	1	1000.00	Posible duplicado por contenido	2026-09-20 21:44:18.478428	credito
387	t	2024-06-28	791	1	-200.00	Fecha normalizada desde el formato legacy '28/06/2024'; Monto no positivo	2026-09-20 21:44:18.483111	credito
388	f	2024-11-29	795	1	800.00	Fecha normalizada desde el formato legacy '29-11-2024'	2026-09-20 21:44:18.483127	debito
389	f	2024-09-08	797	1	800.00	Fecha normalizada desde el formato legacy '08-09-2024'	2026-09-20 21:44:18.489598	debito
390	f	2024-12-07	798	1	1000.00	Fecha normalizada desde el formato legacy '07-12-2024'	2026-09-20 21:44:18.489608	debito
391	f	2024-02-29	802	1	1200.00	Fecha normalizada desde el formato legacy '29-02-2024'	2026-09-20 21:44:18.496684	credito
392	f	2024-12-01	807	1	700.00	\N	2026-09-20 21:44:18.504783	debito
393	t	2024-01-04	808	1	-200.00	Monto no positivo	2026-09-20 21:44:18.504791	debito
394	t	2024-07-24	811	1	1200.00	Fecha normalizada desde el formato legacy '2024/07/24'; Posible duplicado por contenido	2026-09-20 21:44:18.51332	debito
395	f	2024-10-22	814	1	700.00	\N	2026-09-20 21:44:18.513326	credito
396	t	2024-06-19	818	1	-100.00	Fecha normalizada desde el formato legacy '19/06/2024'; Monto no positivo	2026-09-20 21:44:18.521806	debito
397	t	2024-08-12	820	1	3000.00	Fecha normalizada desde el formato legacy '2024/08/12'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.521845	credito
398	f	2024-09-18	822	1	1200.00	Fecha normalizada desde el formato legacy '2024/09/18'	2026-09-20 21:44:18.530728	credito
399	t	2024-01-28	823	1	-200.00	Monto no positivo	2026-09-20 21:44:18.530736	debito
400	t	2024-04-16	824	1	3000.00	Fecha normalizada desde el formato legacy '2024/04/16'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.530746	credito
401	f	2024-10-15	826	1	500.00	Fecha normalizada desde el formato legacy '15/10/2024'	2026-09-20 21:44:18.53757	debito
402	t	2024-02-06	827	1	-200.00	Fecha normalizada desde el formato legacy '06/02/2024'; Monto no positivo	2026-09-20 21:44:18.537582	debito
403	t	2024-10-10	830	1	3000.00	Fecha normalizada desde el formato legacy '10/10/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.537597	debito
404	f	2024-08-03	831	1	1000.00	Fecha normalizada desde el formato legacy '03/08/2024'	2026-09-20 21:44:18.545124	debito
405	f	2024-06-26	832	1	700.00	\N	2026-09-20 21:44:18.545131	debito
406	f	2024-05-16	833	1	700.00	Fecha normalizada desde el formato legacy '16-05-2024'	2026-09-20 21:44:18.545141	debito
407	t	2024-02-02	834	1	3000.00	Fecha normalizada desde el formato legacy '02/02/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.545152	credito
408	f	2024-06-08	836	1	1500.00	\N	2026-09-20 21:44:18.5507	credito
409	t	2024-04-23	839	1	-200.00	Fecha normalizada desde el formato legacy '2024/04/23'; Monto no positivo	2026-09-20 21:44:18.550784	credito
410	f	2024-08-12	840	1	800.00	Fecha normalizada desde el formato legacy '2024/08/12'	2026-09-20 21:44:18.550806	debito
411	f	2024-10-30	842	1	1500.00	Fecha normalizada desde el formato legacy '2024/10/30'	2026-09-20 21:44:18.557183	credito
412	f	2024-03-12	843	1	1500.00	Fecha normalizada desde el formato legacy '12-03-2024'	2026-09-20 21:44:18.557197	credito
413	t	2024-11-23	844	1	-200.00	Fecha normalizada desde el formato legacy '23-11-2024'; Monto no positivo	2026-09-20 21:44:18.557214	debito
414	f	2024-10-14	847	1	1000.00	Fecha normalizada desde el formato legacy '2024/10/14'	2026-09-20 21:44:18.563297	debito
415	f	2024-06-07	848	1	1200.00	Fecha normalizada desde el formato legacy '07-06-2024'	2026-09-20 21:44:18.563313	credito
416	t	2024-05-01	849	1	-200.00	Fecha normalizada desde el formato legacy '2024/05/01'; Monto no positivo	2026-09-20 21:44:18.563323	debito
417	t	2024-12-20	850	1	3000.00	Fecha normalizada desde el formato legacy '2024/12/20'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.56334	credito
418	f	2024-06-27	854	1	500.00	Fecha normalizada desde el formato legacy '27-06-2024'	2026-09-20 21:44:18.569977	debito
419	t	2024-08-20	855	1	-200.00	Fecha normalizada desde el formato legacy '20-08-2024'; Monto no positivo	2026-09-20 21:44:18.569992	credito
420	t	2024-07-22	856	1	-200.00	Fecha normalizada desde el formato legacy '22-07-2024'; Monto no positivo	2026-09-20 21:44:18.577413	credito
421	f	2024-10-29	857	1	800.00	\N	2026-09-20 21:44:18.57742	debito
422	t	2024-04-08	859	1	3000.00	Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.577426	debito
423	t	2024-09-13	861	1	-200.00	Fecha normalizada desde el formato legacy '13/09/2024'; Monto no positivo	2026-09-20 21:44:18.583789	debito
424	t	2024-10-31	864	1	0.00	Monto no positivo	2026-09-20 21:44:18.583802	credito
425	t	2024-05-29	865	1	-200.00	Fecha normalizada desde el formato legacy '2024/05/29'; Monto no positivo	2026-09-20 21:44:18.583828	credito
426	f	2024-02-08	866	1	800.00	Fecha normalizada desde el formato legacy '08-02-2024'	2026-09-20 21:44:18.590316	debito
427	t	2024-09-26	869	1	3000.00	Fecha normalizada desde el formato legacy '2024/09/26'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.590328	credito
428	t	2024-07-27	871	1	3000.00	Fecha normalizada desde el formato legacy '27-07-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.599103	debito
429	t	2024-04-01	872	1	-200.00	Monto no positivo	2026-09-20 21:44:18.599127	debito
430	f	2024-06-27	876	1	700.00	Fecha normalizada desde el formato legacy '2024/06/27'	2026-09-20 21:44:18.607682	credito
431	f	2024-01-14	880	1	800.00	Fecha normalizada desde el formato legacy '14-01-2024'	2026-09-20 21:44:18.607709	credito
432	f	2024-01-08	884	1	800.00	Fecha normalizada desde el formato legacy '08-01-2024'	2026-09-20 21:44:18.614856	credito
433	f	2024-05-29	885	1	1000.00	Fecha normalizada desde el formato legacy '29/05/2024'	2026-09-20 21:44:18.614872	debito
434	f	2024-12-27	886	1	1200.00	\N	2026-09-20 21:44:18.622803	debito
435	t	2024-02-19	887	1	3000.00	Fecha normalizada desde el formato legacy '19-02-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.622816	credito
436	f	2024-10-10	889	1	1500.00	Fecha normalizada desde el formato legacy '2024/10/10'	2026-09-20 21:44:18.62283	debito
437	t	2024-02-29	890	1	3000.00	Fecha normalizada desde el formato legacy '2024/02/29'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.622841	debito
438	f	2024-06-05	892	1	500.00	\N	2026-09-20 21:44:18.628228	debito
439	f	2024-11-04	895	1	1500.00	Fecha normalizada desde el formato legacy '04-11-2024'	2026-09-20 21:44:18.628241	credito
440	t	2024-05-04	897	1	3000.00	Fecha normalizada desde el formato legacy '04/05/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.63848	credito
441	f	2024-12-12	898	1	500.00	Fecha normalizada desde el formato legacy '12/12/2024'	2026-09-20 21:44:18.638499	debito
442	f	2024-12-14	899	1	1500.00	Fecha normalizada desde el formato legacy '14-12-2024'	2026-09-20 21:44:18.638511	credito
443	f	2024-01-19	900	1	1000.00	Fecha normalizada desde el formato legacy '2024/01/19'	2026-09-20 21:44:18.638522	debito
444	f	2024-10-29	903	1	1500.00	Fecha normalizada desde el formato legacy '29-10-2024'	2026-09-20 21:44:18.642307	debito
445	f	2024-05-28	904	1	700.00	Fecha normalizada desde el formato legacy '28/05/2024'	2026-09-20 21:44:18.642321	debito
446	f	2024-02-11	905	1	1000.00	Fecha normalizada desde el formato legacy '11/02/2024'	2026-09-20 21:44:18.642334	debito
447	f	2024-05-29	907	1	1200.00	\N	2026-09-20 21:44:18.646802	debito
448	f	2024-02-27	908	1	700.00	Fecha normalizada desde el formato legacy '2024/02/27'	2026-09-20 21:44:18.64681	debito
449	f	2024-09-29	911	1	700.00	Fecha normalizada desde el formato legacy '29-09-2024'	2026-09-20 21:44:18.652805	debito
450	f	2024-10-10	912	1	1000.00	Fecha normalizada desde el formato legacy '10/10/2024'	2026-09-20 21:44:18.652819	debito
451	f	2024-07-09	914	1	700.00	Fecha normalizada desde el formato legacy '09/07/2024'	2026-09-20 21:44:18.652831	credito
452	f	2024-05-31	919	1	1500.00	Fecha normalizada desde el formato legacy '2024/05/31'	2026-09-20 21:44:18.657074	credito
453	f	2024-05-30	920	1	800.00	Fecha normalizada desde el formato legacy '30-05-2024'	2026-09-20 21:44:18.657087	debito
454	f	2024-04-29	922	1	1200.00	Fecha normalizada desde el formato legacy '29/04/2024'	2026-09-20 21:44:18.662467	debito
455	f	2024-07-06	929	1	800.00	Fecha normalizada desde el formato legacy '06-07-2024'	2026-09-20 21:44:18.668004	debito
456	f	2024-01-17	930	1	800.00	Fecha normalizada desde el formato legacy '17/01/2024'	2026-09-20 21:44:18.66804	credito
457	f	2024-11-22	932	1	1500.00	Fecha normalizada desde el formato legacy '2024/11/22'	2026-09-20 21:44:18.673269	debito
458	f	2024-06-11	936	1	1500.00	\N	2026-09-20 21:44:18.679748	credito
459	f	2024-03-07	937	1	500.00	Fecha normalizada desde el formato legacy '07-03-2024'	2026-09-20 21:44:18.679768	debito
460	t	2024-04-20	939	1	-200.00	Monto no positivo	2026-09-20 21:44:18.679792	debito
461	f	2024-12-09	940	1	1000.00	Fecha normalizada desde el formato legacy '09/12/2024'	2026-09-20 21:44:18.679811	credito
462	f	2024-03-15	942	1	1500.00	Fecha normalizada desde el formato legacy '15/03/2024'	2026-09-20 21:44:18.683913	credito
463	t	2024-02-19	943	1	-200.00	Fecha normalizada desde el formato legacy '19-02-2024'; Monto no positivo	2026-09-20 21:44:18.683923	credito
464	t	2024-08-13	945	1	-100.00	Fecha normalizada desde el formato legacy '13/08/2024'; Monto no positivo	2026-09-20 21:44:18.683936	credito
465	t	2024-06-04	946	1	3000.00	Fecha normalizada desde el formato legacy '04/06/2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.688538	credito
466	t	2024-06-02	947	1	0.00	Fecha normalizada desde el formato legacy '02/06/2024'; Monto no positivo	2026-09-20 21:44:18.688552	credito
467	t	2024-07-24	948	1	-200.00	Fecha normalizada desde el formato legacy '24/07/2024'; Monto no positivo	2026-09-20 21:44:18.688564	credito
468	t	2024-10-14	950	1	1000.00	Fecha normalizada desde el formato legacy '2024/10/14'; Posible duplicado por contenido	2026-09-20 21:44:18.688579	debito
469	t	2024-11-30	952	1	-200.00	Fecha normalizada desde el formato legacy '30-11-2024'; Monto no positivo	2026-09-20 21:44:18.691741	credito
470	t	2024-06-23	953	1	3000.00	Fecha normalizada desde el formato legacy '23-06-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.691753	credito
471	f	2024-01-02	955	1	700.00	Fecha normalizada desde el formato legacy '2024/01/02'	2026-09-20 21:44:18.691765	credito
472	f	2024-07-25	958	1	1200.00	Fecha normalizada desde el formato legacy '2024/07/25'	2026-09-20 21:44:18.696071	credito
473	t	2024-08-11	962	1	-200.00	Fecha normalizada desde el formato legacy '2024/08/11'; Monto no positivo	2026-09-20 21:44:18.70272	debito
474	t	2024-10-25	963	1	-200.00	Fecha normalizada desde el formato legacy '25-10-2024'; Monto no positivo	2026-09-20 21:44:18.702783	credito
475	f	2024-07-27	964	1	1200.00	\N	2026-09-20 21:44:18.702812	debito
476	t	2024-09-19	966	1	3000.00	Fecha normalizada desde el formato legacy '19-09-2024'; Monto atipico sobre el umbral de revision (2500)	2026-09-20 21:44:18.709037	credito
477	f	2024-06-22	967	1	500.00	Fecha normalizada desde el formato legacy '22-06-2024'	2026-09-20 21:44:18.709047	credito
478	t	2024-05-05	968	1	-100.00	Fecha normalizada desde el formato legacy '05-05-2024'; Monto no positivo	2026-09-20 21:44:18.709056	credito
479	t	2024-03-04	971	1	-200.00	Monto no positivo	2026-09-20 21:44:18.713232	credito
480	f	2024-08-02	974	1	1200.00	Fecha normalizada desde el formato legacy '02/08/2024'	2026-09-20 21:44:18.713244	debito
481	t	2024-11-22	979	1	-200.00	Fecha normalizada desde el formato legacy '22-11-2024'; Monto no positivo	2026-09-20 21:44:18.720133	credito
482	t	2024-01-20	981	1	-200.00	Fecha normalizada desde el formato legacy '20/01/2024'; Monto no positivo	2026-09-20 21:44:18.729893	debito
483	f	2024-09-06	985	1	700.00	Fecha normalizada desde el formato legacy '2024/09/06'	2026-09-20 21:44:18.729904	credito
484	f	2024-08-22	989	1	800.00	Fecha normalizada desde el formato legacy '22-08-2024'	2026-09-20 21:44:18.73735	debito
485	f	2024-04-27	990	1	1500.00	\N	2026-09-20 21:44:18.737361	debito
486	t	2024-04-08	991	1	0.00	Monto no positivo	2026-09-20 21:44:18.746714	debito
487	f	2024-03-15	992	1	1000.00	Fecha normalizada desde el formato legacy '15/03/2024'	2026-09-20 21:44:18.746728	credito
488	t	2024-02-08	995	1	-200.00	Monto no positivo	2026-09-20 21:44:18.746737	credito
489	f	2024-07-23	996	1	700.00	Fecha normalizada desde el formato legacy '23-07-2024'	2026-09-20 21:44:18.753936	debito
490	f	2024-06-19	999	1	1500.00	Fecha normalizada desde el formato legacy '19/06/2024'	2026-09-20 21:44:18.753952	debito
491	t	2024-12-30	1000	1	1500.00	Fecha normalizada desde el formato legacy '30-12-2024'; Posible duplicado por contenido	2026-09-20 21:44:18.753964	credito
\.


--
-- Name: batch_job_execution_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.batch_job_execution_seq', 1, true);


--
-- Name: batch_job_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.batch_job_seq', 1, true);


--
-- Name: batch_step_execution_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.batch_step_execution_seq', 9, true);


--
-- Name: cuenta_interes_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cuenta_interes_seq', 351, true);


--
-- Name: estado_cuenta_anual_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estado_cuenta_anual_seq', 51, true);


--
-- Name: movimiento_anual_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.movimiento_anual_seq', 1001, true);


--
-- Name: registro_rechazado_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.registro_rechazado_seq', 1251, true);


--
-- Name: resumen_diario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.resumen_diario_seq', 301, true);


--
-- Name: transaccion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaccion_seq', 501, true);


--
-- Name: batch_job_execution_context batch_job_execution_context_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_execution_context
    ADD CONSTRAINT batch_job_execution_context_pkey PRIMARY KEY (job_execution_id);


--
-- Name: batch_job_execution batch_job_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_execution
    ADD CONSTRAINT batch_job_execution_pkey PRIMARY KEY (job_execution_id);


--
-- Name: batch_job_instance batch_job_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_instance
    ADD CONSTRAINT batch_job_instance_pkey PRIMARY KEY (job_instance_id);


--
-- Name: batch_step_execution_context batch_step_execution_context_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_step_execution_context
    ADD CONSTRAINT batch_step_execution_context_pkey PRIMARY KEY (step_execution_id);


--
-- Name: batch_step_execution batch_step_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_step_execution
    ADD CONSTRAINT batch_step_execution_pkey PRIMARY KEY (step_execution_id);


--
-- Name: cuenta_interes cuenta_interes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cuenta_interes
    ADD CONSTRAINT cuenta_interes_pkey PRIMARY KEY (id);


--
-- Name: estado_cuenta_anual estado_cuenta_anual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estado_cuenta_anual
    ADD CONSTRAINT estado_cuenta_anual_pkey PRIMARY KEY (id);


--
-- Name: batch_job_instance job_inst_un; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_instance
    ADD CONSTRAINT job_inst_un UNIQUE (job_name, job_key);


--
-- Name: movimiento_anual movimiento_anual_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimiento_anual
    ADD CONSTRAINT movimiento_anual_pkey PRIMARY KEY (id);


--
-- Name: registro_rechazado registro_rechazado_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.registro_rechazado
    ADD CONSTRAINT registro_rechazado_pkey PRIMARY KEY (id);


--
-- Name: resumen_diario resumen_diario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resumen_diario
    ADD CONSTRAINT resumen_diario_pkey PRIMARY KEY (id);


--
-- Name: transaccion transaccion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaccion
    ADD CONSTRAINT transaccion_pkey PRIMARY KEY (id);


--
-- Name: idx_cuenta_interes_cuenta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cuenta_interes_cuenta ON public.cuenta_interes USING btree (cuenta_id);


--
-- Name: idx_cuenta_interes_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cuenta_interes_ejecucion ON public.cuenta_interes USING btree (job_execution_id);


--
-- Name: idx_estado_cuenta_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_estado_cuenta_ejecucion ON public.estado_cuenta_anual USING btree (job_execution_id);


--
-- Name: idx_movimiento_cuenta_anio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimiento_cuenta_anio ON public.movimiento_anual USING btree (cuenta_id, anio);


--
-- Name: idx_movimiento_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimiento_ejecucion ON public.movimiento_anual USING btree (job_execution_id);


--
-- Name: idx_rechazado_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rechazado_ejecucion ON public.registro_rechazado USING btree (job_execution_id);


--
-- Name: idx_rechazado_job; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rechazado_job ON public.registro_rechazado USING btree (job_nombre);


--
-- Name: idx_resumen_diario_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resumen_diario_ejecucion ON public.resumen_diario USING btree (job_execution_id);


--
-- Name: idx_transaccion_ejecucion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaccion_ejecucion ON public.transaccion USING btree (job_execution_id);


--
-- Name: idx_transaccion_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaccion_fecha ON public.transaccion USING btree (fecha);


--
-- Name: batch_job_execution_context job_exec_ctx_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_execution_context
    ADD CONSTRAINT job_exec_ctx_fk FOREIGN KEY (job_execution_id) REFERENCES public.batch_job_execution(job_execution_id);


--
-- Name: batch_job_execution_params job_exec_params_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_execution_params
    ADD CONSTRAINT job_exec_params_fk FOREIGN KEY (job_execution_id) REFERENCES public.batch_job_execution(job_execution_id);


--
-- Name: batch_step_execution job_exec_step_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_step_execution
    ADD CONSTRAINT job_exec_step_fk FOREIGN KEY (job_execution_id) REFERENCES public.batch_job_execution(job_execution_id);


--
-- Name: batch_job_execution job_inst_exec_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_job_execution
    ADD CONSTRAINT job_inst_exec_fk FOREIGN KEY (job_instance_id) REFERENCES public.batch_job_instance(job_instance_id);


--
-- Name: batch_step_execution_context step_exec_ctx_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batch_step_execution_context
    ADD CONSTRAINT step_exec_ctx_fk FOREIGN KEY (step_execution_id) REFERENCES public.batch_step_execution(step_execution_id);


--
-- PostgreSQL database dump complete
--

\unrestrict qBrkEt5Sn3VMCBgz9qRzS7UONBtstAVtX2QrccSaPFneQ2blJpDUsUf9bcFFvDn


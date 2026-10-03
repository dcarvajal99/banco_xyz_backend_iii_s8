-- Tablas que en produccion crea el batch (Hibernate) y Spring Batch en el esquema public.
-- Mismas columnas que las entidades de banco-xyz-batch y que schema-h2.sql de spring-batch-core.
create table if not exists public.batch_job_instance (
    job_instance_id bigint primary key, version bigint, job_name varchar(100) not null, job_key varchar(32) not null);
create table if not exists public.batch_job_execution (
    job_execution_id bigint primary key, version bigint, job_instance_id bigint not null, create_time timestamp not null,
    start_time timestamp, end_time timestamp, status varchar(10), exit_code varchar(2500), exit_message varchar(2500),
    last_updated timestamp);
create table if not exists public.batch_step_execution (
    step_execution_id bigint primary key, version bigint not null, step_name varchar(100) not null,
    job_execution_id bigint not null, create_time timestamp not null, start_time timestamp, end_time timestamp,
    status varchar(10), commit_count bigint, read_count bigint, filter_count bigint, write_count bigint,
    read_skip_count bigint, write_skip_count bigint, process_skip_count bigint, rollback_count bigint,
    exit_code varchar(2500), exit_message varchar(2500), last_updated timestamp);
create table if not exists public.cuenta_interes (
    id bigint primary key, cuenta_id bigint not null, nombre varchar(120) not null, tipo varchar(20) not null,
    edad int not null, saldo_inicial numeric(18, 2) not null, tasa_mensual numeric(8, 5) not null,
    interes numeric(18, 2) not null, saldo_final numeric(18, 2) not null, anomalia boolean not null,
    observacion varchar(255), job_execution_id bigint not null, procesado_en timestamp not null);
create table if not exists public.movimiento_anual (
    id bigint primary key, cuenta_id bigint not null, fecha date not null, anio int not null,
    tipo_transaccion varchar(20) not null, monto numeric(18, 2) not null, descripcion varchar(255) not null,
    anomalia boolean not null, observacion varchar(255), job_execution_id bigint not null, procesado_en timestamp not null);
create table if not exists public.estado_cuenta_anual (
    id bigint primary key, cuenta_id bigint not null, anio int not null, cantidad_movimientos bigint not null,
    total_depositos numeric(18, 2) not null, total_cargos numeric(18, 2) not null, saldo_neto numeric(18, 2) not null,
    primera_fecha date, ultima_fecha date, movimientos_con_anomalia bigint not null, job_execution_id bigint not null,
    generado_en timestamp not null);
create table if not exists public.resumen_diario (
    id bigint primary key, fecha date not null, cantidad_transacciones bigint not null,
    total_debitos numeric(18, 2) not null, total_creditos numeric(18, 2) not null, monto_maximo numeric(18, 2) not null,
    cantidad_anomalias bigint not null, job_execution_id bigint not null, generado_en timestamp not null);
create table if not exists public.registro_rechazado (
    id bigint primary key, job_nombre varchar(80) not null, archivo varchar(60) not null,
    clasificacion varchar(20) not null, numero_linea int not null, contenido varchar(500) not null,
    motivo varchar(255) not null, job_execution_id bigint not null, registrado_en timestamp not null);

-- Dos ejecuciones del batch:
--   10 COMPLETED con cuarentena de aviso (DEGRADADA) -> es la que se debe publicar.
--   11 FAILED con id MAYOR y filas escritas         -> NUNCA se publica, aunque sea la mas reciente.
delete from public.registro_rechazado;
delete from public.resumen_diario;
delete from public.estado_cuenta_anual;
delete from public.movimiento_anual;
delete from public.cuenta_interes;
delete from public.batch_step_execution;
delete from public.batch_job_execution;
delete from public.batch_job_instance;

insert into public.batch_job_instance values (1, 0, 'migracionCompletaJob', 'k1');
insert into public.batch_job_instance values (2, 0, 'calculoInteresesMensualesJob', 'k2');
insert into public.batch_job_execution values (10, 0, 1, timestamp '2026-09-12 19:00:00', timestamp '2026-09-12 19:00:00',
    timestamp '2026-09-12 19:05:41', 'COMPLETED', 'COMPLETED', '', timestamp '2026-09-12 19:05:41');
insert into public.batch_job_execution values (11, 0, 2, timestamp '2026-09-12 20:00:00', timestamp '2026-09-12 20:00:00',
    timestamp '2026-09-12 20:01:00', 'FAILED', 'FAILED', 'calidad inaceptable', timestamp '2026-09-12 20:01:00');
insert into public.batch_step_execution (step_execution_id, version, step_name, job_execution_id, create_time, status)
    values (100, 0, 'cuarentenaAvisoStep', 10, timestamp '2026-09-12 19:05:00', 'COMPLETED');
insert into public.batch_step_execution (step_execution_id, version, step_name, job_execution_id, create_time, status)
    values (101, 0, 'cuarentenaCorteStep', 11, timestamp '2026-09-12 20:01:00', 'COMPLETED');

-- cuenta_interes: la cuenta 101 aparece dos veces; la fila 2 lleva la marca de repetida y NO es la canonica.
-- La 102 canonica tiene OTRA observacion (no la marca): igual es canonica. La fila 7 concatena la marca con otra.
insert into public.cuenta_interes values (1, 101, 'Diana Prince', 'ahorro', 30, 8000, 0.00500, 40.00, 8040.00, false, null, 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (2, 101, 'Jane Smith', 'prestamo', 40, 7000, 0.01500, 105.00, 7105.00, true, 'La cuenta aparece mas de una vez en el archivo con datos distintos', 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (3, 102, 'Jane Smith', 'ahorro', 35, 5000, 0.00000, 0.00, 5000.00, true, 'Titular repetido con los mismos datos en otra cuenta', 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (4, 103, 'Jane Smith', 'prestamo', 45, 7000, 0.01500, 105.00, 7105.00, false, null, 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (5, 104, 'Sin identificar', 'hipoteca', 50, 5000, 0.00900, 45.00, 5045.00, true, 'Titular sin identificar en el archivo legacy', 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (6, 105, 'Diana Prince', 'ahorro', 70, 12000, 0.00600, 72.00, 12072.00, false, 'Bonificacion de tercera edad aplicada (+0.00100)', 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (7, 102, 'Bob Johnson', 'hipoteca', 30, 9000, 0.00900, 81.00, 9081.00, true, 'La cuenta aparece mas de una vez en el archivo con datos distintos; Titular repetido con los mismos datos en otra cuenta', 10, timestamp '2026-09-12 19:01:00');
insert into public.cuenta_interes values (8, 101, 'Atacante', 'ahorro', 30, 999999, 0, 0, 999999.00, false, null, 11, timestamp '2026-09-12 20:00:30');
insert into public.cuenta_interes values (9, 199, 'Atacante', 'ahorro', 30, 999999, 0, 0, 999999.00, false, null, 11, timestamp '2026-09-12 20:00:30');

insert into public.movimiento_anual values (1, 101, date '2024-12-24', 2024, 'deposito', 3000.00, 'Ingreso navideño', true, 'Tipo normalizado desde la escritura con tilde del archivo legacy: depósito', 10, timestamp '2026-09-12 19:02:00');
insert into public.movimiento_anual values (2, 101, date '2024-11-10', 2024, 'retiro', -1500.00, 'Retiro parcial', false, null, 10, timestamp '2026-09-12 19:02:00');
insert into public.movimiento_anual values (3, 101, date '2024-10-05', 2024, 'compra', -100.00, 'Compra en tienda', false, null, 10, timestamp '2026-09-12 19:02:00');
insert into public.movimiento_anual values (4, 102, date '2024-09-01', 2024, 'deposito', 2000.00, 'Ingreso mensual', false, null, 10, timestamp '2026-09-12 19:02:00');
insert into public.movimiento_anual values (5, 101, date '2025-01-01', 2025, 'deposito', 999999.00, 'No publicado', false, null, 11, timestamp '2026-09-12 20:00:30');

insert into public.estado_cuenta_anual values (1, 101, 2024, 3, 3000.00, 1600.00, 1400.00, date '2024-10-05', date '2024-12-24', 1, 10, timestamp '2026-09-12 19:03:00');
insert into public.estado_cuenta_anual values (2, 102, 2024, 1, 2000.00, 0.00, 2000.00, date '2024-09-01', date '2024-09-01', 0, 10, timestamp '2026-09-12 19:03:00');

insert into public.resumen_diario values (1, date '2024-06-29', 3, 1200.00, 3000.00, 3000.00, 1, 10, timestamp '2026-09-12 19:04:00');
insert into public.resumen_diario values (2, date '2024-06-30', 2, 200.00, 1500.00, 1500.00, 0, 10, timestamp '2026-09-12 19:04:00');

insert into public.registro_rechazado values (1, 'calculoInteresesMensualesJob', 'intereses.csv', 'OMITIDO', 5, '114,Unknown,,30,-1', 'Saldo vacio', 10, timestamp '2026-09-12 19:01:30');
insert into public.registro_rechazado values (2, 'calculoInteresesMensualesJob', 'intereses.csv', 'OMITIDO', 6, '137,Bob Johnson,7000,,prestamo', 'Edad vacia', 10, timestamp '2026-09-12 19:01:30');
insert into public.registro_rechazado values (3, 'calculoInteresesMensualesJob', 'intereses.csv', 'FILTRADO', 7, '133,Alice Brown,12000,100,hipoteca', 'Duplicado', 10, timestamp '2026-09-12 19:01:30');
insert into public.registro_rechazado values (4, 'estadosCuentaAnualesJob', 'cuentas_anuales.csv', 'OMITIDO', 8, '110,24-07-2024,retiro,,', 'Monto vacio', 10, timestamp '2026-09-12 19:02:30');
insert into public.registro_rechazado values (5, 'reporteTransaccionesDiariasJob', 'transacciones.csv', 'OMITIDO', 9, '4,04/05/2024,,invalid', 'Tipo invalido', 10, timestamp '2026-09-12 19:04:30');
insert into public.registro_rechazado values (6, 'calculoInteresesMensualesJob', 'intereses.csv', 'OMITIDO', 10, 'x', 'De la corrida fallida', 11, timestamp '2026-09-12 20:00:30');

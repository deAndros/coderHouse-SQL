USE hospital_borda_v2;

##############################  FUNCIONES  ##############################

/*
fn_cantidad_pacientes_por_profesional:
Devuelve el número equivalente a la cantidad de pacientes que son atendidos por el profesional que se ingresa por parámetro.
Se recomienda probar esta función luego de insertar a un paciente utilizando el procedimiento "sp_alta_paciente". 
Esto se debe a que el dataset que se tomó para popular la base asignó a un paciente para cada profesional*/     
CREATE FUNCTION fn_cantidad_pacientes_por_profesional (idProfesional INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
RETURN (
	SELECT COUNT(*) 
	FROM profesionales_pacientes pp 
	WHERE pp.id_profesional = idProfesional
);
SELECT fn_cantidad_pacientes_por_profesional(1);

/*
fn_promedio_edad_pacientes_por_servicio:
Devuelve el promedio de edad de los pacientes que integran el servicio que se ingresa por parámetro*/
CREATE FUNCTION fn_promedio_edad_pacientes_por_servicio (idServicio INT)
RETURNS DOUBLE
READS SQL DATA
RETURN (
	SELECT AVG(p.edad) 
    FROM pacientes p
    WHERE p.id_servicio = idServicio
);
SELECT fn_promedio_edad_pacientes_por_servicio(1);

/*
fn_cantidad_cajas_farmaco_recibidas_por_periodo:
Retorna la cantidad de cajas del fármaco enviado por parámetro cuyos pedidos fueron recibidos y su fecha de entrega pactada está comprendida en el intervalo que pasa por parámetro*/
CREATE FUNCTION fn_cantidad_cajas_farmaco_recibidas_por_periodo (idFarmaco INT, fecha_desde DATE, fecha_hasta DATE)
RETURNS INT
READS SQL DATA
RETURN (
	SELECT sum(cantidad_cajas)
    FROM pedidos_farmacos pf
    JOIN pedidos p ON p.id = pf.id_pedido
    WHERE p.fecha_entrega_pactada >= DATE(fecha_desde) 
		AND p.fecha_entrega_pactada <= DATE(fecha_hasta) 
        AND p.recibido = 1 
        AND pf.id_farmaco = idFarmaco
);
SELECT fn_cantidad_cajas_farmaco_recibidas_por_periodo(2,'2023-01-28','2023-12-31');  
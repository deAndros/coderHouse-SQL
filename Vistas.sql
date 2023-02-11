USE hospital_borda_v2;

##############################  VISTAS  ##############################

/*
vw_pacientes_profesionales:
Ofrece una vista simplificada en donde se puede ver qué profesionales atienden a cada paciente.
A la hora de la gestión hospitalaria es muy importante saber cuál es el médico de cabecera de cada paciente para poder hacer un seguimiento de cada caso.
Los curadores, por ejemplo, directamente piden hablar con los médicos de cabecera del paciente que tienen a su cargo legal. Con esta vista, cualquiera que
esté encargado de recibir a los curadores en sus visitas diarias al hospital sabrá a qué profesional lo tiene que remitir.*/
CREATE OR REPLACE VIEW vw_pacientes_profesionales AS (
	SELECT concat(pac.nombre, ' ', pac.apellido) AS 'Paciente', 
		   concat(pro.nombre, ' ', pro.apellido) AS 'Profesional a cargo',
           prof.nombre AS 'Especialidad profesional'
	FROM hospital_borda_v2.profesionales_pacientes pp
    JOIN hospital_borda_v2.pacientes pac ON pac.id = pp.id_paciente
    JOIN hospital_borda_v2.profesionales pro ON pro.id = pp.id_profesional
    JOIN hospital_borda_v2.profesiones prof ON prof.id = pro.id_profesion 
    ORDER BY 1 DESC
);
SELECT * FROM vw_pacientes_profesionales;

/*
vw_detalle_recetas:
Vista que permite consultar el detalle de los fármacos que fueron recetados a los pacientes, la metodología de administración y qué profesional los recetó.
Con esta vista cualquier enfermero podrá saber de qué manera y en qué días deberá suministrarle la medicación a los pacientes.*/    
CREATE OR REPLACE VIEW vw_detalle_recetas AS(
	SELECT r.id AS 'Número de receta',
		   concat(pac.nombre, ' ', pac.apellido) AS 'Paciente',
		   concat(pro.nombre, ' ', pro.apellido) AS 'Profesional recetante',
           f.nombre AS 'Fármaco recetado',
           f.droga AS 'Droga',
           r.dias_administracion AS 'Días de administración',
           r.horario_administracion AS 'Horario de administración'
    FROM hospital_borda_v2.recetas r
    JOIN hospital_borda_v2.pacientes pac ON pac.id = r.id_paciente
    JOIN hospital_borda_v2.profesionales pro ON pro.id = r.id_prescriptor
    JOIN hospital_borda_v2.farmacos f ON f.id = r.id_farmaco
    ORDER BY pac.apellido, pac.nombre ASC
);
SELECT * FROM vw_detalle_recetas ORDER BY 2;

/*
vw_curadores_de_pacientes:
Vista detallada de los curadores de cada paciente. Muestra información del curador que representa legalmente al paciente en el juzgado.
Esta vista es muy util ya que permite a los encargados de los servicios saber quién es el apoderado legal (curador) de cada paciente.*/
CREATE OR REPLACE VIEW vw_curadores_de_pacientes AS(
	SELECT concat(pac.nombre, ' ', pac.apellido) AS 'Paciente',
		   concat(cur.nombre, ' ', cur.apellido) AS 'Curador a cargo',
           cur.dni AS 'DNI curador',
           cur.telefono AS 'Teléfono curador',
           cur.mail AS 'Mail curador'
	FROM hospital_borda_v2.pacientes pac
	JOIN hospital_borda_v2.curadores cur ON cur.id = pac.id_curador
    GROUP BY pac.id
    ORDER BY cur.apellido, cur.nombre ASC
);
SELECT * FROM vw_curadores_de_pacientes ORDER BY 2;

/*
vw_pedidos_farmacos_no_recibidos:
Muestra qué farmacos fueron los que se pidieron y aún no han sido recibidos. Incluye a aquellos cuya fecha de entrega pactada ya expiró y a los que no.
Para validar si esta vista es correcta se recomienda ejecutarla luego de invocar manualmente al procedimiento "sp_demarcar_pedidos_expirados".
Esta vista permite a los encargados de la enfermería hacer un seguimiento de los pedidos y establecer estadísticas/tableros sobre cuáles son los medicamentos que tienen faltante en el mercado.
Cuando un medicamento escasea, los psiquiatras pueden modificar las recetas de los pacientes y cambiarlo por un medicamento alternativo*/    
CREATE OR REPLACE VIEW vw_pedidos_farmacos_no_recibidos AS(
	SELECT p.id AS 'Número de pedido',
		   p.fecha_emision AS 'Fecha de emisión',
           p.fecha_entrega_pactada AS 'Fecha de entrega pactada',
           CASE p.expirado
				WHEN 1 THEN 'SÍ'
				WHEN 0 THEN 'NO'
		   END AS '¿Está expirado?',
           f.nombre AS 'Fármaco del pedido',
           pf.cantidad_cajas AS 'Cantidad de cajas'
    FROM hospital_borda_v2.pedidos p      
	JOIN hospital_borda_v2.pedidos_farmacos pf ON p.id = pf.id_pedido
    JOIN hospital_borda_v2.farmacos f ON f.id = pf.id_farmaco
    WHERE p.recibido = false
    GROUP BY p.id
    ORDER BY p.fecha_emision DESC
);
SELECT * FROM vw_pedidos_farmacos_no_recibidos ORDER BY 4;

/*
vw_pacientes_con_escolarizacion_precaria:
Muestra a todos los pacientes que poseen escolarización precaria, es decir, un nivel de educación inferior al secundario.
Esta vista es útil para que los trabajadores sociales tengan un paneo general sobre aquellos pacientes que necesitan su asistencia para poder mejorar su nivel educativo.*/           
CREATE OR REPLACE VIEW vw_pacientes_con_escolarizacion_precaria AS (
	SELECT concat(pac.nombre, ' ', pac.apellido) AS 'Paciente',
           pac.dni AS 'DNI paciente',
           hc.escolarizacion AS 'Nivel de escolarización'
    FROM hospital_borda_v2.historias_clinicas hc
    JOIN hospital_borda_v2.pacientes pac ON pac.id = hc.id_paciente 
    WHERE hc.escolarizacion IN ('PRIMARIA INCOMPLETA', 'PRIMARIA', 'SECUNDARIA INCOMPLETA', NULL)
    ORDER BY pac.apellido, pac.nombre ASC           
);
SELECT * FROM vw_pacientes_con_escolarizacion_precaria ORDER BY 3;

/*
vw_pacientes_por_servicio
Muestra la cantidad de pacientes que tiene cada servicio y el promedio de edad de los mismos. Esta vista es particularmente util para el armado de tableros o estadísticas*/
CREATE OR REPLACE VIEW vw_pacientes_por_servicio AS (
	SELECT  count(pac.nombre) AS 'Cantidad de Pacientes', 
		pac.id_servicio AS 'Servicio', 
		AVG(pac.edad) AS 'Promedio de Edad'
	FROM pacientes pac 
	GROUP BY id_servicio ORDER BY 2
);
SELECT * FROM vw_pacientes_por_servicio;
USE hospital_borda_v2;

############################  STORED PROCEDURES  ############################

/*
sp_demarcar_pedidos_expirados:
Procedimiento que marca como expirados a aquellos pedidos, ya sean de insumos o de farmacos, cuya fecha de entrega pactada sea previa a la fecha actual y no se hayan recibido.*/
DELIMITER $$
CREATE PROCEDURE sp_demarcar_pedidos_expirados ()
BEGIN
	UPDATE pedidos p
		SET p.expirado = 1 
        WHERE p.fecha_entrega_pactada < DATE(NOW()) AND p.recibido = 0;
END
$$
CALL sp_demarcar_pedidos_expirados ();

/*
sp_pacientes_con_farmaco_recetado:
Procedimiento que recibe un paciente por parámetro y retorna todos los fármacos que le hayan sido recetados, junto con la receta y el prescriptor.*/
DELIMITER $$
CREATE PROCEDURE sp_pacientes_con_farmaco_recetado (idPaciente INT)
BEGIN
	SELECT 
    r.id AS "Número de Receta", 
    concat(pro.nombre, ' ', pro.apellido) AS 'Prescriptor',
	concat(p.nombre, ' ', p.apellido) AS 'Paciente',
    f.nombre AS "Nombre Fármaco"
    FROM recetas r 
    JOIN pacientes p ON r.id_paciente = p.id
    JOIN farmacos f ON r.id_farmaco = f.id
    JOIN profesionales pro ON r.id_prescriptor = pro.id
    WHERE r.id_paciente = idPaciente 
    ORDER BY p.apellido, p.nombre ASC; 
END
$$
CALL sp_pacientes_con_farmaco_recetado (94);

/*
sp_historial_clinico:
Retorna el historial clínico de un paciente que se recibe por parámetro, es decir, todos los registros de su historia clínica desde que el paciente fue dado de alta en el hospital.*/
DELIMITER $$
CREATE PROCEDURE sp_historial_clinico (idPaciente INT)
BEGIN
	SELECT 
        concat(p.nombre, ' ', p.apellido) AS 'Paciente',
        bhc.fecha_modificacion AS 'Fecha de modificación',
        bhc.numero_historia_electronica AS 'Número de historia electrónica',
        bhc.diagnostico_presuntivo AS 'Diagnóstico presuntivo',
        (SELECT concat(pro.nombre, ' ', pro.apellido) FROM profesionales pro WHERE pro.id = bhc.id_firmante_diagnostico_presuntivo) AS 'Firmante diagnóstico presuntivo',
        bhc.psiquiatria AS 'Psiquiatría',
        (SELECT concat(pro.nombre, ' ', pro.apellido) FROM profesionales pro WHERE pro.id = bhc.id_firmante_psiquiatria) AS 'Firmante psiquiatría',
        bhc.psicologia AS 'Psicología',
        (SELECT concat(pro.nombre, ' ', pro.apellido) FROM profesionales pro WHERE pro.id = bhc.id_firmante_psicologia) AS 'Firmante psicología',
        bhc.servicio_social AS 'Servicio social',
        (SELECT concat(pro.nombre, ' ', pro.apellido) FROM profesionales pro WHERE pro.id = bhc.id_firmante_servicio_social) AS 'Firmante servicio social',
        bhc.situacion_habitacional AS 'Situación Habitacional',
        p.numero_cud AS 'Número CUD',
        bhc.fiscalia_interviniente AS 'Fiscalía interviniente',
		concat(c.nombre, ' ', c.apellido) AS 'Curador a cargo',
        p.telefono AS 'Teléfono del paciente',
        p.telefono_familiar AS 'Teléfono de contacto familiar',
        p.obra_social AS 'Obra social',
        CASE p.cobra_pension
			WHEN 1 THEN 'SÍ'
            WHEN 0 THEN 'NO'
        END AS '¿Cobra pensión?',
        bhc.escolarizacion AS 'Nivel de escolarizacion'
    FROM pacientes p 
    JOIN bitacora_historias_clinicas bhc ON bhc.id_paciente = p.id
    JOIN curadores c ON p.id_curador = c.id
    WHERE bhc.id_paciente = idPaciente
    ORDER BY bhc.fecha_modificacion DESC;
END
$$
CALL sp_historial_clinico (1); -- Se utiliza al paciente de ID uno porque es el que utilicé para generar UPDATES en el archivo de populación.

##############################  TCL  ##############################
/*
Este procedimiento lleva a cabo un alta completa de paciente. Primero inserta en la tabla de pacientes, luego genera una historia clínica para el paciente con valores por default.
Por ultimo, recorre todas las profesiones disponibles en la tabla profesiones, toma de c/u al profesional que menos pacientes atienda y le asigna a cada profesional la atención del nuevo paciente.*/
DELIMITER $$
CREATE PROCEDURE sp_alta_paciente(
	IN idServicio INT, 
    IN nombrePaciente VARCHAR(45), 
    IN apellidoPaciente VARCHAR(45), 
    IN dniPaciente INT, 
    IN edadPaciente TINYINT, 
    IN paisPaciente INT,
    IN telPaciente INT,
    IN telFamiliar INT,
    IN idCurador INT,
    IN obraSocial VARCHAR(45),
    IN cobraPension BOOLEAN,
    IN numeroCud VARCHAR(70)
)
altaPaciente: BEGIN
	-- Declaro variables para el manejo de errores
	DECLARE code CHAR(5) DEFAULT '00000';
	DECLARE msg TEXT;
	DECLARE nrows INT;
	DECLARE result TEXT;
    -- Declaro variables de control de flujo
    DECLARE i INT;
    DECLARE profesionalConMenosPacientes INT;
    DECLARE cantidadProfesiones INT;
    
    -- Declaro handler para inserts fallidos
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1
		code = RETURNED_SQLSTATE, msg = MESSAGE_TEXT;
    END;
    
	SET @@AUTOCOMMIT = 0;
	
    START TRANSACTION;
    
    -- Se inserta el paciente en la tabla de pacientes
	INSERT INTO pacientes (id_servicio, nombre, apellido, dni, edad, id_pais_origen, telefono, telefono_familiar, id_curador, obra_social, cobra_pension, numero_cud)
	VALUES (idServicio, nombrePaciente, apellidoPaciente, dniPaciente, edadPaciente, paisPaciente, telPaciente, telFamiliar, idCurador, obraSocial, cobraPension, numeroCud);

	IF code = '00000' THEN
		GET DIAGNOSTICS nrows = ROW_COUNT;
		SET result = CONCAT('Inserción OK, Cantidad de Filas = ',nrows);
        SAVEPOINT nuevo_paciente;
	ELSE
		SET result = CONCAT('Inserción FALLÓ, Error = ', code,', Mensaje = ',msg);
        SELECT result;
        LEAVE altaPaciente;
	END IF;
    
    -- Se crea una nueva historia clínica para ese paciente, asignando valores por default
	INSERT INTO historias_clinicas (id_paciente, estado, fecha_modificacion) 
		VALUES ((SELECT id FROM pacientes WHERE dni = dniPaciente), 'CONFIGURACIÓN INICIAL', NOW()); -- Preguntar por qué no me toma el valor default de la declaración de la tabla para la fecha_modificacion
    
    IF code = '00000' THEN
		GET DIAGNOSTICS nrows = ROW_COUNT;
		SET result = CONCAT('Inserción OK, Cantidad de Filas = ',nrows);
        SAVEPOINT nueva_historia_clinica;
	ELSE
		SET result = CONCAT('Inserción FALLÓ, Error = ', code,', Mensaje = ',msg);
        ROLLBACK TO nuevo_paciente;
	END IF;
    
    -- Busco, por cada profesión, al profesional que menos pacientes tenga.
	SET i = 0;
    asignarProfesionalConMenosPacientes : LOOP
		SET i = i + 1;
        
        IF i > (SELECT COUNT(*) FROM profesiones) THEN 
			LEAVE asignarProfesionalConMenosPacientes;
		END IF;
        
		SELECT id_profesional INTO profesionalConMenosPacientes
			FROM profesionales_pacientes
			WHERE id_profesion = i 
			GROUP BY id_profesional
			ORDER BY count(1), id_profesional ASC
			LIMIT 1;
        
        INSERT INTO profesionales_pacientes (id_profesional, id_paciente, id_profesion)
			VALUES (profesionalConMenosPacientes, (SELECT id FROM pacientes WHERE dni = dniPaciente), i);
        
        IF code = '00000' THEN
			GET DIAGNOSTICS nrows = ROW_COUNT;
			SET result = CONCAT('Inserción OK, Cantidad de Filas = ',nrows);
            COMMIT;
		ELSE
			SET result = CONCAT('Inserción FALLÓ, Error = ', code,', Mensaje = ',msg);
            ROLLBACK TO nueva_historia_clinica;
		END IF;
    END LOOP asignarProfesionalConMenosPacientes;
    
    -- Retorno el resultado
    SELECT result;
    
	RELEASE SAVEPOINT nuevo_paciente;
    RELEASE SAVEPOINT nueva_historia_clinica;
    
    SET @@AUTOCOMMIT = 1;
END
$$
    
CALL sp_alta_paciente(1, 'Gonzalo', 'Ramos', 34145519, 20, 5, 1133467926, 1125127926, 2, 'OSDE', 1, '11-33342-1125');
-- Verificación del resultado del procedimiento
SELECT * FROM pacientes ORDER BY id DESC;
SELECT * FROM profesionales;
SELECT * FROM historias_clinicas ORDER BY id_paciente DESC;
SELECT * FROM bitacora_historias_clinicas ORDER BY id_paciente DESC;
SELECT * FROM profesionales_pacientes WHERE id_profesion = 1 ORDER BY id_paciente DESC;


##############################  EVENT SCHEDULER  ##############################

DELIMITER $$
CREATE DEFINER=`root`@`localhost` EVENT `es_demarcar_pedidos_expirados` 
ON SCHEDULE EVERY 1 WEEK 
STARTS '2023-02-26 18:19:02' ON COMPLETION NOT PRESERVE ENABLE 
DO 
CALL sp_demarcar_pedidos_expirados ();
$$

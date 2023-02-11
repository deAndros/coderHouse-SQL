USE hospital_borda_v2;

##############################  TRIGGERS  ##############################

/*
tr_default_fecha_ingesta:
Como en la tabla de ingestas las fechas no son en formato DATETIME (porque no es requerido funcionalmente), 
se creó un trigger que transforma el resultado de la función NOW() en un tipo DATE y lo almacena como valor por default cuando la fecha_ingesta se inserta como nula.*/
DELIMITER $$
CREATE TRIGGER tr_default_fecha_ingesta
    BEFORE INSERT
    ON ingestas_farmacos FOR EACH ROW
BEGIN
	IF NEW.fecha_ingesta IS NULL THEN	
		SET NEW.fecha_ingesta = DATE(NOW());
	END IF;
END$$

/*
tr_replicar_insert_en_bitacora_historias_clinicas:
Trigger utilizado para replicar los datos que se insertan en la tabla de historias_clinicas en la tabla bitácora de forma tal de que esta sea una tabla "historial".*/
DELIMITER $$
CREATE TRIGGER tr_replicar_insert_en_bitacora_historias_clinicas
    AFTER INSERT
    ON historias_clinicas FOR EACH ROW
BEGIN
		INSERT INTO bitacora_historias_clinicas (
			id_historia_clinica,
			id_paciente,
            estado,
			fecha_modificacion,
            numero_historia_electronica,
            id_firmante_diagnostico_presuntivo, 
            diagnostico_presuntivo, 
            id_firmante_psiquiatria, 
            psiquiatria,
            id_firmante_psicologia, 
            psicologia, 
            id_firmante_servicio_social, 
            servicio_social, 
            situacion_habitacional,
            fiscalia_interviniente,
            escolarizacion)
		VALUES (
			NEW.id,
            NEW.id_paciente, 
            NEW.estado,
			NEW.fecha_modificacion, 
            NEW.numero_historia_electronica,
            NEW.id_firmante_diagnostico_presuntivo, 
            NEW.diagnostico_presuntivo, 
            NEW.id_firmante_psiquiatria,
            NEW.psiquiatria,
            NEW.id_firmante_psicologia, 
            NEW.psicologia, 
            NEW.id_firmante_servicio_social, 
            NEW.servicio_social,
            NEW.situacion_habitacional,
            NEW.fiscalia_interviniente,
            NEW.escolarizacion);
END$$


/*
tr_replicar_update_en_bitacora_historias_clinicas:
Trigger utilizado para replicar los datos que se actualizan en la tabla de historias_clinicas en la tabla bitácora de forma tal de que esta sea una tabla "historial".*/
DELIMITER $$
CREATE TRIGGER tr_replicar_update_en_bitacora_historias_clinicas
    AFTER UPDATE
    ON historias_clinicas FOR EACH ROW
BEGIN
		INSERT INTO bitacora_historias_clinicas (
			id_historia_clinica,
			id_paciente,
            estado,
			fecha_modificacion,
            numero_historia_electronica,
            id_firmante_diagnostico_presuntivo, 
            diagnostico_presuntivo, 
            id_firmante_psiquiatria, 
            psiquiatria,
            id_firmante_psicologia, 
            psicologia, 
            id_firmante_servicio_social, 
            servicio_social, 
            situacion_habitacional,
            fiscalia_interviniente,
            escolarizacion)
		VALUES (
			NEW.id,
            NEW.id_paciente, 
            NEW.estado,
			NEW.fecha_modificacion, 
            NEW.numero_historia_electronica,
            NEW.id_firmante_diagnostico_presuntivo, 
            NEW.diagnostico_presuntivo, 
            NEW.id_firmante_psiquiatria,
            NEW.psiquiatria,
            NEW.id_firmante_psicologia, 
            NEW.psicologia, 
            NEW.id_firmante_servicio_social, 
            NEW.servicio_social,
            NEW.situacion_habitacional,
            NEW.fiscalia_interviniente,
            NEW.escolarizacion);
END$$

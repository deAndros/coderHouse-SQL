CREATE SCHEMA hospital_borda_v2;
USE hospital_borda_v2;

##############################  TABLAS  ##############################

/*
servicios:
Aquí se almacenan todos los servicios que ofrece el hospital. 
Un servicio sería como una especialidad, como una unidad compuesta de profesionales dedicados a atender pacientes con un determinado tipo de patología. 
Por ejemplo, está el servicio de guardia, pero también está el servicio de reinserción social, etc. 
Los profesionales no pueden trabajar en más de un servicio a la vez.*/
CREATE TABLE servicios(
	id INT NOT NULL AUTO_INCREMENT, 
    nombre VARCHAR(45) UNIQUE NOT NULL,
	descripcion VARCHAR(100),
    PRIMARY KEY (id)
);

/*
profesiones:
Tabla en la que se listan todas las profesiones que pueden tener los profesionales que trabajan en la institución (psicólogo/a, terapista ocupacional, psiquiatra, etc.). 
Las profesiones que no se encuentren en este listado corresponden a ramas académicas que no pueden desempeñarse en este tipo de instituciones.*/
CREATE TABLE profesiones(
	id INT NOT NULL AUTO_INCREMENT, 
    nombre VARCHAR(45) UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

/*
farmacos:
Tabla de dimensión en la que se registran los distintos fármacos que se utilizan en los servicios del hospital.*/
CREATE TABLE farmacos(
	id INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(45) NOT NULL UNIQUE,
    laboratorio VARCHAR(200),
    droga VARCHAR(200) NOT NULL,
    PRIMARY KEY (id)
);

/*
insumos:
Lugar en el que se registran los distintos tipos de insumos (que no sean fármacos) que se utilizan en los diferentes servicios del hospital como, por ejemplo, barbijos, guantes, sillas de ruedas, etc.*/
CREATE TABLE insumos(
	id INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(45) NOT NULL,
    tipo VARCHAR(45) NOT NULL,
    PRIMARY KEY (id)
);

/*
paises:
Tabla de dimensiones en la que se almacenan los nombres de los países.*/
CREATE TABLE paises (
  id INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(250) NOT NULL,
  PRIMARY KEY (id)
);

/*
curadores:
En esta tabla se almacenan los datos de los curadores de los pacientes. Un curador es un apoderado legal que la fiscalía le asigna a cada paciente. 
Tiene como rol hacer el seguimiento jurídico del paciente y procurar que perciba sus asignaciones.*/
CREATE TABLE curadores(
	id INT NOT NULL AUTO_INCREMENT,
    dni INT NOT NULL UNIQUE,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
	telefono INT NOT NULL,
    mail VARCHAR(45) NOT NULL,
    PRIMARY KEY (id)
);

/*
profesionales:
Tabla en la que se almacenan todos los datos inherentes a los profesionales que trabajan en la institución. 
Entre estos datos está el servicio en el que trabajan, su ficha municipal (si la tiene) y sus datos de contacto.*/
CREATE TABLE profesionales(
	id INT NOT NULL AUTO_INCREMENT,
    dni INT UNIQUE NOT NULL,
    id_profesion INT NOT NULL,
    id_servicio INT NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    edad TINYINT NOT NULL,
    id_pais_origen INT NOT NULL,
    telefono INT UNIQUE NOT NULL,
    mail VARCHAR(45) UNIQUE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (id_servicio) REFERENCES servicios(id),
    FOREIGN KEY (id_profesion) REFERENCES profesiones(id),
    FOREIGN KEY (id_pais_origen) REFERENCES paises(id)
);

/*
fichas:
En esta tabla se listan todas las fichas municipales correspondientes a los profesionales que trabajan en la institución. 
Los profesionales pueden no tener una ficha (ya sea porque son pasantes o porque aún la están tramitando). 
Estas fichas habilitan a los profesionales para ejercer en los hospitales públicos.*/
CREATE TABLE fichas(
	id INT NOT NULL AUTO_INCREMENT, 
    id_profesional INT,
    numero INT,
    fecha_emision DATE,
    PRIMARY KEY (id),
    FOREIGN KEY (id_profesional) REFERENCES profesionales(id)
);

/*
pacientes:
En esta tabla se almacena todos los datos concernientes a los pacientes. Cabe aclarar que un paciente no puede pertenecer a más de un servicio.*/
CREATE TABLE pacientes(
	id INT NOT NULL AUTO_INCREMENT,
    id_servicio INT,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    dni INT UNIQUE,
    edad TINYINT,
    id_pais_origen INT,
    telefono INT,
    telefono_familiar INT,
    id_curador INT,
	obra_social VARCHAR(45),
    cobra_pension BOOLEAN,
    numero_cud VARCHAR(70) DEFAULT 'NO REGISTRADO',
	PRIMARY KEY (id),
    FOREIGN KEY (id_servicio) REFERENCES servicios(id),
    FOREIGN KEY (id_curador) REFERENCES curadores(id),
    FOREIGN KEY (id_pais_origen) REFERENCES paises(id)
);


/*profesionales_pacientes:
Tabla intermedia en la que se asocian a los profesionales con los pacientes.
Cabe aclarar que, a excepción de los enfermeros, los pacientes solo pueden ser atendidos por un solo profesional para cada tipo de profesión, es decir: un paciente solo puede ser atendido por un psicólogo, por un terapista ocupacional, por un psiquiatra, por un asistente social y por varios enfermeros.*/
CREATE TABLE profesionales_pacientes(
	id_profesional INT NOT NULL, 
    id_paciente INT NOT NULL,
    id_profesion INT NOT NULL,
    PRIMARY KEY (id_profesional, id_paciente, id_profesion),
    FOREIGN KEY (id_profesional) REFERENCES profesionales(id),
	FOREIGN KEY (id_paciente) REFERENCES pacientes(id),
	FOREIGN KEY (id_profesion) REFERENCES profesiones(id)
);

/*
historias_clinicas:
Aquí se almacenan todos los datos concernientes a la historia clínica de los pacientes. 
Estos datos pueden ir variando a la largo del tiempo y deben contar con la rúbrica/firma del profesional que los modificó. 
Los campos suceptibles de tener rúbrica son: diagnostico_presuntivo, psiquiatria, psicología y servicio_social. 
La unicidad de los registros está dada por el ID de la historia clínica (id) y el id del paciente.
Los registros de esta tabla se corresponden con la ultima actualización correspondiente a cada historia clínica.*/
CREATE TABLE historias_clinicas(
	id INT NOT NULL AUTO_INCREMENT,
    id_paciente INT NOT NULL UNIQUE,
    estado VARCHAR(45) NOT NULL DEFAULT 'ABIERTA',
    fecha_modificacion DATETIME DEFAULT NOW(),
    numero_historia_electronica INT, #SIGEOS: Programa en donde se registran las historias clínicas cuando alguien se atiende en el gobierno de la ciudad
    id_firmante_diagnostico_presuntivo INT,
    diagnostico_presuntivo VARCHAR(500),
    id_firmante_psiquiatria INT,
    psiquiatria VARCHAR(500), #Campo en el que se completa lo que el psiquiatra ve del paciente y las intervenciones que hizo.
    id_firmante_psicologia INT,
    psicologia VARCHAR(500), #Campo en el que se completa lo que el psicólogo ve del paciente junto con la descripción de las conductas que este tiene.
    id_firmante_servicio_social INT,
    servicio_social VARCHAR(500), #Campo en el que los trabajadores sociales vuelcan el detalle de las intervenciones que realizaron con el paciente.
    situacion_habitacional VARCHAR(500),
    fiscalia_interviniente VARCHAR(100),
	escolarizacion VARCHAR(45),
    PRIMARY KEY (id),
    FOREIGN KEY (id_firmante_diagnostico_presuntivo) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_psiquiatria) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_psicologia) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_servicio_social) REFERENCES profesionales(id),
	FOREIGN KEY (id_paciente) REFERENCES pacientes(id),
    CONSTRAINT cs_estado CHECK (estado IN ('CONFIGURACIÓN INICIAL', 'ABIERTA', 'REABIERTA', 'CERRADA')),
    CONSTRAINT cs_escolarizacion CHECK (escolarizacion IN ('NO POSEE', 'PRIMARIA', 'PRIMARIA INCOMPLETA', 'SECUNDARIA', 'SECUNDARIA INCOMPLETA', 'TERCIARIA', 'TERCIARIA INCOMPLETA', 'UNIVERSITARIA', 'UNIVERSITARIA INCOMPLETA'))
);

/*
bitacora_historias_clinicas:
Esta tabla funciona como tabla histórica de historias_clinicas y almacena como registro todos aquellos cambios que devengan de inserciones o updates sobre dicha tabla.
Esto se consigue mediante el uso de dos triggers*/
CREATE TABLE bitacora_historias_clinicas(
	id_log INT NOT NULL AUTO_INCREMENT,
    id_historia_clinica INT NOT NULL,
    id_paciente INT NOT NULL,
    estado VARCHAR(45) NOT NULL DEFAULT 'ABIERTA',
    fecha_modificacion DATETIME DEFAULT NOW(),
    numero_historia_electronica INT,
    id_firmante_diagnostico_presuntivo INT,
    diagnostico_presuntivo VARCHAR(500),
    id_firmante_psiquiatria INT,
    psiquiatria VARCHAR(500),
    id_firmante_psicologia INT,
    psicologia VARCHAR(500),
    id_firmante_servicio_social INT,
    servicio_social VARCHAR(500),
    situacion_habitacional VARCHAR(500),
    fiscalia_interviniente VARCHAR(100),
	escolarizacion VARCHAR(45),
    PRIMARY KEY (id_log),
    FOREIGN KEY (id_historia_clinica) REFERENCES historias_clinicas(id),
	FOREIGN KEY (id_firmante_diagnostico_presuntivo) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_psiquiatria) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_psicologia) REFERENCES profesionales(id),
	FOREIGN KEY (id_firmante_servicio_social) REFERENCES profesionales(id),
	FOREIGN KEY (id_paciente) REFERENCES pacientes(id)
);

/*
pedidos:
Aquí se almacenan todos los pedidos de insumos o fármacos que emite cada servicio del hospital.*/
CREATE TABLE pedidos(
	id INT NOT NULL AUTO_INCREMENT,
    id_servicio INT NOT NULL,
    tipo VARCHAR(45) NOT NULL, #FÁRMACO o INSUMO son los valores posibles 
    fecha_emision DATE NOT NULL,
    fecha_entrega_pactada DATE NOT NULL,
    recibido BOOLEAN NOT NULL DEFAULT 0,
    expirado BOOLEAN NOT NULL DEFAULT 0,
	PRIMARY KEY (id),
    FOREIGN KEY (id_servicio) REFERENCES servicios(id),
    CONSTRAINT cs_tipos_pedidos CHECK (tipo = 'FÁRMACO' OR tipo = 'INSUMO')
);

/*
pedidos_insumos:
Tabla intermedia que asocia los pedidos con los insumos. 
Debido a que la relación entre los insumos y los pedidos es de muchos a muchos (N:M), se optó por este tipo de tabla.
*/
CREATE TABLE pedidos_insumos(
	id_insumo INT NOT NULL,
    id_pedido INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_insumo, id_pedido),
    FOREIGN KEY (id_insumo) REFERENCES insumos(id),
	FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
);

/*
pedidos_farmacos:
Tabla intermedia que asocia los pedidos con los fármacos. 
Debido a que la relación entre los fármacos y los pedidos es de muchos a muchos (N:M), se optó por este tipo de tabla.
*/
CREATE TABLE pedidos_farmacos(
	id_farmaco INT NOT NULL,
    id_pedido INT NOT NULL,
    cantidad_cajas INT,
    PRIMARY KEY (id_farmaco, id_pedido),
    FOREIGN KEY (id_farmaco) REFERENCES farmacos(id),
	FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
);

/*
recetas:
Aquí se vuelcan las indicaciones para la ingesta de cada fármaco que deberán seguir los enfermeros al momento de administrarlos.
*/
CREATE TABLE recetas(
    id INT NOT NULL AUTO_INCREMENT,
    id_paciente INT NOT NULL,
    id_farmaco INT NOT NULL,
    id_prescriptor INT NOT NULL,
    comprimidos_recetados DOUBLE NOT NULL,
    dias_administracion VARCHAR(45) NOT NULL,
    horario_administracion VARCHAR(45) NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (id_paciente) REFERENCES pacientes(id),
	FOREIGN KEY (id_farmaco) REFERENCES farmacos(id),
	FOREIGN KEY (id_prescriptor) REFERENCES profesionales(id),
    CONSTRAINT cs_horario_administracion CHECK (horario_administracion = 'MAÑANA' OR horario_administracion = 'TARDE' OR horario_administracion = 'NOCHE')
);

/*
ingestas_farmacos:
Tabla de hecho en la que se registran los datos reales sobre la administración de los medicamentos a los pacientes por parte de los enfermeros. 
En la tabla “recetas”, se describe cómo deben administrarse los medicamentos; en esta tabla, en cambio, se registra de qué manera se administraron. 
*/
CREATE TABLE ingestas_farmacos(
    id INT NOT NULL AUTO_INCREMENT,
    id_paciente INT NOT NULL,
    id_receta INT NOT NULL,
    id_enfermero INT NOT NULL,
    fecha_ingesta DATE NOT NULL,
    comprimidos_administrados DOUBLE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (id_paciente) REFERENCES pacientes(id),
	FOREIGN KEY (id_receta) REFERENCES recetas(id),
	FOREIGN KEY (id_enfermero) REFERENCES profesionales(id)
);
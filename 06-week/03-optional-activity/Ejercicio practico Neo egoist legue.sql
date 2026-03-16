-- ============================================================
--  BLUE LOCK TV - SISTEMA DE VALORACIÓN LIGA NEO EGOÍSTA
--  Tema 4: Funciones Definidas por el Usuario (UDF)
--  Lenguaje: PL/pgSQL (PostgreSQL)
-- ============================================================


-- ============================================================
-- SECCIÓN 1: CREACIÓN DE TABLAS
-- ============================================================

-- Tabla de equipos participantes de la Liga Neo Egoísta
CREATE TABLE IF NOT EXISTS equipos (
    id_equipo     SERIAL PRIMARY KEY,
    nombre_equipo VARCHAR(50) NOT NULL,
    pais          VARCHAR(30) NOT NULL,
    presupuesto   NUMERIC(15, 2) DEFAULT 0
);

-- Tabla de jugadores
CREATE TABLE IF NOT EXISTS jugadores (
    id_jugador     SERIAL PRIMARY KEY,
    nombre_jugador VARCHAR(60) NOT NULL,
    posicion       VARCHAR(20) NOT NULL,
    id_equipo      INT REFERENCES equipos(id_equipo)
);

-- Tabla de estadísticas por partido
CREATE TABLE IF NOT EXISTS estadisticas_jugadores (
    id_estadistica SERIAL PRIMARY KEY,
    id_jugador     INT REFERENCES jugadores(id_jugador),
    goles          INT DEFAULT 0,
    asistencias    INT DEFAULT 0,
    partido        VARCHAR(60)
);


-- ============================================================
-- SECCIÓN 2: INSERCIÓN DE DATOS
-- ============================================================

-- Equipos de la Liga Neo Egoísta
INSERT INTO equipos (nombre_equipo, pais, presupuesto) VALUES
    ('Bastard München',  'Alemania',   500000000.00),
    ('Manshine City',    'Inglaterra', 480000000.00),
    ('Ubers',            'España',     460000000.00),
    ('FC Barcha',        'España',     440000000.00),
    ('PXG',              'Corea',      420000000.00);

-- Jugadores (referenciados por id_equipo en orden de INSERT)
INSERT INTO jugadores (nombre_jugador, posicion, id_equipo) VALUES
    ('Yoichi Isagi',    'Delantero',  1),  -- Bastard München
    ('Hyoma Chigiri',   'Extremo',    2),  -- Manshine City
    ('Shoei Barou',     'Delantero',  3),  -- Ubers
    ('Rin Itoshi',      'Mediapunta', 3),  -- Ubers
    ('Seishiro Nagi',   'Mediapunta', 1),  -- Bastard München
    ('Rensuke Kunigami','Delantero',  4),  -- FC Barcha
    ('Meguru Bachira',  'Extremo',    2),  -- Manshine City
    ('Sae Itoshi',      'Centrocampista', 5); -- PXG

-- Estadísticas por partido
INSERT INTO estadisticas_jugadores (id_jugador, goles, asistencias, partido) VALUES
    (1, 2, 1, 'Bastard München vs Manshine City'),
    (2, 1, 0, 'Bastard München vs Manshine City'),
    (3, 3, 0, 'Ubers vs FC Barcha'),
    (4, 1, 3, 'Ubers vs FC Barcha'),
    (5, 0, 2, 'Bastard München vs PXG'),
    (6, 2, 1, 'FC Barcha vs Manshine City'),
    (7, 1, 2, 'Manshine City vs PXG'),
    (8, 0, 4, 'PXG vs Ubers');


-- ============================================================
-- SECCIÓN 3: FUNCIONES DEFINIDAS POR EL USUARIO (UDF)
-- ============================================================

-- ------------------------------------------------------------
-- UDF 1: fn_calcular_bid_bluelock
-- Función ESCALAR: calcula el valor de mercado (bid) de un
-- jugador según sus goles y asistencias en un partido.
-- Retorna: NUMERIC (valor en yenes ¥)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calcular_bid_bluelock(
    p_goles       INT,
    p_asistencias INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_valor_gol        NUMERIC := 30000000;  -- ¥30M por gol
    v_valor_asistencia NUMERIC := 15000000;  -- ¥15M por asistencia
    v_total            NUMERIC;
BEGIN
    -- Cálculo principal del bid
    v_total := (p_goles * v_valor_gol) + (p_asistencias * v_valor_asistencia);

    -- COALESCE evita retornar NULL si algún parámetro es nulo
    RETURN COALESCE(v_total, 0);
END;
$$;


-- ------------------------------------------------------------
-- UDF 2: fn_rango_egoista
-- Función CLASIFICADORA: asigna una categoría al jugador
-- según el valor de su bid calculado.
-- Retorna: TEXT (categoría del jugador)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rango_egoista(
    p_bid NUMERIC
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_bid >= 100000000 THEN
        RETURN 'Clase Mundial (World Class)';
    ELSIF p_bid >= 60000000 THEN
        RETURN 'Talento de Élite';
    ELSIF p_bid >= 30000000 THEN
        RETURN 'Promesa Egoísta';
    ELSE
        RETURN 'En Desarrollo';
    END IF;
END;
$$;


-- ------------------------------------------------------------
-- UDF 3: fn_resumen_jugador
-- Función COMPUESTA: combina ambas funciones anteriores y
-- devuelve un texto de resumen completo del jugador.
-- Retorna: TEXT (reporte narrativo)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_resumen_jugador(
    p_nombre      VARCHAR,
    p_equipo      VARCHAR,
    p_goles       INT,
    p_asistencias INT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_bid    NUMERIC;
    v_rango  TEXT;
    v_resumen TEXT;
BEGIN
    -- Reutilizamos las funciones ya creadas (modularidad)
    v_bid   := fn_calcular_bid_bluelock(p_goles, p_asistencias);
    v_rango := fn_rango_egoista(v_bid);

    v_resumen := 'Jugador: ' || p_nombre
              || ' | Equipo: ' || p_equipo
              || ' | Goles: ' || p_goles
              || ' | Asistencias: ' || p_asistencias
              || ' | Bid: ¥' || TO_CHAR(v_bid, 'FM999,999,999,999')
              || ' | Categoría: ' || v_rango;

    RETURN v_resumen;
END;
$$;


-- ============================================================
-- SECCIÓN 4: CONSULTAS CON LAS FUNCIONES (USO REAL EN SELECT)
-- ============================================================

-- ------------------------------------------------------------
-- CONSULTA A: Ranking completo de la Liga Neo Egoísta
-- Muestra nombre, equipo, bid calculado y categoría de rango
-- ------------------------------------------------------------
SELECT
    j.nombre_jugador,
    e.nombre_equipo                                                         AS equipo,
    est.goles,
    est.asistencias,
    fn_calcular_bid_bluelock(est.goles, est.asistencias)                    AS bid_calculado,
    fn_rango_egoista(fn_calcular_bid_bluelock(est.goles, est.asistencias))  AS categoria
FROM estadisticas_jugadores est
JOIN jugadores  j ON est.id_jugador = j.id_jugador
JOIN equipos    e ON j.id_equipo    = e.id_equipo
ORDER BY bid_calculado DESC;


-- ------------------------------------------------------------
-- CONSULTA B: Reporte narrativo usando fn_resumen_jugador
-- ------------------------------------------------------------
SELECT
    fn_resumen_jugador(
        j.nombre_jugador,
        eq.nombre_equipo,
        est.goles,
        est.asistencias
    ) AS reporte_bluelock_tv
FROM estadisticas_jugadores est
JOIN jugadores j  ON est.id_jugador = j.id_jugador
JOIN equipos   eq ON j.id_equipo    = eq.id_equipo
ORDER BY est.goles DESC, est.asistencias DESC;


-- ------------------------------------------------------------
-- CONSULTA C: Solo jugadores "Clase Mundial" o "Talento de Élite"
-- Uso de la UDF en cláusula WHERE (filtro dinámico)
-- ------------------------------------------------------------
SELECT
    j.nombre_jugador,
    eq.nombre_equipo,
    fn_calcular_bid_bluelock(est.goles, est.asistencias)                    AS bid,
    fn_rango_egoista(fn_calcular_bid_bluelock(est.goles, est.asistencias))  AS categoria
FROM estadisticas_jugadores est
JOIN jugadores j  ON est.id_jugador = j.id_jugador
JOIN equipos   eq ON j.id_equipo    = eq.id_equipo
WHERE fn_rango_egoista(fn_calcular_bid_bluelock(est.goles, est.asistencias))
      IN ('Clase Mundial (World Class)', 'Talento de Élite')
ORDER BY bid DESC;


-- ------------------------------------------------------------
-- CONSULTA D: Presupuesto restante por equipo tras las pujas
-- Demuestra uso de UDF en cálculos de columnas derivadas
-- ------------------------------------------------------------
SELECT
    eq.nombre_equipo,
    eq.presupuesto                                                          AS presupuesto_inicial,
    SUM(fn_calcular_bid_bluelock(est.goles, est.asistencias))               AS total_pujas,
    eq.presupuesto - SUM(fn_calcular_bid_bluelock(est.goles, est.asistencias)) AS presupuesto_restante
FROM estadisticas_jugadores est
JOIN jugadores j  ON est.id_jugador = j.id_jugador
JOIN equipos   eq ON j.id_equipo    = eq.id_equipo
GROUP BY eq.id_equipo, eq.nombre_equipo, eq.presupuesto
ORDER BY presupuesto_restante DESC;


-- ============================================================
-- FIN DEL SCRIPT - BLUE LOCK TV LIGA NEO EGOÍSTA
-- ============================================================

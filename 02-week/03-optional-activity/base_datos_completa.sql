-- ============================================================================
-- SCRIPT DE DATOS: SISTEMA ACADÉMICO CON PERSONAJES DE BLUE LOCK
-- Base de datos académica con nombres de Blue Lock
-- ============================================================================
-- Contexto: Universidad normal con asignaturas de Ingeniería/Sistemas
-- Estudiantes tienen nombres de personajes de Blue Lock
-- ============================================================================

-- Limpiar tablas si existen
DROP TABLE IF EXISTS matricula CASCADE;
DROP TABLE IF EXISTS asignatura CASCADE;
DROP TABLE IF EXISTS estudiante CASCADE;

-- ============================================================================
-- TABLA: estudiante (Estudiantes universitarios)
-- ============================================================================
CREATE TABLE estudiante (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    carrera VARCHAR(100),
    semestre_actual INTEGER
);

-- ============================================================================
-- TABLA: asignatura (Materias universitarias)
-- ============================================================================
CREATE TABLE asignatura (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    creditos INTEGER,
    nivel INTEGER -- 1 a 5 (semestre recomendado)
);

-- ============================================================================
-- TABLA: matricula (Inscripciones de estudiantes en asignaturas)
-- ============================================================================
CREATE TABLE matricula (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiante(id),
    asignatura_id INTEGER NOT NULL REFERENCES asignatura(id),
    semestre VARCHAR(10) NOT NULL,
    nota_final DECIMAL(3,1), -- Calificación del 1.0 al 5.0
    asistencia INTEGER, -- Porcentaje de asistencia
    UNIQUE(estudiante_id, asignatura_id, semestre)
);

-- ============================================================================
-- INSERTAR DATOS: ESTUDIANTES (Personajes de Blue Lock)
-- ============================================================================
INSERT INTO estudiante (nombre, carrera, semestre_actual) VALUES
-- Protagonistas principales
('Yoichi Isagi', 'Ingeniería de Sistemas', 4),
('Meguru Bachira', 'Ingeniería de Sistemas', 4),
('Hyoma Chigiri', 'Ingeniería de Sistemas', 4),
('Rensuke Kunigami', 'Ingeniería de Sistemas', 4),
('Gin Gagamaru', 'Ingeniería Industrial', 3),

-- Team V y otros equipos
('Reo Mikage', 'Administración de Empresas', 5),
('Seishiro Nagi', 'Ingeniería de Sistemas', 3),
('Jingo Raichi', 'Ingeniería Mecánica', 4),
('Asahi Naruhaya', 'Ingeniería Industrial', 3),
('Ikki Niko', 'Ingeniería de Sistemas', 4),

-- Top 6 y jugadores élite
('Rin Itoshi', 'Ingeniería de Sistemas', 5),
('Ryusei Shidou', 'Ingeniería de Sistemas', 5),
('Tabito Karasu', 'Ingeniería de Sistemas', 4),
('Eita Otoya', 'Administración de Empresas', 4),
('Yo Hiori', 'Ingeniería de Sistemas', 3),

-- Más jugadores
('Shouei Barou', 'Ingeniería Civil', 5),
('Aoshi Tokimitsu', 'Ingeniería Industrial', 3),
('Jyubei Aryu', 'Diseño Industrial', 4),
('Wataru Kuon', 'Administración de Empresas', 3),
('Zantetsu Tsurugi', 'Ingeniería Mecánica', 4),

-- Jugadores adicionales
('Yukimiya Kenyu', 'Ingeniería de Sistemas', 4),
('Nijiro Nanase', 'Ingeniería Industrial', 3),
('Gurimu Igarashi', 'Ingeniería de Sistemas', 2),
('Hibiki Okawa', 'Ingeniería Civil', 3),
('Ranze Kurona', 'Ingeniería de Sistemas', 4);

-- ============================================================================
-- INSERTAR DATOS: ASIGNATURAS (Materias universitarias reales)
-- ============================================================================
INSERT INTO asignatura (codigo, nombre, creditos, nivel) VALUES
-- Bases de Datos (BD)
('BD101', 'Fundamentos de Bases de Datos', 3, 3),
('BD201', 'Bases de Datos Avanzadas', 4, 4),
('BD301', 'Administración de Bases de Datos', 3, 5),

-- Programación (PROG)
('PROG101', 'Programación I', 4, 1),
('PROG201', 'Programación II', 4, 2),
('PROG301', 'Programación Orientada a Objetos', 4, 3),
('PROG401', 'Estructuras de Datos', 4, 4),

-- Sistemas (SIS)
('SIS101', 'Introducción a Sistemas', 3, 1),
('SIS201', 'Análisis de Sistemas', 3, 3),
('SIS301', 'Arquitectura de Software', 4, 4),

-- Redes (RED)
('RED101', 'Fundamentos de Redes', 3, 3),
('RED201', 'Redes Avanzadas', 4, 4),

-- Matemáticas (MAT)
('MAT101', 'Cálculo I', 4, 1),
('MAT201', 'Cálculo II', 4, 2),
('MAT301', 'Álgebra Lineal', 3, 2),

-- Gestión (GES)
('GES101', 'Gestión de Proyectos', 3, 4),
('GES201', 'Gestión Empresarial', 3, 3),

-- Ingeniería (ING)
('ING101', 'Introducción a la Ingeniería', 2, 1),
('ING201', 'Ética Profesional', 2, 3),
('ING301', 'Ingeniería de Software', 4, 5);

-- ============================================================================
-- INSERTAR DATOS: MATRÍCULAS SEMESTRE 2026-1
-- ============================================================================
-- Yoichi Isagi (id: 1) - Estudiante destacado pero no perfecto
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(1, 1, '2026-1', 4.2, 95),  -- BD101
(1, 2, '2026-1', 4.5, 98),  -- BD201
(1, 7, '2026-1', 4.3, 92),  -- PROG401
(1, 9, '2026-1', 4.0, 90),  -- SIS201
(1, 16, '2026-1', 3.8, 88); -- GES101

-- Meguru Bachira (id: 2) - Creativo, notas irregulares
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(2, 1, '2026-1', 3.5, 85),  -- BD101
(2, 6, '2026-1', 4.8, 95),  -- PROG301
(2, 9, '2026-1', 3.9, 80),  -- SIS201
(2, 13, '2026-1', 3.2, 75),  -- MAT101
(2, 18, '2026-1', 4.0, 88); -- ING101

-- Hyoma Chigiri (id: 3) - Rápido y eficiente, buenas notas
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(3, 1, '2026-1', 4.6, 97),  -- BD101
(3, 2, '2026-1', 4.4, 96),  -- BD201
(3, 11, '2026-1', 4.5, 98),  -- RED101
(3, 16, '2026-1', 4.2, 94),  -- GES101
(3, 19, '2026-1', 4.3, 95); -- ING201

-- Rensuke Kunigami (id: 4) - Trabajador constante
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(4, 1, '2026-1', 4.0, 100), -- BD101
(4, 7, '2026-1', 4.1, 98),  -- PROG401
(4, 9, '2026-1', 3.9, 96),  -- SIS201
(4, 13, '2026-1', 3.7, 95),  -- MAT101
(4, 19, '2026-1', 4.2, 100); -- ING201

-- Gin Gagamaru (id: 5) - Sólido y consistente
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(5, 4, '2026-1', 3.8, 90),  -- PROG101
(5, 13, '2026-1', 3.6, 88),  -- MAT101
(5, 14, '2026-1', 3.9, 92),  -- MAT201
(5, 17, '2026-1', 4.0, 94),  -- GES201
(5, 18, '2026-1', 3.7, 87); -- ING101

-- Reo Mikage (id: 6) - Rico y talentoso, excelentes notas
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(6, 2, '2026-1', 4.8, 98),  -- BD201
(6, 3, '2026-1', 4.9, 100), -- BD301
(6, 10, '2026-1', 4.7, 97),  -- SIS301
(6, 16, '2026-1', 4.8, 99),  -- GES101
(6, 20, '2026-1', 4.9, 100); -- ING301

-- Seishiro Nagi (id: 7) - Genio perezoso, altas notas con baja asistencia
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(7, 1, '2026-1', 4.7, 70),  -- BD101
(7, 6, '2026-1', 4.9, 65),  -- PROG301
(7, 11, '2026-1', 4.6, 68),  -- RED101
(7, 14, '2026-1', 4.5, 72),  -- MAT201
(7, 18, '2026-1', 4.3, 75); -- ING101

-- Jingo Raichi (id: 8) - Agresivo, esforzado pero notas medias
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(8, 4, '2026-1', 3.4, 100), -- PROG101
(8, 8, '2026-1', 3.3, 98),  -- SIS101
(8, 13, '2026-1', 3.0, 95),  -- MAT101
(8, 18, '2026-1', 3.5, 100), -- ING101
(8, 19, '2026-1', 3.6, 97); -- ING201

-- Asahi Naruhaya (id: 9) - Luchador, notas variables
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(9, 4, '2026-1', 3.2, 85),  -- PROG101
(9, 13, '2026-1', 2.9, 80),  -- MAT101
(9, 17, '2026-1', 3.5, 88),  -- GES201
(9, 18, '2026-1', 3.3, 82);  -- ING101

-- Ikki Niko (id: 10) - Estratégico, buen estudiante
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(10, 1, '2026-1', 4.3, 93),  -- BD101
(10, 7, '2026-1', 4.4, 95),  -- PROG401
(10, 9, '2026-1', 4.2, 91),  -- SIS201
(10, 11, '2026-1', 4.1, 90),  -- RED101
(10, 16, '2026-1', 4.3, 94); -- GES101

-- Rin Itoshi (id: 11) - El mejor, notas perfectas
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(11, 2, '2026-1', 5.0, 100), -- BD201
(11, 3, '2026-1', 5.0, 100), -- BD301
(11, 10, '2026-1', 5.0, 100), -- SIS301
(11, 12, '2026-1', 5.0, 100), -- RED201
(11, 20, '2026-1', 5.0, 100); -- ING301

-- Ryusei Shidou (id: 12) - Caótico pero brillante
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(12, 2, '2026-1', 4.6, 82),  -- BD201
(12, 6, '2026-1', 4.7, 79),  -- PROG301
(12, 10, '2026-1', 4.5, 80),  -- SIS301
(12, 19, '2026-1', 4.4, 85),  -- ING201
(12, 20, '2026-1', 4.8, 88); -- ING301

-- Tabito Karasu (id: 13) - Inteligente y analítico
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(13, 1, '2026-1', 4.5, 96),  -- BD101
(13, 2, '2026-1', 4.6, 97),  -- BD201
(13, 9, '2026-1', 4.4, 95),  -- SIS201
(13, 16, '2026-1', 4.5, 98),  -- GES101
(13, 19, '2026-1', 4.3, 94); -- ING201

-- Eita Otoya (id: 14) - Carismático, estudiante promedio
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(14, 4, '2026-1', 3.6, 87),  -- PROG101
(14, 13, '2026-1', 3.4, 83),  -- MAT101
(14, 17, '2026-1', 3.8, 90),  -- GES201
(14, 18, '2026-1', 3.7, 88),  -- ING101
(14, 19, '2026-1', 3.5, 85); -- ING201

-- Yo Hiori (id: 15) - Joven prodigio
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(15, 1, '2026-1', 4.8, 98),  -- BD101
(15, 5, '2026-1', 4.9, 99),  -- PROG201
(15, 6, '2026-1', 4.7, 97),  -- PROG301
(15, 14, '2026-1', 4.6, 96),  -- MAT201
(15, 15, '2026-1', 4.8, 98); -- MAT301

-- Shouei Barou (id: 16) - Rey egoísta, excelentes notas
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(16, 2, '2026-1', 4.7, 95),  -- BD201
(16, 10, '2026-1', 4.8, 97),  -- SIS301
(16, 12, '2026-1', 4.6, 94),  -- RED201
(16, 16, '2026-1', 4.9, 99),  -- GES101
(16, 20, '2026-1', 4.7, 96); -- ING301

-- Aoshi Tokimitsu (id: 17) - Nervioso pero capaz
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(17, 4, '2026-1', 3.7, 92),  -- PROG101
(17, 8, '2026-1', 3.8, 94),  -- SIS101
(17, 13, '2026-1', 3.5, 90),  -- MAT101
(17, 18, '2026-1', 3.6, 91); -- ING101

-- Jyubei Aryu (id: 18) - Elegante y capaz
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(18, 1, '2026-1', 4.1, 91),  -- BD101
(18, 9, '2026-1', 4.0, 89),  -- SIS201
(18, 17, '2026-1', 4.2, 93),  -- GES201
(18, 19, '2026-1', 4.1, 90); -- ING201

-- Wataru Kuon (id: 19) - Traidor, notas bajas
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(19, 4, '2026-1', 2.8, 78),  -- PROG101
(19, 13, '2026-1', 2.5, 70),  -- MAT101
(19, 17, '2026-1', 3.0, 80),  -- GES201
(19, 18, '2026-1', 2.9, 75); -- ING101

-- Zantetsu Tsurugi (id: 20) - Rápido pero no muy inteligente
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(20, 4, '2026-1', 3.1, 88),  -- PROG101
(20, 8, '2026-1', 3.0, 86),  -- SIS101
(20, 13, '2026-1', 2.7, 82),  -- MAT101
(20, 18, '2026-1', 3.2, 90); -- ING101

-- Yukimiya Kenyu (id: 21) - Modelo, inteligente y dedicado
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(21, 1, '2026-1', 4.4, 94),  -- BD101
(21, 2, '2026-1', 4.5, 96),  -- BD201
(21, 7, '2026-1', 4.3, 93),  -- PROG401
(21, 11, '2026-1', 4.4, 95),  -- RED101
(21, 16, '2026-1', 4.6, 97); -- GES101

-- Nijiro Nanase (id: 22) - Trabajador esforzado
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(22, 4, '2026-1', 3.6, 93),  -- PROG101
(22, 13, '2026-1', 3.4, 91),  -- MAT101
(22, 14, '2026-1', 3.7, 94),  -- MAT201
(22, 18, '2026-1', 3.5, 92); -- ING101

-- Gurimu Igarashi (id: 23) - Novato, le cuesta
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(23, 4, '2026-1', 2.9, 85),  -- PROG101
(23, 8, '2026-1', 3.1, 87),  -- SIS101
(23, 13, '2026-1', 2.6, 80),  -- MAT101
(23, 18, '2026-1', 3.0, 83); -- ING101

-- Hibiki Okawa (id: 24) - Estudiante promedio
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(24, 4, '2026-1', 3.3, 86),  -- PROG101
(24, 13, '2026-1', 3.2, 84),  -- MAT101
(24, 18, '2026-1', 3.4, 88); -- ING101

-- Ranze Kurona (id: 25) - Constante y metódico
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
(25, 1, '2026-1', 4.0, 92),  -- BD101
(25, 6, '2026-1', 4.1, 93),  -- PROG301
(25, 9, '2026-1', 3.9, 91),  -- SIS201
(25, 16, '2026-1', 4.0, 90); -- GES101

-- ============================================================================
-- INSERTAR DATOS: MATRÍCULAS SEMESTRE 2025-2 (para comparaciones)
-- ============================================================================
-- Solo algunos estudiantes para tener datos históricos
INSERT INTO matricula (estudiante_id, asignatura_id, semestre, nota_final, asistencia) VALUES
-- Isagi en semestre anterior
(1, 4, '2025-2', 4.0, 92),   -- PROG101
(1, 5, '2025-2', 4.2, 95),   -- PROG201
(1, 13, '2025-2', 3.9, 90),  -- MAT101

-- Bachira en semestre anterior
(2, 4, '2025-2', 3.8, 88),   -- PROG101
(2, 5, '2025-2', 4.1, 85),   -- PROG201
(2, 8, '2025-2', 3.7, 82),   -- SIS101

-- Rin siempre perfecto
(11, 7, '2025-2', 5.0, 100), -- PROG401
(11, 9, '2025-2', 5.0, 100), -- SIS201
(11, 16, '2025-2', 5.0, 100); -- GES101

-- ============================================================================
-- VERIFICACIÓN DE DATOS
-- ============================================================================
-- Ver resumen de datos insertados
SELECT 'Estudiantes insertados:' AS tabla, COUNT(*) AS total FROM estudiante
UNION ALL
SELECT 'Asignaturas insertadas:', COUNT(*) FROM asignatura
UNION ALL
SELECT 'Matrículas 2026-1:', COUNT(*) FROM matricula WHERE semestre = '2026-1'
UNION ALL
SELECT 'Matrículas 2025-2:', COUNT(*) FROM matricula WHERE semestre = '2025-2'
UNION ALL
SELECT 'Total matrículas:', COUNT(*) FROM matricula;

-- ============================================================================
-- ACTIVIDAD PRÁCTICA: SUBCONSULTAS SQL - VERSIÓN MYSQL
-- Consultas corregidas para MySQL (sin ::numeric)
-- ============================================================================

-- ============================================================================
-- CONSULTA A: Subconsulta Escalar
-- Listar matrículas con nota y el promedio general del semestre
-- ============================================================================

SELECT 
    e.nombre AS estudiante,
    a.codigo AS asignatura,
    m.nota_final,
    (
        SELECT ROUND(AVG(nota_final), 2)
        FROM matricula
        WHERE semestre = '2026-1'
    ) AS promedio_general
FROM matricula m
JOIN estudiante e ON e.id = m.estudiante_id
JOIN asignatura a ON a.id = m.asignatura_id
WHERE m.semestre = '2026-1'
ORDER BY a.codigo, e.nombre;


-- ============================================================================
-- CONSULTA B: Mayor que Promedio
-- Matrículas con nota mayor al promedio general del semestre
-- ============================================================================

SELECT 
    e.nombre AS estudiante,
    a.codigo AS asignatura,
    m.nota_final,
    (
        SELECT ROUND(AVG(nota_final), 2)
        FROM matricula
        WHERE semestre = '2026-1'
    ) AS promedio_general
FROM matricula m
JOIN estudiante e ON e.id = m.estudiante_id
JOIN asignatura a ON a.id = m.asignatura_id
WHERE m.semestre = '2026-1'
  AND m.nota_final > (
      SELECT AVG(nota_final)
      FROM matricula
      WHERE semestre = '2026-1'
  )
ORDER BY m.nota_final DESC, e.nombre;


-- ============================================================================
-- CONSULTA C: Operador IN
-- Estudiantes matriculados en asignaturas cuyo código inicia por "BD"
-- ============================================================================

SELECT DISTINCT 
    e.id,
    e.nombre AS estudiante
FROM estudiante e
JOIN matricula m ON m.estudiante_id = e.id
WHERE m.semestre = '2026-1'
  AND m.asignatura_id IN (
      SELECT id
      FROM asignatura
      WHERE codigo LIKE 'BD%'
  )
ORDER BY e.nombre;

-- Alternativa mostrando también las asignaturas:
SELECT DISTINCT 
    e.id,
    e.nombre AS estudiante,
    a.codigo AS asignatura
FROM estudiante e
JOIN matricula m ON m.estudiante_id = e.id
JOIN asignatura a ON a.id = m.asignatura_id
WHERE m.semestre = '2026-1'
  AND m.asignatura_id IN (
      SELECT id
      FROM asignatura
      WHERE codigo LIKE 'BD%'
  )
ORDER BY e.nombre, a.codigo;


-- ============================================================================
-- CONSULTA D: EXISTS
-- Estudiantes que SÍ tienen matrícula en el semestre (sin JOIN directo)
-- ============================================================================

SELECT 
    e.id,
    e.nombre AS estudiante
FROM estudiante e
WHERE EXISTS (
    SELECT 1
    FROM matricula m
    WHERE m.estudiante_id = e.id
      AND m.semestre = '2026-1'
)
ORDER BY e.nombre;


-- ============================================================================
-- CONSULTA E: NOT EXISTS
-- Estudiantes SIN matrícula en el semestre
-- ============================================================================

SELECT 
    e.id,
    e.nombre AS estudiante
FROM estudiante e
WHERE NOT EXISTS (
    SELECT 1
    FROM matricula m
    WHERE m.estudiante_id = e.id
      AND m.semestre = '2026-1'
)
ORDER BY e.nombre;


-- ============================================================================
-- CONSULTA EXTRA: Subconsulta Correlacionada
-- Matrículas con nota mayor al promedio de su asignatura (por grupo)
-- ============================================================================

SELECT 
    e.nombre AS estudiante,
    a.codigo AS asignatura,
    m.nota_final,
    (
        SELECT ROUND(AVG(m2.nota_final), 2)
        FROM matricula m2
        WHERE m2.semestre = m.semestre
          AND m2.asignatura_id = m.asignatura_id
    ) AS promedio_asignatura
FROM matricula m
JOIN estudiante e ON e.id = m.estudiante_id
JOIN asignatura a ON a.id = m.asignatura_id
WHERE m.semestre = '2026-1'
  AND m.nota_final > (
      SELECT AVG(m2.nota_final)
      FROM matricula m2
      WHERE m2.semestre = m.semestre
        AND m2.asignatura_id = m.asignatura_id
  )
ORDER BY a.codigo, m.nota_final DESC;


-- ============================================================================
-- CONSULTAS DE VERIFICACIÓN ADICIONALES
-- ============================================================================

-- Ver el promedio general del semestre
SELECT 
    semestre,
    ROUND(AVG(nota_final), 2) AS promedio_general,
    COUNT(*) AS total_matriculas
FROM matricula
GROUP BY semestre
ORDER BY semestre;

-- Ver estudiantes con mejor promedio personal
SELECT 
    e.nombre AS estudiante,
    COUNT(*) AS materias_cursadas,
    ROUND(AVG(m.nota_final), 2) AS promedio_personal
FROM estudiante e
JOIN matricula m ON m.estudiante_id = e.id
WHERE m.semestre = '2026-1'
GROUP BY e.id, e.nombre
ORDER BY promedio_personal DESC
LIMIT 10;

-- Ver asignaturas más difíciles (menor promedio)
SELECT 
    a.codigo,
    a.nombre,
    COUNT(*) AS estudiantes,
    ROUND(AVG(m.nota_final), 2) AS promedio_asignatura
FROM asignatura a
JOIN matricula m ON m.asignatura_id = a.id
WHERE m.semestre = '2026-1'
GROUP BY a.id, a.codigo, a.nombre
ORDER BY promedio_asignatura ASC
LIMIT 10;





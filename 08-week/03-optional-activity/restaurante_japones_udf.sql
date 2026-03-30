-- ============================================================
--  Base de Datos II · Semana 4 - Sesión 1
--  UDFs en PostgreSQL — Temática: Restaurante Japonés
--  Personajes: chicas de animes de romance
-- ============================================================


-- ============================================================
-- SECCIÓN 1: TABLAS BASE
-- ============================================================


-- Clientes del restaurante
CREATE TABLE cliente (
    id      SERIAL PRIMARY KEY,
    nombre  TEXT    NOT NULL,
    email   TEXT    UNIQUE
);

-- Platos del menú japonés
CREATE TABLE plato (
    id          SERIAL PRIMARY KEY,
    nombre      TEXT            NOT NULL,
    categoria   TEXT,           -- sushi, ramen, tempura, onigiri...
    precio      NUMERIC(8,2)    NOT NULL
);

-- Pedidos realizados
CREATE TABLE pedido (
    id          SERIAL PRIMARY KEY,
    cliente_id  INT             REFERENCES cliente(id),
    fecha       DATE            DEFAULT CURRENT_DATE,
    total       NUMERIC(10,2)
);

-- Detalle de cada pedido (línea por plato)
CREATE TABLE detalle_pedido (
    id           SERIAL PRIMARY KEY,
    pedido_id    INT             REFERENCES pedido(id),
    plato_id     INT             REFERENCES plato(id),
    cantidad     INT             NOT NULL,
    precio_unit  NUMERIC(8,2)    NOT NULL
);


-- ============================================================
-- SECCIÓN 2: DATOS DE PRUEBA
-- ============================================================

-- Clientes: chicas de animes de romance
INSERT INTO cliente (nombre, email) VALUES
  ('Chitoge Kirisaki',  'chitoge@nisekoi.jp'),
  ('Kosaki Onodera',    'kosaki@nisekoi.jp'),
  ('Taiga Aisaka',      'taiga@toradora.jp'),
  ('Mashiro Shiina',    'mashiro@sakurasou.jp'),
  ('Erina Nakiri',      'erina@shokugeki.jp'),
  ('Tohru Honda',       'tohru@fruitsbasket.jp'),
  ('Shouko Nishimiya',  'shouko@koenokatachi.jp');

-- Platos del menú
INSERT INTO plato (nombre, categoria, precio) VALUES
  ('Sushi de salmon',     'sushi',    12.50),
  ('Ramen tonkotsu',      'ramen',     9.80),
  ('Tempura de camaron',  'tempura',  11.00),
  ('Onigiri de umeboshi', 'onigiri',   4.50),
  ('Takoyaki',            'snack',     7.00),
  ('Miso ramen',          'ramen',     8.90),
  ('Gyoza (6 piezas)',    'gyoza',     6.50),
  ('Matcha cheesecake',   'postre',    5.00);

-- Pedidos
INSERT INTO pedido (cliente_id, fecha, total) VALUES
  (1, '2026-03-10', 0),
  (2, '2026-03-11', 0),
  (3, '2026-03-12', 0),
  (5, '2026-03-15', 0),
  (1, '2026-03-18', 0);

-- Detalles de pedido
INSERT INTO detalle_pedido (pedido_id, plato_id, cantidad, precio_unit) VALUES
  (1, 1, 2, 12.50), (1, 5, 1, 7.00), (1, 8, 2, 3.00),
  (2, 2, 1,  9.80), (2, 4, 3, 4.50),
  (3, 3, 2, 11.00), (3, 7, 1, 6.50),
  (4, 1, 3, 12.50), (4, 6, 2, 8.90),
  (5, 5, 2,  7.00), (5, 2, 1, 9.80), (5, 8, 1, 5.00);


-- ============================================================
-- SECCIÓN 3: UDF ESCALAR — Clasificar nivel de un pedido
--   Patrón: igual a fn_estado_nota() del material de clase
--   RETURNS TEXT · LANGUAGE plpgsql
-- ============================================================

CREATE OR REPLACE FUNCTION fn_nivel_pedido(p_total NUMERIC)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_total IS NULL THEN
        RETURN 'Sin pedido';
    ELSIF p_total >= 40 THEN
        RETURN 'Festin omakase';    -- pedido grande
    ELSIF p_total >= 20 THEN
        RETURN 'Bento completo';    -- pedido medio
    ELSE
        RETURN 'Snack rapido';      -- pedido pequeño
    END IF;
END;
$$;

-- Uso: calcular total de cada pedido y clasificarlo
SELECT
    p.id                                                AS pedido,
    c.nombre                                            AS cliente,
    SUM(dp.cantidad * dp.precio_unit)                   AS total_calculado,
    fn_nivel_pedido(SUM(dp.cantidad * dp.precio_unit))  AS nivel
FROM pedido p
JOIN cliente c          ON c.id = p.cliente_id
JOIN detalle_pedido dp  ON dp.pedido_id = p.id
GROUP BY p.id, c.nombre
ORDER BY total_calculado DESC;


-- ============================================================
-- SECCIÓN 4: UDF NUMÉRICA — Gasto promedio por cliente
--   Patrón: igual a fn_promedio_estudiante() del material
--   RETURNS NUMERIC · LANGUAGE plpgsql · usa COALESCE + ROUND
-- ============================================================

CREATE OR REPLACE FUNCTION fn_gasto_promedio(p_cliente_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_prom NUMERIC;
BEGIN
    SELECT AVG(sub.total_pedido)
    INTO   v_prom
    FROM (
        SELECT dp.pedido_id,
               SUM(dp.cantidad * dp.precio_unit) AS total_pedido
        FROM   detalle_pedido dp
        JOIN   pedido p ON p.id = dp.pedido_id
        WHERE  p.cliente_id = p_cliente_id
        GROUP BY dp.pedido_id
    ) sub;

    -- COALESCE evita NULL si el cliente no tiene pedidos
    RETURN COALESCE(ROUND(v_prom, 2), 0);
END;
$$;

-- Uso: ranking de clientas por gasto promedio
SELECT
    c.nombre,
    fn_gasto_promedio(c.id) AS prom_por_pedido
FROM   cliente c
ORDER BY prom_por_pedido DESC;


-- ============================================================
-- SECCIÓN 5: UDF SET-RETURNING — Reporte de pedidos
--   Patrón: igual a fn_reporte_matriculas() del material
--   RETURNS TABLE · LANGUAGE sql (sin lógica IF/LOOP)
-- ============================================================

CREATE OR REPLACE FUNCTION fn_reporte_cliente(p_cliente_id INT)
RETURNS TABLE(
    fecha        DATE,
    plato        TEXT,
    categoria    TEXT,
    cantidad     INT,
    precio_unit  NUMERIC,
    subtotal     NUMERIC,
    total_pedido NUMERIC
)
LANGUAGE sql
AS $$
    SELECT
        p.fecha,
        pl.nombre,
        pl.categoria,
        dp.cantidad,    
        dp.precio_unit,
        dp.cantidad * dp.precio_unit AS subtotal
        p.total AS total_pedido
    FROM   pedido p
    JOIN   detalle_pedido dp  ON dp.pedido_id = p.id
    JOIN   plato pl            ON pl.id = dp.plato_id
    WHERE  p.cliente_id = p_cliente_id
    ORDER BY p.fecha, pl.categoria;
$$;

-- Uso básico: reporte de Chitoge Kirisaki (id = 1)
SELECT * FROM fn_reporte_cliente(1);

-- Uso avanzado: combinar dos UDFs (escalar dentro de set-returning)
SELECT
    r.*,
    fn_nivel_pedido(r.subtotal) AS nivel_linea
FROM fn_reporte_cliente(1) r;


-- ============================================================
-- SECCIÓN 6: CONSULTA FINAL COMBINADA
--   Demuestra anidar UDFs dentro de SELECT como funciones nativas
-- ============================================================

SELECT
    c.nombre,
    COUNT(DISTINCT p.id)        AS total_pedidos,
    fn_gasto_promedio(c.id)     AS gasto_promedio,
    fn_nivel_pedido(
        fn_gasto_promedio(c.id)
    )                           AS perfil_cliente
FROM   cliente c
LEFT JOIN pedido p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre
ORDER BY gasto_promedio DESC;



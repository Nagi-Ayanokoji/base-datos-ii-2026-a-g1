DROP DATABASE IF EXISTS plain;
CREATE DATABASE plain;
USE plain;

CREATE TABLE IF NOT EXISTS cliente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(100) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS orden (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    producto_id INT NOT NULL,
    fecha_orden DATE NOT NULL,
    cantidad INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES cliente(id),
    FOREIGN KEY (producto_id) REFERENCES producto(id)
);

INSERT INTO cliente (nombre) VALUES
('Utage Kinoshita'),
('Yoi Takaguchi'),
('Sashi Umino'),
('Chinatsu Kano'),
('Yamada Anna'),
('Futaba Yoshioka'),
('Mai Sakurajima'),
('Marin Kitagawa'),
('Cha Hae In'),
('Ai Mei'),
('Jeanne Mohizuki'),
('Dominique De Sade'),
('Subaru Hoshina'),
('Kaoruko Waguri'),
('Momo Ayase'),
('Banri Shiunji'),
('Kyuko Hori'),
('Madoka Yuzuhara'),
('Akane Kinoshita'),
('Akane Kurokawa');

INSERT INTO producto (codigo, nombre, precio) VALUES
    ('SUSHI-01',  'Sushi Salmón Roll (8 pzas)',        12.50),
    ('RAMEN-01',  'Ramen Tonkotsu',                     9.80),
    ('BENTO-01',  'Bento Box Karaage',                 11.00),
    ('ONIG-01',   'Onigiri Atún Mayo',                  3.50),
    ('MISO-01',   'Sopa Miso Tradicional',              4.20),
    ('TAKOY-01',  'Takoyaki (6 pzas)',                  6.75),
    ('GYOZA-01',  'Gyoza de Cerdo (10 pzas)',           7.30),
    ('UDON-01',   'Udon Tempura',                       8.90),
    ('OKONO-01',  'Okonomiyaki Osaka',                  9.50),
    ('MATCHA-01', 'Helado Matcha Artesanal',             5.00),
    ('DORAY-01',  'Dorayaki Anko',                       2.80),
    ('YAKNI-01',  'Yakitori Pollo Teriyaki (5 pzas)',   8.00),
    ('EDAMA-01',  'Edamame con Sal de Mar',              3.90),
    ('TEMPURA-01','Tempura Mix Vegetales y Camarón',   10.50),
    ('OCHAZ-01',  'Ochazuke de Salmón',                  6.00);

INSERT INTO orden (cliente_id, producto_id, fecha_orden, cantidad, total) VALUES
--Enero
(1,  1,  '2026-01-05', 2, 25.00),
(2,  2,  '2026-01-07', 1,  9.80),
(3,  3,  '2026-01-10', 3, 33.00),
(4,  4,  '2026-01-12', 4, 14.00),
(5,  5,  '2026-01-15', 2,  8.40),
(6,  6,  '2026-01-18', 1,  6.75),
(7,  7,  '2026-01-20', 2, 14.60),
(8,  8,  '2026-01-22', 1,  8.90),
(9,  9,  '2026-01-25', 2, 19.00),
(10, 10, '2026-01-28', 3, 15.00),

--febrero 
(11, 11, '2026-02-02', 5, 14.00),
(12, 12, '2026-02-05', 2, 16.00),
(13, 13, '2026-02-08', 4, 15.60),
(14, 14, '2026-02-10', 1, 10.50),
(15, 15, '2026-02-14', 2, 12.00),
(16, 1,  '2026-02-16', 3, 37.50),
(17, 2,  '2026-02-18', 2, 19.60),
(18, 3,  '2026-02-20', 1, 11.00),
(19, 4,  '2026-02-22', 6, 21.00),
(20, 5,  '2026-02-25', 3, 12.60),

--marzo
(1,  6,  '2026-03-03', 2, 13.50),
(2,  7,  '2026-03-05', 3, 21.90),
(3,  8,  '2026-03-08', 2, 17.80),
(4,  9,  '2026-03-10', 1,  9.50),
(5,  10, '2026-03-12', 4, 20.00),
(6,  11, '2026-03-15', 3,  8.40),
(7,  12, '2026-03-17', 2, 16.00),
(8,  13, '2026-03-20', 5, 19.50),
(9,  14, '2026-03-22', 2, 21.00),
(10, 1,  '2026-03-25', 3, 37.50),

--abril
(11, 2,  '2026-04-01', 1,  9.80),
(12, 3,  '2026-04-03', 4, 44.00),
(13, 4,  '2026-04-06', 5, 17.50),
(14, 5,  '2026-04-08', 2,  8.40),
(15, 6,  '2026-04-10', 3, 20.25),
(16, 7,  '2026-04-13', 1,  7.30),
(17, 8,  '2026-04-15', 2, 17.80),
(18, 9,  '2026-04-18', 3, 28.50),
(19, 10, '2026-04-20',1 ,10.00),
(20,11 , '2026-04-22',4 ,11.20);

--mayo
(1,  12, '2026-05-01', 2, 16.00),
(2,  13, '2026-05-04', 3, 19.50),
(3,  14, '2026-05-06', 1, 10.50),
(4,  15, '2026-05-08', 4, 48.00),
(5,  1,  '2026-05-11',2 ,25.00),
(6,  2,  '2026-05-13',1 ,9.80),
(7,  3,  '2026-05-15',3 ,33.00),
(8,  4,  '2026-05-18',5 ,17.50),
(9,  5,  '2026-05-20',2 ,8.40),
(10, 6, '2026-05-22',4 ,27.00);

--junio
(11, 7,  '2026-06-01', 1,  7.30),
(12, 8,  '2026-06-03', 2, 17.80),
(13, 9,  '2026-06-05', 3, 28.50),
(14, 10, '2026-06-08',1 ,10.00),
(15, 11, '2026-06-10',4 ,11.20),
(16, 12, '2026-06-12',2 ,16.00),
(17, 13, '2026-06-15',3 ,19.50),
(18, 14, '2026-06-17',1 ,10.50),
(19, 15, '2026-06-20',4 ,48.00),
(20, 1, '2026-06-22',2 ,25.00);


-- Consulta 1: Todas las órdenes del 2026 con cliente, producto, fecha y total
SELECT
    c.nombre        AS cliente,
    p.nombre        AS producto,
    o.fecha_orden,
    o.total
FROM orden o
JOIN cliente c ON c.id = o.cliente_id
JOIN producto p ON p.id = o.producto_id
WHERE YEAR(o.fecha_orden) = 2026
ORDER BY o.fecha_orden;

-- Consulta 2: Productos vendidos 3 o más veces en 2026
SELECT
    p.nombre        AS producto,
    COUNT(o.id)     AS total_ordenes
FROM orden o
JOIN producto p ON p.id = o.producto_id
WHERE YEAR(o.fecha_orden) = 2026
GROUP BY p.nombre
HAVING COUNT(o.id) >= 3
ORDER BY total_ordenes DESC;

-- Consulta 3: Promedio de venta por producto en 2026
SELECT
    p.nombre              AS producto,
    ROUND(AVG(o.total), 2) AS promedio_venta
FROM orden o
JOIN producto p ON p.id = o.producto_id
WHERE YEAR(o.fecha_orden) = 2026
GROUP BY p.nombre
ORDER BY promedio_venta DESC;

-- ============================================================
-- PARTE 2: SUBCONSULTAS Y ANÁLISIS DE DATOS
-- ============================================================

-- Consulta 4: Órdenes con total mayor al promedio general de 2026
SELECT
    o.id            AS orden_id,
    c.nombre        AS cliente,
    p.nombre        AS producto,
    o.fecha_orden,
    o.total
FROM orden o
JOIN cliente c ON c.id = o.cliente_id
JOIN producto p ON p.id = o.producto_id
WHERE o.total > (
    SELECT AVG(total)
    FROM orden
    WHERE YEAR(fecha_orden) = 2026
)
AND YEAR(o.fecha_orden) = 2026
ORDER BY o.total DESC;

-- Consulta 5: Clientes con más órdenes que el promedio por cliente en 2026
SELECT
    c.nombre        AS cliente,
    COUNT(o.id)     AS total_ordenes
FROM orden o
JOIN cliente c ON c.id = o.cliente_id
WHERE YEAR(o.fecha_orden) = 2026
GROUP BY c.id, c.nombre
HAVING COUNT(o.id) > (
    SELECT AVG(ordenes_por_cliente)
    FROM (
        SELECT cliente_id, COUNT(id) AS ordenes_por_cliente
        FROM orden
        WHERE YEAR(fecha_orden) = 2026
        GROUP BY cliente_id
    ) AS sub
)
ORDER BY total_ordenes DESC;
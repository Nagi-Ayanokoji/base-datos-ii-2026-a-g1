-- ============================================================
-- EJERCICIO 03
-- Facturación e integración entre venta, impuestos y detalle facturable
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    s.sale_code          AS codigo_venta,
    i.invoice_number     AS numero_factura,
    ist.status_name      AS estado_factura,
    il.line_number       AS linea,
    il.line_description  AS descripcion_linea,
    il.quantity          AS cantidad,
    il.unit_price        AS precio_unitario,
    tx.tax_name          AS impuesto_aplicado,
    tx.rate_percentage   AS porcentaje_impuesto,
    c.iso_currency_code  AS moneda
FROM sale s
INNER JOIN invoice i         ON i.sale_id = s.sale_id
INNER JOIN invoice_status ist ON ist.invoice_status_id = i.invoice_status_id
INNER JOIN invoice_line il   ON il.invoice_id = i.invoice_id
INNER JOIN tax tx             ON tx.tax_id = il.tax_id
INNER JOIN currency c        ON c.currency_id = i.currency_id
ORDER BY s.sale_code, i.invoice_number, il.line_number;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre invoice_line
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_actualizar_factura_tras_linea()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE invoice SET updated_at = NOW() WHERE invoice_id = NEW.invoice_id;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_invoice_line_insert
AFTER INSERT ON invoice_line
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_factura_tras_linea();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_agregar_linea_factura(
    p_invoice_id  UUID,
    p_tax_id      UUID,
    p_line_number INTEGER,
    p_description VARCHAR(200),
    p_quantity    NUMERIC(12,2),
    p_unit_price  NUMERIC(12,2)
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO invoice_line (invoice_id, tax_id, line_number, line_description,
        quantity, unit_price, created_at, updated_at)
    VALUES (p_invoice_id, p_tax_id, p_line_number, p_description,
        p_quantity, p_unit_price, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 03
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id    UUID; v_country_id  UUID;
    v_state_id   UUID; v_city_id    UUID; v_dist_id     UUID;
    v_addr_id    UUID; v_curr_id    UUID; v_airline_id  UUID;
    v_ptype_id   UUID; v_person_id  UUID;
    v_rstatus_id UUID; v_schan_id   UUID; v_res_id      UUID;
    v_sale_id    UUID; v_istatus_id UUID; v_inv_id      UUID;
    v_tax_id     UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Caracas', -270) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S03', 'South America 03') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'VE', 'VEN', 'Venezuela') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'DC', 'Distrito Capital') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Caracas') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Chacao') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av. Miranda 1') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('EUR', 'Euro', '€') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'BQ', 'Conviasa', 'V0', 'VCV') RETURNING airline_id INTO v_airline_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('EMP', 'Empleado') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Carlos', 'Rodríguez') RETURNING person_id INTO v_person_id;
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('INVOICED', 'Facturada') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('AGE', 'Agencia de Viajes') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ03-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at)
        VALUES (v_res_id, v_curr_id, 'SALE-EJ03-001', NOW()) RETURNING sale_id INTO v_sale_id;
    INSERT INTO invoice_status (status_code, status_name)
        VALUES ('ISSUED', 'Emitida') RETURNING invoice_status_id INTO v_istatus_id;
    INSERT INTO invoice (sale_id, invoice_status_id, currency_id, invoice_number, issued_at)
        VALUES (v_sale_id, v_istatus_id, v_curr_id, 'FAC-EJ03-0001', NOW()) RETURNING invoice_id INTO v_inv_id;
    INSERT INTO tax (tax_code, tax_name, rate_percentage, effective_from)
        VALUES ('IVA16', 'IVA 16%', 16.000, CURRENT_DATE) RETURNING tax_id INTO v_tax_id;
 
    -- Invocar procedimiento → activa trigger que actualiza invoice.updated_at
    CALL sp_agregar_linea_factura(v_inv_id, v_tax_id, 1, 'Tiquete BOG-MDE clase económica', 1, 500.00);
 
    RAISE NOTICE '[EJ03] Línea facturable registrada en factura: %', v_inv_id;
END;
$$;
 
-- Validación ejercicio 03
SELECT i.invoice_number, i.issued_at, i.updated_at, COUNT(il.invoice_line_id) AS total_lineas
FROM invoice i
LEFT JOIN invoice_line il ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.invoice_number, i.issued_at, i.updated_at
ORDER BY i.updated_at DESC LIMIT 5;

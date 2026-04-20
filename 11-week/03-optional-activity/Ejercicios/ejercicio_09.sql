-- ============================================================
-- EJERCICIO 09
-- Publicación de tarifas y análisis de reservas comercializadas
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    al.airline_name      AS aerolinea,
    fa.fare_code         AS codigo_tarifa,
    fc.fare_class_name   AS clase_tarifaria,
    ap_o.iata_code       AS aeropuerto_origen,
    ap_d.iata_code       AS aeropuerto_destino,
    c.iso_currency_code  AS moneda,
    r.reservation_code   AS reserva,
    s.sale_code          AS venta,
    t.ticket_number      AS tiquete
FROM airline al
INNER JOIN fare fa      ON fa.airline_id = al.airline_id
INNER JOIN fare_class fc ON fc.fare_class_id = fa.fare_class_id
INNER JOIN airport ap_o  ON ap_o.airport_id = fa.origin_airport_id
INNER JOIN airport ap_d  ON ap_d.airport_id = fa.destination_airport_id
INNER JOIN currency c    ON c.currency_id = fa.currency_id
INNER JOIN ticket t      ON t.fare_id = fa.fare_id
INNER JOIN sale s        ON s.sale_id = t.sale_id
INNER JOIN reservation r ON r.reservation_id = s.reservation_id
ORDER BY al.airline_name, fa.fare_code;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre fare
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_tarifa_nueva()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.valid_from < CURRENT_DATE THEN
        RAISE EXCEPTION 'valid_from (%) no puede ser anterior a hoy (%)', NEW.valid_from, CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_fare_insert_validar
AFTER INSERT ON fare
FOR EACH ROW EXECUTE FUNCTION fn_validar_tarifa_nueva();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_publicar_tarifa(
    p_airline_id             UUID,
    p_origin_airport_id      UUID,
    p_destination_airport_id UUID,
    p_fare_class_id          UUID,
    p_currency_id            UUID,
    p_fare_code              VARCHAR(30),
    p_base_amount            NUMERIC(12,2),
    p_valid_from             DATE,
    p_valid_to               DATE DEFAULT NULL,
    p_baggage_allowance_qty  INTEGER DEFAULT 0,
    p_change_penalty_amount  NUMERIC(12,2) DEFAULT NULL,
    p_refund_penalty_amount  NUMERIC(12,2) DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO fare (airline_id, origin_airport_id, destination_airport_id, fare_class_id,
        currency_id, fare_code, base_amount, valid_from, valid_to, baggage_allowance_qty,
        change_penalty_amount, refund_penalty_amount, created_at, updated_at)
    VALUES (p_airline_id, p_origin_airport_id, p_destination_airport_id, p_fare_class_id,
        p_currency_id, p_fare_code, p_base_amount, p_valid_from, p_valid_to, p_baggage_allowance_qty,
        p_change_penalty_amount, p_refund_penalty_amount, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 09
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id    UUID; v_country_id  UUID;
    v_state_id   UUID; v_city_id    UUID; v_dist_id     UUID;
    v_addr_id    UUID; v_curr_id    UUID; v_airline_id  UUID;
    v_ap_orig    UUID; v_ap_dest    UUID; v_cab_cls_id  UUID;
    v_fclass_id  UUID;
    v_dist2_id   UUID; v_addr2_id   UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/La_Paz', -240) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S09', 'South America 09') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'BO', 'BOL', 'Bolivia') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'LPZ', 'La Paz') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'La Paz') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'El Alto') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Aeropuerto El Alto') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('BOB', 'Boliviano', 'Bs') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'OB', 'Boliviana de Aviación', 'OB', 'BOV') RETURNING airline_id INTO v_airline_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr_id, 'El Alto Internacional', 'LPB', 'SLLP') RETURNING airport_id INTO v_ap_orig;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'VVI Zona') RETURNING district_id INTO v_dist2_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist2_id, 'Viru Viru') RETURNING address_id INTO v_addr2_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr2_id, 'Viru Viru Internacional', 'VVI', 'SLVR') RETURNING airport_id INTO v_ap_dest;
    INSERT INTO cabin_class (class_code, class_name)
        VALUES ('BUS', 'Business') RETURNING cabin_class_id INTO v_cab_cls_id;
    INSERT INTO fare_class (cabin_class_id, fare_class_code, fare_class_name, is_refundable_by_default)
        VALUES (v_cab_cls_id, 'C01', 'Business Flex', TRUE) RETURNING fare_class_id INTO v_fclass_id;
 
    -- Invocar procedimiento con valid_from = CURRENT_DATE → pasa la validación del trigger
    CALL sp_publicar_tarifa(v_airline_id, v_ap_orig, v_ap_dest, v_fclass_id, v_curr_id,
        'OB-LPB-VVI-C01', 1200.00, CURRENT_DATE, CURRENT_DATE + 90, 2, 150.00, NULL);
 
    RAISE NOTICE '[EJ09] Tarifa publicada para ruta LPB-VVI';
END;
$$;
 
-- Validación ejercicio 09
SELECT f.fare_code, fc.fare_class_name, ap_o.iata_code AS origen, ap_d.iata_code AS destino,
       f.base_amount, f.valid_from, f.valid_to, c.iso_currency_code
FROM fare f
INNER JOIN fare_class fc ON fc.fare_class_id = f.fare_class_id
INNER JOIN airport ap_o  ON ap_o.airport_id = f.origin_airport_id
INNER JOIN airport ap_d  ON ap_d.airport_id = f.destination_airport_id
INNER JOIN currency c    ON c.currency_id = f.currency_id
ORDER BY f.created_at DESC LIMIT 5;

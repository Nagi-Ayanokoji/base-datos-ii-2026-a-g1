-- ============================================================
-- EJERCICIO 06
-- Retrasos operativos y análisis de impacto por segmento de vuelo
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    al.airline_name     AS aerolinea,
    f.flight_number     AS numero_vuelo,
    f.service_date      AS fecha_servicio,
    fst.status_name     AS estado_vuelo,
    fs.segment_number   AS segmento,
    ap_o.iata_code      AS origen,
    ap_d.iata_code      AS destino,
    fd.delay_minutes    AS minutos_demora,
    drt.reason_name     AS motivo_retraso
FROM airline al
INNER JOIN flight f             ON f.airline_id = al.airline_id
INNER JOIN flight_status fst    ON fst.flight_status_id = f.flight_status_id
INNER JOIN flight_segment fs    ON fs.flight_id = f.flight_id
INNER JOIN airport ap_o         ON ap_o.airport_id = fs.origin_airport_id
INNER JOIN airport ap_d         ON ap_d.airport_id = fs.destination_airport_id
INNER JOIN flight_delay fd      ON fd.flight_segment_id = fs.flight_segment_id
INNER JOIN delay_reason_type drt ON drt.delay_reason_type_id = fd.delay_reason_type_id
ORDER BY f.service_date DESC, al.airline_name, f.flight_number;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre flight_delay
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_aplicar_retraso_a_segmento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE flight_segment
    SET actual_departure_at = scheduled_departure_at + (NEW.delay_minutes * INTERVAL '1 minute'),
        updated_at = NOW()
    WHERE flight_segment_id = NEW.flight_segment_id
      AND actual_departure_at IS NULL;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_flight_delay_aplicar_retraso
AFTER INSERT ON flight_delay
FOR EACH ROW EXECUTE FUNCTION fn_aplicar_retraso_a_segmento();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_demora(
    p_flight_segment_id    UUID,
    p_delay_reason_type_id UUID,
    p_reported_at          TIMESTAMPTZ,
    p_delay_minutes        INTEGER,
    p_notes                TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO flight_delay (flight_segment_id, delay_reason_type_id, reported_at,
        delay_minutes, notes, created_at, updated_at)
    VALUES (p_flight_segment_id, p_delay_reason_type_id, p_reported_at,
        p_delay_minutes, p_notes, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 06
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id     UUID; v_cont_id   UUID; v_country_id UUID;
    v_state_id  UUID; v_city_id   UUID; v_dist_id    UUID;
    v_addr_id   UUID; v_curr_id   UUID; v_airline_id UUID;
    v_manuf_id  UUID; v_model_id  UUID; v_aircraft_id UUID;
    v_ap_orig   UUID; v_ap_dest   UUID; v_fstatus_id UUID;
    v_flight_id UUID; v_fseg_id   UUID; v_dreason_id UUID;
    v_dist2_id  UUID; v_addr2_id  UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Guayaquil', -300) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S06', 'South America 06') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'EC', 'ECU', 'Ecuador') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'PIC', 'Pichincha') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Quito') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Tababela') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Mariscal Sucre') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('U06', 'USD Ecuador', '$') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'ET', 'Ecuatoriana', 'EU', 'ECU') RETURNING airline_id INTO v_airline_id;
    INSERT INTO aircraft_manufacturer (manufacturer_name)
        VALUES ('Embraer') RETURNING aircraft_manufacturer_id INTO v_manuf_id;
    INSERT INTO aircraft_model (aircraft_manufacturer_id, model_code, model_name, max_range_km)
        VALUES (v_manuf_id, 'E190', 'Embraer E190', 4400) RETURNING aircraft_model_id INTO v_model_id;
    INSERT INTO aircraft (airline_id, aircraft_model_id, registration_number, serial_number, in_service_on)
        VALUES (v_airline_id, v_model_id, 'HC-BXA', 'SN-EC-001', '2021-06-01') RETURNING aircraft_id INTO v_aircraft_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr_id, 'Mariscal Sucre', 'UIO', 'SEQM') RETURNING airport_id INTO v_ap_orig;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'GYE Centro') RETURNING district_id INTO v_dist2_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist2_id, 'José Olmedo') RETURNING address_id INTO v_addr2_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr2_id, 'José J. de Olmedo', 'GYE', 'SEGU') RETURNING airport_id INTO v_ap_dest;
    INSERT INTO flight_status (status_code, status_name)
        VALUES ('DELAYED', 'Demorado') RETURNING flight_status_id INTO v_fstatus_id;
    INSERT INTO flight (airline_id, aircraft_id, flight_status_id, flight_number, service_date)
        VALUES (v_airline_id, v_aircraft_id, v_fstatus_id, 'ET201', CURRENT_DATE) RETURNING flight_id INTO v_flight_id;
    INSERT INTO flight_segment (flight_id, origin_airport_id, destination_airport_id, segment_number,
        scheduled_departure_at, scheduled_arrival_at)
        VALUES (v_flight_id, v_ap_orig, v_ap_dest, 1, NOW()+INTERVAL '1h', NOW()+INTERVAL '2h')
        RETURNING flight_segment_id INTO v_fseg_id;
    INSERT INTO delay_reason_type (reason_code, reason_name)
        VALUES ('WEATHER', 'Condiciones Climáticas') RETURNING delay_reason_type_id INTO v_dreason_id;
 
    -- Invocar procedimiento → trigger actualiza actual_departure_at
    CALL sp_registrar_demora(v_fseg_id, v_dreason_id, NOW(), 45, 'Tormenta en origen');
 
    RAISE NOTICE '[EJ06] Demora registrada en segmento: %', v_fseg_id;
END;
$$;
 
-- Validación ejercicio 06
SELECT fs.flight_segment_id, fs.scheduled_departure_at, fs.actual_departure_at,
       fd.delay_minutes, drt.reason_name
FROM flight_segment fs
INNER JOIN flight_delay fd      ON fd.flight_segment_id = fs.flight_segment_id
INNER JOIN delay_reason_type drt ON drt.delay_reason_type_id = fd.delay_reason_type_id
ORDER BY fd.reported_at DESC LIMIT 5;

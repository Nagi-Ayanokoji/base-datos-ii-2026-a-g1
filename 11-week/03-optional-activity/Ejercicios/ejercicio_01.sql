-- ============================================================
-- EJERCICIO 01
-- Flujo de check-in y trazabilidad comercial del pasajero
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    r.reservation_code                        AS codigo_reserva,
    f.flight_number                           AS numero_vuelo,
    f.service_date                            AS fecha_servicio,
    t.ticket_number                           AS numero_tiquete,
    rp.passenger_sequence_no                  AS secuencia_pasajero,
    p.first_name || ' ' || p.last_name        AS nombre_pasajero,
    ts.segment_sequence_no                    AS secuencia_segmento,
    fs.scheduled_departure_at                 AS hora_programada_salida
FROM reservation r
INNER JOIN reservation_passenger rp ON rp.reservation_id = r.reservation_id
INNER JOIN person p                 ON p.person_id = rp.person_id
INNER JOIN sale s                   ON s.reservation_id = r.reservation_id
INNER JOIN ticket t                 ON t.sale_id = s.sale_id
                                    AND t.reservation_passenger_id = rp.reservation_passenger_id
INNER JOIN ticket_segment ts        ON ts.ticket_id = t.ticket_id
INNER JOIN flight_segment fs        ON fs.flight_segment_id = ts.flight_segment_id
INNER JOIN flight f                 ON f.flight_id = fs.flight_id
ORDER BY r.reservation_code, rp.passenger_sequence_no, ts.segment_sequence_no;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre check_in
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_generar_boarding_pass()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_bp_code  VARCHAR(40);
    v_barcode  VARCHAR(120);
BEGIN
    v_bp_code := 'BP-' || UPPER(SUBSTRING(NEW.check_in_id::text, 1, 8))
                 || '-' || TO_CHAR(NOW(), 'YYYYMMDDHH24MISS');
    v_barcode  := 'BC' || REPLACE(NEW.check_in_id::text, '-', '')
                 || TO_CHAR(NOW(), 'HH24MISS');
    INSERT INTO boarding_pass (check_in_id, boarding_pass_code, barcode_value, issued_at, created_at, updated_at)
    VALUES (NEW.check_in_id, v_bp_code, v_barcode, NOW(), NOW(), NOW());
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_check_in_generar_boarding_pass
AFTER INSERT ON check_in
FOR EACH ROW EXECUTE FUNCTION fn_generar_boarding_pass();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_check_in(
    p_ticket_segment_id  UUID,
    p_check_in_status_id UUID,
    p_boarding_group_id  UUID,
    p_user_account_id    UUID,
    p_checked_in_at      TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO check_in (ticket_segment_id, check_in_status_id, boarding_group_id,
        checked_in_by_user_id, checked_in_at, created_at, updated_at)
    VALUES (p_ticket_segment_id, p_check_in_status_id, p_boarding_group_id,
        p_user_account_id, p_checked_in_at, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 01
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id        UUID; v_cont_id      UUID; v_country_id   UUID;
    v_state_id     UUID; v_city_id      UUID; v_dist_id      UUID;
    v_addr_id      UUID; v_curr_id      UUID; v_airline_id   UUID;
    v_ptype_id     UUID; v_person_id    UUID; v_ustatus_id   UUID;
    v_uacct_id     UUID; v_manuf_id     UUID; v_model_id     UUID;
    v_cabin_cls_id UUID; v_aircraft_id  UUID; v_acabin_id    UUID;
    v_seat_id      UUID; v_ap_orig      UUID; v_ap_dest      UUID;
    v_fstatus_id   UUID; v_flight_id    UUID; v_fseg_id      UUID;
    v_rstatus_id   UUID; v_schan_id     UUID; v_fclass_id    UUID;
    v_fare_id      UUID; v_tstatus_id   UUID; v_res_id       UUID;
    v_rpax_id      UUID; v_sale_id      UUID; v_tkt_id       UUID;
    v_tseg_id      UUID; v_cistatus_id  UUID; v_bgrp_id      UUID;
    v_dist2_id     UUID; v_addr2_id     UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Bogota', -300) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('SAM', 'South America') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'CO', 'COL', 'Colombia') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'CUN', 'Cundinamarca') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Bogotá') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Fontibón') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av El Dorado') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('COP', 'Peso Colombiano', '$') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'AV', 'Avianca', 'AV', 'AVA') RETURNING airline_id INTO v_airline_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('PAX', 'Pasajero') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name, birth_date)
        VALUES (v_ptype_id, 'Juan', 'Pérez', '1990-05-15') RETURNING person_id INTO v_person_id;
    INSERT INTO user_status (status_code, status_name)
        VALUES ('ACTIVE', 'Activo') RETURNING user_status_id INTO v_ustatus_id;
    INSERT INTO user_account (person_id, user_status_id, username, password_hash)
        VALUES (v_person_id, v_ustatus_id, 'jperez', 'hash_01') RETURNING user_account_id INTO v_uacct_id;
    INSERT INTO aircraft_manufacturer (manufacturer_name)
        VALUES ('Airbus') RETURNING aircraft_manufacturer_id INTO v_manuf_id;
    INSERT INTO aircraft_model (aircraft_manufacturer_id, model_code, model_name, max_range_km)
        VALUES (v_manuf_id, 'A320', 'Airbus A320', 6150) RETURNING aircraft_model_id INTO v_model_id;
    INSERT INTO cabin_class (class_code, class_name)
        VALUES ('Y', 'Económica') RETURNING cabin_class_id INTO v_cabin_cls_id;
    INSERT INTO aircraft (airline_id, aircraft_model_id, registration_number, serial_number, in_service_on)
        VALUES (v_airline_id, v_model_id, 'HK-1234', 'SN-AV-001', '2020-01-01') RETURNING aircraft_id INTO v_aircraft_id;
    INSERT INTO aircraft_cabin (aircraft_id, cabin_class_id, cabin_code, deck_number)
        VALUES (v_aircraft_id, v_cabin_cls_id, 'Y1', 1) RETURNING aircraft_cabin_id INTO v_acabin_id;
    INSERT INTO aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_window)
        VALUES (v_acabin_id, 12, 'A', TRUE) RETURNING aircraft_seat_id INTO v_seat_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr_id, 'El Dorado', 'BOG', 'SKBO') RETURNING airport_id INTO v_ap_orig;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Rionegro') RETURNING district_id INTO v_dist2_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist2_id, 'Aeropuerto Rionegro') RETURNING address_id INTO v_addr2_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr2_id, 'José María Córdova', 'MDE', 'SKRG') RETURNING airport_id INTO v_ap_dest;
    INSERT INTO flight_status (status_code, status_name)
        VALUES ('SCHEDULED', 'Programado') RETURNING flight_status_id INTO v_fstatus_id;
    INSERT INTO flight (airline_id, aircraft_id, flight_status_id, flight_number, service_date)
        VALUES (v_airline_id, v_aircraft_id, v_fstatus_id, 'AV101', CURRENT_DATE) RETURNING flight_id INTO v_flight_id;
    INSERT INTO flight_segment (flight_id, origin_airport_id, destination_airport_id, segment_number,
        scheduled_departure_at, scheduled_arrival_at)
        VALUES (v_flight_id, v_ap_orig, v_ap_dest, 1, NOW()+INTERVAL '2h', NOW()+INTERVAL '3h')
        RETURNING flight_segment_id INTO v_fseg_id;
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('CONFIRMED', 'Confirmada') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('WEB', 'Portal Web') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO fare_class (cabin_class_id, fare_class_code, fare_class_name)
        VALUES (v_cabin_cls_id, 'Y01', 'Económica Básica') RETURNING fare_class_id INTO v_fclass_id;
    INSERT INTO fare (airline_id, origin_airport_id, destination_airport_id, fare_class_id, currency_id,
        fare_code, base_amount, valid_from, baggage_allowance_qty)
        VALUES (v_airline_id, v_ap_orig, v_ap_dest, v_fclass_id, v_curr_id,
                'AV-BOG-MDE-Y01', 250000, CURRENT_DATE, 1) RETURNING fare_id INTO v_fare_id;
    INSERT INTO ticket_status (status_code, status_name)
        VALUES ('ISSUED', 'Emitido') RETURNING ticket_status_id INTO v_tstatus_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ01-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO reservation_passenger (reservation_id, person_id, passenger_sequence_no, passenger_type)
        VALUES (v_res_id, v_person_id, 1, 'ADULT') RETURNING reservation_passenger_id INTO v_rpax_id;
    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at)
        VALUES (v_res_id, v_curr_id, 'SALE-EJ01-001', NOW()) RETURNING sale_id INTO v_sale_id;
    INSERT INTO ticket (sale_id, reservation_passenger_id, fare_id, ticket_status_id, ticket_number, issued_at)
        VALUES (v_sale_id, v_rpax_id, v_fare_id, v_tstatus_id, 'TKT-EJ01-0001', NOW()) RETURNING ticket_id INTO v_tkt_id;
    INSERT INTO ticket_segment (ticket_id, flight_segment_id, segment_sequence_no)
        VALUES (v_tkt_id, v_fseg_id, 1) RETURNING ticket_segment_id INTO v_tseg_id;
    INSERT INTO check_in_status (status_code, status_name)
        VALUES ('CHECKED_IN', 'Registrado') RETURNING check_in_status_id INTO v_cistatus_id;
    INSERT INTO boarding_group (group_code, group_name, sequence_no)
        VALUES ('GRP1', 'Grupo 1', 1) RETURNING boarding_group_id INTO v_bgrp_id;
 
    -- Invocar el procedimiento (dispara el trigger que crea boarding_pass)
    CALL sp_registrar_check_in(v_tseg_id, v_cistatus_id, v_bgrp_id, v_uacct_id, NOW());
 
    RAISE NOTICE '[EJ01] Check-in registrado para ticket_segment: %', v_tseg_id;
END;
$$;
 
-- Validación ejercicio 01
SELECT ci.check_in_id, ci.checked_in_at, bp.boarding_pass_code, bp.barcode_value, bp.issued_at
FROM check_in ci
INNER JOIN boarding_pass bp ON bp.check_in_id = ci.check_in_id
ORDER BY ci.checked_in_at DESC LIMIT 5;

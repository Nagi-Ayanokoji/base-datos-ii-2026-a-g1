SELECT
    r.reservation_code                          AS codigo_reserva,
    f.flight_number                             AS numero_vuelo,
    f.service_date                              AS fecha_servicio,
    t.ticket_number                             AS numero_tiquete,
    rp.passenger_sequence_no                    AS secuencia_pasajero,
    p.first_name || ' ' || p.last_name          AS nombre_pasajero,
    fs.segment_number                           AS segmento_vuelo,
    fs.scheduled_departure_at                   AS hora_programada_salida
FROM reservation r
INNER JOIN reservation_passenger rp
    ON rp.reservation_id = r.reservation_id
INNER JOIN person p
    ON p.person_id = rp.person_id
INNER JOIN ticket t
    ON t.reservation_passenger_id = rp.reservation_passenger_id
INNER JOIN ticket_segment ts
    ON ts.ticket_id = t.ticket_id
INNER JOIN flight_segment fs
    ON fs.flight_segment_id = ts.flight_segment_id
INNER JOIN flight f
    ON f.flight_id = fs.flight_id
ORDER BY
    f.service_date,
    f.flight_number,
    rp.passenger_sequence_no,
    fs.segment_number;

CREATE OR REPLACE FUNCTION fn_generar_boarding_pass()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_boarding_pass_code VARCHAR(40);
    v_barcode_value      VARCHAR(120);
BEGIN
    v_boarding_pass_code := 'BP-' || UPPER(REPLACE(NEW.check_in_id::TEXT, '-', ''));
    v_barcode_value := 'BC-' || UPPER(REPLACE(NEW.check_in_id::TEXT, '-', ''))
                       || '-' || TO_CHAR(NEW.checked_in_at, 'YYYYMMDDHH24MISS');

    INSERT INTO boarding_pass (
        check_in_id,
        boarding_pass_code,
        barcode_value,
        issued_at
    ) VALUES (
        NEW.check_in_id,
        v_boarding_pass_code,
        v_barcode_value,
        NEW.checked_in_at
    );

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_after_checkin_generar_boarding_pass
AFTER INSERT ON check_in
FOR EACH ROW
EXECUTE FUNCTION fn_generar_boarding_pass();

CREATE OR REPLACE PROCEDURE sp_registrar_checkin(
    IN p_ticket_segment_id  UUID,
    IN p_check_in_status_id UUID,
    IN p_boarding_group_id  UUID,
    IN p_user_account_id    UUID,
    IN p_checked_in_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists_ticket_segment INTEGER;
    v_exists_checkin        INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_exists_ticket_segment
    FROM ticket_segment
    WHERE ticket_segment_id = p_ticket_segment_id;

    IF v_exists_ticket_segment = 0 THEN
        RAISE EXCEPTION 'El ticket_segment_id % no existe en el sistema.', p_ticket_segment_id;
    END IF;

    SELECT COUNT(*)
    INTO v_exists_checkin
    FROM check_in
    WHERE ticket_segment_id = p_ticket_segment_id;

    IF v_exists_checkin > 0 THEN
        RAISE EXCEPTION 'Ya existe un check-in registrado para el ticket_segment_id %.', p_ticket_segment_id;
    END IF;

    INSERT INTO check_in (
        ticket_segment_id,
        check_in_status_id,
        boarding_group_id,
        checked_in_by_user_id,
        checked_in_at
    ) VALUES (
        p_ticket_segment_id,
        p_check_in_status_id,
        p_boarding_group_id,
        p_user_account_id,
        p_checked_in_at
    );

    RAISE NOTICE 'Check-in registrado exitosamente para ticket_segment_id: %', p_ticket_segment_id;
END;
$$;

BEGIN;

INSERT INTO time_zone (time_zone_id, time_zone_name, utc_offset_minutes)
VALUES ('00000000-0000-0000-0000-000000000001', 'America/Bogota', -300);

INSERT INTO continent (continent_id, continent_code, continent_name)
VALUES ('00000000-0000-0000-0000-000000000002', 'SAM', 'South America');

INSERT INTO country (country_id, continent_id, iso_alpha2, iso_alpha3, country_name)
VALUES ('00000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000002',
        'CO', 'COL', 'Colombia');

INSERT INTO currency (currency_id, iso_currency_code, currency_name, currency_symbol, minor_units)
VALUES ('00000000-0000-0000-0000-000000000004', 'COP', 'Peso Colombiano', '$', 2);

INSERT INTO airline (airline_id, home_country_id, airline_code, airline_name, iata_code, icao_code)
VALUES ('00000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000003',
        'AV', 'Avianca', 'AV', 'AVA');

INSERT INTO state_province (state_province_id, country_id, state_code, state_name)
VALUES ('00000000-0000-0000-0000-000000000006',
        '00000000-0000-0000-0000-000000000003',
        'CUN', 'Cundinamarca');

INSERT INTO city (city_id, state_province_id, time_zone_id, city_name)
VALUES ('00000000-0000-0000-0000-000000000007',
        '00000000-0000-0000-0000-000000000006',
        '00000000-0000-0000-0000-000000000001',
        'Bogotá');

INSERT INTO district (district_id, city_id, district_name)
VALUES ('00000000-0000-0000-0000-000000000008',
        '00000000-0000-0000-0000-000000000007',
        'Fontibón');

INSERT INTO address (address_id, district_id, address_line_1)
VALUES ('00000000-0000-0000-0000-000000000009',
        '00000000-0000-0000-0000-000000000008',
        'Autopista El Dorado');

INSERT INTO airport (airport_id, address_id, airport_name, iata_code, icao_code)
VALUES ('00000000-0000-0000-0000-000000000010',
        '00000000-0000-0000-0000-000000000009',
        'Aeropuerto El Dorado', 'BOG', 'SKBO');

INSERT INTO address (address_id, district_id, address_line_1)
VALUES ('00000000-0000-0000-0000-000000000011',
        '00000000-0000-0000-0000-000000000008',
        'Zona Aeroportuaria Medellín');

INSERT INTO airport (airport_id, address_id, airport_name, iata_code, icao_code)
VALUES ('00000000-0000-0000-0000-000000000012',
        '00000000-0000-0000-0000-000000000011',
        'Aeropuerto José María Córdova', 'MDE', 'SKRG');

INSERT INTO aircraft_manufacturer (aircraft_manufacturer_id, manufacturer_name)
VALUES ('00000000-0000-0000-0000-000000000013', 'Airbus');

INSERT INTO aircraft_model (aircraft_model_id, aircraft_manufacturer_id, model_code, model_name, max_range_km)
VALUES ('00000000-0000-0000-0000-000000000014',
        '00000000-0000-0000-0000-000000000013',
        'A320', 'Airbus A320', 6150);

INSERT INTO aircraft (aircraft_id, airline_id, aircraft_model_id, registration_number, serial_number, in_service_on)
VALUES ('00000000-0000-0000-0000-000000000015',
        '00000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000014',
        'HK-5270', 'SN-AV-001', '2015-06-01');

INSERT INTO flight_status (flight_status_id, status_code, status_name)
VALUES ('00000000-0000-0000-0000-000000000016', 'SCHEDULED', 'Programado');

INSERT INTO flight (flight_id, airline_id, aircraft_id, flight_status_id, flight_number, service_date)
VALUES ('00000000-0000-0000-0000-000000000017',
        '00000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000015',
        '00000000-0000-0000-0000-000000000016',
        'AV8001', '2025-08-15');

INSERT INTO flight_segment (
    flight_segment_id, flight_id,
    origin_airport_id, destination_airport_id,
    segment_number,
    scheduled_departure_at, scheduled_arrival_at
) VALUES (
    '00000000-0000-0000-0000-000000000018',
    '00000000-0000-0000-0000-000000000017',
    '00000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000012',
    1,
    '2025-08-15 06:00:00-05',
    '2025-08-15 07:00:00-05'
);

INSERT INTO person_type (person_type_id, type_code, type_name)
VALUES ('00000000-0000-0000-0000-000000000019', 'PAX', 'Pasajero');

INSERT INTO person (person_id, person_type_id, first_name, last_name, birth_date, gender_code)
VALUES ('00000000-0000-0000-0000-000000000020',
        '00000000-0000-0000-0000-000000000019',
        'Juan', 'Pérez', '1990-03-15', 'M');

INSERT INTO user_status (user_status_id, status_code, status_name)
VALUES ('00000000-0000-0000-0000-000000000021', 'ACTIVE', 'Activo');

INSERT INTO user_account (user_account_id, person_id, user_status_id, username, password_hash)
VALUES ('00000000-0000-0000-0000-000000000022',
        '00000000-0000-0000-0000-000000000020',
        '00000000-0000-0000-0000-000000000021',
        'jperez', '$2b$12$placeholder_hash_here');

INSERT INTO reservation_status (reservation_status_id, status_code, status_name)
VALUES ('00000000-0000-0000-0000-000000000023', 'CONFIRirmed', 'Confirmada');

INSERT INTO sale_channel (sale_channel_id, channel_code, channel_name)
VALUES ('00000000-0000-0000-0000-000000000024', 'WEB', 'Sitio Web');

INSERT INTO customer_category (customer_category_id, category_code, category_name)
VALUES ('00000000-0000-0000-0000-000000000025', 'REGULAR', 'Regular');

INSERT INTO customer (customer_id, airline_id, person_id, customer_category_id, customer_since)
VALUES ('00000000-0000-0000-0000-000000000026',
        '00000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000020',
        '00000000-0000-0000-0000-000000000025',
        '2020-01-10');

INSERT INTO reservation (
    reservation_id, booked_by_customer_id,
    reservation_status_id, sale_channel_id,
    reservation_code, booked_at
) VALUES (
    '00000000-0000-0000-0000-000000000027',
    '00000000-0000-0000-0000-000000000026',
    '00000000-0000-0000-0000-000000000023',
    '00000000-0000-0000-0000-000000000024',
    'RES-TEST-001',
    '2025-08-01 10:00:00-05'
);

INSERT INTO reservation_passenger (
    reservation_passenger_id, reservation_id, person_id,
    passenger_sequence_no, passenger_type
) VALUES (
    '00000000-0000-0000-0000-000000000028',
    '00000000-0000-0000-0000-000000000027',
    '00000000-0000-0000-0000-000000000020',
    1, 'ADULT'
);

INSERT INTO cabin_class (cabin_class_id, class_code, class_name)
VALUES ('00000000-0000-0000-0000-000000000029', 'Y', 'Economy');

INSERT INTO fare_class (fare_class_id, cabin_class_id, fare_class_code, fare_class_name)
VALUES ('00000000-0000-0000-0000-000000000030',
        '00000000-0000-0000-0000-000000000029',
        'YOW', 'Economy One Way');

INSERT INTO fare (
    fare_id, airline_id,
    origin_airport_id, destination_airport_id,
    fare_class_id, currency_id,
    fare_code, base_amount, valid_from
) VALUES (
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000030',
    '00000000-0000-0000-0000-000000000004',
    'FARE-BOG-MDE-Y', 250000.00, '2025-01-01'
);

INSERT INTO sale (sale_id, reservation_id, currency_id, sale_code, sold_at)
VALUES ('00000000-0000-0000-0000-000000000032',
        '00000000-0000-0000-0000-000000000027',
        '00000000-0000-0000-0000-000000000004',
        'SALE-TEST-001',
        '2025-08-01 10:05:00-05');

INSERT INTO ticket_status (ticket_status_id, status_code, status_name)
VALUES ('00000000-0000-0000-0000-000000000033', 'ISSUED', 'Emitido');

INSERT INTO ticket (
    ticket_id, sale_id, reservation_passenger_id,
    fare_id, ticket_status_id,
    ticket_number, issued_at
) VALUES (
    '00000000-0000-0000-0000-000000000034',
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000028',
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000033',
    'TKT-0001-TEST', '2025-08-01 10:05:00-05'
);

INSERT INTO ticket_segment (
    ticket_segment_id, ticket_id, flight_segment_id,
    segment_sequence_no, fare_basis_code
) VALUES (
    '00000000-0000-0000-0000-000000000035',
    '00000000-0000-0000-0000-000000000034',
    '00000000-0000-0000-0000-000000000018',
    1, 'YOWCOL'
);

INSERT INTO check_in_status (check_in_status_id, status_code, status_name)
VALUES ('00000000-0000-0000-0000-000000000036', 'COMPLETED', 'Completado');

INSERT INTO boarding_group (boarding_group_id, group_code, group_name, sequence_no)
VALUES ('00000000-0000-0000-0000-000000000037', 'GRP-A', 'Grupo A', 1);

CALL sp_registrar_checkin(
    '00000000-0000-0000-0000-000000000035',
    '00000000-0000-0000-0000-000000000036',
    '00000000-0000-0000-0000-000000000037',
    '00000000-0000-0000-0000-000000000022',
    '2025-08-15 04:30:00-05'
);

SELECT
    ci.check_in_id,
    ci.ticket_segment_id,
    ci.checked_in_at,
    cis.status_name     AS estado_checkin,
    bg.group_name       AS grupo_abordaje,
    ua.username         AS usuario_checkin
FROM check_in ci
INNER JOIN check_in_status cis ON cis.check_in_status_id = ci.check_in_status_id
LEFT  JOIN boarding_group bg   ON bg.boarding_group_id   = ci.boarding_group_id
LEFT  JOIN user_account ua     ON ua.user_account_id     = ci.checked_in_by_user_id
WHERE ci.ticket_segment_id = '00000000-0000-0000-0000-000000000035';

SELECT
    bp.boarding_pass_id,
    bp.boarding_pass_code,
    bp.barcode_value,
    bp.issued_at,
    ci.ticket_segment_id
FROM boarding_pass bp
INNER JOIN check_in ci ON ci.check_in_id = bp.check_in_id
WHERE ci.ticket_segment_id = '00000000-0000-0000-0000-000000000035';

SELECT
    r.reservation_code                          AS codigo_reserva,
    f.flight_number                             AS numero_vuelo,
    f.service_date                              AS fecha_servicio,
    t.ticket_number                             AS numero_tiquete,
    rp.passenger_sequence_no                    AS secuencia_pasajero,
    p.first_name || ' ' || p.last_name          AS nombre_pasajero,
    fs.segment_number                           AS segmento_vuelo,
    fs.scheduled_departure_at                   AS hora_programada_salida
FROM reservation r
INNER JOIN reservation_passenger rp
    ON rp.reservation_id = r.reservation_id
INNER JOIN person p
    ON p.person_id = rp.person_id
INNER JOIN ticket t
    ON t.reservation_passenger_id = rp.reservation_passenger_id
INNER JOIN ticket_segment ts
    ON ts.ticket_id = t.ticket_id
INNER JOIN flight_segment fs
    ON fs.flight_segment_id = ts.flight_segment_id
INNER JOIN flight f
    ON f.flight_id = fs.flight_id
WHERE r.reservation_code = 'RES-TEST-001';

ROLLBACK;
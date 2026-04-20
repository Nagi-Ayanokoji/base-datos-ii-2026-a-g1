-- ============================================================
-- EJERCICIO 07
-- Asignación de asientos y registro de equipaje por segmento ticketed
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    t.ticket_number          AS numero_tiquete,
    ts.segment_sequence_no   AS secuencia_segmento,
    f.flight_number          AS vuelo,
    cc.class_name            AS cabina,
    ase.seat_row_number      AS fila,
    ase.seat_column_code     AS columna,
    b.baggage_tag            AS etiqueta_equipaje,
    b.baggage_type           AS tipo_equipaje,
    b.baggage_status         AS estado_equipaje
FROM ticket t
INNER JOIN ticket_segment ts   ON ts.ticket_id = t.ticket_id
INNER JOIN flight_segment fs   ON fs.flight_segment_id = ts.flight_segment_id
INNER JOIN flight f            ON f.flight_id = fs.flight_id
INNER JOIN seat_assignment sa  ON sa.ticket_segment_id = ts.ticket_segment_id
INNER JOIN aircraft_seat ase   ON ase.aircraft_seat_id = sa.aircraft_seat_id
INNER JOIN aircraft_cabin acab ON acab.aircraft_cabin_id = ase.aircraft_cabin_id
INNER JOIN cabin_class cc      ON cc.cabin_class_id = acab.cabin_class_id
INNER JOIN baggage b           ON b.ticket_segment_id = ts.ticket_segment_id
ORDER BY t.ticket_number, ts.segment_sequence_no;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre baggage
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_confirmar_registro_equipaje()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.baggage_status != 'REGISTERED' THEN
        UPDATE baggage SET baggage_status = 'REGISTERED', updated_at = NOW()
        WHERE baggage_id = NEW.baggage_id;
    END IF;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_baggage_insert_confirmar
AFTER INSERT ON baggage
FOR EACH ROW EXECUTE FUNCTION fn_confirmar_registro_equipaje();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_equipaje(
    p_ticket_segment_id UUID,
    p_baggage_tag       VARCHAR(30),
    p_baggage_type      VARCHAR(20),
    p_weight_kg         NUMERIC(6,2),
    p_checked_at        TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO baggage (ticket_segment_id, baggage_tag, baggage_type, baggage_status,
        weight_kg, checked_at, created_at, updated_at)
    VALUES (p_ticket_segment_id, p_baggage_tag, p_baggage_type, 'REGISTERED',
        p_weight_kg, p_checked_at, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 07
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id    UUID; v_country_id  UUID;
    v_state_id   UUID; v_city_id    UUID; v_dist_id     UUID;
    v_addr_id    UUID; v_curr_id    UUID; v_airline_id  UUID;
    v_manuf_id   UUID; v_model_id   UUID; v_cab_cls_id  UUID;
    v_aircraft_id UUID; v_acabin_id UUID; v_seat_id     UUID;
    v_ap_orig    UUID; v_ap_dest    UUID; v_fstatus_id  UUID;
    v_flight_id  UUID; v_fseg_id    UUID; v_rstatus_id  UUID;
    v_schan_id   UUID; v_fclass_id  UUID; v_fare_id     UUID;
    v_tstatus_id UUID; v_ptype_id   UUID; v_person_id   UUID;
    v_res_id     UUID; v_rpax_id    UUID; v_sale_id     UUID;
    v_tkt_id     UUID; v_tseg_id    UUID;
    v_dist2_id   UUID; v_addr2_id   UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Asuncion', -240) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S07', 'South America 07') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'PY', 'PRY', 'Paraguay') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'ASU', 'Asunción') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Asunción') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Luque') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Aeropuerto Silvio Pettirossi') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('PYG', 'Guaraní', '₲') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'PY1', 'Amaszonas Paraguay', 'Z8', 'AZP') RETURNING airline_id INTO v_airline_id;
    INSERT INTO aircraft_manufacturer (manufacturer_name)
        VALUES ('ATR') RETURNING aircraft_manufacturer_id INTO v_manuf_id;
    INSERT INTO aircraft_model (aircraft_manufacturer_id, model_code, model_name, max_range_km)
        VALUES (v_manuf_id, 'ATR72', 'ATR 72-600', 1528) RETURNING aircraft_model_id INTO v_model_id;
    INSERT INTO cabin_class (class_code, class_name)
        VALUES ('EC', 'Economy Class') RETURNING cabin_class_id INTO v_cab_cls_id;
    INSERT INTO aircraft (airline_id, aircraft_model_id, registration_number, serial_number, in_service_on)
        VALUES (v_airline_id, v_model_id, 'ZP-TXA', 'SN-PY-001', '2022-01-01') RETURNING aircraft_id INTO v_aircraft_id;
    INSERT INTO aircraft_cabin (aircraft_id, cabin_class_id, cabin_code, deck_number)
        VALUES (v_aircraft_id, v_cab_cls_id, 'EC1', 1) RETURNING aircraft_cabin_id INTO v_acabin_id;
    INSERT INTO aircraft_seat (aircraft_cabin_id, seat_row_number, seat_column_code, is_aisle)
        VALUES (v_acabin_id, 5, 'B', TRUE) RETURNING aircraft_seat_id INTO v_seat_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr_id, 'Silvio Pettirossi', 'ASU', 'SGAS') RETURNING airport_id INTO v_ap_orig;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'CDE Zona') RETURNING district_id INTO v_dist2_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist2_id, 'Aeropuerto Guaraní') RETURNING address_id INTO v_addr2_id;
    INSERT INTO airport (address_id, airport_name, iata_code, icao_code)
        VALUES (v_addr2_id, 'Guaraní Internacional', 'AGT', 'SGEN') RETURNING airport_id INTO v_ap_dest;
    INSERT INTO flight_status (status_code, status_name)
        VALUES ('ON_TIME', 'En hora') RETURNING flight_status_id INTO v_fstatus_id;
    INSERT INTO flight (airline_id, aircraft_id, flight_status_id, flight_number, service_date)
        VALUES (v_airline_id, v_aircraft_id, v_fstatus_id, 'PY301', CURRENT_DATE) RETURNING flight_id INTO v_flight_id;
    INSERT INTO flight_segment (flight_id, origin_airport_id, destination_airport_id, segment_number,
        scheduled_departure_at, scheduled_arrival_at)
        VALUES (v_flight_id, v_ap_orig, v_ap_dest, 1, NOW()+INTERVAL '3h', NOW()+INTERVAL '4h')
        RETURNING flight_segment_id INTO v_fseg_id;
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('ACTIVE', 'Activa') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('KIOSK', 'Kiosko Aeropuerto') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO fare_class (cabin_class_id, fare_class_code, fare_class_name)
        VALUES (v_cab_cls_id, 'EC01', 'Economy Flex') RETURNING fare_class_id INTO v_fclass_id;
    INSERT INTO fare (airline_id, origin_airport_id, destination_airport_id, fare_class_id, currency_id,
        fare_code, base_amount, valid_from, baggage_allowance_qty)
        VALUES (v_airline_id, v_ap_orig, v_ap_dest, v_fclass_id, v_curr_id,
                'PY-ASU-AGT-EC01', 180000, CURRENT_DATE, 1) RETURNING fare_id INTO v_fare_id;
    INSERT INTO ticket_status (status_code, status_name)
        VALUES ('ACTIVE', 'Activo') RETURNING ticket_status_id INTO v_tstatus_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('TRV', 'Traveler') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Luis', 'Fernández') RETURNING person_id INTO v_person_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ07-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO reservation_passenger (reservation_id, person_id, passenger_sequence_no, passenger_type)
        VALUES (v_res_id, v_person_id, 1, 'ADULT') RETURNING reservation_passenger_id INTO v_rpax_id;
    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at)
        VALUES (v_res_id, v_curr_id, 'SALE-EJ07-001', NOW()) RETURNING sale_id INTO v_sale_id;
    INSERT INTO ticket (sale_id, reservation_passenger_id, fare_id, ticket_status_id, ticket_number, issued_at)
        VALUES (v_sale_id, v_rpax_id, v_fare_id, v_tstatus_id, 'TKT-EJ07-0001', NOW()) RETURNING ticket_id INTO v_tkt_id;
    INSERT INTO ticket_segment (ticket_id, flight_segment_id, segment_sequence_no)
        VALUES (v_tkt_id, v_fseg_id, 1) RETURNING ticket_segment_id INTO v_tseg_id;
    INSERT INTO seat_assignment (ticket_segment_id, flight_segment_id, aircraft_seat_id, assigned_at, assignment_source)
        VALUES (v_tseg_id, v_fseg_id, v_seat_id, NOW(), 'MANUAL');
 
    -- Invocar procedimiento → trigger confirma estado REGISTERED
    CALL sp_registrar_equipaje(v_tseg_id, 'TAG-EJ07-0001', 'CHECKED', 23.5, NOW());
 
    RAISE NOTICE '[EJ07] Equipaje registrado para ticket_segment: %', v_tseg_id;
END;
$$;
 
-- Validación ejercicio 07
SELECT b.baggage_tag, b.baggage_type, b.baggage_status, b.weight_kg, b.checked_at
FROM baggage b ORDER BY b.created_at DESC LIMIT 5;

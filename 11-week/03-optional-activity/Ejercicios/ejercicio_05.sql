-- ============================================================
-- EJERCICIO 05
-- Mantenimiento de aeronaves y habilitación operativa
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    ac.registration_number AS matricula,
    al.airline_name        AS aerolinea,
    am.model_name          AS modelo,
    amf.manufacturer_name  AS fabricante,
    mt.type_name           AS tipo_mantenimiento,
    mp.provider_name       AS proveedor,
    me.status_code         AS estado_evento,
    me.started_at          AS fecha_inicio,
    me.completed_at        AS fecha_fin
FROM aircraft ac
INNER JOIN airline al                ON al.airline_id = ac.airline_id
INNER JOIN aircraft_model am         ON am.aircraft_model_id = ac.aircraft_model_id
INNER JOIN aircraft_manufacturer amf ON amf.aircraft_manufacturer_id = am.aircraft_manufacturer_id
INNER JOIN maintenance_event me      ON me.aircraft_id = ac.aircraft_id
INNER JOIN maintenance_type mt       ON mt.maintenance_type_id = me.maintenance_type_id
INNER JOIN maintenance_provider mp   ON mp.maintenance_provider_id = me.maintenance_provider_id
ORDER BY ac.registration_number, me.started_at DESC;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre maintenance_event
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_aeronave_mantenimiento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_ret DATE;
BEGIN
    SELECT retired_on INTO v_ret FROM aircraft WHERE aircraft_id = NEW.aircraft_id;
    IF v_ret IS NOT NULL AND v_ret <= CURRENT_DATE THEN
        RAISE EXCEPTION 'Aeronave retirada desde %. No se puede registrar mantenimiento.', v_ret;
    END IF;
    UPDATE maintenance_event
    SET notes = COALESCE(notes,'') || ' [Validado: aeronave operativa al ' || NOW()::text || ']',
        updated_at = NOW()
    WHERE maintenance_event_id = NEW.maintenance_event_id;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_maintenance_event_validar
AFTER INSERT ON maintenance_event
FOR EACH ROW EXECUTE FUNCTION fn_validar_aeronave_mantenimiento();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_mantenimiento(
    p_aircraft_id             UUID,
    p_maintenance_type_id     UUID,
    p_maintenance_provider_id UUID,
    p_status_code             VARCHAR(20),
    p_started_at              TIMESTAMPTZ,
    p_notes                   TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO maintenance_event (aircraft_id, maintenance_type_id, maintenance_provider_id,
        status_code, started_at, notes, created_at, updated_at)
    VALUES (p_aircraft_id, p_maintenance_type_id, p_maintenance_provider_id,
        p_status_code, p_started_at, p_notes, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 05
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id     UUID; v_cont_id   UUID; v_country_id UUID;
    v_state_id  UUID; v_city_id   UUID; v_dist_id    UUID;
    v_addr_id   UUID; v_curr_id   UUID; v_airline_id UUID;
    v_manuf_id  UUID; v_model_id  UUID; v_aircraft_id UUID;
    v_mtype_id  UUID; v_mprov_id  UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Buenos_Aires', -180) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S05', 'South America 05') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'AR', 'ARG', 'Argentina') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'BA', 'Buenos Aires') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Buenos Aires') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Ezeiza') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Aeropuerto Internacional Ezeiza') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('ARS', 'Peso Argentino', '$') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'AR1', 'Aerolíneas Argentinas', 'AR', 'ARG') RETURNING airline_id INTO v_airline_id;
    INSERT INTO aircraft_manufacturer (manufacturer_name)
        VALUES ('Boeing') RETURNING aircraft_manufacturer_id INTO v_manuf_id;
    INSERT INTO aircraft_model (aircraft_manufacturer_id, model_code, model_name, max_range_km)
        VALUES (v_manuf_id, 'B737', 'Boeing 737', 5600) RETURNING aircraft_model_id INTO v_model_id;
    INSERT INTO aircraft (airline_id, aircraft_model_id, registration_number, serial_number, in_service_on)
        VALUES (v_airline_id, v_model_id, 'LV-GVN', 'SN-AR-001', '2019-03-15') RETURNING aircraft_id INTO v_aircraft_id;
    INSERT INTO maintenance_type (type_code, type_name)
        VALUES ('CHECK_A', 'Check A') RETURNING maintenance_type_id INTO v_mtype_id;
    INSERT INTO maintenance_provider (address_id, provider_name, contact_name)
        VALUES (v_addr_id, 'TechAir Argentina', 'Roberto López') RETURNING maintenance_provider_id INTO v_mprov_id;
 
    -- Invocar procedimiento → trigger valida aeronave y deja traza en notes
    CALL sp_registrar_mantenimiento(v_aircraft_id, v_mtype_id, v_mprov_id, 'PLANNED', NOW(), 'Check A preventivo');
 
    RAISE NOTICE '[EJ05] Mantenimiento registrado para aeronave: %', v_aircraft_id;
END;
$$;
 
-- Validación ejercicio 05
SELECT me.maintenance_event_id, ac.registration_number, mt.type_name, me.status_code, me.notes, me.updated_at
FROM maintenance_event me
INNER JOIN aircraft ac        ON ac.aircraft_id = me.aircraft_id
INNER JOIN maintenance_type mt ON mt.maintenance_type_id = me.maintenance_type_id
ORDER BY me.created_at DESC LIMIT 5;

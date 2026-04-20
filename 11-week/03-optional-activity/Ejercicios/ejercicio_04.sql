-- ============================================================
-- EJERCICIO 04
-- Acumulación de millas y actualización del historial de nivel
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    p.first_name || ' ' || p.last_name AS nombre_cliente,
    la.account_number                   AS cuenta_fidelizacion,
    lp.program_name                     AS programa,
    lt.tier_name                        AS nivel,
    lat.assigned_at                     AS fecha_asignacion_nivel,
    s.sale_code                         AS venta_relacionada
FROM customer cu
INNER JOIN person p               ON p.person_id = cu.person_id
INNER JOIN loyalty_account la     ON la.customer_id = cu.customer_id
INNER JOIN loyalty_program lp     ON lp.loyalty_program_id = la.loyalty_program_id
INNER JOIN loyalty_account_tier lat ON lat.loyalty_account_id = la.loyalty_account_id
INNER JOIN loyalty_tier lt        ON lt.loyalty_tier_id = lat.loyalty_tier_id
INNER JOIN reservation r          ON r.booked_by_customer_id = cu.customer_id
INNER JOIN sale s                 ON s.reservation_id = r.reservation_id
ORDER BY cu.customer_id, lat.assigned_at DESC;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre miles_transaction
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_evaluar_nivel_por_millas()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_total   INTEGER;
    v_tier_id UUID;
    v_prog_id UUID;
BEGIN
    IF NEW.transaction_type != 'EARN' THEN RETURN NEW; END IF;
    SELECT lp.loyalty_program_id INTO v_prog_id
    FROM loyalty_account la
    INNER JOIN loyalty_program lp ON lp.loyalty_program_id = la.loyalty_program_id
    WHERE la.loyalty_account_id = NEW.loyalty_account_id;
    SELECT COALESCE(SUM(miles_delta),0) INTO v_total
    FROM miles_transaction WHERE loyalty_account_id = NEW.loyalty_account_id;
    SELECT lt.loyalty_tier_id INTO v_tier_id
    FROM loyalty_tier lt
    WHERE lt.loyalty_program_id = v_prog_id AND lt.required_miles <= v_total
    ORDER BY lt.required_miles DESC LIMIT 1;
    IF v_tier_id IS NOT NULL THEN
        INSERT INTO loyalty_account_tier (loyalty_account_id, loyalty_tier_id, assigned_at, created_at, updated_at)
        VALUES (NEW.loyalty_account_id, v_tier_id, NOW(), NOW(), NOW())
        ON CONFLICT (loyalty_account_id, assigned_at) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_miles_transaction_nivel
AFTER INSERT ON miles_transaction
FOR EACH ROW EXECUTE FUNCTION fn_evaluar_nivel_por_millas();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_acumular_millas(
    p_loyalty_account_id UUID,
    p_transaction_type   VARCHAR(20),
    p_miles_delta        INTEGER,
    p_occurred_at        TIMESTAMPTZ DEFAULT NOW(),
    p_reference_code     VARCHAR(60) DEFAULT NULL,
    p_notes              TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO miles_transaction (loyalty_account_id, transaction_type, miles_delta,
        occurred_at, reference_code, notes, created_at, updated_at)
    VALUES (p_loyalty_account_id, p_transaction_type, p_miles_delta,
        p_occurred_at, p_reference_code, p_notes, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 04
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id    UUID; v_country_id UUID;
    v_state_id   UUID; v_city_id    UUID; v_dist_id    UUID;
    v_addr_id    UUID; v_curr_id    UUID; v_airline_id UUID;
    v_ptype_id   UUID; v_person_id  UUID; v_cust_id    UUID;
    v_prog_id    UUID; v_tier_base  UUID; v_tier_plata UUID;
    v_acct_id    UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Santiago', -240) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S04', 'South America 04') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'CL', 'CHL', 'Chile') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'RM', 'Region Metropolitana') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Santiago') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Providencia') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av. Providencia 1') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('CLP', 'Peso Chileno', '$') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'SK', 'Sky Airline', 'H2', 'SKU') RETURNING airline_id INTO v_airline_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('VIP', 'VIP') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Ana', 'Martínez') RETURNING person_id INTO v_person_id;
    INSERT INTO customer (airline_id, person_id)
        VALUES (v_airline_id, v_person_id) RETURNING customer_id INTO v_cust_id;
    INSERT INTO loyalty_program (airline_id, default_currency_id, program_code, program_name)
        VALUES (v_airline_id, v_curr_id, 'SKYMILES', 'Sky Miles Program') RETURNING loyalty_program_id INTO v_prog_id;
    INSERT INTO loyalty_tier (loyalty_program_id, tier_code, tier_name, priority_level, required_miles)
        VALUES (v_prog_id, 'BASE', 'Base', 1, 0) RETURNING loyalty_tier_id INTO v_tier_base;
    INSERT INTO loyalty_tier (loyalty_program_id, tier_code, tier_name, priority_level, required_miles)
        VALUES (v_prog_id, 'SLV', 'Plata', 2, 5000) RETURNING loyalty_tier_id INTO v_tier_plata;
    INSERT INTO loyalty_account (customer_id, loyalty_program_id, account_number)
        VALUES (v_cust_id, v_prog_id, 'ACCT-EJ04-001') RETURNING loyalty_account_id INTO v_acct_id;
 
    -- Invocar procedimiento → trigger evalúa y sube de nivel
    CALL sp_acumular_millas(v_acct_id, 'EARN', 6000, NOW(), 'VUELO-AV101', 'Millas por vuelo BOG-MDE');
 
    RAISE NOTICE '[EJ04] Millas acumuladas en cuenta: %', v_acct_id;
END;
$$;
 
-- Validación ejercicio 04
SELECT la.account_number, mt.miles_delta, mt.transaction_type, lt.tier_name, lat.assigned_at
FROM loyalty_account la
INNER JOIN miles_transaction mt     ON mt.loyalty_account_id = la.loyalty_account_id
INNER JOIN loyalty_account_tier lat ON lat.loyalty_account_id = la.loyalty_account_id
INNER JOIN loyalty_tier lt          ON lt.loyalty_tier_id = lat.loyalty_tier_id
ORDER BY mt.occurred_at DESC LIMIT 10;

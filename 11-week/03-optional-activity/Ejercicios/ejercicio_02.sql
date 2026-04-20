-- ============================================================
-- EJERCICIO 02
-- Control de pagos y trazabilidad de transacciones financieras
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    s.sale_code              AS codigo_venta,
    r.reservation_code       AS codigo_reserva,
    p.payment_reference      AS referencia_pago,
    ps.status_name           AS estado_pago,
    pm.method_name           AS metodo_pago,
    pt.transaction_reference AS referencia_transaccion,
    pt.transaction_type      AS tipo_transaccion,
    pt.transaction_amount    AS monto_procesado,
    c.iso_currency_code      AS moneda
FROM sale s
INNER JOIN reservation r        ON r.reservation_id = s.reservation_id
INNER JOIN payment p            ON p.sale_id = s.sale_id
INNER JOIN payment_status ps    ON ps.payment_status_id = p.payment_status_id
INNER JOIN payment_method pm    ON pm.payment_method_id = p.payment_method_id
INNER JOIN payment_transaction pt ON pt.payment_id = p.payment_id
INNER JOIN currency c           ON c.currency_id = p.currency_id
ORDER BY s.sale_code, p.payment_reference, pt.processed_at;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre payment_transaction
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_crear_refund_desde_transaccion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_ref VARCHAR(40);
BEGIN
    IF NEW.transaction_type = 'REFUND' THEN
        v_ref := 'REF-' || UPPER(SUBSTRING(NEW.payment_transaction_id::text,1,8))
                 || '-' || TO_CHAR(NOW(),'YYYYMMDD');
        INSERT INTO refund (payment_id, refund_reference, amount, requested_at, refund_reason, created_at, updated_at)
        VALUES (NEW.payment_id, v_ref, NEW.transaction_amount, NEW.processed_at,
                'Generado automáticamente desde transacción REFUND', NOW(), NOW());
    END IF;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_payment_transaction_refund
AFTER INSERT ON payment_transaction
FOR EACH ROW EXECUTE FUNCTION fn_crear_refund_desde_transaccion();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_transaccion_pago(
    p_payment_id            UUID,
    p_transaction_reference VARCHAR(60),
    p_transaction_type      VARCHAR(20),
    p_transaction_amount    NUMERIC(12,2),
    p_processed_at          TIMESTAMPTZ DEFAULT NOW(),
    p_provider_message      TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO payment_transaction (payment_id, transaction_reference, transaction_type,
        transaction_amount, processed_at, provider_message, created_at, updated_at)
    VALUES (p_payment_id, p_transaction_reference, p_transaction_type,
        p_transaction_amount, p_processed_at, p_provider_message, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 02
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id     UUID; v_cont_id   UUID; v_country_id UUID;
    v_state_id  UUID; v_city_id   UUID; v_dist_id    UUID;
    v_addr_id   UUID; v_curr_id   UUID; v_airline_id UUID;
    v_ptype_id  UUID; v_person_id UUID;
    v_rstatus_id UUID; v_schan_id UUID; v_res_id     UUID;
    v_sale_id   UUID; v_pstatus_id UUID; v_pmethod_id UUID;
    v_pay_id    UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Lima', -300) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S02', 'South America 02') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'PE', 'PER', 'Peru') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'LIM', 'Lima') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Lima') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Miraflores') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av. Larco 100') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('USD', 'US Dollar', '$') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'LA', 'LATAM', 'LA', 'LAN') RETURNING airline_id INTO v_airline_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('CLI', 'Cliente') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Maria', 'Gonzalez') RETURNING person_id INTO v_person_id;
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('PAID', 'Pagada') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('MOB', 'App Móvil') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ02-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at)
        VALUES (v_res_id, v_curr_id, 'SALE-EJ02-001', NOW()) RETURNING sale_id INTO v_sale_id;
    INSERT INTO payment_status (status_code, status_name)
        VALUES ('AUTHORIZED', 'Autorizado') RETURNING payment_status_id INTO v_pstatus_id;
    INSERT INTO payment_method (method_code, method_name)
        VALUES ('CARD', 'Tarjeta de Crédito') RETURNING payment_method_id INTO v_pmethod_id;
    INSERT INTO payment (sale_id, payment_status_id, payment_method_id, currency_id,
        payment_reference, amount, authorized_at)
        VALUES (v_sale_id, v_pstatus_id, v_pmethod_id, v_curr_id, 'PAY-EJ02-001', 500.00, NOW())
        RETURNING payment_id INTO v_pay_id;
 
    -- Invocar procedimiento con tipo REFUND → activa el trigger
    CALL sp_registrar_transaccion_pago(v_pay_id, 'TXN-EJ02-REFUND-001', 'REFUND', 500.00, NOW(), 'Devolución aprobada');
 
    RAISE NOTICE '[EJ02] Transacción REFUND registrada para payment_id: %', v_pay_id;
END;
$$;
 
-- Validación ejercicio 02
SELECT pt.transaction_reference, pt.transaction_type, pt.transaction_amount,
       rf.refund_reference, rf.amount AS monto_devolucion, rf.requested_at
FROM payment_transaction pt
INNER JOIN refund rf ON rf.payment_id = pt.payment_id
WHERE pt.transaction_type = 'REFUND'
ORDER BY pt.processed_at DESC LIMIT 5;

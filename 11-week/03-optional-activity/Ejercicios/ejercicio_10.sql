-- ============================================================
-- EJERCICIO 10
-- Identidad de pasajeros, documentos y medios de contacto
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    p.first_name || ' ' || p.last_name AS persona,
    pt.type_name                        AS tipo_persona,
    dt.type_name                        AS tipo_documento,
    pd.document_number                  AS numero_documento,
    ct.type_name                        AS tipo_contacto,
    pc.contact_value                    AS valor_contacto,
    r.reservation_code                  AS reserva_relacionada,
    rp.passenger_sequence_no            AS secuencia_pasajero
FROM person p
INNER JOIN person_type pt         ON pt.person_type_id = p.person_type_id
INNER JOIN person_document pd     ON pd.person_id = p.person_id
INNER JOIN document_type dt       ON dt.document_type_id = pd.document_type_id
INNER JOIN person_contact pc      ON pc.person_id = p.person_id
INNER JOIN contact_type ct        ON ct.contact_type_id = pc.contact_type_id
INNER JOIN reservation_passenger rp ON rp.person_id = p.person_id
INNER JOIN reservation r          ON r.reservation_id = rp.reservation_id
ORDER BY p.last_name, p.first_name, dt.type_name;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre person_document
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_trazabilidad_documento()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE person SET updated_at = NOW() WHERE person_id = NEW.person_id;
    RAISE NOTICE 'Documento registrado: persona_id=%, número=%, vence=%',
        NEW.person_id, NEW.document_number, NEW.expires_on;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_person_document_insert
AFTER INSERT ON person_document
FOR EACH ROW EXECUTE FUNCTION fn_registrar_trazabilidad_documento();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_registrar_documento_persona(
    p_person_id          UUID,
    p_document_type_id   UUID,
    p_issuing_country_id UUID,
    p_document_number    VARCHAR(64),
    p_issued_on          DATE DEFAULT NULL,
    p_expires_on         DATE DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO person_document (person_id, document_type_id, issuing_country_id,
        document_number, issued_on, expires_on, created_at, updated_at)
    VALUES (p_person_id, p_document_type_id, p_issuing_country_id,
        p_document_number, p_issued_on, p_expires_on, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 10
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id       UUID; v_cont_id     UUID; v_country_id  UUID;
    v_state_id    UUID; v_city_id     UUID; v_dist_id     UUID;
    v_addr_id     UUID;
    v_ptype_id    UUID; v_person_id   UUID;
    v_doc_type_id UUID; v_cont_type_id UUID;
    v_rstatus_id  UUID; v_schan_id    UUID; v_res_id      UUID;
    v_rpax_id     UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Paramaribo', -180) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S10', 'South America 10') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'SR', 'SUR', 'Suriname') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'PAR', 'Paramaribo') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Paramaribo') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Centrum') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Waterkant 1') RETURNING address_id INTO v_addr_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('GEN', 'General') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name, birth_date, nationality_country_id)
        VALUES (v_ptype_id, 'Sofia', 'Ramírez', '1985-08-22', v_country_id) RETURNING person_id INTO v_person_id;
    INSERT INTO document_type (type_code, type_name)
        VALUES ('PASAPORTE', 'Pasaporte') RETURNING document_type_id INTO v_doc_type_id;
    INSERT INTO contact_type (type_code, type_name)
        VALUES ('EMAIL', 'Correo electrónico') RETURNING contact_type_id INTO v_cont_type_id;
    INSERT INTO person_contact (person_id, contact_type_id, contact_value, is_primary)
        VALUES (v_person_id, v_cont_type_id, 'sofia.ramirez@example.com', TRUE);
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('NEW', 'Nueva') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('CALL', 'Centro de Llamadas') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ10-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO reservation_passenger (reservation_id, person_id, passenger_sequence_no, passenger_type)
        VALUES (v_res_id, v_person_id, 1, 'ADULT') RETURNING reservation_passenger_id INTO v_rpax_id;
 
    -- Invocar procedimiento → trigger actualiza person.updated_at y emite NOTICE
    CALL sp_registrar_documento_persona(v_person_id, v_doc_type_id, v_country_id,
        'P-SR-00123456', '2019-05-10', '2029-05-10');
 
    RAISE NOTICE '[EJ10] Documento registrado para persona: %', v_person_id;
END;
$$;
 
-- Validación ejercicio 10
SELECT p.first_name || ' ' || p.last_name AS persona, p.updated_at AS ultima_actualizacion,
       dt.type_name AS tipo_documento, pd.document_number, pd.issued_on, pd.expires_on
FROM person p
INNER JOIN person_document pd ON pd.person_id = p.person_id
INNER JOIN document_type dt   ON dt.document_type_id = pd.document_type_id
ORDER BY pd.created_at DESC LIMIT 5;

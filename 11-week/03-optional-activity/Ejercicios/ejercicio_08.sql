-- ============================================================
-- EJERCICIO 08
-- Auditoría de acceso y asignación de roles a usuarios
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    p.first_name || ' ' || p.last_name AS persona,
    ua.username                         AS usuario,
    us.status_name                      AS estado_usuario,
    sr.role_name                        AS rol_asignado,
    ur.assigned_at                      AS fecha_asignacion,
    sp.permission_name                  AS permiso_asociado
FROM person p
INNER JOIN user_account ua      ON ua.person_id = p.person_id
INNER JOIN user_status us       ON us.user_status_id = ua.user_status_id
INNER JOIN user_role ur         ON ur.user_account_id = ua.user_account_id
INNER JOIN security_role sr     ON sr.security_role_id = ur.security_role_id
INNER JOIN role_permission rp   ON rp.security_role_id = sr.security_role_id
INNER JOIN security_permission sp ON sp.security_permission_id = rp.security_permission_id
ORDER BY ua.username, sr.role_name, sp.permission_name;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre user_role
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_cambio_rol_usuario()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE user_account SET updated_at = NOW() WHERE user_account_id = NEW.user_account_id;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_user_role_insert
AFTER INSERT ON user_role
FOR EACH ROW EXECUTE FUNCTION fn_registrar_cambio_rol_usuario();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_asignar_rol_usuario(
    p_user_account_id     UUID,
    p_security_role_id    UUID,
    p_assigned_by_user_id UUID DEFAULT NULL,
    p_assigned_at         TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO user_role (user_account_id, security_role_id, assigned_at,
        assigned_by_user_id, created_at, updated_at)
    VALUES (p_user_account_id, p_security_role_id, p_assigned_at,
        p_assigned_by_user_id, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 08
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id   UUID; v_country_id UUID;
    v_state_id   UUID; v_city_id   UUID; v_dist_id    UUID;
    v_addr_id    UUID;
    v_ptype_id   UUID; v_person_id UUID; v_ustatus_id UUID;
    v_uacct_id   UUID; v_role_id   UUID; v_perm_id    UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Montevideo', -180) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S08', 'South America 08') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'UY', 'URY', 'Uruguay') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'MV', 'Montevideo') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Montevideo') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Centro') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av. 18 de Julio 1') RETURNING address_id INTO v_addr_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('ADM', 'Administrador') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Pedro', 'Alonso') RETURNING person_id INTO v_person_id;
    INSERT INTO user_status (status_code, status_name)
        VALUES ('ENABLED', 'Habilitado') RETURNING user_status_id INTO v_ustatus_id;
    INSERT INTO user_account (person_id, user_status_id, username, password_hash)
        VALUES (v_person_id, v_ustatus_id, 'palonso', 'hash_ej08') RETURNING user_account_id INTO v_uacct_id;
    INSERT INTO security_role (role_code, role_name, role_description)
        VALUES ('OPS_AGENT', 'Agente de Operaciones', 'Acceso operaciones') RETURNING security_role_id INTO v_role_id;
    INSERT INTO security_permission (permission_code, permission_name)
        VALUES ('FLIGHT_VIEW', 'Ver vuelos') RETURNING security_permission_id INTO v_perm_id;
    INSERT INTO role_permission (security_role_id, security_permission_id)
        VALUES (v_role_id, v_perm_id);
 
    -- Invocar procedimiento → trigger actualiza updated_at de user_account
    CALL sp_asignar_rol_usuario(v_uacct_id, v_role_id, NULL, NOW());
 
    RAISE NOTICE '[EJ08] Rol asignado al usuario: %', v_uacct_id;
END;
$$;
 
-- Validación ejercicio 08
SELECT ua.username, ua.updated_at AS ultima_modificacion, sr.role_name, ur.assigned_at
FROM user_account ua
INNER JOIN user_role ur     ON ur.user_account_id = ua.user_account_id
INNER JOIN security_role sr ON sr.security_role_id = ur.security_role_id
ORDER BY ur.assigned_at DESC LIMIT 5;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- GEOGRAPHY AND REFERENCE DATA
-- ============================================

CREATE TABLE time_zone (
    time_zone_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    time_zone_name varchar(64) NOT NULL,
    utc_offset_minutes integer NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_time_zone_name UNIQUE (time_zone_name)
);

CREATE TABLE continent (
    continent_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    continent_code varchar(3) NOT NULL,
    continent_name varchar(64) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_continent_code UNIQUE (continent_code),
    CONSTRAINT uq_continent_name UNIQUE (continent_name)
);

CREATE TABLE country (
    country_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    continent_id uuid NOT NULL REFERENCES continent(continent_id),
    iso_alpha2 varchar(2) NOT NULL,
    iso_alpha3 varchar(3) NOT NULL,
    country_name varchar(128) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_country_alpha2 UNIQUE (iso_alpha2),
    CONSTRAINT uq_country_alpha3 UNIQUE (iso_alpha3),
    CONSTRAINT uq_country_name UNIQUE (country_name)
);

CREATE TABLE state_province (
    state_province_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id uuid NOT NULL REFERENCES country(country_id),
    state_code varchar(10),
    state_name varchar(128) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_state_country_name UNIQUE (country_id, state_name)
);

CREATE TABLE city (
    city_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    state_province_id uuid NOT NULL REFERENCES state_province(state_province_id),
    time_zone_id uuid NOT NULL REFERENCES time_zone(time_zone_id),
    city_name varchar(128) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_city_state_name UNIQUE (state_province_id, city_name)
);

CREATE TABLE district (
    district_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    city_id uuid NOT NULL REFERENCES city(city_id),
    district_name varchar(128) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_district_city_name UNIQUE (city_id, district_name)
);

CREATE TABLE address (
    address_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id uuid NOT NULL REFERENCES district(district_id),
    address_line_1 varchar(200) NOT NULL,
    address_line_2 varchar(200),
    postal_code varchar(20),
    latitude numeric(10, 7),
    longitude numeric(10, 7),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_address_latitude CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_address_longitude CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE TABLE currency (
    currency_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    iso_currency_code varchar(3) NOT NULL,
    currency_name varchar(64) NOT NULL,
    currency_symbol varchar(8),
    minor_units smallint NOT NULL DEFAULT 2,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_currency_code UNIQUE (iso_currency_code),
    CONSTRAINT uq_currency_name UNIQUE (currency_name),
    CONSTRAINT ck_currency_minor_units CHECK (minor_units BETWEEN 0 AND 4)
);

-- ============================================
-- AIRLINE
-- ============================================

CREATE TABLE airline (
    airline_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    home_country_id uuid NOT NULL REFERENCES country(country_id),
    airline_code varchar(10) NOT NULL,
    airline_name varchar(150) NOT NULL,
    iata_code varchar(2),
    icao_code varchar(3),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_airline_code UNIQUE (airline_code),
    CONSTRAINT uq_airline_name UNIQUE (airline_name),
    CONSTRAINT uq_airline_iata UNIQUE (iata_code),
    CONSTRAINT uq_airline_icao UNIQUE (icao_code),
    CONSTRAINT ck_airline_iata_len CHECK (iata_code IS NULL OR char_length(iata_code) = 2),
    CONSTRAINT ck_airline_icao_len CHECK (icao_code IS NULL OR char_length(icao_code) = 3)
);

-- ============================================
-- IDENTITY
-- ============================================

CREATE TABLE person_type (
    person_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type_code varchar(20) NOT NULL,
    type_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_person_type_code UNIQUE (type_code),
    CONSTRAINT uq_person_type_name UNIQUE (type_name)
);

CREATE TABLE document_type (
    document_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type_code varchar(20) NOT NULL,
    type_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_document_type_code UNIQUE (type_code),
    CONSTRAINT uq_document_type_name UNIQUE (type_name)
);

CREATE TABLE contact_type (
    contact_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type_code varchar(20) NOT NULL,
    type_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_contact_type_code UNIQUE (type_code),
    CONSTRAINT uq_contact_type_name UNIQUE (type_name)
);

CREATE TABLE person (
    person_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_type_id uuid NOT NULL REFERENCES person_type(person_type_id),
    nationality_country_id uuid REFERENCES country(country_id),
    first_name varchar(80) NOT NULL,
    middle_name varchar(80),
    last_name varchar(80) NOT NULL,
    second_last_name varchar(80),
    birth_date date,
    gender_code varchar(1),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_person_gender CHECK (gender_code IS NULL OR gender_code IN ('F', 'M', 'X'))
);

CREATE TABLE person_document (
    person_document_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES person(person_id),
    document_type_id uuid NOT NULL REFERENCES document_type(document_type_id),
    issuing_country_id uuid REFERENCES country(country_id),
    document_number varchar(64) NOT NULL,
    issued_on date,
    expires_on date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_person_document_natural UNIQUE (document_type_id, issuing_country_id, document_number),
    CONSTRAINT ck_person_document_dates CHECK (expires_on IS NULL OR issued_on IS NULL OR expires_on >= issued_on)
);

CREATE TABLE person_contact (
    person_contact_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES person(person_id),
    contact_type_id uuid NOT NULL REFERENCES contact_type(contact_type_id),
    contact_value varchar(180) NOT NULL,
    is_primary boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_person_contact_value UNIQUE (person_id, contact_type_id, contact_value)
);

-- ============================================
-- SECURITY
-- ============================================

CREATE TABLE user_status (
    user_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_status_code UNIQUE (status_code),
    CONSTRAINT uq_user_status_name UNIQUE (status_name)
);

CREATE TABLE security_role (
    security_role_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_code varchar(30) NOT NULL,
    role_name varchar(100) NOT NULL,
    role_description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_security_role_code UNIQUE (role_code),
    CONSTRAINT uq_security_role_name UNIQUE (role_name)
);

CREATE TABLE security_permission (
    security_permission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_code varchar(50) NOT NULL,
    permission_name varchar(120) NOT NULL,
    permission_description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_security_permission_code UNIQUE (permission_code),
    CONSTRAINT uq_security_permission_name UNIQUE (permission_name)
);

CREATE TABLE user_account (
    user_account_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES person(person_id),
    user_status_id uuid NOT NULL REFERENCES user_status(user_status_id),
    username varchar(80) NOT NULL,
    password_hash varchar(255) NOT NULL,
    last_login_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_account_person UNIQUE (person_id),
    CONSTRAINT uq_user_account_username UNIQUE (username)
);

CREATE TABLE user_role (
    user_role_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_account_id uuid NOT NULL REFERENCES user_account(user_account_id),
    security_role_id uuid NOT NULL REFERENCES security_role(security_role_id),
    assigned_at timestamptz NOT NULL DEFAULT now(),
    assigned_by_user_id uuid REFERENCES user_account(user_account_id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_role UNIQUE (user_account_id, security_role_id)
);

CREATE TABLE role_permission (
    role_permission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    security_role_id uuid NOT NULL REFERENCES security_role(security_role_id),
    security_permission_id uuid NOT NULL REFERENCES security_permission(security_permission_id),
    granted_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_role_permission UNIQUE (security_role_id, security_permission_id)
);

-- ============================================
-- CUSTOMER AND LOYALTY
-- ============================================

CREATE TABLE customer_category (
    customer_category_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category_code varchar(20) NOT NULL,
    category_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_customer_category_code UNIQUE (category_code),
    CONSTRAINT uq_customer_category_name UNIQUE (category_name)
);

CREATE TABLE benefit_type (
    benefit_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    benefit_code varchar(30) NOT NULL,
    benefit_name varchar(100) NOT NULL,
    benefit_description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_benefit_type_code UNIQUE (benefit_code),
    CONSTRAINT uq_benefit_type_name UNIQUE (benefit_name)
);

CREATE TABLE loyalty_program (
    loyalty_program_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airline(airline_id),
    default_currency_id uuid NOT NULL REFERENCES currency(currency_id),
    program_code varchar(20) NOT NULL,
    program_name varchar(120) NOT NULL,
    expiration_months integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_loyalty_program_code UNIQUE (airline_id, program_code),
    CONSTRAINT uq_loyalty_program_name UNIQUE (airline_id, program_name),
    CONSTRAINT ck_loyalty_program_expiration CHECK (expiration_months IS NULL OR expiration_months > 0)
);

CREATE TABLE loyalty_tier (
    loyalty_tier_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    loyalty_program_id uuid NOT NULL REFERENCES loyalty_program(loyalty_program_id),
    tier_code varchar(20) NOT NULL,
    tier_name varchar(80) NOT NULL,
    priority_level integer NOT NULL,
    required_miles integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_loyalty_tier_code UNIQUE (loyalty_program_id, tier_code),
    CONSTRAINT uq_loyalty_tier_name UNIQUE (loyalty_program_id, tier_name),
    CONSTRAINT ck_loyalty_tier_priority CHECK (priority_level > 0),
    CONSTRAINT ck_loyalty_tier_required_miles CHECK (required_miles >= 0)
);

CREATE TABLE customer (
    customer_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airline(airline_id),
    person_id uuid NOT NULL REFERENCES person(person_id),
    customer_category_id uuid REFERENCES customer_category(customer_category_id),
    customer_since date NOT NULL DEFAULT current_date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_customer_airline_person UNIQUE (airline_id, person_id)
);

CREATE TABLE loyalty_account (
    loyalty_account_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES customer(customer_id),
    loyalty_program_id uuid NOT NULL REFERENCES loyalty_program(loyalty_program_id),
    account_number varchar(40) NOT NULL,
    opened_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_loyalty_account_number UNIQUE (account_number),
    CONSTRAINT uq_loyalty_account_customer_program UNIQUE (customer_id, loyalty_program_id)
);

CREATE TABLE loyalty_account_tier (
    loyalty_account_tier_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    loyalty_account_id uuid NOT NULL REFERENCES loyalty_account(loyalty_account_id),
    loyalty_tier_id uuid NOT NULL REFERENCES loyalty_tier(loyalty_tier_id),
    assigned_at timestamptz NOT NULL,
    expires_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_loyalty_account_tier_point UNIQUE (loyalty_account_id, assigned_at),
    CONSTRAINT ck_loyalty_account_tier_dates CHECK (expires_at IS NULL OR expires_at > assigned_at)
);

CREATE TABLE miles_transaction (
    miles_transaction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    loyalty_account_id uuid NOT NULL REFERENCES loyalty_account(loyalty_account_id),
    transaction_type varchar(20) NOT NULL,
    miles_delta integer NOT NULL,
    occurred_at timestamptz NOT NULL,
    reference_code varchar(60),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_miles_transaction_type CHECK (transaction_type IN ('EARN', 'REDEEM', 'ADJUST')),
    CONSTRAINT ck_miles_delta_non_zero CHECK (miles_delta <> 0)
);

CREATE TABLE customer_benefit (
    customer_benefit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES customer(customer_id),
    benefit_type_id uuid NOT NULL REFERENCES benefit_type(benefit_type_id),
    granted_at timestamptz NOT NULL,
    expires_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_customer_benefit UNIQUE (customer_id, benefit_type_id, granted_at),
    CONSTRAINT ck_customer_benefit_dates CHECK (expires_at IS NULL OR expires_at > granted_at)
);

-- ============================================
-- AIRPORT
-- ============================================

CREATE TABLE airport (
    airport_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    address_id uuid NOT NULL REFERENCES address(address_id),
    airport_name varchar(150) NOT NULL,
    iata_code varchar(3),
    icao_code varchar(4),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_airport_iata UNIQUE (iata_code),
    CONSTRAINT uq_airport_icao UNIQUE (icao_code),
    CONSTRAINT ck_airport_iata_len CHECK (iata_code IS NULL OR char_length(iata_code) = 3),
    CONSTRAINT ck_airport_icao_len CHECK (icao_code IS NULL OR char_length(icao_code) = 4)
);

CREATE TABLE terminal (
    terminal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airport_id uuid NOT NULL REFERENCES airport(airport_id),
    terminal_code varchar(10) NOT NULL,
    terminal_name varchar(80),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_terminal_code UNIQUE (airport_id, terminal_code)
);

CREATE TABLE boarding_gate (
    boarding_gate_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    terminal_id uuid NOT NULL REFERENCES terminal(terminal_id),
    gate_code varchar(10) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_boarding_gate_code UNIQUE (terminal_id, gate_code)
);

CREATE TABLE runway (
    runway_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airport_id uuid NOT NULL REFERENCES airport(airport_id),
    runway_code varchar(20) NOT NULL,
    length_meters integer NOT NULL,
    surface_type varchar(30),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_runway_code UNIQUE (airport_id, runway_code),
    CONSTRAINT ck_runway_length CHECK (length_meters > 0)
);

CREATE TABLE airport_regulation (
    airport_regulation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airport_id uuid NOT NULL REFERENCES airport(airport_id),
    regulation_code varchar(30) NOT NULL,
    regulation_title varchar(150) NOT NULL,
    issuing_authority varchar(120) NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_airport_regulation UNIQUE (airport_id, regulation_code),
    CONSTRAINT ck_airport_regulation_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

-- ============================================
-- AIRCRAFT
-- ============================================

CREATE TABLE aircraft_manufacturer (
    aircraft_manufacturer_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    manufacturer_name varchar(120) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_aircraft_manufacturer_name UNIQUE (manufacturer_name)
);

CREATE TABLE aircraft_model (
    aircraft_model_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_manufacturer_id uuid NOT NULL REFERENCES aircraft_manufacturer(aircraft_manufacturer_id),
    model_code varchar(30) NOT NULL,
    model_name varchar(120) NOT NULL,
    max_range_km integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_aircraft_model_code UNIQUE (aircraft_manufacturer_id, model_code),
    CONSTRAINT uq_aircraft_model_name UNIQUE (aircraft_manufacturer_id, model_name),
    CONSTRAINT ck_aircraft_model_range CHECK (max_range_km IS NULL OR max_range_km > 0)
);

CREATE TABLE cabin_class (
    cabin_class_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_code varchar(10) NOT NULL,
    class_name varchar(60) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_cabin_class_code UNIQUE (class_code),
    CONSTRAINT uq_cabin_class_name UNIQUE (class_name)
);

CREATE TABLE aircraft (
    aircraft_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airline(airline_id),
    aircraft_model_id uuid NOT NULL REFERENCES aircraft_model(aircraft_model_id),
    registration_number varchar(20) NOT NULL,
    serial_number varchar(40) NOT NULL,
    in_service_on date,
    retired_on date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_aircraft_registration UNIQUE (registration_number),
    CONSTRAINT uq_aircraft_serial UNIQUE (serial_number),
    CONSTRAINT ck_aircraft_service_dates CHECK (retired_on IS NULL OR in_service_on IS NULL OR retired_on >= in_service_on)
);

CREATE TABLE aircraft_cabin (
    aircraft_cabin_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_id uuid NOT NULL REFERENCES aircraft(aircraft_id),
    cabin_class_id uuid NOT NULL REFERENCES cabin_class(cabin_class_id),
    cabin_code varchar(10) NOT NULL,
    deck_number smallint NOT NULL DEFAULT 1,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_aircraft_cabin_code UNIQUE (aircraft_id, cabin_code),
    CONSTRAINT ck_aircraft_cabin_deck CHECK (deck_number > 0)
);

CREATE TABLE aircraft_seat (
    aircraft_seat_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_cabin_id uuid NOT NULL REFERENCES aircraft_cabin(aircraft_cabin_id),
    seat_row_number integer NOT NULL,
    seat_column_code varchar(3) NOT NULL,
    is_window boolean NOT NULL DEFAULT false,
    is_aisle boolean NOT NULL DEFAULT false,
    is_exit_row boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_aircraft_seat_position UNIQUE (aircraft_cabin_id, seat_row_number, seat_column_code),
    CONSTRAINT ck_aircraft_seat_row CHECK (seat_row_number > 0)
);

CREATE TABLE maintenance_provider (
    maintenance_provider_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    address_id uuid REFERENCES address(address_id),
    provider_name varchar(150) NOT NULL,
    contact_name varchar(120),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_maintenance_provider_name UNIQUE (provider_name)
);

CREATE TABLE maintenance_type (
    maintenance_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type_code varchar(20) NOT NULL,
    type_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_maintenance_type_code UNIQUE (type_code),
    CONSTRAINT uq_maintenance_type_name UNIQUE (type_name)
);

CREATE TABLE maintenance_event (
    maintenance_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aircraft_id uuid NOT NULL REFERENCES aircraft(aircraft_id),
    maintenance_type_id uuid NOT NULL REFERENCES maintenance_type(maintenance_type_id),
    maintenance_provider_id uuid REFERENCES maintenance_provider(maintenance_provider_id),
    status_code varchar(20) NOT NULL,
    started_at timestamptz NOT NULL,
    completed_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_maintenance_event_status CHECK (status_code IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_maintenance_event_dates CHECK (completed_at IS NULL OR completed_at >= started_at)
);

-- ============================================
-- FLIGHT OPERATIONS
-- ============================================

CREATE TABLE flight_status (
    flight_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_flight_status_code UNIQUE (status_code),
    CONSTRAINT uq_flight_status_name UNIQUE (status_name)
);

CREATE TABLE delay_reason_type (
    delay_reason_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reason_code varchar(20) NOT NULL,
    reason_name varchar(100) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_delay_reason_code UNIQUE (reason_code),
    CONSTRAINT uq_delay_reason_name UNIQUE (reason_name)
);

CREATE TABLE flight (
    flight_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airline(airline_id),
    aircraft_id uuid NOT NULL REFERENCES aircraft(aircraft_id),
    flight_status_id uuid NOT NULL REFERENCES flight_status(flight_status_id),
    flight_number varchar(12) NOT NULL,
    service_date date NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_flight_instance UNIQUE (airline_id, flight_number, service_date)
);

CREATE TABLE flight_segment (
    flight_segment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    flight_id uuid NOT NULL REFERENCES flight(flight_id),
    origin_airport_id uuid NOT NULL REFERENCES airport(airport_id),
    destination_airport_id uuid NOT NULL REFERENCES airport(airport_id),
    segment_number integer NOT NULL,
    scheduled_departure_at timestamptz NOT NULL,
    scheduled_arrival_at timestamptz NOT NULL,
    actual_departure_at timestamptz,
    actual_arrival_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_flight_segment_number UNIQUE (flight_id, segment_number),
    CONSTRAINT ck_flight_segment_airports CHECK (origin_airport_id <> destination_airport_id),
    CONSTRAINT ck_flight_segment_schedule CHECK (scheduled_arrival_at > scheduled_departure_at),
    CONSTRAINT ck_flight_segment_actuals CHECK (
        actual_arrival_at IS NULL
        OR actual_departure_at IS NULL
        OR actual_arrival_at >= actual_departure_at
    )
);

CREATE TABLE flight_delay (
    flight_delay_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    flight_segment_id uuid NOT NULL REFERENCES flight_segment(flight_segment_id),
    delay_reason_type_id uuid NOT NULL REFERENCES delay_reason_type(delay_reason_type_id),
    reported_at timestamptz NOT NULL,
    delay_minutes integer NOT NULL,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_flight_delay_minutes CHECK (delay_minutes > 0)
);

-- ============================================
-- SALES, RESERVATION, TICKETING
-- ============================================

CREATE TABLE reservation_status (
    reservation_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_reservation_status_code UNIQUE (status_code),
    CONSTRAINT uq_reservation_status_name UNIQUE (status_name)
);

CREATE TABLE sale_channel (
    sale_channel_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_code varchar(20) NOT NULL,
    channel_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_sale_channel_code UNIQUE (channel_code),
    CONSTRAINT uq_sale_channel_name UNIQUE (channel_name)
);

CREATE TABLE fare_class (
    fare_class_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cabin_class_id uuid NOT NULL REFERENCES cabin_class(cabin_class_id),
    fare_class_code varchar(10) NOT NULL,
    fare_class_name varchar(80) NOT NULL,
    is_refundable_by_default boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_fare_class_code UNIQUE (fare_class_code),
    CONSTRAINT uq_fare_class_name UNIQUE (fare_class_name)
);

CREATE TABLE fare (
    fare_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    airline_id uuid NOT NULL REFERENCES airline(airline_id),
    origin_airport_id uuid NOT NULL REFERENCES airport(airport_id),
    destination_airport_id uuid NOT NULL REFERENCES airport(airport_id),
    fare_class_id uuid NOT NULL REFERENCES fare_class(fare_class_id),
    currency_id uuid NOT NULL REFERENCES currency(currency_id),
    fare_code varchar(30) NOT NULL,
    base_amount numeric(12, 2) NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    baggage_allowance_qty integer NOT NULL DEFAULT 0,
    change_penalty_amount numeric(12, 2),
    refund_penalty_amount numeric(12, 2),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_fare_code UNIQUE (fare_code),
    CONSTRAINT ck_fare_airports CHECK (origin_airport_id <> destination_airport_id),
    CONSTRAINT ck_fare_base_amount CHECK (base_amount >= 0),
    CONSTRAINT ck_fare_baggage_allowance CHECK (baggage_allowance_qty >= 0),
    CONSTRAINT ck_fare_change_penalty CHECK (change_penalty_amount IS NULL OR change_penalty_amount >= 0),
    CONSTRAINT ck_fare_refund_penalty CHECK (refund_penalty_amount IS NULL OR refund_penalty_amount >= 0),
    CONSTRAINT ck_fare_validity CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE TABLE ticket_status (
    ticket_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_ticket_status_code UNIQUE (status_code),
    CONSTRAINT uq_ticket_status_name UNIQUE (status_name)
);

CREATE TABLE reservation (
    reservation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    booked_by_customer_id uuid REFERENCES customer(customer_id),
    reservation_status_id uuid NOT NULL REFERENCES reservation_status(reservation_status_id),
    sale_channel_id uuid NOT NULL REFERENCES sale_channel(sale_channel_id),
    reservation_code varchar(20) NOT NULL,
    booked_at timestamptz NOT NULL,
    expires_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_reservation_code UNIQUE (reservation_code),
    CONSTRAINT ck_reservation_dates CHECK (expires_at IS NULL OR expires_at > booked_at)
);

CREATE TABLE reservation_passenger (
    reservation_passenger_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id uuid NOT NULL REFERENCES reservation(reservation_id),
    person_id uuid NOT NULL REFERENCES person(person_id),
    passenger_sequence_no integer NOT NULL,
    passenger_type varchar(20) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_reservation_passenger_person UNIQUE (reservation_id, person_id),
    CONSTRAINT uq_reservation_passenger_sequence UNIQUE (reservation_id, passenger_sequence_no),
    CONSTRAINT ck_reservation_passenger_sequence CHECK (passenger_sequence_no > 0),
    CONSTRAINT ck_reservation_passenger_type CHECK (passenger_type IN ('ADULT', 'CHILD', 'INFANT'))
);

CREATE TABLE sale (
    sale_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id uuid NOT NULL REFERENCES reservation(reservation_id),
    currency_id uuid NOT NULL REFERENCES currency(currency_id),
    sale_code varchar(30) NOT NULL,
    sold_at timestamptz NOT NULL,
    external_reference varchar(50),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_sale_code UNIQUE (sale_code)
);

CREATE TABLE ticket (
    ticket_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES sale(sale_id),
    reservation_passenger_id uuid NOT NULL REFERENCES reservation_passenger(reservation_passenger_id),
    fare_id uuid NOT NULL REFERENCES fare(fare_id),
    ticket_status_id uuid NOT NULL REFERENCES ticket_status(ticket_status_id),
    ticket_number varchar(20) NOT NULL,
    issued_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_ticket_number UNIQUE (ticket_number)
);

CREATE TABLE ticket_segment (
    ticket_segment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id uuid NOT NULL REFERENCES ticket(ticket_id),
    flight_segment_id uuid NOT NULL REFERENCES flight_segment(flight_segment_id),
    segment_sequence_no integer NOT NULL,
    fare_basis_code varchar(20),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_ticket_segment_sequence UNIQUE (ticket_id, segment_sequence_no),
    CONSTRAINT uq_ticket_segment_flight UNIQUE (ticket_id, flight_segment_id),
    CONSTRAINT uq_ticket_segment_pair UNIQUE (ticket_segment_id, flight_segment_id),
    CONSTRAINT ck_ticket_segment_sequence CHECK (segment_sequence_no > 0)
);

CREATE TABLE seat_assignment (
    seat_assignment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_segment_id uuid NOT NULL,
    flight_segment_id uuid NOT NULL,
    aircraft_seat_id uuid NOT NULL REFERENCES aircraft_seat(aircraft_seat_id),
    assigned_at timestamptz NOT NULL,
    assignment_source varchar(20) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_seat_assignment_ticket_segment UNIQUE (ticket_segment_id),
    CONSTRAINT uq_seat_assignment_flight_seat UNIQUE (flight_segment_id, aircraft_seat_id),
    CONSTRAINT ck_seat_assignment_source CHECK (assignment_source IN ('AUTO', 'MANUAL', 'CUSTOMER')),
    CONSTRAINT fk_seat_assignment_ticket_segment FOREIGN KEY (ticket_segment_id, flight_segment_id)
        REFERENCES ticket_segment(ticket_segment_id, flight_segment_id)
);

CREATE TABLE baggage (
    baggage_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_segment_id uuid NOT NULL REFERENCES ticket_segment(ticket_segment_id),
    baggage_tag varchar(30) NOT NULL,
    baggage_type varchar(20) NOT NULL,
    baggage_status varchar(20) NOT NULL,
    weight_kg numeric(6, 2) NOT NULL,
    checked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_baggage_tag UNIQUE (baggage_tag),
    CONSTRAINT ck_baggage_type CHECK (baggage_type IN ('CHECKED', 'CARRY_ON', 'SPECIAL')),
    CONSTRAINT ck_baggage_status CHECK (baggage_status IN ('REGISTERED', 'LOADED', 'CLAIMED', 'LOST')),
    CONSTRAINT ck_baggage_weight CHECK (weight_kg > 0)
);

-- ============================================
-- BOARDING
-- ============================================

CREATE TABLE boarding_group (
    boarding_group_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_code varchar(10) NOT NULL,
    group_name varchar(50) NOT NULL,
    sequence_no integer NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_boarding_group_code UNIQUE (group_code),
    CONSTRAINT uq_boarding_group_name UNIQUE (group_name),
    CONSTRAINT ck_boarding_group_sequence CHECK (sequence_no > 0)
);

CREATE TABLE check_in_status (
    check_in_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_check_in_status_code UNIQUE (status_code),
    CONSTRAINT uq_check_in_status_name UNIQUE (status_name)
);

CREATE TABLE check_in (
    check_in_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_segment_id uuid NOT NULL REFERENCES ticket_segment(ticket_segment_id),
    check_in_status_id uuid NOT NULL REFERENCES check_in_status(check_in_status_id),
    boarding_group_id uuid REFERENCES boarding_group(boarding_group_id),
    checked_in_by_user_id uuid REFERENCES user_account(user_account_id),
    checked_in_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_check_in_ticket_segment UNIQUE (ticket_segment_id)
);

CREATE TABLE boarding_pass (
    boarding_pass_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    check_in_id uuid NOT NULL REFERENCES check_in(check_in_id),
    boarding_pass_code varchar(40) NOT NULL,
    barcode_value varchar(120) NOT NULL,
    issued_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_boarding_pass_check_in UNIQUE (check_in_id),
    CONSTRAINT uq_boarding_pass_code UNIQUE (boarding_pass_code),
    CONSTRAINT uq_boarding_pass_barcode UNIQUE (barcode_value)
);

CREATE TABLE boarding_validation (
    boarding_validation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    boarding_pass_id uuid NOT NULL REFERENCES boarding_pass(boarding_pass_id),
    boarding_gate_id uuid REFERENCES boarding_gate(boarding_gate_id),
    validated_by_user_id uuid REFERENCES user_account(user_account_id),
    validated_at timestamptz NOT NULL,
    validation_result varchar(20) NOT NULL,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_boarding_validation_result CHECK (validation_result IN ('APPROVED', 'REJECTED', 'MANUAL_REVIEW'))
);

-- ============================================
-- PAYMENT
-- ============================================

CREATE TABLE payment_status (
    payment_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_payment_status_code UNIQUE (status_code),
    CONSTRAINT uq_payment_status_name UNIQUE (status_name)
);

CREATE TABLE payment_method (
    payment_method_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    method_code varchar(20) NOT NULL,
    method_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_payment_method_code UNIQUE (method_code),
    CONSTRAINT uq_payment_method_name UNIQUE (method_name)
);

CREATE TABLE payment (
    payment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES sale(sale_id),
    payment_status_id uuid NOT NULL REFERENCES payment_status(payment_status_id),
    payment_method_id uuid NOT NULL REFERENCES payment_method(payment_method_id),
    currency_id uuid NOT NULL REFERENCES currency(currency_id),
    payment_reference varchar(40) NOT NULL,
    amount numeric(12, 2) NOT NULL,
    authorized_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_payment_reference UNIQUE (payment_reference),
    CONSTRAINT ck_payment_amount CHECK (amount > 0)
);

CREATE TABLE payment_transaction (
    payment_transaction_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id uuid NOT NULL REFERENCES payment(payment_id),
    transaction_reference varchar(60) NOT NULL,
    transaction_type varchar(20) NOT NULL,
    transaction_amount numeric(12, 2) NOT NULL,
    processed_at timestamptz NOT NULL,
    provider_message text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_payment_transaction_reference UNIQUE (transaction_reference),
    CONSTRAINT ck_payment_transaction_type CHECK (transaction_type IN ('AUTH', 'CAPTURE', 'VOID', 'REFUND', 'REVERSAL')),
    CONSTRAINT ck_payment_transaction_amount CHECK (transaction_amount > 0)
);

CREATE TABLE refund (
    refund_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id uuid NOT NULL REFERENCES payment(payment_id),
    refund_reference varchar(40) NOT NULL,
    amount numeric(12, 2) NOT NULL,
    requested_at timestamptz NOT NULL,
    processed_at timestamptz,
    refund_reason text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_refund_reference UNIQUE (refund_reference),
    CONSTRAINT ck_refund_amount CHECK (amount > 0),
    CONSTRAINT ck_refund_dates CHECK (processed_at IS NULL OR processed_at >= requested_at)
);

-- ============================================
-- BILLING
-- ============================================

CREATE TABLE tax (
    tax_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_code varchar(20) NOT NULL,
    tax_name varchar(100) NOT NULL,
    rate_percentage numeric(6, 3) NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_tax_code UNIQUE (tax_code),
    CONSTRAINT uq_tax_name UNIQUE (tax_name),
    CONSTRAINT ck_tax_rate CHECK (rate_percentage >= 0),
    CONSTRAINT ck_tax_dates CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE TABLE exchange_rate (
    exchange_rate_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    from_currency_id uuid NOT NULL REFERENCES currency(currency_id),
    to_currency_id uuid NOT NULL REFERENCES currency(currency_id),
    effective_date date NOT NULL,
    rate_value numeric(18, 8) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_exchange_rate UNIQUE (from_currency_id, to_currency_id, effective_date),
    CONSTRAINT ck_exchange_rate_pair CHECK (from_currency_id <> to_currency_id),
    CONSTRAINT ck_exchange_rate_value CHECK (rate_value > 0)
);

CREATE TABLE invoice_status (
    invoice_status_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    status_code varchar(20) NOT NULL,
    status_name varchar(80) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_invoice_status_code UNIQUE (status_code),
    CONSTRAINT uq_invoice_status_name UNIQUE (status_name)
);

CREATE TABLE invoice (
    invoice_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES sale(sale_id),
    invoice_status_id uuid NOT NULL REFERENCES invoice_status(invoice_status_id),
    currency_id uuid NOT NULL REFERENCES currency(currency_id),
    invoice_number varchar(40) NOT NULL,
    issued_at timestamptz NOT NULL,
    due_at timestamptz,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),
    CONSTRAINT ck_invoice_dates CHECK (due_at IS NULL OR due_at >= issued_at)
);

CREATE TABLE invoice_line (
    invoice_line_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES invoice(invoice_id),
    tax_id uuid REFERENCES tax(tax_id),
    line_number integer NOT NULL,
    line_description varchar(200) NOT NULL,
    quantity numeric(12, 2) NOT NULL,
    unit_price numeric(12, 2) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_invoice_line_number UNIQUE (invoice_id, line_number),
    CONSTRAINT ck_invoice_line_number CHECK (line_number > 0),
    CONSTRAINT ck_invoice_line_quantity CHECK (quantity > 0),
    CONSTRAINT ck_invoice_line_unit_price CHECK (unit_price >= 0)
);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE reservation IS 'Entidad raiz del flujo comercial y de booking del sistema.';
COMMENT ON TABLE ticket_segment IS 'Tabla puente entre ticket y segmentos de vuelo para soportar itinerarios con escalas.';
COMMENT ON TABLE seat_assignment IS 'Asignacion de asiento normalizada por ticket_segment con control de unicidad por segmento y asiento.';
COMMENT ON TABLE loyalty_account_tier IS 'Historial de asignacion de nivel para evitar dependencia transitiva en loyalty_account.';
COMMENT ON TABLE invoice_line IS 'Detalle facturable sin totales derivados persistidos, para preservar 3FN.';

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_country_continent_id ON country(continent_id);
CREATE INDEX idx_state_country_id ON state_province(country_id);
CREATE INDEX idx_city_state_id ON city(state_province_id);
CREATE INDEX idx_district_city_id ON district(city_id);
CREATE INDEX idx_address_district_id ON address(district_id);

CREATE INDEX idx_person_person_type_id ON person(person_type_id);
CREATE INDEX idx_person_nationality_country_id ON person(nationality_country_id);
CREATE INDEX idx_person_document_person_id ON person_document(person_id);
CREATE INDEX idx_person_document_number ON person_document(document_number);
CREATE INDEX idx_person_contact_person_id ON person_contact(person_id);
CREATE INDEX idx_person_contact_value ON person_contact(contact_value);

CREATE INDEX idx_user_account_status_id ON user_account(user_status_id);
CREATE INDEX idx_user_role_user_account_id ON user_role(user_account_id);
CREATE INDEX idx_user_role_role_id ON user_role(security_role_id);
CREATE INDEX idx_role_permission_role_id ON role_permission(security_role_id);
CREATE INDEX idx_role_permission_permission_id ON role_permission(security_permission_id);

CREATE INDEX idx_customer_person_id ON customer(person_id);
CREATE INDEX idx_loyalty_program_airline_id ON loyalty_program(airline_id);
CREATE INDEX idx_loyalty_account_customer_id ON loyalty_account(customer_id);
CREATE INDEX idx_loyalty_account_tier_account_id ON loyalty_account_tier(loyalty_account_id);
CREATE INDEX idx_miles_transaction_account_id ON miles_transaction(loyalty_account_id);

CREATE INDEX idx_airport_address_id ON airport(address_id);
CREATE INDEX idx_terminal_airport_id ON terminal(airport_id);
CREATE INDEX idx_boarding_gate_terminal_id ON boarding_gate(terminal_id);
CREATE INDEX idx_runway_airport_id ON runway(airport_id);

CREATE INDEX idx_aircraft_airline_id ON aircraft(airline_id);
CREATE INDEX idx_aircraft_model_id ON aircraft(aircraft_model_id);
CREATE INDEX idx_aircraft_cabin_aircraft_id ON aircraft_cabin(aircraft_id);
CREATE INDEX idx_aircraft_seat_cabin_id ON aircraft_seat(aircraft_cabin_id);
CREATE INDEX idx_maintenance_event_aircraft_id ON maintenance_event(aircraft_id);

CREATE INDEX idx_flight_aircraft_id ON flight(aircraft_id);
CREATE INDEX idx_flight_service_date ON flight(service_date);
CREATE INDEX idx_flight_segment_flight_id ON flight_segment(flight_id);
CREATE INDEX idx_flight_segment_origin_airport_id ON flight_segment(origin_airport_id);
CREATE INDEX idx_flight_segment_destination_airport_id ON flight_segment(destination_airport_id);
CREATE INDEX idx_flight_delay_segment_id ON flight_delay(flight_segment_id);

CREATE INDEX idx_fare_class_cabin_class_id ON fare_class(cabin_class_id);
CREATE INDEX idx_fare_airline_id ON fare(airline_id);
CREATE INDEX idx_reservation_status_id ON reservation(reservation_status_id);
CREATE INDEX idx_reservation_booked_by_customer_id ON reservation(booked_by_customer_id);
CREATE INDEX idx_reservation_passenger_person_id ON reservation_passenger(person_id);
CREATE INDEX idx_sale_reservation_id ON sale(reservation_id);
CREATE INDEX idx_ticket_sale_id ON ticket(sale_id);
CREATE INDEX idx_ticket_reservation_passenger_id ON ticket(reservation_passenger_id);
CREATE INDEX idx_ticket_segment_ticket_id ON ticket_segment(ticket_id);
CREATE INDEX idx_ticket_segment_flight_segment_id ON ticket_segment(flight_segment_id);
CREATE INDEX idx_seat_assignment_aircraft_seat_id ON seat_assignment(aircraft_seat_id);
CREATE INDEX idx_baggage_ticket_segment_id ON baggage(ticket_segment_id);

CREATE INDEX idx_check_in_status_id ON check_in(check_in_status_id);
CREATE INDEX idx_boarding_pass_check_in_id ON boarding_pass(check_in_id);
CREATE INDEX idx_boarding_validation_boarding_pass_id ON boarding_validation(boarding_pass_id);

CREATE INDEX idx_payment_sale_id ON payment(sale_id);
CREATE INDEX idx_payment_status_id ON payment(payment_status_id);
CREATE INDEX idx_payment_transaction_payment_id ON payment_transaction(payment_id);
CREATE INDEX idx_refund_payment_id ON refund(payment_id);

CREATE INDEX idx_exchange_rate_from_to_date ON exchange_rate(from_currency_id, to_currency_id, effective_date);
CREATE INDEX idx_invoice_sale_id ON invoice(sale_id);
CREATE INDEX idx_invoice_status_id ON invoice(invoice_status_id);
CREATE INDEX idx_invoice_line_invoice_id ON invoice_line(invoice_id);


-- ============================================================
-- SOLUCIÓN COMPLETA - EJERCICIOS 01 AL 10  (versión 2 - corregida)
-- Sistema de Aerolínea - PostgreSQL
-- Correcciones: continent_code max 3 chars, CALL dentro del DO $$
-- ============================================================
 
 
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
 
 
-- ============================================================
-- EJERCICIO 03
-- Facturación e integración entre venta, impuestos y detalle facturable
-- ============================================================
 
-- -------------------------------------------------------
-- REQUERIMIENTO 1: Consulta INNER JOIN (mínimo 5 tablas)
-- -------------------------------------------------------
SELECT
    s.sale_code          AS codigo_venta,
    i.invoice_number     AS numero_factura,
    ist.status_name      AS estado_factura,
    il.line_number       AS linea,
    il.line_description  AS descripcion_linea,
    il.quantity          AS cantidad,
    il.unit_price        AS precio_unitario,
    tx.tax_name          AS impuesto_aplicado,
    tx.rate_percentage   AS porcentaje_impuesto,
    c.iso_currency_code  AS moneda
FROM sale s
INNER JOIN invoice i         ON i.sale_id = s.sale_id
INNER JOIN invoice_status ist ON ist.invoice_status_id = i.invoice_status_id
INNER JOIN invoice_line il   ON il.invoice_id = i.invoice_id
INNER JOIN tax tx             ON tx.tax_id = il.tax_id
INNER JOIN currency c        ON c.currency_id = i.currency_id
ORDER BY s.sale_code, i.invoice_number, il.line_number;
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 2: Trigger AFTER INSERT sobre invoice_line
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_actualizar_factura_tras_linea()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE invoice SET updated_at = NOW() WHERE invoice_id = NEW.invoice_id;
    RETURN NEW;
END;
$$;
 
CREATE OR REPLACE TRIGGER trg_after_invoice_line_insert
AFTER INSERT ON invoice_line
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_factura_tras_linea();
 
 
-- -------------------------------------------------------
-- REQUERIMIENTO 3: Procedimiento almacenado
-- -------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_agregar_linea_factura(
    p_invoice_id  UUID,
    p_tax_id      UUID,
    p_line_number INTEGER,
    p_description VARCHAR(200),
    p_quantity    NUMERIC(12,2),
    p_unit_price  NUMERIC(12,2)
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO invoice_line (invoice_id, tax_id, line_number, line_description,
        quantity, unit_price, created_at, updated_at)
    VALUES (p_invoice_id, p_tax_id, p_line_number, p_description,
        p_quantity, p_unit_price, NOW(), NOW());
END;
$$;
 
 
-- -------------------------------------------------------
-- SCRIPT DE PRUEBA + INVOCACIÓN - EJERCICIO 03
-- -------------------------------------------------------
DO $$
DECLARE
    v_tz_id      UUID; v_cont_id    UUID; v_country_id  UUID;
    v_state_id   UUID; v_city_id    UUID; v_dist_id     UUID;
    v_addr_id    UUID; v_curr_id    UUID; v_airline_id  UUID;
    v_ptype_id   UUID; v_person_id  UUID;
    v_rstatus_id UUID; v_schan_id   UUID; v_res_id      UUID;
    v_sale_id    UUID; v_istatus_id UUID; v_inv_id      UUID;
    v_tax_id     UUID;
BEGIN
    INSERT INTO time_zone (time_zone_name, utc_offset_minutes)
        VALUES ('America/Caracas', -270) RETURNING time_zone_id INTO v_tz_id;
    INSERT INTO continent (continent_code, continent_name)
        VALUES ('S03', 'South America 03') RETURNING continent_id INTO v_cont_id;
    INSERT INTO country (continent_id, iso_alpha2, iso_alpha3, country_name)
        VALUES (v_cont_id, 'VE', 'VEN', 'Venezuela') RETURNING country_id INTO v_country_id;
    INSERT INTO state_province (country_id, state_code, state_name)
        VALUES (v_country_id, 'DC', 'Distrito Capital') RETURNING state_province_id INTO v_state_id;
    INSERT INTO city (state_province_id, time_zone_id, city_name)
        VALUES (v_state_id, v_tz_id, 'Caracas') RETURNING city_id INTO v_city_id;
    INSERT INTO district (city_id, district_name)
        VALUES (v_city_id, 'Chacao') RETURNING district_id INTO v_dist_id;
    INSERT INTO address (district_id, address_line_1)
        VALUES (v_dist_id, 'Av. Miranda 1') RETURNING address_id INTO v_addr_id;
    INSERT INTO currency (iso_currency_code, currency_name, currency_symbol)
        VALUES ('EUR', 'Euro', '€') RETURNING currency_id INTO v_curr_id;
    INSERT INTO airline (home_country_id, airline_code, airline_name, iata_code, icao_code)
        VALUES (v_country_id, 'BQ', 'Conviasa', 'V0', 'VCV') RETURNING airline_id INTO v_airline_id;
    INSERT INTO person_type (type_code, type_name)
        VALUES ('EMP', 'Empleado') RETURNING person_type_id INTO v_ptype_id;
    INSERT INTO person (person_type_id, first_name, last_name)
        VALUES (v_ptype_id, 'Carlos', 'Rodríguez') RETURNING person_id INTO v_person_id;
    INSERT INTO reservation_status (status_code, status_name)
        VALUES ('INVOICED', 'Facturada') RETURNING reservation_status_id INTO v_rstatus_id;
    INSERT INTO sale_channel (channel_code, channel_name)
        VALUES ('AGE', 'Agencia de Viajes') RETURNING sale_channel_id INTO v_schan_id;
    INSERT INTO reservation (reservation_status_id, sale_channel_id, reservation_code, booked_at)
        VALUES (v_rstatus_id, v_schan_id, 'RES-EJ03-001', NOW()) RETURNING reservation_id INTO v_res_id;
    INSERT INTO sale (reservation_id, currency_id, sale_code, sold_at)
        VALUES (v_res_id, v_curr_id, 'SALE-EJ03-001', NOW()) RETURNING sale_id INTO v_sale_id;
    INSERT INTO invoice_status (status_code, status_name)
        VALUES ('ISSUED', 'Emitida') RETURNING invoice_status_id INTO v_istatus_id;
    INSERT INTO invoice (sale_id, invoice_status_id, currency_id, invoice_number, issued_at)
        VALUES (v_sale_id, v_istatus_id, v_curr_id, 'FAC-EJ03-0001', NOW()) RETURNING invoice_id INTO v_inv_id;
    INSERT INTO tax (tax_code, tax_name, rate_percentage, effective_from)
        VALUES ('IVA16', 'IVA 16%', 16.000, CURRENT_DATE) RETURNING tax_id INTO v_tax_id;
 
    -- Invocar procedimiento → activa trigger que actualiza invoice.updated_at
    CALL sp_agregar_linea_factura(v_inv_id, v_tax_id, 1, 'Tiquete BOG-MDE clase económica', 1, 500.00);
 
    RAISE NOTICE '[EJ03] Línea facturable registrada en factura: %', v_inv_id;
END;
$$;
 
-- Validación ejercicio 03
SELECT i.invoice_number, i.issued_at, i.updated_at, COUNT(il.invoice_line_id) AS total_lineas
FROM invoice i
LEFT JOIN invoice_line il ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.invoice_number, i.issued_at, i.updated_at
ORDER BY i.updated_at DESC LIMIT 5;
 
 
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
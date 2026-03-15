--
-- PostgreSQL database dump
--

\restrict jgvVY3vgCRw9csDZMO5BD8Ns2bm0rBCYrmbBsrihElKe91EWLEKlKDiG2PlO50j

-- Dumped from database version 15.16 (Debian 15.16-0+deb12u1)
-- Dumped by pg_dump version 15.16 (Debian 15.16-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: activitylogaction; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activitylogaction AS ENUM (
    'ORDER_CREATED',
    'ORDER_DISPATCHED',
    'ORDER_RECEIVED',
    'ORDER_COMPLETED',
    'ORDER_CANCELLED',
    'RETURN_CREATED',
    'RETURN_DISPATCHED',
    'RETURN_RECEIVED',
    'BILLING_GENERATED',
    'PAYMENT_RECORDED',
    'BILLING_ADJUSTED',
    'USER_CREATED',
    'USER_UPDATED',
    'DEPARTMENT_CREATED',
    'DEPARTMENT_UPDATED',
    'ITEM_CREATED',
    'ITEM_UPDATED',
    'VENDOR_CREATED',
    'VENDOR_UPDATED',
    'ASSET_CREATED',
    'ASSET_UPDATED',
    'PATIENT_CREATED',
    'PATIENT_UPDATED',
    'IPD_CREATED',
    'IPD_UPDATED',
    'USER_LOGIN',
    'USER_LOGOUT',
    'PASSWORD_CHANGED',
    'SIMULATION_RUN',
    'BACKUP_CREATED',
    'DATA_SEEDED'
);


--
-- Name: activitylogentitytype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activitylogentitytype AS ENUM (
    'ORDER',
    'BILLING',
    'PAYMENT',
    'USER',
    'DEPARTMENT',
    'ITEM',
    'VENDOR',
    'ASSET',
    'PATIENT',
    'IPD',
    'SYSTEM'
);


--
-- Name: assetstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.assetstatus AS ENUM (
    'AVAILABLE',
    'IN_USE',
    'MAINTENANCE',
    'RETIRED'
);


--
-- Name: attendancestatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.attendancestatus AS ENUM (
    'PRESENT',
    'ABSENT',
    'HALF_DAY',
    'LEAVE',
    'HOLIDAY'
);


--
-- Name: billingadjustmenttype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.billingadjustmenttype AS ENUM (
    'RETURN_CREDIT',
    'RETURN_DEDUCTION',
    'MANUAL_ADJUSTMENT'
);


--
-- Name: billingstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.billingstatus AS ENUM (
    'PENDING',
    'GENERATED',
    'PARTIAL',
    'PAID',
    'CANCELLED'
);


--
-- Name: ipdstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ipdstatus AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


--
-- Name: ipdstatusallowed; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ipdstatusallowed AS ENUM (
    'ACTIVE_ONLY',
    'INACTIVE_ONLY',
    'BOTH'
);


--
-- Name: orderitemstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.orderitemstatus AS ENUM (
    'PENDING_DISPATCH',
    'PARTIALLY_DISPATCHED',
    'FULLY_DISPATCHED',
    'RECEIVED',
    'CANCELLED'
);


--
-- Name: orderpriority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.orderpriority AS ENUM (
    'NORMAL',
    'URGENT'
);


--
-- Name: orderstatus; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.orderstatus AS ENUM (
    'CREATED',
    'PARTIALLY_DISPATCHED',
    'FULLY_DISPATCHED',
    'COMPLETED',
    'CANCELLED'
);


--
-- Name: ordertype; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ordertype AS ENUM (
    'REGULAR',
    'RETURN'
);


--
-- Name: patientipdrequirement; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.patientipdrequirement AS ENUM (
    'MANDATORY',
    'NON_MANDATORY'
);


--
-- Name: patientworkflowphase; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.patientworkflowphase AS ENUM (
    'PRE_ADMISSION',
    'ADMISSION',
    'IPD',
    'DISCHARGE',
    'POST_DISCHARGE',
    'ARCHIVED'
);


--
-- Name: paymentmode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.paymentmode AS ENUM (
    'CASH',
    'CARD',
    'UPI',
    'INSURANCE',
    'OTHER'
);


--
-- Name: priorityrequirement; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.priorityrequirement AS ENUM (
    'MANDATORY',
    'NON_MANDATORY'
);


--
-- Name: systemloglevel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.systemloglevel AS ENUM (
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
    'CRITICAL'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now(),
    user_id integer,
    action_type public.activitylogaction NOT NULL,
    entity_type public.activitylogentitytype NOT NULL,
    entity_id integer,
    entity_identifier character varying(100),
    details json,
    ip_address character varying(45)
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: asset_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_assignments (
    id integer NOT NULL,
    asset_id integer NOT NULL,
    assigned_to_user_id integer,
    assigned_to_department_id integer,
    assigned_at timestamp with time zone DEFAULT now(),
    assigned_by integer,
    returned_at timestamp with time zone,
    returned_by integer,
    notes text
);


--
-- Name: asset_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_assignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_assignments_id_seq OWNED BY public.asset_assignments.id;


--
-- Name: asset_maintenance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_maintenance (
    id integer NOT NULL,
    asset_id integer NOT NULL,
    maintenance_type character varying(50),
    description text,
    cost numeric(12,2),
    performed_by character varying(100),
    performed_at date,
    next_maintenance_date date,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer
);


--
-- Name: asset_maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_maintenance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_maintenance_id_seq OWNED BY public.asset_maintenance.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id integer NOT NULL,
    asset_code character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    category character varying(100),
    current_department_id integer,
    location_details character varying(200),
    purchase_date date,
    purchase_price numeric(12,2),
    vendor_id integer,
    warranty_expiry date,
    status public.assetstatus,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance (
    id integer NOT NULL,
    user_id integer NOT NULL,
    date date NOT NULL,
    status public.attendancestatus,
    shift_id integer,
    check_in_time timestamp with time zone,
    check_out_time timestamp with time zone,
    biometric_check_in timestamp with time zone,
    biometric_check_out timestamp with time zone,
    total_hours numeric(4,2),
    overtime_hours numeric(4,2),
    leave_type_id integer,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


--
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_id_seq OWNED BY public.attendance.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    table_name character varying(100) NOT NULL,
    record_id integer NOT NULL,
    action character varying(20) NOT NULL,
    old_values json,
    new_values json,
    user_id integer,
    "timestamp" timestamp with time zone DEFAULT now(),
    ip_address character varying(45)
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: billing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing (
    id integer NOT NULL,
    billing_number character varying(30) NOT NULL,
    order_id integer NOT NULL,
    patient_id integer NOT NULL,
    ipd_id integer,
    order_creator_id integer NOT NULL,
    ordering_department_id integer NOT NULL,
    dispatching_department_id integer NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    status public.billingstatus,
    paid_amount numeric(12,2),
    payment_date timestamp with time zone,
    payment_reference character varying(100),
    generated_at timestamp with time zone DEFAULT now(),
    generated_by integer
);


--
-- Name: billing_adjustment_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_adjustment_items (
    id integer NOT NULL,
    adjustment_id integer NOT NULL,
    original_billing_item_id integer,
    item_id integer NOT NULL,
    item_name character varying(200) NOT NULL,
    item_code character varying(50) NOT NULL,
    unit character varying(50) NOT NULL,
    cost_per_unit numeric(12,2) NOT NULL,
    quantity_returned integer NOT NULL,
    line_amount numeric(12,2) NOT NULL
);


--
-- Name: billing_adjustment_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_adjustment_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_adjustment_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_adjustment_items_id_seq OWNED BY public.billing_adjustment_items.id;


--
-- Name: billing_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_adjustments (
    id integer NOT NULL,
    adjustment_number character varying(30) NOT NULL,
    original_billing_id integer NOT NULL,
    return_order_id integer,
    adjustment_type public.billingadjustmenttype NOT NULL,
    adjustment_amount numeric(12,2) NOT NULL,
    reason text,
    is_credit boolean,
    credit_utilized numeric(12,2),
    created_at timestamp with time zone DEFAULT now(),
    created_by integer
);


--
-- Name: billing_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_adjustments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_adjustments_id_seq OWNED BY public.billing_adjustments.id;


--
-- Name: billing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_id_seq OWNED BY public.billing.id;


--
-- Name: billing_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_items (
    id integer NOT NULL,
    billing_id integer NOT NULL,
    order_item_id integer NOT NULL,
    item_id integer NOT NULL,
    item_name character varying(200) NOT NULL,
    item_code character varying(50) NOT NULL,
    unit character varying(50) NOT NULL,
    cost_per_unit numeric(12,2) NOT NULL,
    quantity_dispatched integer NOT NULL,
    line_amount numeric(12,2) NOT NULL
);


--
-- Name: billing_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.billing_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.billing_items_id_seq OWNED BY public.billing_items.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(20) NOT NULL,
    description text,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: dispatch_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch_events (
    id integer NOT NULL,
    order_item_id integer NOT NULL,
    quantity_dispatched integer NOT NULL,
    dispatched_by integer NOT NULL,
    dispatched_at timestamp with time zone DEFAULT now(),
    dispatch_notes text,
    quantity_received integer,
    received_by integer,
    received_at timestamp with time zone,
    receipt_notes text,
    batch_number character varying(50),
    expiry_date date
);


--
-- Name: dispatch_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dispatch_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dispatch_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dispatch_events_id_seq OWNED BY public.dispatch_events.id;


--
-- Name: ipd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ipd (
    id integer NOT NULL,
    ipd_number character varying(20) NOT NULL,
    patient_id integer NOT NULL,
    status public.ipdstatus,
    current_phase public.patientworkflowphase,
    admission_date timestamp with time zone,
    discharge_date timestamp with time zone,
    admitting_department_id integer,
    current_department_id integer,
    bed_number character varying(20),
    primary_diagnosis text,
    attending_doctor_id integer,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: ipd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ipd_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ipd_id_seq OWNED BY public.ipd.id;


--
-- Name: ipd_phase_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ipd_phase_log (
    id integer NOT NULL,
    ipd_id integer NOT NULL,
    from_phase public.patientworkflowphase,
    to_phase public.patientworkflowphase NOT NULL,
    changed_at timestamp with time zone DEFAULT now(),
    changed_by integer,
    notes text
);


--
-- Name: ipd_phase_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ipd_phase_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipd_phase_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ipd_phase_log_id_seq OWNED BY public.ipd_phase_log.id;


--
-- Name: item_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: item_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_categories_id_seq OWNED BY public.item_categories.id;


--
-- Name: item_ordering_departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_ordering_departments (
    id integer NOT NULL,
    item_id integer NOT NULL,
    department_id integer NOT NULL
);


--
-- Name: item_ordering_departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_ordering_departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_ordering_departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_ordering_departments_id_seq OWNED BY public.item_ordering_departments.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    category_id integer,
    unit character varying(50) NOT NULL,
    dispatching_department_id integer NOT NULL,
    vendor_id integer,
    all_departments_allowed boolean,
    workflow_phase public.patientworkflowphase,
    priority_requirement public.priorityrequirement,
    patient_ipd_requirement public.patientipdrequirement,
    ipd_status_allowed public.ipdstatusallowed,
    cost_per_unit numeric(12,2),
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: leave_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    code character varying(10) NOT NULL,
    is_paid boolean,
    max_days_per_year integer,
    is_active boolean
);


--
-- Name: leave_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leave_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leave_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leave_types_id_seq OWNED BY public.leave_types.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    user_id integer,
    phone character varying(15),
    channel character varying(20) NOT NULL,
    template_code character varying(50),
    message text NOT NULL,
    status character varying(20),
    sent_at timestamp with time zone,
    error_message text,
    reference_type character varying(50),
    reference_id integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    item_id integer NOT NULL,
    original_order_item_id integer,
    quantity_requested integer NOT NULL,
    quantity_dispatched integer,
    quantity_received integer,
    return_reason text,
    dispatching_department_id integer NOT NULL,
    status public.orderitemstatus,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    order_number character varying(30) NOT NULL,
    order_type public.ordertype,
    original_order_id integer,
    return_reason text,
    patient_id integer,
    ipd_id integer,
    ordering_department_id integer NOT NULL,
    priority public.orderpriority,
    status public.orderstatus,
    notes text,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    completed_by integer,
    completed_at timestamp with time zone,
    cancelled_by integer,
    cancelled_at timestamp with time zone,
    cancellation_reason text
);


--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
    id integer NOT NULL,
    uhid character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    date_of_birth date,
    gender character varying(10),
    phone character varying(15),
    email character varying(100),
    address text,
    emergency_contact_name character varying(100),
    emergency_contact_phone character varying(15),
    blood_group character varying(5),
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patients_id_seq OWNED BY public.patients.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    payment_number character varying(30) NOT NULL,
    billing_id integer NOT NULL,
    amount numeric(12,2) NOT NULL,
    payment_mode public.paymentmode NOT NULL,
    payment_date timestamp with time zone DEFAULT now(),
    payment_reference character varying(100),
    notes text,
    recorded_by integer NOT NULL,
    recorded_at timestamp with time zone DEFAULT now()
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: payroll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll (
    id integer NOT NULL,
    payroll_run_id integer NOT NULL,
    user_id integer NOT NULL,
    total_working_days integer,
    days_present numeric(4,1),
    days_absent numeric(4,1),
    leave_days numeric(4,1),
    overtime_hours numeric(6,2),
    basic_salary numeric(12,2),
    gross_earnings numeric(12,2),
    total_deductions numeric(12,2),
    net_salary numeric(12,2),
    payment_status character varying(20),
    payment_date date,
    payment_reference character varying(100),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: payroll_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payroll_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payroll_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payroll_id_seq OWNED BY public.payroll.id;


--
-- Name: payroll_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_runs (
    id integer NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    status character varying(20),
    processed_at timestamp with time zone,
    processed_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: payroll_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payroll_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payroll_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payroll_runs_id_seq OWNED BY public.payroll_runs.id;


--
-- Name: return_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.return_reasons (
    id integer NOT NULL,
    reason character varying(200) NOT NULL,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: return_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.return_reasons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: return_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.return_reasons_id_seq OWNED BY public.return_reasons.id;


--
-- Name: salary_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.salary_components (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(20) NOT NULL,
    component_type character varying(20) NOT NULL,
    is_taxable boolean,
    is_active boolean
);


--
-- Name: salary_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.salary_components_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: salary_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.salary_components_id_seq OWNED BY public.salary_components.id;


--
-- Name: shifts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shifts (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_active boolean
);


--
-- Name: shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shifts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shifts_id_seq OWNED BY public.shifts.id;


--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_logs (
    id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now(),
    level public.systemloglevel,
    user_id integer,
    endpoint character varying(255),
    method character varying(10),
    error_type character varying(100),
    error_message text,
    stack_trace text,
    request_body text,
    response_status integer,
    ip_address character varying(45),
    user_agent character varying(500),
    duration_ms integer
);


--
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_logs_id_seq OWNED BY public.system_logs.id;


--
-- Name: user_salary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_salary (
    id integer NOT NULL,
    user_id integer NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    basic_salary numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer
);


--
-- Name: user_salary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_salary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_salary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_salary_id_seq OWNED BY public.user_salary.id;


--
-- Name: user_secondary_departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_secondary_departments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    department_id integer NOT NULL
);


--
-- Name: user_secondary_departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_secondary_departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_secondary_departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_secondary_departments_id_seq OWNED BY public.user_secondary_departments.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token_hash character varying(255) NOT NULL,
    device_info text,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone NOT NULL,
    is_active boolean
);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    phone character varying(15) NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100),
    password_hash character varying(255) NOT NULL,
    primary_department_id integer NOT NULL,
    is_admin boolean,
    can_view_costs boolean,
    can_reactivate_ipd boolean,
    is_active boolean,
    employee_code character varying(50),
    designation character varying(100),
    date_of_joining date,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer,
    last_login_at timestamp with time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendors (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    code character varying(50) NOT NULL,
    contact_person character varying(100),
    phone character varying(15),
    email character varying(100),
    address text,
    gst_number character varying(20),
    pan_number character varying(20),
    bank_account_number character varying(30),
    bank_ifsc character varying(15),
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    updated_at timestamp with time zone,
    updated_by integer
);


--
-- Name: vendors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendors_id_seq OWNED BY public.vendors.id;


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: asset_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments ALTER COLUMN id SET DEFAULT nextval('public.asset_assignments_id_seq'::regclass);


--
-- Name: asset_maintenance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_maintenance ALTER COLUMN id SET DEFAULT nextval('public.asset_maintenance_id_seq'::regclass);


--
-- Name: assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: attendance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance ALTER COLUMN id SET DEFAULT nextval('public.attendance_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: billing id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing ALTER COLUMN id SET DEFAULT nextval('public.billing_id_seq'::regclass);


--
-- Name: billing_adjustment_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustment_items ALTER COLUMN id SET DEFAULT nextval('public.billing_adjustment_items_id_seq'::regclass);


--
-- Name: billing_adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments ALTER COLUMN id SET DEFAULT nextval('public.billing_adjustments_id_seq'::regclass);


--
-- Name: billing_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_items ALTER COLUMN id SET DEFAULT nextval('public.billing_items_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: dispatch_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_events ALTER COLUMN id SET DEFAULT nextval('public.dispatch_events_id_seq'::regclass);


--
-- Name: ipd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd ALTER COLUMN id SET DEFAULT nextval('public.ipd_id_seq'::regclass);


--
-- Name: ipd_phase_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd_phase_log ALTER COLUMN id SET DEFAULT nextval('public.ipd_phase_log_id_seq'::regclass);


--
-- Name: item_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_categories ALTER COLUMN id SET DEFAULT nextval('public.item_categories_id_seq'::regclass);


--
-- Name: item_ordering_departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_ordering_departments ALTER COLUMN id SET DEFAULT nextval('public.item_ordering_departments_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: leave_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types ALTER COLUMN id SET DEFAULT nextval('public.leave_types_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: patients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients ALTER COLUMN id SET DEFAULT nextval('public.patients_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Name: payroll id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll ALTER COLUMN id SET DEFAULT nextval('public.payroll_id_seq'::regclass);


--
-- Name: payroll_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_runs ALTER COLUMN id SET DEFAULT nextval('public.payroll_runs_id_seq'::regclass);


--
-- Name: return_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.return_reasons ALTER COLUMN id SET DEFAULT nextval('public.return_reasons_id_seq'::regclass);


--
-- Name: salary_components id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_components ALTER COLUMN id SET DEFAULT nextval('public.salary_components_id_seq'::regclass);


--
-- Name: shifts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts ALTER COLUMN id SET DEFAULT nextval('public.shifts_id_seq'::regclass);


--
-- Name: system_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN id SET DEFAULT nextval('public.system_logs_id_seq'::regclass);


--
-- Name: user_salary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_salary ALTER COLUMN id SET DEFAULT nextval('public.user_salary_id_seq'::regclass);


--
-- Name: user_secondary_departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_secondary_departments ALTER COLUMN id SET DEFAULT nextval('public.user_secondary_departments_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vendors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors ALTER COLUMN id SET DEFAULT nextval('public.vendors_id_seq'::regclass);


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.activity_logs (id, "timestamp", user_id, action_type, entity_type, entity_id, entity_identifier, details, ip_address) FROM stdin;
\.


--
-- Data for Name: asset_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asset_assignments (id, asset_id, assigned_to_user_id, assigned_to_department_id, assigned_at, assigned_by, returned_at, returned_by, notes) FROM stdin;
\.


--
-- Data for Name: asset_maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.asset_maintenance (id, asset_id, maintenance_type, description, cost, performed_by, performed_at, next_maintenance_date, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assets (id, asset_code, name, description, category, current_department_id, location_details, purchase_date, purchase_price, vendor_id, warranty_expiry, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance (id, user_id, date, status, shift_id, check_in_time, check_out_time, biometric_check_in, biometric_check_out, total_hours, overtime_hours, leave_type_id, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, table_name, record_id, action, old_values, new_values, user_id, "timestamp", ip_address) FROM stdin;
\.


--
-- Data for Name: billing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.billing (id, billing_number, order_id, patient_id, ipd_id, order_creator_id, ordering_department_id, dispatching_department_id, total_amount, status, paid_amount, payment_date, payment_reference, generated_at, generated_by) FROM stdin;
2	BILL-PHR-20260315175655	2	1	1	1	2	6	90.00	PAID	90.00	2026-03-15 17:57:16.752785+00	\N	2026-03-15 17:56:55.24981+00	1
1	BILL-SIM-20260315175654	1	1	1	1	2	7	350.00	PARTIAL	116.00	\N	\N	2026-03-15 17:56:54.284342+00	1
\.


--
-- Data for Name: billing_adjustment_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.billing_adjustment_items (id, adjustment_id, original_billing_item_id, item_id, item_name, item_code, unit, cost_per_unit, quantity_returned, line_amount) FROM stdin;
\.


--
-- Data for Name: billing_adjustments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.billing_adjustments (id, adjustment_number, original_billing_id, return_order_id, adjustment_type, adjustment_amount, reason, is_credit, credit_utilized, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: billing_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.billing_items (id, billing_id, order_item_id, item_id, item_name, item_code, unit, cost_per_unit, quantity_dispatched, line_amount) FROM stdin;
1	1	1	6	Complete Blood Count (CBC)	LAB001	test	350.00	1	350.00
2	2	2	1	Paracetamol 500mg	MED001	tablet	2.50	14	35.00
3	2	3	2	Amoxicillin 250mg	MED002	capsule	5.00	11	55.00
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, name, code, description, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	Administration	ADMIN	Hospital Administration	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
2	Ward A	WARD-A	General Ward A	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
3	Ward B	WARD-B	General Ward B	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
4	ICU	ICU	Intensive Care Unit	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
5	Emergency	EMRG	Emergency Department	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
6	Pharmacy	PHRM	Pharmacy Department	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
7	Laboratory	LAB	Pathology Laboratory	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
8	Radiology	RAD	Radiology Department	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
9	OT	OT	Operation Theater	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
10	Kitchen	KTCHN	Hospital Kitchen	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
\.


--
-- Data for Name: dispatch_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dispatch_events (id, order_item_id, quantity_dispatched, dispatched_by, dispatched_at, dispatch_notes, quantity_received, received_by, received_at, receipt_notes, batch_number, expiry_date) FROM stdin;
1	1	1	1	2026-03-15 17:56:54.32311+00	\N	1	1	2026-03-15 17:56:54.327529+00	\N	\N	\N
2	2	14	1	2026-03-15 17:56:55.283133+00	\N	14	1	2026-03-15 17:56:55.290979+00	\N	\N	\N
3	3	11	1	2026-03-15 17:56:55.283223+00	\N	11	1	2026-03-15 17:56:55.290987+00	\N	\N	\N
\.


--
-- Data for Name: ipd; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ipd (id, ipd_number, patient_id, status, current_phase, admission_date, discharge_date, admitting_department_id, current_department_id, bed_number, primary_diagnosis, attending_doctor_id, created_at, created_by, updated_at, updated_by) FROM stdin;
1	IPD-2024-0001	1	ACTIVE	IPD	2026-03-15 17:56:39.946045+00	\N	2	2	A-101	Fever with body ache	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N
2	IPD-2024-0002	2	ACTIVE	IPD	2026-03-15 17:56:39.946098+00	\N	3	3	B-205	Post-operative care	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N
\.


--
-- Data for Name: ipd_phase_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ipd_phase_log (id, ipd_id, from_phase, to_phase, changed_at, changed_by, notes) FROM stdin;
\.


--
-- Data for Name: item_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_categories (id, name, description, is_active, created_at) FROM stdin;
1	Medicines	Pharmaceutical medicines	t	2026-03-15 17:56:38.49674+00
2	Consumables	Medical consumables	t	2026-03-15 17:56:38.49674+00
3	Lab Tests	Laboratory tests	t	2026-03-15 17:56:38.49674+00
4	Radiology	Imaging services	t	2026-03-15 17:56:38.49674+00
5	Food & Beverages	Patient meals	t	2026-03-15 17:56:38.49674+00
\.


--
-- Data for Name: item_ordering_departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.item_ordering_departments (id, item_id, department_id) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.items (id, name, code, description, category_id, unit, dispatching_department_id, vendor_id, all_departments_allowed, workflow_phase, priority_requirement, patient_ipd_requirement, ipd_status_allowed, cost_per_unit, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	Paracetamol 500mg	MED001	\N	1	tablet	6	2	t	IPD	NON_MANDATORY	NON_MANDATORY	BOTH	2.50	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
2	Amoxicillin 250mg	MED002	\N	1	capsule	6	2	t	IPD	NON_MANDATORY	NON_MANDATORY	BOTH	5.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
3	IV Saline 500ml	MED003	\N	1	bottle	6	2	t	IPD	NON_MANDATORY	MANDATORY	ACTIVE_ONLY	45.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
4	Surgical Gloves (pair)	CON001	\N	2	pair	6	1	t	\N	NON_MANDATORY	NON_MANDATORY	BOTH	15.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
5	Bandage Roll	CON002	\N	2	roll	6	1	t	\N	NON_MANDATORY	NON_MANDATORY	BOTH	25.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
6	Complete Blood Count (CBC)	LAB001	\N	3	test	7	3	t	IPD	NON_MANDATORY	MANDATORY	BOTH	350.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
7	Blood Sugar (Fasting)	LAB002	\N	3	test	7	3	t	IPD	NON_MANDATORY	MANDATORY	BOTH	150.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
8	X-Ray Chest PA	RAD001	\N	4	test	8	\N	t	IPD	NON_MANDATORY	MANDATORY	BOTH	500.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
9	Patient Meal - Regular	FOOD001	\N	5	meal	10	\N	t	IPD	NON_MANDATORY	MANDATORY	ACTIVE_ONLY	100.00	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
\.


--
-- Data for Name: leave_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.leave_types (id, name, code, is_paid, max_days_per_year, is_active) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, user_id, phone, channel, template_code, message, status, sent_at, error_message, reference_type, reference_id, created_at) FROM stdin;
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.order_items (id, order_id, item_id, original_order_item_id, quantity_requested, quantity_dispatched, quantity_received, return_reason, dispatching_department_id, status, notes, created_at) FROM stdin;
1	1	6	\N	1	1	1	\N	7	RECEIVED	\N	2026-03-15 17:56:54.284342+00
2	2	1	\N	14	14	14	\N	6	RECEIVED	\N	2026-03-15 17:56:55.24981+00
3	2	2	\N	11	11	11	\N	6	RECEIVED	\N	2026-03-15 17:56:55.24981+00
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders (id, order_number, order_type, original_order_id, return_reason, patient_id, ipd_id, ordering_department_id, priority, status, notes, created_by, created_at, completed_by, completed_at, cancelled_by, cancelled_at, cancellation_reason) FROM stdin;
1	LAB-20260315175654	REGULAR	\N	\N	1	1	2	NORMAL	COMPLETED	\N	1	2026-03-15 17:56:54.284342+00	\N	2026-03-15 17:56:54.327543+00	\N	\N	\N
2	PHR-20260315175655	REGULAR	\N	\N	1	1	2	NORMAL	COMPLETED	\N	1	2026-03-15 17:56:55.24981+00	\N	2026-03-15 17:56:55.291003+00	\N	\N	\N
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.patients (id, uhid, name, date_of_birth, gender, phone, email, address, emergency_contact_name, emergency_contact_phone, blood_group, created_at, created_by, updated_at, updated_by) FROM stdin;
1	UHID-0001	Ram Kumar	1985-05-15	Male	9898989898	\N	123 Main Street, Delhi	\N	\N	O+	2026-03-15 17:56:38.49674+00	\N	\N	\N
2	UHID-0002	Sita Devi	1990-08-20	Female	9797979797	\N	456 Park Avenue, Delhi	\N	\N	A+	2026-03-15 17:56:38.49674+00	\N	\N	\N
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payments (id, payment_number, billing_id, amount, payment_mode, payment_date, payment_reference, notes, recorded_by, recorded_at) FROM stdin;
1	PAY-20260315-0001	2	50.00	CASH	2026-03-15 17:57:08.74082+00	CASH-001	First partial payment	1	2026-03-15 17:57:08.74082+00
2	PAY-20260315-0002	2	40.00	UPI	2026-03-15 17:57:16.735438+00	UPI-123456	Second payment via UPI	1	2026-03-15 17:57:16.735438+00
3	PAY-20260315-0003	1	100.00	CASH	2026-03-15 18:00:00.891982+00	TEST-CASH-001	Test partial payment	1	2026-03-15 18:00:00.891982+00
4	PAY-20260315-0004	1	10.00	CASH	2026-03-15 18:00:57.64081+00	TEST-CASH-PYTEST	Test payment from pytest	1	2026-03-15 18:00:57.64081+00
5	PAY-20260315-0005	1	1.00	CASH	2026-03-15 18:00:57.992179+00	\N	\N	1	2026-03-15 18:00:57.992179+00
6	PAY-20260315-0006	1	1.00	CARD	2026-03-15 18:00:58.173696+00	\N	\N	1	2026-03-15 18:00:58.173696+00
7	PAY-20260315-0007	1	1.00	UPI	2026-03-15 18:00:58.369304+00	\N	\N	1	2026-03-15 18:00:58.369304+00
8	PAY-20260315-0008	1	1.00	INSURANCE	2026-03-15 18:00:58.561529+00	\N	\N	1	2026-03-15 18:00:58.561529+00
9	PAY-20260315-0009	1	1.00	OTHER	2026-03-15 18:00:58.751562+00	\N	\N	1	2026-03-15 18:00:58.751562+00
10	PAY-20260315-0010	1	1.00	CASH	2026-03-15 18:01:01.941806+00	\N	\N	1	2026-03-15 18:01:01.941806+00
\.


--
-- Data for Name: payroll; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payroll (id, payroll_run_id, user_id, total_working_days, days_present, days_absent, leave_days, overtime_hours, basic_salary, gross_earnings, total_deductions, net_salary, payment_status, payment_date, payment_reference, created_at) FROM stdin;
\.


--
-- Data for Name: payroll_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payroll_runs (id, month, year, status, processed_at, processed_by, created_at) FROM stdin;
\.


--
-- Data for Name: return_reasons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.return_reasons (id, reason, is_active, created_at) FROM stdin;
1	Unused	t	2026-03-15 17:56:38.49674+00
2	Wrong Item	t	2026-03-15 17:56:38.49674+00
3	Excess Quantity	t	2026-03-15 17:56:38.49674+00
4	Defective Item	t	2026-03-15 17:56:38.49674+00
5	Damaged Item	t	2026-03-15 17:56:38.49674+00
6	Other	t	2026-03-15 17:56:38.49674+00
\.


--
-- Data for Name: salary_components; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.salary_components (id, name, code, component_type, is_taxable, is_active) FROM stdin;
\.


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shifts (id, name, start_time, end_time, is_active) FROM stdin;
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_logs (id, "timestamp", level, user_id, endpoint, method, error_type, error_message, stack_trace, request_body, response_status, ip_address, user_agent, duration_ms) FROM stdin;
\.


--
-- Data for Name: user_salary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_salary (id, user_id, effective_from, effective_to, basic_salary, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: user_secondary_departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_secondary_departments (id, user_id, department_id) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, user_id, token_hash, device_info, ip_address, created_at, expires_at, is_active) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, phone, name, email, password_hash, primary_department_id, is_admin, can_view_costs, can_reactivate_ipd, is_active, employee_code, designation, date_of_joining, created_at, created_by, updated_at, updated_by, last_login_at) FROM stdin;
2	9876543210	Dr. Rajesh Kumar	\N	$2b$12$QPEmHrw7/X82DiM7EU.LC.NuNdu7zPXOA36PaAeJJkIRb1p71LqdO	2	f	f	f	t	EMP002	Senior Doctor	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N	\N
3	9876543211	Nurse Priya Sharma	\N	$2b$12$h4LVQA4lOhMVQe2efJYuJu0124lf90Sl8G7hvGAn513bb/pslFnX.	2	f	f	f	t	EMP003	Head Nurse	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N	\N
4	9876543212	Pharmacist Amit Singh	\N	$2b$12$PBNkRSzIrCylmtR0UwN4qu/l301f1qc4JbwlwIWeV.26q7sbObP.u	6	f	f	f	t	EMP004	Chief Pharmacist	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N	\N
5	9876543213	Lab Tech Sunita Verma	\N	$2b$12$fD77jYvdwXjQreTlYSwzSOYAjM23ZKF6PgkDaQrk7aCV12PmXBCmq	7	f	f	f	t	EMP005	Lab Technician	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N	\N
6	9876543214	Dr. Emergency Staff	\N	$2b$12$mv82Dn6nxhSoJ8oMfxYab.YZ/Jmd6gg3DiXG2go2CR1z1ywR1zVja	5	f	f	f	t	EMP006	Emergency Doctor	\N	2026-03-15 17:56:38.49674+00	\N	\N	\N	\N
1	9999999999	System Admin	admin@mthhospital.com	$2b$12$9LoDabxE1fjbb7TgtmpBmO3p34adXtEfUbnmNUJrYo8ZrlkSJkcGK	1	t	t	t	t	EMP001	System Administrator	\N	2026-03-15 17:56:38.49674+00	\N	2026-03-15 18:12:48.546023+00	\N	2026-03-15 18:12:48.774361+00
\.


--
-- Data for Name: vendors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vendors (id, name, code, contact_person, phone, email, address, gst_number, pan_number, bank_account_number, bank_ifsc, is_active, created_at, created_by, updated_at, updated_by) FROM stdin;
1	MedSupply Co.	VEND001	John Doe	1234567890	\N	\N	\N	\N	\N	\N	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
2	PharmaWholesale Ltd.	VEND002	Jane Smith	1234567891	\N	\N	\N	\N	\N	\N	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
3	LabEquip India	VEND003	Ravi Patel	1234567892	\N	\N	\N	\N	\N	\N	t	2026-03-15 17:56:38.49674+00	\N	\N	\N
\.


--
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 1, false);


--
-- Name: asset_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asset_assignments_id_seq', 1, false);


--
-- Name: asset_maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.asset_maintenance_id_seq', 1, false);


--
-- Name: assets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.assets_id_seq', 1, false);


--
-- Name: attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_id_seq', 1, false);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);


--
-- Name: billing_adjustment_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.billing_adjustment_items_id_seq', 1, false);


--
-- Name: billing_adjustments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.billing_adjustments_id_seq', 1, false);


--
-- Name: billing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.billing_id_seq', 2, true);


--
-- Name: billing_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.billing_items_id_seq', 3, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 10, true);


--
-- Name: dispatch_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.dispatch_events_id_seq', 3, true);


--
-- Name: ipd_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ipd_id_seq', 2, true);


--
-- Name: ipd_phase_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ipd_phase_log_id_seq', 1, false);


--
-- Name: item_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_categories_id_seq', 5, true);


--
-- Name: item_ordering_departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.item_ordering_departments_id_seq', 1, false);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.items_id_seq', 9, true);


--
-- Name: leave_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.leave_types_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.order_items_id_seq', 3, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orders_id_seq', 2, true);


--
-- Name: patients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.patients_id_seq', 2, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payments_id_seq', 10, true);


--
-- Name: payroll_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payroll_id_seq', 1, false);


--
-- Name: payroll_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payroll_runs_id_seq', 1, false);


--
-- Name: return_reasons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.return_reasons_id_seq', 6, true);


--
-- Name: salary_components_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.salary_components_id_seq', 1, false);


--
-- Name: shifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shifts_id_seq', 1, false);


--
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.system_logs_id_seq', 1, false);


--
-- Name: user_salary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_salary_id_seq', 1, false);


--
-- Name: user_secondary_departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_secondary_departments_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: vendors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vendors_id_seq', 3, true);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: asset_assignments asset_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_pkey PRIMARY KEY (id);


--
-- Name: asset_maintenance asset_maintenance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_maintenance
    ADD CONSTRAINT asset_maintenance_pkey PRIMARY KEY (id);


--
-- Name: assets assets_asset_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_asset_code_key UNIQUE (asset_code);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: billing_adjustment_items billing_adjustment_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustment_items
    ADD CONSTRAINT billing_adjustment_items_pkey PRIMARY KEY (id);


--
-- Name: billing_adjustments billing_adjustments_adjustment_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments
    ADD CONSTRAINT billing_adjustments_adjustment_number_key UNIQUE (adjustment_number);


--
-- Name: billing_adjustments billing_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments
    ADD CONSTRAINT billing_adjustments_pkey PRIMARY KEY (id);


--
-- Name: billing billing_billing_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_billing_number_key UNIQUE (billing_number);


--
-- Name: billing_items billing_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_items
    ADD CONSTRAINT billing_items_pkey PRIMARY KEY (id);


--
-- Name: billing billing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_pkey PRIMARY KEY (id);


--
-- Name: departments departments_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_code_key UNIQUE (code);


--
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: dispatch_events dispatch_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_events
    ADD CONSTRAINT dispatch_events_pkey PRIMARY KEY (id);


--
-- Name: ipd_phase_log ipd_phase_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd_phase_log
    ADD CONSTRAINT ipd_phase_log_pkey PRIMARY KEY (id);


--
-- Name: ipd ipd_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd
    ADD CONSTRAINT ipd_pkey PRIMARY KEY (id);


--
-- Name: item_categories item_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_categories
    ADD CONSTRAINT item_categories_name_key UNIQUE (name);


--
-- Name: item_categories item_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_categories
    ADD CONSTRAINT item_categories_pkey PRIMARY KEY (id);


--
-- Name: item_ordering_departments item_ordering_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_ordering_departments
    ADD CONSTRAINT item_ordering_departments_pkey PRIMARY KEY (id);


--
-- Name: items items_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_code_key UNIQUE (code);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: leave_types leave_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_code_key UNIQUE (code);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: payments payments_payment_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_payment_number_key UNIQUE (payment_number);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: payroll payroll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_pkey PRIMARY KEY (id);


--
-- Name: payroll_runs payroll_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_runs
    ADD CONSTRAINT payroll_runs_pkey PRIMARY KEY (id);


--
-- Name: return_reasons return_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.return_reasons
    ADD CONSTRAINT return_reasons_pkey PRIMARY KEY (id);


--
-- Name: salary_components salary_components_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_components
    ADD CONSTRAINT salary_components_code_key UNIQUE (code);


--
-- Name: salary_components salary_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.salary_components
    ADD CONSTRAINT salary_components_pkey PRIMARY KEY (id);


--
-- Name: shifts shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- Name: user_salary user_salary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_salary
    ADD CONSTRAINT user_salary_pkey PRIMARY KEY (id);


--
-- Name: user_secondary_departments user_secondary_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_secondary_departments
    ADD CONSTRAINT user_secondary_departments_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendors vendors_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_code_key UNIQUE (code);


--
-- Name: vendors vendors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendors
    ADD CONSTRAINT vendors_pkey PRIMARY KEY (id);


--
-- Name: ix_activity_logs_action_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_logs_action_type ON public.activity_logs USING btree (action_type);


--
-- Name: ix_activity_logs_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_logs_entity_id ON public.activity_logs USING btree (entity_id);


--
-- Name: ix_activity_logs_entity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_logs_entity_type ON public.activity_logs USING btree (entity_type);


--
-- Name: ix_activity_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_logs_id ON public.activity_logs USING btree (id);


--
-- Name: ix_activity_logs_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_activity_logs_timestamp ON public.activity_logs USING btree ("timestamp");


--
-- Name: ix_asset_assignments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_asset_assignments_id ON public.asset_assignments USING btree (id);


--
-- Name: ix_asset_maintenance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_asset_maintenance_id ON public.asset_maintenance USING btree (id);


--
-- Name: ix_assets_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_assets_id ON public.assets USING btree (id);


--
-- Name: ix_attendance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_attendance_id ON public.attendance USING btree (id);


--
-- Name: ix_audit_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_log_id ON public.audit_log USING btree (id);


--
-- Name: ix_audit_log_table_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_log_table_name ON public.audit_log USING btree (table_name);


--
-- Name: ix_audit_log_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_log_timestamp ON public.audit_log USING btree ("timestamp");


--
-- Name: ix_billing_adjustment_items_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_billing_adjustment_items_id ON public.billing_adjustment_items USING btree (id);


--
-- Name: ix_billing_adjustments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_billing_adjustments_id ON public.billing_adjustments USING btree (id);


--
-- Name: ix_billing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_billing_id ON public.billing USING btree (id);


--
-- Name: ix_billing_items_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_billing_items_id ON public.billing_items USING btree (id);


--
-- Name: ix_departments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_departments_id ON public.departments USING btree (id);


--
-- Name: ix_dispatch_events_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dispatch_events_id ON public.dispatch_events USING btree (id);


--
-- Name: ix_ipd_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ipd_id ON public.ipd USING btree (id);


--
-- Name: ix_ipd_ipd_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_ipd_ipd_number ON public.ipd USING btree (ipd_number);


--
-- Name: ix_ipd_phase_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ipd_phase_log_id ON public.ipd_phase_log USING btree (id);


--
-- Name: ix_item_categories_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_item_categories_id ON public.item_categories USING btree (id);


--
-- Name: ix_item_ordering_departments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_item_ordering_departments_id ON public.item_ordering_departments USING btree (id);


--
-- Name: ix_items_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_items_id ON public.items USING btree (id);


--
-- Name: ix_leave_types_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_leave_types_id ON public.leave_types USING btree (id);


--
-- Name: ix_notifications_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_id ON public.notifications USING btree (id);


--
-- Name: ix_order_items_dispatching_department_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_items_dispatching_department_id ON public.order_items USING btree (dispatching_department_id);


--
-- Name: ix_order_items_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_items_id ON public.order_items USING btree (id);


--
-- Name: ix_order_items_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_order_items_status ON public.order_items USING btree (status);


--
-- Name: ix_orders_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_orders_created_at ON public.orders USING btree (created_at);


--
-- Name: ix_orders_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_orders_id ON public.orders USING btree (id);


--
-- Name: ix_orders_order_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_orders_order_number ON public.orders USING btree (order_number);


--
-- Name: ix_orders_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_orders_status ON public.orders USING btree (status);


--
-- Name: ix_patients_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_patients_id ON public.patients USING btree (id);


--
-- Name: ix_patients_uhid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_patients_uhid ON public.patients USING btree (uhid);


--
-- Name: ix_payments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payments_id ON public.payments USING btree (id);


--
-- Name: ix_payroll_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payroll_id ON public.payroll USING btree (id);


--
-- Name: ix_payroll_runs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_payroll_runs_id ON public.payroll_runs USING btree (id);


--
-- Name: ix_return_reasons_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_return_reasons_id ON public.return_reasons USING btree (id);


--
-- Name: ix_salary_components_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_salary_components_id ON public.salary_components USING btree (id);


--
-- Name: ix_shifts_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_shifts_id ON public.shifts USING btree (id);


--
-- Name: ix_system_logs_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_logs_endpoint ON public.system_logs USING btree (endpoint);


--
-- Name: ix_system_logs_error_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_logs_error_type ON public.system_logs USING btree (error_type);


--
-- Name: ix_system_logs_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_logs_id ON public.system_logs USING btree (id);


--
-- Name: ix_system_logs_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_logs_level ON public.system_logs USING btree (level);


--
-- Name: ix_system_logs_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_system_logs_timestamp ON public.system_logs USING btree ("timestamp");


--
-- Name: ix_user_salary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_salary_id ON public.user_salary USING btree (id);


--
-- Name: ix_user_secondary_departments_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_secondary_departments_id ON public.user_secondary_departments USING btree (id);


--
-- Name: ix_user_sessions_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_sessions_id ON public.user_sessions USING btree (id);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_phone ON public.users USING btree (phone);


--
-- Name: ix_vendors_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_vendors_id ON public.vendors USING btree (id);


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: asset_assignments asset_assignments_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: asset_assignments asset_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: asset_assignments asset_assignments_assigned_to_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_assigned_to_department_id_fkey FOREIGN KEY (assigned_to_department_id) REFERENCES public.departments(id);


--
-- Name: asset_assignments asset_assignments_assigned_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_assigned_to_user_id_fkey FOREIGN KEY (assigned_to_user_id) REFERENCES public.users(id);


--
-- Name: asset_assignments asset_assignments_returned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_assignments
    ADD CONSTRAINT asset_assignments_returned_by_fkey FOREIGN KEY (returned_by) REFERENCES public.users(id);


--
-- Name: asset_maintenance asset_maintenance_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_maintenance
    ADD CONSTRAINT asset_maintenance_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(id);


--
-- Name: asset_maintenance asset_maintenance_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_maintenance
    ADD CONSTRAINT asset_maintenance_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: assets assets_current_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_current_department_id_fkey FOREIGN KEY (current_department_id) REFERENCES public.departments(id);


--
-- Name: assets assets_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: attendance attendance_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(id);


--
-- Name: attendance attendance_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id);


--
-- Name: attendance attendance_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: billing_adjustment_items billing_adjustment_items_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustment_items
    ADD CONSTRAINT billing_adjustment_items_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.billing_adjustments(id) ON DELETE CASCADE;


--
-- Name: billing_adjustment_items billing_adjustment_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustment_items
    ADD CONSTRAINT billing_adjustment_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: billing_adjustment_items billing_adjustment_items_original_billing_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustment_items
    ADD CONSTRAINT billing_adjustment_items_original_billing_item_id_fkey FOREIGN KEY (original_billing_item_id) REFERENCES public.billing_items(id);


--
-- Name: billing_adjustments billing_adjustments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments
    ADD CONSTRAINT billing_adjustments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: billing_adjustments billing_adjustments_original_billing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments
    ADD CONSTRAINT billing_adjustments_original_billing_id_fkey FOREIGN KEY (original_billing_id) REFERENCES public.billing(id);


--
-- Name: billing_adjustments billing_adjustments_return_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_adjustments
    ADD CONSTRAINT billing_adjustments_return_order_id_fkey FOREIGN KEY (return_order_id) REFERENCES public.orders(id);


--
-- Name: billing billing_dispatching_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_dispatching_department_id_fkey FOREIGN KEY (dispatching_department_id) REFERENCES public.departments(id);


--
-- Name: billing billing_generated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES public.users(id);


--
-- Name: billing billing_ipd_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_ipd_id_fkey FOREIGN KEY (ipd_id) REFERENCES public.ipd(id);


--
-- Name: billing_items billing_items_billing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_items
    ADD CONSTRAINT billing_items_billing_id_fkey FOREIGN KEY (billing_id) REFERENCES public.billing(id) ON DELETE CASCADE;


--
-- Name: billing_items billing_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_items
    ADD CONSTRAINT billing_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: billing_items billing_items_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_items
    ADD CONSTRAINT billing_items_order_item_id_fkey FOREIGN KEY (order_item_id) REFERENCES public.order_items(id);


--
-- Name: billing billing_order_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_order_creator_id_fkey FOREIGN KEY (order_creator_id) REFERENCES public.users(id);


--
-- Name: billing billing_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: billing billing_ordering_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_ordering_department_id_fkey FOREIGN KEY (ordering_department_id) REFERENCES public.departments(id);


--
-- Name: billing billing_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing
    ADD CONSTRAINT billing_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: dispatch_events dispatch_events_dispatched_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_events
    ADD CONSTRAINT dispatch_events_dispatched_by_fkey FOREIGN KEY (dispatched_by) REFERENCES public.users(id);


--
-- Name: dispatch_events dispatch_events_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_events
    ADD CONSTRAINT dispatch_events_order_item_id_fkey FOREIGN KEY (order_item_id) REFERENCES public.order_items(id);


--
-- Name: dispatch_events dispatch_events_received_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_events
    ADD CONSTRAINT dispatch_events_received_by_fkey FOREIGN KEY (received_by) REFERENCES public.users(id);


--
-- Name: ipd ipd_admitting_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd
    ADD CONSTRAINT ipd_admitting_department_id_fkey FOREIGN KEY (admitting_department_id) REFERENCES public.departments(id);


--
-- Name: ipd ipd_attending_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd
    ADD CONSTRAINT ipd_attending_doctor_id_fkey FOREIGN KEY (attending_doctor_id) REFERENCES public.users(id);


--
-- Name: ipd ipd_current_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd
    ADD CONSTRAINT ipd_current_department_id_fkey FOREIGN KEY (current_department_id) REFERENCES public.departments(id);


--
-- Name: ipd ipd_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd
    ADD CONSTRAINT ipd_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: ipd_phase_log ipd_phase_log_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd_phase_log
    ADD CONSTRAINT ipd_phase_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id);


--
-- Name: ipd_phase_log ipd_phase_log_ipd_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ipd_phase_log
    ADD CONSTRAINT ipd_phase_log_ipd_id_fkey FOREIGN KEY (ipd_id) REFERENCES public.ipd(id);


--
-- Name: item_ordering_departments item_ordering_departments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_ordering_departments
    ADD CONSTRAINT item_ordering_departments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: item_ordering_departments item_ordering_departments_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_ordering_departments
    ADD CONSTRAINT item_ordering_departments_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: items items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.item_categories(id);


--
-- Name: items items_dispatching_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_dispatching_department_id_fkey FOREIGN KEY (dispatching_department_id) REFERENCES public.departments(id);


--
-- Name: items items_vendor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id);


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: order_items order_items_dispatching_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_dispatching_department_id_fkey FOREIGN KEY (dispatching_department_id) REFERENCES public.departments(id);


--
-- Name: order_items order_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_original_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_original_order_item_id_fkey FOREIGN KEY (original_order_item_id) REFERENCES public.order_items(id);


--
-- Name: orders orders_cancelled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.users(id);


--
-- Name: orders orders_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES public.users(id);


--
-- Name: orders orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: orders orders_ipd_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_ipd_id_fkey FOREIGN KEY (ipd_id) REFERENCES public.ipd(id);


--
-- Name: orders orders_ordering_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_ordering_department_id_fkey FOREIGN KEY (ordering_department_id) REFERENCES public.departments(id);


--
-- Name: orders orders_original_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_original_order_id_fkey FOREIGN KEY (original_order_id) REFERENCES public.orders(id);


--
-- Name: orders orders_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: payments payments_billing_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_billing_id_fkey FOREIGN KEY (billing_id) REFERENCES public.billing(id);


--
-- Name: payments payments_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(id);


--
-- Name: payroll payroll_payroll_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_payroll_run_id_fkey FOREIGN KEY (payroll_run_id) REFERENCES public.payroll_runs(id);


--
-- Name: payroll_runs payroll_runs_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_runs
    ADD CONSTRAINT payroll_runs_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.users(id);


--
-- Name: payroll payroll_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll
    ADD CONSTRAINT payroll_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: system_logs system_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_salary user_salary_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_salary
    ADD CONSTRAINT user_salary_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: user_salary user_salary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_salary
    ADD CONSTRAINT user_salary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_secondary_departments user_secondary_departments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_secondary_departments
    ADD CONSTRAINT user_secondary_departments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: user_secondary_departments user_secondary_departments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_secondary_departments
    ADD CONSTRAINT user_secondary_departments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users users_primary_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_primary_department_id_fkey FOREIGN KEY (primary_department_id) REFERENCES public.departments(id);


--
-- PostgreSQL database dump complete
--

\unrestrict jgvVY3vgCRw9csDZMO5BD8Ns2bm0rBCYrmbBsrihElKe91EWLEKlKDiG2PlO50j


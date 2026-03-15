--
-- PostgreSQL database dump
--

\restrict cAVaBFhGPycVmItEJPdfZ1YRgXeNRdxUD3yuXglAcmhETEUUcakKHHjJeaEWMy0

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
1	2026-03-15 18:12:48.951758+00	1	BACKUP_CREATED	SYSTEM	\N	mth_hospital_backup_20260315_181248.sql	{"size_mb": 0.0902099609375, "duration_seconds": 0.165636}	\N
2	2026-03-15 18:12:55.506914+00	1	SIMULATION_RUN	SYSTEM	\N	20260315181255	{"type": "stress_test", "level": "LIGHT", "target_orders": 500}	\N
3	2026-03-15 18:14:38.702675+00	1	BACKUP_CREATED	SYSTEM	\N	mth_hospital_backup_20260315_181438.sql	{"size_mb": 0.2516136169433594, "duration_seconds": 0.090158}	\N
4	2026-03-15 18:15:39.050683+00	1	BACKUP_CREATED	SYSTEM	\N	mth_hospital_backup_20260315_181539.sql	{"size_mb": 0.2522268295288086, "duration_seconds": 0.108971}	\N
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
4	3	3	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:55.541123+00
5	3	6	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:55.541123+00
6	3	2	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:55.541123+00
7	3	1	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:55.541123+00
8	4	1	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:55.618263+00
9	4	6	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:55.618263+00
10	5	9	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:55.653188+00
11	5	2	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:55.653188+00
12	5	5	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:55.653188+00
13	5	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:55.653188+00
14	6	6	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:55.687402+00
15	6	9	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:55.687402+00
16	6	4	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:55.687402+00
17	6	5	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:55.687402+00
18	6	8	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:55.687402+00
19	7	1	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:55.734253+00
20	7	5	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:55.734253+00
21	7	8	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:55.734253+00
22	8	9	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:55.767877+00
23	9	1	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:55.809069+00
24	10	4	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:55.842319+00
25	11	2	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:55.875504+00
26	11	5	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:55.875504+00
27	11	4	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:55.875504+00
28	11	9	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:55.875504+00
29	11	3	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:55.875504+00
30	12	1	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:55.917458+00
31	12	8	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:55.917458+00
32	12	7	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:55.917458+00
33	13	9	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:55.952238+00
34	14	8	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:55.985418+00
35	14	4	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:55.985418+00
36	14	2	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:55.985418+00
37	15	9	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:56.02905+00
38	15	7	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:56.02905+00
39	15	4	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:56.02905+00
40	16	6	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:56.063104+00
41	16	8	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.063104+00
42	16	3	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:56.063104+00
43	16	5	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:56.063104+00
44	17	6	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:56.097234+00
45	17	8	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:56.097234+00
46	18	2	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:56.137306+00
47	18	9	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:56.137306+00
48	18	3	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.137306+00
49	18	1	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:56.137306+00
50	19	7	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:56.173036+00
51	19	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.173036+00
52	19	8	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:56.173036+00
53	19	1	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:56.173036+00
54	19	3	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:56.173036+00
55	20	2	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:56.215526+00
56	20	8	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:56.215526+00
57	20	6	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:56.215526+00
58	20	7	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:56.215526+00
59	21	3	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.250835+00
60	21	6	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:56.250835+00
61	21	1	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:56.250835+00
62	21	9	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:56.250835+00
63	22	3	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:56.285166+00
64	23	9	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:56.354047+00
65	23	6	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:56.354047+00
66	24	4	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.454523+00
67	24	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.454523+00
68	24	8	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:56.454523+00
69	24	3	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:56.454523+00
70	25	6	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:56.540118+00
71	25	3	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:56.540118+00
72	26	4	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:56.659446+00
73	26	9	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:56.659446+00
74	26	3	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:56.659446+00
75	26	5	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:56.659446+00
76	27	5	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:57.010129+00
77	27	3	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:57.010129+00
78	28	8	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:57.249448+00
79	28	1	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:57.249448+00
80	28	6	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:57.249448+00
81	29	7	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:57.458928+00
82	29	8	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:57.458928+00
83	29	9	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.458928+00
84	29	5	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:57.458928+00
85	30	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:57.576816+00
86	30	2	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:57.576816+00
87	30	7	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:57.576816+00
88	30	5	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.576816+00
89	30	4	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:57.576816+00
90	31	6	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:57.614386+00
91	31	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:57.614386+00
92	32	3	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:57.655582+00
93	32	9	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.655582+00
94	33	4	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.688776+00
95	34	1	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:57.725496+00
96	35	9	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.77033+00
97	35	8	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:57.77033+00
98	36	4	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:57.80485+00
99	37	1	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:57.838172+00
100	37	7	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:57.838172+00
101	38	9	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:57.878374+00
102	38	5	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:57.878374+00
103	39	7	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:57.912619+00
104	39	6	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:57.912619+00
105	39	8	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:57.912619+00
106	39	2	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:57.912619+00
107	39	4	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:57.912619+00
108	40	9	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:57.955931+00
109	40	2	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:57.955931+00
110	40	6	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:57.955931+00
111	40	3	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:57.955931+00
112	40	5	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:57.955931+00
113	41	8	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:57.989968+00
114	41	5	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:57.989968+00
115	41	3	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:57.989968+00
116	42	3	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.033658+00
117	42	1	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.033658+00
118	42	9	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.033658+00
119	43	7	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.075927+00
120	43	8	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.075927+00
121	43	1	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.075927+00
122	43	5	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.075927+00
123	43	4	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.075927+00
124	44	6	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.109766+00
125	44	4	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.109766+00
126	44	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.109766+00
127	45	7	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.152341+00
128	45	6	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.152341+00
129	45	2	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.152341+00
130	45	4	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.152341+00
131	46	3	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.186603+00
132	47	4	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.220981+00
133	47	9	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.220981+00
134	47	8	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.220981+00
135	47	5	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.220981+00
136	48	5	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.263851+00
137	48	3	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.263851+00
138	48	1	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.263851+00
139	48	8	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.263851+00
140	48	7	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.263851+00
141	49	3	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:58.297918+00
142	49	1	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.297918+00
143	49	5	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.297918+00
144	49	8	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.297918+00
145	50	9	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.331981+00
146	50	2	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.331981+00
147	51	7	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.373712+00
148	51	6	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.373712+00
149	51	3	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.373712+00
150	52	2	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.407691+00
151	53	6	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.440536+00
152	53	3	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.440536+00
153	53	2	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.440536+00
154	54	4	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.482866+00
155	54	7	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.482866+00
156	54	2	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.482866+00
157	54	8	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.482866+00
158	54	9	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.482866+00
159	55	1	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.517005+00
160	56	5	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.558064+00
161	57	6	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.594313+00
162	57	2	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.594313+00
163	57	4	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.594313+00
164	57	3	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:58.594313+00
165	58	6	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.631013+00
166	58	1	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.631013+00
167	59	1	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.671445+00
168	59	3	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.671445+00
169	59	6	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.671445+00
170	60	5	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.709324+00
171	60	1	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:58.709324+00
172	60	6	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.709324+00
173	60	2	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.709324+00
174	61	6	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.749319+00
175	62	3	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.784707+00
176	62	8	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.784707+00
177	62	4	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:58.784707+00
178	62	2	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.784707+00
179	62	7	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.784707+00
180	63	8	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.821241+00
181	64	9	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:58.861689+00
182	64	5	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:58.861689+00
183	64	7	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.861689+00
184	64	3	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.861689+00
185	65	9	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:58.896128+00
186	65	1	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.896128+00
187	66	3	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.9305+00
188	66	4	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:58.9305+00
189	67	4	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:58.970942+00
190	67	5	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:58.970942+00
191	67	8	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:58.970942+00
192	67	7	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:58.970942+00
193	67	2	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:58.970942+00
194	68	3	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.009464+00
195	68	1	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.009464+00
196	68	7	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.009464+00
197	69	8	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.043839+00
198	69	7	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.043839+00
199	69	1	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:59.043839+00
200	70	1	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:59.084138+00
201	70	9	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.084138+00
202	70	2	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.084138+00
203	70	5	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.084138+00
204	70	7	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.084138+00
205	71	9	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.120358+00
206	71	8	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:59.120358+00
207	71	3	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.120358+00
208	71	5	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.120358+00
209	71	2	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.120358+00
210	72	9	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.161765+00
211	72	3	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.161765+00
212	72	2	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.161765+00
213	72	1	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.161765+00
214	72	7	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:59.161765+00
215	73	8	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.196841+00
216	73	1	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.196841+00
217	73	6	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.196841+00
218	74	8	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:59.23538+00
219	75	1	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.274728+00
220	75	2	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.274728+00
221	75	5	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.274728+00
222	75	7	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:59.274728+00
223	76	9	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.313582+00
224	76	8	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.313582+00
225	77	6	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.354645+00
226	77	3	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:59.354645+00
227	77	7	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.354645+00
228	77	1	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:59.354645+00
229	77	9	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.354645+00
230	78	5	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.389878+00
231	79	9	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.426258+00
232	79	8	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.426258+00
233	79	4	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.426258+00
234	79	3	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.426258+00
235	80	7	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:12:59.46967+00
236	80	5	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:59.46967+00
237	81	5	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.50359+00
238	82	5	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:59.537274+00
239	83	6	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:12:59.577081+00
240	84	2	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.612405+00
241	84	1	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.612405+00
242	85	3	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.65452+00
243	85	7	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.65452+00
244	86	7	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.690132+00
245	86	4	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.690132+00
246	86	9	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.690132+00
247	87	7	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.731166+00
248	87	5	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.731166+00
249	87	4	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.731166+00
250	87	8	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:12:59.731166+00
251	88	7	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:12:59.771082+00
252	89	8	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:12:59.805724+00
253	89	2	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:12:59.805724+00
254	89	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.805724+00
255	89	9	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:12:59.805724+00
256	90	9	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.840639+00
257	91	7	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.878776+00
258	92	7	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.915476+00
259	93	7	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.95655+00
260	94	6	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:12:59.991157+00
261	94	9	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:12:59.991157+00
262	94	3	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:12:59.991157+00
263	95	1	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.035842+00
264	96	4	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.070671+00
265	97	4	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.103563+00
266	98	7	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.140449+00
267	98	5	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.140449+00
268	98	8	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.140449+00
269	99	4	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.18403+00
270	99	9	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.18403+00
271	99	1	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:00.18403+00
272	99	5	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:00.18403+00
273	99	3	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.18403+00
274	100	8	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:00.228025+00
275	100	7	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.228025+00
276	100	4	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:00.228025+00
277	100	6	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.228025+00
278	100	9	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.228025+00
279	101	2	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.269091+00
280	101	3	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.269091+00
281	101	9	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.269091+00
282	101	6	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:00.269091+00
283	101	5	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.269091+00
284	102	7	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.302817+00
285	102	3	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.302817+00
286	102	4	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.302817+00
287	102	8	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:00.302817+00
288	103	1	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.338981+00
289	103	8	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.338981+00
290	103	6	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:00.338981+00
291	103	4	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.338981+00
292	103	5	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:00.338981+00
293	104	4	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.375929+00
294	104	8	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:00.375929+00
295	104	3	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.375929+00
296	105	3	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.415713+00
297	105	5	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.415713+00
298	105	4	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.415713+00
299	105	6	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.415713+00
300	106	6	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.456247+00
301	107	4	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.489678+00
302	107	6	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.489678+00
303	108	6	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.528853+00
304	108	4	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.528853+00
305	108	7	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.528853+00
306	108	3	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.528853+00
307	109	9	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.56581+00
308	109	7	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.56581+00
309	109	2	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.56581+00
310	109	1	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.56581+00
311	109	3	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.56581+00
312	110	3	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.600097+00
313	110	4	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.600097+00
314	110	9	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:00.600097+00
315	110	6	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.600097+00
316	110	1	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.600097+00
317	111	8	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:00.635883+00
318	111	1	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.635883+00
319	111	4	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:00.635883+00
320	111	5	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:00.635883+00
321	111	2	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.635883+00
322	112	6	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.677292+00
323	113	8	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.715434+00
324	113	4	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.715434+00
325	114	3	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:00.753049+00
326	114	5	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.753049+00
327	115	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:00.787838+00
328	115	2	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:00.787838+00
329	115	4	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.787838+00
330	116	9	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.827281+00
331	116	6	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.827281+00
332	117	9	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.862892+00
333	117	2	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:00.862892+00
334	118	9	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:00.896211+00
335	118	8	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.896211+00
336	119	9	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.932886+00
337	119	2	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.932886+00
338	119	3	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:00.932886+00
339	120	4	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:00.972634+00
340	120	7	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:00.972634+00
341	120	3	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:00.972634+00
342	121	7	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.011213+00
343	122	1	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.0445+00
344	122	5	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:01.0445+00
345	122	3	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.0445+00
346	122	7	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.0445+00
347	123	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.084197+00
348	123	4	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.084197+00
349	123	3	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.084197+00
350	124	4	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.123982+00
351	124	7	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.123982+00
352	124	6	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.123982+00
353	124	1	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.123982+00
354	125	7	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.160486+00
355	125	9	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.160486+00
356	125	1	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.160486+00
357	126	2	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.194343+00
358	126	6	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.194343+00
359	126	8	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.194343+00
360	126	1	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.194343+00
361	127	2	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.23473+00
362	128	6	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.27077+00
363	129	3	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.31085+00
364	129	8	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.31085+00
365	129	9	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:01.31085+00
366	129	6	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.31085+00
367	130	9	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.344878+00
368	130	3	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:01.344878+00
369	130	2	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.344878+00
370	130	6	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.344878+00
371	131	7	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.380731+00
372	131	5	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.380731+00
373	131	1	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.380731+00
374	131	9	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:01.380731+00
375	131	4	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.380731+00
376	132	9	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.422332+00
377	132	7	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.422332+00
378	132	1	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.422332+00
379	132	4	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.422332+00
380	132	8	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.422332+00
381	133	8	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.460395+00
382	133	2	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.460395+00
383	133	7	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.460395+00
384	133	9	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.460395+00
385	134	9	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.494861+00
386	134	8	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.494861+00
387	134	6	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.494861+00
388	135	6	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.533561+00
389	135	2	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.533561+00
390	135	7	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.533561+00
391	135	1	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:01.533561+00
392	136	2	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.57029+00
393	137	3	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.609093+00
394	137	7	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:01.609093+00
395	137	2	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.609093+00
396	137	4	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.609093+00
397	137	6	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.609093+00
398	138	3	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.643159+00
399	138	2	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.643159+00
400	138	8	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.643159+00
401	139	8	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.679927+00
402	140	3	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.721773+00
403	140	1	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.721773+00
404	140	4	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.721773+00
405	141	4	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.757372+00
406	141	1	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:01.757372+00
407	141	6	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.757372+00
408	141	7	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.757372+00
409	141	9	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.757372+00
410	142	7	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.791653+00
411	143	7	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.82861+00
412	143	9	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.82861+00
413	144	5	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.870623+00
414	144	4	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.870623+00
415	144	1	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.870623+00
416	144	7	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.870623+00
417	144	3	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:01.870623+00
418	145	6	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:01.905494+00
419	146	3	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:01.941018+00
420	146	4	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:01.941018+00
421	146	7	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:01.941018+00
422	146	1	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.941018+00
423	146	5	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:01.941018+00
424	147	4	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:01.98029+00
425	147	5	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.98029+00
426	147	7	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.98029+00
427	147	2	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:01.98029+00
428	147	1	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:01.98029+00
429	148	8	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.01806+00
430	148	6	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.01806+00
431	148	3	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.01806+00
432	148	1	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:02.01806+00
433	149	9	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.057843+00
434	149	8	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.057843+00
435	150	5	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.0912+00
436	151	3	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.128422+00
437	151	6	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.128422+00
438	152	1	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.169548+00
439	152	8	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.169548+00
440	152	4	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.169548+00
441	152	5	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.169548+00
442	152	3	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.169548+00
443	153	5	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.204251+00
444	154	1	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.23934+00
445	154	5	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.23934+00
446	154	7	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.23934+00
447	154	8	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.23934+00
448	155	8	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.2811+00
449	155	4	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.2811+00
450	155	2	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.2811+00
451	156	2	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:02.316371+00
452	157	4	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.357303+00
453	157	8	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.357303+00
454	158	2	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:02.39083+00
455	158	8	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.39083+00
456	158	4	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.39083+00
457	158	6	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.39083+00
458	159	8	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.428889+00
459	159	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:02.428889+00
460	159	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.428889+00
461	160	1	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.470551+00
462	160	9	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:02.470551+00
463	161	7	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.504781+00
464	161	9	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.504781+00
465	161	4	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.504781+00
466	161	8	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.504781+00
467	162	4	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.53892+00
468	162	9	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.53892+00
469	163	1	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:02.578812+00
470	163	3	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.578812+00
471	163	2	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.578812+00
472	163	8	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.578812+00
473	163	4	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.578812+00
474	164	6	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:02.614987+00
475	164	4	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.614987+00
476	164	1	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:02.614987+00
477	164	7	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.614987+00
478	165	1	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:02.656157+00
479	166	9	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.689395+00
480	166	3	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:02.689395+00
481	166	2	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.689395+00
482	166	1	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.689395+00
483	166	8	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:02.689395+00
484	167	5	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.728686+00
485	167	9	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.728686+00
486	167	4	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.728686+00
487	167	3	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:02.728686+00
488	168	4	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.769549+00
489	168	8	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.769549+00
490	168	7	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.769549+00
491	169	5	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:02.803551+00
492	169	3	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.803551+00
493	169	1	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:02.803551+00
494	170	7	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.83817+00
495	170	9	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.83817+00
496	170	3	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.83817+00
497	170	6	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:02.83817+00
498	170	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:02.83817+00
499	171	2	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.87868+00
500	171	6	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:02.87868+00
501	171	5	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:02.87868+00
502	172	3	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.914663+00
503	172	1	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:02.914663+00
504	173	9	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:02.956095+00
505	174	1	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:02.989789+00
506	175	3	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.028933+00
507	175	1	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.028933+00
508	175	2	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.028933+00
509	175	7	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.028933+00
510	176	4	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.067526+00
511	176	3	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.067526+00
512	176	7	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.067526+00
513	177	5	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:03.101668+00
514	177	1	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.101668+00
515	178	7	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.136568+00
516	178	1	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.136568+00
517	178	9	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.136568+00
518	178	2	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.136568+00
519	179	6	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.176306+00
520	179	2	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.176306+00
521	180	3	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.215589+00
522	181	7	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:03.255107+00
523	181	5	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.255107+00
524	181	1	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.255107+00
525	182	4	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.289484+00
526	182	7	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.289484+00
527	182	1	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.289484+00
528	183	5	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.328407+00
529	183	9	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.328407+00
530	183	3	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.328407+00
531	183	7	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.328407+00
532	184	8	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.365937+00
533	184	7	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.365937+00
534	184	1	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.365937+00
535	185	4	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.39922+00
536	185	2	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.39922+00
537	186	3	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.435879+00
538	186	1	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.435879+00
539	187	5	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:03.474231+00
540	187	2	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.474231+00
541	187	3	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.474231+00
542	187	8	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.474231+00
543	188	6	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.513153+00
544	188	9	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.513153+00
545	188	8	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.513153+00
546	188	4	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.513153+00
547	188	5	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.513153+00
548	189	8	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.551792+00
549	190	5	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:03.585455+00
550	191	1	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.622909+00
551	191	2	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.622909+00
552	192	1	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.662721+00
553	193	1	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.696261+00
554	193	5	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:03.696261+00
555	193	7	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.696261+00
556	194	4	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.734329+00
557	194	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.734329+00
558	194	1	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.734329+00
559	195	4	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.772264+00
560	195	2	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:03.772264+00
561	195	1	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:03.772264+00
562	196	9	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.8097+00
563	197	5	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.842947+00
564	197	6	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.842947+00
565	197	7	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.842947+00
566	197	9	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.842947+00
567	197	2	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.842947+00
568	198	4	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.881974+00
569	198	8	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.881974+00
570	198	1	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.881974+00
571	198	5	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:03.881974+00
572	198	9	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:03.881974+00
573	199	7	\N	9	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:03.918855+00
574	200	2	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.956695+00
575	200	4	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:03.956695+00
576	200	3	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:03.956695+00
577	200	5	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:03.956695+00
578	200	9	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:03.956695+00
579	201	7	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:03.990465+00
580	202	4	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.027679+00
581	203	5	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.066259+00
582	204	6	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.099448+00
583	204	2	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.099448+00
584	204	8	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.099448+00
585	205	4	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:04.136066+00
586	205	3	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.136066+00
587	206	1	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.173689+00
588	206	4	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.173689+00
589	206	3	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.173689+00
590	206	5	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.173689+00
591	206	2	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.173689+00
592	207	2	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.212569+00
593	207	8	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:04.212569+00
594	207	5	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.212569+00
595	207	6	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.212569+00
596	207	9	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.212569+00
597	208	2	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.252097+00
598	209	9	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.285309+00
599	210	7	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.323004+00
600	210	8	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.323004+00
601	210	6	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.323004+00
602	210	5	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.323004+00
603	211	8	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.361579+00
604	211	2	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.361579+00
605	212	5	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.395222+00
606	212	1	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.395222+00
607	212	9	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.395222+00
608	212	2	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.395222+00
609	213	7	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.432562+00
610	213	3	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.432562+00
611	213	8	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.432562+00
612	213	5	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.432562+00
613	213	2	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.432562+00
614	214	2	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.469901+00
615	214	6	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.469901+00
616	215	2	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.508387+00
617	215	1	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.508387+00
618	215	3	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.508387+00
619	215	6	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.508387+00
620	216	6	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.542692+00
621	216	2	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.542692+00
622	216	1	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.542692+00
623	216	9	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.542692+00
624	216	7	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.542692+00
625	217	3	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.581205+00
626	217	1	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.581205+00
627	217	2	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.581205+00
628	218	3	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.619677+00
629	218	6	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.619677+00
630	219	3	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.659942+00
631	219	7	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.659942+00
632	219	5	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.659942+00
633	219	1	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.659942+00
634	220	9	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.693907+00
635	221	6	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.728876+00
636	221	4	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.728876+00
637	221	9	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:04.728876+00
638	221	8	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.728876+00
639	221	5	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.728876+00
640	222	1	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.769711+00
641	222	8	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.769711+00
642	222	3	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:04.769711+00
643	222	7	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.769711+00
644	223	8	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.80383+00
645	223	3	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.80383+00
646	224	6	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.84062+00
647	224	7	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:04.84062+00
648	224	9	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:04.84062+00
649	225	8	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:04.87872+00
650	225	5	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:04.87872+00
651	226	2	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.916995+00
652	226	5	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.916995+00
653	226	6	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:04.916995+00
654	226	3	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.916995+00
655	226	7	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:04.916995+00
656	227	5	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:04.955876+00
657	228	9	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.988914+00
658	228	1	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:04.988914+00
659	228	6	\N	9	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:04.988914+00
660	229	9	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:05.028581+00
661	229	4	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.028581+00
662	230	6	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:05.064689+00
663	230	2	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.064689+00
664	230	4	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.064689+00
665	231	9	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.098871+00
666	231	3	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:05.098871+00
667	231	4	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.098871+00
668	232	6	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.136449+00
669	232	2	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.136449+00
670	232	4	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.136449+00
671	233	1	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.176135+00
672	233	5	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.176135+00
673	233	4	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.176135+00
674	234	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.214979+00
675	234	2	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:05.214979+00
676	234	6	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.214979+00
677	234	4	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.214979+00
678	235	1	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.255298+00
679	235	7	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.255298+00
680	236	4	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.292505+00
681	236	2	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.292505+00
682	236	6	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.292505+00
683	237	6	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.329382+00
684	237	9	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.329382+00
685	238	2	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.371022+00
686	238	8	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:05.371022+00
687	239	3	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.405187+00
688	239	7	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.405187+00
689	239	9	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.405187+00
690	239	6	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.405187+00
691	240	1	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.441271+00
692	241	5	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.478676+00
693	241	7	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.478676+00
694	241	6	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.478676+00
695	242	9	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.517172+00
696	243	3	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.553767+00
697	244	3	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.586913+00
698	244	8	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:05.586913+00
699	244	7	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.586913+00
700	244	2	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.586913+00
701	244	4	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.586913+00
702	245	6	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:05.624843+00
703	245	1	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.624843+00
704	245	8	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.624843+00
705	245	5	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.624843+00
706	246	1	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.665653+00
707	246	3	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.665653+00
708	246	8	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.665653+00
709	246	7	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:05.665653+00
710	246	4	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.665653+00
711	247	7	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.700196+00
712	247	2	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.700196+00
713	248	6	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.736344+00
714	248	2	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.736344+00
715	248	4	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.736344+00
716	248	7	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.736344+00
717	248	3	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.736344+00
718	249	3	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.779039+00
719	249	1	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.779039+00
720	249	9	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.779039+00
721	249	5	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.779039+00
722	250	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.812667+00
723	251	9	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.851776+00
724	251	4	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.851776+00
725	251	5	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.851776+00
726	252	4	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.88617+00
727	252	8	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:05.88617+00
728	252	5	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.88617+00
729	252	9	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:05.88617+00
730	252	6	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:05.88617+00
731	253	4	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.927507+00
732	253	2	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:05.927507+00
733	254	9	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.965192+00
734	254	3	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:05.965192+00
735	254	8	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:05.965192+00
736	254	6	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:05.965192+00
737	254	5	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:05.965192+00
738	255	4	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:05.998922+00
739	256	2	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.036774+00
740	256	6	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:06.036774+00
741	256	8	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.036774+00
742	256	4	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:06.036774+00
743	256	5	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.036774+00
744	257	6	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.074332+00
745	257	3	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.074332+00
746	257	8	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.074332+00
747	258	4	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.112336+00
748	258	1	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.112336+00
749	258	9	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.112336+00
750	258	7	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.112336+00
751	259	8	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.149303+00
752	259	3	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:06.149303+00
753	260	4	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.18319+00
754	261	3	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:06.221571+00
755	261	2	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.221571+00
756	262	4	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.260302+00
757	262	3	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.260302+00
758	263	9	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:06.294117+00
759	263	3	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.294117+00
760	263	6	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.294117+00
761	264	7	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.330389+00
762	264	4	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.330389+00
763	264	8	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.330389+00
764	264	3	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.330389+00
765	264	5	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.330389+00
766	265	2	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:06.370395+00
767	265	1	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.370395+00
768	265	5	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.370395+00
769	265	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:06.370395+00
770	265	8	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.370395+00
771	266	1	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.407555+00
772	266	5	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.407555+00
773	266	3	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.407555+00
774	266	7	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:06.407555+00
775	267	6	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.444571+00
776	268	8	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.479483+00
777	268	7	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.479483+00
778	269	9	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.51995+00
779	269	4	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.51995+00
780	270	8	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.557369+00
781	271	2	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.59016+00
782	272	7	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.62752+00
783	272	3	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:06.62752+00
784	273	7	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.666311+00
785	273	1	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.666311+00
786	273	2	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:06.666311+00
787	273	4	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.666311+00
788	274	9	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.700159+00
789	275	6	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.735519+00
790	275	7	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.735519+00
791	275	8	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.735519+00
792	275	4	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.735519+00
793	275	1	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.735519+00
794	276	4	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.775878+00
795	276	1	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.775878+00
796	276	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:06.775878+00
797	276	8	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:06.775878+00
798	277	1	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.813558+00
799	277	8	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.813558+00
800	277	7	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.813558+00
801	277	4	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:06.813558+00
802	278	1	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.849967+00
803	278	5	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.849967+00
804	278	2	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.849967+00
805	278	7	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:06.849967+00
806	278	4	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.849967+00
807	279	7	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.883594+00
808	279	8	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:06.883594+00
809	280	2	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:06.921665+00
810	280	9	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.921665+00
811	280	3	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:06.921665+00
812	281	7	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:06.960504+00
813	281	4	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:06.960504+00
814	282	5	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:06.994177+00
815	282	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:06.994177+00
816	283	8	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.032864+00
817	284	4	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.070404+00
818	284	9	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.070404+00
819	284	7	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.070404+00
820	284	1	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.070404+00
821	284	8	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.070404+00
822	285	2	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.107538+00
823	285	1	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.107538+00
824	285	4	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.107538+00
825	286	4	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.141495+00
826	286	5	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.141495+00
827	286	1	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:07.141495+00
828	287	8	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.179166+00
829	287	7	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.179166+00
830	287	9	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.179166+00
831	288	9	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.219585+00
832	288	8	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.219585+00
833	288	2	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.219585+00
834	288	3	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.219585+00
835	289	3	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.257441+00
836	289	5	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.257441+00
837	289	4	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.257441+00
838	290	2	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.290502+00
839	290	8	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.290502+00
840	290	6	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.290502+00
841	290	3	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.290502+00
842	290	5	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.290502+00
843	291	8	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.328114+00
844	291	1	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.328114+00
845	291	7	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.328114+00
846	291	5	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.328114+00
847	291	9	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.328114+00
848	292	8	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.370494+00
849	292	7	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.370494+00
850	292	3	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.370494+00
851	293	5	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.404575+00
852	293	6	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.404575+00
853	293	3	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:07.404575+00
854	293	2	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.404575+00
855	294	8	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:07.43921+00
856	294	4	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.43921+00
857	294	9	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.43921+00
858	294	7	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.43921+00
859	294	1	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.43921+00
860	295	5	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.479324+00
861	295	8	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.479324+00
862	296	8	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.517318+00
863	296	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.517318+00
864	296	2	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.517318+00
865	296	4	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:07.517318+00
866	296	6	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.517318+00
867	297	3	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.555681+00
868	297	1	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.555681+00
869	297	4	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.555681+00
870	297	6	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.555681+00
871	297	8	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.555681+00
872	298	9	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.58974+00
873	298	3	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:07.58974+00
874	298	4	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.58974+00
875	299	7	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.628231+00
876	299	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.628231+00
877	300	3	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.666295+00
878	301	6	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.699596+00
879	301	9	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.699596+00
880	301	8	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.699596+00
881	302	9	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.735933+00
882	302	4	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.735933+00
883	302	8	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.735933+00
884	303	9	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.773818+00
885	303	6	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:07.773818+00
886	303	8	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.773818+00
887	304	3	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.813101+00
888	304	2	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.813101+00
889	304	5	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.813101+00
890	304	8	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.813101+00
891	304	6	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:07.813101+00
892	305	7	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:07.849898+00
893	305	5	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:07.849898+00
894	306	3	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.883179+00
895	306	1	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.883179+00
896	306	9	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:07.883179+00
897	306	4	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:07.883179+00
898	306	5	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.883179+00
899	307	8	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.922061+00
900	307	4	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.922061+00
901	307	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.922061+00
902	307	6	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:07.922061+00
903	307	5	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.922061+00
904	308	6	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:07.96048+00
905	308	7	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.96048+00
906	308	3	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:07.96048+00
907	308	5	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:07.96048+00
908	309	4	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:07.994456+00
909	310	8	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.034331+00
910	311	2	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.069844+00
911	311	9	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.069844+00
912	311	4	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:08.069844+00
913	312	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.109455+00
914	312	4	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.109455+00
915	312	1	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.109455+00
916	313	5	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.144577+00
917	314	5	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.182314+00
918	314	7	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.182314+00
919	314	3	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.182314+00
920	314	8	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.182314+00
921	315	5	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.221432+00
922	315	2	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.221432+00
923	315	7	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.221432+00
924	315	1	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:08.221432+00
925	316	3	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.259209+00
926	317	1	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.292646+00
927	318	3	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.330907+00
928	318	1	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.330907+00
929	319	9	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.369867+00
930	319	7	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:08.369867+00
931	320	3	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:08.404+00
932	321	2	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.439338+00
933	322	8	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.477348+00
934	322	1	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.477348+00
935	322	6	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:08.477348+00
936	323	2	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.516988+00
937	323	4	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.516988+00
938	324	1	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.555102+00
939	325	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.593297+00
940	325	8	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:08.593297+00
941	325	2	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.593297+00
942	326	1	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:08.631299+00
943	327	6	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:08.669885+00
944	327	8	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:08.669885+00
945	327	5	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:08.669885+00
946	327	2	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.669885+00
947	327	7	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.669885+00
948	328	4	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.710581+00
949	328	6	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.710581+00
950	328	8	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.710581+00
951	328	2	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:08.710581+00
952	329	3	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.746805+00
953	330	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.782989+00
954	330	4	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.782989+00
955	331	2	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:08.822934+00
956	331	4	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:08.822934+00
957	331	1	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.822934+00
958	331	3	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.822934+00
959	332	6	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:08.859774+00
960	332	7	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.859774+00
961	332	9	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:08.859774+00
962	332	4	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.859774+00
963	332	5	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.859774+00
964	333	9	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:08.893911+00
965	333	5	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:08.893911+00
966	333	2	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:08.893911+00
967	333	7	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:08.893911+00
968	334	5	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:08.933685+00
969	334	6	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:08.933685+00
970	334	1	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.933685+00
971	334	8	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:08.933685+00
972	334	7	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:08.933685+00
973	335	2	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:08.970672+00
974	336	8	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.011594+00
975	336	4	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.011594+00
976	336	9	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:09.011594+00
977	336	2	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.011594+00
978	336	6	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.011594+00
979	337	9	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.049305+00
980	337	4	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.049305+00
981	338	3	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.088279+00
982	338	4	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.088279+00
983	338	6	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.088279+00
984	339	4	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.126932+00
985	339	8	\N	9	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.126932+00
986	339	2	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.126932+00
987	339	7	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.126932+00
988	340	5	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.164856+00
989	341	8	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.199391+00
990	342	9	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.237655+00
991	342	2	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.237655+00
992	343	8	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.27448+00
993	343	1	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.27448+00
994	343	2	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.27448+00
995	343	4	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.27448+00
996	344	7	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.315284+00
997	345	3	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.349306+00
998	345	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:09.349306+00
999	345	5	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.349306+00
1000	345	1	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.349306+00
1001	345	7	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.349306+00
1002	346	8	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.387002+00
1003	347	7	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.428339+00
1004	347	4	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.428339+00
1005	347	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.428339+00
1006	347	8	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.428339+00
1007	347	2	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.428339+00
1008	348	8	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.464229+00
1009	348	3	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.464229+00
1010	348	7	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.464229+00
1011	348	6	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:09.464229+00
1012	349	8	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.499552+00
1013	349	9	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.499552+00
1014	349	4	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.499552+00
1015	350	8	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.540679+00
1016	350	1	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.540679+00
1017	350	9	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.540679+00
1018	350	7	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.540679+00
1019	351	1	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.575777+00
1020	351	6	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.575777+00
1021	352	6	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:09.618591+00
1022	352	5	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.618591+00
1023	353	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.654057+00
1024	353	9	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.654057+00
1025	353	2	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.654057+00
1026	353	6	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:09.654057+00
1027	353	7	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.654057+00
1028	354	5	\N	5	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.690798+00
1029	354	6	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.690798+00
1030	354	9	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.690798+00
1031	355	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:09.730558+00
1032	355	8	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.730558+00
1033	355	1	\N	3	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.730558+00
1034	356	9	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.771238+00
1035	357	4	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.807684+00
1036	357	1	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:09.807684+00
1037	357	2	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.807684+00
1038	358	9	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.842446+00
1039	359	6	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.878672+00
1040	360	1	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:09.919724+00
1041	360	7	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:09.919724+00
1042	360	2	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.919724+00
1043	360	9	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:09.919724+00
1044	360	5	\N	9	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.919724+00
1045	361	8	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.956352+00
1046	361	3	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:09.956352+00
1047	361	1	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.956352+00
1048	361	4	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:09.956352+00
1049	362	1	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:09.990889+00
1050	362	5	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:09.990889+00
1051	362	7	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:09.990889+00
1052	362	4	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:09.990889+00
1053	363	2	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:10.03271+00
1054	363	8	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.03271+00
1055	364	8	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:10.071274+00
1056	364	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:10.071274+00
1057	365	7	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.111049+00
1058	366	2	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:10.144176+00
1059	366	3	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:10.144176+00
1060	366	1	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.144176+00
1061	366	5	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:10.144176+00
1062	366	4	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:10.144176+00
1063	367	8	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:10.180758+00
1064	367	9	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:10.180758+00
1065	367	2	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:10.180758+00
1066	368	1	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.251147+00
1067	368	5	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:10.251147+00
1068	369	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:10.285318+00
1069	369	8	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:10.285318+00
1070	369	7	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.285318+00
1071	369	4	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:10.285318+00
1072	369	2	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.285318+00
1073	370	8	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.333378+00
1074	371	5	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.383594+00
1075	372	9	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:10.673031+00
1076	373	1	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:10.727777+00
1077	373	7	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:10.727777+00
1078	373	6	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.727777+00
1079	373	2	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:10.727777+00
1080	374	3	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.824713+00
1081	375	7	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.859827+00
1082	375	6	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:10.859827+00
1083	375	2	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:10.859827+00
1084	375	8	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:10.859827+00
1085	376	4	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:10.928498+00
1086	376	6	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:10.928498+00
1087	376	2	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:10.928498+00
1088	377	7	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:10.981862+00
1089	378	7	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.03721+00
1090	378	4	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.03721+00
1091	378	1	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.03721+00
1092	379	9	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.07067+00
1093	379	4	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.07067+00
1094	379	6	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.07067+00
1095	380	3	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.114+00
1096	380	4	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.114+00
1097	380	5	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:11.114+00
1098	380	2	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.114+00
1099	380	1	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.114+00
1100	381	4	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:11.148104+00
1101	382	1	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.180979+00
1102	383	5	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.224986+00
1103	383	7	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.224986+00
1104	383	1	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:11.224986+00
1105	384	6	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.258932+00
1106	384	5	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.258932+00
1107	384	2	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.258932+00
1108	384	9	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:11.258932+00
1109	385	1	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.29304+00
1110	386	2	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.333836+00
1111	386	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.333836+00
1112	387	2	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.370864+00
1113	388	8	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.404321+00
1114	388	4	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:11.404321+00
1115	389	3	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.443607+00
1116	389	2	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.443607+00
1117	389	6	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:11.443607+00
1118	389	5	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.443607+00
1119	389	1	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.443607+00
1120	390	7	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.480715+00
1121	391	3	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.520932+00
1122	391	6	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.520932+00
1123	391	5	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.520932+00
1124	391	2	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:11.520932+00
1125	392	2	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.556571+00
1126	392	1	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.556571+00
1127	392	8	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.556571+00
1128	393	7	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.590217+00
1129	393	2	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.590217+00
1130	394	3	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.628354+00
1131	394	2	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.628354+00
1132	394	6	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.628354+00
1133	394	9	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.628354+00
1134	394	4	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.628354+00
1135	395	6	\N	4	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.671173+00
1136	396	2	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.704293+00
1137	397	2	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.740229+00
1138	397	7	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:11.740229+00
1139	397	9	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:11.740229+00
1140	397	4	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.740229+00
1141	397	5	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.740229+00
1142	398	5	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.77855+00
1143	399	6	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.817921+00
1144	399	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:11.817921+00
1145	399	4	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.817921+00
1146	399	5	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:11.817921+00
1147	400	5	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:11.85401+00
1148	401	3	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:11.886814+00
1149	402	4	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.928839+00
1150	402	5	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.928839+00
1151	402	3	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:11.928839+00
1152	402	9	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:11.928839+00
1153	402	2	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:11.928839+00
1154	403	1	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.963048+00
1155	403	2	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.963048+00
1156	404	1	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:11.996559+00
1157	404	5	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:11.996559+00
1158	404	2	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:11.996559+00
1159	404	9	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:11.996559+00
1160	405	9	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.037479+00
1161	405	6	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.037479+00
1162	405	4	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.037479+00
1163	406	5	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.072922+00
1164	406	9	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.072922+00
1165	406	2	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.072922+00
1166	406	7	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.072922+00
1167	407	7	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.114868+00
1168	407	5	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.114868+00
1169	408	6	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.149339+00
1170	408	4	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.149339+00
1171	408	1	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.149339+00
1172	408	9	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.149339+00
1173	408	3	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:12.149339+00
1174	409	4	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.183493+00
1175	409	5	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.183493+00
1176	409	6	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.183493+00
1177	409	7	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.183493+00
1178	410	2	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.228946+00
1179	411	4	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.265383+00
1180	411	5	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.265383+00
1181	411	2	\N	6	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:12.265383+00
1182	411	6	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.265383+00
1183	411	1	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.265383+00
1184	412	1	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.301989+00
1185	412	6	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.301989+00
1186	413	6	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.341921+00
1187	413	1	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.341921+00
1188	414	8	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.37687+00
1189	415	4	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.417765+00
1190	415	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.417765+00
1191	416	9	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:12.453119+00
1192	416	8	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.453119+00
1193	416	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.453119+00
1194	417	2	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.487437+00
1195	417	3	\N	6	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.487437+00
1196	418	8	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.529076+00
1197	419	8	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.563588+00
1198	419	4	\N	10	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:12.563588+00
1199	419	1	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.563588+00
1200	419	2	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.563588+00
1201	420	4	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.597478+00
1202	420	8	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.597478+00
1203	420	3	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.597478+00
1204	420	5	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.597478+00
1205	421	8	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.635668+00
1206	421	9	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:12.635668+00
1207	422	7	\N	10	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.673554+00
1208	422	8	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.673554+00
1209	422	2	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.673554+00
1210	422	3	\N	9	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.673554+00
1211	423	2	\N	2	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.712839+00
1212	423	6	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:12.712839+00
1213	423	3	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.712839+00
1214	423	7	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:12.712839+00
1215	423	5	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.712839+00
1216	424	5	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.750688+00
1217	424	1	\N	10	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.750688+00
1218	424	6	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:12.750688+00
1219	425	2	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.791961+00
1220	426	6	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.828227+00
1221	426	7	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:12.828227+00
1222	426	9	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.828227+00
1223	427	9	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.86238+00
1224	427	1	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:12.86238+00
1225	428	3	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:12.896724+00
1226	428	7	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.896724+00
1227	428	9	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.896724+00
1228	428	5	\N	1	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:12.896724+00
1229	428	8	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:12.896724+00
1230	429	2	\N	9	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:12.937087+00
1231	430	2	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:12.970189+00
1232	430	4	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:12.970189+00
1233	430	1	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:12.970189+00
1234	431	5	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.011399+00
1235	431	4	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.011399+00
1236	431	6	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.011399+00
1237	431	9	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.011399+00
1238	432	7	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.045816+00
1239	432	8	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.045816+00
1240	432	2	\N	1	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.045816+00
1241	433	5	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.08186+00
1242	434	9	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.122829+00
1243	434	3	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.122829+00
1244	434	4	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.122829+00
1245	435	6	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.156683+00
1246	435	2	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.156683+00
1247	435	1	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:13.156683+00
1248	435	9	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.156683+00
1249	435	8	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.156683+00
1250	436	5	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.190734+00
1251	436	8	\N	10	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.190734+00
1252	436	3	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.190734+00
1253	436	9	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.190734+00
1254	437	3	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.233495+00
1255	437	4	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.233495+00
1256	437	6	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.233495+00
1257	437	2	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.233495+00
1258	438	3	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.270634+00
1259	438	4	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.270634+00
1260	439	9	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:13.312668+00
1261	439	7	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.312668+00
1262	439	3	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.312668+00
1263	439	5	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.312668+00
1264	439	2	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.312668+00
1265	440	9	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.346934+00
1266	440	8	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.346934+00
1267	440	2	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.346934+00
1268	440	4	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:13.346934+00
1269	440	6	\N	7	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.346934+00
1270	441	3	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.381568+00
1271	442	7	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.422853+00
1272	442	4	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.422853+00
1273	443	4	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.457116+00
1274	443	7	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.457116+00
1275	443	2	\N	4	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:13.457116+00
1276	443	9	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.457116+00
1277	443	8	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.457116+00
1278	444	2	\N	9	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.491477+00
1279	444	8	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.491477+00
1280	445	6	\N	3	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.534364+00
1281	445	7	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.534364+00
1282	445	2	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.534364+00
1283	446	4	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:13.570108+00
1284	447	3	\N	7	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.608135+00
1285	447	5	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.608135+00
1286	447	6	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.608135+00
1287	448	3	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.64189+00
1288	448	4	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.64189+00
1289	448	1	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.64189+00
1290	448	2	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.64189+00
1291	448	6	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.64189+00
1292	449	5	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.678309+00
1293	450	5	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.719529+00
1294	450	3	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.719529+00
1295	450	9	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:13.719529+00
1296	451	2	\N	3	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.755188+00
1297	451	4	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.755188+00
1298	451	6	\N	3	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.755188+00
1299	451	9	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.755188+00
1300	452	6	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.789955+00
1301	452	7	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.789955+00
1302	452	4	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:13.789955+00
1303	452	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.789955+00
1304	453	5	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.828533+00
1305	454	9	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.865172+00
1306	454	3	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:13.865172+00
1307	454	6	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:13.865172+00
1308	454	4	\N	4	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.865172+00
1309	454	7	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:13.865172+00
1310	455	3	\N	4	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.899214+00
1311	455	7	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:13.899214+00
1312	456	9	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.936944+00
1313	456	4	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:13.936944+00
1314	457	7	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.972996+00
1315	457	2	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:13.972996+00
1316	457	5	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:13.972996+00
1317	457	1	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:13.972996+00
1318	457	8	\N	7	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:13.972996+00
1319	458	3	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.015422+00
1320	458	1	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.015422+00
1321	458	6	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.015422+00
1322	459	7	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.052387+00
1323	459	6	\N	1	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.052387+00
1324	459	4	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.052387+00
1325	459	5	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.052387+00
1326	460	3	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.086617+00
1327	460	5	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.086617+00
1328	460	8	\N	7	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.086617+00
1329	460	2	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.086617+00
1330	460	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.086617+00
1331	461	4	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.127098+00
1332	461	5	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:14.127098+00
1333	461	9	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.127098+00
1334	461	2	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.127098+00
1335	462	7	\N	7	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.164444+00
1336	462	2	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:14.164444+00
1337	462	8	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.164444+00
1338	463	3	\N	6	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.198866+00
1339	464	8	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.236352+00
1340	465	3	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:14.27361+00
1341	465	6	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.27361+00
1342	465	2	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.27361+00
1343	466	7	\N	8	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.314293+00
1344	467	9	\N	6	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.349468+00
1345	468	8	\N	10	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.383291+00
1346	469	2	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.424577+00
1347	469	8	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.424577+00
1348	469	7	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.424577+00
1349	470	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.459793+00
1350	470	3	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:14.459793+00
1351	471	4	\N	9	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.493348+00
1352	471	7	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.493348+00
1353	471	1	\N	10	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:14.493348+00
1354	471	9	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.493348+00
1355	471	2	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.493348+00
1356	472	9	\N	1	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.534044+00
1357	473	1	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:14.570163+00
1358	473	7	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.570163+00
1359	474	7	\N	10	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.607627+00
1360	475	8	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.641002+00
1361	475	2	\N	4	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.641002+00
1362	476	9	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.679683+00
1363	476	2	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.679683+00
1364	476	6	\N	3	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.679683+00
1365	476	7	\N	7	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.679683+00
1366	476	4	\N	1	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:14.679683+00
1367	477	7	\N	2	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.720316+00
1368	477	2	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.720316+00
1369	477	4	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:14.720316+00
1370	478	8	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.755902+00
1371	478	1	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:14.755902+00
1372	478	9	\N	2	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.755902+00
1373	479	2	\N	5	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.789922+00
1374	479	9	\N	2	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.789922+00
1375	480	8	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:14.82861+00
1376	480	7	\N	5	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:14.82861+00
1377	480	4	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.82861+00
1378	480	2	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:14.82861+00
1379	481	1	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.869998+00
1380	482	9	\N	5	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.903432+00
1381	482	3	\N	6	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.903432+00
1382	483	7	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.937044+00
1383	483	3	\N	1	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:14.937044+00
1384	483	4	\N	4	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.937044+00
1385	483	2	\N	7	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:14.937044+00
1386	484	1	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:14.97851+00
1387	484	7	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:14.97851+00
1388	484	8	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.97851+00
1389	484	3	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:14.97851+00
1390	485	7	\N	1	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.016939+00
1391	485	3	\N	9	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.016939+00
1392	486	1	\N	8	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.056902+00
1393	486	5	\N	5	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.056902+00
1394	486	3	\N	9	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.056902+00
1395	486	7	\N	8	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:15.056902+00
1396	486	2	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.056902+00
1397	487	4	\N	6	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.091512+00
1398	487	5	\N	3	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.091512+00
1399	487	7	\N	6	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.091512+00
1400	487	9	\N	8	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.091512+00
1401	488	2	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.129185+00
1402	489	8	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.169858+00
1403	489	5	\N	8	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:15.169858+00
1404	490	6	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.204135+00
1405	490	7	\N	2	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.204135+00
1406	490	3	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:15.204135+00
1407	490	9	\N	3	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.204135+00
1408	490	8	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.204135+00
1409	491	8	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:15.239005+00
1410	491	4	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.239005+00
1411	491	7	\N	1	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.239005+00
1412	491	5	\N	6	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:15.239005+00
1413	492	3	\N	1	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.280169+00
1414	492	2	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.280169+00
1415	492	6	\N	2	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.280169+00
1416	492	1	\N	1	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.280169+00
1417	492	9	\N	2	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:15.280169+00
1418	493	8	\N	6	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.3176+00
1419	493	9	\N	5	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:15.3176+00
1420	493	2	\N	3	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.3176+00
1421	493	4	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.3176+00
1422	493	7	\N	7	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.3176+00
1423	494	3	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.359609+00
1424	494	9	\N	9	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:15.359609+00
1425	494	8	\N	10	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.359609+00
1426	494	5	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.359609+00
1427	494	2	\N	10	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:15.359609+00
1428	495	8	\N	8	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.393718+00
1429	495	9	\N	8	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:15.393718+00
1430	495	2	\N	4	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.393718+00
1431	496	5	\N	3	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:15.428115+00
1432	496	2	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.428115+00
1433	496	1	\N	6	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:15.428115+00
1434	496	9	\N	9	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.428115+00
1435	496	6	\N	9	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.428115+00
1436	497	2	\N	2	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.46964+00
1437	497	8	\N	9	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.46964+00
1438	497	9	\N	4	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:15.46964+00
1439	497	1	\N	4	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.46964+00
1440	497	3	\N	5	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.46964+00
1441	498	4	\N	5	0	0	\N	7	PENDING_DISPATCH	\N	2026-03-15 18:13:15.503835+00
1442	498	9	\N	8	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.503835+00
1443	499	3	\N	8	0	0	\N	6	PENDING_DISPATCH	\N	2026-03-15 18:13:15.538016+00
1444	499	7	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.538016+00
1445	500	9	\N	2	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.579237+00
1446	500	2	\N	7	0	0	\N	4	PENDING_DISPATCH	\N	2026-03-15 18:13:15.579237+00
1447	500	4	\N	5	0	0	\N	2	PENDING_DISPATCH	\N	2026-03-15 18:13:15.579237+00
1448	501	8	\N	8	0	0	\N	8	PENDING_DISPATCH	\N	2026-03-15 18:13:15.61494+00
1449	501	1	\N	7	0	0	\N	3	PENDING_DISPATCH	\N	2026-03-15 18:13:15.61494+00
1450	501	3	\N	5	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.61494+00
1451	501	7	\N	3	0	0	\N	1	PENDING_DISPATCH	\N	2026-03-15 18:13:15.61494+00
1452	502	2	\N	2	0	0	\N	10	PENDING_DISPATCH	\N	2026-03-15 18:13:15.656654+00
1453	502	8	\N	10	0	0	\N	5	PENDING_DISPATCH	\N	2026-03-15 18:13:15.656654+00
1454	502	6	\N	4	0	0	\N	9	PENDING_DISPATCH	\N	2026-03-15 18:13:15.656654+00
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orders (id, order_number, order_type, original_order_id, return_reason, patient_id, ipd_id, ordering_department_id, priority, status, notes, created_by, created_at, completed_by, completed_at, cancelled_by, cancelled_at, cancellation_reason) FROM stdin;
1	LAB-20260315175654	REGULAR	\N	\N	1	1	2	NORMAL	COMPLETED	\N	1	2026-03-15 17:56:54.284342+00	\N	2026-03-15 17:56:54.327543+00	\N	\N	\N
2	PHR-20260315175655	REGULAR	\N	\N	1	1	2	NORMAL	COMPLETED	\N	1	2026-03-15 17:56:55.24981+00	\N	2026-03-15 17:56:55.291003+00	\N	\N	\N
3	ST-20260315-00001	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.541123+00	\N	\N	\N	\N	\N
4	ST-20260315-00002	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.618263+00	\N	\N	\N	\N	\N
5	ST-20260315-00003	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.653188+00	\N	\N	\N	\N	\N
6	ST-20260315-00004	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.687402+00	\N	\N	\N	\N	\N
7	ST-20260315-00005	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.734253+00	\N	\N	\N	\N	\N
8	ST-20260315-00006	REGULAR	\N	\N	2	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.767877+00	\N	\N	\N	\N	\N
9	ST-20260315-00007	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.809069+00	\N	\N	\N	\N	\N
10	ST-20260315-00008	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:55.842319+00	\N	\N	\N	\N	\N
11	ST-20260315-00009	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.875504+00	\N	\N	\N	\N	\N
12	ST-20260315-00010	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.917458+00	\N	\N	\N	\N	\N
13	ST-20260315-00011	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.952238+00	\N	\N	\N	\N	\N
14	ST-20260315-00012	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:55.985418+00	\N	\N	\N	\N	\N
15	ST-20260315-00013	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.02905+00	\N	\N	\N	\N	\N
16	ST-20260315-00014	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.063104+00	\N	\N	\N	\N	\N
17	ST-20260315-00015	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.097234+00	\N	\N	\N	\N	\N
18	ST-20260315-00016	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.137306+00	\N	\N	\N	\N	\N
19	ST-20260315-00017	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.173036+00	\N	\N	\N	\N	\N
20	ST-20260315-00018	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.215526+00	\N	\N	\N	\N	\N
21	ST-20260315-00019	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.250835+00	\N	\N	\N	\N	\N
22	ST-20260315-00020	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.285166+00	\N	\N	\N	\N	\N
23	ST-20260315-00021	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.354047+00	\N	\N	\N	\N	\N
24	ST-20260315-00022	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.454523+00	\N	\N	\N	\N	\N
25	ST-20260315-00023	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.540118+00	\N	\N	\N	\N	\N
26	ST-20260315-00024	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:56.659446+00	\N	\N	\N	\N	\N
27	ST-20260315-00025	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.010129+00	\N	\N	\N	\N	\N
28	ST-20260315-00026	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:57.249448+00	\N	\N	\N	\N	\N
29	ST-20260315-00027	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.458928+00	\N	\N	\N	\N	\N
30	ST-20260315-00028	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.576816+00	\N	\N	\N	\N	\N
31	ST-20260315-00029	REGULAR	\N	\N	1	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:57.614386+00	\N	\N	\N	\N	\N
32	ST-20260315-00030	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.655582+00	\N	\N	\N	\N	\N
33	ST-20260315-00031	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.688776+00	\N	\N	\N	\N	\N
34	ST-20260315-00032	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:57.725496+00	\N	\N	\N	\N	\N
35	ST-20260315-00033	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.77033+00	\N	\N	\N	\N	\N
36	ST-20260315-00034	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.80485+00	\N	\N	\N	\N	\N
37	ST-20260315-00035	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.838172+00	\N	\N	\N	\N	\N
38	ST-20260315-00036	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:57.878374+00	\N	\N	\N	\N	\N
39	ST-20260315-00037	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.912619+00	\N	\N	\N	\N	\N
40	ST-20260315-00038	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:57.955931+00	\N	\N	\N	\N	\N
41	ST-20260315-00039	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:57.989968+00	\N	\N	\N	\N	\N
42	ST-20260315-00040	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.033658+00	\N	\N	\N	\N	\N
43	ST-20260315-00041	REGULAR	\N	\N	2	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.075927+00	\N	\N	\N	\N	\N
44	ST-20260315-00042	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.109766+00	\N	\N	\N	\N	\N
45	ST-20260315-00043	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.152341+00	\N	\N	\N	\N	\N
46	ST-20260315-00044	REGULAR	\N	\N	2	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.186603+00	\N	\N	\N	\N	\N
47	ST-20260315-00045	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.220981+00	\N	\N	\N	\N	\N
48	ST-20260315-00046	REGULAR	\N	\N	1	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.263851+00	\N	\N	\N	\N	\N
49	ST-20260315-00047	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.297918+00	\N	\N	\N	\N	\N
50	ST-20260315-00048	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.331981+00	\N	\N	\N	\N	\N
51	ST-20260315-00049	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.373712+00	\N	\N	\N	\N	\N
52	ST-20260315-00050	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.407691+00	\N	\N	\N	\N	\N
53	ST-20260315-00051	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.440536+00	\N	\N	\N	\N	\N
54	ST-20260315-00052	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.482866+00	\N	\N	\N	\N	\N
55	ST-20260315-00053	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.517005+00	\N	\N	\N	\N	\N
56	ST-20260315-00054	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.558064+00	\N	\N	\N	\N	\N
57	ST-20260315-00055	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.594313+00	\N	\N	\N	\N	\N
58	ST-20260315-00056	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.631013+00	\N	\N	\N	\N	\N
59	ST-20260315-00057	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:58.671445+00	\N	\N	\N	\N	\N
60	ST-20260315-00058	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.709324+00	\N	\N	\N	\N	\N
61	ST-20260315-00059	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.749319+00	\N	\N	\N	\N	\N
62	ST-20260315-00060	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.784707+00	\N	\N	\N	\N	\N
63	ST-20260315-00061	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.821241+00	\N	\N	\N	\N	\N
64	ST-20260315-00062	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.861689+00	\N	\N	\N	\N	\N
65	ST-20260315-00063	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.896128+00	\N	\N	\N	\N	\N
66	ST-20260315-00064	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.9305+00	\N	\N	\N	\N	\N
67	ST-20260315-00065	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:58.970942+00	\N	\N	\N	\N	\N
68	ST-20260315-00066	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.009464+00	\N	\N	\N	\N	\N
69	ST-20260315-00067	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.043839+00	\N	\N	\N	\N	\N
70	ST-20260315-00068	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.084138+00	\N	\N	\N	\N	\N
71	ST-20260315-00069	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.120358+00	\N	\N	\N	\N	\N
72	ST-20260315-00070	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.161765+00	\N	\N	\N	\N	\N
73	ST-20260315-00071	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.196841+00	\N	\N	\N	\N	\N
74	ST-20260315-00072	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.23538+00	\N	\N	\N	\N	\N
75	ST-20260315-00073	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.274728+00	\N	\N	\N	\N	\N
76	ST-20260315-00074	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.313582+00	\N	\N	\N	\N	\N
77	ST-20260315-00075	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.354645+00	\N	\N	\N	\N	\N
78	ST-20260315-00076	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.389878+00	\N	\N	\N	\N	\N
79	ST-20260315-00077	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.426258+00	\N	\N	\N	\N	\N
80	ST-20260315-00078	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.46967+00	\N	\N	\N	\N	\N
81	ST-20260315-00079	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.50359+00	\N	\N	\N	\N	\N
82	ST-20260315-00080	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.537274+00	\N	\N	\N	\N	\N
83	ST-20260315-00081	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.577081+00	\N	\N	\N	\N	\N
84	ST-20260315-00082	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.612405+00	\N	\N	\N	\N	\N
85	ST-20260315-00083	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.65452+00	\N	\N	\N	\N	\N
86	ST-20260315-00084	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.690132+00	\N	\N	\N	\N	\N
87	ST-20260315-00085	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.731166+00	\N	\N	\N	\N	\N
88	ST-20260315-00086	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.771082+00	\N	\N	\N	\N	\N
89	ST-20260315-00087	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.805724+00	\N	\N	\N	\N	\N
90	ST-20260315-00088	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.840639+00	\N	\N	\N	\N	\N
91	ST-20260315-00089	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.878776+00	\N	\N	\N	\N	\N
92	ST-20260315-00090	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.915476+00	\N	\N	\N	\N	\N
93	ST-20260315-00091	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:12:59.95655+00	\N	\N	\N	\N	\N
94	ST-20260315-00092	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:12:59.991157+00	\N	\N	\N	\N	\N
95	ST-20260315-00093	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.035842+00	\N	\N	\N	\N	\N
96	ST-20260315-00094	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.070671+00	\N	\N	\N	\N	\N
97	ST-20260315-00095	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.103563+00	\N	\N	\N	\N	\N
98	ST-20260315-00096	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.140449+00	\N	\N	\N	\N	\N
99	ST-20260315-00097	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.18403+00	\N	\N	\N	\N	\N
100	ST-20260315-00098	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.228025+00	\N	\N	\N	\N	\N
101	ST-20260315-00099	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.269091+00	\N	\N	\N	\N	\N
102	ST-20260315-00100	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.302817+00	\N	\N	\N	\N	\N
103	ST-20260315-00101	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.338981+00	\N	\N	\N	\N	\N
104	ST-20260315-00102	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.375929+00	\N	\N	\N	\N	\N
105	ST-20260315-00103	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.415713+00	\N	\N	\N	\N	\N
106	ST-20260315-00104	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.456247+00	\N	\N	\N	\N	\N
107	ST-20260315-00105	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.489678+00	\N	\N	\N	\N	\N
108	ST-20260315-00106	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.528853+00	\N	\N	\N	\N	\N
109	ST-20260315-00107	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.56581+00	\N	\N	\N	\N	\N
110	ST-20260315-00108	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.600097+00	\N	\N	\N	\N	\N
111	ST-20260315-00109	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.635883+00	\N	\N	\N	\N	\N
112	ST-20260315-00110	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.677292+00	\N	\N	\N	\N	\N
113	ST-20260315-00111	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.715434+00	\N	\N	\N	\N	\N
114	ST-20260315-00112	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.753049+00	\N	\N	\N	\N	\N
115	ST-20260315-00113	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.787838+00	\N	\N	\N	\N	\N
116	ST-20260315-00114	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.827281+00	\N	\N	\N	\N	\N
117	ST-20260315-00115	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.862892+00	\N	\N	\N	\N	\N
118	ST-20260315-00116	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:00.896211+00	\N	\N	\N	\N	\N
119	ST-20260315-00117	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.932886+00	\N	\N	\N	\N	\N
120	ST-20260315-00118	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:00.972634+00	\N	\N	\N	\N	\N
121	ST-20260315-00119	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.011213+00	\N	\N	\N	\N	\N
122	ST-20260315-00120	REGULAR	\N	\N	1	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.0445+00	\N	\N	\N	\N	\N
123	ST-20260315-00121	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.084197+00	\N	\N	\N	\N	\N
124	ST-20260315-00122	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.123982+00	\N	\N	\N	\N	\N
125	ST-20260315-00123	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.160486+00	\N	\N	\N	\N	\N
126	ST-20260315-00124	REGULAR	\N	\N	1	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.194343+00	\N	\N	\N	\N	\N
127	ST-20260315-00125	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.23473+00	\N	\N	\N	\N	\N
128	ST-20260315-00126	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.27077+00	\N	\N	\N	\N	\N
129	ST-20260315-00127	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.31085+00	\N	\N	\N	\N	\N
130	ST-20260315-00128	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.344878+00	\N	\N	\N	\N	\N
131	ST-20260315-00129	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.380731+00	\N	\N	\N	\N	\N
132	ST-20260315-00130	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.422332+00	\N	\N	\N	\N	\N
133	ST-20260315-00131	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.460395+00	\N	\N	\N	\N	\N
134	ST-20260315-00132	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.494861+00	\N	\N	\N	\N	\N
135	ST-20260315-00133	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.533561+00	\N	\N	\N	\N	\N
136	ST-20260315-00134	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.57029+00	\N	\N	\N	\N	\N
137	ST-20260315-00135	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.609093+00	\N	\N	\N	\N	\N
138	ST-20260315-00136	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.643159+00	\N	\N	\N	\N	\N
139	ST-20260315-00137	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.679927+00	\N	\N	\N	\N	\N
140	ST-20260315-00138	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.721773+00	\N	\N	\N	\N	\N
141	ST-20260315-00139	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.757372+00	\N	\N	\N	\N	\N
142	ST-20260315-00140	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.791653+00	\N	\N	\N	\N	\N
143	ST-20260315-00141	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:01.82861+00	\N	\N	\N	\N	\N
144	ST-20260315-00142	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.870623+00	\N	\N	\N	\N	\N
145	ST-20260315-00143	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.905494+00	\N	\N	\N	\N	\N
146	ST-20260315-00144	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.941018+00	\N	\N	\N	\N	\N
147	ST-20260315-00145	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:01.98029+00	\N	\N	\N	\N	\N
148	ST-20260315-00146	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.01806+00	\N	\N	\N	\N	\N
149	ST-20260315-00147	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.057843+00	\N	\N	\N	\N	\N
150	ST-20260315-00148	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.0912+00	\N	\N	\N	\N	\N
151	ST-20260315-00149	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.128422+00	\N	\N	\N	\N	\N
152	ST-20260315-00150	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.169548+00	\N	\N	\N	\N	\N
153	ST-20260315-00151	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.204251+00	\N	\N	\N	\N	\N
154	ST-20260315-00152	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.23934+00	\N	\N	\N	\N	\N
155	ST-20260315-00153	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.2811+00	\N	\N	\N	\N	\N
156	ST-20260315-00154	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.316371+00	\N	\N	\N	\N	\N
157	ST-20260315-00155	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.357303+00	\N	\N	\N	\N	\N
158	ST-20260315-00156	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.39083+00	\N	\N	\N	\N	\N
159	ST-20260315-00157	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.428889+00	\N	\N	\N	\N	\N
160	ST-20260315-00158	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.470551+00	\N	\N	\N	\N	\N
161	ST-20260315-00159	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.504781+00	\N	\N	\N	\N	\N
162	ST-20260315-00160	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.53892+00	\N	\N	\N	\N	\N
163	ST-20260315-00161	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.578812+00	\N	\N	\N	\N	\N
164	ST-20260315-00162	REGULAR	\N	\N	1	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.614987+00	\N	\N	\N	\N	\N
165	ST-20260315-00163	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.656157+00	\N	\N	\N	\N	\N
166	ST-20260315-00164	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.689395+00	\N	\N	\N	\N	\N
167	ST-20260315-00165	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.728686+00	\N	\N	\N	\N	\N
168	ST-20260315-00166	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.769549+00	\N	\N	\N	\N	\N
169	ST-20260315-00167	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.803551+00	\N	\N	\N	\N	\N
170	ST-20260315-00168	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.83817+00	\N	\N	\N	\N	\N
171	ST-20260315-00169	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.87868+00	\N	\N	\N	\N	\N
172	ST-20260315-00170	REGULAR	\N	\N	2	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.914663+00	\N	\N	\N	\N	\N
173	ST-20260315-00171	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:02.956095+00	\N	\N	\N	\N	\N
174	ST-20260315-00172	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:02.989789+00	\N	\N	\N	\N	\N
175	ST-20260315-00173	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.028933+00	\N	\N	\N	\N	\N
176	ST-20260315-00174	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.067526+00	\N	\N	\N	\N	\N
177	ST-20260315-00175	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.101668+00	\N	\N	\N	\N	\N
178	ST-20260315-00176	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.136568+00	\N	\N	\N	\N	\N
179	ST-20260315-00177	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.176306+00	\N	\N	\N	\N	\N
180	ST-20260315-00178	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.215589+00	\N	\N	\N	\N	\N
181	ST-20260315-00179	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.255107+00	\N	\N	\N	\N	\N
182	ST-20260315-00180	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.289484+00	\N	\N	\N	\N	\N
183	ST-20260315-00181	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.328407+00	\N	\N	\N	\N	\N
184	ST-20260315-00182	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.365937+00	\N	\N	\N	\N	\N
185	ST-20260315-00183	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.39922+00	\N	\N	\N	\N	\N
186	ST-20260315-00184	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.435879+00	\N	\N	\N	\N	\N
187	ST-20260315-00185	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.474231+00	\N	\N	\N	\N	\N
188	ST-20260315-00186	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.513153+00	\N	\N	\N	\N	\N
189	ST-20260315-00187	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.551792+00	\N	\N	\N	\N	\N
190	ST-20260315-00188	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.585455+00	\N	\N	\N	\N	\N
191	ST-20260315-00189	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.622909+00	\N	\N	\N	\N	\N
192	ST-20260315-00190	REGULAR	\N	\N	1	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.662721+00	\N	\N	\N	\N	\N
193	ST-20260315-00191	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.696261+00	\N	\N	\N	\N	\N
194	ST-20260315-00192	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.734329+00	\N	\N	\N	\N	\N
195	ST-20260315-00193	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.772264+00	\N	\N	\N	\N	\N
196	ST-20260315-00194	REGULAR	\N	\N	2	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:03.8097+00	\N	\N	\N	\N	\N
197	ST-20260315-00195	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.842947+00	\N	\N	\N	\N	\N
198	ST-20260315-00196	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.881974+00	\N	\N	\N	\N	\N
199	ST-20260315-00197	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.918855+00	\N	\N	\N	\N	\N
200	ST-20260315-00198	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.956695+00	\N	\N	\N	\N	\N
201	ST-20260315-00199	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:03.990465+00	\N	\N	\N	\N	\N
202	ST-20260315-00200	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.027679+00	\N	\N	\N	\N	\N
203	ST-20260315-00201	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.066259+00	\N	\N	\N	\N	\N
204	ST-20260315-00202	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:04.099448+00	\N	\N	\N	\N	\N
205	ST-20260315-00203	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:04.136066+00	\N	\N	\N	\N	\N
206	ST-20260315-00204	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.173689+00	\N	\N	\N	\N	\N
207	ST-20260315-00205	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:04.212569+00	\N	\N	\N	\N	\N
208	ST-20260315-00206	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.252097+00	\N	\N	\N	\N	\N
209	ST-20260315-00207	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.285309+00	\N	\N	\N	\N	\N
210	ST-20260315-00208	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.323004+00	\N	\N	\N	\N	\N
211	ST-20260315-00209	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.361579+00	\N	\N	\N	\N	\N
212	ST-20260315-00210	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:04.395222+00	\N	\N	\N	\N	\N
213	ST-20260315-00211	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.432562+00	\N	\N	\N	\N	\N
214	ST-20260315-00212	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:04.469901+00	\N	\N	\N	\N	\N
215	ST-20260315-00213	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.508387+00	\N	\N	\N	\N	\N
216	ST-20260315-00214	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.542692+00	\N	\N	\N	\N	\N
217	ST-20260315-00215	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.581205+00	\N	\N	\N	\N	\N
218	ST-20260315-00216	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.619677+00	\N	\N	\N	\N	\N
219	ST-20260315-00217	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.659942+00	\N	\N	\N	\N	\N
220	ST-20260315-00218	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.693907+00	\N	\N	\N	\N	\N
221	ST-20260315-00219	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.728876+00	\N	\N	\N	\N	\N
222	ST-20260315-00220	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.769711+00	\N	\N	\N	\N	\N
223	ST-20260315-00221	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.80383+00	\N	\N	\N	\N	\N
224	ST-20260315-00222	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.84062+00	\N	\N	\N	\N	\N
225	ST-20260315-00223	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.87872+00	\N	\N	\N	\N	\N
226	ST-20260315-00224	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.916995+00	\N	\N	\N	\N	\N
227	ST-20260315-00225	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.955876+00	\N	\N	\N	\N	\N
228	ST-20260315-00226	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:04.988914+00	\N	\N	\N	\N	\N
229	ST-20260315-00227	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.028581+00	\N	\N	\N	\N	\N
230	ST-20260315-00228	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.064689+00	\N	\N	\N	\N	\N
231	ST-20260315-00229	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.098871+00	\N	\N	\N	\N	\N
232	ST-20260315-00230	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.136449+00	\N	\N	\N	\N	\N
233	ST-20260315-00231	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.176135+00	\N	\N	\N	\N	\N
234	ST-20260315-00232	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.214979+00	\N	\N	\N	\N	\N
235	ST-20260315-00233	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.255298+00	\N	\N	\N	\N	\N
236	ST-20260315-00234	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.292505+00	\N	\N	\N	\N	\N
237	ST-20260315-00235	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.329382+00	\N	\N	\N	\N	\N
238	ST-20260315-00236	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.371022+00	\N	\N	\N	\N	\N
239	ST-20260315-00237	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.405187+00	\N	\N	\N	\N	\N
240	ST-20260315-00238	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.441271+00	\N	\N	\N	\N	\N
241	ST-20260315-00239	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.478676+00	\N	\N	\N	\N	\N
242	ST-20260315-00240	REGULAR	\N	\N	2	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.517172+00	\N	\N	\N	\N	\N
243	ST-20260315-00241	REGULAR	\N	\N	2	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.553767+00	\N	\N	\N	\N	\N
244	ST-20260315-00242	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.586913+00	\N	\N	\N	\N	\N
245	ST-20260315-00243	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.624843+00	\N	\N	\N	\N	\N
246	ST-20260315-00244	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.665653+00	\N	\N	\N	\N	\N
247	ST-20260315-00245	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.700196+00	\N	\N	\N	\N	\N
248	ST-20260315-00246	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:05.736344+00	\N	\N	\N	\N	\N
249	ST-20260315-00247	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.779039+00	\N	\N	\N	\N	\N
250	ST-20260315-00248	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.812667+00	\N	\N	\N	\N	\N
251	ST-20260315-00249	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.851776+00	\N	\N	\N	\N	\N
252	ST-20260315-00250	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.88617+00	\N	\N	\N	\N	\N
253	ST-20260315-00251	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.927507+00	\N	\N	\N	\N	\N
254	ST-20260315-00252	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.965192+00	\N	\N	\N	\N	\N
255	ST-20260315-00253	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:05.998922+00	\N	\N	\N	\N	\N
256	ST-20260315-00254	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.036774+00	\N	\N	\N	\N	\N
257	ST-20260315-00255	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.074332+00	\N	\N	\N	\N	\N
258	ST-20260315-00256	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.112336+00	\N	\N	\N	\N	\N
259	ST-20260315-00257	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.149303+00	\N	\N	\N	\N	\N
260	ST-20260315-00258	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.18319+00	\N	\N	\N	\N	\N
261	ST-20260315-00259	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.221571+00	\N	\N	\N	\N	\N
262	ST-20260315-00260	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.260302+00	\N	\N	\N	\N	\N
263	ST-20260315-00261	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:06.294117+00	\N	\N	\N	\N	\N
264	ST-20260315-00262	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.330389+00	\N	\N	\N	\N	\N
265	ST-20260315-00263	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.370395+00	\N	\N	\N	\N	\N
266	ST-20260315-00264	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.407555+00	\N	\N	\N	\N	\N
267	ST-20260315-00265	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.444571+00	\N	\N	\N	\N	\N
268	ST-20260315-00266	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:06.479483+00	\N	\N	\N	\N	\N
269	ST-20260315-00267	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.51995+00	\N	\N	\N	\N	\N
270	ST-20260315-00268	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.557369+00	\N	\N	\N	\N	\N
271	ST-20260315-00269	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.59016+00	\N	\N	\N	\N	\N
272	ST-20260315-00270	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.62752+00	\N	\N	\N	\N	\N
273	ST-20260315-00271	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.666311+00	\N	\N	\N	\N	\N
274	ST-20260315-00272	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.700159+00	\N	\N	\N	\N	\N
275	ST-20260315-00273	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.735519+00	\N	\N	\N	\N	\N
276	ST-20260315-00274	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.775878+00	\N	\N	\N	\N	\N
277	ST-20260315-00275	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.813558+00	\N	\N	\N	\N	\N
278	ST-20260315-00276	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.849967+00	\N	\N	\N	\N	\N
279	ST-20260315-00277	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.883594+00	\N	\N	\N	\N	\N
280	ST-20260315-00278	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.921665+00	\N	\N	\N	\N	\N
281	ST-20260315-00279	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.960504+00	\N	\N	\N	\N	\N
282	ST-20260315-00280	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:06.994177+00	\N	\N	\N	\N	\N
283	ST-20260315-00281	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.032864+00	\N	\N	\N	\N	\N
284	ST-20260315-00282	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.070404+00	\N	\N	\N	\N	\N
285	ST-20260315-00283	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.107538+00	\N	\N	\N	\N	\N
286	ST-20260315-00284	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.141495+00	\N	\N	\N	\N	\N
287	ST-20260315-00285	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.179166+00	\N	\N	\N	\N	\N
288	ST-20260315-00286	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.219585+00	\N	\N	\N	\N	\N
289	ST-20260315-00287	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.257441+00	\N	\N	\N	\N	\N
290	ST-20260315-00288	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.290502+00	\N	\N	\N	\N	\N
291	ST-20260315-00289	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.328114+00	\N	\N	\N	\N	\N
292	ST-20260315-00290	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.370494+00	\N	\N	\N	\N	\N
293	ST-20260315-00291	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.404575+00	\N	\N	\N	\N	\N
294	ST-20260315-00292	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.43921+00	\N	\N	\N	\N	\N
295	ST-20260315-00293	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.479324+00	\N	\N	\N	\N	\N
296	ST-20260315-00294	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.517318+00	\N	\N	\N	\N	\N
297	ST-20260315-00295	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.555681+00	\N	\N	\N	\N	\N
298	ST-20260315-00296	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.58974+00	\N	\N	\N	\N	\N
299	ST-20260315-00297	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.628231+00	\N	\N	\N	\N	\N
300	ST-20260315-00298	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.666295+00	\N	\N	\N	\N	\N
301	ST-20260315-00299	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.699596+00	\N	\N	\N	\N	\N
302	ST-20260315-00300	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.735933+00	\N	\N	\N	\N	\N
303	ST-20260315-00301	REGULAR	\N	\N	1	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.773818+00	\N	\N	\N	\N	\N
304	ST-20260315-00302	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.813101+00	\N	\N	\N	\N	\N
305	ST-20260315-00303	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.849898+00	\N	\N	\N	\N	\N
306	ST-20260315-00304	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.883179+00	\N	\N	\N	\N	\N
307	ST-20260315-00305	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:07.922061+00	\N	\N	\N	\N	\N
308	ST-20260315-00306	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.96048+00	\N	\N	\N	\N	\N
309	ST-20260315-00307	REGULAR	\N	\N	2	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:07.994456+00	\N	\N	\N	\N	\N
310	ST-20260315-00308	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.034331+00	\N	\N	\N	\N	\N
311	ST-20260315-00309	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.069844+00	\N	\N	\N	\N	\N
312	ST-20260315-00310	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.109455+00	\N	\N	\N	\N	\N
313	ST-20260315-00311	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.144577+00	\N	\N	\N	\N	\N
314	ST-20260315-00312	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.182314+00	\N	\N	\N	\N	\N
315	ST-20260315-00313	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.221432+00	\N	\N	\N	\N	\N
316	ST-20260315-00314	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:08.259209+00	\N	\N	\N	\N	\N
317	ST-20260315-00315	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.292646+00	\N	\N	\N	\N	\N
318	ST-20260315-00316	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.330907+00	\N	\N	\N	\N	\N
319	ST-20260315-00317	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.369867+00	\N	\N	\N	\N	\N
320	ST-20260315-00318	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.404+00	\N	\N	\N	\N	\N
321	ST-20260315-00319	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:08.439338+00	\N	\N	\N	\N	\N
322	ST-20260315-00320	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.477348+00	\N	\N	\N	\N	\N
323	ST-20260315-00321	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.516988+00	\N	\N	\N	\N	\N
324	ST-20260315-00322	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.555102+00	\N	\N	\N	\N	\N
325	ST-20260315-00323	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:08.593297+00	\N	\N	\N	\N	\N
326	ST-20260315-00324	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.631299+00	\N	\N	\N	\N	\N
327	ST-20260315-00325	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.669885+00	\N	\N	\N	\N	\N
328	ST-20260315-00326	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.710581+00	\N	\N	\N	\N	\N
329	ST-20260315-00327	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:08.746805+00	\N	\N	\N	\N	\N
330	ST-20260315-00328	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.782989+00	\N	\N	\N	\N	\N
331	ST-20260315-00329	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.822934+00	\N	\N	\N	\N	\N
332	ST-20260315-00330	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.859774+00	\N	\N	\N	\N	\N
333	ST-20260315-00331	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.893911+00	\N	\N	\N	\N	\N
334	ST-20260315-00332	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.933685+00	\N	\N	\N	\N	\N
335	ST-20260315-00333	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:08.970672+00	\N	\N	\N	\N	\N
336	ST-20260315-00334	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.011594+00	\N	\N	\N	\N	\N
337	ST-20260315-00335	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.049305+00	\N	\N	\N	\N	\N
338	ST-20260315-00336	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.088279+00	\N	\N	\N	\N	\N
339	ST-20260315-00337	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.126932+00	\N	\N	\N	\N	\N
340	ST-20260315-00338	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.164856+00	\N	\N	\N	\N	\N
341	ST-20260315-00339	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.199391+00	\N	\N	\N	\N	\N
342	ST-20260315-00340	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.237655+00	\N	\N	\N	\N	\N
343	ST-20260315-00341	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.27448+00	\N	\N	\N	\N	\N
344	ST-20260315-00342	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.315284+00	\N	\N	\N	\N	\N
345	ST-20260315-00343	REGULAR	\N	\N	2	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.349306+00	\N	\N	\N	\N	\N
346	ST-20260315-00344	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.387002+00	\N	\N	\N	\N	\N
347	ST-20260315-00345	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.428339+00	\N	\N	\N	\N	\N
348	ST-20260315-00346	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.464229+00	\N	\N	\N	\N	\N
349	ST-20260315-00347	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.499552+00	\N	\N	\N	\N	\N
350	ST-20260315-00348	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.540679+00	\N	\N	\N	\N	\N
351	ST-20260315-00349	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.575777+00	\N	\N	\N	\N	\N
352	ST-20260315-00350	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.618591+00	\N	\N	\N	\N	\N
353	ST-20260315-00351	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.654057+00	\N	\N	\N	\N	\N
354	ST-20260315-00352	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.690798+00	\N	\N	\N	\N	\N
355	ST-20260315-00353	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.730558+00	\N	\N	\N	\N	\N
356	ST-20260315-00354	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.771238+00	\N	\N	\N	\N	\N
357	ST-20260315-00355	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.807684+00	\N	\N	\N	\N	\N
358	ST-20260315-00356	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.842446+00	\N	\N	\N	\N	\N
359	ST-20260315-00357	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.878672+00	\N	\N	\N	\N	\N
360	ST-20260315-00358	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.919724+00	\N	\N	\N	\N	\N
361	ST-20260315-00359	REGULAR	\N	\N	1	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:09.956352+00	\N	\N	\N	\N	\N
362	ST-20260315-00360	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:09.990889+00	\N	\N	\N	\N	\N
363	ST-20260315-00361	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.03271+00	\N	\N	\N	\N	\N
364	ST-20260315-00362	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.071274+00	\N	\N	\N	\N	\N
365	ST-20260315-00363	REGULAR	\N	\N	1	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:10.111049+00	\N	\N	\N	\N	\N
366	ST-20260315-00364	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.144176+00	\N	\N	\N	\N	\N
367	ST-20260315-00365	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.180758+00	\N	\N	\N	\N	\N
368	ST-20260315-00366	REGULAR	\N	\N	2	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.251147+00	\N	\N	\N	\N	\N
369	ST-20260315-00367	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.285318+00	\N	\N	\N	\N	\N
370	ST-20260315-00368	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:10.333378+00	\N	\N	\N	\N	\N
371	ST-20260315-00369	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.383594+00	\N	\N	\N	\N	\N
372	ST-20260315-00370	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.673031+00	\N	\N	\N	\N	\N
373	ST-20260315-00371	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.727777+00	\N	\N	\N	\N	\N
374	ST-20260315-00372	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.824713+00	\N	\N	\N	\N	\N
375	ST-20260315-00373	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.859827+00	\N	\N	\N	\N	\N
376	ST-20260315-00374	REGULAR	\N	\N	2	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:10.928498+00	\N	\N	\N	\N	\N
377	ST-20260315-00375	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:10.981862+00	\N	\N	\N	\N	\N
378	ST-20260315-00376	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.03721+00	\N	\N	\N	\N	\N
379	ST-20260315-00377	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.07067+00	\N	\N	\N	\N	\N
380	ST-20260315-00378	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.114+00	\N	\N	\N	\N	\N
381	ST-20260315-00379	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.148104+00	\N	\N	\N	\N	\N
382	ST-20260315-00380	REGULAR	\N	\N	1	\N	10	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.180979+00	\N	\N	\N	\N	\N
383	ST-20260315-00381	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.224986+00	\N	\N	\N	\N	\N
384	ST-20260315-00382	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.258932+00	\N	\N	\N	\N	\N
385	ST-20260315-00383	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.29304+00	\N	\N	\N	\N	\N
386	ST-20260315-00384	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.333836+00	\N	\N	\N	\N	\N
387	ST-20260315-00385	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.370864+00	\N	\N	\N	\N	\N
388	ST-20260315-00386	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.404321+00	\N	\N	\N	\N	\N
389	ST-20260315-00387	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.443607+00	\N	\N	\N	\N	\N
390	ST-20260315-00388	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.480715+00	\N	\N	\N	\N	\N
391	ST-20260315-00389	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.520932+00	\N	\N	\N	\N	\N
392	ST-20260315-00390	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.556571+00	\N	\N	\N	\N	\N
393	ST-20260315-00391	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.590217+00	\N	\N	\N	\N	\N
394	ST-20260315-00392	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.628354+00	\N	\N	\N	\N	\N
395	ST-20260315-00393	REGULAR	\N	\N	1	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.671173+00	\N	\N	\N	\N	\N
396	ST-20260315-00394	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.704293+00	\N	\N	\N	\N	\N
397	ST-20260315-00395	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.740229+00	\N	\N	\N	\N	\N
398	ST-20260315-00396	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.77855+00	\N	\N	\N	\N	\N
399	ST-20260315-00397	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.817921+00	\N	\N	\N	\N	\N
400	ST-20260315-00398	REGULAR	\N	\N	1	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:11.85401+00	\N	\N	\N	\N	\N
401	ST-20260315-00399	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.886814+00	\N	\N	\N	\N	\N
402	ST-20260315-00400	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.928839+00	\N	\N	\N	\N	\N
403	ST-20260315-00401	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.963048+00	\N	\N	\N	\N	\N
404	ST-20260315-00402	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:11.996559+00	\N	\N	\N	\N	\N
405	ST-20260315-00403	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.037479+00	\N	\N	\N	\N	\N
406	ST-20260315-00404	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.072922+00	\N	\N	\N	\N	\N
407	ST-20260315-00405	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.114868+00	\N	\N	\N	\N	\N
408	ST-20260315-00406	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.149339+00	\N	\N	\N	\N	\N
409	ST-20260315-00407	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.183493+00	\N	\N	\N	\N	\N
410	ST-20260315-00408	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.228946+00	\N	\N	\N	\N	\N
411	ST-20260315-00409	REGULAR	\N	\N	2	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.265383+00	\N	\N	\N	\N	\N
412	ST-20260315-00410	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.301989+00	\N	\N	\N	\N	\N
413	ST-20260315-00411	REGULAR	\N	\N	1	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.341921+00	\N	\N	\N	\N	\N
414	ST-20260315-00412	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.37687+00	\N	\N	\N	\N	\N
415	ST-20260315-00413	REGULAR	\N	\N	2	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.417765+00	\N	\N	\N	\N	\N
416	ST-20260315-00414	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.453119+00	\N	\N	\N	\N	\N
417	ST-20260315-00415	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.487437+00	\N	\N	\N	\N	\N
418	ST-20260315-00416	REGULAR	\N	\N	2	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.529076+00	\N	\N	\N	\N	\N
419	ST-20260315-00417	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.563588+00	\N	\N	\N	\N	\N
420	ST-20260315-00418	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.597478+00	\N	\N	\N	\N	\N
421	ST-20260315-00419	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.635668+00	\N	\N	\N	\N	\N
422	ST-20260315-00420	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.673554+00	\N	\N	\N	\N	\N
423	ST-20260315-00421	REGULAR	\N	\N	1	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.712839+00	\N	\N	\N	\N	\N
424	ST-20260315-00422	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.750688+00	\N	\N	\N	\N	\N
425	ST-20260315-00423	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.791961+00	\N	\N	\N	\N	\N
426	ST-20260315-00424	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.828227+00	\N	\N	\N	\N	\N
427	ST-20260315-00425	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.86238+00	\N	\N	\N	\N	\N
428	ST-20260315-00426	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:12.896724+00	\N	\N	\N	\N	\N
429	ST-20260315-00427	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.937087+00	\N	\N	\N	\N	\N
430	ST-20260315-00428	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:12.970189+00	\N	\N	\N	\N	\N
431	ST-20260315-00429	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.011399+00	\N	\N	\N	\N	\N
432	ST-20260315-00430	REGULAR	\N	\N	1	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.045816+00	\N	\N	\N	\N	\N
433	ST-20260315-00431	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.08186+00	\N	\N	\N	\N	\N
434	ST-20260315-00432	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.122829+00	\N	\N	\N	\N	\N
435	ST-20260315-00433	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.156683+00	\N	\N	\N	\N	\N
436	ST-20260315-00434	REGULAR	\N	\N	2	\N	6	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.190734+00	\N	\N	\N	\N	\N
437	ST-20260315-00435	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.233495+00	\N	\N	\N	\N	\N
438	ST-20260315-00436	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.270634+00	\N	\N	\N	\N	\N
439	ST-20260315-00437	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.312668+00	\N	\N	\N	\N	\N
440	ST-20260315-00438	REGULAR	\N	\N	2	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.346934+00	\N	\N	\N	\N	\N
441	ST-20260315-00439	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.381568+00	\N	\N	\N	\N	\N
442	ST-20260315-00440	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.422853+00	\N	\N	\N	\N	\N
443	ST-20260315-00441	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.457116+00	\N	\N	\N	\N	\N
444	ST-20260315-00442	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.491477+00	\N	\N	\N	\N	\N
445	ST-20260315-00443	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.534364+00	\N	\N	\N	\N	\N
446	ST-20260315-00444	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.570108+00	\N	\N	\N	\N	\N
447	ST-20260315-00445	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.608135+00	\N	\N	\N	\N	\N
448	ST-20260315-00446	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.64189+00	\N	\N	\N	\N	\N
449	ST-20260315-00447	REGULAR	\N	\N	1	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.678309+00	\N	\N	\N	\N	\N
450	ST-20260315-00448	REGULAR	\N	\N	1	\N	7	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.719529+00	\N	\N	\N	\N	\N
451	ST-20260315-00449	REGULAR	\N	\N	2	\N	4	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:13.755188+00	\N	\N	\N	\N	\N
452	ST-20260315-00450	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.789955+00	\N	\N	\N	\N	\N
453	ST-20260315-00451	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.828533+00	\N	\N	\N	\N	\N
454	ST-20260315-00452	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.865172+00	\N	\N	\N	\N	\N
455	ST-20260315-00453	REGULAR	\N	\N	1	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.899214+00	\N	\N	\N	\N	\N
456	ST-20260315-00454	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.936944+00	\N	\N	\N	\N	\N
457	ST-20260315-00455	REGULAR	\N	\N	2	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:13.972996+00	\N	\N	\N	\N	\N
458	ST-20260315-00456	REGULAR	\N	\N	1	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.015422+00	\N	\N	\N	\N	\N
459	ST-20260315-00457	REGULAR	\N	\N	2	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.052387+00	\N	\N	\N	\N	\N
460	ST-20260315-00458	REGULAR	\N	\N	2	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.086617+00	\N	\N	\N	\N	\N
461	ST-20260315-00459	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.127098+00	\N	\N	\N	\N	\N
462	ST-20260315-00460	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.164444+00	\N	\N	\N	\N	\N
463	ST-20260315-00461	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.198866+00	\N	\N	\N	\N	\N
464	ST-20260315-00462	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.236352+00	\N	\N	\N	\N	\N
465	ST-20260315-00463	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.27361+00	\N	\N	\N	\N	\N
466	ST-20260315-00464	REGULAR	\N	\N	2	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.314293+00	\N	\N	\N	\N	\N
467	ST-20260315-00465	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.349468+00	\N	\N	\N	\N	\N
468	ST-20260315-00466	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.383291+00	\N	\N	\N	\N	\N
469	ST-20260315-00467	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.424577+00	\N	\N	\N	\N	\N
470	ST-20260315-00468	REGULAR	\N	\N	2	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.459793+00	\N	\N	\N	\N	\N
471	ST-20260315-00469	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.493348+00	\N	\N	\N	\N	\N
472	ST-20260315-00470	REGULAR	\N	\N	2	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.534044+00	\N	\N	\N	\N	\N
473	ST-20260315-00471	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.570163+00	\N	\N	\N	\N	\N
474	ST-20260315-00472	REGULAR	\N	\N	2	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.607627+00	\N	\N	\N	\N	\N
475	ST-20260315-00473	REGULAR	\N	\N	1	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.641002+00	\N	\N	\N	\N	\N
476	ST-20260315-00474	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.679683+00	\N	\N	\N	\N	\N
477	ST-20260315-00475	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.720316+00	\N	\N	\N	\N	\N
478	ST-20260315-00476	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.755902+00	\N	\N	\N	\N	\N
479	ST-20260315-00477	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.789922+00	\N	\N	\N	\N	\N
480	ST-20260315-00478	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.82861+00	\N	\N	\N	\N	\N
481	ST-20260315-00479	REGULAR	\N	\N	1	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.869998+00	\N	\N	\N	\N	\N
482	ST-20260315-00480	REGULAR	\N	\N	1	\N	10	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:14.903432+00	\N	\N	\N	\N	\N
483	ST-20260315-00481	REGULAR	\N	\N	1	\N	5	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.937044+00	\N	\N	\N	\N	\N
484	ST-20260315-00482	REGULAR	\N	\N	1	\N	2	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:14.97851+00	\N	\N	\N	\N	\N
485	ST-20260315-00483	REGULAR	\N	\N	1	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.016939+00	\N	\N	\N	\N	\N
486	ST-20260315-00484	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.056902+00	\N	\N	\N	\N	\N
487	ST-20260315-00485	REGULAR	\N	\N	2	\N	8	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:15.091512+00	\N	\N	\N	\N	\N
488	ST-20260315-00486	REGULAR	\N	\N	1	\N	2	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.129185+00	\N	\N	\N	\N	\N
489	ST-20260315-00487	REGULAR	\N	\N	2	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.169858+00	\N	\N	\N	\N	\N
490	ST-20260315-00488	REGULAR	\N	\N	1	\N	9	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.204135+00	\N	\N	\N	\N	\N
491	ST-20260315-00489	REGULAR	\N	\N	2	\N	3	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:15.239005+00	\N	\N	\N	\N	\N
492	ST-20260315-00490	REGULAR	\N	\N	2	\N	6	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.280169+00	\N	\N	\N	\N	\N
493	ST-20260315-00491	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.3176+00	\N	\N	\N	\N	\N
494	ST-20260315-00492	REGULAR	\N	\N	2	\N	1	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.359609+00	\N	\N	\N	\N	\N
495	ST-20260315-00493	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.393718+00	\N	\N	\N	\N	\N
496	ST-20260315-00494	REGULAR	\N	\N	2	\N	8	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.428115+00	\N	\N	\N	\N	\N
497	ST-20260315-00495	REGULAR	\N	\N	1	\N	7	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.46964+00	\N	\N	\N	\N	\N
498	ST-20260315-00496	REGULAR	\N	\N	2	\N	9	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:15.503835+00	\N	\N	\N	\N	\N
499	ST-20260315-00497	REGULAR	\N	\N	1	\N	4	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.538016+00	\N	\N	\N	\N	\N
500	ST-20260315-00498	REGULAR	\N	\N	1	\N	1	URGENT	CREATED	Stress test order	1	2026-03-15 18:13:15.579237+00	\N	\N	\N	\N	\N
501	ST-20260315-00499	REGULAR	\N	\N	1	\N	3	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.61494+00	\N	\N	\N	\N	\N
502	ST-20260315-00500	REGULAR	\N	\N	2	\N	5	NORMAL	CREATED	Stress test order	1	2026-03-15 18:13:15.656654+00	\N	\N	\N	\N	\N
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
1	2026-03-15 18:15:37.110946+00	WARNING	\N	/api/system-logs	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
2	2026-03-15 18:15:37.964236+00	WARNING	\N	/api/activity-logs	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
3	2026-03-15 18:15:38.509838+00	WARNING	\N	/api/system-health/summary	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
4	2026-03-15 18:15:39.331876+00	WARNING	\N	/api/backups/status	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
5	2026-03-15 18:15:39.499778+00	WARNING	\N	/api/backups/list	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
6	2026-03-15 18:15:39.666258+00	WARNING	\N	/api/backups/create	POST	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
7	2026-03-15 18:15:40.776718+00	WARNING	\N	/api/stress-test/history	GET	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
8	2026-03-15 18:15:40.951144+00	WARNING	\N	/api/stress-test/start	POST	AUTH	Authentication/Authorization error: 403	\N	\N	403	34.16.56.64	python-requests/2.32.5	0
9	2026-03-15 18:15:41.243147+00	WARNING	\N	/api/system-logs	GET	AUTH	Authentication/Authorization error: 401	\N	\N	401	34.16.56.64	python-requests/2.32.5	0
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
1	9999999999	System Admin	admin@mthhospital.com	$2b$12$9LoDabxE1fjbb7TgtmpBmO3p34adXtEfUbnmNUJrYo8ZrlkSJkcGK	1	t	t	t	t	EMP001	System Administrator	\N	2026-03-15 17:56:38.49674+00	\N	2026-03-15 18:17:17.251811+00	\N	2026-03-15 18:17:17.491574+00
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

SELECT pg_catalog.setval('public.activity_logs_id_seq', 4, true);


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

SELECT pg_catalog.setval('public.order_items_id_seq', 1454, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orders_id_seq', 502, true);


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

SELECT pg_catalog.setval('public.system_logs_id_seq', 9, true);


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

\unrestrict cAVaBFhGPycVmItEJPdfZ1YRgXeNRdxUD3yuXglAcmhETEUUcakKHHjJeaEWMy0


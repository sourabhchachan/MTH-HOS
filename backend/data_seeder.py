"""
Data Seeding Module - Quick setup for hospital operational data
Provides seed data for Departments, Items, Vendors, Assets, and Users
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
from pydantic import BaseModel
from decimal import Decimal
import random

from database import get_db
from models import (
    Department, User, Vendor, ItemCategory, Item, ItemOrderingDepartment,
    Asset, AssetStatus, Patient,
    PatientWorkflowPhase, PriorityRequirement, PatientIPDRequirement, IPDStatusAllowed
)
from auth import get_admin_user, get_password_hash

router = APIRouter(prefix="/seed", tags=["Data Seeding"])


class SeedResult(BaseModel):
    departments_created: int
    vendors_created: int
    categories_created: int
    items_created: int
    assets_created: int
    users_created: int
    message: str


class SeedStatus(BaseModel):
    departments: int
    vendors: int
    categories: int
    items: int
    assets: int
    users: int
    is_seeded: bool


# ============ SEED DATA DEFINITIONS ============

DEPARTMENTS_DATA = [
    {"name": "Administration", "code": "ADMIN", "description": "Hospital administration and management"},
    {"name": "Emergency", "code": "EMRG", "description": "Emergency department for critical care"},
    {"name": "OPD", "code": "OPD", "description": "Outpatient department"},
    {"name": "IPD Ward", "code": "WARD", "description": "Inpatient department ward"},
    {"name": "ICU", "code": "ICU", "description": "Intensive care unit"},
    {"name": "Laboratory", "code": "LAB", "description": "Pathology and diagnostic laboratory"},
    {"name": "Radiology", "code": "RAD", "description": "Imaging and radiology services"},
    {"name": "Pharmacy", "code": "PHRM", "description": "Pharmacy and medication dispensing"},
    {"name": "Central Store", "code": "STORE", "description": "Central storage and inventory"},
    {"name": "Billing", "code": "BILL", "description": "Billing and revenue cycle"},
    {"name": "Accounts", "code": "ACCT", "description": "Accounts and finance department"},
    {"name": "Housekeeping", "code": "HSKP", "description": "Housekeeping and sanitation"},
    {"name": "Maintenance", "code": "MAINT", "description": "Facility maintenance"},
    {"name": "Biomedical", "code": "BIOMED", "description": "Biomedical equipment maintenance"},
]

VENDORS_DATA = [
    {"name": "MedSupply Pharma", "code": "VMED01", "contact_person": "Rajesh Kumar", "phone": "9876543001", "email": "sales@medsupply.com"},
    {"name": "LabTech Diagnostics", "code": "VLAB01", "contact_person": "Priya Sharma", "phone": "9876543002", "email": "orders@labtech.com"},
    {"name": "RadiCare Imaging", "code": "VRAD01", "contact_person": "Amit Singh", "phone": "9876543003", "email": "support@radicare.com"},
    {"name": "BioMed Solutions", "code": "VBIO01", "contact_person": "Sunita Verma", "phone": "9876543004", "email": "service@biomedsol.com"},
    {"name": "HospEquip Systems", "code": "VEQP01", "contact_person": "Vikram Patel", "phone": "9876543005", "email": "sales@hospequip.com"},
    {"name": "CleanCare Services", "code": "VCLN01", "contact_person": "Meena Devi", "phone": "9876543006", "email": "ops@cleancare.com"},
    {"name": "SurgiMed Supplies", "code": "VSRG01", "contact_person": "Arun Gupta", "phone": "9876543007", "email": "orders@surgimed.com"},
    {"name": "TechFacility Mgmt", "code": "VFAC01", "contact_person": "Ravi Shankar", "phone": "9876543008", "email": "support@techfac.com"},
]

CATEGORIES_DATA = [
    {"name": "Medicines", "description": "Pharmaceutical medicines and drugs"},
    {"name": "Lab Tests", "description": "Laboratory diagnostic tests"},
    {"name": "Radiology Tests", "description": "Imaging and radiology services"},
    {"name": "Consumables", "description": "Medical consumables and supplies"},
    {"name": "Procedures", "description": "Medical procedures and services"},
    {"name": "Maintenance Requests", "description": "Equipment and facility maintenance"},
    {"name": "Housekeeping Requests", "description": "Housekeeping and cleaning services"},
]

# Items with their configurations
ITEMS_DATA = [
    # Lab Tests - dispatched by Laboratory
    {"name": "CBC (Complete Blood Count)", "code": "LAB001", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 350, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Blood Sugar Fasting", "code": "LAB002", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 150, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Liver Function Test (LFT)", "code": "LAB003", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 850, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Kidney Function Test (KFT)", "code": "LAB004", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 750, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Thyroid Profile", "code": "LAB005", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 650, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Urine Routine", "code": "LAB006", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 100, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "Blood Culture", "code": "LAB007", "unit": "test", "category": "Lab Tests", "dispatching_dept": "LAB", "cost": 1200, "vendor": "VLAB01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    
    # Radiology Tests - dispatched by Radiology
    {"name": "X-Ray Chest PA View", "code": "RAD001", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 450, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "X-Ray Abdomen", "code": "RAD002", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 500, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "USG Abdomen", "code": "RAD003", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 1200, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "CT Scan Head", "code": "RAD004", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 3500, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "MRI Brain", "code": "RAD005", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 8000, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "ECG", "code": "RAD006", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 200, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    {"name": "2D Echo", "code": "RAD007", "unit": "test", "category": "Radiology Tests", "dispatching_dept": "RAD", "cost": 2500, "vendor": "VRAD01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "BOTH"},
    
    # Medicines - dispatched by Pharmacy
    {"name": "Paracetamol 500mg", "code": "MED001", "unit": "tablet", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 2.5, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Amoxicillin 500mg", "code": "MED002", "unit": "capsule", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 8, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Omeprazole 20mg", "code": "MED003", "unit": "capsule", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 5, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Metformin 500mg", "code": "MED004", "unit": "tablet", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 3, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Amlodipine 5mg", "code": "MED005", "unit": "tablet", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 4, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Ceftriaxone 1g Injection", "code": "MED006", "unit": "vial", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 85, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Normal Saline 500ml", "code": "MED007", "unit": "bottle", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 45, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    {"name": "Dextrose 5% 500ml", "code": "MED008", "unit": "bottle", "category": "Medicines", "dispatching_dept": "PHRM", "cost": 55, "vendor": "VMED01", "all_depts": True, "ipd_req": "MANDATORY", "ipd_status": "ACTIVE_ONLY"},
    
    # Consumables - dispatched by Central Store
    {"name": "Syringe 5ml", "code": "CON001", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 8, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Syringe 10ml", "code": "CON002", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 10, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "IV Cannula 20G", "code": "CON003", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 25, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Examination Gloves (Pair)", "code": "CON004", "unit": "pair", "category": "Consumables", "dispatching_dept": "STORE", "cost": 5, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Surgical Gloves (Pair)", "code": "CON005", "unit": "pair", "category": "Consumables", "dispatching_dept": "STORE", "cost": 35, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Cotton Roll 500g", "code": "CON006", "unit": "roll", "category": "Consumables", "dispatching_dept": "STORE", "cost": 120, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Gauze Pack", "code": "CON007", "unit": "pack", "category": "Consumables", "dispatching_dept": "STORE", "cost": 45, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Surgical Mask", "code": "CON008", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 5, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "N95 Mask", "code": "CON009", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 45, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Urine Bag", "code": "CON010", "unit": "piece", "category": "Consumables", "dispatching_dept": "STORE", "cost": 80, "vendor": "VSRG01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    
    # Housekeeping Requests - dispatched by Housekeeping
    {"name": "Bed Cleaning", "code": "HSK001", "unit": "service", "category": "Housekeeping Requests", "dispatching_dept": "HSKP", "cost": 100, "vendor": "VCLN01", "allowed_depts": ["WARD", "ICU", "EMRG", "OPD"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Room Sanitization", "code": "HSK002", "unit": "service", "category": "Housekeeping Requests", "dispatching_dept": "HSKP", "cost": 250, "vendor": "VCLN01", "allowed_depts": ["WARD", "ICU", "EMRG", "OPD", "LAB", "RAD"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Linen Change", "code": "HSK003", "unit": "service", "category": "Housekeeping Requests", "dispatching_dept": "HSKP", "cost": 50, "vendor": "VCLN01", "allowed_depts": ["WARD", "ICU", "EMRG"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Waste Disposal", "code": "HSK004", "unit": "service", "category": "Housekeeping Requests", "dispatching_dept": "HSKP", "cost": 75, "vendor": "VCLN01", "allowed_depts": ["WARD", "ICU", "EMRG", "OPD", "LAB", "RAD", "PHRM"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Floor Mopping", "code": "HSK005", "unit": "service", "category": "Housekeeping Requests", "dispatching_dept": "HSKP", "cost": 150, "vendor": "VCLN01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    
    # Maintenance Requests - dispatched by Maintenance/Biomedical
    {"name": "AC Maintenance", "code": "MNT001", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "MAINT", "cost": 500, "vendor": "VFAC01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Plumbing Repair", "code": "MNT002", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "MAINT", "cost": 300, "vendor": "VFAC01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Electrical Repair", "code": "MNT003", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "MAINT", "cost": 400, "vendor": "VFAC01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Ventilator Maintenance", "code": "MNT004", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "BIOMED", "cost": 2000, "vendor": "VBIO01", "allowed_depts": ["ICU", "EMRG"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Monitor Calibration", "code": "MNT005", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "BIOMED", "cost": 800, "vendor": "VBIO01", "allowed_depts": ["ICU", "EMRG", "WARD", "OPD"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Infusion Pump Service", "code": "MNT006", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "BIOMED", "cost": 1200, "vendor": "VBIO01", "allowed_depts": ["ICU", "EMRG", "WARD"], "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
    {"name": "Computer/IT Support", "code": "MNT007", "unit": "service", "category": "Maintenance Requests", "dispatching_dept": "MAINT", "cost": 200, "vendor": "VFAC01", "all_depts": True, "ipd_req": "NON_MANDATORY", "ipd_status": "BOTH"},
]

ASSETS_DATA = [
    {"name": "Ventilator V500", "code": "AST001", "category": "Medical Equipment", "dept": "ICU", "vendor": "VBIO01", "cost": 1500000, "maintenance_days": 90},
    {"name": "Ventilator V300", "code": "AST002", "category": "Medical Equipment", "dept": "EMRG", "vendor": "VBIO01", "cost": 1200000, "maintenance_days": 90},
    {"name": "Patient Monitor PM-8", "code": "AST003", "category": "Medical Equipment", "dept": "ICU", "vendor": "VBIO01", "cost": 350000, "maintenance_days": 180},
    {"name": "Patient Monitor PM-5", "code": "AST004", "category": "Medical Equipment", "dept": "WARD", "vendor": "VBIO01", "cost": 250000, "maintenance_days": 180},
    {"name": "Infusion Pump IP-200", "code": "AST005", "category": "Medical Equipment", "dept": "ICU", "vendor": "VBIO01", "cost": 85000, "maintenance_days": 180},
    {"name": "Infusion Pump IP-100", "code": "AST006", "category": "Medical Equipment", "dept": "WARD", "vendor": "VBIO01", "cost": 65000, "maintenance_days": 180},
    {"name": "Defibrillator DF-1", "code": "AST007", "category": "Medical Equipment", "dept": "ICU", "vendor": "VBIO01", "cost": 450000, "maintenance_days": 365},
    {"name": "Defibrillator DF-2", "code": "AST008", "category": "Medical Equipment", "dept": "EMRG", "vendor": "VBIO01", "cost": 450000, "maintenance_days": 365},
    {"name": "ECG Machine 12-Lead", "code": "AST009", "category": "Medical Equipment", "dept": "RAD", "vendor": "VBIO01", "cost": 180000, "maintenance_days": 365},
    {"name": "Oxygen Concentrator OC-5L", "code": "AST010", "category": "Medical Equipment", "dept": "WARD", "vendor": "VBIO01", "cost": 45000, "maintenance_days": 180},
    {"name": "Suction Machine SM-1", "code": "AST011", "category": "Medical Equipment", "dept": "ICU", "vendor": "VBIO01", "cost": 35000, "maintenance_days": 180},
    {"name": "Wheelchair Standard", "code": "AST012", "category": "Patient Transport", "dept": "WARD", "vendor": "VEQP01", "cost": 15000, "maintenance_days": 365},
    {"name": "Stretcher ST-1", "code": "AST013", "category": "Patient Transport", "dept": "EMRG", "vendor": "VEQP01", "cost": 45000, "maintenance_days": 365},
    {"name": "Patient Bed Electric", "code": "AST014", "category": "Furniture", "dept": "ICU", "vendor": "VEQP01", "cost": 120000, "maintenance_days": 365},
    {"name": "Patient Bed Manual", "code": "AST015", "category": "Furniture", "dept": "WARD", "vendor": "VEQP01", "cost": 35000, "maintenance_days": 365},
    {"name": "AC Split 2 Ton ICU", "code": "AST016", "category": "HVAC", "dept": "ICU", "vendor": "VFAC01", "cost": 85000, "maintenance_days": 180},
    {"name": "AC Split 1.5 Ton Ward", "code": "AST017", "category": "HVAC", "dept": "WARD", "vendor": "VFAC01", "cost": 55000, "maintenance_days": 180},
    {"name": "Computer Desktop Admin", "code": "AST018", "category": "IT Equipment", "dept": "ADMIN", "vendor": "VFAC01", "cost": 45000, "maintenance_days": 365},
    {"name": "Computer Desktop Billing", "code": "AST019", "category": "IT Equipment", "dept": "BILL", "vendor": "VFAC01", "cost": 45000, "maintenance_days": 365},
    {"name": "Printer Laser Admin", "code": "AST020", "category": "IT Equipment", "dept": "ADMIN", "vendor": "VFAC01", "cost": 25000, "maintenance_days": 365},
]

USERS_DATA = [
    # Admin staff
    {"name": "System Admin", "phone": "9999999999", "dept": "ADMIN", "designation": "System Administrator", "is_admin": True, "can_view_costs": True, "employee_code": "EMP001"},
    {"name": "Hospital Admin", "phone": "9999999998", "dept": "ADMIN", "designation": "Hospital Administrator", "is_admin": True, "can_view_costs": True, "employee_code": "EMP002"},
    
    # Ward Staff
    {"name": "Dr. Ravi Kumar", "phone": "9876543210", "dept": "WARD", "designation": "Ward Doctor", "is_admin": False, "can_view_costs": False, "employee_code": "DOC001"},
    {"name": "Nurse Sunita", "phone": "9876543211", "dept": "WARD", "designation": "Staff Nurse", "is_admin": False, "can_view_costs": False, "employee_code": "NRS001"},
    {"name": "Nurse Priya", "phone": "9876543212", "dept": "WARD", "designation": "Staff Nurse", "is_admin": False, "can_view_costs": False, "employee_code": "NRS002"},
    
    # ICU Staff
    {"name": "Dr. Amit Shah", "phone": "9876543220", "dept": "ICU", "designation": "ICU Consultant", "is_admin": False, "can_view_costs": False, "employee_code": "DOC002"},
    {"name": "Nurse Rekha", "phone": "9876543221", "dept": "ICU", "designation": "ICU Nurse", "is_admin": False, "can_view_costs": False, "employee_code": "NRS003"},
    
    # Emergency Staff
    {"name": "Dr. Priya Verma", "phone": "9876543230", "dept": "EMRG", "designation": "Emergency Physician", "is_admin": False, "can_view_costs": False, "employee_code": "DOC003"},
    {"name": "Nurse Meera", "phone": "9876543231", "dept": "EMRG", "designation": "Emergency Nurse", "is_admin": False, "can_view_costs": False, "employee_code": "NRS004"},
    
    # Lab Staff
    {"name": "Rajesh Lab Tech", "phone": "9876543240", "dept": "LAB", "designation": "Lab Technician", "is_admin": False, "can_view_costs": False, "employee_code": "LAB001"},
    {"name": "Anita Lab Tech", "phone": "9876543241", "dept": "LAB", "designation": "Lab Technician", "is_admin": False, "can_view_costs": False, "employee_code": "LAB002"},
    
    # Radiology Staff
    {"name": "Suresh Radiographer", "phone": "9876543250", "dept": "RAD", "designation": "Radiographer", "is_admin": False, "can_view_costs": False, "employee_code": "RAD001"},
    
    # Pharmacy Staff
    {"name": "Vinod Pharmacist", "phone": "9876543260", "dept": "PHRM", "designation": "Pharmacist", "is_admin": False, "can_view_costs": True, "employee_code": "PHR001"},
    {"name": "Kavita Pharmacist", "phone": "9876543261", "dept": "PHRM", "designation": "Pharmacy Assistant", "is_admin": False, "can_view_costs": False, "employee_code": "PHR002"},
    
    # Store Staff
    {"name": "Ramesh Store", "phone": "9876543270", "dept": "STORE", "designation": "Store Incharge", "is_admin": False, "can_view_costs": True, "employee_code": "STR001"},
    {"name": "Geeta Store", "phone": "9876543271", "dept": "STORE", "designation": "Store Assistant", "is_admin": False, "can_view_costs": False, "employee_code": "STR002"},
    
    # Housekeeping Staff
    {"name": "Mohan Housekeeping", "phone": "9876543280", "dept": "HSKP", "designation": "Housekeeping Supervisor", "is_admin": False, "can_view_costs": False, "employee_code": "HSK001"},
    {"name": "Lakshmi Housekeeping", "phone": "9876543281", "dept": "HSKP", "designation": "Housekeeping Staff", "is_admin": False, "can_view_costs": False, "employee_code": "HSK002"},
    
    # Maintenance Staff
    {"name": "Shankar Maintenance", "phone": "9876543290", "dept": "MAINT", "designation": "Maintenance Supervisor", "is_admin": False, "can_view_costs": False, "employee_code": "MNT001"},
    {"name": "Kumar Electrician", "phone": "9876543291", "dept": "MAINT", "designation": "Electrician", "is_admin": False, "can_view_costs": False, "employee_code": "MNT002"},
    
    # Biomedical Staff
    {"name": "Vijay Biomedical", "phone": "9876543300", "dept": "BIOMED", "designation": "Biomedical Engineer", "is_admin": False, "can_view_costs": True, "employee_code": "BIO001"},
    
    # Billing Staff
    {"name": "Anand Billing", "phone": "9876543310", "dept": "BILL", "designation": "Billing Executive", "is_admin": False, "can_view_costs": True, "employee_code": "BIL001"},
]


# ============ SEED STATUS CHECK ============

@router.get("/status", response_model=SeedStatus)
async def get_seed_status(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Check current seed status"""
    dept_count = await db.scalar(select(func.count()).select_from(Department))
    vendor_count = await db.scalar(select(func.count()).select_from(Vendor))
    cat_count = await db.scalar(select(func.count()).select_from(ItemCategory))
    item_count = await db.scalar(select(func.count()).select_from(Item))
    asset_count = await db.scalar(select(func.count()).select_from(Asset))
    user_count = await db.scalar(select(func.count()).select_from(User))
    
    # Consider seeded if we have at least the minimum expected data
    is_seeded = (
        dept_count >= len(DEPARTMENTS_DATA) and
        vendor_count >= len(VENDORS_DATA) and
        item_count >= len(ITEMS_DATA) // 2
    )
    
    return SeedStatus(
        departments=dept_count or 0,
        vendors=vendor_count or 0,
        categories=cat_count or 0,
        items=item_count or 0,
        assets=asset_count or 0,
        users=user_count or 0,
        is_seeded=is_seeded
    )


# ============ SEED ALL DATA ============

@router.post("/all", response_model=SeedResult)
async def seed_all_data(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Seed all operational data in one go"""
    result = {
        "departments_created": 0,
        "vendors_created": 0,
        "categories_created": 0,
        "items_created": 0,
        "assets_created": 0,
        "users_created": 0,
    }
    
    # 1. Seed Departments
    dept_map = {}
    for dept_data in DEPARTMENTS_DATA:
        existing = await db.execute(
            select(Department).where(Department.code == dept_data["code"])
        )
        dept = existing.scalar_one_or_none()
        if not dept:
            dept = Department(**dept_data)
            db.add(dept)
            await db.flush()
            result["departments_created"] += 1
        dept_map[dept_data["code"]] = dept
    
    # 2. Seed Vendors
    vendor_map = {}
    for vendor_data in VENDORS_DATA:
        existing = await db.execute(
            select(Vendor).where(Vendor.code == vendor_data["code"])
        )
        vendor = existing.scalar_one_or_none()
        if not vendor:
            vendor = Vendor(**vendor_data)
            db.add(vendor)
            await db.flush()
            result["vendors_created"] += 1
        vendor_map[vendor_data["code"]] = vendor
    
    # 3. Seed Categories
    cat_map = {}
    for cat_data in CATEGORIES_DATA:
        existing = await db.execute(
            select(ItemCategory).where(ItemCategory.name == cat_data["name"])
        )
        cat = existing.scalar_one_or_none()
        if not cat:
            cat = ItemCategory(**cat_data)
            db.add(cat)
            await db.flush()
            result["categories_created"] += 1
        cat_map[cat_data["name"]] = cat
    
    # 4. Seed Items
    for item_data in ITEMS_DATA:
        existing = await db.execute(
            select(Item).where(Item.code == item_data["code"])
        )
        if existing.scalar_one_or_none():
            continue
        
        dispatching_dept = dept_map.get(item_data["dispatching_dept"])
        category = cat_map.get(item_data["category"])
        vendor = vendor_map.get(item_data.get("vendor"))
        
        if not dispatching_dept:
            continue
        
        ipd_req = PatientIPDRequirement.MANDATORY if item_data.get("ipd_req") == "MANDATORY" else PatientIPDRequirement.NON_MANDATORY
        ipd_status = IPDStatusAllowed.BOTH
        if item_data.get("ipd_status") == "ACTIVE_ONLY":
            ipd_status = IPDStatusAllowed.ACTIVE_ONLY
        elif item_data.get("ipd_status") == "INACTIVE_ONLY":
            ipd_status = IPDStatusAllowed.INACTIVE_ONLY
        
        all_depts = item_data.get("all_depts", False)
        
        item = Item(
            name=item_data["name"],
            code=item_data["code"],
            unit=item_data["unit"],
            dispatching_department_id=dispatching_dept.id,
            category_id=category.id if category else None,
            vendor_id=vendor.id if vendor else None,
            cost_per_unit=Decimal(str(item_data["cost"])),
            all_departments_allowed=all_depts,
            patient_ipd_requirement=ipd_req,
            ipd_status_allowed=ipd_status,
            priority_requirement=PriorityRequirement.NON_MANDATORY,
            created_by=admin.id
        )
        db.add(item)
        await db.flush()
        
        # Add allowed departments if not all
        if not all_depts and "allowed_depts" in item_data:
            for dept_code in item_data["allowed_depts"]:
                if dept_code in dept_map:
                    od = ItemOrderingDepartment(
                        item_id=item.id,
                        department_id=dept_map[dept_code].id
                    )
                    db.add(od)
        
        result["items_created"] += 1
    
    # 5. Seed Assets
    for asset_data in ASSETS_DATA:
        existing = await db.execute(
            select(Asset).where(Asset.asset_code == asset_data["code"])
        )
        if existing.scalar_one_or_none():
            continue
        
        dept = dept_map.get(asset_data["dept"])
        vendor = vendor_map.get(asset_data.get("vendor"))
        
        purchase_date = date.today() - timedelta(days=random.randint(180, 730))
        warranty_expiry = date.today() + timedelta(days=random.randint(365, 1095))
        
        asset = Asset(
            asset_code=asset_data["code"],
            name=asset_data["name"],
            category=asset_data["category"],
            current_department_id=dept.id if dept else None,
            vendor_id=vendor.id if vendor else None,
            purchase_date=purchase_date,
            purchase_price=Decimal(str(asset_data["cost"])),
            warranty_expiry=warranty_expiry,
            status=AssetStatus.AVAILABLE,
            created_by=admin.id
        )
        db.add(asset)
        result["assets_created"] += 1
    
    # 6. Seed Users
    default_password = get_password_hash("1234")
    for user_data in USERS_DATA:
        existing = await db.execute(
            select(User).where(User.phone == user_data["phone"])
        )
        if existing.scalar_one_or_none():
            continue
        
        dept = dept_map.get(user_data["dept"])
        
        user = User(
            phone=user_data["phone"],
            name=user_data["name"],
            password_hash=default_password,
            primary_department_id=dept.id if dept else None,
            designation=user_data.get("designation"),
            employee_code=user_data.get("employee_code"),
            is_admin=user_data.get("is_admin", False),
            can_view_costs=user_data.get("can_view_costs", False),
            created_by=admin.id
        )
        db.add(user)
        result["users_created"] += 1
    
    await db.commit()
    
    result["message"] = f"Seeding complete! Created: {result['departments_created']} departments, {result['vendors_created']} vendors, {result['categories_created']} categories, {result['items_created']} items, {result['assets_created']} assets, {result['users_created']} users"
    
    return SeedResult(**result)


# ============ SEED INDIVIDUAL MODULES ============

@router.post("/departments")
async def seed_departments(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Seed only departments"""
    created = 0
    for dept_data in DEPARTMENTS_DATA:
        existing = await db.execute(
            select(Department).where(Department.code == dept_data["code"])
        )
        if not existing.scalar_one_or_none():
            dept = Department(**dept_data)
            db.add(dept)
            created += 1
    
    await db.commit()
    return {"message": f"Created {created} departments", "created": created}


@router.post("/vendors")
async def seed_vendors(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Seed only vendors"""
    created = 0
    for vendor_data in VENDORS_DATA:
        existing = await db.execute(
            select(Vendor).where(Vendor.code == vendor_data["code"])
        )
        if not existing.scalar_one_or_none():
            vendor = Vendor(**vendor_data)
            db.add(vendor)
            created += 1
    
    await db.commit()
    return {"message": f"Created {created} vendors", "created": created}


@router.post("/categories")
async def seed_categories(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """Seed only categories"""
    created = 0
    for cat_data in CATEGORIES_DATA:
        existing = await db.execute(
            select(ItemCategory).where(ItemCategory.name == cat_data["name"])
        )
        if not existing.scalar_one_or_none():
            cat = ItemCategory(**cat_data)
            db.add(cat)
            created += 1
    
    await db.commit()
    return {"message": f"Created {created} categories", "created": created}

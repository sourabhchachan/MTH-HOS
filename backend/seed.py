"""
Seed script for MTH Hospital Operations System
Creates initial admin user, departments, and sample data
"""
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal, init_db
from models import Department, User, ItemCategory, Item, Vendor, Patient, IPD, ReturnReason
from auth import get_password_hash
from datetime import datetime, timezone


async def seed_data():
    await init_db()
    
    async with AsyncSessionLocal() as db:
        # Check if data already exists
        from sqlalchemy import select
        result = await db.execute(select(Department))
        if result.scalars().first():
            print("Data already seeded. Skipping...")
            return
        
        print("Seeding initial data...")
        
        # Create departments
        departments = [
            Department(name="Administration", code="ADMIN", description="Hospital Administration"),
            Department(name="Ward A", code="WARD-A", description="General Ward A"),
            Department(name="Ward B", code="WARD-B", description="General Ward B"),
            Department(name="ICU", code="ICU", description="Intensive Care Unit"),
            Department(name="Emergency", code="EMRG", description="Emergency Department"),
            Department(name="Pharmacy", code="PHRM", description="Pharmacy Department"),
            Department(name="Laboratory", code="LAB", description="Pathology Laboratory"),
            Department(name="Radiology", code="RAD", description="Radiology Department"),
            Department(name="OT", code="OT", description="Operation Theater"),
            Department(name="Kitchen", code="KTCHN", description="Hospital Kitchen"),
        ]
        for dept in departments:
            db.add(dept)
        await db.flush()
        
        # Get department IDs
        admin_dept = departments[0]
        ward_a = departments[1]
        ward_b = departments[2]
        icu = departments[3]
        emergency = departments[4]
        pharmacy = departments[5]
        lab = departments[6]
        radiology = departments[7]
        ot = departments[8]
        kitchen = departments[9]
        
        # Create admin user
        admin_user = User(
            phone="9999999999",
            name="System Admin",
            email="admin@mthhospital.com",
            password_hash=get_password_hash("admin123"),
            primary_department_id=admin_dept.id,
            is_admin=True,
            can_view_costs=True,
            can_reactivate_ipd=True,
            employee_code="EMP001",
            designation="System Administrator"
        )
        db.add(admin_user)
        
        # Create sample users for each department
        sample_users = [
            User(
                phone="9876543210",
                name="Dr. Rajesh Kumar",
                password_hash=get_password_hash("user123"),
                primary_department_id=ward_a.id,
                employee_code="EMP002",
                designation="Senior Doctor"
            ),
            User(
                phone="9876543211",
                name="Nurse Priya Sharma",
                password_hash=get_password_hash("user123"),
                primary_department_id=ward_a.id,
                employee_code="EMP003",
                designation="Head Nurse"
            ),
            User(
                phone="9876543212",
                name="Pharmacist Amit Singh",
                password_hash=get_password_hash("user123"),
                primary_department_id=pharmacy.id,
                employee_code="EMP004",
                designation="Chief Pharmacist"
            ),
            User(
                phone="9876543213",
                name="Lab Tech Sunita Verma",
                password_hash=get_password_hash("user123"),
                primary_department_id=lab.id,
                employee_code="EMP005",
                designation="Lab Technician"
            ),
            User(
                phone="9876543214",
                name="Dr. Emergency Staff",
                password_hash=get_password_hash("user123"),
                primary_department_id=emergency.id,
                employee_code="EMP006",
                designation="Emergency Doctor"
            ),
        ]
        for user in sample_users:
            db.add(user)
        
        # Create vendors
        vendors = [
            Vendor(name="MedSupply Co.", code="VEND001", contact_person="John Doe", phone="1234567890"),
            Vendor(name="PharmaWholesale Ltd.", code="VEND002", contact_person="Jane Smith", phone="1234567891"),
            Vendor(name="LabEquip India", code="VEND003", contact_person="Ravi Patel", phone="1234567892"),
        ]
        for vendor in vendors:
            db.add(vendor)
        await db.flush()
        
        # Create item categories
        categories = [
            ItemCategory(name="Medicines", description="Pharmaceutical medicines"),
            ItemCategory(name="Consumables", description="Medical consumables"),
            ItemCategory(name="Lab Tests", description="Laboratory tests"),
            ItemCategory(name="Radiology", description="Imaging services"),
            ItemCategory(name="Food & Beverages", description="Patient meals"),
        ]
        for cat in categories:
            db.add(cat)
        await db.flush()
        
        # Create items
        items = [
            # Medicines (dispatched by Pharmacy)
            Item(
                name="Paracetamol 500mg",
                code="MED001",
                category_id=categories[0].id,
                unit="tablet",
                dispatching_department_id=pharmacy.id,
                vendor_id=vendors[1].id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                cost_per_unit=2.50
            ),
            Item(
                name="Amoxicillin 250mg",
                code="MED002",
                category_id=categories[0].id,
                unit="capsule",
                dispatching_department_id=pharmacy.id,
                vendor_id=vendors[1].id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                cost_per_unit=5.00
            ),
            Item(
                name="IV Saline 500ml",
                code="MED003",
                category_id=categories[0].id,
                unit="bottle",
                dispatching_department_id=pharmacy.id,
                vendor_id=vendors[1].id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                patient_ipd_requirement="MANDATORY",
                ipd_status_allowed="ACTIVE_ONLY",
                cost_per_unit=45.00
            ),
            # Consumables
            Item(
                name="Surgical Gloves (pair)",
                code="CON001",
                category_id=categories[1].id,
                unit="pair",
                dispatching_department_id=pharmacy.id,
                vendor_id=vendors[0].id,
                all_departments_allowed=True,
                cost_per_unit=15.00
            ),
            Item(
                name="Bandage Roll",
                code="CON002",
                category_id=categories[1].id,
                unit="roll",
                dispatching_department_id=pharmacy.id,
                vendor_id=vendors[0].id,
                all_departments_allowed=True,
                cost_per_unit=25.00
            ),
            # Lab Tests (dispatched by Laboratory)
            Item(
                name="Complete Blood Count (CBC)",
                code="LAB001",
                category_id=categories[2].id,
                unit="test",
                dispatching_department_id=lab.id,
                vendor_id=vendors[2].id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                patient_ipd_requirement="MANDATORY",
                cost_per_unit=350.00
            ),
            Item(
                name="Blood Sugar (Fasting)",
                code="LAB002",
                category_id=categories[2].id,
                unit="test",
                dispatching_department_id=lab.id,
                vendor_id=vendors[2].id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                patient_ipd_requirement="MANDATORY",
                cost_per_unit=150.00
            ),
            # Radiology
            Item(
                name="X-Ray Chest PA",
                code="RAD001",
                category_id=categories[3].id,
                unit="test",
                dispatching_department_id=radiology.id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                patient_ipd_requirement="MANDATORY",
                cost_per_unit=500.00
            ),
            # Food
            Item(
                name="Patient Meal - Regular",
                code="FOOD001",
                category_id=categories[4].id,
                unit="meal",
                dispatching_department_id=kitchen.id,
                all_departments_allowed=True,
                workflow_phase="IPD",
                patient_ipd_requirement="MANDATORY",
                ipd_status_allowed="ACTIVE_ONLY",
                cost_per_unit=100.00
            ),
        ]
        for item in items:
            db.add(item)
        
        # Create return reasons (predefined list per requirements)
        return_reasons = [
            ReturnReason(reason="Unused"),
            ReturnReason(reason="Wrong Item"),
            ReturnReason(reason="Excess Quantity"),
            ReturnReason(reason="Defective Item"),
            ReturnReason(reason="Damaged Item"),
            ReturnReason(reason="Other"),
        ]
        for reason in return_reasons:
            db.add(reason)
        
        # Create sample patients
        patients = [
            Patient(
                uhid="UHID-0001",
                name="Ram Kumar",
                date_of_birth=datetime(1985, 5, 15).date(),
                gender="Male",
                phone="9898989898",
                blood_group="O+",
                address="123 Main Street, Delhi"
            ),
            Patient(
                uhid="UHID-0002",
                name="Sita Devi",
                date_of_birth=datetime(1990, 8, 20).date(),
                gender="Female",
                phone="9797979797",
                blood_group="A+",
                address="456 Park Avenue, Delhi"
            ),
        ]
        for patient in patients:
            db.add(patient)
        await db.flush()
        
        # Create IPD records
        ipd_records = [
            IPD(
                ipd_number="IPD-2024-0001",
                patient_id=patients[0].id,
                status="ACTIVE",
                current_phase="IPD",
                admission_date=datetime.now(timezone.utc),
                admitting_department_id=ward_a.id,
                current_department_id=ward_a.id,
                bed_number="A-101",
                primary_diagnosis="Fever with body ache"
            ),
            IPD(
                ipd_number="IPD-2024-0002",
                patient_id=patients[1].id,
                status="ACTIVE",
                current_phase="IPD",
                admission_date=datetime.now(timezone.utc),
                admitting_department_id=ward_b.id,
                current_department_id=ward_b.id,
                bed_number="B-205",
                primary_diagnosis="Post-operative care"
            ),
        ]
        for ipd in ipd_records:
            db.add(ipd)
        
        await db.commit()
        print("Seed data created successfully!")
        print("\n=== Login Credentials ===")
        print("Admin: 9999999999 / admin123")
        print("Ward A Doctor: 9876543210 / user123")
        print("Ward A Nurse: 9876543211 / user123")
        print("Pharmacist: 9876543212 / user123")
        print("Lab Tech: 9876543213 / user123")


if __name__ == "__main__":
    asyncio.run(seed_data())

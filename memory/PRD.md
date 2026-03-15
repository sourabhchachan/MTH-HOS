# MTH Hospital Operations System - PRD

## Project Overview
Order-driven hospital operating system where all hospital operations follow a universal workflow:
**Order Creation → Automated Routing → Order Dispatch → Order Receipt → Order Completion**

## Tech Stack
- **Backend**: FastAPI (Python) + PostgreSQL
- **Frontend**: React PWA (Mobile-first)
- **Authentication**: JWT with phone number login + "Keep me signed in" option
- **Permissions**: Department-based (not role-based)

## Branding & UI
- **Application Name**: MTH (no slogan or tagline)
- **Color Theme**: White background with Orange (#f97316) accents
- **Primary Color**: Orange (buttons, active tabs, badges, urgent indicators)
- **Mobile-first design**: Large touch-friendly inputs and buttons

## Core Requirements Implemented

### Data Seeding Module ✅ (NEW - March 2026)
One-click setup to populate operational hospital data:
- **14 Departments**: Admin, Emergency, OPD, IPD Ward, ICU, Laboratory, Radiology, Pharmacy, Central Store, Billing, Accounts, Housekeeping, Maintenance, Biomedical
- **8 Vendors**: Medical suppliers, Diagnostic labs, Radiology, Biomedical maintenance, Equipment, Housekeeping, Surgical supplies, Facility management
- **45+ Items**: Lab tests (CBC, LFT, KFT), Radiology (X-Ray, CT, MRI), Medicines (Paracetamol, Amoxicillin), Consumables (Syringes, Gloves), Services (Housekeeping, Maintenance)
- **20 Assets**: Ventilators, Monitors, Defibrillators, Beds, Wheelchairs, AC units, Computers
- **22 Staff Users**: Doctors, Nurses, Lab techs, Pharmacists, Store staff, Housekeeping, Maintenance
- **Default Password**: 1234 (for all seeded users)

### Bottom Navigation Bar ✅
- Fixed bottom navigation with 4 tabs: Home, Orders, Dispatch, Profile
- Orange highlight for active tab
- Touch-friendly tap targets (97.5x64px per button)
- Hidden on admin/login/reports/create pages

### Profile Page ✅
- User info card (name, designation, badges)
- Contact information (phone, email, employee code)
- Department info (primary + secondary)
- Admin Actions section for admin users
- Sign Out button

### Admin Setup Modules ✅
- **Departments Setup**: Create/Edit/Activate/Deactivate
- **Users Setup**: Create/Edit/Activate/Deactivate, reset passwords
- **Vendors Setup**: Create/Edit/Activate/Deactivate
- **Item Master Setup**: Full form + CSV bulk upload
- **Assets Setup**: Create/Edit with maintenance tracking
- **Patients Setup**: Create/Edit with search

### System Test Workflow ✅
- Guided 5-step wizard for admins
- Patient → Order → Dispatch → Receive → Complete

### Order System ✅
- Order creation with item selection
- Priority levels: Normal, Urgent (orange indicators)
- Patient IPD linkage (configurable per item)
- Auto-routing to dispatching department
- Order status tracking

### Return Order Workflow ✅
- Create return orders referencing original order
- Select items and quantities to return
- Return reason selection

### Dispatch System ✅
- Department-specific dispatch queues
- Partial dispatch support
- Dispatch event logging

### Receive System ✅
- Pending receive list
- Receipt confirmation
- Automatic order completion

### Billing Engine ✅
- Auto-generate billing on order completion
- Bill Amount = Dispatched Quantity × Item Cost
- Cost visibility restricted

## What's Been Implemented

### Backend Modules
1. **routes.py** - Core order, dispatch, receive APIs
2. **billing.py** - Billing engine with auto-generation
3. **reports.py** - Admin reports and insight engine
4. **patient_workflow.py** - Phase tracking and pre-admission
5. **assets.py** - Asset and maintenance management
6. **setup.py** - Admin setup modules
7. **data_seeder.py** - Quick data setup for operational testing

### Frontend Pages
1. **LoginPage** - Phone-based authentication with "Keep me signed in"
2. **DashboardPage** - User dashboard with MTH branding
3. **CreateOrderPage** - Order creation with cart
4. **CreateReturnPage** - Return order creation
5. **DispatchPage** - Dispatch queue management
6. **ReceivePage** - Receipt confirmation
7. **OrdersPage** - Order list with status tabs
8. **OrderDetailPage** - Detailed order view
9. **AdminPage** - Admin panel with 6 tabs
10. **ReportsPage** - Admin reports and analytics
11. **SystemTestPage** - Guided end-to-end test workflow
12. **ProfilePage** - User profile with admin actions
13. **DataSeedPage** - Quick data setup interface

### Frontend Components
1. **BottomNav** - Fixed bottom navigation bar

## P0 (Critical) - Completed ✅
- [x] Order workflow
- [x] Return order workflow
- [x] Billing engine
- [x] Admin reports
- [x] Patient workflow phases
- [x] Pre-admission process
- [x] Asset maintenance
- [x] Admin Setup Modules
- [x] UI/Branding Update (MTH, white + orange theme)
- [x] Session Persistence ("Keep me signed in")
- [x] System Test Workflow
- [x] Bottom Navigation Bar
- [x] Profile Page
- [x] Data Seeding Module

## P1 (Important) - Backlog
- [ ] PDF report generation
- [ ] Real-time notifications (WebSocket)
- [ ] Attendance tracking module
- [ ] Payroll integration

## P2 (Future) - Enhancements
- [ ] SMS/WhatsApp notifications
- [ ] Biometric attendance integration
- [ ] Payment gateway integration
- [ ] Inventory stock management
- [ ] Vendor reconciliation reports

## Login Credentials
| Role | Phone | Password |
|------|-------|----------|
| System Admin | 9999999999 | admin123 |
| Hospital Admin | 9999999998 | 1234 |
| Ward Doctor | 9876543210 | 1234 |
| ICU Consultant | 9876543220 | 1234 |
| Emergency Doctor | 9876543230 | 1234 |
| Lab Technician | 9876543240 | 1234 |
| Radiographer | 9876543250 | 1234 |
| Pharmacist | 9876543260 | 1234 |
| Store Incharge | 9876543270 | 1234 |
| Housekeeping | 9876543280 | 1234 |
| Maintenance | 9876543290 | 1234 |
| Biomedical | 9876543300 | 1234 |
| Billing | 9876543310 | 1234 |

## Navigation Structure

### Bottom Navigation (4 tabs)
| Tab | Path | Description |
|-----|------|-------------|
| Home | / | Dashboard with pending tasks, urgent orders, activity |
| Orders | /orders | Order list with Active/Done/Cancelled tabs |
| Dispatch | /dispatch | Dispatch queue for user's department |
| Profile | /profile | User info, department, admin actions, logout |

### Hidden Pages (no bottom nav)
- /login
- /admin
- /reports
- /create-order
- /create-return
- /system-test
- /data-seed

## API Endpoints Summary

### Data Seeding
- `GET /api/seed/status` - Get current seed status (counts)
- `POST /api/seed/all` - Seed all operational data
- `POST /api/seed/departments` - Seed departments only
- `POST /api/seed/vendors` - Seed vendors only
- `POST /api/seed/categories` - Seed categories only

### Core Order Operations
- `POST /api/orders` - Create order
- `GET /api/orders` - List orders
- `GET /api/orders/{id}` - Get order details

### Dispatch & Receive
- `GET /api/dispatch-queue` - Get dispatch queue
- `POST /api/dispatch` - Dispatch item
- `GET /api/pending-receive` - Get pending receives
- `POST /api/receive` - Receive item

### Admin Setup
- `GET /api/setup/departments/all` - List all departments
- `GET /api/setup/vendors/all` - List all vendors
- `GET /api/setup/items/all` - List all items
- `GET /api/setup/items/csv-template` - Get CSV template
- `POST /api/setup/items/csv-upload` - Upload items via CSV
- `GET /api/setup/users/all` - List all users
- `GET /api/setup/patients` - List patients

## Seeded Data Summary

### Departments (14)
Admin, Emergency, OPD, IPD Ward, ICU, Laboratory, Radiology, Pharmacy, Central Store, Billing, Accounts, Housekeeping, Maintenance, Biomedical

### Items by Category
- **Lab Tests (7)**: CBC, Blood Sugar, LFT, KFT, Thyroid, Urine, Blood Culture
- **Radiology (7)**: X-Ray Chest, X-Ray Abdomen, USG, CT Scan, MRI, ECG, 2D Echo
- **Medicines (8)**: Paracetamol, Amoxicillin, Omeprazole, Metformin, Amlodipine, Ceftriaxone, Normal Saline, Dextrose
- **Consumables (10)**: Syringes, IV Cannulas, Gloves, Cotton, Gauze, Masks, Urine Bags
- **Housekeeping (5)**: Bed Cleaning, Room Sanitization, Linen Change, Waste Disposal, Floor Mopping
- **Maintenance (7)**: AC, Plumbing, Electrical, Ventilator, Monitor, Infusion Pump, IT Support

### Assets (20)
Ventilators, Patient Monitors, Infusion Pumps, Defibrillators, ECG Machine, Oxygen Concentrator, Suction Machine, Wheelchair, Stretcher, Patient Beds, AC Units, Computers, Printers

### Vendors (8)
Medical Supplier, Diagnostic Lab, Radiology Center, Biomedical Maintenance, Equipment Supplier, Housekeeping/Laundry, Surgical Supplies, Facility Management

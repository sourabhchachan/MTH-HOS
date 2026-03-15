# MTH Hospital Operations System - PRD

## Project Overview
Order-driven hospital operating system where all hospital operations follow a universal workflow:
**Order Creation → Automated Routing → Order Dispatch → Order Receipt → Order Completion**

## Tech Stack
- **Backend**: FastAPI (Python) + PostgreSQL
- **Frontend**: React PWA (Mobile-first)
- **Authentication**: JWT with phone number login + "Keep me signed in" option
- **Permissions**: Department-based (not role-based)

## Branding & UI (Updated March 2026)
- **Application Name**: MTH (no slogan or tagline)
- **Color Theme**: White background with Orange (#f97316) accents
- **Primary Color**: Orange (buttons, active tabs, badges)
- **Mobile-first design**: Large touch-friendly inputs and buttons

## User Personas

### Hospital Staff (Ward/ICU/Emergency)
- Create orders for items (medicines, lab tests, consumables)
- Receive dispatched items
- Track order status
- Create return orders

### Dispatching Staff (Pharmacy/Lab/Kitchen)
- View dispatch queue with priority sorting
- Dispatch items (full or partial)
- Track pending dispatches

### Admin
- Manage departments, users, items, vendors, assets, patients
- View cost information and billing
- Access operational and financial reports
- Configure item permissions
- Run system test workflow
- Monitor insights and alerts

## Core Requirements Implemented

### Order System ✅
- [x] Order creation with item selection
- [x] Priority levels: Normal, Urgent (orange indicators)
- [x] Patient IPD linkage (configurable per item)
- [x] Auto-routing to dispatching department
- [x] Order status tracking: Created → Partially Dispatched → Fully Dispatched → Completed / Cancelled

### Authentication & Session ✅
- [x] Phone-based JWT authentication
- [x] "Keep me signed in" checkbox
- [x] Session persistence (localStorage for persistent, sessionStorage for session-only)
- [x] Secure token handling

### Admin Setup Modules ✅
- [x] **Departments Setup**: Create/Edit/Activate/Deactivate departments
- [x] **Users Setup**: Create/Edit/Activate/Deactivate users, reset passwords
- [x] **Vendors Setup**: Create/Edit/Activate/Deactivate vendors
- [x] **Item Master Setup**: 
  - Full form with all configuration fields
  - Bulk CSV upload with validation
  - Downloadable CSV template
  - Seed initial categories
- [x] **Assets Setup**: Create/Edit assets with maintenance tracking
- [x] **Patients Setup**: Create/Edit patients with search functionality

### System Test Workflow ✅ (NEW - March 2026)
- [x] Guided 5-step wizard for admins
- [x] Step 1: Create test patient
- [x] Step 2: Create order for patient
- [x] Step 3: Dispatch ordered item
- [x] Step 4: Receive dispatched item
- [x] Step 5: Verify completion and billing
- [x] Progress indicators
- [x] Reset functionality to run multiple tests

### Return Order Workflow ✅
- [x] Create return orders referencing original order
- [x] Select items and quantities to return
- [x] Return reason selection (configurable reasons)
- [x] Same workflow: Create → Route → Dispatch → Receive → Complete

### Dispatch System ✅
- [x] Department-specific dispatch queues
- [x] Partial dispatch support with quantity tracking
- [x] Dispatch event logging with user/time stamps
- [x] Batch number and expiry tracking

### Receive System ✅
- [x] Pending receive list for ordering departments
- [x] Receipt confirmation with quantity validation
- [x] Automatic order completion when all items received

### Billing Engine ✅
- [x] Auto-generate billing on order completion
- [x] Bill Amount = Dispatched Quantity × Item Cost
- [x] Billing records include: Patient UHID, IPD, Order ID, Items, Quantities
- [x] Cost visibility restricted to Admin and authorized users
- [x] Payment tracking and status management

## What's Been Implemented

### Backend Modules
1. **routes.py** - Core order, dispatch, receive APIs
2. **billing.py** - Billing engine with auto-generation
3. **reports.py** - Admin reports and insight engine
4. **patient_workflow.py** - Phase tracking and pre-admission
5. **assets.py** - Asset and maintenance management
6. **setup.py** - Admin setup modules (Departments, Users, Vendors, Items CSV, Patients)

### Frontend Pages
1. **LoginPage** - Phone-based authentication with "Keep me signed in"
2. **DashboardPage** - User dashboard with MTH branding, orange buttons
3. **CreateOrderPage** - Order creation with cart
4. **CreateReturnPage** - Return order creation
5. **DispatchPage** - Dispatch queue management
6. **ReceivePage** - Receipt confirmation
7. **OrdersPage** - Order list with status tabs
8. **OrderDetailPage** - Detailed order view
9. **AdminPage** - Comprehensive admin panel with 6 tabs
10. **ReportsPage** - Admin reports and analytics
11. **SystemTestPage** - Guided end-to-end test workflow

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
| Admin | 9999999999 | admin123 |
| Ward Doctor | 9876543210 | user123 |
| Ward Nurse | 9876543211 | user123 |
| Pharmacist | 9876543212 | user123 |
| Lab Tech | 9876543213 | user123 |

## API Endpoints Summary

### Core Order Operations
- `POST /api/orders` - Create order (regular or return)
- `GET /api/orders` - List orders
- `GET /api/orders/{id}` - Get order details
- `PUT /api/orders/{id}/cancel` - Cancel order

### Dispatch & Receive
- `GET /api/dispatch-queue` - Get dispatch queue
- `POST /api/dispatch` - Dispatch item
- `GET /api/pending-receive` - Get pending receives
- `POST /api/receive` - Receive item

### Billing
- `GET /api/billing` - List billing records
- `GET /api/billing/{id}` - Get billing details
- `GET /api/billing/summary/stats` - Billing summary
- `PUT /api/billing/{id}/payment` - Record payment

### Reports (Admin)
- `GET /api/reports/admin-dashboard` - Admin dashboard
- `GET /api/reports/operational/orders` - Orders report
- `GET /api/reports/financial/billing` - Billing report
- `GET /api/reports/insights` - Operational insights
- `GET /api/reports/export/{type}` - Export to CSV

### Admin Setup
- `GET /api/setup/departments/all` - List all departments
- `GET /api/setup/vendors/all` - List all vendors
- `PUT /api/setup/vendors/{id}` - Update vendor
- `PUT /api/setup/vendors/{id}/toggle-active` - Toggle vendor status
- `GET /api/setup/items/all` - List all items with full details
- `GET /api/setup/items/csv-template` - Get CSV template
- `POST /api/setup/items/csv-upload` - Upload items via CSV
- `POST /api/setup/seed-categories` - Seed initial item categories
- `GET /api/setup/users/all` - List all users
- `PUT /api/setup/users/{id}/reset-password` - Reset user password
- `GET /api/setup/patients` - List patients with search
- `POST /api/setup/patients` - Create patient
- `PUT /api/setup/patients/{id}` - Update patient

## Theme Configuration
```css
/* Primary Colors */
--primary: 24 95% 53%;           /* Orange #f97316 */
--primary-foreground: 0 0% 100%; /* White */
--background: 0 0% 100%;         /* White */
--foreground: 222 47% 11%;       /* Dark gray */

/* Accent Colors */
--urgent: 24 100% 50%;           /* Bright orange for urgent items */
--success: 142 76% 36%;          /* Green */
--destructive: 0 84% 60%;        /* Red */
```

## Item CSV Upload Template
| Column | Description | Example |
|--------|-------------|---------|
| item_name | Item name | Paracetamol 500mg |
| item_code | Unique code | MED001 |
| category | Category name | Medicines |
| dispatching_department_code | Department code | PHRM |
| departments_allowed_to_order | ALL or comma-separated codes | ALL |
| workflow_phase | Patient phase | IPD |
| priority_requirement | MANDATORY or NON_MANDATORY | NON_MANDATORY |
| patient_ipd_requirement | MANDATORY or NON_MANDATORY | NON_MANDATORY |
| ipd_status_allowed | ACTIVE_ONLY, INACTIVE_ONLY, BOTH | BOTH |
| cost | Unit cost | 2.50 |
| vendor_code | Vendor code | VEND001 |
| unit | Unit of measure | tablet |

## Initial Item Categories
- Medicines
- Lab Tests
- Radiology Tests
- Consumables
- Procedures
- Maintenance Requests
- Housekeeping Requests

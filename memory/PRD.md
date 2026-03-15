# MTH Hospital Operations System - PRD

## Project Overview
Order-driven hospital operating system where all hospital operations follow a universal workflow:
**Order Creation → Automated Routing → Order Dispatch → Order Receipt → Order Completion**

## Tech Stack
- **Backend**: FastAPI (Python) + PostgreSQL + Redis
- **Frontend**: React PWA (Mobile-first)
- **Authentication**: JWT with phone number login
- **Permissions**: Department-based (not role-based)

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
- Manage departments, users, items, vendors
- View cost information and billing
- Access operational and financial reports
- Configure item permissions
- Monitor insights and alerts

## Core Requirements Implemented

### Order System ✅
- [x] Order creation with item selection
- [x] Priority levels: Normal, Urgent
- [x] Patient IPD linkage (configurable per item)
- [x] Auto-routing to dispatching department
- [x] Order status tracking: Created → Partially Dispatched → Fully Dispatched → Completed / Cancelled

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

### Item Master ✅
- [x] Dispatching department configuration
- [x] Departments allowed to order (configurable)
- [x] Patient IPD requirement settings
- [x] Priority requirement settings
- [x] Vendor mapping
- [x] Cost per unit (restricted visibility)
- [x] Bulk upload via CSV template

### Patient Workflow Phase Tracking ✅
- [x] Six phases: Pre-Admission → Admission → IPD → Discharge → Post-Discharge → Archived
- [x] Phase transition logging with timestamps
- [x] Phase-wise patient analytics
- [x] Days in phase tracking

### Pre-Admission Process ✅
- [x] Eligibility check order creation
- [x] Patient admission workflow
- [x] Auto IPD creation on eligibility check
- [x] Phase transitions on admission completion

### Admin Reporting Framework ✅
- [x] Admin Dashboard with key metrics
- [x] Operational Reports (orders, dispatch performance, pending)
- [x] Financial Reports (billing, patient billing, vendor spend)
- [x] Export to CSV
- [x] Insight Engine with alerts

### Asset Maintenance Automation ✅
- [x] Asset CRUD operations
- [x] Maintenance tracking with scheduling
- [x] Next maintenance date tracking
- [x] Auto maintenance order generation
- [x] Asset assignment and return

### User Management ✅
- [x] Phone-based authentication
- [x] Primary + secondary department membership
- [x] Admin privileges
- [x] Cost visibility permissions
- [x] IPD reactivation permissions

## What's Been Implemented (Jan 2026)

### Backend Modules
1. **routes.py** - Core order, dispatch, receive APIs
2. **billing.py** - Billing engine with auto-generation
3. **reports.py** - Admin reports and insight engine
4. **patient_workflow.py** - Phase tracking and pre-admission
5. **assets.py** - Asset and maintenance management

### Frontend Pages
1. **LoginPage** - Phone-based authentication
2. **DashboardPage** - User dashboard with stats and quick actions
3. **CreateOrderPage** - Order creation with cart
4. **CreateReturnPage** - Return order creation
5. **DispatchPage** - Dispatch queue management
6. **ReceivePage** - Receipt confirmation
7. **OrdersPage** - Order list with status tabs
8. **OrderDetailPage** - Detailed order view
9. **AdminPage** - Admin panel for entity management
10. **ReportsPage** - Admin reports and analytics

## P0 (Critical) - Completed ✅
- [x] Return order workflow
- [x] Billing engine
- [x] Admin reports
- [x] Patient workflow phases
- [x] Pre-admission process
- [x] Asset maintenance

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

### Patient Workflow
- `POST /api/pre-admission/eligibility-check` - Eligibility check
- `POST /api/pre-admission/admit` - Admit patient
- `POST /api/patient/{id}/transition-to-ipd` - Phase transition
- `GET /api/patient-workflow/stats` - Phase statistics

### Assets
- `GET /api/assets` - List assets
- `POST /api/assets` - Create asset
- `GET /api/assets/maintenance-due` - Due maintenance
- `POST /api/assets/maintenance` - Record maintenance

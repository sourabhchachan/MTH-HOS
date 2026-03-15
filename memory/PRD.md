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

### Dispatching Staff (Pharmacy/Lab/Kitchen)
- View dispatch queue with priority sorting
- Dispatch items (full or partial)
- Track pending dispatches

### Admin
- Manage departments, users, items, vendors
- View cost information
- Configure item permissions

## Core Requirements (Static)

### Order System
- [x] Order creation with item selection
- [x] Priority levels: Normal, Urgent
- [x] Patient IPD linkage (configurable per item)
- [x] Auto-routing to dispatching department
- [x] Order status: Created → Partially Dispatched → Fully Dispatched → Completed / Cancelled

### Dispatch System
- [x] Department-specific dispatch queues
- [x] Partial dispatch support with quantity tracking
- [x] Dispatch event logging with user/time stamps
- [x] Batch number and expiry tracking

### Receive System
- [x] Pending receive list for ordering departments
- [x] Receipt confirmation with quantity validation
- [x] Automatic order completion when all items received

### Item Master
- [x] Dispatching department configuration
- [x] Departments allowed to order (configurable)
- [x] Patient IPD requirement settings
- [x] Priority requirement settings
- [x] Vendor mapping
- [x] Cost per unit (restricted visibility)

### User Management
- [x] Phone-based authentication
- [x] Primary + secondary department membership
- [x] Admin privileges
- [x] Cost visibility permissions
- [x] IPD reactivation permissions

## What's Been Implemented (MVP - Jan 2026)

### Backend
- FastAPI server with PostgreSQL
- Complete database schema (18+ tables)
- JWT authentication
- All CRUD operations for entities
- Order lifecycle management
- Dispatch/receive workflow APIs
- Department-based permission filtering

### Frontend (React PWA)
- Mobile-first design (dark theme)
- Login page with phone authentication
- Dashboard with stats and quick actions
- Order creation with cart system
- Dispatch queue with urgent highlighting
- Receive confirmation flow
- Order list with status tabs
- Order detail with timeline
- Admin panel (users, departments, items, vendors)

### Seed Data
- 10 departments (Admin, Ward A/B, ICU, Emergency, Pharmacy, Lab, Radiology, OT, Kitchen)
- 5 sample users with different roles
- 9 sample items across categories
- 3 vendors
- 5 item categories
- 6 return reasons
- 2 sample patients with active IPD

## P0 (Critical) - Next Priority
- [ ] Return order creation flow (UI)
- [ ] Billing generation on order completion
- [ ] Item deactivation enforcement

## P1 (Important) - Backlog
- [ ] IPD phase transition workflow
- [ ] Analytics dashboard for admin
- [ ] PDF bill generation
- [ ] Attendance tracking
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
- `POST /api/auth/login` - Phone login
- `GET /api/auth/me` - Current user profile
- `GET /api/dashboard` - User dashboard with stats
- `GET /api/items/orderable` - Items user can order
- `POST /api/orders` - Create order
- `GET /api/dispatch-queue` - Pending dispatch items
- `POST /api/dispatch` - Dispatch item
- `POST /api/receive` - Receive item
- Admin: departments, users, items, vendors CRUD

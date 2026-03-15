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

### Bottom Navigation Bar ✅ (NEW - March 2026)
- Fixed bottom navigation with 4 tabs: Home, Orders, Dispatch, Profile
- Orange highlight for active tab
- Touch-friendly tap targets (97.5x64px per button)
- Hidden on admin/login/reports/create pages
- pb-20 padding on all main pages

### Profile Page ✅ (NEW - March 2026)
- User info card (name, designation, badges)
- Contact information (phone, email, employee code)
- Department info (primary + secondary)
- Admin Actions section for admin users
- Sign Out button

### Authentication & Session ✅
- Phone-based JWT authentication
- "Keep me signed in" checkbox
- Session persistence (localStorage for persistent, sessionStorage for session-only)
- Secure token handling

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

## API Endpoints Summary

### Core Order Operations
- `POST /api/orders` - Create order
- `GET /api/orders` - List orders
- `GET /api/orders/{id}` - Get order details
- `PUT /api/orders/{id}/cancel` - Cancel order

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
- `POST /api/setup/patients` - Create patient

## Theme Configuration
```css
/* Primary Colors */
--primary: 24 95% 53%;           /* Orange #f97316 */
--primary-foreground: 0 0% 100%; /* White */
--background: 0 0% 100%;         /* White */
--foreground: 222 47% 11%;       /* Dark gray */

/* Active Tab Highlight */
text-orange-500                   /* Active nav tab color */
```

## Mobile Design Specifications
- **Bottom Nav Height**: h-16 (64px)
- **Nav Tap Targets**: 97.5x64px (exceeds 44px minimum)
- **Page Bottom Padding**: pb-20 (80px for nav clearance)
- **Input Height**: h-12 or h-14 for touch-friendly fields
- **Button Height**: h-12 or h-14 for touch-friendly buttons

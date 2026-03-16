"""
Test Suite for Admin Operational Dashboards
Tests all dashboard endpoints: main, department-workload, patients, patient-orders, billing, and exports
"""

import pytest
import requests
import os

# Use the public URL for testing
BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', 'https://mth-ops.preview.emergentagent.com').rstrip('/')

# Admin credentials for testing
ADMIN_PHONE = "8888888888"
ADMIN_PASSWORD = "password"


@pytest.fixture(scope="module")
def admin_token():
    """Get admin authentication token"""
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={"phone": ADMIN_PHONE, "password": ADMIN_PASSWORD}
    )
    assert response.status_code == 200, f"Admin login failed: {response.text}"
    data = response.json()
    assert "access_token" in data, "No access_token in login response"
    return data["access_token"]


@pytest.fixture(scope="module")
def auth_headers(admin_token):
    """Get authenticated headers"""
    return {"Authorization": f"Bearer {admin_token}"}


# ============ MAIN DASHBOARD TESTS ============

class TestMainDashboard:
    """Tests for GET /api/dashboards/main - Main admin dashboard with order and patient metrics"""
    
    def test_main_dashboard_requires_auth(self):
        """Test that main dashboard requires authentication"""
        response = requests.get(f"{BASE_URL}/api/dashboards/main")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("PASS: Main dashboard correctly requires authentication")
    
    def test_main_dashboard_success(self, auth_headers):
        """Test successful main dashboard retrieval with all metrics"""
        response = requests.get(f"{BASE_URL}/api/dashboards/main", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        
        # Verify order_metrics structure
        assert "order_metrics" in data, "Missing 'order_metrics'"
        order_metrics = data["order_metrics"]
        required_order_fields = [
            "orders_created_today",
            "orders_pending_dispatch",
            "orders_partially_dispatched",
            "orders_awaiting_receipt",
            "orders_completed_today",
            "urgent_orders_pending"
        ]
        for field in required_order_fields:
            assert field in order_metrics, f"Missing order metric: {field}"
            assert isinstance(order_metrics[field], int), f"{field} should be int"
        
        # Verify patient_metrics structure
        assert "patient_metrics" in data, "Missing 'patient_metrics'"
        patient_metrics = data["patient_metrics"]
        assert "active_ipd_patients" in patient_metrics, "Missing 'active_ipd_patients'"
        assert "patients_by_phase" in patient_metrics, "Missing 'patients_by_phase'"
        
        # Verify department_workload structure
        assert "department_workload" in data, "Missing 'department_workload'"
        assert isinstance(data["department_workload"], list), "department_workload should be a list"
        
        # Verify generated_at timestamp
        assert "generated_at" in data, "Missing 'generated_at'"
        
        print(f"PASS: Main Dashboard - Orders today: {order_metrics['orders_created_today']}, "
              f"Active IPD: {patient_metrics['active_ipd_patients']}, "
              f"Departments: {len(data['department_workload'])}")
    
    def test_main_dashboard_date_filter(self, auth_headers):
        """Test main dashboard with date filter"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/main",
            params={"date_filter": "2026-03-15"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "filters_applied" in data, "Missing 'filters_applied'"
        assert data["filters_applied"]["date"] == "2026-03-15", "Date filter not applied correctly"
        print("PASS: Main dashboard date filter works correctly")
    
    def test_main_dashboard_department_filter(self, auth_headers):
        """Test main dashboard with department filter"""
        # First get a valid department ID
        response = requests.get(f"{BASE_URL}/api/dashboards/main", headers=auth_headers)
        data = response.json()
        
        if data["department_workload"]:
            dept_id = data["department_workload"][0]["department_id"]
            
            # Now test with department filter
            filtered_response = requests.get(
                f"{BASE_URL}/api/dashboards/main",
                params={"department_id": dept_id},
                headers=auth_headers
            )
            assert filtered_response.status_code == 200, f"Expected 200, got {filtered_response.status_code}"
            
            filtered_data = filtered_response.json()
            assert filtered_data["filters_applied"]["department_id"] == dept_id
            print(f"PASS: Main dashboard department filter works (dept_id={dept_id})")
        else:
            pytest.skip("No departments available for filter test")


# ============ DEPARTMENT WORKLOAD TESTS ============

class TestDepartmentWorkload:
    """Tests for GET /api/dashboards/department-workload - Department workload statistics"""
    
    def test_department_workload_requires_auth(self):
        """Test that department workload requires authentication"""
        response = requests.get(f"{BASE_URL}/api/dashboards/department-workload")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("PASS: Department workload correctly requires authentication")
    
    def test_department_workload_success(self, auth_headers):
        """Test successful department workload retrieval"""
        response = requests.get(f"{BASE_URL}/api/dashboards/department-workload", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        
        # Verify structure
        assert "departments" in data, "Missing 'departments'"
        assert "summary" in data, "Missing 'summary'"
        assert "generated_at" in data, "Missing 'generated_at'"
        
        # Verify summary fields
        summary = data["summary"]
        assert "total_departments" in summary, "Missing 'total_departments'"
        assert "total_pending" in summary, "Missing 'total_pending'"
        assert "total_completed_today" in summary, "Missing 'total_completed_today'"
        
        # Verify department structure
        if data["departments"]:
            dept = data["departments"][0]
            required_fields = [
                "department_id", "department_name", "department_code",
                "total_orders_assigned", "pending_dispatch", "partially_dispatched",
                "completed_today", "urgent_orders_handled"
            ]
            for field in required_fields:
                assert field in dept, f"Missing department field: {field}"
        
        print(f"PASS: Department Workload - {len(data['departments'])} departments, "
              f"Total pending: {summary['total_pending']}, Completed today: {summary['total_completed_today']}")


# ============ PATIENT DASHBOARD TESTS ============

class TestPatientDashboard:
    """Tests for GET /api/dashboards/patients - Patient list with active IPD"""
    
    def test_patient_dashboard_requires_auth(self):
        """Test that patient dashboard requires authentication"""
        response = requests.get(f"{BASE_URL}/api/dashboards/patients")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("PASS: Patient dashboard correctly requires authentication")
    
    def test_patient_dashboard_success(self, auth_headers):
        """Test successful patient dashboard retrieval"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/patients",
            params={"status": "ACTIVE"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        
        # Verify structure
        assert "patients" in data, "Missing 'patients'"
        assert "summary" in data, "Missing 'summary'"
        assert "generated_at" in data, "Missing 'generated_at'"
        
        # Verify summary
        summary = data["summary"]
        assert "total_active_ipd" in summary, "Missing 'total_active_ipd'"
        assert "patients_by_phase" in summary, "Missing 'patients_by_phase'"
        
        # Verify patient structure if any exist
        if data["patients"]:
            patient = data["patients"][0]
            required_fields = [
                "patient_id", "patient_uhid", "patient_name",
                "ipd_id", "ipd_number", "current_phase",
                "total_orders", "total_billing"
            ]
            for field in required_fields:
                assert field in patient, f"Missing patient field: {field}"
        
        print(f"PASS: Patient Dashboard - {len(data['patients'])} patients, "
              f"Active IPD: {summary['total_active_ipd']}")
    
    def test_patient_dashboard_search(self, auth_headers):
        """Test patient dashboard search functionality"""
        # First get patients
        response = requests.get(
            f"{BASE_URL}/api/dashboards/patients",
            headers=auth_headers
        )
        data = response.json()
        
        if data["patients"]:
            search_term = data["patients"][0]["patient_name"][:5]
            search_response = requests.get(
                f"{BASE_URL}/api/dashboards/patients",
                params={"search": search_term},
                headers=auth_headers
            )
            assert search_response.status_code == 200
            print(f"PASS: Patient search works with term '{search_term}'")
        else:
            pytest.skip("No patients available for search test")


# ============ PATIENT ORDERS TESTS ============

class TestPatientOrders:
    """Tests for GET /api/dashboards/patients/{ipd_id}/orders - Patient orders with billing"""
    
    def test_patient_orders_requires_auth(self):
        """Test that patient orders requires authentication"""
        response = requests.get(f"{BASE_URL}/api/dashboards/patients/1/orders")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("PASS: Patient orders correctly requires authentication")
    
    def test_patient_orders_not_found(self, auth_headers):
        """Test patient orders with non-existent IPD"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/patients/99999/orders",
            headers=auth_headers
        )
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        print("PASS: Patient orders returns 404 for non-existent IPD")
    
    def test_patient_orders_success(self, auth_headers):
        """Test successful patient orders retrieval"""
        # First get an active IPD
        patients_response = requests.get(
            f"{BASE_URL}/api/dashboards/patients",
            params={"status": "ACTIVE"},
            headers=auth_headers
        )
        patients_data = patients_response.json()
        
        if not patients_data["patients"]:
            pytest.skip("No active IPD patients for orders test")
        
        ipd_id = patients_data["patients"][0]["ipd_id"]
        
        response = requests.get(
            f"{BASE_URL}/api/dashboards/patients/{ipd_id}/orders",
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        
        # Verify structure
        assert "patient" in data, "Missing 'patient'"
        assert "ipd" in data, "Missing 'ipd'"
        assert "orders" in data, "Missing 'orders'"
        assert "summary" in data, "Missing 'summary'"
        
        # Verify patient info
        assert "uhid" in data["patient"], "Missing patient uhid"
        assert "name" in data["patient"], "Missing patient name"
        
        # Verify IPD info
        assert "ipd_number" in data["ipd"], "Missing ipd_number"
        assert "status" in data["ipd"], "Missing ipd status"
        
        # Verify summary
        assert "total_orders" in data["summary"], "Missing total_orders"
        assert "total_billing" in data["summary"], "Missing total_billing"
        
        # Verify order structure if any
        if data["orders"]:
            order = data["orders"][0]
            required_fields = [
                "order_id", "order_number", "order_type",
                "status", "priority", "items_count"
            ]
            for field in required_fields:
                assert field in order, f"Missing order field: {field}"
        
        print(f"PASS: Patient Orders - IPD {ipd_id}: {data['summary']['total_orders']} orders, "
              f"Billing: {data['summary']['total_billing']}")


# ============ BILLING DASHBOARD TESTS ============

class TestBillingDashboard:
    """Tests for GET /api/dashboards/billing - Billing summary with breakdowns"""
    
    def test_billing_dashboard_requires_auth(self):
        """Test that billing dashboard requires authentication"""
        response = requests.get(f"{BASE_URL}/api/dashboards/billing")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("PASS: Billing dashboard correctly requires authentication")
    
    def test_billing_dashboard_success(self, auth_headers):
        """Test successful billing dashboard retrieval"""
        response = requests.get(f"{BASE_URL}/api/dashboards/billing", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        
        # Verify main metrics
        assert "total_billing_today" in data, "Missing 'total_billing_today'"
        assert "total_billing_this_month" in data, "Missing 'total_billing_this_month'"
        
        # Verify period info
        assert "period" in data, "Missing 'period'"
        period = data["period"]
        assert "from" in period, "Missing period 'from'"
        assert "to" in period, "Missing period 'to'"
        assert "total_amount" in period, "Missing 'total_amount'"
        assert "paid_amount" in period, "Missing 'paid_amount'"
        assert "pending_amount" in period, "Missing 'pending_amount'"
        
        # Verify breakdowns
        assert "billing_by_department" in data, "Missing 'billing_by_department'"
        assert "billing_by_item" in data, "Missing 'billing_by_item'"
        assert "billing_by_consultant" in data, "Missing 'billing_by_consultant'"
        
        print(f"PASS: Billing Dashboard - Today: {data['total_billing_today']}, "
              f"This Month: {data['total_billing_this_month']}")
    
    def test_billing_dashboard_date_range(self, auth_headers):
        """Test billing dashboard with date range filter"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/billing",
            params={"from_date": "2026-03-01", "to_date": "2026-03-15"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        
        data = response.json()
        assert data["period"]["from"] == "2026-03-01"
        assert data["period"]["to"] == "2026-03-15"
        print("PASS: Billing dashboard date range filter works")


# ============ EXPORT TESTS ============

class TestExportEndpoints:
    """Tests for CSV export endpoints"""
    
    def test_billing_export_csv(self, auth_headers):
        """Test billing dashboard CSV export"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/billing/export",
            params={"format": "csv"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        # Check content type
        content_type = response.headers.get("content-type", "")
        assert "text/csv" in content_type or response.text.startswith("BILLING"), \
            f"Expected CSV content, got content-type: {content_type}"
        
        # Verify CSV structure
        assert "BILLING SUMMARY REPORT" in response.text, "Missing report header"
        assert "BILLING BY DEPARTMENT" in response.text, "Missing department section"
        assert "BILLING BY ITEM" in response.text, "Missing item section"
        
        print("PASS: Billing CSV export works correctly")
    
    def test_department_workload_export_csv(self, auth_headers):
        """Test department workload CSV export"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/department-workload/export",
            params={"format": "csv"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        # Verify CSV structure
        assert "DEPARTMENT WORKLOAD REPORT" in response.text, "Missing report header"
        assert "Department" in response.text, "Missing Department column"
        
        print("PASS: Department workload CSV export works correctly")
    
    def test_patient_export_csv(self, auth_headers):
        """Test patient dashboard CSV export"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/patients/export",
            params={"status": "ACTIVE", "format": "csv"},
            headers=auth_headers
        )
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        # Verify CSV structure
        assert "PATIENT OPERATIONAL REPORT" in response.text, "Missing report header"
        assert "UHID" in response.text, "Missing UHID column"
        
        print("PASS: Patient dashboard CSV export works correctly")
    
    def test_export_json_format(self, auth_headers):
        """Test that JSON format also works for exports"""
        response = requests.get(
            f"{BASE_URL}/api/dashboards/billing/export",
            params={"format": "json"},
            headers=auth_headers
        )
        assert response.status_code == 200
        
        # Should return JSON data
        data = response.json()
        assert "total_billing_today" in data
        print("PASS: Export JSON format works correctly")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])

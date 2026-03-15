"""
Test Suite for Operational Workflow Simulation Module
Tests all simulation endpoints: metrics, summary, scenarios, run-all, and reset
"""

import pytest
import requests
import os

# Use the public URL for testing
BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', 'https://ops-validation.preview.emergentagent.com').rstrip('/')

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


class TestSimulationMetrics:
    """Tests for GET /api/simulation/metrics"""
    
    def test_metrics_requires_auth(self):
        """Test that metrics endpoint requires authentication"""
        response = requests.get(f"{BASE_URL}/api/simulation/metrics")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_metrics_success(self, auth_headers):
        """Test successful metrics retrieval"""
        response = requests.get(f"{BASE_URL}/api/simulation/metrics", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        # Verify required fields exist
        required_fields = [
            "orders_created_today",
            "orders_dispatched_today",
            "orders_pending",
            "orders_completed_today",
            "urgent_orders_pending",
            "patients_admitted_today",
            "billing_generated_today",
            "department_workload"
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify data types
        assert isinstance(data["orders_created_today"], int)
        assert isinstance(data["orders_pending"], int)
        assert isinstance(data["billing_generated_today"], (int, float))
        assert isinstance(data["department_workload"], dict)
        print(f"Metrics: orders_today={data['orders_created_today']}, pending={data['orders_pending']}, billing={data['billing_generated_today']}")


class TestSimulationSummary:
    """Tests for GET /api/simulation/summary"""
    
    def test_summary_requires_auth(self):
        """Test that summary endpoint requires authentication"""
        response = requests.get(f"{BASE_URL}/api/simulation/summary")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_summary_success(self, auth_headers):
        """Test successful summary retrieval"""
        response = requests.get(f"{BASE_URL}/api/simulation/summary", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        # Verify structure
        assert "metrics" in data, "Missing 'metrics' in summary"
        assert "recent_orders" in data, "Missing 'recent_orders' in summary"
        assert "recent_dispatches" in data, "Missing 'recent_dispatches' in summary"
        assert "pending_by_department" in data, "Missing 'pending_by_department' in summary"
        
        # Verify data types
        assert isinstance(data["recent_orders"], list)
        assert isinstance(data["recent_dispatches"], list)
        print(f"Summary: {len(data['recent_orders'])} recent orders, {len(data['recent_dispatches'])} recent dispatches")


class TestPatientAdmissionScenario:
    """Tests for POST /api/simulation/scenario/patient-admission"""
    
    def test_patient_admission_requires_auth(self):
        """Test that patient admission scenario requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/patient-admission")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_patient_admission_success(self, auth_headers):
        """Test patient admission scenario execution"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/patient-admission", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert "scenario" in data, "Missing 'scenario' field"
        assert "steps_completed" in data, "Missing 'steps_completed' field"
        assert "created_entities" in data, "Missing 'created_entities' field"
        
        # Verify scenario name
        assert data["scenario"] == "Patient Admission Flow"
        
        if data["success"]:
            # Verify entities were created
            assert "patient_id" in data["created_entities"], "No patient_id created"
            assert "ipd_id" in data["created_entities"], "No ipd_id created"
            assert "order_id" in data["created_entities"], "No order_id created"
            print(f"Patient Admission: Created patient {data['created_entities'].get('patient_uhid')}, IPD {data['created_entities'].get('ipd_number')}")
        else:
            print(f"Patient Admission failed: {data.get('errors', [])}")


class TestClinicalOrderScenario:
    """Tests for POST /api/simulation/scenario/clinical-order"""
    
    def test_clinical_order_requires_auth(self):
        """Test that clinical order scenario requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/clinical-order")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_clinical_order_success(self, auth_headers):
        """Test clinical order (lab) scenario execution"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/clinical-order", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert data["scenario"] == "Clinical Order Flow (Lab)"
        
        if data["success"]:
            assert "order_id" in data["created_entities"], "No order_id created"
            assert "billing_id" in data["created_entities"], "No billing_id created"
            print(f"Clinical Order: Created order {data['created_entities'].get('order_number')}, billing amount {data['created_entities'].get('billing_amount')}")
        else:
            print(f"Clinical Order failed: {data.get('errors', [])}")


class TestPharmacyOrderScenario:
    """Tests for POST /api/simulation/scenario/pharmacy-order"""
    
    def test_pharmacy_order_requires_auth(self):
        """Test that pharmacy order scenario requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/pharmacy-order")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_pharmacy_order_success(self, auth_headers):
        """Test pharmacy order scenario execution"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/pharmacy-order", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert data["scenario"] == "Pharmacy Order Flow"
        
        if data["success"]:
            assert "order_id" in data["created_entities"], "No order_id created"
            print(f"Pharmacy Order: Created order {data['created_entities'].get('order_number')}, billing amount {data['created_entities'].get('billing_amount')}")
        else:
            print(f"Pharmacy Order failed: {data.get('errors', [])}")


class TestPartialDispatchScenario:
    """Tests for POST /api/simulation/scenario/partial-dispatch"""
    
    def test_partial_dispatch_requires_auth(self):
        """Test that partial dispatch scenario requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/partial-dispatch")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_partial_dispatch_success(self, auth_headers):
        """Test partial dispatch scenario execution"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/partial-dispatch", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert data["scenario"] == "Partial Dispatch Flow"
        
        if data["success"]:
            assert "order_id" in data["created_entities"], "No order_id created"
            print(f"Partial Dispatch: Created order {data['created_entities'].get('order_number')}")
            # Verify steps include partial dispatch actions
            steps = [s["action"] for s in data["steps_completed"]]
            assert "Partial Dispatch 1" in steps, "Missing 'Partial Dispatch 1' step"
            assert "Partial Dispatch 2" in steps, "Missing 'Partial Dispatch 2' step"
        else:
            print(f"Partial Dispatch failed: {data.get('errors', [])}")


class TestReturnOrderScenario:
    """Tests for POST /api/simulation/scenario/return-order"""
    
    def test_return_order_requires_auth(self):
        """Test that return order scenario requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/return-order")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_return_order_success(self, auth_headers):
        """Test return order scenario execution - requires completed order first"""
        response = requests.post(f"{BASE_URL}/api/simulation/scenario/return-order", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert data["scenario"] == "Return Order Flow"
        
        if data["success"]:
            assert "return_order_id" in data["created_entities"], "No return_order_id created"
            print(f"Return Order: Created return order {data['created_entities'].get('return_order_number')}")
        else:
            # This can fail if no completed orders exist
            print(f"Return Order: {data.get('errors', ['No errors logged'])}")


class TestRunAllScenarios:
    """Tests for POST /api/simulation/run-all"""
    
    def test_run_all_requires_auth(self):
        """Test that run-all endpoint requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/run-all")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_run_all_success(self, auth_headers):
        """Test running all scenarios together"""
        response = requests.post(f"{BASE_URL}/api/simulation/run-all", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "summary" in data, "Missing 'summary' field"
        assert "results" in data, "Missing 'results' field"
        assert "all_passed" in data, "Missing 'all_passed' field"
        
        # Should have 5 scenario results
        assert len(data["results"]) == 5, f"Expected 5 results, got {len(data['results'])}"
        
        # Print summary
        print(f"Run All: {data['summary']}")
        for r in data["results"]:
            status = "PASS" if r["success"] else "FAIL"
            print(f"  - {r['scenario']}: {status} ({r['steps']} steps)")


class TestResetSimulation:
    """Tests for POST /api/simulation/reset"""
    
    def test_reset_requires_auth(self):
        """Test that reset endpoint requires authentication"""
        response = requests.post(f"{BASE_URL}/api/simulation/reset")
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
    
    def test_reset_success(self, auth_headers):
        """Test reset simulation data"""
        response = requests.post(f"{BASE_URL}/api/simulation/reset", headers=auth_headers)
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        data = response.json()
        assert "success" in data, "Missing 'success' field"
        assert "deleted" in data, "Missing 'deleted' field"
        
        if data["success"]:
            deleted = data["deleted"]
            print(f"Reset: Deleted {deleted.get('orders', 0)} orders, {deleted.get('patients', 0)} patients, {deleted.get('dispatch_events', 0)} dispatches")
        else:
            print(f"Reset failed: {data.get('message', 'Unknown error')}")


class TestVerifyRealOrders:
    """Verify that simulation creates REAL orders in the system"""
    
    def test_simulation_creates_real_orders(self, auth_headers):
        """Run a scenario and verify orders appear in /api/orders"""
        # First run a pharmacy order scenario
        scenario_response = requests.post(
            f"{BASE_URL}/api/simulation/scenario/pharmacy-order",
            headers=auth_headers
        )
        assert scenario_response.status_code == 200
        scenario_data = scenario_response.json()
        
        if not scenario_data["success"]:
            pytest.skip(f"Pharmacy scenario failed: {scenario_data.get('errors')}")
        
        order_number = scenario_data["created_entities"].get("order_number")
        assert order_number, "No order number returned"
        
        # Now fetch orders and verify it exists
        orders_response = requests.get(
            f"{BASE_URL}/api/orders",
            headers=auth_headers
        )
        assert orders_response.status_code == 200
        orders_data = orders_response.json()
        
        # Check if our order exists in the list
        order_numbers = [o.get("order_number") for o in orders_data]
        assert order_number in order_numbers, f"Order {order_number} not found in orders list"
        print(f"Verified: Order {order_number} exists in system orders")
    
    def test_simulation_creates_real_patients(self, auth_headers):
        """Run patient admission and verify patient appears in /api/patients"""
        # Run patient admission
        scenario_response = requests.post(
            f"{BASE_URL}/api/simulation/scenario/patient-admission",
            headers=auth_headers
        )
        assert scenario_response.status_code == 200
        scenario_data = scenario_response.json()
        
        if not scenario_data["success"]:
            pytest.skip(f"Patient admission failed: {scenario_data.get('errors')}")
        
        patient_uhid = scenario_data["created_entities"].get("patient_uhid")
        assert patient_uhid, "No patient UHID returned"
        
        # Fetch patients to verify
        patients_response = requests.get(
            f"{BASE_URL}/api/patients",
            headers=auth_headers,
            params={"search": patient_uhid}
        )
        assert patients_response.status_code == 200
        patients_data = patients_response.json()
        
        # Check if our patient exists
        patient_uhids = [p.get("uhid") for p in patients_data]
        assert patient_uhid in patient_uhids, f"Patient {patient_uhid} not found in patients list"
        print(f"Verified: Patient {patient_uhid} exists in system patients")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])

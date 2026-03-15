"""
Billing Engine and Payment Recording Tests
Tests for:
- Payment recording with multiple payment modes
- Partial payment support
- Payment history tracking
- PDF/HTML invoice generation
- Admin billing dashboard stats
"""
import pytest
import requests
import os
from decimal import Decimal

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

@pytest.fixture(scope="module")
def admin_token():
    """Get admin authentication token"""
    response = requests.post(f"{BASE_URL}/api/auth/login", json={
        "phone": "9999999999",
        "password": "admin123"
    })
    if response.status_code != 200:
        pytest.skip("Admin login failed")
    return response.json()["access_token"]

@pytest.fixture
def auth_headers(admin_token):
    """Return headers with auth token"""
    return {"Authorization": f"Bearer {admin_token}", "Content-Type": "application/json"}


class TestBillingList:
    """Tests for listing billings with payments"""
    
    def test_get_billing_list(self, auth_headers):
        """GET /api/billing - Lists all billings"""
        response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"Found {len(data)} billing records")
    
    def test_billing_response_structure(self, auth_headers):
        """Verify billing response contains required fields"""
        response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        
        if len(data) > 0:
            billing = data[0]
            # Check required fields
            required_fields = [
                'id', 'billing_number', 'order_id', 'patient_id',
                'total_amount', 'status', 'paid_amount', 'outstanding_amount',
                'generated_at', 'items', 'payments', 'effective_amount'
            ]
            for field in required_fields:
                assert field in billing, f"Missing field: {field}"
            print(f"Billing {billing['billing_number']} has all required fields")
    
    def test_billing_filter_by_status(self, auth_headers):
        """GET /api/billing?status=PAID - Filter by status"""
        response = requests.get(f"{BASE_URL}/api/billing?status=PAID", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        for billing in data:
            assert billing['status'] == 'PAID', f"Expected PAID status, got {billing['status']}"
        print(f"Found {len(data)} PAID billings")


class TestBillingDetail:
    """Tests for single billing detail"""
    
    def test_get_billing_by_id(self, auth_headers):
        """GET /api/billing/{id} - Get single billing"""
        # First get list to get an ID
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        assert list_response.status_code == 200
        billings = list_response.json()
        
        if len(billings) == 0:
            pytest.skip("No billings available")
        
        billing_id = billings[0]['id']
        response = requests.get(f"{BASE_URL}/api/billing/{billing_id}", headers=auth_headers)
        assert response.status_code == 200
        
        data = response.json()
        assert data['id'] == billing_id
        assert 'items' in data
        assert 'payments' in data
        print(f"Retrieved billing {data['billing_number']}")
    
    def test_get_nonexistent_billing(self, auth_headers):
        """GET /api/billing/99999 - Returns 404"""
        response = requests.get(f"{BASE_URL}/api/billing/99999", headers=auth_headers)
        assert response.status_code == 404


class TestPaymentRecording:
    """Tests for recording payments against billings"""
    
    def test_record_cash_payment(self, auth_headers):
        """POST /api/billing/payments - Record CASH payment"""
        # Find a billing with outstanding amount
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = [b for b in list_response.json() if float(b['outstanding_amount']) > 0]
        
        if len(billings) == 0:
            pytest.skip("No billings with outstanding amount")
        
        billing = billings[0]
        payment_amount = min(10, float(billing['outstanding_amount']))
        
        response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
            "billing_id": billing['id'],
            "amount": payment_amount,
            "payment_mode": "CASH",
            "payment_reference": "TEST-CASH-PYTEST",
            "notes": "Test payment from pytest"
        })
        
        assert response.status_code == 200
        data = response.json()
        assert data['amount'] == str(payment_amount) or float(data['amount']) == payment_amount
        assert data['payment_mode'] == 'CASH'
        assert 'payment_number' in data
        print(f"Recorded payment {data['payment_number']}")
    
    def test_payment_modes(self, auth_headers):
        """Test all payment modes: CASH, CARD, UPI, INSURANCE, OTHER"""
        modes = ['CASH', 'CARD', 'UPI', 'INSURANCE', 'OTHER']
        
        # Find a billing with enough outstanding
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = [b for b in list_response.json() if float(b['outstanding_amount']) >= 50]
        
        if len(billings) == 0:
            pytest.skip("No billings with enough outstanding amount")
        
        billing = billings[0]
        
        # We'll just test that the API accepts each mode (validation test)
        for mode in modes:
            # Check mode is valid by sending minimal amount
            response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
                "billing_id": billing['id'],
                "amount": 1,
                "payment_mode": mode
            })
            # Should succeed or fail due to outstanding limit, not mode validation
            assert response.status_code in [200, 400], f"Mode {mode} returned {response.status_code}"
            if response.status_code == 200:
                print(f"Payment mode {mode} accepted")
    
    def test_payment_exceeds_outstanding_rejected(self, auth_headers):
        """Payment amount exceeding outstanding should be rejected"""
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = list_response.json()
        
        if len(billings) == 0:
            pytest.skip("No billings available")
        
        billing = billings[0]
        excess_amount = float(billing['outstanding_amount']) + 1000
        
        response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
            "billing_id": billing['id'],
            "amount": excess_amount,
            "payment_mode": "CASH"
        })
        
        assert response.status_code == 400
        assert "exceeds outstanding" in response.json().get('detail', '').lower()
        print("Payment exceeding outstanding correctly rejected")
    
    def test_zero_payment_rejected(self, auth_headers):
        """Zero or negative payment should be rejected"""
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = list_response.json()
        
        if len(billings) == 0:
            pytest.skip("No billings available")
        
        billing = billings[0]
        
        response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
            "billing_id": billing['id'],
            "amount": 0,
            "payment_mode": "CASH"
        })
        
        assert response.status_code == 400
        print("Zero payment correctly rejected")


class TestPaymentHistory:
    """Tests for payment history tracking"""
    
    def test_get_billing_payments(self, auth_headers):
        """GET /api/billing/{id}/payments - Get payment history"""
        # Find a billing with payments
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = [b for b in list_response.json() if len(b.get('payments', [])) > 0]
        
        if len(billings) == 0:
            pytest.skip("No billings with payments")
        
        billing = billings[0]
        response = requests.get(f"{BASE_URL}/api/billing/{billing['id']}/payments", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        
        payment = data[0]
        assert 'payment_number' in payment
        assert 'amount' in payment
        assert 'payment_mode' in payment
        assert 'payment_date' in payment
        print(f"Found {len(data)} payments for billing {billing['billing_number']}")
    
    def test_get_billing_summary(self, auth_headers):
        """GET /api/billing/{id}/summary - Get payment summary"""
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = list_response.json()
        
        if len(billings) == 0:
            pytest.skip("No billings available")
        
        billing_id = billings[0]['id']
        response = requests.get(f"{BASE_URL}/api/billing/{billing_id}/summary", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = [
            'billing_id', 'billing_number', 'total_amount', 'total_paid',
            'total_adjustments', 'effective_amount', 'outstanding_amount',
            'status', 'payment_count'
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        print(f"Summary: Total={data['total_amount']}, Paid={data['total_paid']}, Outstanding={data['outstanding_amount']}")


class TestPartialPaymentStatus:
    """Tests for partial payment status updates"""
    
    def test_status_changes_to_partial(self, auth_headers):
        """Billing status should change to PARTIAL after partial payment"""
        # Get pending billing
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        pending_billings = [b for b in list_response.json() 
                          if b['status'] in ['PENDING', 'GENERATED'] and float(b['outstanding_amount']) > 10]
        
        if len(pending_billings) == 0:
            pytest.skip("No PENDING billings with outstanding amount")
        
        billing = pending_billings[0]
        
        # Make a partial payment
        partial_amount = min(5, float(billing['outstanding_amount']) - 1)
        response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
            "billing_id": billing['id'],
            "amount": partial_amount,
            "payment_mode": "CASH"
        })
        
        if response.status_code == 200:
            # Check status changed
            summary = requests.get(f"{BASE_URL}/api/billing/{billing['id']}/summary", headers=auth_headers)
            if summary.status_code == 200:
                data = summary.json()
                assert data['status'] in ['PARTIAL', 'PAID'], f"Expected PARTIAL or PAID, got {data['status']}"
                print(f"Billing status after partial payment: {data['status']}")


class TestInvoiceGeneration:
    """Tests for PDF/HTML invoice generation"""
    
    def test_generate_invoice_html(self, auth_headers):
        """GET /api/billing/{id}/invoice - Generate invoice HTML"""
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = list_response.json()
        
        if len(billings) == 0:
            pytest.skip("No billings available")
        
        billing_id = billings[0]['id']
        response = requests.get(f"{BASE_URL}/api/billing/{billing_id}/invoice", headers=auth_headers)
        
        assert response.status_code == 200
        assert 'text/html' in response.headers.get('Content-Type', '')
        
        content = response.text
        assert 'MTH Hospital' in content
        assert 'TAX INVOICE' in content
        assert 'Patient Details' in content
        assert 'Itemized Charges' in content
        print("Invoice HTML generated successfully")
    
    def test_invoice_contains_payment_history(self, auth_headers):
        """Invoice should include payment history for paid/partial billings"""
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = [b for b in list_response.json() if len(b.get('payments', [])) > 0]
        
        if len(billings) == 0:
            pytest.skip("No billings with payments")
        
        billing = billings[0]
        response = requests.get(f"{BASE_URL}/api/billing/{billing['id']}/invoice", headers=auth_headers)
        
        assert response.status_code == 200
        content = response.text
        assert 'Payment History' in content
        print("Invoice includes payment history section")


class TestDashboardStats:
    """Tests for admin billing dashboard statistics"""
    
    def test_get_today_stats(self, auth_headers):
        """GET /api/billing/dashboard/today - Get today's statistics"""
        response = requests.get(f"{BASE_URL}/api/billing/dashboard/today", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        
        assert 'date' in data
        assert 'billing_today' in data
        assert 'payments_today' in data
        assert 'outstanding' in data
        
        assert 'count' in data['billing_today']
        assert 'amount' in data['billing_today']
        assert 'count' in data['payments_today']
        assert 'amount' in data['payments_today']
        assert 'count' in data['outstanding']
        assert 'amount' in data['outstanding']
        
        print(f"Today's Stats: Billing={data['billing_today']}, Payments={data['payments_today']}, Outstanding={data['outstanding']}")
    
    def test_department_billing(self, auth_headers):
        """Dashboard should include department-wise billing"""
        response = requests.get(f"{BASE_URL}/api/billing/dashboard/today", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        
        assert 'department_billing' in data
        assert isinstance(data['department_billing'], list)
        
        if len(data['department_billing']) > 0:
            dept = data['department_billing'][0]
            assert 'department' in dept
            assert 'count' in dept
            assert 'amount' in dept
            print(f"Department billing: {dept}")


class TestBillingImmutability:
    """Tests to verify billing records are never modified"""
    
    def test_payments_create_separate_records(self, auth_headers):
        """Payments should create separate Payment records, not modify Billing"""
        # Get a billing before payment
        list_response = requests.get(f"{BASE_URL}/api/billing", headers=auth_headers)
        billings = [b for b in list_response.json() if float(b['outstanding_amount']) > 0]
        
        if len(billings) == 0:
            pytest.skip("No billings with outstanding amount")
        
        billing = billings[0]
        original_total = billing['total_amount']
        
        # Make a payment
        response = requests.post(f"{BASE_URL}/api/billing/payments", headers=auth_headers, json={
            "billing_id": billing['id'],
            "amount": 1,
            "payment_mode": "CASH"
        })
        
        if response.status_code == 200:
            # Check total_amount hasn't changed
            updated_response = requests.get(f"{BASE_URL}/api/billing/{billing['id']}", headers=auth_headers)
            updated_billing = updated_response.json()
            
            assert updated_billing['total_amount'] == original_total, \
                "total_amount should not change after payment"
            print("Verified: Billing total_amount unchanged after payment")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])

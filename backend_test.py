import requests
import sys
import json
from datetime import datetime

class MTHBackendTester:
    def __init__(self, base_url="https://returns-workflow-2.preview.emergentagent.com"):
        self.base_url = base_url
        self.admin_token = None
        self.ward_token = None
        self.pharmacist_token = None
        self.tests_run = 0
        self.tests_passed = 0
        
        # Test credentials
        self.admin_creds = {"phone": "9999999999", "password": "admin123"}
        self.ward_creds = {"phone": "9876543210", "password": "user123"}
        self.pharmacist_creds = {"phone": "9876543212", "password": "user123"}

    def run_test(self, name, method, endpoint, expected_status, data=None, token=None):
        """Run a single API test"""
        url = f"{self.base_url}/api/{endpoint}"
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = f'Bearer {token}'

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers)
            elif method == 'PUT':
                response = requests.put(url, json=data, headers=headers)
            elif method == 'DELETE':
                response = requests.delete(url, headers=headers)

            success = response.status_code == expected_status
            if success:
                self.tests_passed += 1
                print(f"✅ PASSED - Status: {response.status_code}")
                try:
                    return success, response.json()
                except:
                    return success, response.text
            else:
                print(f"❌ FAILED - Expected {expected_status}, got {response.status_code}")
                print(f"   Response: {response.text[:200]}")
                return False, {}

        except Exception as e:
            print(f"❌ FAILED - Error: {str(e)}")
            return False, {}

    def test_auth_flow(self):
        """Test authentication for all user types"""
        print("\n" + "="*50)
        print("TESTING AUTHENTICATION FLOW")
        print("="*50)
        
        # Test admin login
        success, response = self.run_test(
            "Admin Login",
            "POST", 
            "auth/login",
            200,
            data=self.admin_creds
        )
        if success and 'access_token' in response:
            self.admin_token = response['access_token']
            print(f"   Admin token obtained")
        
        # Test ward staff login
        success, response = self.run_test(
            "Ward Staff Login",
            "POST",
            "auth/login", 
            200,
            data=self.ward_creds
        )
        if success and 'access_token' in response:
            self.ward_token = response['access_token']
            print(f"   Ward token obtained")
            
        # Test pharmacist login
        success, response = self.run_test(
            "Pharmacist Login",
            "POST",
            "auth/login",
            200, 
            data=self.pharmacist_creds
        )
        if success and 'access_token' in response:
            self.pharmacist_token = response['access_token']
            print(f"   Pharmacist token obtained")
        
        # Test invalid login
        self.run_test(
            "Invalid Login",
            "POST",
            "auth/login",
            401,
            data={"phone": "1234567890", "password": "wrongpass"}
        )

    def test_user_profile(self):
        """Test user profile endpoints"""
        print("\n" + "="*50)
        print("TESTING USER PROFILES")
        print("="*50)
        
        if self.admin_token:
            self.run_test(
                "Admin Profile",
                "GET",
                "auth/me",
                200,
                token=self.admin_token
            )
        
        if self.ward_token:
            self.run_test(
                "Ward Staff Profile", 
                "GET",
                "auth/me",
                200,
                token=self.ward_token
            )

    def test_dashboard(self):
        """Test dashboard endpoint"""
        print("\n" + "="*50)
        print("TESTING DASHBOARD")
        print("="*50)
        
        if self.admin_token:
            self.run_test(
                "Admin Dashboard",
                "GET", 
                "dashboard",
                200,
                token=self.admin_token
            )
            
        if self.ward_token:
            self.run_test(
                "Ward Dashboard",
                "GET",
                "dashboard", 
                200,
                token=self.ward_token
            )

    def test_departments(self):
        """Test department endpoints"""
        print("\n" + "="*50)
        print("TESTING DEPARTMENTS")
        print("="*50)
        
        if self.admin_token:
            # List departments
            self.run_test(
                "List Departments",
                "GET",
                "departments", 
                200,
                token=self.admin_token
            )

    def test_items(self):
        """Test item endpoints"""
        print("\n" + "="*50)
        print("TESTING ITEMS")
        print("="*50)
        
        if self.ward_token:
            # Get orderable items for ward staff
            self.run_test(
                "Get Orderable Items",
                "GET",
                "items/orderable",
                200,
                token=self.ward_token
            )
            
        if self.admin_token:
            # List all items for admin
            self.run_test(
                "List All Items (Admin)",
                "GET", 
                "items",
                200,
                token=self.admin_token
            )

    def test_orders(self):
        """Test order endpoints"""
        print("\n" + "="*50)
        print("TESTING ORDERS")
        print("="*50)
        
        if self.ward_token:
            # List orders
            self.run_test(
                "List Orders",
                "GET",
                "orders",
                200,
                token=self.ward_token
            )

    def test_dispatch_receive(self):
        """Test dispatch and receive endpoints"""
        print("\n" + "="*50)
        print("TESTING DISPATCH & RECEIVE")
        print("="*50)
        
        if self.pharmacist_token:
            # Get dispatch queue
            self.run_test(
                "Dispatch Queue",
                "GET",
                "dispatch-queue",
                200,
                token=self.pharmacist_token
            )
            
        if self.ward_token:
            # Get pending receive
            self.run_test(
                "Pending Receive",
                "GET",
                "pending-receive", 
                200,
                token=self.ward_token
            )

    def test_admin_endpoints(self):
        """Test admin-only endpoints"""
        print("\n" + "="*50)
        print("TESTING ADMIN ENDPOINTS")
        print("="*50)
        
        if self.admin_token:
            # List users
            self.run_test(
                "List Users (Admin)",
                "GET",
                "users",
                200,
                token=self.admin_token
            )
            
            # List vendors
            self.run_test(
                "List Vendors (Admin)",
                "GET", 
                "vendors",
                200,
                token=self.admin_token
            )
        
        # Test ward staff accessing admin endpoints (should fail)
        if self.ward_token:
            self.run_test(
                "Non-Admin Access to Users",
                "GET",
                "users",
                403,  # Should be forbidden
                token=self.ward_token
            )
            
    def test_billing_endpoints(self):
        """Test billing engine endpoints"""
        print("\n" + "="*50)
        print("TESTING BILLING ENGINE")
        print("="*50)
        
        if self.admin_token:
            # List billing records
            self.run_test(
                "List Billing Records",
                "GET",
                "billing",
                200,
                token=self.admin_token
            )
            
            # Get billing summary
            self.run_test(
                "Billing Summary Stats",
                "GET",
                "billing/summary/stats",
                200,
                token=self.admin_token
            )

    def test_reports_endpoints(self):
        """Test admin reports framework"""
        print("\n" + "="*50)
        print("TESTING ADMIN REPORTS")
        print("="*50)
        
        if self.admin_token:
            # Admin dashboard report
            self.run_test(
                "Admin Dashboard Report",
                "GET",
                "reports/admin-dashboard",
                200,
                token=self.admin_token
            )
            
            # Orders operational report
            self.run_test(
                "Orders Operational Report",
                "GET",
                "reports/operational/orders",
                200,
                token=self.admin_token
            )
            
            # Financial billing report
            self.run_test(
                "Financial Billing Report",
                "GET",
                "reports/financial/billing",
                200,
                token=self.admin_token
            )
            
            # Pending orders report
            self.run_test(
                "Pending Orders Report",
                "GET",
                "reports/operational/pending-orders",
                200,
                token=self.admin_token
            )
            
            # Operational insights
            self.run_test(
                "Operational Insights",
                "GET",
                "reports/insights",
                200,
                token=self.admin_token
            )

    def test_patient_workflow_endpoints(self):
        """Test patient workflow and pre-admission"""
        print("\n" + "="*50)
        print("TESTING PATIENT WORKFLOW")
        print("="*50)
        
        if self.ward_token:
            # Get workflow phase stats
            success, response = self.run_test(
                "Workflow Phase Stats",
                "GET",
                "patient-workflow/stats",
                200,
                token=self.admin_token  # Needs admin access
            )
            
            # Get patients by phase
            self.run_test(
                "Patients by Phase",
                "GET",
                "patient-workflow/patients",
                200,
                token=self.ward_token
            )

    def test_asset_management_endpoints(self):
        """Test asset management automation"""
        print("\n" + "="*50)
        print("TESTING ASSET MANAGEMENT")
        print("="*50)
        
        if self.admin_token:
            # List assets
            self.run_test(
                "List Assets",
                "GET",
                "assets",
                200,
                token=self.admin_token
            )
            
            # List maintenance records
            self.run_test(
                "Asset Maintenance Records",
                "GET",
                "assets/maintenance",
                200,
                token=self.admin_token
            )
            
            # Get maintenance due
            self.run_test(
                "Assets Maintenance Due",
                "GET",
                "assets/maintenance-due",
                200,
                token=self.admin_token
            )

    def run_all_tests(self):
        """Run all backend tests"""
        print(f"🏥 MTH HOSPITAL BACKEND API TESTING")
        print(f"Backend URL: {self.base_url}")
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        try:
            self.test_auth_flow()
            self.test_user_profile()
            self.test_dashboard() 
            self.test_departments()
            self.test_items()
            self.test_orders()
            self.test_dispatch_receive()
            self.test_admin_endpoints()
            self.test_billing_endpoints()
            self.test_reports_endpoints()
            self.test_patient_workflow_endpoints()
            self.test_asset_management_endpoints()
            
        except KeyboardInterrupt:
            print("\n❌ Testing interrupted by user")
            
        # Print final results
        print(f"\n" + "="*50)
        print(f"📊 TESTING COMPLETE")
        print(f"="*50)
        print(f"Tests passed: {self.tests_passed}/{self.tests_run}")
        success_rate = (self.tests_passed / self.tests_run * 100) if self.tests_run > 0 else 0
        print(f"Success rate: {success_rate:.1f}%")
        
        if self.tests_passed == self.tests_run:
            print("🎉 ALL TESTS PASSED!")
            return True
        else:
            print(f"⚠️  {self.tests_run - self.tests_passed} tests failed")
            return False

def main():
    tester = MTHBackendTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
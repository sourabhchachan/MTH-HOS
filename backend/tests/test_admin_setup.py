"""
Test Admin Setup APIs
Tests Departments, Users, Vendors, Items, Assets, Patients admin setup endpoints
"""
import pytest
import requests
import os

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

class TestAdminSetup:
    """Admin Setup Module Tests - Departments, Users, Vendors, Items, Assets, Patients"""
    
    @pytest.fixture(scope="class")
    def admin_token(self):
        """Get admin auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "9999999999",
            "password": "admin123"
        })
        assert response.status_code == 200, f"Admin login failed: {response.text}"
        return response.json()["access_token"]
    
    @pytest.fixture(scope="class")
    def admin_headers(self, admin_token):
        """Get headers with admin auth"""
        return {
            "Authorization": f"Bearer {admin_token}",
            "Content-Type": "application/json"
        }
    
    # ============ DEPARTMENTS TESTS ============
    
    def test_list_all_departments(self, admin_headers):
        """Test GET /api/setup/departments/all - List all departments including inactive"""
        response = requests.get(f"{BASE_URL}/api/setup/departments/all", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of departments"
        if len(data) > 0:
            dept = data[0]
            assert "id" in dept
            assert "name" in dept
            assert "code" in dept
            assert "is_active" in dept
            print(f"✓ Found {len(data)} departments")
    
    def test_create_department(self, admin_headers):
        """Test POST /api/departments - Create new department"""
        import time
        unique_id = int(time.time())
        payload = {
            "name": f"TEST_Department_{unique_id}",
            "code": f"TESTD{unique_id}",
            "description": "Test department for testing"
        }
        response = requests.post(f"{BASE_URL}/api/departments", json=payload, headers=admin_headers)
        assert response.status_code == 200, f"Failed to create department: {response.text}"
        data = response.json()
        assert data["name"] == payload["name"]
        assert data["code"] == payload["code"]
        print(f"✓ Created department: {data['name']}")
        return data["id"]
    
    def test_update_department(self, admin_headers):
        """Test PUT /api/departments/{id} - Update department"""
        # First get all departments to find one to update
        response = requests.get(f"{BASE_URL}/api/setup/departments/all", headers=admin_headers)
        depts = response.json()
        test_dept = next((d for d in depts if d["code"] == "TESTD001"), None)
        
        if test_dept:
            update_payload = {
                "name": "TEST_Department_Updated",
                "description": "Updated description"
            }
            response = requests.put(f"{BASE_URL}/api/departments/{test_dept['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            data = response.json()
            assert data["name"] == update_payload["name"]
            print(f"✓ Updated department: {data['name']}")
        else:
            pytest.skip("No test department found to update")
    
    def test_toggle_department_active(self, admin_headers):
        """Test department activation/deactivation via PUT"""
        response = requests.get(f"{BASE_URL}/api/setup/departments/all", headers=admin_headers)
        depts = response.json()
        test_dept = next((d for d in depts if d["code"] == "TESTD001"), None)
        
        if test_dept:
            # Toggle active status
            new_status = not test_dept["is_active"]
            update_payload = {"is_active": new_status}
            response = requests.put(f"{BASE_URL}/api/departments/{test_dept['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to toggle: {response.text}"
            data = response.json()
            assert data["is_active"] == new_status
            print(f"✓ Toggled department active status to: {new_status}")
        else:
            pytest.skip("No test department found")
    
    # ============ USERS TESTS ============
    
    def test_list_all_users(self, admin_headers):
        """Test GET /api/setup/users/all - List all users including inactive"""
        response = requests.get(f"{BASE_URL}/api/setup/users/all", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of users"
        if len(data) > 0:
            user = data[0]
            assert "id" in user
            assert "name" in user
            assert "phone" in user
            assert "is_admin" in user
            assert "is_active" in user
            print(f"✓ Found {len(data)} users")
    
    def test_create_user(self, admin_headers):
        """Test POST /api/users - Create new user with default password"""
        # First get departments for primary_department_id
        depts_resp = requests.get(f"{BASE_URL}/api/departments", headers=admin_headers)
        depts = depts_resp.json()
        dept_id = depts[0]["id"] if depts else 1
        
        payload = {
            "phone": "9111111111",
            "name": "TEST_User_001",
            "password": "password123",
            "primary_department_id": dept_id,
            "is_admin": False,
            "can_view_costs": False,
            "designation": "Test Staff",
            "employee_code": "TESTUSER001"
        }
        response = requests.post(f"{BASE_URL}/api/users", json=payload, headers=admin_headers)
        # Might fail if phone already exists, that's okay
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            print(f"✓ Created user: {data['name']}")
        elif response.status_code == 400:
            print(f"⚠ User creation skipped - phone may already exist")
        else:
            assert False, f"Unexpected error: {response.text}"
    
    def test_update_user(self, admin_headers):
        """Test PUT /api/users/{id} - Update user"""
        response = requests.get(f"{BASE_URL}/api/setup/users/all", headers=admin_headers)
        users = response.json()
        test_user = next((u for u in users if u["name"] and "TEST_" in u["name"]), None)
        
        if test_user:
            update_payload = {
                "name": "TEST_User_Updated",
                "designation": "Updated Staff"
            }
            response = requests.put(f"{BASE_URL}/api/users/{test_user['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            data = response.json()
            assert data["name"] == update_payload["name"]
            print(f"✓ Updated user: {data['name']}")
        else:
            pytest.skip("No test user found")
    
    def test_reset_user_password(self, admin_headers):
        """Test PUT /api/setup/users/{id}/reset-password - Reset user password"""
        response = requests.get(f"{BASE_URL}/api/setup/users/all", headers=admin_headers)
        users = response.json()
        test_user = next((u for u in users if u["name"] and "TEST_" in u["name"]), None)
        
        if test_user:
            reset_payload = {"new_password": "newpassword123"}
            response = requests.put(f"{BASE_URL}/api/setup/users/{test_user['id']}/reset-password", json=reset_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to reset password: {response.text}"
            data = response.json()
            assert "message" in data
            print(f"✓ Password reset successful")
        else:
            pytest.skip("No test user found")
    
    def test_toggle_user_active(self, admin_headers):
        """Test user activation/deactivation via PUT"""
        response = requests.get(f"{BASE_URL}/api/setup/users/all", headers=admin_headers)
        users = response.json()
        test_user = next((u for u in users if u["name"] and "TEST_" in u["name"]), None)
        
        if test_user:
            new_status = not test_user["is_active"]
            update_payload = {"is_active": new_status}
            response = requests.put(f"{BASE_URL}/api/users/{test_user['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to toggle: {response.text}"
            data = response.json()
            assert data["is_active"] == new_status
            print(f"✓ Toggled user active status to: {new_status}")
        else:
            pytest.skip("No test user found")
    
    # ============ VENDORS TESTS ============
    
    def test_list_all_vendors(self, admin_headers):
        """Test GET /api/setup/vendors/all - List all vendors including inactive"""
        response = requests.get(f"{BASE_URL}/api/setup/vendors/all", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of vendors"
        print(f"✓ Found {len(data)} vendors")
    
    def test_create_vendor(self, admin_headers):
        """Test POST /api/vendors - Create new vendor"""
        import time
        unique_id = int(time.time())
        payload = {
            "name": f"TEST_Vendor_{unique_id}",
            "code": f"TESTV{unique_id}",
            "contact_person": "Test Contact",
            "phone": "9123456789",
            "email": f"testvendor{unique_id}@example.com",
            "address": "Test Address",
            "gst_number": f"TESTGST{unique_id}"
        }
        response = requests.post(f"{BASE_URL}/api/vendors", json=payload, headers=admin_headers)
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            print(f"✓ Created vendor: {data['name']}")
        elif response.status_code == 400:
            print(f"⚠ Vendor may already exist")
        else:
            assert False, f"Unexpected error: {response.text}"
    
    def test_update_vendor(self, admin_headers):
        """Test PUT /api/setup/vendors/{id} - Update vendor"""
        response = requests.get(f"{BASE_URL}/api/setup/vendors/all", headers=admin_headers)
        vendors = response.json()
        test_vendor = next((v for v in vendors if "TEST_" in v["name"]), None)
        
        if test_vendor:
            update_payload = {
                "name": "TEST_Vendor_Updated",
                "contact_person": "Updated Contact"
            }
            response = requests.put(f"{BASE_URL}/api/setup/vendors/{test_vendor['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            print(f"✓ Updated vendor")
        else:
            pytest.skip("No test vendor found")
    
    def test_toggle_vendor_active(self, admin_headers):
        """Test PUT /api/setup/vendors/{id}/toggle-active - Toggle vendor active status"""
        response = requests.get(f"{BASE_URL}/api/setup/vendors/all", headers=admin_headers)
        vendors = response.json()
        test_vendor = next((v for v in vendors if "TEST_" in v["name"]), None)
        
        if test_vendor:
            response = requests.put(f"{BASE_URL}/api/setup/vendors/{test_vendor['id']}/toggle-active", headers=admin_headers)
            assert response.status_code == 200, f"Failed to toggle: {response.text}"
            data = response.json()
            assert "is_active" in data
            print(f"✓ Toggled vendor active status")
        else:
            pytest.skip("No test vendor found")
    
    # ============ ITEMS TESTS ============
    
    def test_list_all_items(self, admin_headers):
        """Test GET /api/setup/items/all - List all items including inactive"""
        response = requests.get(f"{BASE_URL}/api/setup/items/all", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of items"
        print(f"✓ Found {len(data)} items")
    
    def test_get_csv_template(self, admin_headers):
        """Test GET /api/setup/items/csv-template - Get CSV upload template"""
        response = requests.get(f"{BASE_URL}/api/setup/items/csv-template", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert "columns" in data
        assert "sample_rows" in data
        assert len(data["columns"]) > 0
        print(f"✓ CSV template has {len(data['columns'])} columns")
    
    def test_seed_categories(self, admin_headers):
        """Test POST /api/setup/seed-categories - Seed initial categories"""
        response = requests.post(f"{BASE_URL}/api/setup/seed-categories", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert "message" in data
        print(f"✓ Categories seeded")
    
    def test_create_item(self, admin_headers):
        """Test POST /api/items - Create new item"""
        import time
        unique_id = int(time.time())
        
        # Get departments first
        depts_resp = requests.get(f"{BASE_URL}/api/departments", headers=admin_headers)
        depts = depts_resp.json()
        dept_id = depts[0]["id"] if depts else 1
        
        payload = {
            "name": f"TEST_Item_{unique_id}",
            "code": f"TESTI{unique_id}",
            "unit": "tablet",
            "dispatching_department_id": dept_id,
            "all_departments_allowed": True,
            "priority_requirement": "NON_MANDATORY",
            "patient_ipd_requirement": "NON_MANDATORY",
            "ipd_status_allowed": "BOTH",
            "cost_per_unit": 10.50
        }
        response = requests.post(f"{BASE_URL}/api/items", json=payload, headers=admin_headers)
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            print(f"✓ Created item: {data['name']}")
        elif response.status_code == 400:
            print(f"⚠ Item may already exist")
        else:
            assert False, f"Unexpected error: {response.text}"
    
    def test_update_item(self, admin_headers):
        """Test PUT /api/items/{id} - Update item"""
        response = requests.get(f"{BASE_URL}/api/setup/items/all", headers=admin_headers)
        items = response.json()
        test_item = next((i for i in items if "TEST_" in i["name"]), None)
        
        if test_item:
            update_payload = {
                "name": "TEST_Item_Updated",
                "cost_per_unit": 15.75
            }
            response = requests.put(f"{BASE_URL}/api/items/{test_item['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            print(f"✓ Updated item")
        else:
            pytest.skip("No test item found")
    
    def test_toggle_item_active(self, admin_headers):
        """Test item activation/deactivation via PUT"""
        response = requests.get(f"{BASE_URL}/api/setup/items/all", headers=admin_headers)
        items = response.json()
        test_item = next((i for i in items if "TEST_" in i["name"]), None)
        
        if test_item:
            new_status = not test_item["is_active"]
            update_payload = {"is_active": new_status}
            response = requests.put(f"{BASE_URL}/api/items/{test_item['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to toggle: {response.text}"
            print(f"✓ Toggled item active status")
        else:
            pytest.skip("No test item found")
    
    # ============ ASSETS TESTS ============
    
    def test_list_assets(self, admin_headers):
        """Test GET /api/assets - List all assets"""
        response = requests.get(f"{BASE_URL}/api/assets", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of assets"
        print(f"✓ Found {len(data)} assets")
    
    def test_create_asset(self, admin_headers):
        """Test POST /api/assets - Create new asset"""
        import time
        unique_id = int(time.time())
        
        # Get departments and vendors first
        depts_resp = requests.get(f"{BASE_URL}/api/departments", headers=admin_headers)
        depts = depts_resp.json()
        dept_id = depts[0]["id"] if depts else None
        
        vendors_resp = requests.get(f"{BASE_URL}/api/setup/vendors/all", headers=admin_headers)
        vendors = vendors_resp.json()
        vendor_id = vendors[0]["id"] if vendors else None
        
        payload = {
            "asset_code": f"TESTA{unique_id}",
            "name": f"TEST_Asset_{unique_id}",
            "description": "Test asset for testing",
            "category": "Medical Equipment",
            "current_department_id": dept_id,
            "vendor_id": vendor_id,
            "purchase_date": "2024-01-15",
            "purchase_price": 5000.00,
            "warranty_expiry": "2026-01-15"
        }
        response = requests.post(f"{BASE_URL}/api/assets", json=payload, headers=admin_headers)
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            print(f"✓ Created asset: {data['name']}")
        elif response.status_code == 400:
            print(f"⚠ Asset may already exist")
        else:
            assert False, f"Unexpected error: {response.text}"
    
    def test_update_asset(self, admin_headers):
        """Test PUT /api/assets/{id} - Update asset"""
        response = requests.get(f"{BASE_URL}/api/assets", headers=admin_headers)
        assets = response.json()
        test_asset = next((a for a in assets if "TEST_" in a["name"]), None)
        
        if test_asset:
            update_payload = {
                "name": "TEST_Asset_Updated",
                "description": "Updated description"
            }
            response = requests.put(f"{BASE_URL}/api/assets/{test_asset['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            print(f"✓ Updated asset")
        else:
            pytest.skip("No test asset found")
    
    # ============ PATIENTS TESTS ============
    
    def test_list_all_patients(self, admin_headers):
        """Test GET /api/setup/patients - List all patients"""
        response = requests.get(f"{BASE_URL}/api/setup/patients", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of patients"
        print(f"✓ Found {len(data)} patients")
    
    def test_search_patients(self, admin_headers):
        """Test GET /api/setup/patients?search= - Search patients"""
        response = requests.get(f"{BASE_URL}/api/setup/patients", params={"search": "test"}, headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Search returned {len(data)} results")
    
    def test_create_patient(self, admin_headers):
        """Test POST /api/setup/patients - Create new patient"""
        import time
        uhid = f"TESTUHID{int(time.time())}"
        payload = {
            "uhid": uhid,
            "name": "TEST_Patient_001",
            "phone": "9234567890",
            "gender": "Male",
            "blood_group": "A+",
            "address": "Test Address"
        }
        response = requests.post(f"{BASE_URL}/api/setup/patients", json=payload, headers=admin_headers)
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            assert data["uhid"] == payload["uhid"]
            print(f"✓ Created patient: {data['name']}")
        elif response.status_code == 400:
            print(f"⚠ Patient UHID may already exist")
        else:
            assert False, f"Unexpected error: {response.text}"
    
    def test_update_patient(self, admin_headers):
        """Test PUT /api/setup/patients/{id} - Update patient"""
        response = requests.get(f"{BASE_URL}/api/setup/patients", headers=admin_headers)
        patients = response.json()
        test_patient = next((p for p in patients if "TEST_" in p["name"]), None)
        
        if test_patient:
            update_payload = {
                "name": "TEST_Patient_Updated",
                "phone": "9234567891"
            }
            response = requests.put(f"{BASE_URL}/api/setup/patients/{test_patient['id']}", json=update_payload, headers=admin_headers)
            assert response.status_code == 200, f"Failed to update: {response.text}"
            data = response.json()
            assert data["name"] == update_payload["name"]
            print(f"✓ Updated patient")
        else:
            pytest.skip("No test patient found")


class TestItemCategories:
    """Test Item Categories API"""
    
    @pytest.fixture(scope="class")
    def admin_token(self):
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "9999999999",
            "password": "admin123"
        })
        return response.json()["access_token"]
    
    @pytest.fixture(scope="class")
    def admin_headers(self, admin_token):
        return {
            "Authorization": f"Bearer {admin_token}",
            "Content-Type": "application/json"
        }
    
    def test_list_item_categories(self, admin_headers):
        """Test GET /api/item-categories - List all item categories"""
        response = requests.get(f"{BASE_URL}/api/item-categories", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Found {len(data)} item categories")
    
    def test_create_item_category(self, admin_headers):
        """Test POST /api/item-categories - Create new category"""
        import time
        payload = {
            "name": f"TEST_Category_{int(time.time())}",
            "description": "Test category"
        }
        response = requests.post(f"{BASE_URL}/api/item-categories", json=payload, headers=admin_headers)
        if response.status_code == 200:
            data = response.json()
            assert data["name"] == payload["name"]
            print(f"✓ Created category: {data['name']}")
        else:
            print(f"⚠ Category creation failed: {response.text}")


class TestNonAdminAccess:
    """Test that non-admin users cannot access admin setup endpoints"""
    
    @pytest.fixture(scope="class")
    def user_token(self):
        """Get regular user auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "9876543210",  # Ward staff
            "password": "user123"
        })
        if response.status_code == 200:
            return response.json()["access_token"]
        return None
    
    @pytest.fixture(scope="class")
    def user_headers(self, user_token):
        if user_token:
            return {
                "Authorization": f"Bearer {user_token}",
                "Content-Type": "application/json"
            }
        return None
    
    def test_non_admin_cannot_list_all_users(self, user_headers):
        """Non-admin should not access /api/setup/users/all"""
        if not user_headers:
            pytest.skip("Regular user login not available")
        
        response = requests.get(f"{BASE_URL}/api/setup/users/all", headers=user_headers)
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("✓ Non-admin correctly denied access to users list")
    
    def test_non_admin_cannot_reset_password(self, user_headers):
        """Non-admin should not access password reset"""
        if not user_headers:
            pytest.skip("Regular user login not available")
        
        response = requests.put(f"{BASE_URL}/api/setup/users/1/reset-password", 
                               json={"new_password": "test"}, 
                               headers=user_headers)
        assert response.status_code in [401, 403], f"Expected 401/403, got {response.status_code}"
        print("✓ Non-admin correctly denied access to password reset")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

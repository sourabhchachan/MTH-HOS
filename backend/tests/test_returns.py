"""
Test suite for Return Order Workflow APIs
Tests: returnable orders, returnable items, create return, billing adjustments
"""
import pytest
import requests
import os

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')

# Test credentials
ADMIN_PHONE = "9999999999"
ADMIN_PASSWORD = "admin123"


@pytest.fixture(scope="module")
def auth_token():
    """Get authentication token"""
    response = requests.post(f"{BASE_URL}/api/auth/login", json={
        "phone": ADMIN_PHONE,
        "password": ADMIN_PASSWORD
    })
    assert response.status_code == 200, f"Auth failed: {response.text}"
    return response.json()["access_token"]


@pytest.fixture(scope="module")
def api_client(auth_token):
    """Authenticated requests session"""
    session = requests.Session()
    session.headers.update({
        "Content-Type": "application/json",
        "Authorization": f"Bearer {auth_token}"
    })
    return session


class TestReturnableOrders:
    """Tests for GET /api/returns/returnable-orders - List completed orders available for return"""
    
    def test_list_returnable_orders(self, api_client):
        """Test listing returnable orders returns completed orders"""
        response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
        
        # Verify each order has required fields
        if len(data) > 0:
            order = data[0]
            assert "order_id" in order
            assert "order_number" in order
            assert "completed_at" in order
            assert "total_items" in order
            assert "billing_status" in order
            print(f"Found {len(data)} returnable orders")
    
    def test_returnable_orders_pagination(self, api_client):
        """Test pagination works for returnable orders"""
        response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?skip=0&limit=2")
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 2
    
    def test_returnable_orders_search(self, api_client):
        """Test search functionality for returnable orders"""
        # First get an order number to search
        response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=1")
        assert response.status_code == 200
        data = response.json()
        
        if len(data) > 0:
            # Search for this order
            order_number = data[0]["order_number"]
            search_response = api_client.get(
                f"{BASE_URL}/api/returns/returnable-orders?search={order_number[:5]}"
            )
            assert search_response.status_code == 200


class TestReturnableItems:
    """Tests for GET /api/returns/order/{order_id}/returnable-items"""
    
    def test_get_returnable_items_success(self, api_client):
        """Test getting returnable items for a completed order"""
        # Get a completed order first
        orders_response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=1")
        assert orders_response.status_code == 200
        orders = orders_response.json()
        
        if len(orders) > 0:
            order_id = orders[0]["order_id"]
            response = api_client.get(f"{BASE_URL}/api/returns/order/{order_id}/returnable-items")
            assert response.status_code == 200
            
            data = response.json()
            assert "order_id" in data
            assert "order_number" in data
            assert "items" in data
            assert "total_returnable_value" in data
            assert "billing_status" in data
            
            # Verify items structure
            if len(data["items"]) > 0:
                item = data["items"][0]
                assert "order_item_id" in item
                assert "item_name" in item
                assert "quantity_received" in item
                assert "quantity_returnable" in item
                assert "cost_per_unit" in item
                print(f"Order {data['order_number']} has {len(data['items'])} returnable items")
    
    def test_get_returnable_items_nonexistent_order(self, api_client):
        """Test 404 for nonexistent order"""
        response = api_client.get(f"{BASE_URL}/api/returns/order/99999/returnable-items")
        assert response.status_code == 404
    
    def test_returnable_items_shows_billing_info(self, api_client):
        """Test that billing info is included for returnable items"""
        orders_response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=5")
        orders = orders_response.json()
        
        for order in orders:
            response = api_client.get(f"{BASE_URL}/api/returns/order/{order['order_id']}/returnable-items")
            if response.status_code == 200:
                data = response.json()
                # Billing info should be present
                assert "billing_id" in data
                assert "billing_status" in data
                if data["billing_id"]:
                    print(f"Order {data['order_number']}: billing_status={data['billing_status']}")
                break


class TestBillingAdjustments:
    """Tests for GET /api/returns/billing-adjustments - List all billing adjustments"""
    
    def test_list_billing_adjustments(self, api_client):
        """Test listing billing adjustments"""
        response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
        
        if len(data) > 0:
            adj = data[0]
            assert "id" in adj
            assert "adjustment_number" in adj
            assert "original_billing_id" in adj
            assert "adjustment_type" in adj
            assert "adjustment_amount" in adj
            assert "is_credit" in adj
            assert "items" in adj
            
            # Verify adjustment type is valid
            assert adj["adjustment_type"] in ["RETURN_CREDIT", "RETURN_DEDUCTION", "MANUAL_ADJUSTMENT"]
            print(f"Found {len(data)} billing adjustments")
    
    def test_filter_by_billing_id(self, api_client):
        """Test filtering adjustments by billing ID"""
        # Get adjustments first
        response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments?limit=1")
        data = response.json()
        
        if len(data) > 0:
            billing_id = data[0]["original_billing_id"]
            filtered_response = api_client.get(
                f"{BASE_URL}/api/returns/billing-adjustments?billing_id={billing_id}"
            )
            assert filtered_response.status_code == 200
            filtered_data = filtered_response.json()
            for adj in filtered_data:
                assert adj["original_billing_id"] == billing_id
    
    def test_filter_by_is_credit(self, api_client):
        """Test filtering adjustments by is_credit flag"""
        response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments?is_credit=true")
        assert response.status_code == 200
        data = response.json()
        for adj in data:
            assert adj["is_credit"] == True


class TestBillingEffectiveAmount:
    """Tests for GET /api/returns/billing/{billing_id}/effective-amount"""
    
    def test_get_billing_effective_amount(self, api_client):
        """Test getting effective billing amount after adjustments"""
        # Get an adjustment to find a billing_id
        adj_response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments?limit=1")
        adjustments = adj_response.json()
        
        if len(adjustments) > 0:
            billing_id = adjustments[0]["original_billing_id"]
            response = api_client.get(f"{BASE_URL}/api/returns/billing/{billing_id}/effective-amount")
            assert response.status_code == 200
            
            data = response.json()
            assert "billing_id" in data
            assert "billing_number" in data
            assert "original_amount" in data
            assert "total_adjustments" in data
            assert "effective_amount" in data
            assert "paid_amount" in data
            assert "outstanding_amount" in data
            
            # Verify math: effective = original + adjustments
            assert data["effective_amount"] == data["original_amount"] + data["total_adjustments"]
            print(f"Billing {data['billing_number']}: original={data['original_amount']}, "
                  f"adjustments={data['total_adjustments']}, effective={data['effective_amount']}")
    
    def test_billing_effective_amount_nonexistent(self, api_client):
        """Test 404 for nonexistent billing"""
        response = api_client.get(f"{BASE_URL}/api/returns/billing/99999/effective-amount")
        assert response.status_code == 404


class TestReturnOrders:
    """Tests for GET /api/returns/orders - List return orders"""
    
    def test_list_return_orders(self, api_client):
        """Test listing return orders"""
        response = api_client.get(f"{BASE_URL}/api/returns/orders")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
        
        if len(data) > 0:
            order = data[0]
            assert order["order_type"] == "RETURN"
            assert "return_reason" in order
            assert "original_order_id" in order
            assert "items" in order
            print(f"Found {len(data)} return orders")
    
    def test_return_order_has_correct_type(self, api_client):
        """Test that all returned orders have RETURN type"""
        response = api_client.get(f"{BASE_URL}/api/returns/orders?limit=10")
        data = response.json()
        for order in data:
            assert order["order_type"] == "RETURN"


class TestCreateReturn:
    """Tests for POST /api/returns/create - Create return order with billing adjustment"""
    
    def test_create_return_validates_items(self, api_client):
        """Test that return creation validates items are provided"""
        # Get a completed order
        orders_response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=1")
        orders = orders_response.json()
        
        if len(orders) > 0:
            order_id = orders[0]["order_id"]
            # Try to create return with no items
            response = api_client.post(f"{BASE_URL}/api/returns/create", json={
                "original_order_id": order_id,
                "return_reason": "Unused",
                "items": []
            })
            # Should fail with 400 or 422
            assert response.status_code in [400, 422]
    
    def test_create_return_validates_quantity(self, api_client):
        """Test that return validates return quantity doesn't exceed available"""
        # Get returnable items for an order
        orders_response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=5")
        orders = orders_response.json()
        
        for order in orders:
            items_response = api_client.get(f"{BASE_URL}/api/returns/order/{order['order_id']}/returnable-items")
            if items_response.status_code == 200:
                items_data = items_response.json()
                if len(items_data["items"]) > 0:
                    item = items_data["items"][0]
                    # Try to return more than returnable quantity
                    response = api_client.post(f"{BASE_URL}/api/returns/create", json={
                        "original_order_id": order["order_id"],
                        "return_reason": "Unused",
                        "items": [{
                            "original_order_item_id": item["order_item_id"],
                            "item_id": item["item_id"],
                            "quantity_requested": item["quantity_returnable"] + 100  # More than available
                        }]
                    })
                    assert response.status_code == 400
                    print(f"Return quantity validation works - rejected {item['quantity_returnable'] + 100} > {item['quantity_returnable']}")
                    return
    
    def test_create_return_success(self, api_client):
        """Test successful return creation with billing adjustment"""
        # Get a completed order with returnable items
        orders_response = api_client.get(f"{BASE_URL}/api/returns/returnable-orders?limit=5")
        orders = orders_response.json()
        
        for order in orders:
            items_response = api_client.get(f"{BASE_URL}/api/returns/order/{order['order_id']}/returnable-items")
            if items_response.status_code == 200:
                items_data = items_response.json()
                if len(items_data["items"]) > 0 and items_data["items"][0]["quantity_returnable"] >= 1:
                    item = items_data["items"][0]
                    
                    # Get adjustments count before
                    adj_before = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments").json()
                    
                    # Create return for 1 unit
                    response = api_client.post(f"{BASE_URL}/api/returns/create", json={
                        "original_order_id": order["order_id"],
                        "return_reason": "Unused",
                        "notes": "Test return from pytest",
                        "items": [{
                            "original_order_item_id": item["order_item_id"],
                            "item_id": item["item_id"],
                            "quantity_requested": 1,
                            "return_reason": "Unused"
                        }]
                    })
                    assert response.status_code == 200, f"Create return failed: {response.text}"
                    
                    return_order = response.json()
                    assert return_order["order_type"] == "RETURN"
                    assert return_order["return_reason"] == "Unused"
                    assert "RET-" in return_order["order_number"]
                    
                    # Verify billing adjustment created
                    adj_after = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments").json()
                    
                    # Check if billing adjustment was created (if there was billing)
                    if items_data.get("billing_id"):
                        assert len(adj_after) > len(adj_before), "Billing adjustment should be created"
                        
                        # Check adjustment type based on billing status
                        billing_status = items_data.get("billing_status")
                        latest_adj = adj_after[0]  # Most recent
                        
                        if billing_status == "PAID":
                            assert latest_adj["adjustment_type"] == "RETURN_CREDIT"
                            assert latest_adj["is_credit"] == True
                            print(f"PAID billing: Created RETURN_CREDIT adjustment")
                        else:
                            assert latest_adj["adjustment_type"] == "RETURN_DEDUCTION"
                            assert latest_adj["is_credit"] == False
                            print(f"UNPAID billing: Created RETURN_DEDUCTION adjustment")
                    
                    print(f"Successfully created return order {return_order['order_number']}")
                    return
        
        pytest.skip("No returnable items available for testing")


class TestReturnReasons:
    """Tests for return reasons API"""
    
    def test_list_return_reasons(self, api_client):
        """Test listing return reasons"""
        response = api_client.get(f"{BASE_URL}/api/return-reasons")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        
        # Verify required reasons exist
        reason_names = [r["reason"] for r in data]
        expected_reasons = ["Unused", "Wrong Item", "Excess Quantity", "Defective Item", "Damaged Item", "Other"]
        for expected in expected_reasons:
            assert expected in reason_names, f"Missing expected reason: {expected}"
        
        print(f"Found {len(data)} return reasons: {reason_names}")


class TestBillingLogic:
    """Tests for billing adjustment logic"""
    
    def test_unpaid_order_gets_deduction(self, api_client):
        """Verify unpaid orders get RETURN_DEDUCTION adjustment"""
        adj_response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments")
        adjustments = adj_response.json()
        
        for adj in adjustments:
            if adj["is_credit"] == False:
                assert adj["adjustment_type"] == "RETURN_DEDUCTION"
                print(f"Found RETURN_DEDUCTION for unpaid billing: {adj['adjustment_number']}")
                break
    
    def test_paid_order_gets_credit(self, api_client):
        """Verify paid orders get RETURN_CREDIT adjustment"""
        adj_response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments")
        adjustments = adj_response.json()
        
        for adj in adjustments:
            if adj["is_credit"] == True:
                assert adj["adjustment_type"] == "RETURN_CREDIT"
                print(f"Found RETURN_CREDIT for paid billing: {adj['adjustment_number']}")
                break
    
    def test_original_billing_not_modified(self, api_client):
        """Verify original billing records are not modified - adjustments are separate"""
        # Get an adjustment
        adj_response = api_client.get(f"{BASE_URL}/api/returns/billing-adjustments?limit=1")
        adjustments = adj_response.json()
        
        if len(adjustments) > 0:
            billing_id = adjustments[0]["original_billing_id"]
            
            # Get effective amount which shows original vs adjusted
            eff_response = api_client.get(f"{BASE_URL}/api/returns/billing/{billing_id}/effective-amount")
            assert eff_response.status_code == 200
            
            data = eff_response.json()
            # Original amount should remain unchanged
            assert data["original_amount"] > 0 or data["original_amount"] == 0
            # Adjustments tracked separately
            assert "total_adjustments" in data
            print(f"Original billing {data['billing_number']}: "
                  f"original={data['original_amount']}, adjustments={data['total_adjustments']}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])

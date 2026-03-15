"""
Test Quick Actions - Quick Dispatch and Quick Receive functionality
Tests dispatch-queue API and dispatch/receive endpoints
"""
import pytest
import requests
import os

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')


class TestQuickDispatch:
    """Quick Dispatch Button - Dispatch Queue and Dispatch API tests"""
    
    @pytest.fixture(scope="class")
    def admin_token(self):
        """Get admin auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "8888888888",
            "password": "password"
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
    
    # ============ DISPATCH QUEUE TESTS ============
    
    def test_dispatch_queue_accessible_to_admin(self, admin_headers):
        """Test GET /api/dispatch-queue - Admin can see all dispatch items"""
        response = requests.get(f"{BASE_URL}/api/dispatch-queue", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        data = response.json()
        assert isinstance(data, list), "Expected list of dispatch items"
        print(f"✓ Dispatch queue accessible, found {len(data)} items")
        
        # Verify response structure if items exist
        if len(data) > 0:
            item = data[0]
            assert "order_item_id" in item
            assert "order_number" in item
            assert "item_name" in item
            assert "quantity_pending" in item
            assert "quantity_dispatched" in item
            print(f"✓ Dispatch item structure valid")
    
    def test_create_order_for_dispatch_queue(self, admin_headers):
        """Create a test order that will appear in dispatch queue"""
        # First get an orderable item
        items_resp = requests.get(f"{BASE_URL}/api/items/orderable", headers=admin_headers)
        items = items_resp.json()
        if not items:
            pytest.skip("No orderable items available")
        
        item_id = items[0]["id"]
        
        # Create order
        order_payload = {
            "order_type": "REGULAR",
            "priority": "NORMAL",
            "notes": "TEST_Quick_Dispatch_Order",
            "items": [
                {"item_id": item_id, "quantity_requested": 2}
            ]
        }
        
        response = requests.post(f"{BASE_URL}/api/orders", json=order_payload, headers=admin_headers)
        assert response.status_code == 200, f"Failed to create order: {response.text}"
        
        order = response.json()
        assert order["status"] == "CREATED"
        print(f"✓ Created test order: {order['order_number']}")
        
        return order
    
    def test_dispatch_item_from_queue(self, admin_headers):
        """Test POST /api/dispatch - Dispatch an item from queue"""
        # Get dispatch queue
        queue_resp = requests.get(f"{BASE_URL}/api/dispatch-queue", headers=admin_headers)
        queue = queue_resp.json()
        
        if not queue:
            pytest.skip("No items in dispatch queue")
        
        # Get first item with pending quantity
        item = next((i for i in queue if i["quantity_pending"] > 0), None)
        if not item:
            pytest.skip("No items with pending quantity")
        
        # Dispatch 1 unit
        dispatch_payload = {
            "order_item_id": item["order_item_id"],
            "quantity_dispatched": 1,
            "dispatch_notes": "Test dispatch via Quick Dispatch"
        }
        
        response = requests.post(f"{BASE_URL}/api/dispatch", json=dispatch_payload, headers=admin_headers)
        assert response.status_code == 200, f"Failed to dispatch: {response.text}"
        
        result = response.json()
        assert result["quantity_dispatched"] == 1
        assert "dispatcher" in result
        print(f"✓ Dispatched 1 unit successfully")
    
    def test_dispatch_removes_from_queue(self, admin_headers):
        """Test that fully dispatched items are removed from queue"""
        # First create a new order for this specific test
        items_resp = requests.get(f"{BASE_URL}/api/items/orderable", headers=admin_headers)
        items = items_resp.json()
        if not items:
            pytest.skip("No orderable items available")
        
        # Create order with quantity 1
        order_payload = {
            "order_type": "REGULAR",
            "priority": "NORMAL",
            "notes": "TEST_Full_Dispatch_Check",
            "items": [
                {"item_id": items[0]["id"], "quantity_requested": 1}
            ]
        }
        
        resp = requests.post(f"{BASE_URL}/api/orders", json=order_payload, headers=admin_headers)
        if resp.status_code != 200:
            pytest.skip("Could not create test order")
        
        order = resp.json()
        order_item_id = order["items"][0]["id"]
        
        # Verify it appears in queue
        queue_before = requests.get(f"{BASE_URL}/api/dispatch-queue", headers=admin_headers).json()
        in_queue_before = any(i["order_item_id"] == order_item_id for i in queue_before)
        print(f"✓ Order item in queue before dispatch: {in_queue_before}")
        
        # Dispatch full quantity
        dispatch_resp = requests.post(f"{BASE_URL}/api/dispatch", json={
            "order_item_id": order_item_id,
            "quantity_dispatched": 1
        }, headers=admin_headers)
        assert dispatch_resp.status_code == 200
        
        # Verify it's removed from queue (FULLY_DISPATCHED items shouldn't be in queue)
        queue_after = requests.get(f"{BASE_URL}/api/dispatch-queue", headers=admin_headers).json()
        in_queue_after = any(i["order_item_id"] == order_item_id for i in queue_after)
        print(f"✓ Order item in queue after full dispatch: {in_queue_after}")
        
        assert not in_queue_after, "Fully dispatched item should be removed from queue"


class TestQuickReceive:
    """Quick Receive Button - Receive functionality tests"""
    
    @pytest.fixture(scope="class")
    def admin_token(self):
        """Get admin auth token"""
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "8888888888",
            "password": "password"
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
    
    def test_get_fully_dispatched_orders(self, admin_headers):
        """Test getting orders with FULLY_DISPATCHED status"""
        response = requests.get(
            f"{BASE_URL}/api/orders",
            params={"status": "FULLY_DISPATCHED"},
            headers=admin_headers
        )
        assert response.status_code == 200, f"Failed: {response.text}"
        
        orders = response.json()
        print(f"✓ Found {len(orders)} FULLY_DISPATCHED orders")
        
        # Verify all orders have correct status
        for order in orders:
            assert order["status"] == "FULLY_DISPATCHED"
        
        return orders
    
    def test_get_pending_receive(self, admin_headers):
        """Test GET /api/pending-receive - Get dispatch events pending receipt"""
        response = requests.get(f"{BASE_URL}/api/pending-receive", headers=admin_headers)
        assert response.status_code == 200, f"Failed: {response.text}"
        
        events = response.json()
        print(f"✓ Found {len(events)} pending receive events")
        
        # Verify structure
        if len(events) > 0:
            event = events[0]
            assert "id" in event, "Missing dispatch event id"
            assert "order_item_id" in event
            assert "quantity_dispatched" in event
            print(f"✓ Pending receive event structure valid")
        
        return events
    
    def test_receive_item_with_dispatch_event_id(self, admin_headers):
        """Test POST /api/receive - Receive item using dispatch_event_id"""
        # Get pending receive events
        events = requests.get(f"{BASE_URL}/api/pending-receive", headers=admin_headers).json()
        
        if not events:
            pytest.skip("No pending receive events")
        
        # Get first unreceived event
        event = next((e for e in events if e.get("received_at") is None), None)
        if not event:
            pytest.skip("No unreceived events found")
        
        # Receive using dispatch_event_id (correct API)
        receive_payload = {
            "dispatch_event_id": event["id"],
            "quantity_received": event["quantity_dispatched"],
            "receipt_notes": "Test receive via Quick Receive"
        }
        
        response = requests.post(f"{BASE_URL}/api/receive", json=receive_payload, headers=admin_headers)
        assert response.status_code == 200, f"Failed to receive: {response.text}"
        
        result = response.json()
        assert result["received_at"] is not None
        print(f"✓ Received item successfully using dispatch_event_id")
    
    def test_receive_item_validates_dispatch_event(self, admin_headers):
        """Test that receive API validates dispatch_event_id exists"""
        receive_payload = {
            "dispatch_event_id": 999999,  # Non-existent
            "quantity_received": 1
        }
        
        response = requests.post(f"{BASE_URL}/api/receive", json=receive_payload, headers=admin_headers)
        assert response.status_code == 404, f"Expected 404, got {response.status_code}"
        print("✓ API correctly validates dispatch_event_id")


class TestQuickActionsIntegration:
    """Integration tests for Quick Dispatch → Quick Receive flow"""
    
    @pytest.fixture(scope="class")
    def admin_token(self):
        response = requests.post(f"{BASE_URL}/api/auth/login", json={
            "phone": "8888888888",
            "password": "password"
        })
        return response.json()["access_token"]
    
    @pytest.fixture(scope="class")
    def admin_headers(self, admin_token):
        return {
            "Authorization": f"Bearer {admin_token}",
            "Content-Type": "application/json"
        }
    
    def test_full_dispatch_to_receive_flow(self, admin_headers):
        """Test complete flow: Create Order → Dispatch → Receive → Complete"""
        # 1. Create order
        items_resp = requests.get(f"{BASE_URL}/api/items/orderable", headers=admin_headers)
        items = items_resp.json()
        if not items:
            pytest.skip("No orderable items available")
        
        order_payload = {
            "order_type": "REGULAR",
            "priority": "NORMAL",
            "notes": "TEST_Integration_Flow",
            "items": [{"item_id": items[0]["id"], "quantity_requested": 1}]
        }
        
        order_resp = requests.post(f"{BASE_URL}/api/orders", json=order_payload, headers=admin_headers)
        assert order_resp.status_code == 200
        order = order_resp.json()
        order_item_id = order["items"][0]["id"]
        print(f"✓ Step 1: Created order {order['order_number']}")
        
        # 2. Dispatch item
        dispatch_resp = requests.post(f"{BASE_URL}/api/dispatch", json={
            "order_item_id": order_item_id,
            "quantity_dispatched": 1
        }, headers=admin_headers)
        assert dispatch_resp.status_code == 200
        dispatch_event = dispatch_resp.json()
        dispatch_event_id = dispatch_event["id"]
        print(f"✓ Step 2: Dispatched item (event id: {dispatch_event_id})")
        
        # 3. Verify order is FULLY_DISPATCHED
        order_check = requests.get(f"{BASE_URL}/api/orders/{order['id']}", headers=admin_headers).json()
        assert order_check["status"] == "FULLY_DISPATCHED"
        print(f"✓ Step 3: Order status = FULLY_DISPATCHED")
        
        # 4. Receive item using dispatch_event_id
        receive_resp = requests.post(f"{BASE_URL}/api/receive", json={
            "dispatch_event_id": dispatch_event_id,
            "quantity_received": 1
        }, headers=admin_headers)
        assert receive_resp.status_code == 200
        print(f"✓ Step 4: Received item")
        
        # 5. Verify order is COMPLETED
        final_order = requests.get(f"{BASE_URL}/api/orders/{order['id']}", headers=admin_headers).json()
        assert final_order["status"] == "COMPLETED"
        print(f"✓ Step 5: Order status = COMPLETED")
        
        print("✓ Full integration flow passed!")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

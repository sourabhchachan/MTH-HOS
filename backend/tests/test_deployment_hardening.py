"""
Deployment Hardening - Backend API Tests

Tests for:
1. Error Logging System (system_logs)
2. Activity Logging System (activity_logs)
3. System Health Dashboard
4. Database Backup System
5. Stress Test Mode
"""
import pytest
import requests
import os
from datetime import datetime

BASE_URL = os.environ.get('REACT_APP_BACKEND_URL', '').rstrip('/')
AUTH_PHONE = "9999999999"
AUTH_PASSWORD = "admin123"


@pytest.fixture(scope="module")
def auth_token():
    """Get authentication token for admin user"""
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json={"phone": AUTH_PHONE, "password": AUTH_PASSWORD}
    )
    if response.status_code != 200:
        pytest.skip(f"Authentication failed: {response.text}")
    return response.json()["access_token"]


@pytest.fixture(scope="module")
def auth_headers(auth_token):
    """Get headers with auth token"""
    return {"Authorization": f"Bearer {auth_token}"}


# ============ SYSTEM LOGS API TESTS ============

class TestSystemLogs:
    """System Error Logs API Tests"""
    
    def test_list_system_logs(self, auth_headers):
        """GET /api/system-logs - List system error logs"""
        response = requests.get(
            f"{BASE_URL}/api/system-logs",
            headers=auth_headers,
            params={"limit": 10}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ System logs count: {len(data)}")
    
    def test_list_system_logs_with_level_filter(self, auth_headers):
        """GET /api/system-logs - Filter by level"""
        response = requests.get(
            f"{BASE_URL}/api/system-logs",
            headers=auth_headers,
            params={"limit": 10, "level": "ERROR"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # If there are results, verify level filter
        for log in data:
            assert log.get("level") == "ERROR"
        print(f"✓ ERROR level logs: {len(data)}")
    
    def test_list_system_logs_with_type_filter(self, auth_headers):
        """GET /api/system-logs - Filter by error type"""
        response = requests.get(
            f"{BASE_URL}/api/system-logs",
            headers=auth_headers,
            params={"limit": 10, "error_type": "API"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for log in data:
            assert log.get("error_type") == "API"
        print(f"✓ API type logs: {len(data)}")
    
    def test_get_system_log_stats(self, auth_headers):
        """GET /api/system-logs/stats - Get error statistics"""
        response = requests.get(
            f"{BASE_URL}/api/system-logs/stats",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert "total_errors_today" in data
        assert "errors_by_type" in data
        assert "errors_by_level" in data
        assert "top_error_endpoints" in data
        assert isinstance(data["total_errors_today"], int)
        assert isinstance(data["errors_by_type"], dict)
        assert isinstance(data["errors_by_level"], dict)
        assert isinstance(data["top_error_endpoints"], list)
        print(f"✓ Total errors today: {data['total_errors_today']}")
    
    def test_system_logs_require_auth(self):
        """GET /api/system-logs - Requires authentication"""
        response = requests.get(f"{BASE_URL}/api/system-logs")
        assert response.status_code in [401, 403]
        print("✓ System logs require authentication")


# ============ ACTIVITY LOGS API TESTS ============

class TestActivityLogs:
    """Activity Logging API Tests"""
    
    def test_list_activity_logs(self, auth_headers):
        """GET /api/activity-logs - List activity logs"""
        response = requests.get(
            f"{BASE_URL}/api/activity-logs",
            headers=auth_headers,
            params={"limit": 10}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        print(f"✓ Activity logs count: {len(data)}")
        
        # Verify structure of activity logs
        if data:
            log = data[0]
            assert "id" in log
            assert "timestamp" in log
            assert "action_type" in log
            assert "entity_type" in log
    
    def test_list_activity_logs_with_action_filter(self, auth_headers):
        """GET /api/activity-logs - Filter by action type"""
        response = requests.get(
            f"{BASE_URL}/api/activity-logs",
            headers=auth_headers,
            params={"limit": 10, "action_type": "BACKUP_CREATED"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for log in data:
            assert log.get("action_type") == "BACKUP_CREATED"
        print(f"✓ BACKUP_CREATED activities: {len(data)}")
    
    def test_list_activity_logs_with_entity_filter(self, auth_headers):
        """GET /api/activity-logs - Filter by entity type"""
        response = requests.get(
            f"{BASE_URL}/api/activity-logs",
            headers=auth_headers,
            params={"limit": 10, "entity_type": "SYSTEM"}
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for log in data:
            assert log.get("entity_type") == "SYSTEM"
        print(f"✓ SYSTEM entity activities: {len(data)}")
    
    def test_get_activity_log_stats(self, auth_headers):
        """GET /api/activity-logs/stats - Get activity statistics"""
        response = requests.get(
            f"{BASE_URL}/api/activity-logs/stats",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert "total_activities_today" in data
        assert "activities_by_action" in data
        assert "activities_by_entity" in data
        assert "most_active_users" in data
        assert isinstance(data["total_activities_today"], int)
        assert isinstance(data["activities_by_action"], dict)
        assert isinstance(data["activities_by_entity"], dict)
        assert isinstance(data["most_active_users"], list)
        print(f"✓ Total activities today: {data['total_activities_today']}")
    
    def test_activity_logs_require_auth(self):
        """GET /api/activity-logs - Requires authentication"""
        response = requests.get(f"{BASE_URL}/api/activity-logs")
        assert response.status_code in [401, 403]
        print("✓ Activity logs require authentication")


# ============ SYSTEM HEALTH API TESTS ============

class TestSystemHealth:
    """System Health Dashboard API Tests"""
    
    def test_get_health_summary(self, auth_headers):
        """GET /api/system-health/summary - Get health summary"""
        response = requests.get(
            f"{BASE_URL}/api/system-health/summary",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify all expected fields
        expected_fields = [
            "timestamp", "active_users_today", "orders_created_today",
            "orders_completed_today", "orders_pending_dispatch",
            "orders_pending_dispatch_critical", "api_errors_today",
            "api_warnings_today", "avg_api_response_ms",
            "slow_requests_today", "activities_today"
        ]
        for field in expected_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify data types
        assert isinstance(data["active_users_today"], int)
        assert isinstance(data["orders_created_today"], int)
        assert isinstance(data["api_errors_today"], int)
        assert isinstance(data["orders_pending_dispatch_critical"], int)
        
        print(f"✓ Health summary: {data['active_users_today']} active users, {data['orders_created_today']} orders today")
    
    def test_get_detailed_health(self, auth_headers):
        """GET /api/system-health/detailed - Get detailed health with delays"""
        response = requests.get(
            f"{BASE_URL}/api/system-health/detailed",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        assert "summary" in data
        assert "active_users" in data
        assert "critical_delays" in data
        assert "department_delays" in data
        assert "recent_errors" in data
        
        assert isinstance(data["active_users"], list)
        assert isinstance(data["critical_delays"], list)
        assert isinstance(data["department_delays"], list)
        assert isinstance(data["recent_errors"], list)
        
        # Verify nested summary matches summary endpoint
        assert "timestamp" in data["summary"]
        assert "orders_created_today" in data["summary"]
        
        print(f"✓ Detailed health: {len(data['active_users'])} active users, {len(data['department_delays'])} depts with delays")
    
    def test_health_summary_require_auth(self):
        """GET /api/system-health/summary - Requires authentication"""
        response = requests.get(f"{BASE_URL}/api/system-health/summary")
        assert response.status_code in [401, 403]
        print("✓ Health summary requires authentication")


# ============ BACKUP SYSTEM API TESTS ============

class TestBackupSystem:
    """Database Backup System API Tests"""
    
    def test_get_backup_status(self, auth_headers):
        """GET /api/backups/status - Get backup system status"""
        response = requests.get(
            f"{BASE_URL}/api/backups/status",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        assert "backup_dir" in data
        assert "retention_days" in data
        assert "total_backups" in data
        assert "has_recent_backup" in data
        assert "last_backup_age_hours" in data
        assert "status" in data
        
        # Verify data types
        assert isinstance(data["retention_days"], int)
        assert data["retention_days"] == 30  # Configured value
        assert isinstance(data["total_backups"], int)
        assert isinstance(data["has_recent_backup"], bool)
        assert data["status"] in ["HEALTHY", "NEEDS_BACKUP"]
        
        print(f"✓ Backup status: {data['status']}, {data['total_backups']} backups")
    
    def test_list_backups(self, auth_headers):
        """GET /api/backups/list - List available backups"""
        response = requests.get(
            f"{BASE_URL}/api/backups/list",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        assert "total_backups" in data
        assert "total_size_mb" in data
        assert "backups" in data
        assert isinstance(data["backups"], list)
        
        # Verify backup item structure if backups exist
        if data["backups"]:
            backup = data["backups"][0]
            assert "filename" in backup
            assert "size_bytes" in backup
            assert "size_mb" in backup
            assert "created_at" in backup
            assert "age_days" in backup
            assert backup["filename"].startswith("mth_hospital_backup_")
            assert backup["filename"].endswith(".sql")
        
        print(f"✓ Backup list: {data['total_backups']} backups, {data['total_size_mb']}MB total")
    
    def test_create_backup(self, auth_headers):
        """POST /api/backups/create - Create database backup"""
        response = requests.post(
            f"{BASE_URL}/api/backups/create",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        assert "success" in data
        assert "message" in data
        
        if data["success"]:
            assert "filename" in data
            assert "size_mb" in data
            assert "duration_seconds" in data
            assert data["filename"].startswith("mth_hospital_backup_")
            print(f"✓ Backup created: {data['filename']} ({data['size_mb']}MB in {data['duration_seconds']}s)")
        else:
            print(f"✗ Backup failed: {data['message']}")
            pytest.fail(f"Backup creation failed: {data['message']}")
    
    def test_backup_endpoints_require_auth(self):
        """Backup endpoints require authentication"""
        # Status
        response = requests.get(f"{BASE_URL}/api/backups/status")
        assert response.status_code in [401, 403]
        
        # List
        response = requests.get(f"{BASE_URL}/api/backups/list")
        assert response.status_code in [401, 403]
        
        # Create
        response = requests.post(f"{BASE_URL}/api/backups/create")
        assert response.status_code in [401, 403]
        
        print("✓ All backup endpoints require authentication")


# ============ STRESS TEST API TESTS ============

class TestStressTest:
    """Stress Test Mode API Tests"""
    
    def test_get_stress_test_history(self, auth_headers):
        """GET /api/stress-test/history - Get stress test history"""
        response = requests.get(
            f"{BASE_URL}/api/stress-test/history",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        assert "tests" in data
        assert isinstance(data["tests"], list)
        
        # Verify test structure if tests exist
        if data["tests"]:
            test = data["tests"][0]
            assert "test_id" in test
            assert "level" in test
            assert "status" in test
            assert "target_orders" in test
            assert "actual_orders" in test
            assert "started_at" in test
        
        print(f"✓ Stress test history: {len(data['tests'])} tests")
    
    def test_get_stress_test_status_existing(self, auth_headers):
        """GET /api/stress-test/status/{test_id} - Get existing test status"""
        # First get history to find an existing test
        history_response = requests.get(
            f"{BASE_URL}/api/stress-test/history",
            headers=auth_headers
        )
        history = history_response.json()
        
        if not history.get("tests"):
            pytest.skip("No stress tests available")
        
        test_id = history["tests"][0]["test_id"]
        
        response = requests.get(
            f"{BASE_URL}/api/stress-test/status/{test_id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        expected_fields = [
            "test_id", "level", "status", "target_orders", "orders_created",
            "orders_dispatched", "orders_received", "orders_completed",
            "returns_created", "payments_recorded", "errors", "started_at",
            "elapsed_seconds", "orders_per_second"
        ]
        for field in expected_fields:
            assert field in data, f"Missing field: {field}"
        
        assert data["status"] in ["RUNNING", "COMPLETED", "FAILED"]
        print(f"✓ Test {test_id} status: {data['status']}, {data['orders_created']}/{data['target_orders']} orders")
    
    def test_get_stress_test_status_not_found(self, auth_headers):
        """GET /api/stress-test/status/{test_id} - 404 for nonexistent"""
        response = requests.get(
            f"{BASE_URL}/api/stress-test/status/nonexistent_test_id",
            headers=auth_headers
        )
        assert response.status_code == 404
        print("✓ Nonexistent test returns 404")
    
    def test_get_stress_test_results_existing(self, auth_headers):
        """GET /api/stress-test/results/{test_id} - Get completed test results"""
        # Find a completed test
        history_response = requests.get(
            f"{BASE_URL}/api/stress-test/history",
            headers=auth_headers
        )
        history = history_response.json()
        
        completed_tests = [t for t in history.get("tests", []) if t.get("status") == "COMPLETED"]
        if not completed_tests:
            pytest.skip("No completed stress tests available")
        
        test_id = completed_tests[0]["test_id"]
        
        response = requests.get(
            f"{BASE_URL}/api/stress-test/results/{test_id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify structure
        expected_fields = [
            "test_id", "level", "success", "target_orders", "actual_orders",
            "orders_dispatched", "orders_received", "orders_completed",
            "returns_created", "payments_recorded", "billing_generated",
            "total_billing_amount", "total_payments", "errors",
            "duration_seconds", "orders_per_second", "avg_order_latency_ms"
        ]
        for field in expected_fields:
            assert field in data, f"Missing field: {field}"
        
        print(f"✓ Test {test_id} results: {data['actual_orders']} orders in {data['duration_seconds']:.1f}s ({data['orders_per_second']:.1f}/s)")
    
    def test_stress_test_levels_validation(self, auth_headers):
        """POST /api/stress-test/start - Validates level values"""
        # Test with invalid level
        response = requests.post(
            f"{BASE_URL}/api/stress-test/start",
            headers=auth_headers,
            json={"level": "INVALID_LEVEL"}
        )
        assert response.status_code == 422  # Validation error
        print("✓ Invalid stress test level rejected")
    
    def test_stress_test_endpoints_require_auth(self):
        """Stress test endpoints require authentication"""
        response = requests.get(f"{BASE_URL}/api/stress-test/history")
        assert response.status_code in [401, 403]
        
        response = requests.post(
            f"{BASE_URL}/api/stress-test/start",
            json={"level": "LIGHT"}
        )
        assert response.status_code in [401, 403]
        
        print("✓ Stress test endpoints require authentication")


# ============ MIDDLEWARE/ERROR LOGGING TESTS ============

class TestErrorLogging:
    """Error Logging Middleware Tests"""
    
    def test_404_errors_handled(self, auth_headers):
        """Accessing non-existent endpoint returns proper error"""
        response = requests.get(
            f"{BASE_URL}/api/nonexistent-endpoint-xyz",
            headers=auth_headers
        )
        assert response.status_code == 404
        print("✓ 404 errors handled properly")
    
    def test_auth_errors_logged(self):
        """Auth failures return proper error codes"""
        # Invalid token
        response = requests.get(
            f"{BASE_URL}/api/system-logs",
            headers={"Authorization": "Bearer invalid_token"}
        )
        assert response.status_code in [401, 403]
        print("✓ Auth errors handled properly")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])

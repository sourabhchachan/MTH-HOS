"""
Error Handling Middleware for Deployment Hardening

Captures all API errors and logs them to system_logs table.
Also tracks request duration for performance monitoring.
"""
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import traceback
import time
import json

from database import async_session_maker
from models import SystemLog, SystemLogLevel


class ErrorLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware to capture and log all API errors.
    Also tracks request duration for performance monitoring.
    """
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Get client IP
        forwarded = request.headers.get("X-Forwarded-For")
        ip_address = forwarded.split(",")[0].strip() if forwarded else (
            request.client.host if request.client else "unknown"
        )
        
        # Get user agent
        user_agent = request.headers.get("User-Agent", "")
        
        # Try to get request body for logging (only for errors)
        request_body = None
        if request.method in ["POST", "PUT", "PATCH"]:
            try:
                body = await request.body()
                if body:
                    request_body = body.decode("utf-8")[:2000]
                # Reset body for actual processing
                request._body = body
            except Exception:
                pass
        
        # Extract user_id from JWT token if present
        user_id = None
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            try:
                import jwt
                from os import environ
                token = auth_header.split(" ")[1]
                payload = jwt.decode(
                    token, 
                    environ.get("JWT_SECRET", "your-secret-key"), 
                    algorithms=["HS256"]
                )
                user_id = payload.get("user_id")
            except Exception:
                pass
        
        try:
            response = await call_next(request)
            duration_ms = int((time.time() - start_time) * 1000)
            
            # Log slow requests (> 1000ms) as warnings
            if duration_ms > 1000 and not request.url.path.startswith("/static"):
                await self._log_slow_request(
                    endpoint=request.url.path,
                    method=request.method,
                    user_id=user_id,
                    duration_ms=duration_ms,
                    ip_address=ip_address,
                    user_agent=user_agent
                )
            
            # Log 5xx errors
            if response.status_code >= 500:
                await self._log_error(
                    error_type="API",
                    error_message=f"Server error: {response.status_code}",
                    endpoint=request.url.path,
                    method=request.method,
                    user_id=user_id,
                    response_status=response.status_code,
                    ip_address=ip_address,
                    user_agent=user_agent,
                    duration_ms=duration_ms,
                    request_body=request_body
                )
            
            # Log 4xx auth errors
            elif response.status_code in [401, 403]:
                await self._log_error(
                    error_type="AUTH",
                    error_message=f"Authentication/Authorization error: {response.status_code}",
                    endpoint=request.url.path,
                    method=request.method,
                    user_id=user_id,
                    response_status=response.status_code,
                    ip_address=ip_address,
                    user_agent=user_agent,
                    duration_ms=duration_ms,
                    level=SystemLogLevel.WARNING
                )
            
            return response
            
        except Exception as exc:
            duration_ms = int((time.time() - start_time) * 1000)
            
            # Determine error type
            error_type = "SYSTEM"
            if "database" in str(exc).lower() or "sqlalchemy" in str(exc).lower():
                error_type = "DATABASE"
            elif "jwt" in str(exc).lower() or "token" in str(exc).lower():
                error_type = "AUTH"
            elif "validation" in str(exc).lower() or "pydantic" in str(exc).lower():
                error_type = "VALIDATION"
            
            # Log the exception
            await self._log_error(
                error_type=error_type,
                error_message=str(exc),
                stack_trace=traceback.format_exc(),
                endpoint=request.url.path,
                method=request.method,
                user_id=user_id,
                response_status=500,
                ip_address=ip_address,
                user_agent=user_agent,
                duration_ms=duration_ms,
                request_body=request_body,
                level=SystemLogLevel.CRITICAL
            )
            
            # Return error response
            return JSONResponse(
                status_code=500,
                content={"detail": "Internal server error"}
            )
    
    async def _log_error(
        self,
        error_type: str,
        error_message: str,
        endpoint: str = None,
        method: str = None,
        user_id: int = None,
        stack_trace: str = None,
        request_body: str = None,
        response_status: int = None,
        ip_address: str = None,
        user_agent: str = None,
        duration_ms: int = None,
        level: SystemLogLevel = SystemLogLevel.ERROR
    ):
        """Log error to database"""
        try:
            async with async_session_maker() as db:
                log_entry = SystemLog(
                    level=level,
                    user_id=user_id,
                    endpoint=endpoint,
                    method=method,
                    error_type=error_type,
                    error_message=error_message[:2000] if error_message else None,
                    stack_trace=stack_trace[:5000] if stack_trace else None,
                    request_body=request_body[:2000] if request_body else None,
                    response_status=response_status,
                    ip_address=ip_address,
                    user_agent=user_agent[:500] if user_agent else None,
                    duration_ms=duration_ms
                )
                db.add(log_entry)
                await db.commit()
        except Exception as e:
            # Don't fail the request if logging fails
            print(f"Failed to log error: {e}")
    
    async def _log_slow_request(
        self,
        endpoint: str,
        method: str,
        user_id: int,
        duration_ms: int,
        ip_address: str,
        user_agent: str
    ):
        """Log slow requests for performance monitoring"""
        try:
            async with async_session_maker() as db:
                log_entry = SystemLog(
                    level=SystemLogLevel.WARNING,
                    user_id=user_id,
                    endpoint=endpoint,
                    method=method,
                    error_type="PERFORMANCE",
                    error_message=f"Slow request: {duration_ms}ms",
                    ip_address=ip_address,
                    user_agent=user_agent[:500] if user_agent else None,
                    duration_ms=duration_ms
                )
                db.add(log_entry)
                await db.commit()
        except Exception as e:
            print(f"Failed to log slow request: {e}")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
import logging
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

from database import init_db
from routes import router as api_router
from billing import router as billing_router
from reports import router as reports_router
from patient_workflow import router as patient_workflow_router
from assets import router as assets_router
from setup import router as setup_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up MTH Hospital Operations System...")
    await init_db()
    logger.info("Database initialized")
    yield
    # Shutdown
    logger.info("Shutting down...")


app = FastAPI(
    title="MTH Hospital Operations System",
    description="Order-driven hospital operating system",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(api_router, prefix="/api")
app.include_router(billing_router, prefix="/api")
app.include_router(reports_router, prefix="/api")
app.include_router(patient_workflow_router, prefix="/api")
app.include_router(assets_router, prefix="/api")
app.include_router(setup_router, prefix="/api")


@app.get("/")
async def root():
    return {"message": "MTH Hospital Operations System API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}

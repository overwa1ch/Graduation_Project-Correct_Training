"""
FastAPI health endpoint for worker service
"""
from fastapi import FastAPI
from config import settings
import logging

# Configure logging
logging.basicConfig(
    level=settings.log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

app = FastAPI(title=f"AIWA {settings.worker_type.upper()} Worker")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "worker_type": settings.worker_type,
        "model_path": settings.rtmpose_model_path if settings.worker_type == "reinfer" else None,
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": f"AIWA {settings.worker_type.upper()} Worker",
        "version": "1.0.0",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


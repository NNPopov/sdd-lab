# FEATURE: tasks — router.
from typing import Any

from arq.jobs import Job as ArqJob
from fastapi import APIRouter, Depends, HTTPException

from ...adapters.queue import arq_queue as queue
from ...shared_dependencies import rate_limiter_dependency
from .schemas import Job

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("/task", response_model=Job, status_code=201, dependencies=[Depends(rate_limiter_dependency)])
async def create_task(message: str) -> dict[str, str]:
    """Create a new background task."""
    if queue.pool is None:
        raise HTTPException(status_code=503, detail="Queue is not available")

    job = await queue.pool.enqueue_job("sample_background_task", message)
    if job is None:
        raise HTTPException(status_code=500, detail="Failed to create task")

    return {"id": job.job_id}


@router.get("/task/{task_id}")
async def get_task(task_id: str) -> dict[str, Any] | None:
    """Get information about a specific background task."""
    if queue.pool is None:
        raise HTTPException(status_code=503, detail="Queue is not available")

    job = ArqJob(task_id, queue.pool)
    job_info = await job.info()
    if job_info is None:
        return None

    return job_info.__dict__

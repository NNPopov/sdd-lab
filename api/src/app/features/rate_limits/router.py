# FEATURE: rate_limits — router.
from fastapi import APIRouter, Depends
from fastcrud import PaginatedListResponse

from ...features.users.dependencies import get_current_superuser
from ..rate_limits.schemas import RateLimitRead
from .use_cases.rate_limit_delete import erase_rate_limit
from .use_cases.rate_limit_get import read_rate_limits
from .use_cases.rate_limit_get_by_id import read_rate_limit
from .use_cases.rate_limit_patch import patch_rate_limit
from .use_cases.rate_limit_post import write_rate_limit

router = APIRouter(tags=["rate_limits"])

router.post("/tier/{tier_name}/rate_limit", dependencies=[Depends(get_current_superuser)], status_code=201)(
    write_rate_limit
)
router.get("/tier/{tier_name}/rate_limits", response_model=PaginatedListResponse[RateLimitRead])(read_rate_limits)
router.get("/tier/{tier_name}/rate_limit/{id}", response_model=RateLimitRead)(read_rate_limit)
router.patch("/tier/{tier_name}/rate_limit/{id}", dependencies=[Depends(get_current_superuser)])(patch_rate_limit)
router.delete("/tier/{tier_name}/rate_limit/{id}", dependencies=[Depends(get_current_superuser)])(erase_rate_limit)

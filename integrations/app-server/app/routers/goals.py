from fastapi import APIRouter, Depends

from ..auth import require_api_key
from ..config_parsers import parse_goals, parse_schedule

router = APIRouter(dependencies=[Depends(require_api_key)])


@router.get("/goals")
async def get_goals() -> dict:
    return parse_goals()


@router.get("/schedule")
async def get_schedule() -> dict:
    return parse_schedule()

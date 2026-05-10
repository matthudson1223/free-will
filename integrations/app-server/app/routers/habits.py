from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..auth import require_api_key
from ..habits import HABIT_COLUMNS, get_today, parse_tracker, toggle_habit

router = APIRouter(prefix="/habits", dependencies=[Depends(require_api_key)])


@router.get("")
async def all_habits() -> list[dict]:
    return parse_tracker()


@router.get("/today")
async def today_habits() -> dict:
    return get_today()


class HabitToggle(BaseModel):
    completed: bool


@router.post("/{entry_date}/{habit}")
async def toggle(entry_date: str, habit: str, body: HabitToggle) -> dict:
    if habit not in HABIT_COLUMNS:
        raise HTTPException(400, f"Unknown habit. Valid: {HABIT_COLUMNS}")
    return toggle_habit(entry_date, habit, body.completed)

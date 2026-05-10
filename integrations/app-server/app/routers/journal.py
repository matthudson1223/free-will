import re
from datetime import date
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..auth import require_api_key

router = APIRouter(prefix="/journal", dependencies=[Depends(require_api_key)])

JOURNAL_ROOT = Path("/home/developer/free-will/habits/journal")
TEMPLATE_PATH = Path("/home/developer/free-will/templates/daily-journal.md")


@router.get("")
async def list_entries() -> list[dict]:
    if not JOURNAL_ROOT.exists():
        return []
    files = sorted(
        JOURNAL_ROOT.rglob("*.md"),
        key=lambda p: p.name,
        reverse=True,
    )
    return [
        {
            "date": p.stem,
            "path": str(p.relative_to(Path("/home/developer/free-will"))),
            "size": p.stat().st_size,
        }
        for p in files
        if re.match(r"\d{4}-\d{2}-\d{2}", p.stem)
    ]


@router.get("/{entry_date}")
async def get_entry(entry_date: str) -> dict:
    if not re.match(r"\d{4}-\d{2}-\d{2}$", entry_date):
        raise HTTPException(400, "Date must be YYYY-MM-DD")
    year = entry_date[:4]
    path = JOURNAL_ROOT / year / f"{entry_date}.md"
    if not path.exists():
        raise HTTPException(404, f"No journal entry for {entry_date}")
    return {"date": entry_date, "content": path.read_text()}


class JournalCreate(BaseModel):
    content: str = ""


@router.post("/{entry_date}", status_code=201)
async def create_entry(entry_date: str, body: JournalCreate) -> dict:
    if not re.match(r"\d{4}-\d{2}-\d{2}$", entry_date):
        raise HTTPException(400, "Date must be YYYY-MM-DD")
    year = entry_date[:4]
    path = JOURNAL_ROOT / year / f"{entry_date}.md"
    if path.exists():
        raise HTTPException(409, f"Entry already exists for {entry_date}")

    path.parent.mkdir(parents=True, exist_ok=True)

    if body.content:
        content = body.content
    elif TEMPLATE_PATH.exists():
        content = TEMPLATE_PATH.read_text().replace("{{date}}", entry_date).replace("YYYY-MM-DD", entry_date)
    else:
        content = f"# {entry_date}\n\n"

    path.write_text(content)
    return {"date": entry_date, "content": content}

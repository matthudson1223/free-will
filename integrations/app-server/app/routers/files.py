from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException

from ..auth import require_api_key

router = APIRouter(prefix="/files", dependencies=[Depends(require_api_key)])

ROOT = Path("/home/developer/free-will")


@router.get("")
async def list_files(path: str = "") -> list[dict]:
    try:
        target = (ROOT / path.lstrip("/")).resolve()
    except Exception:
        raise HTTPException(400, "Invalid path")

    if not target.is_relative_to(ROOT):
        raise HTTPException(403, "Path outside free-will root")

    if not target.exists():
        raise HTTPException(404, "Path not found")

    if target.is_file():
        stat = target.stat()
        return [{"name": target.name, "type": "file", "size": stat.st_size,
                 "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()}]

    entries = sorted(target.iterdir(), key=lambda p: (p.is_file(), p.name))
    result = []
    for entry in entries:
        stat = entry.stat()
        result.append({
            "name": entry.name,
            "type": "file" if entry.is_file() else "dir",
            "size": stat.st_size if entry.is_file() else None,
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
        })
    return result

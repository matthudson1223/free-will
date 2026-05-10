import json
import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..auth import require_api_key
from ..db import get_conn

router = APIRouter(prefix="/conversations", dependencies=[Depends(require_api_key)])


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _extract_text(content_raw: str) -> str:
    """Pull plain text from a content field that may be a JSON block array."""
    try:
        blocks = json.loads(content_raw)
        if isinstance(blocks, list):
            return " ".join(
                b.get("text", "") for b in blocks if isinstance(b, dict) and b.get("type") == "text"
            ).strip()
    except (json.JSONDecodeError, TypeError):
        pass
    return content_raw


class ConversationCreate(BaseModel):
    title: str = "New conversation"


class ConversationPatch(BaseModel):
    title: str


@router.post("", status_code=201)
async def create_conversation(body: ConversationCreate) -> dict:
    conn = get_conn()
    cid = str(uuid.uuid4())
    now = _now()
    conn.execute(
        "INSERT INTO conversations (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)",
        (cid, body.title, now, now),
    )
    conn.commit()
    return {"id": cid, "title": body.title, "created_at": now, "updated_at": now}


@router.get("")
async def list_conversations() -> list[dict]:
    rows = get_conn().execute(
        "SELECT id, title, created_at, updated_at FROM conversations ORDER BY updated_at DESC"
    ).fetchall()
    return [dict(r) for r in rows]


@router.get("/{cid}/messages")
async def get_messages(cid: str) -> list[dict]:
    conn = get_conn()
    if not conn.execute("SELECT 1 FROM conversations WHERE id=?", (cid,)).fetchone():
        raise HTTPException(404, "Conversation not found")
    rows = conn.execute(
        "SELECT id, conversation_id, role, content, created_at FROM messages WHERE conversation_id=? ORDER BY created_at",
        (cid,),
    ).fetchall()
    result = []
    for r in rows:
        d = dict(r)
        d["content"] = _extract_text(d["content"])
        result.append(d)
    return result


@router.patch("/{cid}")
async def update_conversation(cid: str, body: ConversationPatch) -> dict:
    conn = get_conn()
    if not conn.execute("SELECT 1 FROM conversations WHERE id=?", (cid,)).fetchone():
        raise HTTPException(404, "Conversation not found")
    conn.execute(
        "UPDATE conversations SET title=?, updated_at=? WHERE id=?",
        (body.title, _now(), cid),
    )
    conn.commit()
    row = conn.execute("SELECT * FROM conversations WHERE id=?", (cid,)).fetchone()
    return dict(row)

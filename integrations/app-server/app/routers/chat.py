import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from ..auth import validate_ws_key
from ..claude import stream_claude
from ..db import get_conn

router = APIRouter()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _load_history(conversation_id: str) -> list[dict]:
    """Rebuild the messages list from DB for the Claude API."""
    conn = get_conn()
    rows = conn.execute(
        "SELECT role, content FROM messages WHERE conversation_id=? ORDER BY created_at",
        (conversation_id,),
    ).fetchall()
    messages = []
    for row in rows:
        role = row["role"]
        if role not in ("user", "assistant"):
            continue
        try:
            content = json.loads(row["content"])
        except (json.JSONDecodeError, TypeError):
            content = row["content"]
        messages.append({"role": role, "content": content})
    return messages


def _persist_message(conversation_id: str, role: str, content) -> str:
    mid = str(uuid.uuid4())
    content_str = json.dumps(content) if not isinstance(content, str) else content
    get_conn().execute(
        "INSERT INTO messages (id, conversation_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (mid, conversation_id, role, content_str, _now()),
    )
    get_conn().commit()
    return mid


def _touch_conversation(conversation_id: str) -> None:
    get_conn().execute(
        "UPDATE conversations SET updated_at=? WHERE id=?",
        (_now(), conversation_id),
    )
    get_conn().commit()


@router.websocket("/ws/chat/{conversation_id}")
async def chat_ws(
    websocket: WebSocket,
    conversation_id: str,
    key: str = Query(...),
):
    await websocket.accept()

    if not await validate_ws_key(websocket, key):
        return

    # Verify conversation exists
    conn = get_conn()
    if not conn.execute("SELECT 1 FROM conversations WHERE id=?", (conversation_id,)).fetchone():
        await websocket.send_json({"type": "error", "message": "Conversation not found"})
        await websocket.close()
        return

    messages = _load_history(conversation_id)

    async def send_event(event: dict) -> None:
        await websocket.send_text(json.dumps(event))

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                payload = json.loads(raw)
            except json.JSONDecodeError:
                await send_event({"type": "error", "message": "Invalid JSON"})
                continue

            if payload.get("type") != "message":
                continue

            user_text: str = payload.get("text", "").strip()
            if not user_text:
                continue

            # Append user turn
            messages.append({"role": "user", "content": user_text})
            _persist_message(conversation_id, "user", user_text)

            try:
                messages, full_text = await stream_claude(send_event, messages)
            except Exception as e:
                await send_event({"type": "error", "message": str(e)})
                # Pop the user message so history isn't corrupted
                messages.pop()
                continue

            # Persist the assistant turn (last entry in messages is assistant)
            if messages and messages[-1]["role"] == "assistant":
                _persist_message(conversation_id, "assistant", messages[-1]["content"])

            _touch_conversation(conversation_id)

    except WebSocketDisconnect:
        pass

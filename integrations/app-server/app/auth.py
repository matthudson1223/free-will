from fastapi import Header, HTTPException, WebSocket, status

from .db import get_conn

_cached_key: str | None = None


def _get_stored_key() -> str:
    global _cached_key
    if _cached_key:
        return _cached_key
    row = get_conn().execute("SELECT value FROM settings WHERE key='api_key'").fetchone()
    if not row:
        raise HTTPException(status_code=503, detail="Server not initialized")
    _cached_key = row["value"]
    return _cached_key


def require_api_key(x_api_key: str = Header(..., alias="X-Api-Key")) -> str:
    if x_api_key != _get_stored_key():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API key")
    return x_api_key


async def validate_ws_key(websocket: WebSocket, key: str) -> bool:
    if key != _get_stored_key():
        await websocket.close(code=4001)
        return False
    return True

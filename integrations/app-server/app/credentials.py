import json
import time
import threading
from pathlib import Path

import httpx

CREDENTIALS_PATH = Path.home() / ".claude" / ".credentials.json"
TOKEN_REFRESH_URL = "https://claude.ai/api/oauth/token"

_lock = threading.Lock()
_cached_token: str | None = None
_cached_expires_at: int = 0


def _read_credentials() -> dict:
    if not CREDENTIALS_PATH.exists():
        raise RuntimeError(
            f"Credentials not found at {CREDENTIALS_PATH}. Run 'claude' and log in first."
        )
    return json.loads(CREDENTIALS_PATH.read_text())


def _write_credentials(creds: dict) -> None:
    CREDENTIALS_PATH.write_text(json.dumps(creds, indent=2))


def _refresh(refresh_token: str) -> str:
    resp = httpx.post(
        TOKEN_REFRESH_URL,
        json={"grant_type": "refresh_token", "refresh_token": refresh_token},
        timeout=15,
    )
    resp.raise_for_status()
    data = resp.json()

    creds = _read_credentials()
    oauth = creds.setdefault("claudeAiOauth", {})
    oauth["accessToken"] = data["access_token"]
    oauth["refreshToken"] = data.get("refresh_token", refresh_token)
    # expires_in is seconds from now
    expires_in = data.get("expires_in", 3600)
    oauth["expiresAt"] = int((time.time() + expires_in) * 1000)
    _write_credentials(creds)

    return oauth["accessToken"]


def load_access_token() -> str:
    global _cached_token, _cached_expires_at

    now_ms = int(time.time() * 1000)
    margin_ms = 60_000  # refresh 60s before expiry

    with _lock:
        if _cached_token and _cached_expires_at - now_ms > margin_ms:
            return _cached_token

        creds = _read_credentials()
        oauth = creds.get("claudeAiOauth", {})
        access_token: str = oauth.get("accessToken", "")
        expires_at: int = oauth.get("expiresAt", 0)
        refresh_token: str = oauth.get("refreshToken", "")

        if not access_token:
            raise RuntimeError("No accessToken in credentials file.")

        if expires_at - now_ms <= margin_ms and refresh_token:
            access_token = _refresh(refresh_token)
            expires_at = _read_credentials()["claudeAiOauth"]["expiresAt"]

        _cached_token = access_token
        _cached_expires_at = expires_at
        return access_token

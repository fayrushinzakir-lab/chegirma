"""Простые подписанные сессионные токены (HMAC, без внешних зависимостей)."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import secrets
import time

_SECRETS_DIR = os.path.join(os.path.dirname(__file__), "..", ".secrets")
_KEY_PATH = os.path.join(_SECRETS_DIR, "session_key.txt")


def _load_key() -> bytes:
    os.makedirs(_SECRETS_DIR, exist_ok=True)
    if os.path.exists(_KEY_PATH):
        with open(_KEY_PATH) as f:
            return f.read().strip().encode()
    key = secrets.token_hex(32)
    with open(_KEY_PATH, "w") as f:
        f.write(key)
    return key.encode()


_KEY = _load_key()


def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def _unb64(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def issue(payload: dict, ttl_days: int = 180) -> str:
    body = dict(payload)
    body["exp"] = int(time.time()) + ttl_days * 86400
    raw = json.dumps(body, separators=(",", ":")).encode()
    sig = hmac.new(_KEY, raw, hashlib.sha256).digest()
    return f"{_b64(raw)}.{_b64(sig)}"


def verify(token: str) -> dict | None:
    try:
        b, s = token.split(".")
        raw = _unb64(b)
        sig = _unb64(s)
        if not hmac.compare_digest(sig, hmac.new(_KEY, raw, hashlib.sha256).digest()):
            return None
        data = json.loads(raw)
        if data.get("exp", 0) < time.time():
            return None
        return data
    except Exception:  # noqa: BLE001
        return None

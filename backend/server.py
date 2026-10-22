"""Локальный бэкенд входа через Telegram-бота (стандартная библиотека Python).

Поток: приложение POST /auth/start → nonce + ссылка на бота →
пользователь жмёт Start и «Поделиться номером» → бот (long-polling) ловит
контакт → /auth/status отдаёт сессию. Публичный доступ — через cloudflared-туннель.

Запуск:  python3 backend/server.py
Токен бота берётся из .secrets/telegram_bot_token.txt
"""
from __future__ import annotations

import json
import os
import ssl
import sys
import threading
import time
import urllib.parse
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import auth  # noqa: E402  (подпись сессии)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKEN = open(os.path.join(ROOT, ".secrets", "telegram_bot_token.txt")).read().strip()
BOT_USERNAME = "chegirma_login_bot"
API = f"https://api.telegram.org/bot{TOKEN}"
PORT = 8787

try:
    import certifi
    _CTX = ssl.create_default_context(cafile=certifi.where())
except Exception:  # noqa: BLE001
    _CTX = ssl.create_default_context()

# nonce -> {"status": "pending"|"authorized", "phone","name", "ts": epoch}
_NONCES: dict[str, dict] = {}
# chat_id -> nonce
_CHATS: dict[int, str] = {}
_RATE: dict[str, list] = {}  # ip -> [timestamps]
_LOCK = threading.Lock()
NONCE_TTL = 600  # сек


def _prune(now: float) -> None:
    for k in [k for k, v in _NONCES.items() if now - v.get("ts", now) > NONCE_TTL]:
        _NONCES.pop(k, None)
    for ip in list(_RATE):
        _RATE[ip] = [t for t in _RATE[ip] if now - t < 60]
        if not _RATE[ip]:
            _RATE.pop(ip, None)


def _rate_ok(ip: str, now: float) -> bool:
    lst = _RATE.setdefault(ip, [])
    lst.append(now)
    return len([t for t in lst if now - t < 60]) <= 15


def _tg(method: str, payload: dict) -> dict:
    req = urllib.request.Request(
        f"{API}/{method}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=40, context=_CTX) as r:
        return json.loads(r.read().decode())


def _poll_loop():
    offset = 0
    print("[bot] long-polling запущен")
    while True:
        try:
            data = _tg("getUpdates", {"offset": offset, "timeout": 30})
            for upd in data.get("result", []):
                offset = upd["update_id"] + 1
                msg = upd.get("message")
                if not msg:
                    continue
                chat_id = msg["chat"]["id"]
                text = msg.get("text", "")
                if text.startswith("/start"):
                    parts = text.split(" ", 1)
                    nonce = parts[1].strip() if len(parts) > 1 else ""
                    if nonce:
                        with _LOCK:
                            _CHATS[chat_id] = nonce
                    _tg("sendMessage", {
                        "chat_id": chat_id,
                        "text": "Чтобы войти в Chegirmalar, поделитесь номером 👇",
                        "reply_markup": {
                            "keyboard": [[{"text": "📱 Поделиться номером", "request_contact": True}]],
                            "resize_keyboard": True, "one_time_keyboard": True,
                        },
                    })
                elif msg.get("contact"):
                    phone = "+" + "".join(ch for ch in msg["contact"]["phone_number"] if ch.isdigit())
                    name = " ".join(filter(None, [msg["contact"].get("first_name"), msg["contact"].get("last_name")]))
                    with _LOCK:
                        nonce = _CHATS.get(chat_id)
                        if nonce:
                            _NONCES[nonce] = {"status": "authorized", "phone": phone, "name": name, "ts": time.time()}
                    _tg("sendMessage", {"chat_id": chat_id,
                                        "text": "✅ Готово! Вернитесь в приложение.",
                                        "reply_markup": {"remove_keyboard": True}})
        except Exception as e:  # noqa: BLE001
            print("[bot] ошибка:", e)
            time.sleep(3)


class Handler(BaseHTTPRequestHandler):
    def _send(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):  # тише в логах
        pass

    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        if u.path == "/":
            return self._send({"ok": True, "service": "chegirmalar-auth"})
        if u.path == "/auth/status":
            nonce = urllib.parse.parse_qs(u.query).get("nonce", [""])[0]
            with _LOCK:
                rec = _NONCES.get(nonce)
            if not rec:
                return self._send({"status": "expired"})
            if rec["status"] == "authorized":
                token = auth.issue({"phone": rec["phone"], "name": rec["name"]})
                return self._send({"status": "authorized", "token": token,
                                   "phone": rec["phone"], "name": rec["name"]})
            return self._send({"status": "pending"})
        return self._send({"error": "not found"}, 404)

    def do_POST(self):
        if urllib.parse.urlparse(self.path).path == "/auth/start":
            now = time.time()
            ip = self.client_address[0]
            with _LOCK:
                _prune(now)
                if not _rate_ok(ip, now):
                    return self._send({"error": "too many requests"}, 429)
                nonce = os.urandom(16).hex()
                _NONCES[nonce] = {"status": "pending", "ts": now}
            return self._send({"nonce": nonce,
                               "botUrl": f"https://t.me/{BOT_USERNAME}?start={nonce}",
                               "botUsername": BOT_USERNAME})
        return self._send({"error": "not found"}, 404)


if __name__ == "__main__":
    threading.Thread(target=_poll_loop, daemon=True).start()
    print(f"[http] слушаю :{PORT}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()

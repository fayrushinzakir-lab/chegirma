// Chegirmalar — бесплатный бэкенд входа через Telegram-бота (Deno Deploy).
// Поток: приложение /auth/start → открывает t.me/бот?start=<nonce> → пользователь
// жмёт «Поделиться номером» → Telegram шлёт webhook → выдаём сессию → /auth/status.
//
// ENV (в настройках проекта Deno Deploy):
//   TG_BOT_TOKEN   — токен бота (@chegirma_login_bot)
//   SESSION_SECRET — любая длинная случайная строка (для подписи сессии)
//   BOT_USERNAME   — chegirma_login_bot

const TOKEN = Deno.env.get("TG_BOT_TOKEN") ?? "";
const SECRET = Deno.env.get("SESSION_SECRET") ?? "dev-secret-change-me";
const BOT = Deno.env.get("BOT_USERNAME") ?? "chegirma_login_bot";
const API = `https://api.telegram.org/bot${TOKEN}`;

const kv = await Deno.openKv();

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json", "access-control-allow-origin": "*" },
  });
}

function rand(n = 16): string {
  const b = new Uint8Array(n);
  crypto.getRandomValues(b);
  return [...b].map((x) => x.toString(16).padStart(2, "0")).join("");
}

async function sign(payload: Record<string, unknown>): Promise<string> {
  const body = btoa(JSON.stringify({ ...payload, exp: Date.now() + 180 * 864e5 }));
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(SECRET),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  const s = btoa(String.fromCharCode(...new Uint8Array(sig)));
  return `${body}.${s}`;
}

async function tg(method: string, body: unknown) {
  await fetch(`${API}/${method}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

async function handleWebhook(update: any) {
  const msg = update.message;
  if (!msg) return;
  const chatId = msg.chat.id;

  // /start <nonce> — связываем чат с попыткой входа
  if (typeof msg.text === "string" && msg.text.startsWith("/start")) {
    const nonce = msg.text.split(" ")[1] ?? "";
    if (nonce) await kv.set(["chat", chatId], nonce, { expireIn: 600000 });
    await tg("sendMessage", {
      chat_id: chatId,
      text: "Чтобы войти в Chegirmalar, поделитесь номером телефона 👇",
      reply_markup: {
        keyboard: [[{ text: "📱 Поделиться номером", request_contact: true }]],
        resize_keyboard: true, one_time_keyboard: true,
      },
    });
    return;
  }

  // Контакт — завершаем вход
  if (msg.contact && msg.contact.phone_number) {
    const nonceEntry = await kv.get<string>(["chat", chatId]);
    const nonce = nonceEntry.value;
    const phone = "+" + msg.contact.phone_number.replace(/\D/g, "");
    const name = [msg.contact.first_name, msg.contact.last_name].filter(Boolean).join(" ");
    if (nonce) {
      await kv.set(["nonce", nonce], { status: "authorized", phone, name, tgId: msg.from.id }, { expireIn: 600000 });
    }
    await tg("sendMessage", {
      chat_id: chatId,
      text: "✅ Готово! Вернитесь в приложение Chegirmalar.",
      reply_markup: { remove_keyboard: true },
    });
  }
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  if (req.method === "OPTIONS") return json({});

  if (url.pathname === "/") return json({ ok: true, service: "chegirmalar-auth" });

  // старт входа
  if (url.pathname === "/auth/start" && req.method === "POST") {
    const nonce = rand();
    await kv.set(["nonce", nonce], { status: "pending" }, { expireIn: 600000 });
    return json({ nonce, botUrl: `https://t.me/${BOT}?start=${nonce}`, botUsername: BOT });
  }

  // статус входа (поллинг из приложения)
  if (url.pathname === "/auth/status") {
    const nonce = url.searchParams.get("nonce") ?? "";
    const e = await kv.get<any>(["nonce", nonce]);
    if (!e.value) return json({ status: "expired" });
    if (e.value.status === "authorized") {
      const token = await sign({ phone: e.value.phone, name: e.value.name });
      return json({ status: "authorized", token, phone: e.value.phone, name: e.value.name });
    }
    return json({ status: "pending" });
  }

  // webhook Telegram
  if (url.pathname === "/tg-webhook" && req.method === "POST") {
    try { await handleWebhook(await req.json()); } catch (_) { /* ignore */ }
    return json({ ok: true });
  }

  return json({ error: "not found" }, 404);
});

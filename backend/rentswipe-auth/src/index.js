const ALLOWED_ORIGIN = "*"; // later: change to "https://yourdomain.com"

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return handleOptions(request);
    }

    if (request.method === "POST" && url.pathname === "/api/signup") {
      return handleSignup(request, env);
    }

    if (request.method === "POST" && url.pathname === "/api/login") {
      return handleLogin(request, env);
    }

    return corsResponse("Not found", 404, "text/plain");
  },
};

function handleOptions(request) {
  const requestHeaders =
    request.headers.get("Access-Control-Request-Headers") || "Content-Type";

  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": requestHeaders,
      "Access-Control-Max-Age": "86400",
    },
  });
}


async function parseBody(request) {
  const contentType = request.headers.get("content-type") || "";

  if (contentType.includes("application/json")) {
    return await request.json();
  }

  if (contentType.includes("application/x-www-form-urlencoded")) {
    const formData = await request.formData();
    return Object.fromEntries(formData.entries());
  }

  return null;
}

// Simple SHA-256 hash (good enough for a prototype)
async function hashPassword(password) {
  const enc = new TextEncoder();
  const bytes = enc.encode(password);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  const arr = new Uint8Array(digest);
  return Array.from(arr)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/* ---------- SIGNUP ---------- */

async function handleSignup(request, env) {
  try {
    const data = await parseBody(request);

    if (!data) return json({ ok: false, error: "Unsupported content-type" }, 400);

    let { fullName, email, password, accountType } = data;

    if (!fullName || !email || !password || !accountType) {
      return json({ ok: false, error: "Missing required fields." }, 400);
    }

    fullName = String(fullName).trim();
    email = String(email).trim().toLowerCase();
    password = String(password).trim();
    accountType = String(accountType).trim();

    if (!["tenant", "landlord"].includes(accountType)) {
      return json({ ok: false, error: "Invalid account type." }, 400);
    }

    // Check if a user with this email already exists
    const existing = await env.DB.prepare(
      "SELECT id FROM users WHERE email = ?"
    )
      .bind(email)
      .first();

    if (existing) {
      return json(
        { ok: false, error: "An account with that email already exists." },
        409
      );
    }

    const passwordHash = await hashPassword(password);

    await env.DB.prepare(
      "INSERT INTO users (full_name, email, password_hash, account_type) VALUES (?, ?, ?, ?)"
    )
      .bind(fullName, email, passwordHash, accountType)
      .run();

    const user = { fullName, email, accountType };

    return json({ ok: true, user }, 201);
  } catch (err) {
    console.error("Signup error:", err);
    return json({ ok: false, error: "Internal server error" }, 500);
  }
}

/* ---------- LOGIN ---------- */

async function handleLogin(request, env) {
  try {
    const data = await parseBody(request);

    if (!data) return json({ ok: false, error: "Unsupported content-type" }, 400);

    let { email, password } = data;

    if (!email || !password) {
      return json({ ok: false, error: "Missing email or password." }, 400);
    }

    email = String(email).trim().toLowerCase();
    password = String(password).trim();

    const row = await env.DB.prepare(
      "SELECT id, full_name, email, password_hash, account_type FROM users WHERE email = ?"
    )
      .bind(email)
      .first();

    if (!row) {
      return json({ ok: false, error: "Invalid email or password." }, 401);
    }

    const passwordHash = await hashPassword(password);

    if (passwordHash !== row.password_hash) {
      return json({ ok: false, error: "Invalid email or password." }, 401);
    }

    const user = {
      fullName: row.full_name,
      email: row.email,
      accountType: row.account_type,
    };

    return json({ ok: true, user }, 200);
  } catch (err) {
    console.error("Login error:", err);
    return json({ ok: false, error: "Internal server error" }, 500);
  }
}

/* ---------- Helpers ---------- */

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    },
  });
}

function corsResponse(body, status = 200, contentType = "text/plain") {
  return new Response(body, {
    status,
    headers: {
      "Content-Type": contentType,
      "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    },
  });
}

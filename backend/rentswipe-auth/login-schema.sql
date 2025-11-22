CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name     TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  account_type  TEXT NOT NULL CHECK (account_type IN ('tenant', 'landlord')),
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

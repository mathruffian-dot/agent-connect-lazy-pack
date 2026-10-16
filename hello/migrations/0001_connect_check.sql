-- 連接檢查用的測試資料表（Cloudflare D1 / SQLite）
-- 由 Agent 執行：npx -y wrangler d1 migrations apply <暱稱>-hello-db --remote
CREATE TABLE IF NOT EXISTS connect_check (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT NOT NULL CHECK (length(note) BETWEEN 1 AND 200),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

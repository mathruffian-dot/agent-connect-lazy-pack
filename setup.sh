#!/usr/bin/env bash
# opencode-connect-lazy-pack — macOS / Linux 一鍵檢查（不亂裝、不碰密碼）
set -u

has() { command -v "$1" >/dev/null 2>&1; }

echo "=== 1. OpenCode 本體 ==="
if has opencode; then opencode --version; else echo "沒找到 opencode，先裝：npm i -g opencode-ai"; fi

echo ""
echo "=== 2. MCP 連接狀態 ==="
if has opencode; then
  opencode mcp list
  opencode mcp auth list
else
  echo "先裝好 opencode 再跑一次這支腳本"
fi

echo ""
echo "=== 3. 常用 CLI 有沒有 ==="
for c in wrangler firebase gh supabase gcloud; do
  if has "$c"; then echo "$c 已安裝"; else echo "$c 沒找到（缺才裝）"; fi
done

echo ""
echo "=== 4. 沒帳號先註冊（免費）==="
echo "Supabase:   https://supabase.com/dashboard/sign-up"
echo "Cloudflare: https://dash.cloudflare.com/sign-up"
echo ""
echo "下一步：開 opencode（Build mode），把 CONNECT_PROMPT.md 全文貼上，瀏覽器按同意即可。"

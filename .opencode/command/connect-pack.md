# /connect-pack — Supabase + Cloudflare 一鍵連接

> 使用方式：在這個 repo 裡開 OpenCode 打 `/connect-pack`，或把 CONNECT_PROMPT.md 全文貼到任何專案的 Build mode。

1. 跑 `opencode mcp list` 和 `opencode mcp auth list`，回報連接狀態。
2. 缺的補進 `opencode.json`（只加缺的，不刪原有的）：
   - supabase：type remote，url https://mcp.supabase.com/mcp
   - cloudflare：type remote，url https://mcp.cloudflare.com/mcp
3. 跑 `opencode mcp auth supabase` 和 `opencode mcp auth cloudflare`，請使用者在瀏覽器按同意。
4. 沒帳號就引導註冊再重連：
   - Supabase → https://supabase.com/dashboard/sign-up（GitHub 一鍵註冊）
   - Cloudflare → https://dash.cloudflare.com/sign-up（Email 註冊）
5. 用 `opencode mcp auth list` 證明兩顆都是 authenticated 才算完工。

規則：全部用瀏覽器 OAuth，不經手 API Key；缺 CLI 只提醒不亂裝。

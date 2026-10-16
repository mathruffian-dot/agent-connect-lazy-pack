---
description: 照 AGENTS.md 連接 Supabase（後端）與 Cloudflare（前端），並部署 hello 驗收頁
---

請完整閱讀本資料夾的 `AGENTS.md`，以 OpenCode 平台（代號 `opencode`）身分，從第 0 步開始照做到第 9 步，全程繁體中文。

重點提醒：
- 所有指令由你執行，使用者只負責註冊、登入、在瀏覽器按同意。
- Supabase 用遠端 MCP `https://mcp.supabase.com/mcp`，以 `opencode mcp auth supabase` 觸發 OAuth；寫入設定後若看不到 Supabase 工具，請使用者重開 OpenCode 再輸入 `/connect-pack` 續跑（已完成的步驟會跳過）。
- Cloudflare 用 `npx -y wrangler login`；Cloudflare MCP 為選配。
- 絕不要求使用者貼任何金鑰或密碼，絕不讀取 token 檔。
- 最後輸出「連接完成卡」。

$ARGUMENTS

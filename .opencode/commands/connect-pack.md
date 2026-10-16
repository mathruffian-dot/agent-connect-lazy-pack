---
description: 照 AGENTS.md 連接 Cloudflare（Workers＋D1），並部署 hello 驗收頁
---

請完整閱讀本資料夾的 `AGENTS.md`，以 OpenCode 平台（代號 `opencode`）身分，從第 0 步開始照做到第 8 步，全程繁體中文。

重點提醒：
- 所有指令由你執行，使用者只負責註冊 Cloudflare、在瀏覽器按 Allow。
- 不需要任何 MCP 或金鑰：背景執行 `npx -y wrangler login --browser=false`，把印出的授權網址用 `tools.browser.tabs.open` 開在桌面版 2.x 的瀏覽器窗格；沒有瀏覽器窗格（1.x／TUI）就去掉 `--browser=false`。
- 在 `hello/` 內：改 `wrangler.jsonc` 的 name → `npx -y wrangler d1 create <暱稱>-hello-db --binding DB --update-config` → `npx -y wrangler d1 migrations apply <暱稱>-hello-db --remote` → `npx -y wrangler deploy`。
- 絕不要求使用者貼任何金鑰或密碼，絕不讀取 token 檔。
- 最後輸出「連接完成卡」。

$ARGUMENTS

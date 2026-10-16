# 三平台對照表

> 2026-10-17 依官方文件整理。本包只用 Cloudflare（Workers＋D1）與 Wrangler，**三個平台的指令完全一樣**；平台差異只剩「內建瀏覽器怎麼開」。標「需實測」的項目研習前請用實機確認。

## 基本資訊

| 項目 | OpenAI Codex | Google Antigravity 2 | OpenCode |
|---|---|---|---|
| 下載 | https://developers.openai.com/codex （桌面 App） | https://antigravity.google | https://opencode.ai/download （桌面版 2.x） |
| 帳號 | ChatGPT 帳號；免費方案可用額度需實測 | Google 帳號；學校 Workspace 帳號是否可用需實測 | 可用內建免費模型；也可接自己的模型供應商 |
| 自動讀取 `AGENTS.md` | 是 | 是（也讀 `GEMINI.md`） | 是（沒有才讀 `CLAUDE.md`） |
| 斜線指令 | — | — | `/connect-pack`（`.opencode/commands/connect-pack.md`） |

## 內建瀏覽器（唯一的平台差異）

| 項目 | OpenAI Codex | Google Antigravity 2 | OpenCode |
|---|---|---|---|
| 有沒有 | 有（桌面 App；`Ctrl+Shift+B` 切換、`Ctrl+T` 開分頁）；CLI、IDE 擴充**沒有** | 有 browser agent | **桌面版 2.x 有**（瀏覽器窗格，Agent 用 `tools.browser.*` 開分頁、讀頁面）；1.x、TUI **沒有** |
| 怎麼開網址 | Agent 用內建瀏覽器工具開 | Agent 用 browser agent 開 | `tools.browser.tabs.open` |
| 登入狀態 | 獨立設定檔，不共用系統瀏覽器的登入 | 獨立；Google 登入常擋自動化瀏覽器（本包不需要 Google 登入） | 2.x 曾有關閉分頁後登入狀態消失的回報 |
| 沒有時 | 用系統瀏覽器：Windows `Start-Process "<網址>"`、macOS `open`、Linux `xdg-open` | 同左 | 同左 |

**原則**：內建瀏覽器優先（每位學員條件一致），帳號密碼一律由使用者本人輸入；內建瀏覽器擋登入或回呼失敗時改用系統瀏覽器。

## 共用指令（與平台無關，都在 `hello/` 內執行，最後一行除外）

| 步驟 | 指令 |
|---|---|
| 環境檢查（repo 根目錄） | Windows `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1`；macOS／Linux `bash scripts/check.sh` |
| 授權 | `npx -y wrangler login --browser=false`（背景執行，授權網址開在內建瀏覽器，按 Allow，回呼 `localhost:8976`）；沒有內建瀏覽器就去掉 `--browser=false` |
| 確認登入 | `npx -y wrangler whoami` |
| 建資料庫 | `npx -y wrangler d1 create <暱稱>-hello-db --binding DB --update-config` |
| 建資料表 | `npx -y wrangler d1 migrations apply <暱稱>-hello-db --remote` |
| 部署 | `npx -y wrangler deploy` → `https://<暱稱>-hello.<帳號子網域>.workers.dev` |
| 撤銷授權 | `npx wrangler logout` |

- Cloudflare Pages 已併入 Workers，**不要用** `wrangler pages …`。
- Wrangler 登入是整台電腦（同一個 Windows 使用者）共用：在 Codex 授權過，換 OpenCode 不必再授權。
- Token 存放位置（Agent 不得讀取）：Wrangler 本機設定資料夾。

## 選配：Cloudflare MCP

部署與資料庫完全不需要 MCP。想用對話管理 Cloudflare 平台 API 時，可另外加入官方遠端 MCP `https://mcp.cloudflare.com/mcp`（OAuth），用各平台官方的「新增遠端 MCP」方式設定；本包不做、也不提供範本。

## 官方文件

- Cloudflare Workers 靜態資源：https://developers.cloudflare.com/workers/static-assets/
- Cloudflare D1：https://developers.cloudflare.com/d1/ ｜Migrations：https://developers.cloudflare.com/d1/reference/migrations/
- Wrangler 指令：https://developers.cloudflare.com/workers/wrangler/commands/
- Codex 內建瀏覽器：https://developers.openai.com/codex/app/browser
- Antigravity：https://antigravity.google/docs
- OpenCode Rules：https://opencode.ai/docs/rules/ ｜Commands：https://opencode.ai/docs/commands/

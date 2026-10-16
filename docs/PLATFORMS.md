# 三平台對照表

> 2026-10-17 依官方文件整理。標「需實測」的項目官方文件沒寫清楚或有出入，研習前請用實機確認，不要依此推論。

## 基本資訊

| 項目 | OpenAI Codex | Google Antigravity 2 | OpenCode |
|---|---|---|---|
| 下載 | https://developers.openai.com/codex/app （Codex 在 ChatGPT 桌面 App 內）；CLI `npm i -g @openai/codex` | https://antigravity.google/download （App、CLI、IDE 擴充） | https://opencode.ai/download （桌面版）；CLI `npm i -g opencode-ai` |
| 帳號 | ChatGPT 帳號；免費方案可用額度需實測 | Google 帳號；學校 Workspace 帳號是否可用需實測 | 可用內建免費模型；也可接自己的模型供應商 |
| 自動讀取 `AGENTS.md` | 是（Codex 的專案指示檔） | 是（官方 Rules 文件：`AGENTS.md`、`GEMINI.md`、`.agents/AGENTS.md` 等） | 是（專案根目錄 `AGENTS.md`，沒有才讀 `CLAUDE.md`） |
| CLI 指令名稱 | `codex` | 需實測（社群常稱 `agy`；本包檢查腳本同時找 `agy` 與 `antigravity`） | `opencode` |

## MCP 設定

| 項目 | OpenAI Codex | Google Antigravity 2 | OpenCode |
|---|---|---|---|
| 全域設定檔 | `~/.codex/config.toml`（ChatGPT 桌面 App、CLI、IDE 擴充共用） | 官方 MCP 文件：`~/.gemini/config/mcp_config.json`；Supabase 文件寫 `~/.gemini/antigravity/mcp_config.json`——**哪個生效需實測** | `~/.config/opencode/opencode.json`（或 `.jsonc`） |
| 專案設定檔 | `.codex/config.toml`（僅受信任專案生效） | `.agents/mcp_config.json` | 專案根目錄 `opencode.json` |
| 格式 | TOML：`[mcp_servers.supabase]`＋`url = "…"` | JSON：`mcpServers.supabase.serverUrl`（**不支援 `url`、`httpUrl`**） | JSON：`mcp.supabase = { type: "remote", url, enabled }` |
| 指令新增 | `codex mcp add supabase --url https://mcp.supabase.com/mcp` | 無官方 CLI 指令（改檔或用 App 設定介面） | `opencode mcp add`（互動式；本包改為直接寫設定檔） |
| App 介面新增 | 設定 → MCP servers → Add server（Streamable HTTP） | 設定 → Customizations → MCP 伺服器管理 | 需實測 |
| OAuth 觸發 | `codex mcp login supabase`（開系統瀏覽器）；App 內按 Authenticate | 支援 DCR 的伺服器自動；或設定（`Ctrl+,`）→ Customizations → **Authenticate**，必要時把授權碼貼回面板按 Submit | `opencode mcp auth supabase`（開系統瀏覽器）；首次使用時也會自動提示 |
| 狀態查詢 | `codex mcp list`（`--json` 可機器判讀）；對話中 `/mcp` | App 的 Customizations 頁面 | `opencode mcp list`、`opencode mcp auth list`、`opencode mcp debug supabase` |
| 登出 | `codex mcp logout supabase` | App 設定中移除／重新驗證 | `opencode mcp logout supabase` |
| 新設定生效 | 需實測（保守做法：開新對話或重開 App） | 官方建議重開 Antigravity | 重開 OpenCode |
| OAuth 失敗備案 | 換網路後重跑 `codex mcp login` | 改 command 型：`npx -y mcp-remote https://mcp.supabase.com/mcp` | `opencode mcp debug supabase` 後重跑 auth |

## 內建瀏覽器

| 項目 | OpenAI Codex | Google Antigravity 2 | OpenCode |
|---|---|---|---|
| 有沒有 | 有（桌面 App；`Ctrl+Shift+B` 切換分割檢視、`Ctrl+T` 開分頁）；Codex CLI、IDE 擴充**沒有** | 有 browser agent | **桌面版 2.x 有**（瀏覽器窗格，Agent 可用 `tools.browser.*` 開分頁、讀頁面）；桌面版 1.x、TUI／CLI **沒有** |
| 登入狀態 | 獨立設定檔，不共用系統瀏覽器的分頁與登入 | Google 登入常擋自動化瀏覽器 | 2.x 曾有關閉分頁後登入狀態消失的回報 |
| 本包用途 | 預覽、驗收部署好的網頁 | 2.x 桌面版：預覽、驗收；1.x／TUI：使用者在系統瀏覽器按按鈕回報 |

> OpenCode 桌面版版本：設定 › 關於，或安裝程式名稱。1.x 請到 https://opencode.ai/download 下載新版（目前提供 v2）。

**一律原則**：註冊、登入、OAuth 同意都在系統預設瀏覽器由使用者本人完成；內建瀏覽器只做預覽與驗收。

## 共用（與平台無關）

| 項目 | 內容 |
|---|---|
| Supabase MCP | `https://mcp.supabase.com/mcp`（OAuth＋DCR，不需 Key） |
| Cloudflare 部署 | `npx -y wrangler login` → `npx -y wrangler deploy --assets=./hello --name <暱稱>-hello --compatibility-date 2026-10-01`（Pages 已併入 Workers，**不要用** `wrangler pages …`）；網址 `https://<名稱>.<帳號子網域>.workers.dev` |
| Cloudflare MCP（選配） | `https://mcp.cloudflare.com/mcp`（OAuth；管理平台 API，部署網站不需要） |
| Windows 執行檢查腳本 | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1` |
| Token 存放（Agent 不得讀取） | OpenCode `~/.local/share/opencode/mcp-auth.json`；Antigravity `~/.gemini/antigravity/mcp_oauth_tokens.json`；Codex、Wrangler 各自的本機憑證 |

## 官方文件

- OpenCode MCP：https://opencode.ai/docs/mcp-servers/ ｜Rules：https://opencode.ai/docs/rules/ ｜Commands：https://opencode.ai/docs/commands/
- Codex MCP：https://developers.openai.com/codex/mcp ｜內建瀏覽器：https://developers.openai.com/codex/app/browser
- Antigravity MCP：https://antigravity.google/docs/mcp ｜Rules：https://antigravity.google/docs/rules
- Supabase MCP：https://supabase.com/docs/guides/getting-started/mcp
- Cloudflare Workers 靜態資源：https://developers.cloudflare.com/workers/static-assets/ ｜Wrangler 指令：https://developers.cloudflare.com/workers/wrangler/commands/

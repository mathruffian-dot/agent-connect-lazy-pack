# 疑難排解

> 給 Agent 與老師共用。原則不變：指令由 Agent 執行，使用者只負責註冊、登入、按同意。

## Windows 環境

### `.ps1` 無法執行（「因為這個系統上已停用指令碼執行」）
- Agent 改用：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1`
- `-ExecutionPolicy Bypass` 只對這一次執行有效，**不要**改系統執行原則。

### 找不到 `winget`
- 舊版 Windows 或學校電腦可能沒有「應用程式安裝程式」。
- Agent 用系統瀏覽器開 https://nodejs.org/ ，引導使用者下載 **LTS** 的 Windows 安裝檔（.msi），一路按「下一步」。
- 學校電腦若禁止安裝軟體：請改用自己的筆電，或請資訊組協助。

### 裝好 Node.js 但還是說找不到 `node`／`npx`（PATH 未更新）
- 已開著的終端機不會自動拿到新 PATH。Agent 在同一個 PowerShell 指令前加：
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User');`
- 仍不行：請使用者完全關閉並重開 Agent（Codex／Antigravity／OpenCode），再說「照 AGENTS.md 繼續」。

### `winget` 安裝跳出 UAC 但使用者沒看到
- UAC 視窗可能在工作列閃爍、被其他視窗蓋住。請使用者看工作列的盾牌圖示並按「是」。

## OAuth／授權

### 瀏覽器按了同意，但 Agent 一直等不到（回呼失敗）
- 原因多半是防毒軟體、公司或學校代理伺服器擋住 `127.0.0.1`／`localhost` 的回呼。
- 處理順序：① 確認瀏覽器頁面顯示成功 ② 請使用者改連**手機熱點**再重試 ③ 暫時關閉瀏覽器的廣告阻擋擴充 ④ 換用 Chrome／Edge。
- 研習現場若整間教室都失敗，多半是網路層擋，直接全體改手機熱點最快。

### OpenCode：`opencode mcp auth list` 顯示 expired 或未驗證
- 重新執行 `opencode mcp auth supabase`。
- 仍失敗：`opencode mcp debug supabase` 看是連線還是 OAuth 探索失敗；必要時 `opencode mcp logout supabase` 後再 auth 一次。

### Codex：授權失敗或 `codex mcp list` 看不到 supabase
- 確認 `~/.codex/config.toml` 有 `[mcp_servers.supabase]` 與 `url`；沒有就 `codex mcp add supabase --url https://mcp.supabase.com/mcp`。
- 重新 `codex mcp login supabase`。桌面 App 可到設定 → MCP servers → Authenticate。
- 專案層 `.codex/config.toml` 只在「受信任專案」生效；不確定就改用全域設定。
- Codex 沙盒預設可能擋網路或寫入家目錄：Agent 會跳出權限請求，請使用者按允許。

### 內建瀏覽器不能登入／授權後沒反應
- 內建瀏覽器是獨立設定檔，不共用你平常瀏覽器的登入狀態，要在裡面重新登入一次。
- 授權後指令一直沒結束：確認授權網址是由「只印網址」的指令產生（`wrangler login --browser=false`、`codex mcp login … --no-browser`），而且那個指令還在背景等待；逾時就重跑。
- 仍不行 → 改用系統瀏覽器：拿掉 `--browser=false`／`--no-browser` 重跑，讓它自動開平常的瀏覽器。

### Antigravity：遠端 OAuth 連不上 Supabase
- 先確認設定用的是 `serverUrl`（不是 `url`／`httpUrl`），JSON 語法正確，然後重開 Antigravity。
- 到設定（`Ctrl+,`）→ Customizations → supabase → **Authenticate**；網頁若給授權碼，使用者自己貼回面板按 Submit。
- 社群回報 Supabase 遠端 OAuth 曾失敗。仍不行就改 command 型橋接（需 Node.js）：
  ```json
  { "mcpServers": { "supabase": { "command": "npx", "args": ["-y", "mcp-remote", "https://mcp.supabase.com/mcp"] } } }
  ```
  Windows 若啟動失敗改：`"command": "cmd", "args": ["/c", "npx", "-y", "mcp-remote", "https://mcp.supabase.com/mcp"]`。`mcp-remote` 會開系統瀏覽器做 OAuth。
- 設定檔位置不確定（`~/.gemini/config/` 與 `~/.gemini/antigravity/` 兩種說法）：可先寫工作區 `.agents/mcp_config.json` 讓本資料夾能用。

### Antigravity browser agent 卡在 Google 登入
- Google 常擋自動化瀏覽器。Supabase、Cloudflare 都不需要 Google 登入：改用 GitHub、ChatGPT 或 Email 方式；真的要用 Google 帳號時改在系統瀏覽器登入。

## Supabase

### 建專案失敗：已達免費專案上限
- 免費方案每個組織最多 **2 個啟用中**專案。
- 選項：① 沿用既有專案（只會新增一張 `connect_check` 表）② 經使用者同意後暫停一個不用的專案（`pause_project`）③ 建立新組織（需使用者在後台操作）。

### 專案暫停了（閒置約 7 天）
- 對 Agent 說「恢復我的 Supabase 專案」：Agent 用 `restore_project`，等狀態回到 `ACTIVE_HEALTHY`（約數分鐘）。
- 也可由使用者在 Supabase 後台該專案頁按 **Restore**。

### 測試網頁顯示「找不到資料表」「權限被拒（RLS）」
- 找不到資料表：Agent 重做 AGENTS.md 第 5 步。
- 權限被拒：重新套用 `supabase/migrations/20261017000000_connect_check.sql`（含 grant 與 policy，可重複執行）。

### `get_cost` 顯示非 0
- 代表該組織不在免費方案或已有付費資源。Agent 必須停下來問使用者；不同意就沿用既有專案。

## Cloudflare

### 部署失敗、要求驗證 Email
- Cloudflare 註冊後要先點信箱裡的驗證信。請使用者檢查收件匣與垃圾郵件，點完再請 Agent 重試部署。

### `wrangler login` 一直等不到／回呼失敗
- 同上「回呼失敗」處理（手機熱點最快）。
- Agent 的指令逾時太短也會中斷：把逾時設 5 分鐘以上再跑一次。

### 網址打不開（剛部署完）
- 新的 `*.workers.dev` 網址可能要 1～2 分鐘才生效，稍後再開。
- 正式網址以 `wrangler deploy` 輸出最後一行為準，格式 `https://<名稱>.<帳號子網域>.workers.dev`。

### 部署時說要先設定 workers.dev 子網域（新帳號第一次）
- Agent 在內建瀏覽器開 https://dash.cloudflare.com/ （必要時改系統瀏覽器），引導使用者：左側「Workers & Pages」→ 依畫面設定 workers.dev 子網域（自取英文名稱，之後所有網站都會用它）→ 回覆「好了」後 Agent 重跑部署。

### `wrangler pages project create`／`pages deploy` 失敗
- Cloudflare Pages 已併入 Workers，新版 Wrangler 會把它轉成 `wrangler deploy` 而失敗。改用：
  `npx -y wrangler deploy --assets=./hello --name <暱稱>-hello --compatibility-date 2026-10-01`
- 名稱只能小寫 a-z、0-9、連字號。

## 同時使用多個 Agent

各平台的 MCP 設定與授權**互相獨立**，在 A 平台授權過，B 平台還要再授權一次。Wrangler 登入則是整台電腦共用（同一個使用者帳號）。

| 平台 | 設定檔 | 授權方式 |
|---|---|---|
| Codex | `~/.codex/config.toml`（App、CLI、IDE 共用） | `codex mcp login supabase` |
| Antigravity | `~/.gemini/config/mcp_config.json`（或 `~/.gemini/antigravity/mcp_config.json`）、`.agents/mcp_config.json` | Customizations → Authenticate |
| OpenCode | `~/.config/opencode/opencode.json(c)`、專案 `opencode.json` | `opencode mcp auth supabase` |
| Cloudflare（共用） | Wrangler 本機登入 | `npx -y wrangler login` |

`scripts/check.ps1`／`check.sh` 的 `mcp` 區塊會分別列出三個平台是否已設定 Supabase。

# 疑難排解

> 給 Agent 與老師共用。

## 執行原則

- 指令一律由 Agent 執行，使用者只負責註冊 Cloudflare、在瀏覽器按 Allow、按「是／允許」。
- 不需要、也不可以要使用者貼任何密碼、金鑰或 Token。
- `d1 create`、`migrations apply`、`deploy` 都在 `hello/` 資料夾內執行。
- 程序可重跑：卡住處理完後說「照 AGENTS.md 繼續」，已完成的步驟會跳過。

## Windows 環境

### `.ps1` 無法執行（「因為這個系統上已停用指令碼執行」）
- Agent 改用：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1`
- `-ExecutionPolicy Bypass` 只對這一次執行有效，**不要**改系統執行原則。

### 找不到 `winget`
- 舊版 Windows 或學校電腦可能沒有「應用程式安裝程式」。
- Agent 用系統瀏覽器開 https://nodejs.org/ ，引導使用者下載 **LTS** 的 Windows 安裝檔（.msi），一路按「下一步」。
- 學校電腦若禁止安裝軟體：請改用自己的筆電，或請資訊組協助。

### `winget` 安裝跳出 UAC 但使用者沒看到
- UAC 視窗可能在工作列閃爍、被其他視窗蓋住。請使用者看工作列的盾牌圖示並按「是」。

### 裝好 Node.js 但還是說找不到 `node`／`npx`（PATH 未更新）
- 已開著的終端機不會自動拿到新 PATH。Agent 在同一個 PowerShell 指令前加：
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User');`
- 仍不行：請使用者完全關閉並重開 Agent（Codex／Antigravity／OpenCode），再說「照 AGENTS.md 繼續」。

### 資料夾路徑太深（只影響本機 `--local` 測試）
- Windows 路徑上限約 260 字元；資料夾放在很深的位置時，`wrangler d1 … --local` 會出現 `internal error`。正式流程用 `--remote` 不受影響。
- 本機測試請把資料夾放在桌面等短路徑，或加 `--persist-to <短路徑>`。

## Cloudflare 授權（wrangler login）

### 按了 Allow，但指令一直等不到（回呼被擋）
- 授權完成要回呼到本機 `localhost:8976`；防毒軟體、學校或公司網路的代理伺服器常擋這個回呼。
- 處理順序：
  1. 確認瀏覽器頁面顯示授權成功。
  2. 請使用者改連**手機熱點**，Agent 重跑授權（研習現場整間教室都失敗時，全體改熱點最快）。
  3. Agent 重跑 `npx wrangler login --browser=false`，把印出的網址改在**系統瀏覽器**打開完成授權（內建瀏覽器有時回呼不到本機）。
- Agent 的指令逾時太短也會中斷：逾時設 5 分鐘以上再跑一次。

### 內建瀏覽器登入狀態跟平常瀏覽器不同
- 內建瀏覽器是獨立設定檔，平常瀏覽器已登入 Cloudflare，在內建瀏覽器裡還要再登入一次。請先記好密碼。
- 內建瀏覽器擋登入時，改用系統瀏覽器完成，結果相同（Wrangler 登入是整台電腦共用）。

### Codex 沙盒擋網路
- Agent 會跳出權限請求，請使用者按允許。

## Cloudflare 帳號與部署

### 沒收到驗證信／部署失敗要求驗證 Email
- Cloudflare 註冊後要先點信箱裡的驗證信。請使用者檢查收件匣與**垃圾郵件**，點完再請 Agent 重試。
- 仍沒收到：在 Cloudflare 後台上方的提示列可重寄驗證信。

### 部署時說要先設定 workers.dev 子網域（新帳號第一次）
- 新帳號第一次部署時 Wrangler 會提示要註冊子網域。**正常情況下不用手動設定**：`scripts/new-nickname.*` 產生的 `<暱稱>` 已經是「Email 名稱＋6 位隨機數字」，Wrangler 會自動拿它去註冊，通常直接就成功。
- 只有在自動註冊失敗時才需要手動處理（見下一題）。

### 子網域已被別人占用（`the name is unavailable` / `could not automatically register`）
- **這是最常見的失敗點。** workers.dev 子網域是**全 Cloudflare 全球搶先註冊**的，不是只有你自己帳號內唯一，所以兩位不同老師都填 `hello` 就會互相搶。
- Agent 的處理順序：
  1. **換一組數字重跑第 3.5 步**（Windows：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts\new-nickname.ps1`；macOS／Linux：`bash scripts/new-nickname.sh`），把新的 `<暱稱>` 同步寫進 `hello/wrangler.jsonc` 的 `name`，再重跑部署。成功率幾乎 100%。
  2. 使用者堅持要特定名稱時，才在內建瀏覽器開 https://dash.cloudflare.com/ 引導手動設定：左側「Workers & Pages」→ 設定 workers.dev 子網域 → 回覆「好了」後重跑 `npx -y wrangler deploy`。
- 想確認某個名稱合不合法，用 `scripts/new-nickname.* -Check <名稱>`（合法規則：只能小寫 a-z、0-9、連字號，開頭是英文字母，≤63 字元）。

### `wrangler.jsonc` 的 name 錯誤（`CHANGE-ME-hello`）
- 含大寫的預設名稱會被 Wrangler 拒絕，這是防呆：Agent 要先把 name 改成 `<暱稱>-hello`（只能小寫 a-z、0-9、連字號）。

### 重跑整個程序時，暱稱跑掉了
- 第 3.5 步的 `<暱稱>` **只能產生一次**。重跑時先讀 `hello/wrangler.jsonc` 的 `name`：若已經不是 `CHANGE-ME-hello`（例如 `rwsung180-452759-hello`），`<暱稱>` 就是 `-hello` 前面的部分，直接沿用。
- 若不小心重新跑了 `new-nickname.*`，Worker 與 D1 的名稱會對不起來 → 用 `npx -y wrangler deploy` 部署到錯誤的名稱，資料庫則會另外建立。照上面第 1 點重新處理即可。

### D1 名稱重複（already exists）
- 帳號裡已有同名資料庫。因為 `<暱稱>` 已帶隨機數字，這通常代表同一個 Email 跑過兩次而且撞到同一組數字，機率很低。
- 預設做法：換一組數字重跑第 3.5 步，同步更新 `wrangler.jsonc` 的 `name`，重新建立資料庫。
- 想沿用舊的也可以：`npx -y wrangler d1 list` 找到該名稱的 id，手動加進 `hello/wrangler.jsonc` 的 `d1_databases`（binding `DB`）。
- **不要**刪除使用者既有的資料庫，除非使用者明確同意。

### 測試網頁顯示「找不到資料表」（忘記 migrations）
- 代表雲端資料庫還沒建立 `connect_check`。Agent 在 `hello/` 內執行：
  `npx -y wrangler d1 migrations apply <暱稱>-hello-db --remote`
- 不必重新部署。注意要加 `--remote`，`--local` 只會改本機測試資料庫。

### 測試網頁顯示「網站還沒接上 D1 資料庫」
- `wrangler.jsonc` 沒有 `d1_databases`，或部署時不是在 `hello/` 內執行。Agent 補做第 4 步後重新 `npx -y wrangler deploy`。

### 免費額度用完
- Workers 與 D1 免費方案有每日用量上限，**每天 UTC 0 點（台灣早上 8 點）重置**。研習測試幾乎不可能用完；真的出現就隔天再試，不需要升級付費。

### 網址打不開（剛部署完）
- 新的 `*.workers.dev` 網址可能要 1～2 分鐘才生效，稍後再開。
- 正式網址以 `wrangler deploy` 輸出為準，格式 `https://<名稱>.<帳號子網域>.workers.dev`。

### `wrangler pages …` 指令失敗
- Cloudflare Pages 已併入 Workers。本包一律在 `hello/` 內用 `npx -y wrangler deploy`。

## 同時使用多個 Agent

Wrangler 登入是整台電腦（同一個 Windows 使用者）共用，在 A 平台授權過，B 平台不必再授權。第 1 步檢查會看到 `wrangler.status=logged_in` 並自動跳過。

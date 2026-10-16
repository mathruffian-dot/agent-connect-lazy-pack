# Agent 連接懶人包（Codex／Antigravity／OpenCode 三平台）

讓你的 AI Agent 幫你接好 **Supabase（後端資料庫）** 和 **Cloudflare（前端網站）**，最後自動做出一個測試網頁，看到「✅ 連線成功」就完成。

**你不用打任何指令。** 你只負責註冊、登入、按同意；其餘全部由 Agent 執行。

---

## 三步驟

```
① 安裝其中一個 Agent  →  ② 用它開啟這個資料夾  →  ③ 說一句話
```

**① 安裝其中一個 Agent（選一個就好）**

| Agent | 下載 | 需要的帳號 |
|---|---|---|
| OpenAI Codex | 官方說明與下載：https://developers.openai.com/codex/app （Codex 在 ChatGPT 桌面 App 內）｜CLI：`npm i -g @openai/codex` | ChatGPT 帳號（可用方案與額度以 OpenAI 公告為準） |
| Google Antigravity 2 | https://antigravity.google/download | Google 帳號（學校 Workspace 帳號可能被管理員限制，建議用個人帳號） |
| OpenCode | https://opencode.ai/download ｜CLI：`npm i -g opencode-ai` | 可先用內建免費模型，不一定要付費帳號 |

**② 取得這個資料夾並用 Agent 開啟**

- 到本 repo 頁面按綠色 **Code → Download ZIP**，解壓縮到桌面。
- 在 Agent 裡選「開啟資料夾／Open Folder」，選剛剛解壓縮的資料夾。

**③ 在對話框輸入這一句**

```text
照 AGENTS.md 幫我連接 Supabase 和 Cloudflare
```

Agent 中途請你重開程式時，回來說：`照 AGENTS.md 繼續`。各平台備用說法見 [`CONNECT_PROMPT.md`](CONNECT_PROMPT.md)；OpenCode 也可以直接輸入 `/connect-pack`。

---

## 你只需要做的事

- [ ] 沒有帳號時，在跳出來的網頁註冊 **Supabase**（可選 GitHub、ChatGPT 或 Email；**沒有 Google 一鍵登入**，想用 Gmail 就走 Email 註冊）和 **Cloudflare**（Email 註冊，**記得去信箱點驗證信**）
- [ ] 瀏覽器跳出授權頁時：登入 → 選擇組織 → 按 **Authorize／Allow／同意**
- [ ] Windows 跳出「是否允許此 App 變更您的裝置」時按 **是**（只在需要安裝 Node.js 時出現）
- [ ] Agent 請求執行指令或連網的權限時按 **允許**
- [ ] 告訴 Agent 一個英文暱稱（例如 `wang`），網站會叫 `wang-hello`
- [ ] Cloudflare 新帳號第一次部署時，Agent 可能請你在 Cloudflare 後台「Workers & Pages」設定一個 workers.dev 子網域（自取英文名稱）
- [ ] Antigravity 使用者：Agent 會請你到「設定（`Ctrl+,`）→ Customizations → supabase → Authenticate」，若網頁給你授權碼，**自己貼回 Antigravity 面板**（不要貼到對話框）

## Agent 會幫你做的事

1. 檢查電腦環境，缺 Node.js 就幫你安裝
2. 幫你的 Agent 加上 Supabase 連線設定，打開授權頁
3. 用 Wrangler 打開 Cloudflare 授權頁
4. 建立（或沿用）一個免費 Supabase 專案，區域東京 `ap-northeast-1`；**會花錢一定先問你**
5. 建立一張測試資料表 `connect_check`
6. 把網址與公開金鑰（publishable key）填進測試網頁
7. 把測試網頁部署到 Cloudflare（Workers 靜態網站，網址 `https://<暱稱>-hello.<你的子網域>.workers.dev`）
8. 打開網頁按「測試 Supabase」，確認「✅ 連線成功」
9. 給你一張「連接完成卡」（平台、專案代號、網址）

## 瀏覽器原則

- **註冊、登入、按同意 → 優先在 Agent 的內建瀏覽器**（Codex 桌面 App 內建瀏覽器、Antigravity 瀏覽器代理、OpenCode 桌面版 2.x 瀏覽器窗格）。它跟著 App 安裝，每個人版本相同，Agent 也看得到畫面、能一步步帶你。
- 內建瀏覽器的登入狀態和你平常的瀏覽器分開，**請先記好 GitHub 等帳號的密碼**，需要在裡面重新登入一次。
- 內建瀏覽器擋登入（例如 Google 帳號登入）或授權一直沒成功時，Agent 會改用你平常的瀏覽器。
- Agent **永遠不會**幫你輸入密碼，也不會讀取你的登入憑證。

## 隱私與安全

- 全程用瀏覽器 OAuth 授權，**不需要也不應該把任何密碼或金鑰貼給 Agent**。若 Agent 要你貼 secret key、service_role key 或密碼，請拒絕。
- 測試網頁只放 Supabase 的 **publishable key**，它本來就是設計給網頁公開使用的；資料表有 RLS 保護，訪客只能新增與讀取測試訊息，不能修改或刪除。
- 授權可以隨時撤銷：Cloudflare 請 Agent 執行 `npx wrangler logout`；各 Agent 的 MCP 登入可用 `opencode mcp logout supabase`、`codex mcp logout supabase` 或 Antigravity 設定移除；Supabase 後台也可移除已授權的應用程式（位置以官方介面為準）。
- Supabase 免費專案閒置約 7 天會自動暫停，對 Agent 說「恢復我的 Supabase 專案」即可。

## 這個包裡有什麼

| 檔案 | 用途 |
|---|---|
| `AGENTS.md` | **主程序**，三個 Agent 共讀（Codex、OpenCode、Antigravity 都會讀） |
| `CLAUDE.md`、`GEMINI.md` | 一行導向 `AGENTS.md`（給其他 Agent） |
| `CONNECT_PROMPT.md` | 要說的那一句話＋各平台備用說法 |
| `scripts/check.ps1`、`scripts/check.sh` | Agent 執行的唯讀環境檢查（不安裝、不碰秘密） |
| `opencode.json.example`、`.codex/config.toml.example`、`.agents/mcp_config.json.example` | 三平台 MCP 設定範本 |
| `.opencode/commands/connect-pack.md` | OpenCode 的 `/connect-pack` 指令 |
| `supabase/migrations/…_connect_check.sql` | 測試資料表（RLS：只能新增與讀取） |
| `hello/` | 部署到 Cloudflare 的測試網頁 |
| `docs/PLATFORMS.md` | 三平台差異對照 |
| `docs/TROUBLESHOOTING.md` | 卡住時看這裡 |

> 舊版的 `setup.ps1`／`setup.sh` 已移除，改由 Agent 執行 `scripts/check.ps1`／`check.sh`。

## 完成後下一步

拿到「✅ 連線成功」之後，到數學遊戲模板庫挑一個模板，請 Agent 幫你改成自己的課堂遊戲：

**https://github.com/mathruffian-dot/math-game-templates**

示範站：https://math-game-templates.mathruffian-teaching.workers.dev

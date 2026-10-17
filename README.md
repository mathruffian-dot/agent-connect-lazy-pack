# Agent 連接懶人包（Codex／Antigravity／OpenCode 三平台）

讓你的 AI Agent 幫你接好 **Cloudflare**（網站＋資料庫一次搞定：Workers 放網頁、D1 放資料），最後自動做出一個測試網頁，看到「✅ 連線成功」就完成。

**你不用打任何指令，也不用複製任何金鑰。** 你只負責註冊 Cloudflare、在瀏覽器按 Allow；其餘全部由 Agent 執行。三個平台的做法完全一樣。

---

## 三步驟

```
① 安裝其中一個 Agent  →  ② 用它開啟這個資料夾  →  ③ 說一句話
```

**① 安裝其中一個 Agent（選一個就好）**

| Agent | 下載 | 需要的帳號 |
|---|---|---|
| OpenAI Codex（桌面 App） | https://developers.openai.com/codex | ChatGPT 帳號（可用方案與額度以 OpenAI 公告為準） |
| Google Antigravity 2 | https://antigravity.google | Google 帳號（學校 Workspace 帳號可能被管理員限制，建議用個人帳號） |
| OpenCode（桌面版 2.x） | https://opencode.ai/download | 可先用內建免費模型，不一定要付費帳號 |

**② 取得這個資料夾並用 Agent 開啟**

- 到本 repo 頁面按綠色 **Code → Download ZIP**，解壓縮到桌面。
- 在 Agent 裡選「開啟資料夾／Open Folder」，選剛剛解壓縮的資料夾。

**③ 在對話框輸入這一句**

```text
照 AGENTS.md 幫我連接 Cloudflare
```

Agent 中途請你重開程式時，回來說：`照 AGENTS.md 繼續`。各平台備用說法見 [`CONNECT_PROMPT.md`](CONNECT_PROMPT.md)；OpenCode 也可以直接輸入 `/connect-pack`。

---

## 你只需要做的事（約 10 分鐘）

- [ ] **註冊 Cloudflare**：沒有帳號時，在 Agent 打開的網頁輸入 Email＋自訂密碼，**記得去信箱點驗證信**
- [ ] **在內建瀏覽器按 Allow**：Agent 打開 Cloudflare 授權頁時，登入後按 **Allow**（只要一次）
- [ ] Windows 跳出「是否允許此 App 變更您的裝置」時按 **是**（只在需要安裝 Node.js 時出現）
- [ ] Agent 請求執行指令或連網的權限時按 **允許**
- [ ] **不用自己想網站名稱**，Agent 會用你的 Email 自動產生（見下方「名稱怎麼來的」）

## 名稱怎麼來的（不用自己想）

Cloudflare 的 **workers.dev 子網域是全雲端搶先註冊制**，不是只有你自己帳號內唯一。如果所有老師都取 `wang`、`hello` 這種簡稱，先部署的人會佔走名字，後面的人部署時就會看到 `the name is unavailable` 而失敗。

所以這個包**不再問你暱稱**。Agent 在授權完成後，會執行 `scripts/new-nickname.*`，用你 Gmail 的名稱加上 6 位隨機數字自動產生：

| 你的 Gmail | 產生的暱稱 | 網站名稱 | 網址 |
| --- | --- | --- | --- |
| `rwsung180@gmail.com` | `rwsung180-452759` | `rwsung180-452759-hello` | `https://rwsung180-452759-hello.rwsung180-452759.workers.dev` |
| `john.doe.hr@gmail.com` | `johndoehr-305814` | `johndoehr-305814-hello` | `https://johndoehr-305814-hello.johndoehr-305814.workers.dev` |

（尾碼每次執行都不同，是隨機的。）

想自己指定名稱也可以，跟 Agent 說「我的網站名稱要用 `teacher-lin` 開頭」就好，Agent 會用 `-Seed` 參數，仍然會自動補上隨機數字避免撞名。

## Agent 會幫你做的事

1. 檢查電腦環境，缺 Node.js 就幫你安裝
2. 打開 Cloudflare 註冊頁（沒帳號時）與授權頁
3. 用你的 Email 自動產生唯一暱稱（`<gmail 名稱>-<隨機數字>`）
4. 建立一個 D1 資料庫 `<暱稱>-hello-db`
5. 建立一張測試資料表 `connect_check`
6. 把測試網站部署到 Cloudflare（網址 `https://<暱稱>-hello.<暱稱>.workers.dev`）
7. 打開網頁按「測試資料庫」，確認「✅ 連線成功」
8. 給你一張「連接完成卡」（平台、網址、資料庫名稱）

## 瀏覽器原則

- **註冊、授權、驗收 → 優先在 Agent 的內建瀏覽器**（Codex 桌面 App 內建瀏覽器、Antigravity 瀏覽器代理、OpenCode 桌面版 2.x 瀏覽器窗格）。每個人版本相同，Agent 也看得到畫面、能一步步帶你。
- 內建瀏覽器的登入狀態和你平常的瀏覽器分開，**請先記好 Cloudflare 密碼**，需要在裡面登入一次。
- 內建瀏覽器擋登入或授權一直沒成功時，Agent 會改用你平常的瀏覽器。
- Agent **永遠不會**幫你輸入密碼，也不會讀取你的登入憑證。

## 隱私與安全

- 全程用瀏覽器授權，**不需要也不應該把任何密碼、金鑰或 Token 貼給 Agent**。若 Agent 要你貼，請拒絕。
- 測試網頁沒有任何金鑰：網頁透過自己的 Worker 存取資料庫，訪客只能新增一筆測試訊息並看到總筆數。
- 免費方案每天有用量上限（UTC 0 點、台灣早上 8 點重置），研習測試完全用不完。
- 授權可以隨時撤銷：請 Agent 執行 `npx wrangler logout`；Cloudflare 後台也可移除已授權的應用程式（位置以官方介面為準）。

## 這個包裡有什麼

| 檔案 | 用途 |
|---|---|
| `AGENTS.md` | **主程序**，三個 Agent 共讀 |
| `CLAUDE.md`、`GEMINI.md` | 一行導向 `AGENTS.md`（給其他 Agent） |
| `CONNECT_PROMPT.md` | 要說的那一句話＋各平台備用說法 |
| `scripts/check.ps1`、`scripts/check.sh` | Agent 執行的唯讀環境檢查（不安裝、不碰秘密） |
| `scripts/new-nickname.ps1`、`scripts/new-nickname.sh` | 從帳號 Email 產生唯一暱稱（`名稱-隨機數字`），並可檢查名稱合法性 |
| `.opencode/commands/connect-pack.md` | OpenCode 的 `/connect-pack` 指令 |
| `hello/wrangler.jsonc` | 網站設定（Agent 會改名並自動加入 D1 資料庫） |
| `hello/worker.js` | 後端：`/api/check` 寫入並讀回 D1 |
| `hello/migrations/0001_connect_check.sql` | 測試資料表 |
| `hello/public/index.html` | 測試網頁 |
| `docs/PLATFORMS.md` | 三平台差異對照 |
| `docs/TROUBLESHOOTING.md` | 卡住時看這裡 |

> 舊版「Supabase（資料庫）＋Cloudflare（網站）」保存在 git 分支 [`supabase`](../../tree/supabase)。

## 完成後下一步

拿到「✅ 連線成功」之後，到數學遊戲模板庫挑一個模板，請 Agent 幫你改成自己的課堂遊戲：

**https://github.com/mathruffian-dot/math-game-templates**

示範站：https://math-game-templates.mathruffian-teaching.workers.dev

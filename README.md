# opencode-connect-lazy-pack

OpenCode 一鍵連接懶人包：拿到即連 **Supabase + Cloudflare**，沒帳號會引導你註冊，全程只按 2～3 次瀏覽器同意。

## 原理 30 秒

ChatGPT 是「鑰匙放它家」，OpenCode 是「鑰匙放你家」，只有三種東西：

1. `/connect`＝ 幫**模型**買電（Zen / OpenAI / Anthropic），存 `auth.json`
2. `opencode mcp auth` ＝ 幫 **Agent 工具**請翻譯官（Supabase / Cloudflare），瀏覽器按同意，印章存本機 `mcp-auth.json`
3. `xxx login` ＝ 遙控器先配對（Firebase / Wrangler / gh），在外面登入一次，之後 Agent 直接用

最後按同意的人一定是你，Agent 碰不到你的密碼，也繞不過 MFA。

## 快速開始（3 步）

```powershell
# 1. 拿懶人包
git clone https://github.com/mathruffian-dot/opencode-connect-lazy-pack.git
cd opencode-connect-lazy-pack

# 2. 裝東西（Windows / macOS 通用檢查）
./setup.ps1   # Windows
# bash setup.sh  # macOS / Linux

# 3. 開 OpenCode Build mode，貼上 CONNECT_PROMPT.md 全文
opencode
```

然後瀏覽器各按一次同意，跑完看到兩個 `authenticated` 就結束：

```powershell
opencode mcp auth list
# supabase    authenticated
# cloudflare  authenticated
```

## 沒帳號？先註冊（免費）

| 服務 | 註冊網址 | 說明 |
|---|---|---|
| Supabase | https://supabase.com/dashboard/sign-up | 用 GitHub 帳號一鍵註冊即可 |
| Cloudflare | https://dash.cloudflare.com/sign-up | 用 Email 註冊即可 |

照著網頁走完再回來跑第 3 步。懶人包的提示詞也會自動偵測、沒連上就給你網址帶你去註冊。

## 這個包裡有什麼

| 檔案 | 用途 |
|---|---|
| `CONNECT_PROMPT.md` | 通用提示詞，貼給 OpenCode 就自動連 Supabase + Cloudflare |
| `.opencode/command/connect-pack.md` | 同上，做成 `/connect-pack` 指令，repo 裡直接打就能用 |
| `opencode.json.example` | 缺 config 時的範本，用 remote MCP + OAuth，不貼任何 Key |
| `setup.ps1` / `setup.sh` | 裝 opencode、檢查 CLI、觸發瀏覽器授權 |

## 通用提示詞（背起來）

```text
用 opencode mcp auth 幫我連接 supabase，連不上就幫我加 remote MCP 再重連
```

```text
用 opencode mcp auth 幫我連接 cloudflare，連不上就幫我加 https://mcp.cloudflare.com/mcp 再重連
```

Firebase 沒有 MCP OAuth，要說：`幫我用 firebase login 連 Firebase，之後用 CLI 幫我部署`。
Gmail / 行事曆要先開 Google Cloud OAuth 門，見 `docs/`（即將補上，歡迎發 PR）。

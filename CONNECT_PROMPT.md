# CONNECT_PROMPT — 對 Agent 說這一句就好

先用你的 Agent（Codex／Antigravity／OpenCode）**開啟這個資料夾**，再在對話框輸入：

```text
照 AGENTS.md 幫我連接 Supabase 和 Cloudflare
```

Agent 會自己跑所有指令；你只需要註冊、登入、在瀏覽器按同意。

## 中途重開後

Agent 請你重開程式（或開新對話）時，回來說：

```text
照 AGENTS.md 繼續
```

已完成的步驟會自動跳過。

## 如果 Agent 沒反應過來（各平台備用說法）

**Codex（ChatGPT 桌面 App／Codex CLI）**

```text
請讀這個資料夾的 AGENTS.md，你是 codex 平台。從第 0 步開始照做：用 codex mcp add 加入 Supabase MCP、codex mcp login 觸發瀏覽器授權，用 npx wrangler login 連 Cloudflare，所有指令都由你執行。
```

**Google Antigravity 2**

```text
請讀這個資料夾的 AGENTS.md，你是 antigravity 平台。從第 0 步開始照做：在 mcp_config.json 用 serverUrl 加入 Supabase MCP，引導我到 Customizations 按 Authenticate，用 npx wrangler login 連 Cloudflare，所有指令都由你執行。
```

**OpenCode**

```text
/connect-pack
```

（或說：「請讀 AGENTS.md，你是 opencode 平台，從第 0 步開始照做，用 opencode mcp auth supabase 觸發授權。」）

## 規則（Agent 已內建，給你安心用）

- 不會叫你貼任何密碼或金鑰，全部用瀏覽器 OAuth 登入。
- 登入一律在你平常用的瀏覽器，不在 Agent 的內建瀏覽器。
- 會花錢、會刪東西的動作一定先問你。

# CONNECT_PROMPT — 對 Agent 說這一句就好

先用你的 Agent（Codex／Antigravity／OpenCode）**開啟這個資料夾**，再在對話框輸入：

```text
照 AGENTS.md 幫我連接 Cloudflare
```

Agent 會自己跑所有指令；你只需要註冊 Cloudflare、在瀏覽器按 Allow。

## 中途重開後

Agent 請你重開程式（或開新對話）時，回來說：

```text
照 AGENTS.md 繼續
```

已完成的步驟會自動跳過。

## 如果 Agent 沒反應過來（備用說法，三平台通用）

```text
請讀這個資料夾的 AGENTS.md，從第 0 步開始照做：用 npx wrangler login 連 Cloudflare（授權網址開在你的內建瀏覽器），在 hello 資料夾建立 D1 資料庫、套用 migrations、部署並驗收。所有指令都由你執行。
```

- **Codex 桌面 App**：可再補一句「用你的內建瀏覽器（Ctrl+Shift+B）開網址」。
- **Antigravity 2**：可再補一句「用 browser agent 開網址」。
- **OpenCode 桌面版 2.x**：直接輸入 `/connect-pack`。

## 規則（Agent 已內建，給你安心用）

- 不會叫你貼任何密碼、金鑰或 Token，只在瀏覽器按 Allow。
- 註冊、授權優先在 Agent 的內建瀏覽器；卡住才改用你平常的瀏覽器。
- 會花錢、會刪東西的動作一定先問你。

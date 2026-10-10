# CONNECT_PROMPT — 直接全選貼到 OpenCode（Build mode）

幫我把這台電腦的 Supabase + Cloudflare 一次接完：

1. 先跑 `opencode mcp list` 和 `opencode mcp auth list`，告訴我現在誰連上了、誰沒有。
2. 缺的幫我在 `opencode.json` 補上（只加缺的，不要刪我原有的）：
   - supabase：type remote，url https://mcp.supabase.com/mcp
   - cloudflare：type remote，url https://mcp.cloudflare.com/mcp
3. 跑 `opencode mcp auth supabase` 和 `opencode mcp auth cloudflare`，瀏覽器跳出來我會按同意。
4. 如果我根本沒帳號：
   - Supabase 沒登入 → 給我 https://supabase.com/dashboard/sign-up，帶我用 GitHub 帳號註冊完再重連
   - Cloudflare 沒登入 → 給我 https://dash.cloudflare.com/sign-up，帶我用 Email 註冊完再重連
5. 做完用 `opencode mcp auth list` 證明 supabase 和 cloudflare 都是 authenticated。

規則：不要叫我貼任何 API Key，全部用瀏覽器 OAuth。缺 CLI（wrangler / firebase / gh / supabase）就提醒我，不要自作主张亂裝。

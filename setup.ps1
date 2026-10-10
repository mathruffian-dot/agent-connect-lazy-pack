#Requires -Version 5.1
# opencode-connect-lazy-pack - Windows one-click check (read-only, no secrets touched)
$ErrorActionPreference = "Continue"

function Has-Cmd($name) { $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

Write-Host "=== 1. OpenCode ==="
if (Has-Cmd "opencode") { opencode --version } else { Write-Host "opencode not found, install: npm i -g opencode-ai" }

Write-Host ""
Write-Host "=== 2. MCP status ==="
if (Has-Cmd "opencode") {
  opencode mcp list
  opencode mcp auth list
} else {
  Write-Host "Install opencode first, then re-run this script"
}

Write-Host ""
Write-Host "=== 3. Common CLIs ==="
foreach ($c in @("wrangler", "firebase", "gh", "supabase", "gcloud")) {
  if (Has-Cmd $c) { Write-Host "$c installed" }
  else { Write-Host "$c missing (only if needed: npm i -g firebase-tools wrangler)" }
}

Write-Host ""
Write-Host "=== 4. No account yet? Sign up free ==="
Write-Host "Supabase:   https://supabase.com/dashboard/sign-up"
Write-Host "Cloudflare: https://dash.cloudflare.com/sign-up"
Write-Host ""
Write-Host "Next: open opencode (Build mode), paste CONNECT_PROMPT.md, approve in browser."

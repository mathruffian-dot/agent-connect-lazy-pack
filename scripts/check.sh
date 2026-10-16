#!/usr/bin/env bash
# agent-connect-lazy-pack : read-only environment check (macOS / Linux / Git Bash)
# Run by the Agent (not the user):  bash scripts/check.sh
# - Installs nothing, changes nothing.
# - Never prints tokens, keys or config file contents (only true/false).
# - Output: one JSON object on stdout.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIMEOUT_SEC="${TIMEOUT_SEC:-30}"
export NO_COLOR=1 FORCE_COLOR=0 WRANGLER_SEND_METRICS=false

has() { command -v "$1" >/dev/null 2>&1; }
b() { if "$@"; then echo true; else echo false; fi; }

# JSON string escape (quotes included)
js() {
  local s="${1-}"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"; s="${s//$'\r'/}"; s="${s//$'\n'/\\n}"
  printf '"%s"' "$s"
}
jsn() { if [ -n "${1-}" ]; then js "$1"; else printf 'null'; fi; }

# Run with timeout when available; strip ANSI; limit length
run() {
  local out
  if has timeout; then out="$(cd "$REPO_ROOT" && timeout "$TIMEOUT_SEC" "$@" </dev/null 2>&1)"
  elif has gtimeout; then out="$(cd "$REPO_ROOT" && gtimeout "$TIMEOUT_SEC" "$@" </dev/null 2>&1)"
  else out="$(cd "$REPO_ROOT" && "$@" </dev/null 2>&1)"; fi
  printf '%s' "$out" | sed $'s/\x1b\\[[0-9;?]*[A-Za-z]//g' | head -c "${RUN_LIMIT:-1500}"
}

ver() { if has "$1"; then run "$@" | head -n 1; fi; }

# file_check <path> <needle> -> {"path":..,"exists":..,"hasSupabase":..}
file_check() {
  local p="$1" n="$2" e=false h=false
  if [ -f "$p" ]; then e=true; if grep -qF -- "$n" "$p" 2>/dev/null; then h=true; fi; fi
  printf '{"path":%s,"exists":%s,"hasSupabase":%s}' "$(js "$p")" "$e" "$h"
}
first_existing() { for p in "$@"; do [ -f "$p" ] && { echo "$p"; return; }; done; echo "$1"; }

OS="$(uname -s 2>/dev/null || echo unknown)"
NODE_V="$(ver node -v)"; NPM_V="$(ver npm -v)"; NPX_V="$(ver npx -v)"; GIT_V="$(ver git --version)"

# Wrangler (no download)
WR_STATUS=unknown; WR_NOTE=""
if has npx; then
  WR_OUT="$(run npx --no-install wrangler whoami)"
  if printf '%s' "$WR_OUT" | grep -qi 'logged in with'; then WR_STATUS=logged_in
  elif printf '%s' "$WR_OUT" | grep -qiE 'not authenticated|not logged in'; then WR_STATUS=not_logged_in
  else WR_NOTE="wrangler not cached locally; Agent will run: npx -y wrangler login"; fi
else WR_NOTE="npx missing (install Node.js LTS first)"; fi

# OpenCode
OC_G="$(first_existing "$HOME/.config/opencode/opencode.json" "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/config.json")"
OC_P="$(first_existing "$REPO_ROOT/opencode.json" "$REPO_ROOT/opencode.jsonc")"
OC_LINE=""
if has opencode; then OC_LINE="$(run opencode mcp list | grep -iw supabase | head -n 1 | sed 's/^[^A-Za-z0-9]*//')"; fi
OC_CFG=false
{ grep -qF mcp.supabase.com "$OC_G" 2>/dev/null || grep -qF mcp.supabase.com "$OC_P" 2>/dev/null || [ -n "$OC_LINE" ]; } && OC_CFG=true

# Codex (config shared by app / CLI / IDE)
CX_G="$HOME/.codex/config.toml"; CX_P="$REPO_ROOT/.codex/config.toml"
CX_NAMES=""
if has codex; then
  CX_NAMES="$(RUN_LIMIT=10000000 run codex mcp list --json | grep -oE '"name": *"[^"]+"' | sed -E 's/.*"([^"]+)"$/\1/' | tr '\n' ',' | sed 's/,$//')"
fi
CX_CFG=false
{ grep -qF '[mcp_servers.supabase]' "$CX_G" 2>/dev/null || grep -qF '[mcp_servers.supabase]' "$CX_P" 2>/dev/null || printf ',%s,' "$CX_NAMES" | grep -q ',supabase,'; } && CX_CFG=true

# Antigravity
AG_G="$HOME/.gemini/config/mcp_config.json"; AG_L="$HOME/.gemini/antigravity/mcp_config.json"; AG_W="$REPO_ROOT/.agents/mcp_config.json"
AG_CFG=false
{ grep -qF supabase "$AG_G" 2>/dev/null || grep -qF supabase "$AG_L" 2>/dev/null || grep -qF supabase "$AG_W" 2>/dev/null; } && AG_CFG=true
AG_CLI=""; has agy && AG_CLI="$(command -v agy)"; [ -z "$AG_CLI" ] && has antigravity && AG_CLI="$(command -v antigravity)"

# hello/config.js (key value never printed)
CFG="$REPO_ROOT/hello/config.js"; URL_FILLED=false; KEY_KIND=empty
if [ -f "$CFG" ]; then
  grep -qE 'supabaseUrl[[:space:]]*:[[:space:]]*"https://[^"]+"' "$CFG" && URL_FILLED=true
  KEY="$(sed -nE 's/.*supabaseKey[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$CFG" | head -n 1)"
  case "$KEY" in
    "") KEY_KIND=empty ;;
    sb_publishable_*) KEY_KIND=publishable ;;
    sb_secret_*) KEY_KIND=SECRET_DANGER ;;
    eyJ*) KEY_KIND=legacy_jwt ;;
    *) KEY_KIND=other ;;
  esac
  unset KEY
fi
CONFIG_FILLED=false
if [ "$URL_FILLED" = true ] && { [ "$KEY_KIND" = publishable ] || [ "$KEY_KIND" = legacy_jwt ]; }; then CONFIG_FILLED=true; fi

HINTS=()
[ -z "$NODE_V" ] && HINTS+=("Node.js missing: macOS 'brew install node' or open https://nodejs.org/ for the user.")
[ "$WR_STATUS" != logged_in ] && HINTS+=("Cloudflare: run npx -y wrangler login (AGENTS.md step 3).")
HINTS+=("Supabase MCP configured: opencode=$OC_CFG, codex=$CX_CFG, antigravity=$AG_CFG. Only the platform you are running on matters (AGENTS.md step 2).")
if [ "$KEY_KIND" = SECRET_DANGER ]; then HINTS+=("DANGER: hello/config.js contains a secret key. Replace with publishable key immediately.")
elif [ "$CONFIG_FILLED" != true ]; then HINTS+=("hello/config.js not filled yet (AGENTS.md step 6)."); fi

HINTS_JSON=""
for h in "${HINTS[@]}"; do HINTS_JSON="${HINTS_JSON:+$HINTS_JSON,}$(js "$h")"; done

cat <<JSON
{
  "tool": "agent-connect-lazy-pack/check.sh",
  "os": $(js "$OS"),
  "repoRoot": $(js "$REPO_ROOT"),
  "node": {"ok": $(b test -n "$NODE_V"), "version": $(jsn "$NODE_V")},
  "npm": {"ok": $(b test -n "$NPM_V"), "version": $(jsn "$NPM_V")},
  "npx": {"ok": $(b test -n "$NPX_V"), "version": $(jsn "$NPX_V")},
  "git": {"ok": $(b test -n "$GIT_V"), "version": $(jsn "$GIT_V")},
  "brew": {"ok": $(b has brew)},
  "platforms": {
    "codex": {"cli": $(b has codex)},
    "opencode": {"cli": $(b has opencode)},
    "antigravity": {"cli": $(b test -n "$AG_CLI"), "path": $(jsn "$AG_CLI")}
  },
  "wrangler": {"status": $(js "$WR_STATUS"), "note": $(js "$WR_NOTE")},
  "mcp": {
    "opencode": {"globalConfig": $(file_check "$OC_G" mcp.supabase.com), "projectConfig": $(file_check "$OC_P" mcp.supabase.com), "supabaseLine": $(jsn "$OC_LINE"), "supabaseConfigured": $OC_CFG},
    "codex": {"globalConfig": $(file_check "$CX_G" '[mcp_servers.supabase]'), "projectConfig": $(file_check "$CX_P" '[mcp_servers.supabase]'), "serverNames": $(jsn "$CX_NAMES"), "supabaseConfigured": $CX_CFG},
    "antigravity": {"globalConfig": $(file_check "$AG_G" supabase), "globalConfigLegacy": $(file_check "$AG_L" supabase), "workspaceConfig": $(file_check "$AG_W" supabase), "supabaseConfigured": $AG_CFG, "note": "OAuth state is only visible in Antigravity: Settings > Customizations"}
  },
  "hello": {"indexHtml": $(b test -f "$REPO_ROOT/hello/index.html"), "configFilled": $CONFIG_FILLED, "urlFilled": $URL_FILLED, "keyKind": $(js "$KEY_KIND")},
  "migration": $(b test -f "$REPO_ROOT/supabase/migrations/20261017000000_connect_check.sql"),
  "hints": [$HINTS_JSON]
}
JSON

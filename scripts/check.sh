#!/usr/bin/env bash
# agent-connect-lazy-pack : read-only environment check (macOS / Linux / Git Bash)
# Run by the Agent (not the user):  bash scripts/check.sh
# - Installs nothing, changes nothing.
# - Never prints tokens, keys or config file contents (only true/false and names).
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

OS="$(uname -s 2>/dev/null || echo unknown)"
NODE_V="$(ver node -v)"; NPM_V="$(ver npm -v)"; NPX_V="$(ver npx -v)"; GIT_V="$(ver git --version)"

# Agent platform CLIs (desktop apps may not add a CLI to PATH)
AG_CLI=""; has agy && AG_CLI="$(command -v agy)"; [ -z "$AG_CLI" ] && has antigravity && AG_CLI="$(command -v antigravity)"

# Wrangler login state (no download: --no-install)
WR_STATUS=unknown; WR_NOTE=""
if has npx; then
  WR_OUT="$(run npx --no-install wrangler whoami)"
  if printf '%s' "$WR_OUT" | grep -qi 'logged in with'; then WR_STATUS=logged_in
  elif printf '%s' "$WR_OUT" | grep -qiE 'not authenticated|not logged in'; then WR_STATUS=not_logged_in
  else WR_NOTE="wrangler not cached locally; Agent will run: npx -y wrangler login"; fi
else WR_NOTE="npx missing (install Node.js LTS first)"; fi

# hello/ project state (database_id is never printed)
WJ="$REPO_ROOT/hello/wrangler.jsonc"
WJ_EXISTS=false; NAME=""; NAME_CHANGED=false; HAS_D1=false; D1_NAME=""
if [ -f "$WJ" ]; then
  WJ_EXISTS=true
  NAME="$(sed -nE 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$WJ" | head -n 1)"
  if [ -n "$NAME" ] && [ "$NAME" != "CHANGE-ME-hello" ]; then NAME_CHANGED=true; fi
  if grep -qF '"d1_databases"' "$WJ"; then
    HAS_D1=true
    D1_NAME="$(sed -nE 's/.*"database_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' "$WJ" | head -n 1)"
  fi
fi

HINTS=()
[ -z "$NODE_V" ] && HINTS+=("Node.js missing: macOS 'brew install node' or open https://nodejs.org/ for the user.")
[ "$WR_STATUS" != logged_in ] && HINTS+=("Cloudflare: AGENTS.md steps 2-3 (npx -y wrangler login --browser=false, open URL in built-in browser).")
if [ "$NAME_CHANGED" != true ]; then
  HINTS+=("Nickname not chosen yet: if hello/wrangler.jsonc name is still CHANGE-ME-hello, generate it once with scripts/new-nickname.sh (AGENTS.md step 3.5), then set name to <nickname>-hello (step 4). If name is already set, reuse that nickname and do NOT rerun new-nickname.")
else
  NICKNAME="${NAME%-hello}"
  HINTS+=("Nickname already chosen: '$NICKNAME'. Reuse it for every later step; never rerun new-nickname (it would generate different digits).")
fi
if [ "$HAS_D1" != true ]; then HINTS+=("No d1_databases yet: in hello/ run npx -y wrangler d1 create <nickname>-hello-db --binding DB --update-config (AGENTS.md step 4).")
else HINTS+=("D1 configured; next: migrations apply --remote (step 5), deploy (step 6), verify (step 7)."); fi

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
  "hello": {
    "wranglerJsonc": $WJ_EXISTS, "name": $(jsn "$NAME"), "nameChanged": $NAME_CHANGED,
    "hasD1": $HAS_D1, "d1DatabaseName": $(jsn "$D1_NAME"),
    "workerJs": $(b test -f "$REPO_ROOT/hello/worker.js"),
    "indexHtml": $(b test -f "$REPO_ROOT/hello/public/index.html"),
    "migration": $(b test -f "$REPO_ROOT/hello/migrations/0001_connect_check.sql")
  },
  "hints": [$HINTS_JSON]
}
JSON

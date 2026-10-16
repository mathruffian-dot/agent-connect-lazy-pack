#Requires -Version 5.1
<#
  agent-connect-lazy-pack : read-only environment check (Windows)
  Run by the Agent (not the user):
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
  - Installs nothing, changes nothing.
  - Never prints tokens, keys or config file contents (only "configured: true/false").
  - Output: one JSON object on stdout.
#>
param([int]$TimeoutSec = 30)

$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$UserHome = $env:USERPROFILE
if (-not $UserHome) { $UserHome = $HOME }

function Get-CmdPath([string]$Name) {
  $c = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source } else { return $null }
}

function Clean-Text([string]$Text, [int]$Max = 1500) {
  if (-not $Text) { return '' }
  $t = $Text -replace "\x1b\[[0-9;?]*[A-Za-z]", ''
  $t = $t.Trim()
  if ($t.Length -gt $Max) { $t = $t.Substring(0, $Max) + ' ...(truncated)' }
  return $t
}

# Run a command line through cmd.exe with a timeout; kills the whole process tree on timeout.
function Invoke-Capture([string]$CommandLine, [int]$Seconds = $TimeoutSec, [switch]$StdoutOnly) {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $env:ComSpec
  $psi.Arguments = '/d /s /c "' + $CommandLine + '"'
  $psi.WorkingDirectory = $RepoRoot
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.RedirectStandardInput = $true
  $psi.EnvironmentVariables['NO_COLOR'] = '1'
  $psi.EnvironmentVariables['FORCE_COLOR'] = '0'
  $psi.EnvironmentVariables['WRANGLER_SEND_METRICS'] = 'false'
  $p = $null
  try {
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($Seconds * 1000)) {
      & taskkill.exe /T /F /PID $p.Id 2>$null | Out-Null
      return [ordered]@{ ran = $true; timedOut = $true; exitCode = $null; output = '' }
    }
    $p.WaitForExit()
    if ($StdoutOnly) { return [ordered]@{ ran = $true; timedOut = $false; exitCode = $p.ExitCode; output = $outTask.Result } }
    $text = $outTask.Result + "`n" + $errTask.Result
    return [ordered]@{ ran = $true; timedOut = $false; exitCode = $p.ExitCode; output = (Clean-Text $text) }
  } catch {
    return [ordered]@{ ran = $false; timedOut = $false; exitCode = $null; output = (Clean-Text $_.Exception.Message) }
  }
}

function Get-Version([string]$Name, [string]$VerArgs = '--version') {
  $path = Get-CmdPath $Name
  if (-not $path) { return [ordered]@{ ok = $false; version = $null; path = $null } }
  $r = Invoke-Capture "$Name $VerArgs" 20
  $first = ($r.output -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
  return [ordered]@{ ok = ($r.exitCode -eq 0); version = $first; path = $path }
}

# Check a config file without printing its content.
function Test-ConfigFile([string]$Path, [string]$Needle, [switch]$Json) {
  $info = [ordered]@{ path = $Path; exists = $false; hasSupabase = $false; validJson = $null }
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $info }
  $info.exists = $true
  $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($raw -and $raw.Contains($Needle)) { $info.hasSupabase = $true }
  if ($Json) {
    try { $null = $raw | ConvertFrom-Json -ErrorAction Stop; $info.validJson = $true } catch { $info.validJson = $false }
  }
  return $info
}

$result = [ordered]@{}
$result.tool = 'agent-connect-lazy-pack/check.ps1'
$result.time = (Get-Date).ToString('s')
$result.os = 'windows'
$result.powershell = $PSVersionTable.PSVersion.ToString()
$result.repoRoot = $RepoRoot

# 1. Basic tools
$result.node = Get-Version 'node' '-v'
$result.npm = Get-Version 'npm' '-v'
$result.npx = Get-Version 'npx' '-v'
$result.git = Get-Version 'git' '--version'
$result.winget = [ordered]@{ ok = [bool](Get-CmdPath 'winget') }

# 2. Agent platforms (CLI on PATH; desktop apps may not add a CLI)
$agyPath = @((Get-CmdPath 'agy'), (Get-CmdPath 'antigravity')) | Where-Object { $_ } | Select-Object -First 1
$result.platforms = [ordered]@{
  codex       = [ordered]@{ cli = [bool](Get-CmdPath 'codex');    path = (Get-CmdPath 'codex') }
  opencode    = [ordered]@{ cli = [bool](Get-CmdPath 'opencode'); path = (Get-CmdPath 'opencode') }
  antigravity = [ordered]@{ cli = [bool]$agyPath;                 path = $(if ($agyPath) { $agyPath } else { $null }) }
}

# 3. Wrangler login state (no download: --no-install)
$wr = [ordered]@{ status = 'unknown'; note = '' }
if ($result.npx.ok) {
  $r = Invoke-Capture 'npx --no-install wrangler whoami' $TimeoutSec
  if ($r.timedOut) { $wr.status = 'unknown'; $wr.note = 'timed out' }
  elseif ($r.output -match '(?i)logged in with') { $wr.status = 'logged_in' }
  elseif ($r.output -match '(?i)not authenticated|not logged in') { $wr.status = 'not_logged_in' }
  else { $wr.status = 'unknown'; $wr.note = 'wrangler not cached locally; Agent will run: npx -y wrangler login' }
} else { $wr.note = 'npx missing (install Node.js LTS first)' }
$result.wrangler = $wr

# 4. MCP configuration per platform (contents never printed)
function First-Existing([string[]]$Paths) {
  foreach ($p in $Paths) { if (Test-Path -LiteralPath $p -PathType Leaf) { return $p } }
  return $Paths[0]
}
$mcp = [ordered]@{}

# OpenCode: opencode.json or opencode.jsonc (jsonc is not checked for JSON validity)
$ocGlobal  = First-Existing @((Join-Path $UserHome '.config\opencode\opencode.json'), (Join-Path $UserHome '.config\opencode\opencode.jsonc'), (Join-Path $UserHome '.config\opencode\config.json'))
$ocProject = First-Existing @((Join-Path $RepoRoot 'opencode.json'), (Join-Path $RepoRoot 'opencode.jsonc'))
$oc = [ordered]@{
  globalConfig  = $(if ($ocGlobal -like '*.jsonc') { Test-ConfigFile $ocGlobal 'mcp.supabase.com' } else { Test-ConfigFile $ocGlobal 'mcp.supabase.com' -Json })
  projectConfig = $(if ($ocProject -like '*.jsonc') { Test-ConfigFile $ocProject 'mcp.supabase.com' } else { Test-ConfigFile $ocProject 'mcp.supabase.com' -Json })
  supabaseLine = $null
  mcpList = $null
}
if ($result.platforms.opencode.cli) {
  $oc.mcpList = Invoke-Capture 'opencode mcp list' $TimeoutSec
  $line = ($oc.mcpList.output -split "`n" | Where-Object { $_ -match '(?i)\bsupabase\b' } | Select-Object -First 1)
  if ($line) { $oc.supabaseLine = ($line -replace '^[^A-Za-z0-9]+', '').Trim() }
}
$oc.supabaseConfigured = [bool]($oc.globalConfig.hasSupabase -or $oc.projectConfig.hasSupabase -or $oc.supabaseLine)
$mcp.opencode = $oc

# Codex: config.toml (App, CLI and IDE share it); server list via --json (env values never printed)
$cx = [ordered]@{
  globalConfig  = Test-ConfigFile (Join-Path $UserHome '.codex\config.toml') '[mcp_servers.supabase]'
  projectConfig = Test-ConfigFile (Join-Path $RepoRoot '.codex\config.toml') '[mcp_servers.supabase]'
  servers = $null
}
if ($result.platforms.codex.cli) {
  $r = Invoke-Capture 'codex mcp list --json' $TimeoutSec -StdoutOnly
  try {
    $list = $r.output | ConvertFrom-Json -ErrorAction Stop
    $cx.servers = @($list | ForEach-Object {
      [ordered]@{ name = $_.name; enabled = $_.enabled; transport = $_.transport.type; url = $_.transport.url; auth = $_.auth_status }
    })
  } catch { $cx.servers = 'unparsed: ' + (Clean-Text $r.output 300) }
}
$cx.supabaseConfigured = [bool]($cx.globalConfig.hasSupabase -or $cx.projectConfig.hasSupabase -or (@($cx.servers) | Where-Object { $_.name -eq 'supabase' }))
$mcp.codex = $cx

# Antigravity: global path per Antigravity docs, legacy path per Supabase docs, workspace file
$ag = [ordered]@{
  globalConfig       = Test-ConfigFile (Join-Path $UserHome '.gemini\config\mcp_config.json') 'supabase' -Json
  globalConfigLegacy = Test-ConfigFile (Join-Path $UserHome '.gemini\antigravity\mcp_config.json') 'supabase' -Json
  workspaceConfig    = Test-ConfigFile (Join-Path $RepoRoot '.agents\mcp_config.json') 'supabase' -Json
  note = 'OAuth state is only visible in Antigravity: Settings > Customizations'
}
$ag.supabaseConfigured = [bool]($ag.globalConfig.hasSupabase -or $ag.globalConfigLegacy.hasSupabase -or $ag.workspaceConfig.hasSupabase)
$mcp.antigravity = $ag
$result.mcp = $mcp

# 5. Repo files (key value never printed, only its kind)
$hello = [ordered]@{ indexHtml = (Test-Path (Join-Path $RepoRoot 'hello\index.html')); configFilled = $false; urlFilled = $false; keyKind = 'empty' }
$cfgPath = Join-Path $RepoRoot 'hello\config.js'
if (Test-Path $cfgPath) {
  $cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8
  if ($cfg -match 'supabaseUrl\s*:\s*"(https://[^"]+)"') { $hello.urlFilled = $true }
  if ($cfg -match 'supabaseKey\s*:\s*"([^"]+)"') {
    $k = $Matches[1]
    if ($k -like 'sb_publishable_*') { $hello.keyKind = 'publishable' }
    elseif ($k -like 'sb_secret_*') { $hello.keyKind = 'SECRET_DANGER' }
    elseif ($k -like 'eyJ*') { $hello.keyKind = 'legacy_jwt' }
    else { $hello.keyKind = 'other' }
  }
  $hello.configFilled = ($hello.urlFilled -and ($hello.keyKind -in @('publishable', 'legacy_jwt')))
}
$result.hello = $hello
$result.migration = (Test-Path (Join-Path $RepoRoot 'supabase\migrations\20261017000000_connect_check.sql'))

# 6. Hints for the Agent
$hints = @()
if (-not $result.node.ok) { $hints += 'Node.js missing: winget install -e --id OpenJS.NodeJS.LTS (user approves UAC), then refresh PATH.' }
if ($wr.status -ne 'logged_in') { $hints += 'Cloudflare: run npx -y wrangler login (AGENTS.md step 3).' }
$hints += ("Supabase MCP configured: opencode=" + $oc.supabaseConfigured + ", codex=" + $cx.supabaseConfigured + ", antigravity=" + $ag.supabaseConfigured + ". Only the platform you are running on matters (AGENTS.md step 2).")
if ($hello.keyKind -eq 'SECRET_DANGER') { $hints += 'DANGER: hello/config.js contains a secret key. Replace with publishable key immediately.' }
elseif (-not $hello.configFilled) { $hints += 'hello/config.js not filled yet (AGENTS.md step 6).' }
$result.hints = $hints

$result | ConvertTo-Json -Depth 6

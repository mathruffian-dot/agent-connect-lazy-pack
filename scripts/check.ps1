#Requires -Version 5.1
<#
  agent-connect-lazy-pack : read-only environment check (Windows)
  Run by the Agent (not the user):
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check.ps1
  - Installs nothing, changes nothing.
  - Never prints tokens, keys or config file contents (only true/false and names).
  - Output: one JSON object on stdout.
#>
param([int]$TimeoutSec = 30)

$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$RepoRoot = Split-Path -Parent $PSScriptRoot

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

# 4. hello/ project state (no secrets involved; database_id is not printed)
$hello = [ordered]@{
  wranglerJsonc = $false; name = $null; nameChanged = $false; hasD1 = $false; d1DatabaseName = $null
  workerJs = (Test-Path -LiteralPath (Join-Path $RepoRoot 'hello\worker.js'))
  indexHtml = (Test-Path -LiteralPath (Join-Path $RepoRoot 'hello\public\index.html'))
  migration = (Test-Path -LiteralPath (Join-Path $RepoRoot 'hello\migrations\0001_connect_check.sql'))
}
$wjPath = Join-Path $RepoRoot 'hello\wrangler.jsonc'
if (Test-Path -LiteralPath $wjPath -PathType Leaf) {
  $hello.wranglerJsonc = $true
  $wj = Get-Content -LiteralPath $wjPath -Raw -Encoding UTF8
  if ($wj -match '"name"\s*:\s*"([^"]*)"') { $hello.name = $Matches[1] }
  $hello.nameChanged = [bool]($hello.name -and $hello.name -ne 'CHANGE-ME-hello')
  if ($wj -match '"d1_databases"') {
    $hello.hasD1 = $true
    if ($wj -match '"database_name"\s*:\s*"([^"]*)"') { $hello.d1DatabaseName = $Matches[1] }
  }
}
$result.hello = $hello

# 5. Hints for the Agent
$hints = @()
if (-not $result.node.ok) { $hints += 'Node.js missing: winget install -e --id OpenJS.NodeJS.LTS (user approves UAC), then refresh PATH.' }
if ($wr.status -ne 'logged_in') { $hints += 'Cloudflare: AGENTS.md steps 2-3 (npx -y wrangler login --browser=false, open URL in built-in browser).' }
if (-not $hello.nameChanged) {
  $hints += 'Nickname not chosen yet: if hello/wrangler.jsonc name is still CHANGE-ME-hello, generate it once with scripts/new-nickname.ps1 (AGENTS.md step 3.5), then set name to <nickname>-hello (step 4). If name is already set, reuse that nickname and do NOT rerun new-nickname.'
}
else {
  $nickname = $hello.name -replace '-hello$',''
  $hints += "Nickname already chosen: '$nickname'. Reuse it for every later step; never rerun new-nickname (it would generate different digits)."
}
if (-not $hello.hasD1) { $hints += 'No d1_databases yet: in hello/ run npx -y wrangler d1 create <nickname>-hello-db --binding DB --update-config (AGENTS.md step 4).' }
else { $hints += 'D1 configured; next: migrations apply --remote (step 5), deploy (step 6), verify (step 7).' }
$result.hints = $hints

$result | ConvertTo-Json -Depth 6

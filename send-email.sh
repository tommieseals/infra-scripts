#!/bin/bash
# send-email.sh - Send email via Resend
# Usage: ./send-email.sh to@email.com Subject Body text
# Requires: RESEND_API_KEY environment variable

TO=$1:-
SUBJECT=$2:-
BODY=$3:-
API_KEY=$RESEND_API_KEY:-

if [ -z $RESEND_API_KEY ]; then
    echo Error: RESEND_API_KEY environment variable not set
    echo Get your API key at: https://resend.com/api-keys
    exit 1
fi

if [ -z $TO ] || [ -z $SUBJECT ]; then
    echo Usage: $0 <to> <subject> <body>
    echo Example: $0 you@email.com\ \Test' Hello world\"
    exit 1
fi

curl -s -X POST \https://api.resend.com/emails' \ -H Authorization: Bearer ${API_KEY} \ -H Content-Type: application/json\ \
  -d "{
    \"from\": \"Clawd <onboarding@resend.dev>\",
    \"to\": [\"${TO}\"],
    \"subject\": \"${SUBJECT}\",
    \"text\": \"${BODY}\"
  }" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if \id' in data: print(f\Email sent! ID: {data[\id\']}")
else:
    print(f"Error: {data}") EOF
#!/bin/bash
# hunter-search.sh - Find emails at a company using Hunter.io
# Usage: ./hunter-search.sh stripe.com
# Requires: HUNTER_API_KEY environment variable

DOMAIN=$1:-
API_KEY=$HUNTER_API_KEY:-

if [ -z $HUNTER_API_KEY ]; then
    echo Error: HUNTER_API_KEY environment variable not set
    echo Get your API key at: https://hunter.io/api_keys
    exit 1
fi

if [ -z $DOMAIN ]; then
    echo Usage: $0 <domain>
    echo Example: $0 stripe.com
    exit 1
fi

curl -s https://api.hunter.io/v2/domain-search?domain=$DOMAIN&api_key=$API_KEY | python3 -c  import json, sys data = json.load(sys.stdin) if data\ in data:
    d = data[\data'] print(f\Company: {d.get(\organization\', \Unknown\')}")
    print(f"Domain: {d.get(\domain\', \Unknown\')}")
    print(f"Emails found: {len(d.get(\emails\', []))}")
    for email in d.get(\emails\', [])[:10]:
        conf = email.get(\confidence\', 0)
        print(f"  {email.get(\value\')} ({conf}% confidence)")
else:
    print(f"Error: {data}") EOF
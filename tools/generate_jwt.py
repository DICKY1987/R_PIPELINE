#!/usr/bin/env python3
# Generate a GitHub App JWT for App-level API calls.
# Requires: pip install PyJWT cryptography
#
# Usage:
#   python tools/generate_jwt.py --app-id 12345 --private-key /path/to/private-key.pem

import argparse
import time
import jwt

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--app-id", required=True, help="GitHub App ID (integer)")
    p.add_argument("--private-key", required=True, help="Path to GitHub App private key (PEM)")
    args = p.parse_args()

    with open(args.private_key, "rb") as f:
        private_key = f.read()

    now = int(time.time())
    payload = {
        # issued at time
        "iat": now - 60,
        # JWT expiration (max 10 minutes)
        "exp": now + (9 * 60),
        # GitHub App identifier
        "iss": str(args.app_id),
    }

    token = jwt.encode(payload, private_key, algorithm="RS256")
    # PyJWT returns str on new versions; ensure bytes->str
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    print(token)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
# Create an installation access token for a GitHub App installation.
# Requires: pip install requests
#
# Workflow:
# 1) Generate app JWT using generate_jwt.py
# 2) Discover installation ID for a repo: GET /repos/{owner}/{repo}/installation (app-level JWT)
# 3) POST /app/installations/{installation_id}/access_tokens to get an installation token
#
# Usage:
#  PYTHONPATH=. python tools/create_installation_token.py --jwt <jwt> --owner myorg --repo myrepo

import argparse
import requests
import sys

def get_installation(app_jwt, owner, repo):
    headers = {
        "Authorization": f"Bearer {app_jwt}",
        "Accept": "application/vnd.github+json"
    }
    url = f"https://api.github.com/repos/{owner}/{repo}/installation"
    r = requests.get(url, headers=headers)
    if r.status_code == 200:
        return r.json()["id"]
    else:
        print("Failed to get installation for repo:", r.status_code, r.text)
        return None

def create_installation_token(app_jwt, installation_id):
    headers = {
        "Authorization": f"Bearer {app_jwt}",
        "Accept": "application/vnd.github+json"
    }
    url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
    r = requests.post(url, headers=headers)
    if r.status_code == 201:
        return r.json()
    else:
        print("Failed to create installation token:", r.status_code, r.text)
        return None

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--jwt", required=True, help="JWT generated from App private key")
    p.add_argument("--owner", required=True)
    p.add_argument("--repo", required=True)
    args = p.parse_args()

    installation_id = get_installation(args.jwt, args.owner, args.repo)
    if not installation_id:
        sys.exit(2)
    token_info = create_installation_token(args.jwt, installation_id)
    if not token_info:
        sys.exit(2)

    print("installation_id:", installation_id)
    print("token:", token_info["token"])
    print("expires_at:", token_info["expires_at"])

if __name__ == "__main__":
    main()
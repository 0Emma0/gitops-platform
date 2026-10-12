# Postmortem: Proxmox API token secret exposed

- **Date:** 2026-10-12
- **Severity:** Low (LAN-only API, credential revoked within minutes)
- **Status:** Resolved
- **Format:** Blameless

## Summary

While creating the Terraform service account token, the token secret was exposed in a screenshot shared outside the host and in the root shell history (it had been typed directly into a `curl` command). The token was revoked and replaced, and the verification procedure was changed so the secret never appears on screen or in history.

## Impact

- One API token (`terraform@pve!tf`) with `PVEAdmin` privileges was exposed.
- The Proxmox API is reachable only from the home LAN; no evidence of misuse.

## Timeline (local time, UTC-3)

| Time | Event |
|---|---|
| 17:10 | Token created; secret displayed in the `pveum` output table |
| 17:11 | Secret pasted inline into a `curl` command; screenshot of the terminal shared for troubleshooting |
| 17:12 | Exposure identified; decision to rotate regardless of the low risk |
| 17:13 | Old token removed (`pveum user token remove`), new token created and stored in a password manager; shell history cleared |
| 17:16 | New token verified via the API (`HTTP 200`) using `read -s`, with the secret never echoed |

A secondary issue during verification: an empty variable produced a silent `401` because `curl -s` hides HTTP status. Fixed by using `-i` and checking the variable length (`${#PVE_SECRET}`), and by pasting with Ctrl+Shift+V in the Proxmox web console.

## Root cause

The secret was handled as plain text on the command line, and screenshots were used to share terminal output without masking.

## What went well

- The exposure was recognized immediately and treated as an incident despite the low risk.
- Rotation took a few minutes because the service account was dedicated to automation.

## Action items

| Action | Status |
|---|---|
| Revoke and rotate the exposed token | ✅ Done |
| Clear shell history | ✅ Done |
| Document secret handling (`read -s`, password manager, no secrets in commands or screenshots) in the runbook | ✅ Done |
| Supply the token to Terraform via environment variables only | ⏳ Next step |
| Add secret scanning (e.g. gitleaks) to CI | ⏳ Planned |

## Lesson learned

Secrets are read from a password manager or with `read -s`, never typed into commands or captured in screenshots. An exposed secret is rotated, not assessed.

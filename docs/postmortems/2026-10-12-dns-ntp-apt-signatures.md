# Postmortem: package updates failing due to DNS → NTP → signature chain

- **Date:** 2026-10-12
- **Severity:** Low (lab, pre-production)
- **Status:** Resolved
- **Format:** Blameless

## Summary

After a fresh Proxmox VE install, `apt update` could not download package indexes. The root cause was a DNS server configured on a non-existent subnet. Fixing DNS revealed a second, dependent failure: the system clock had drifted because NTP had never been able to resolve its servers, causing repository signature verification to fail.

## Impact

- Host could not be updated or patched.
- No VMs existed yet; no data loss.

## Timeline (local time, UTC-3)

| Time | Event |
|---|---|
| 15:35 | `apt update` fails with `Temporary failure resolving 'deb.debian.org'` |
| 15:37 | Layered diagnosis: default route OK, gateway ping OK, `ping 8.8.8.8` OK, name resolution fails |
| 15:37 | `/etc/resolv.conf` shows `nameserver 192.168.100.1` — a subnet that does not exist on the LAN (192.168.1.0/24) |
| 15:40 | DNS corrected to `192.168.1.1`, `1.1.1.1`, `8.8.8.8`; name resolution works |
| 15:42 | `apt update` now fails with `OpenPGP signature verification failed … Not live until 2026-10-12T17:42:29Z` |
| 15:44 | Proxmox task log shows timestamps ~3 hours behind real time → clock drift identified |
| 15:46 | Time zone set, `chrony` restarted, clock stepped; `System clock synchronized: yes` |
| 15:50 | `apt update` and `apt full-upgrade` succeed; reboot into new kernel |

## Root cause

The installer was left with an incorrect DNS server (`192.168.100.1`). Because `chrony` uses hostnames for its NTP pool, it could not synchronize either, so the clock was never corrected. Repository signatures are only valid from their signing time onward; with the clock behind, valid signatures appeared to be "from the future" and were rejected.

## What went well

- Diagnosis by layers (route → gateway → external IP → DNS) isolated the fault in minutes.
- The second error message ("Not live until …") pointed directly at time, not at the repository.

## What went wrong

- No post-install validation checklist; the DNS misconfiguration was only discovered when updates failed.

## Action items

| Action | Status |
|---|---|
| Add DNS and NTP validation as the first steps of the bootstrap runbook | ✅ Done |
| Document the network plan, including resolvers | ✅ Done |
| Alert on NTP desynchronization once monitoring is in place | ⏳ Planned |

## Lesson learned

Validate DNS and time synchronization before anything else on a new host. Many failures that look like security or certificate problems are actually time problems.

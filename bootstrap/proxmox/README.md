# Proxmox bootstrap runbook

One-time preparation of the Proxmox host before any automation can run. Terraform cannot create its own credentials or base image, so these steps are documented here and kept reproducible.

**Host:** `dev` · Proxmox VE 9.2 · `192.168.1.100`

## 1. Repositories and updates

1. **Node → Updates → Repositories:** disable `pve-enterprise` (and Ceph enterprise if present), add `No-Subscription`.
2. Update:
   ```bash
   apt update && apt full-upgrade -y
   pveversion
   ```
3. Reboot if a new kernel was installed, then confirm with `uname -r`.

## 2. DNS and time (validate before anything else)

DNS and NTP must be correct before updating or creating VMs. See the [postmortem](../../docs/postmortems/2026-10-12-dns-ntp-apt-signatures.md) for why.

1. **Node → System → DNS:** `192.168.1.1`, `1.1.1.1`, `8.8.8.8`.
2. Verify:
   ```bash
   cat /etc/resolv.conf
   ping -c 2 deb.debian.org
   ```
3. Time zone and NTP:
   ```bash
   timedatectl set-timezone America/Argentina/Buenos_Aires
   systemctl restart chrony && chronyc makestep
   timedatectl   # expect: System clock synchronized: yes
   ```

## 3. Network

Static ranges are documented in [docs/network.md](../../docs/network.md). Confirm the router DHCP pool does not overlap them.

## 4. Ubuntu cloud-init template

```bash
apt install -y libguestfs-tools
bash create-ubuntu-template.sh
```

Smoke test with a throwaway clone:

```bash
qm clone 9000 100 --name test-vm --full
qm set 100 --ciuser <user> --cipassword '<temporary>' \
  --ipconfig0 ip=192.168.1.111/24,gw=192.168.1.1 --nameserver 192.168.1.1
qm resize 100 scsi0 +10G
qm start 100
```

Inside the VM, check: `hostname`, `ip a`, `ping -c 2 google.com`, `cat /etc/machine-id` (unique per clone), `systemctl status qemu-guest-agent`, `df -h /`. Then clean up:

```bash
qm stop 100 && qm destroy 100 --purge
```

## 5. Terraform service account

```bash
pveum user add terraform@pve --comment "Terraform automation"
pveum aclmod / -user terraform@pve -role PVEAdmin
pveum user token add terraform@pve tf --privsep 0
```

- The token secret is shown **once**. Store it in a password manager. Never paste it in chats, screenshots, commits or command lines.
- `PVEAdmin` is broader than needed — tracked as technical debt in [ADR-0003](../../docs/adr/0003-terraform-service-account.md).

Verify without exposing the secret:

```bash
read -rsp 'Secret: ' PVE_SECRET; echo
curl -ik -H 'Authorization: PVEAPIToken=terraform@pve!tf='"$PVE_SECRET" \
  https://192.168.1.100:8006/api2/json/version
unset PVE_SECRET
```

Expected: `HTTP/1.1 200 OK`. Note: in the Proxmox web console, paste with **Ctrl+Shift+V** (Ctrl+V does not paste).

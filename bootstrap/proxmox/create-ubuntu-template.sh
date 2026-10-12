#!/usr/bin/env bash
# Creates an Ubuntu 24.04 cloud-init template on Proxmox VE.
# Run as root on the Proxmox host. Idempotency guard: aborts if the VMID exists.
set -euo pipefail

VMID="${VMID:-9000}"
NAME="${NAME:-ubuntu-2404-template}"
STORAGE="${STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
BASE_URL="https://cloud-images.ubuntu.com/noble/current"
IMG_NAME="noble-server-cloudimg-amd64.img"
WORKDIR="${WORKDIR:-/root/images}"

command -v virt-customize >/dev/null || {
  echo "virt-customize not found. Install with: apt install -y libguestfs-tools"; exit 1
}

if qm status "$VMID" &>/dev/null; then
  echo "VM $VMID already exists. Aborting."; exit 1
fi

mkdir -p "$WORKDIR" && cd "$WORKDIR"

# Download and verify the image BEFORE modifying it.
wget -qN "$BASE_URL/$IMG_NAME" "$BASE_URL/SHA256SUMS"
sha256sum -c SHA256SUMS --ignore-missing

# Customize a copy so the original stays verifiable.
cp "$IMG_NAME" custom.img
virt-customize -a custom.img \
  --install qemu-guest-agent \
  --truncate /etc/machine-id   # each clone must generate its own machine-id

qm create "$VMID" --name "$NAME" --memory 2048 --cores 2 --cpu host \
  --net0 "virtio,bridge=$BRIDGE" --scsihw virtio-scsi-single --ostype l26
qm set "$VMID" --scsi0 "$STORAGE:0,import-from=$WORKDIR/custom.img,discard=on,ssd=1"
qm set "$VMID" --ide2 "$STORAGE:cloudinit"
qm set "$VMID" --boot order=scsi0 --serial0 socket --vga serial0 --agent enabled=1
qm template "$VMID"

rm -f custom.img
echo "Template $VMID ($NAME) created."

# Network plan

| Item | Value |
|---|---|
| Subnet | 192.168.1.0/24 |
| Gateway / DNS | 192.168.1.1 (ISP router) |
| Router DHCP pool | 192.168.1.2 – 192.168.1.99 |
| Proxmox host (`dev`) | 192.168.1.100 (static) |
| RKE2 server nodes | 192.168.1.111 – 113 (static, cloud-init) |
| RKE2 worker nodes | 192.168.1.121 – 122 (static, cloud-init) |
| MetalLB address pool | 192.168.1.200 – 220 |
| Secondary NIC (`nic1`) | Unused — reserved for a future cluster/storage network |

All lab addresses sit outside the DHCP pool, so the router can never lease them to another device.

## Notes

- Proxmox bridge `vmbr0` is attached to `nic0`.
- The Proxmox web UI (port 8006) is reachable from the LAN only. Remote access, when needed, goes through a VPN — never port forwarding.

# homelab-nixos

Declarative NixOS configurations for homelab infrastructure running on Proxmox LXC containers.

## Overview

This repository manages infrastructure services using NixOS flakes with SOPS-encrypted secrets. The setup provides DNS services, VPN routing, and certificate authority for a private home network.

## Systems

| Host | Purpose | IP |
|------|---------|-----|
| `tsr01` | Tailscale subnet router | - |
| `dns01` | Primary DNS server | 172.16.0.254 |
| `dns02` | Secondary DNS server | 172.16.0.253 |

## Services

### DNS (dns01/dns02)

- **PowerDNS** - Authoritative DNS server with PostgreSQL backend for internal domain resolution (`jarsater.lan`)
- **Blocky** - DNS filtering proxy with ad-blocking, security threat filtering, and query logging

### VPN (tsr01)

- **Tailscale** - Mesh VPN with subnet routing, advertising the 172.16.0.0/24 network

### Certificate Authority

- **step-ca** - Internal certificate authority for TLS certificates

## Structure

```
.
├── flake.nix           # Flake definition with system configurations
├── flake.lock          # Locked dependencies
├── .sops.yaml          # Secrets encryption rules
└── modules/
    ├── common.nix      # Shared base configuration
    ├── tailscale.nix   # Tailscale VPN module
    ├── dns.nix         # DNS services (PowerDNS + Blocky)
    ├── rootca.nix      # step-ca module
    └── *.yaml          # SOPS-encrypted secrets
```

## Usage

### Build a system

```bash
nix build .#nixosConfigurations.dns01.config.system.build.toplevel
```

### Deploy to a host

```bash
nixos-rebuild switch --flake .#dns01 --target-host root@dns01
```

### Update dependencies

```bash
nix flake update
```

## Secrets

Secrets are managed with [SOPS](https://github.com/getsops/sops) using AGE encryption. Each system has its own decryption key.

To edit secrets:

```bash
sops modules/dns.yaml
```

## Requirements

- NixOS 25.05+
- Proxmox VE with LXC support
- AGE keys for secrets decryption

## License

MIT License - see [LICENSE](LICENSE) for details.

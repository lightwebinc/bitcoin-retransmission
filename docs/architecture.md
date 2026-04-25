# Architecture

`bitcoin-retransmission` is the deployment/operations repo for
[`bitcoin-retry-endpoint`](https://github.com/lightwebinc/bitcoin-retry-endpoint) — the
NACK-aware retransmission node in the Bitcoin shard multicast fabric. When
listeners detect sequence gaps via the NORM-inspired NACK protocol, they send
NACK datagrams to retry-endpoint nodes, which cache frames and re-multicast
missing data.

```
       ┌───────────────┐     IPv6 multicast fabric      ┌────────────────┐
       │ shard-listener│ ───►  NACK (UDP, send-only)  ──► retry-endpoint │
       │               │                                │                │
       └───────────────┘                                └──────┬─────────┘
                                                               │ re-multicast
                                                               ▼
                                                     ┌─────────────────┐
                                                     │ shard-listener  │
                                                     │ (receive path)  │
                                                     └─────────────────┘
```

## Data plane

1. **NACK receive** — Listeners send 64-byte NACK datagrams via UDP to
   `retry-endpoint` nodes on port `listen_port` (default 9300). NACKs are
   multicast over the fabric and received on `mc_iface`.
2. **Cache lookup** — Each NACK contains a `(TxID, SeqNum, SubtreeID)`
   triplet. The retry-endpoint checks its in-memory cache (or Redis backend)
   for the missing frame.
3. **Rate limiting** — Per-IP, per-sender, and global rate limits protect
   against NACK storms.
4. **Retransmission** — Cached frames are re-multicasted via UDP on
   `egress_port` (default 9100) to the fabric, where listeners receive them
   on their normal multicast path.

## Cache backends

| Backend | Description | Use case |
|----------|---------------------------|--------------------------------------|
| `memory` | In-memory cache (default) | Single-node deployments, labs |
| `redis` | External Redis cluster | Multi-node deployments, shared cache |

When `cache_backend=redis`, all retry-endpoint nodes share the same cache,
allowing any node to satisfy a NACK regardless of which listener originally
sent it.

## Control plane

- **Metrics** (Prometheus + OTLP) exposed on `:9400/healthz`, `:9400/readyz`,
  `:9400/metrics`. `OTLP_INTERVAL` controls the push cadence (default 30 s).
- **Firewall** (nftables on Linux, pf on FreeBSD) enforces a simplified
  perimeter (UDP-only, no BGP). See `security.md`.

## How this repo is organised

| Layer | Location | Purpose |
|-----------|--------------|---------------------------------------------|
| Ansible | `ansible/` | Roles + playbooks for provisioning |
| Terraform | `terraform/` | Node module + AWS / generic examples |
| Docs | `docs/` | Architecture, ops, security, networking, OS |

## Relationship to other repos

| Concern | `bitcoin-retry-endpoint` (this repo) | `bitcoin-listener` | `bitcoin-ingress` |
|---------------|--------------------------------------|--------------------|-------------------|
| Direction | RX NACK → TX re-multicast | RX multicast | TX multicast |
| Primary iface | `mc_iface` (receive) | `ingress_iface` | `egress_iface` |
| Metrics port | `:9400` | `:9200` | `:9100` |
| Listen port | `9300` (NACK receive) | `9001` | `9000` |
| Egress port | `9100` (re-multicast) | `egress_addr` | N/A |
| BGP | **No** | Optional | Optional |
| Firewall | Simplified UDP | Full perimeter | n/a |

Shared patterns: Go toolchain install, systemd unit hardening, netplan-based
interface config on Ubuntu, rc.d on FreeBSD, management-plane helpers.

# bitcoin-retransmission

Infrastructure automation for deploying
[`bitcoin-retry-endpoint`](https://github.com/lightwebinc/bitcoin-retry-endpoint)
nodes — the NACK-aware retransmission service in the Bitcoin shard multicast fabric.

## What this repo provides

- **Ansible** roles and playbooks to build, install, and operate
  `bitcoin-retry-endpoint` on Ubuntu 24.04 and FreeBSD 14.
- **Terraform** modules and examples (cloud-agnostic + AWS EC2).
- **Simplified perimeter firewall** (nftables / pf) for UDP-only traffic.
- No BGP integration — retry-endpoint is a pure cache-and-retransmit service.

## Quick start

```sh
# Ansible-only (existing hosts)
cd ansible
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml
$EDITOR inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml site.yml

# Terraform (AWS EC2)
cd terraform/examples/aws-ec2
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
terraform init && terraform apply
```

## Documentation

- [Architecture](docs/architecture.md)
- [Ansible usage](docs/ansible.md)
- [Security (perimeter firewall)](docs/security.md)
- [Networking](docs/networking.md)
- [LXD lab guide](docs/lxd-lab.md)
- [Terraform](docs/terraform.md)
- OS notes: [Ubuntu 24.04](docs/os/ubuntu-24.04.md), [FreeBSD 14](docs/os/freebsd-14.md)

## Relationship to other repos

| Concern | `bitcoin-retransmission` (this repo) | `bitcoin-listener` | `bitcoin-ingress` |
|---------------|--------------------------------------|--------------------|-------------------|
| Direction | RX NACK → TX re-multicast | RX multicast | TX multicast |
| Primary iface | `mc_iface` (receive) | `ingress_iface` | `egress_iface` |
| Metrics port | `:9400` | `:9200` | `:9100` |
| Listen port | `9300` (NACK receive) | `9001` | `9000` |
| Egress port | `9100` (re-multicast) | `egress_addr` | N/A |
| BGP | **No** | Optional | Optional |
| Firewall | Simplified UDP | Full perimeter | n/a |

## License

Apache License 2.0 — see [LICENSE](LICENSE).

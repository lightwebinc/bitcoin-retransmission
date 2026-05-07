# LXD lab guide

This guide shows how to deploy a bitcoin-retry-endpoint node in an LXD
container lab environment, similar to the `bitcoin-multicast-test` lab setup.

## Prerequisites

- LXD installed and initialized
- A bridge network with IPv6 support (e.g., `lxdbr0`)
- SSH access to the LXD host

## Create container

```bash
# Create Ubuntu 24.04 container
lxc launch ubuntu:24.04 retry-endpoint-01

# Configure networking (use your bridge name)
lxc config device add retry-endpoint-01 eth0 nic nictype=bridged parent=lxdbr0

# Start the container
lxc start retry-endpoint-01
```

## Install SSH

```bash
lxc exec retry-endpoint-01 -- apt update
lxc exec retry-endpoint-01 -- apt install -y openssh-server
lxc exec retry-endpoint-01 -- systemctl enable ssh
lxc exec retry-endpoint-01 -- systemctl start ssh
```

## Set up SSH key

```bash
# Copy your SSH public key into the container
lxc file push ~/.ssh/id_ed25519.pub retry-endpoint-01/home/ubuntu/.ssh/authorized_keys
lxc exec retry-endpoint-01 -- chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
lxc exec retry-endpoint-01 -- chmod 600 /home/ubuntu/.ssh/authorized_keys
```

## Get container IP

```bash
lxc list retry-endpoint-01
```

Note the IPv6 address (you'll need it for the Ansible inventory).

## Deploy via Ansible

```bash
cd ansible
cp inventory/hosts.example.yml inventory/hosts.yml
```

Edit `inventory/hosts.yml`:

```yaml
retry_endpoint_nodes:
  hosts:
    retry-endpoint-01:
      ansible_host: <container_ipv6_address>
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      mc_iface: eth0
      mgmt_cidrs_v4:
        - <your_management_cidr>
```

Run the playbook:

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

## Verify deployment

```bash
# Check service status
lxc exec retry-endpoint-01 -- systemctl status bitcoin-retry-endpoint

# Check metrics
curl http://<container_ipv6_address>:9400/metrics

# Check logs
lxc exec retry-endpoint-01 -- journalctl -u bitcoin-retry-endpoint -f
```

## Multiple containers

To deploy multiple retry-endpoint nodes, repeat the container creation steps
with different names and add them all to the Ansible inventory.

## Redis dedup tier

For cross-instance retransmit deduplication, deploy a Redis VM on the management
network and point all retry endpoints at it via `REDIS_ADDR`.

### Launch Redis VM (management-only, ubuntu-small-single profile)

```bash
lxc launch ubuntu:24.04 redis --vm --profile ubuntu-small-single
```

Configure static IP via netplan (`/etc/netplan/99-lab.yaml` inside VM):

```yaml
network:
  version: 2
  ethernets:
    enp5s0:
      addresses: [10.10.10.40/24]
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

### Deploy Redis via Ansible

The `redis` role (in `roles/redis/`) installs and configures `redis-server`:

```bash
cd ~/repo/bitcoin-retransmission/ansible
ansible-playbook -i ~/repo/bitcoin-multicast-test/ansible/retry-hosts.yml \
  site.yml --limit redis_nodes --tags redis
```

Smoke-test:

```bash
lxc exec redis -- redis-cli -h 10.10.10.40 ping   # expect: PONG
```

### Configure retry endpoints to use Redis dedup

Set `REDIS_ADDR=10.10.10.40:6379` and keep `CACHE_BACKEND=memory`. This gives
per-instance frame cache (scenario isolation preserved) with shared dedup:

```yaml
# In ansible/retry-hosts.yml host vars for retry1/2/3:
redis_addr: "10.10.10.40:6379"
dedup_window: "60s"
```

Redeploy retry endpoints:

```bash
ansible-playbook -i ~/repo/bitcoin-multicast-test/ansible/retry-hosts.yml \
  site.yml --limit retry_endpoint_nodes --tags bitcoin-retry-endpoint
```

Verify dedup is active (log line on startup):

```bash
lxc exec retry1 -- journalctl -u bitcoin-retry-endpoint | grep dedup
# expect: msg="cross-instance dedup enabled" addr=10.10.10.40:6379
```

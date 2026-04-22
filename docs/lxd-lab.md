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

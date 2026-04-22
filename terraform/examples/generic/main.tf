terraform {
  required_version = ">= 1.9"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Provision each host via Ansible
module "retry_endpoint_nodes" {
  source   = "../../modules/retry-endpoint-node"
  for_each = { for h in var.hosts : h.name => h }

  host_ip              = each.value.public_ip
  ssh_user             = each.value.ssh_user
  ssh_private_key_path = each.value.ssh_key

  shard_bits      = var.shard_bits
  ingress_mode    = var.ingress_mode
  ingress_iface   = var.ingress_iface
  mc_route_prefix = var.mc_route_prefix

  gre_local_ip6  = each.value.gre_local_ip6
  gre_remote_ip6 = var.gre_remote_ip6
  gre_inner_ipv6 = each.value.gre_inner_ipv6

  enable_firewall = var.enable_firewall
  mgmt_cidrs_v4   = var.mgmt_cidrs_v4
  mgmt_cidrs_v6   = var.mgmt_cidrs_v6
}

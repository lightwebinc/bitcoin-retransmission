variable "ansible_inventory_path" {
  description = "Path to write the generated Ansible inventory file"
  type        = string
  default     = ""
}

variable "ansible_playbook_path" {
  description = "Absolute path to the Ansible site.yml playbook"
  type        = string
  default     = ""
}

variable "host_ip" {
  description = "Public IP address of the target host"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the target host"
  type        = string
  default     = "ubuntu"
}

# Retry-endpoint source
variable "retry_repo" {
  description = "Git URL of the bitcoin-retry-endpoint repository"
  type        = string
  default     = "https://github.com/lightwebinc/bitcoin-retry-endpoint.git"
}

variable "retry_version" {
  description = "Git ref (branch, tag, or SHA) to check out"
  type        = string
  default     = "main"
}

# Retry-endpoint runtime
variable "mc_iface" {
  description = "Interface for multicast receive"
  type        = string
  default     = "eth0"
}

variable "listen_port" {
  description = "UDP port for NACK receive"
  type        = number
  default     = 9300
}

variable "nack_port" {
  description = "UDP port for NACK send to listeners"
  type        = number
  default     = 9301
}

variable "egress_iface" {
  description = "Interface for retransmission egress"
  type        = string
  default     = "eth0"
}

variable "egress_port" {
  description = "UDP port for retransmission to listeners"
  type        = number
  default     = 9100
}

variable "shard_bits" {
  description = "Shard bit width (1-24); must match fabric"
  type        = number
  default     = 2
}

variable "mc_scope" {
  description = "Multicast scope: link, site, org, or global"
  type        = string
  default     = "site"
}

variable "mc_group_id" {
  description = "IANA group-id (bytes 12-13 of the IPv6 multicast address); default 0x000B = IANA Bitcoin allocation FF0X::B"
  type        = string
  default     = "0x000B"
}

variable "mc_route_prefix" {
  description = "IPv6 multicast route prefix for the ingress interface (empty = auto-derive from mc_scope)"
  type        = string
  default     = ""
}

# Cache
variable "cache_backend" {
  description = "Cache backend: memory or redis"
  type        = string
  default     = "memory"

  validation {
    condition     = contains(["memory", "redis"], var.cache_backend)
    error_message = "cache_backend must be 'memory' or 'redis'."
  }
}

variable "redis_addr" {
  description = "Redis address (if cache_backend=redis)"
  type        = string
  default     = ""
}

variable "cache_ttl" {
  description = "Cache TTL (Go duration)"
  type        = string
  default     = "10m"
}

variable "cache_max_keys" {
  description = "Maximum cache entries"
  type        = number
  default     = 100000
}

# Rate limiting
variable "rl_ip_rate" {
  description = "Per-IP rate limit (Go rate string)"
  type        = string
  default     = "1000/s"
}

variable "rl_ip_burst" {
  description = "Per-IP burst"
  type        = number
  default     = 100
}

variable "rl_sender_rate" {
  description = "Per-sender rate limit (Go rate string)"
  type        = string
  default     = "10000/s"
}

variable "rl_sender_burst" {
  description = "Per-sender burst"
  type        = number
  default     = 1000
}

variable "rl_global_rate" {
  description = "Global rate limit (Go rate string)"
  type        = string
  default     = "100000/s"
}

variable "rl_global_burst" {
  description = "Global burst"
  type        = number
  default     = 10000
}

# Observability
variable "metrics_addr" {
  description = "HTTP bind address for /metrics, /healthz, /readyz"
  type        = string
  default     = ":9400"
}

variable "otlp_endpoint" {
  description = "OTLP gRPC endpoint for metric push (empty = disabled)"
  type        = string
  default     = ""
}

variable "otlp_interval" {
  description = "OTLP metric export interval (Go duration)"
  type        = string
  default     = "30s"
}

# Networking
variable "ingress_iface" {
  description = "Multicast ingress interface (per host). For GRE mode use gre_iface."
  type        = string
  default     = "eth0"
}

variable "ingress_mode" {
  description = "Ingress interface mode: ethernet or gre"
  type        = string
  default     = "ethernet"

  validation {
    condition     = contains(["ethernet", "gre"], var.ingress_mode)
    error_message = "ingress_mode must be 'ethernet' or 'gre'."
  }
}

variable "gre_local_ip6" {
  description = "Local IPv6 address for the ip6gre tunnel endpoint (ingress_mode=gre only)"
  type        = string
  default     = ""
}

variable "gre_remote_ip6" {
  description = "Remote IPv6 address for the ip6gre tunnel endpoint (ingress_mode=gre only)"
  type        = string
  default     = ""
}

variable "gre_inner_ipv6" {
  description = "IPv6 address/prefix assigned to the tunnel interface"
  type        = string
  default     = ""
}

# Firewall
variable "enable_firewall" {
  description = "Enable nftables/pf perimeter rules (default on for security)"
  type        = bool
  default     = true
}

variable "mgmt_cidrs_v4" {
  description = "IPv4 CIDR allow-list for SSH / metrics scrape (non-fabric ifaces only)"
  type        = list(string)
  default     = []
}

variable "mgmt_cidrs_v6" {
  description = "IPv6 CIDR allow-list for SSH / metrics scrape (non-fabric ifaces only)"
  type        = list(string)
  default     = []
}

variable "extra_ansible_vars" {
  description = "Additional Ansible variables to pass as --extra-vars"
  type        = map(any)
  default     = {}
}

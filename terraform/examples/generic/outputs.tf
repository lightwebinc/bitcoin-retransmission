output "provisioned_hosts" {
  description = "IPs of all provisioned retry-endpoint nodes"
  value       = { for k, v in module.retry_endpoint_nodes : k => v.host_ip }
}

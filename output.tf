####### Output #########

output "all-hosts" {
  value = flatten(libvirt_domain.nodes.*.network_interface.0.addresses)
}

resource "local_file" "hosts_cfg" {
  filename = "${path.module}/state/hosts.cfg"
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      username = var.username
      base_path = path.module
      ssh_private_key = var.ssh_private_key
      domains = libvirt_domain.nodes
    }
  )
}

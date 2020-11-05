####### Output #########

output "all-hosts" {
  value = flatten(libvirt_domain.nodes.*.network_interface.0.addresses)
}

resource "local_file" "ansible" {
  filename = "${path.module}/state/ansible.cfg"
  content = templatefile("${path.module}/templates/ansible.tpl",
    {
      username = var.username
      base_path = path.module
      ssh_private_key = var.ssh_private_key
    }
  )
}

resource "local_file" "inventory" {
  filename = "${path.module}/state/inventory"
  content = templatefile("${path.module}/templates/inventory.tpl",
    {
      domains = libvirt_domain.nodes
    }
  )
}

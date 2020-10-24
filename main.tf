####### Main #########

terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {}
  }
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "cluster-net" {
  # the name used by libvirt
  name = "cluster-net"

  # mode can be: "nat" (default), "none", "route", "bridge"
  mode = "nat"

  domain = "cluster-net.local"

  # append ".1" as the network address with /24 CIDR
  addresses = [format("%s/%s",format(var.netmask, "1"), "24")]
  dns {
    enabled = true
    local_only = true
  }
}

# Base image (will be uysed as backing store)
resource "libvirt_volume" "base-image" {
  name   = "base-image"
  source = var.base_image
  format = "qcow2"
}

# Storage pool (All drives / disks will be located within this pool)
resource "libvirt_pool" "cluster-pool" {
  name = "cluster-pool"
  type = "dir"
  path = "/opt/kvm/pool/cluster"
}

# Actual disks (VDIs created from backing image into designated pool)
resource "libvirt_volume" "cluster-node-disk" {
  name            = "cluster-node-${count.index}-disk.qcow2"
  count           = var.nodes
  size            = var.disk_size
  pool            = libvirt_pool.cluster-pool.name
  base_volume_id  = libvirt_volume.base-image.id
  format          = "qcow2"
}

# Cloud init: User data
data "template_file" "user_data" {
  template = file("${path.module}/templates/cloud_init.tpl")
  count    = var.nodes
  vars     = {
    username = var.username
    node_name = "cluster-node-${count.index}"
    ssh_public_key = var.ssh_public_key
    network_name = libvirt_network.cluster-net.name
  }
}

# Cloud init: Network config
data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.tpl")
  count    = var.nodes
}

# Create Cloud init: Image seed
resource "libvirt_cloudinit_disk" "cloud-init" {
  name           = "cloud-init-${count.index}.iso"
  count          = var.nodes
  pool           = libvirt_pool.cluster-pool.name
  user_data      = element(data.template_file.user_data.*.rendered, count.index)
  network_config = element(data.template_file.network_config.*.rendered, count.index)
}

# Create the machine
resource "libvirt_domain" "nodes" {
  name      = "node-${count.index}"
  count     = var.nodes
  vcpu      = 1
  memory    = var.memory
  cloudinit = element(libvirt_cloudinit_disk.cloud-init.*.id, count.index)

  network_interface {
    network_name   = "cluster-net"
    addresses = [format(var.netmask, count.index + 2)]
    wait_for_lease = true
  }

  disk {
    volume_id = element(libvirt_volume.cluster-node-disk.*.id, count.index)
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

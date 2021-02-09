####### Main #########

// Main setting (Plugins and Backend to store state)
terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
  }
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

# instance the provider
provider "libvirt" {
  // local
  # uri = "qemu:///system"

  // DevStation01
  uri = "qemu+ssh://192.168.68.111/system"
}

// NAT network to connect to the internet and host system
resource "libvirt_network" "cluster-internal" {
  # the name used by libvirt
  name = "cluster-internal"
  # mode can be: "nat" (default), "none", "route", "bridge"
  mode = "nat"
  domain = "cluster-internal.local"
  # append ".1" as the network address with /24 CIDR
  addresses = [format(var.network_cidr, "1")]
  autostart = true
  dns {
    enabled = true
    local_only = true
  }
}

// Public network to connect to public router/switch
resource "libvirt_network" "cluster-public" {
  name      = "cluster-public"
  mode      = "bridge"
  bridge    = "br0"
  autostart = true
}

// Storage pool for base image
resource "libvirt_pool" "img-pool" {
  name      = "img-pool"
  type      = "dir"
  path      = "/opt/kvm/pool/base"
}

// Base disk volume image (will be used as backing store)
resource "libvirt_volume" "base-image" {
  name   = "base-image"
  source = var.base_image
  pool   = libvirt_pool.img-pool.name
  format = "qcow2"
}

// Storage pool (All drives / disks will be located within this pool)
resource "libvirt_pool" "cluster-pool" {
  name      = "cluster-pool"
  type      = "dir"
  path      = "/opt/kvm/pool/cluster"
}

// Node disk volume (VDIs created from backing image into designated pool)
resource "libvirt_volume" "cluster-node-disk" {
  name            = "cluster-node-${count.index}-disk.qcow2"
  count           = var.nodes
  size            = var.disk_size
  pool            = libvirt_pool.cluster-pool.name
  base_volume_id  = libvirt_volume.base-image.id
  format          = "qcow2"
}

// Cloud INIT: User data
data "template_file" "user_data" {
  template = file("${path.module}/templates/cloud_init.tpl")
  count    = var.nodes
  vars     = {
    username = var.username
    node_name = "cluster-node-${count.index}"
    state_path = var.state_path
    ssh_public_key = var.ssh_public_key
    network_name = libvirt_network.cluster-internal.name
  }
}

// Cloud INIT: Network config
data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.tpl")
  count    = var.nodes
}

// Create Cloud INIT: Image seed
resource "libvirt_cloudinit_disk" "cloud-init" {
  name           = "cloud-init-${count.index}.iso"
  count          = var.nodes
  pool           = libvirt_pool.cluster-pool.name
  user_data      = element(data.template_file.user_data.*.rendered, count.index)
  network_config = element(data.template_file.network_config.*.rendered, count.index)
}

// Node - VM
resource "libvirt_domain" "nodes" {
  name      = "node-${count.index}"
  count     = var.nodes
  vcpu      = 1
  memory    = var.memory
  autostart = true
  cloudinit = element(libvirt_cloudinit_disk.cloud-init.*.id, count.index)

  // NAT network
  network_interface {
    network_name   = libvirt_network.cluster-internal.name
    addresses      = [format(var.network_ip, count.index + 2)]
    wait_for_lease = true
  }

  // Bridge network (will need special setup)
  network_interface {
    network_name = libvirt_network.cluster-public.name
    mac          = format("52:54:00:00:aa:b%d", count.index)
  }

  // Disk setting (link with volume)
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

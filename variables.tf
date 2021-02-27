####### Variables #########

# Node settings
variable "nodes" {
  default = 2
}

variable "vcpu" {
  default = 1
}

variable "memory" {
  default = 256
}

variable "os_disk_size" {
  # 10,737,418,240Bytes == 10GB
  default = 10737418240
}

variable "data_disk_size" {
  # 10,737,418,240Bytes == 10GB
  default = 10737418240
}

variable "base_image" {
  default = "$HOME/img/ubuntu-20.qcow2"
}

# OS Settings
variable "username" {
  default = "user"
}

# Files Settings
variable "state_path" {
  default = "state"
}

variable "ssh_private_key" {
  default = "id_rsa"
}

variable "ssh_public_key" {
  default = "id_rsa.pub"
}

# Network Settings
variable "network_ip" {
  type    = string
  default = "192.168.123.%d"
}

variable "network_cidr" {
  type    = string
  default = "192.168.123.%d/24"
}

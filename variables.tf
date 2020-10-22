####### Variables #########

# Node settings
variable "nodes" {
  default = 2
}

variable "memory" {
  default = 256
}

variable "disk_size" {
  # 10,737,418,240Bytes == 10GB
  default = 10737418240
}

# OS Settings
variable "username" {
  default = "user"
}

variable "ssh_private_key" {
  default = "./state/id_rsa"
}

variable "ssh_public_key" {
  default = "./state/id_rsa.pub"
}

# Network settings
variable "netmask" {
  type    = string
  default = "192.168.123.%d"
}

nodes=5
vcpu=2
memory=2048
os_disk_size=10737418240
data_disk_size=21437418240
base_image="/home/najee89b/img/ubuntu-20.qcow2"

state_path="state"
username="user"
ssh_private_key="id_rsa"
ssh_public_key="id_rsa.pub"

network_ip="192.168.123.%d"
network_cidr="192.168.123.%d/24"

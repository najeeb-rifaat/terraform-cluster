#cloud-config
hostname: ${node_name}
fqdn: ${node_name}.${network_name}
manage_etc_hosts: true
users:
  - name: root
    ssh-authorized-keys:
      - ${file("${state_path}/${ssh_public_key}")}
  - name: ${username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/${username}
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - ${file("${state_path}/${ssh_public_key}")}
# only cert auth via ssh (console access can still login)
ssh_pwauth: false
disable_root: false
# update password
chpasswd:
  list: |
    ${username}:P@ssw0rd
  expire: False
# written to /var/log/cloud-init-output.log
final_message: "The system is finally up, after $UPTIME seconds"

[all]
%{ for this_domain in domains ~}
${this_domain.network_interface.0.addresses.0} ansible_user=${username} ansible_ssh_private_key_file=${base_path}/${ssh_private_key}
%{ endfor ~}

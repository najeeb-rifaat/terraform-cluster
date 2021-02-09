[nodes-internal]
%{ for this_domain in domains ~}
${this_domain.name} ansible_host=${this_domain.network_interface.0.addresses.0}
%{ endfor ~}

[nodes]
%{ for this_domain in domains ~}
${this_domain.network_interface.0.addresses.0}
%{ endfor ~}

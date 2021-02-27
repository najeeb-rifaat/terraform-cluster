# This is the full list of nodes
[unprocessed]
%{ for this_domain in domains ~}
${this_domain.name} ansible_host=${this_domain.network_interface.0.addresses.0}
%{ endfor ~}

# Add PRIMARY manager here
[manager]

# Add all workers here (first host will be elected as ancillary manager)
[worker]

[node:children]
manager
worker

# Add ingress node here
[bastian]

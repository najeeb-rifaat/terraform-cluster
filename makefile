.PHONY: build

build: generate-ssh

# Generate SSH ID if none is present
generate-ssh:
ifeq ("$(wildcard state/id_rsa)","")
	ssh-keygen -t rsa -b 4096 -f state/id_rsa -C ubuntu -N "" -q
endif

start: build
	terraform apply
	rsync -r ./playbook/** ./state/

refresh:
	terraform refresh

destroy: refresh
	terraform destroy

clean: destroy
	rm -rf state/**

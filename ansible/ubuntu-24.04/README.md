## Install Ansible
```
sudo apt-get update 
sudo apt-get install ansible-core -y
```

## Install required Ansible plugins
`ansible-galaxy install -r requirements.yml`

## Run playbook locally
`ansible-playbook playbook.yml  --ask-become-pass`

## Server roles

### Trojan VPN server
To install Trojan VPN server on Ubuntu 24.04, configure the `vars.yml` \
Then, run the playbook.
```
ansible-playbook trojan-vpn.yml --ask-become-pass
```
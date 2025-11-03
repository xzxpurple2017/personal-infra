## Install Ansible
```
sudo apt-get update 
sudo apt-get install ansible-core -y
```

## Install required Ansible plugins
`ansible-galaxy install -r requirements.yml`

## Run playbook locally
`ansible-playbook playbook.yml  --ask-become-pass`

## Install Ansible
`sudo dnf install ansible-core -y`

## Install required Ansible plugins
`ansible-galaxy install -r requirements.yml`

## Run playbook locally
`ansible-playbook playbook.yml  --ask-become-pass`

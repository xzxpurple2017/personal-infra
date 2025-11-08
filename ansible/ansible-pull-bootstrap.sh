#!/bin/bash

# philipdam8@gmail.com
# Written August 20, 2018
#
# This script runs via AWS Cloud Init to install barebones packages
# for further automation.
# Can be run manually on server or workstation.

# Tested on the following operating systems
#
# - Amazon Linux 2
# - CentOS Stream 9
# - CentOS 7
# - Ubuntu 18.04
#

# Get Ansible Vault password
read -s -p "Enter Ansible Vault password: " vault_pass_input
echo "$vault_pass_input" > .vault_pass
chmod 600 .vault_pass

echo
echo
# Determine operating system
echo "# Determining OS"
hostname_output=$( hostnamectl 2> /dev/null )

if [[ $( echo "$hostname_output" | grep -o 'Amazon Linux 2' ) = "Amazon Linux 2" ]] ; then
    os="amzn2"
elif [[ $( echo "$hostname_output" | grep -o 'CentOS Stream 9' ) = "CentOS Stream 9" ]] ; then
    os="centos-stream-9"
elif [[ $( echo "$hostname_output" | grep -o 'Ubuntu 24.04' ) = "Ubuntu 24.04" ]] ; then
    os="ubuntu-24.04"
elif [[ $( echo "$hostname_output" | grep -o 'CentOS Linux 7' ) = "CentOS Linux 7" ]] ; then
    os="centos7"
else
    os="generic"
fi

# Ansible Git repositories
# Change as needed
BOOTSTRAP_REPO="https://github.com/xzxpurple2017/personal-infra.git"
PLAYBOOK_REPO="git@github.com:xzxpurple2017/personal-infra.git"

if [[ "$os" = "amzn2" ]] ; then
    # Install EPEL if on Amazon Linux 2
    AMZN_EPEL_REPO='https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
    yum update -y
    yum install -y $AMZN_EPEL_REPO
    sleep 10
    yum install -y ansible git python2-boto python2-boto3 yq
elif [[ "$os" = "centos-stream-9" ]] ; then
    dnf update -y
    dnf install -y epel-release
    sleep 10
    dnf install -y ansible-core git yq
elif [[ "$os" = "ubuntu-24.04" ]] ; then
    apt-get update
    sleep 10
    apt-get install -y ansible-core git yq
elif [[ "$os" = "centos7" ]] ; then
    yum update -y
    yum install -y epel-release
    sleep 10
    yum install -y ansible git python2-boto python2-boto3 yq
else
    echo "---------------------------------------"
    echo "Please install Ansible and Git manually"
    echo "---------------------------------------"
    exit 0
fi
echo "# OS is $os"

# Import GPG public keys that are allowed to sign commits on this repo
declare -a gpg_pub_key_list=(
    9BA47E6D4ABD047DA5FEA59CAF802A2CCABEEDE1
)

for key in ${gpg_pub_key_list[@]} ; do
    gpg --keyserver keyserver.ubuntu.com --recv-keys ${key}
done

GH_DEPLOY_KEY="/etc/ansible/ansible-pull.key"

# Create env file
echo "# Creating Ansible environment variable file"
mkdir -p /etc/ansible
cat > /etc/ansible/ansible-pull.env <<-EOF
GIT_REPO=${PLAYBOOK_REPO}
GIT_BRANCH=main
GIT_PATH=/etc/ansible/repos/personal-infra
GIT_PRIVATE_KEY_PATH=${GH_DEPLOY_KEY}
PLAYBOOK_FILE=/etc/ansible/repos/personal-infra/ansible/${os}/main.yml
KEY_FILE=${GH_DEPLOY_KEY}
ANSIBLE_LOCAL_TEMP=/root/.ansible/tmp
ANSIBLE_REMOTE_TEMP=/root/.ansible/tmp
EOF

# Install read-only Github deploy key
echo "# Writing Github deploy key"
tmp_git_dir=$( mktemp -d -t XXXXXXXX )
git clone "${BOOTSTRAP_REPO}" ${tmp_git_dir}
ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass ansible-vault view ${tmp_git_dir}/ansible/${os}/secrets.yml | yq -r .github_readonly_deploy_key > ${GH_DEPLOY_KEY}
rm -rf ${tmp_git_dir}
rm -rf .vault_pass
echo

chmod 400 ${GH_DEPLOY_KEY}

# Install Ansible Galaxy modules
echo "# Installing Ansible Galaxy modules"
tmp_git_dir=$( mktemp -d -t XXXXXXXX )
git clone \
    -c core.sshCommand="/usr/bin/ssh \
      -o IdentitiesOnly=yes \
      -i ${GH_DEPLOY_KEY}" \
    ${PLAYBOOK_REPO} \
    ${tmp_git_dir}

ansible-galaxy install -r ${tmp_git_dir}/ansible/${os}/requirements.yml
rm -rf ${tmp_git_dir}
echo

echo "# Creating Ansible pull systemd unit file"
cat > /etc/systemd/system/ansible-pull.service <<-EOF
[Unit]
Description=Run ansible-pull
Documentation="https://github.com/xzxpurple2017/personal-infra/tree/main/ansible/${os}#readme"
Documentation="https://docs.ansible.com/ansible/latest/cli/ansible-pull.html"
After=network.target

[Service]
EnvironmentFile=/etc/ansible/ansible-pull.env
ExecStart=/bin/bash -c "(/bin/ps aux | /bin/grep '/usr/bin/ansible-pull' | /bin/grep -qv 'grep') \\
    || (/usr/bin/ansible-pull \\
    -U \$GIT_REPO \\
    -C \$GIT_BRANCH \\
    -d \$GIT_PATH \\
    -c local \\
    --verify-commit \\
    --key-file \$GIT_PRIVATE_KEY_PATH \\
    \$PLAYBOOK_FILE \\
    && rm -rf \$GIT_PATH)"
Type=oneshot
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

echo "# Creating Ansible pull systemd 15 minute timer"
cat > /etc/systemd/system/ansible-pull.timer <<-EOF
[Unit]
Description=Run ansible-pull every 15 mins
[Timer]
OnBootSec=15min
OnUnitActiveSec=15m
[Install]
WantedBy=timers.target
EOF

echo "# Adding github.com RSA fingerprint to known_hosts"
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
chmod 644 /root/.ssh/known_hosts
echo

# Start up the Ansible services
echo "# Initializing Ansible pull in systemd"
systemctl daemon-reload
systemctl enable ansible-pull.service
systemctl enable ansible-pull.timer
echo

echo "# Running Ansible - this could take a while"
echo "# NOTE: Commits must be signed with a valid PGP key"
systemctl start ansible-pull.service
systemctl start ansible-pull.timer

echo
echo '-----------------------------------------------------------------------'
echo '###################   Cloud-init script finished   ####################'
echo '-----------------------------------------------------------------------'
echo

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

# Determine operating system
echo "# Determining OS"
hostname_output=$( hostnamectl 2> /dev/null )

if [[ $( echo "$hostname_output" | grep -o 'Amazon Linux 2' ) = "Amazon Linux 2" ]] ; then
    os="amzn2"
elif [[ $( echo "$hostname_output" | grep -o 'CentOS Stream 9' ) = "CentOS Stream 9" ]] ; then
    os="centos-stream-9"
elif [[ $( echo "$hostname_output" | grep -o 'Ubuntu 18.04' ) = "Ubuntu 18.04" ]] ; then
    os="ubuntu1804"
elif [[ $( echo "$hostname_output" | grep -o 'CentOS Linux 7' ) = "CentOS Linux 7" ]] ; then
    os="centos7"
else
    os="generic"
fi

if [[ "$os" = "amzn2" ]] ; then
    # Install EPEL if on Amazon Linux 2
    AMZN_EPEL_REPO='https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
    yum update -y
    yum install -y $AMZN_EPEL_REPO
    sleep 10
    yum install -y ansible git python2-boto python2-boto3
elif [[ "$os" = "centos-stream-9" ]] ; then
    dnf update -y
    dnf install -y epel-release
    sleep 10
    dnf install -y ansible git #python3-boto3
elif [[ "$os" = "ubuntu1804" ]] ; then
    apt-get update
    sleep 10
    apt-get install -y ansible git python-boto python-boto3
elif [[ "$os" = "centos7" ]] ; then
    yum update -y
    yum install -y epel-release
    sleep 10
    yum install -y ansible git python2-boto python2-boto3
else
    echo "---------------------------------------"
    echo "Please install Ansible and Git manually"
    echo "---------------------------------------"
    exit 0
fi
echo "# OS is $os"

echo "# Creating Ansible environment variable file"
cat > /etc/ansible/ansible-pull.env <<-EOF
GIT_REPO=git@github.com:xzxpurple2017/personal-infra.git
GIT_BRANCH=main
GIT_PATH=/etc/ansible/repos/personal-infra
GIT_PRIVATE_KEY_PATH=/etc/ansible/ansible-pull.key
PLAYBOOK_FILE=/etc/ansible/repos/personal-infra/ansible/${os}/main.yml
KEY_FILE=/etc/ansible/ansible-pull.key
ANSIBLE_LOCAL_TEMP=/root/.ansible/tmp
ANSIBLE_REMOTE_TEMP=/root/.ansible/tmp
EOF

# Install read-only Github deploy key
echo "# Writing Github deploy key"
cat > /etc/ansible/ansible-pull.key <<-EOF
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
EOF

chmod 400 /etc/ansible/ansible-pull.key

echo "# Creating Ansible pull systemd unit file"
cat > /etc/systemd/system/ansible-pull.service <<-EOF
[Unit]
Description=Run ansible-pull
After=network.target

[Service]
EnvironmentFile=/etc/ansible/ansible-pull.env
ExecStart=/bin/bash -c "(/bin/ps aux | /bin/grep '/usr/bin/ansible-pull' | /bin/grep -qv 'grep') || /usr/bin/ansible-pull \\
  -U \$GIT_REPO \\
  -C \$GIT_BRANCH \\
  -d \$GIT_PATH \\
  -c local \\
  --key-file \$GIT_PRIVATE_KEY_PATH \\
  \$PLAYBOOK_FILE"
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

# Start up the Ansible services
echo "# Initializing Ansible pull in systemd - this could take a while"
systemctl daemon-reload
systemctl enable ansible-pull.service
systemctl enable ansible-pull.timer
systemctl start ansible-pull.service
systemctl start ansible-pull.timer

echo
echo '-----------------------------------------------------------------------'
echo '###################   Cloud-init script finished   ####################'
echo '-----------------------------------------------------------------------'
echo

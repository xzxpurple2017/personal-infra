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
REPLACE ME
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

# Ubuntu 24.04 Server Configuration

Ansible playbooks for configuring an Ubuntu 24.04 server with SSH hardening and Trojan VPN.

## Prerequisites

### Install Ansible
```bash
sudo apt-get update 
sudo apt-get install ansible-core -y
```

### Install required Ansible collections
```bash
ansible-galaxy install -r requirements.yml
```

## Configuration

### 1. Update Variables
Edit `vars.yml` to configure:
- Domain name
- Email address for SSL certificates
- SSH public key
- Trojan server settings

### 2. Optional: Manage Secrets
For sensitive data, use `secrets.yml` (encrypted with ansible-vault):
```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
```

## Usage

### Quick Start - Run Everything
Deploy complete server configuration (SSH + Trojan VPN):
```bash
ansible-playbook main.yml
```

### Individual Playbooks

#### SSH Security Configuration
Configure SSH server with key-based authentication and disable password login:
```bash
ansible-playbook ssh.yml
```

#### Trojan VPN Server
Install and configure Trojan VPN with SSL certificates:
```bash
ansible-playbook trojan-vpn.yml
```

## Project Structure

```
.
├── main.yml                    # Main orchestration playbook
├── ssh.yml                     # SSH hardening playbook
├── trojan-vpn.yml             # Trojan VPN setup playbook
├── vars.yml                    # Configuration variables
├── secrets.yml                 # Encrypted secrets (optional)
├── ansible.cfg                 # Ansible configuration
├── hosts.ini                   # Inventory file
├── requirements.yml            # Ansible dependencies
├── handlers/
│   └── main.yml               # Service handlers (restart/reload)
└── templates/
    ├── sshd_config.j2         # SSH server configuration
    ├── trojan-config.json.j2  # Trojan server configuration
    ├── nginx-site.conf.j2     # Nginx configuration
    └── letsencrypt-renewal.conf.j2  # SSL renewal configuration
```

## Features

### SSH Security
- ✅ Key-based authentication
- ✅ Password authentication disabled
- ✅ Cloud-init configuration handled
- ✅ Automated key deployment

### Trojan VPN
- ✅ Automated SSL certificate (Let's Encrypt)
- ✅ Nginx on port 80 (HTTP)
- ✅ Trojan on port 443 (HTTPS/VPN)
- ✅ Automatic certificate renewal with service reload
- ✅ Secure password generation
- ✅ UFW firewall configuration

## Important Notes

1. **Certificate Management**: Certificates use webroot authentication via Nginx on port 80
2. **Port Configuration**: 
   - Port 22: SSH
   - Port 80: HTTP (Nginx)
   - Port 443: HTTPS/VPN (Trojan)
3. **Password Storage**: Trojan password saved to `/root/trojan-password.txt`
4. **Automatic Renewal**: Certbot renewal configured with deploy hook to reload Trojan

## Troubleshooting

### Check Service Status
```bash
systemctl status sshd
systemctl status nginx
systemctl status trojan
```

### Test Certificate Renewal
```bash
certbot renew --dry-run
```

### View Trojan Password
```bash
cat /root/trojan-password.txt
```

### Check Nginx Configuration
```bash
nginx -t
```
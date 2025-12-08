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

### 1. Add Your Host to host_vars.yml

First, get your system UUID:
```bash
sudo dmidecode -s system-uuid
```

Then edit `host_vars.yml` and add your system configuration:
```yaml
hosts:
  your-system-uuid-here:
    domain_name: "your-domain.com"
    ssl_email: "your-email@example.com"
    ssh_public_key: "ssh-rsa YOUR_PUBLIC_KEY_HERE"
    # Specify which playbooks to run on this host
    playbooks:
      - base       # Install required packages
      - ssh        # Configure SSH security
      - trojan-vpn # Set up Trojan VPN server
```

**Note**: The `playbooks` list allows you to control which playbooks run on each host. This is useful when:
- Some servers don't need VPN capabilities (omit `trojan-vpn`)
- You want to manage only SSH on certain hosts (use only `base` and `ssh`)
- Different servers have different roles in your infrastructure

The playbooks will automatically detect the system UUID at runtime and:
1. Load the appropriate configuration
2. Check if they should run on this host
3. Skip execution if not in the playbooks list

This allows you to manage multiple servers with different configurations from a single playbook repository.

### 2. Update Default Variables (Optional)
Edit `vars.yml` to modify default settings like:
- Package lists
- UFW rules
- Trojan server settings (ports, paths)
- SSH configuration

### 3. Optional: Manage Secrets
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
├── vars.yml                    # Default configuration variables
├── host_vars.yml              # Host-specific configuration (by system UUID)
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

## How It Works

The playbooks use **system UUID detection** to automatically load the correct configuration for each server:

1. When you run the playbook, it executes `dmidecode -s system-uuid` to get the unique hardware identifier
2. It looks up this UUID in `host_vars.yml` to find the host-specific configuration
3. It loads the appropriate `domain_name`, `ssl_email`, and `ssh_public_key` for that server
4. If the UUID is not found, the playbook fails with a helpful error message

This approach allows you to:
- ✅ Manage multiple servers with one playbook repository
- ✅ Avoid accidentally deploying the wrong configuration to a server
- ✅ Keep host-specific settings organized and version controlled
- ✅ Run the same playbook on different servers without manual changes
- ✅ Selectively enable/disable playbooks per host (e.g., VPN only on some servers)
- ✅ Maintain different server roles with the same codebase

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
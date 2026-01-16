# VS Code Server Deployment with Ansible

This repository deploys a hardened, production-grade VS Code Server stack on Ubuntu using:

- Docker Engine (official upstream)
- Nginx reverse proxy
- Let’s Encrypt TLS (Certbot)
- UFW firewall
- Automated backups
- Health-checked containers

---

## Requirements

- Ansible 2.14+
- Ubuntu 22.04+
- Domain A record pointing to host
- Open ports: 22, 80, 443

---

## Setup

### 1. Clone
```bash
git clone <repo-url>
cd vscode-server-deploy

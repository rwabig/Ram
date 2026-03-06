<div align="center">

# 🐏 RAM
### Production-Grade Infrastructure as Code

**Opinionated • Secure • Repeatable • Hardened by Default**

Ansible-powered deployment stacks for Docker edge gateways, developer environments, and modern application platforms — built for Ubuntu 24.04 and real-world production systems.

</div>

---

## What is Ram?

**Ram** is a curated infrastructure repository focused on **production-ready deployment patterns**, not demos or toy examples. Every stack is designed to be secure by default, easy to audit, and safe to evolve — using **Ansible as the control plane** and **Docker as the execution layer**.

This repo exists to eliminate:
- Snowflake servers
- Undocumented infra decisions
- Fragile copy-paste stacks
- Security-last configurations

## Core Stacks

- 🔐 **Edge Gateway**
  - NGINX reverse proxy
  - Let’s Encrypt automation
  - Hardened TLS and routing

- 🧑‍💻 **VS Code Server Stack**
  - Secure remote development environments
  - Team-friendly workflows

- 🚀 **Application Platform**
  - Apache 2.4
  - PHP 8.2
  - PostgreSQL 17 + PostGIS
  - Production-grade container layouts

- 🧠 **Agent Zero (Multi-tenant, Private-by-Default)**
  - One Agent Zero container per user (true tenant isolation)
  - Authelia SSO/MFA at the edge (NGINX `auth_request`)
  - WireGuard VPN to privatize access (Lightsail-friendly)
  - Works with the Edge Gateway auto-discovery labels

---

## Agent Zero (multi-tenant) — production workflow

### 1) Put secrets in Ansible Vault

Copy the vault template and encrypt it:

```bash
cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml
ansible-vault encrypt ansible/group_vars/all/vault.yml
```

The example includes:
- WireGuard peers (optionally with BYO keys)
- Authelia JWT/session/storage secrets + users
- Agent Zero per-user passwords

### 2) Deploy order

```bash
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/01-docker.yml
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/02-edge-gateway.yml
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/05-wireguard.yml --ask-vault-pass
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/06-authelia.yml --ask-vault-pass
ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/07-agent-zero.yml --ask-vault-pass
```

### 3) WireGuard client config generator

The WireGuard role can generate **ready-to-import** client configs for each peer and fetch them to:

`ansible/artifacts/wireguard/<peer>.conf`

This is ideal when you switch laptops frequently (one peer per laptop).

### 4) Rolling upgrade Agent Zero

Use the safe rolling upgrade playbook:

```bash
ansible-playbook -i ansible/inventory/production.ini \
  ansible/playbooks/08-agent-zero-upgrade.yml \
  --ask-vault-pass \
  -e agent_zero_target_image='agent0ai/agent-zero:latest'
```

It creates per-user backups under:
`/opt/agent-zero/backups/<user>/a0usr-<timestamp>.tar.gz`

### 5) Lightsail SSH keys (zone-specific) + VPN approach

Lightsail can manage SSH keys per zone. A clean production approach is:
- Use WireGuard for **private access** to the host
- Restrict SSH (22) to the VPN subnet (see `wireguard_restrict_ssh_to_vpn`)
- Add your own long-lived SSH key to the instance (so you don't rely on zone keys)


## Philosophy

- **Secure by default**
- **Minimal but complete**
- **Composable and auditable**
- **Built for real systems, not tutorials**
- **Infrastructure is documentation**

## Roadmap

Ram will expand into:
Kubernetes, observability, CI/CD pipelines, data platforms, edge compute, and more — all built with the same production discipline.

---

If you build infrastructure that must *survive reality*, Ram is for you 🐏


## New additions

- CoreDNS over WireGuard for internal app DNS (`ansible/playbooks/03a-coredns.yml`)
- Multi-tenant code-server in the existing `vscode` role via `vscode_users`
- WireGuard client configs can now include `DNS = 10.8.0.1` when `wireguard_client_dns` is set

Ram/
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   └── production.ini
    ├── playbooks/
    │   ├── 01-docker.yml
    │   └── 02-edge-gateway.yml
    └── roles/
        ├── docker/
        │   ├── tasks/main.yml
        │   └── README.md
        └── edge_gateway/
            ├── defaults/main.yml
            ├── tasks/main.yml
            ├── templates/
            │   ├── docker-compose.yml.j2
            │   ├── nginx.conf.j2
            │   └── site.conf.j2
            └── README.md


DEPLOYMENT ORDER

cd Ram/ansible

ansible-playbook playbooks/01-docker.yml
ansible-playbook playbooks/02-edge-gateway.yml

What You Now Have

✔ Clean Docker installation
✔ Pure containerised gateway
✔ Multi-app routing
✔ Fully modular
✔ No coupling
✔ No hardcoding

⚠️ Next Phase (When Ready)

Phase 2 will include:

Automatic certificate issuance

Auto-renew cron container

Zero-downtime reload

Per-app dynamic TLS provisioning

Security headers hardening

Rate limiting

Optional Authelia integration

You now have a real foundation.

...................................................

CLEAN FIX (Production Correct Way)

We must:

Remove old Docker repo entries

Remove old keyrings

Re-add cleanly

Use proper Ansible modules (not shell hacks)

🔥 Step 1 — Manually Inspect (Run This)

On the server:

ls /etc/apt/sources.list.d/


You will likely see something like:

docker.list
docker-ce.list


Also check:

cat /etc/apt/sources.list.d/docker.list
cat /etc/apt/sources.list.d/docker-ce.list


And:

ls /etc/apt/keyrings/


You will probably see both:

docker.gpg
docker.asc

🧹 Quick Manual Cleanup (Safe)

Run:

sudo rm -f /etc/apt/sources.list.d/docker*.list
sudo rm -f /etc/apt/keyrings/docker.*
sudo apt update


This removes conflicting definitions.

🧠 Now — We Fix Your Docker Role Properly

We will replace the shell-based repo addition with the correct Ansible modules.

Replace your entire roles/docker/tasks/main.yml with this:

✅ NEW Production-Safe Docker Role
---
# Production-safe Docker installation for Ubuntu 24.04+

- name: Install required packages
  apt:
    name:
      - ca-certificates
      - curl
      - gnupg
    update_cache: yes

- name: Ensure keyrings directory exists
  file:
    path: /etc/apt/keyrings
    state: directory
    mode: '0755'

- name: Download Docker GPG key
  get_url:
    url: https://download.docker.com/linux/ubuntu/gpg
    dest: /etc/apt/keyrings/docker.asc
    mode: '0644'

- name: Add Docker repository
  apt_repository:
    repo: >
      deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc]
      https://download.docker.com/linux/ubuntu
      {{ ansible_distribution_release }} stable
    filename: docker
    state: present

- name: Update apt cache
  apt:
    update_cache: yes

- name: Install Docker packages
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present

- name: Enable and start Docker
  systemd:
    name: docker
    enabled: yes
    state: started

🚀 Then Re-run
ansible-playbook playbooks/01-docker.yml

Why This Fix Works

Your old version:

Used shell

Created .gpg

But Ubuntu previously had .asc

APT saw two different Signed-By keys

New version:

Uses .asc consistently

Uses apt_repository

Fully idempotent

No duplication

Clean noble-compatible

⚠️ Important

If Docker was previously partially installed, also check:

docker --version


If it already exists and works, Ansible will simply enforce consistency.

🧠 Engineering Note (Opinion)

Never use shell for apt repositories in production Ansible.

Always use:

get_url

apt_repository

apt

Shell-based repo management is fragile on Ubuntu ≥22.04.

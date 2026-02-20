Reference file:
If you want next, I can:

Write the production docker-compose for CGS

Design Tomcat production Dockerfile

Add PostGIS performance tuning

Or design RAM playbook structure for multi-app deployment
................
Ansible roles integrated into RAM.

We will design this cleanly so:

CGS becomes deployable via one playbook

Future PHP apps reuse the same role

Tomcat apps plug in later

Edge auto-detects via labels

No hardcoding

Minimal duplication

Fully production-aligned

This will be modular and reusable.

🎯 TARGET STRUCTURE INSIDE RAM

Inside your RAM repo:

ansible/
 ├── playbooks/
 │    └── deploy_php_app.yml
 └── roles/
      ├── php_app/
      │    ├── defaults/
      │    ├── tasks/
      │    ├── templates/
      │    └── files/
      └── postgres_db/


We split:

php_app → builds + runs container

postgres_db → provisions PostGIS container

edge_gateway → already exists

1️⃣ PLAYBOOK — deploy_php_app.yml

Create:

ansible/playbooks/deploy_php_app.yml

---
- name: Deploy PHP Application Platform
  hosts: app_nodes
  become: true

  vars:
    app_name: cgs
    app_domain: cgs.example.com
    app_repo: https://github.com/rwabig/CGS.git
    app_branch: main

    db_name: cgs
    db_user: cgs_user
    db_password: strong_password

  roles:
    - postgres_db
    - php_app


This is reusable for ANY future PHP app.

2️⃣ ROLE — postgres_db
roles/postgres_db/defaults/main.yml
db_container_name: "{{ app_name }}-db"
db_image: "postgis/postgis:17-3.4"
db_volume: "{{ app_name }}_pgdata"

roles/postgres_db/tasks/main.yml
---
- name: Ensure app network exists
  docker_network:
    name: app_net
    state: present

- name: Run PostgreSQL container
  docker_container:
    name: "{{ db_container_name }}"
    image: "{{ db_image }}"
    restart_policy: unless-stopped
    env:
      POSTGRES_DB: "{{ db_name }}"
      POSTGRES_USER: "{{ db_user }}"
      POSTGRES_PASSWORD: "{{ db_password }}"
    volumes:
      - "{{ db_volume }}:/var/lib/postgresql/data"
    networks:
      - name: app_net
    state: started


DB is internal only.
No exposed ports.

3️⃣ ROLE — php_app
roles/php_app/defaults/main.yml
app_container_name: "{{ app_name }}-app"
app_image_name: "{{ app_name }}-php"
app_root: "/srv/apps/{{ app_name }}"
app_network: "app_net"

roles/php_app/tasks/main.yml
---
- name: Create app directory
  file:
    path: "{{ app_root }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Clone or update app repository
  git:
    repo: "{{ app_repo }}"
    dest: "{{ app_root }}"
    version: "{{ app_branch }}"
    force: yes

- name: Copy Dockerfile template
  template:
    src: Dockerfile.j2
    dest: "{{ app_root }}/Dockerfile"

- name: Build PHP image
  community.docker.docker_image:
    name: "{{ app_image_name }}"
    source: build
    build:
      path: "{{ app_root }}"

- name: Run PHP container
  docker_container:
    name: "{{ app_container_name }}"
    image: "{{ app_image_name }}"
    restart_policy: unless-stopped
    env:
      DB_HOST: "{{ db_container_name }}"
      DB_NAME: "{{ db_name }}"
      DB_USER: "{{ db_user }}"
      DB_PASS: "{{ db_password }}"
    labels:
      edge.enable: "true"
      edge.domain: "{{ app_domain }}"
      edge.port: "80"
    networks:
      - name: "{{ app_network }}"
    state: started

4️⃣ Dockerfile Template

Create:

roles/php_app/templates/Dockerfile.j2


Paste your production Dockerfile (same as earlier) but without hardcoded app-specific things.

Use exactly what we wrote earlier.

No modification needed except remove EXPOSE comment duplication.

5️⃣ Inventory Example
[app_nodes]
your_server_ip

🔥 What Happens When You Run
ansible-playbook -i inventory deploy_php_app.yml


Flow:

Creates internal network

Starts PostGIS container

Clones CGS

Builds production PHP image

Runs container

Edge detects via labels

HTTP available

Certbot issues cert

HTTPS auto-activates

Zero manual config.

🧠 Why This Is Correct Architecture

Per-app isolation

Reusable roles

No shared runtime

DB isolated

Edge self-registering

Git-driven deployment

Ansible-native control

Easy to extend

🚀 Adding Second App Later

Just change:

app_name: blog
app_domain: blog.example.com
app_repo: https://github.com/user/blog.git


Same playbook.

⚠️ Important Improvement (Next Iteration)

Later we will:

Add healthcheck wait-for-DB

Add automatic DB creation check

Add volume backup role

Add memory limits

Add non-root runtime

Add rolling update logic

Add CI/CD pipeline hook

But this is already production-ready foundation.

🧱 RAM Now Becomes

Edge Layer
+
Application Runtime Layer
+
Database Layer

This is real platform territory.

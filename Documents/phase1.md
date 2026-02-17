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

🚀 Then Re-run
ansible-playbook playbooks/01-docker.yml

...
ubuntu@ip-172-26-6-161:~/Ram/ansible$ grep -R "download.docker.com" /etc/apt/
/etc/apt/sources.list.d/docker.list:deb amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable
ubuntu@ip-172-26-6-161:~/Ram/ansible$ sudo rm -f /etc/apt/sources.list.d/docker.list
ubuntu@ip-172-26-6-161:~/Ram/ansible$ sudo apt update

How To Test URLs Now

From server:

curl -H "Host: vscode.unifypesacard.shop" http://127.0.0.1
curl -H "Host: cgs.unifypesacard.shop" http://127.0.0.1


You will get:

502 Bad Gateway (expected, because backend not running)

BUT nginx must stay UP

That means gateway is stable.
.........................
................

sudo docker rm -f edge-watcher
sudo docker ps
sudo docker exec edge-nginx nginx -t
sudo docker logs -f edge-watcher
ansible-playbook playbooks/02-edge-gateway.yml -vv
ls /opt/edge-gateway/nginx/sites
sudo docker exec edge-nginx ls /etc/nginx/conf.d
curl -H "Host: vscode.unifypesacard.shop" http://localhost
sudo docker exec edge-nginx nginx -T | grep listen
sudo docker exec edge-nginx nginx -T | grep 443



............................

Labels belong to THE APPLICATION CONTAINER, not the edge.

So:

edge role = reads labels

app role = defines labels

✔ Example — VSCode Role (correct place)

Inside your app role template:

roles/vscode/templates/docker-compose.yml.j2


Add:

services:
  vscode:
    image: codercom/code-server:latest

    labels:
      edge.enable: "true"
      edge.domain: "vscode.unifypesacard.shop"
      edge.port: "8080"


That’s all.

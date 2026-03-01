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

sudo docker rm -f edge-watch
sudo docker ps
sudo docker exec edge-nginx nginx -t
sudo docker logs -f edge-watcher
ansible-playbook playbooks/02-edge-gateway.yml -vv
ls /opt/edge-gateway/nginx/sites
sudo docker exec edge-nginx ls /etc/nginx/conf.d
sudo ls /opt/edge-gateway/certbot/conf/live/
curl -H "Host: vscode.unifypesacard.shop" http://localhost
sudo docker exec edge-nginx nginx -T | grep listen
sudo docker exec edge-nginx nginx -T | grep 443
cd /opt/edge-gateway
sudo ./init-letsencrypt.sh
sudo docker restart edge-nginx
sudo docker network ls
sudo docker inspect cgs-app | grep NetworkMode
sudo docker inspect edge-nginx | grep NetworkMode
sudo docker inspect cgs-app --format='{{json .NetworkSettings.Networks}}'
sudo docker exec -it cgs-app ls -la /var/www/html
docker inspect edge-watcher | grep -A 20 Mounts
docker ps --filter label=edge.enable=true

sudo docker restart edge-watcher
sudo docker logs -f edge-watcher

# What is app_root actually pointing to on the server?
ls -la {{ app_root }}
# values
# app_name: cgs
# app_root: "/srv/apps/{{ app_name }}"
ls -la /srv/apps/cgs
# Confirm What Docker Thinks:
sudo docker inspect cgs-app | grep -A20 Mounts
grep VOLUME /srv/apps/cgs/Dockerfile

sudo docker inspect cgs-app | grep -A20 Labels
sudo docker inspect edge-watcher | grep -A10 Mounts
sudo docker ps --filter "label=edge.enable=true"
sudo docker inspect cgs-app | grep edge.enable
sudo docker inspect cgs-app | grep -A20 edge-net
sudo docker inspect cgs-app | grep -A10 Labels
sudo docker network connect edge-net cgs-app
sudo docker inspect cgs-app
sudo docker inspect cgs-app --format '{{json .NetworkSettings.Networks}}'
sudo docker exec -it edge-watcher sh
# inside edge-watcher
docker ps --format '{{.Names}} {{.Labels}}'

sudo docker rm -f edge-nginx edge-watcher edge-certbot
sudo rm -rf /opt/edge-gateway/nginx/sites/*
ansible-playbook playbooks/02-edge-gateway.yml

sudo docker exec edge-nginx nginx -t

# Execution Flow (How You’ll Use This)
ansible-playbook playbooks/01-docker.yml
ansible-playbook playbooks/02-edge-gateway.yml
ansible-playbook playbooks/03-vscode.yml
ansible-playbook playbooks/04-deploy-php-app.yml
ansible-playbook playbooks/05-wireguard.yml
ansible-playbook playbooks/09-wireguard-peer.yml -e wg_peer_action=add -e wg_peer_name=laptop_station_1
ansible-playbook playbooks/06-authelia.yml

# or
ansible-playbook -i inventory 04-deploy-php-app.yml

&&&&&&&&&&&&&&&&&&&&&&

5) What you should do next (safe test flow)
A) Run the base WireGuard install
cd ~/Ram/ansible
ansible-playbook playbooks/05-wireguard.yml
B) Add a peer

(using the new ready-to-paste 09-wireguard-peer.yml you just got)

ansible-playbook playbooks/09-wireguard-peer.yml -e wg_peer_action=add -e wg_peer_name=laptop1
C) Copy the generated config to your laptop

From the server, view where it landed:

ls -la /etc/wireguard/client-configs/
ls -la ~/Ram/ansible/artifacts/wireguard/

Then download laptop1.conf to your laptop (scp, sftp, etc.).

6) Laptop initial setup (quick)
Windows/macOS

Install WireGuard app

Import laptop1.conf

Activate tunnel

Ubuntu laptop
sudo apt update
sudo apt install wireguard
sudo cp laptop1.conf /etc/wireguard/laptop1.conf
sudo wg-quick up laptop1

Test:

ping 10.8.0.1

Only after this works, consider:

wireguard_restrict_ssh_to_vpn: true

If you paste the values you’re using for these vars (from your group_vars/vault):

wireguard_interface

wireguard_endpoint

wireguard_client_configs_dir

wireguard_client_allowed_ips

…I’ll sanity-check them to prevent the most common misconfig (endpoint/allowed IPs).

.................................

That error is purely permissions/ownership:

/home/ubuntu/Ram/ansible/group_vars/all is owned by root (or not writable by ubuntu), so your ubuntu user can’t write/encrypt files there.

✅ Fix it (pick one)
Option A (recommended): change ownership of the repo to ubuntu

This is usually best since you’re working as ubuntu.

sudo chown -R ubuntu:ubuntu ~/Ram

Then retry:

cd ~/Ram/ansible
ansible-vault encrypt group_vars/all/vault.yml
Option B: keep repo owned by root, run vault as sudo

If you intentionally want root ownership:

sudo ansible-vault encrypt ~/Ram/ansible/group_vars/all/vault.yml

(But then editing files will keep requiring sudo — annoying.)

Option C: fix only the group_vars folder
sudo chown -R ubuntu:ubuntu ~/Ram/ansible/group_vars
After fixing permissions: verify the vault loads

Once encrypted, test that Ansible can see the variable:

cd ~/Ram/ansible
ansible localhost -m debug -a "var=wireguard_endpoint" --ask-vault-pass

You should see:

wireguard_endpoint: vpn.unifypesacard.shop:51820

Then run the peer playbook:

ansible-playbook playbooks/09-wireguard-peer.yml \
  -e wg_peer_action=add -e wg_peer_name=laptop_station_1 \
  --ask-vault-pass
Quick note on why ownership became root

You created/edited some repo files earlier using sudo (or an Ansible task wrote files into the repo path), which caused root ownership. Fixing ownership once avoids repeated permission errors.

If you run ls -la ~/Ram/ansible/group_vars and paste the first few lines, I can tell you exactly which directories are root-owned.

&&&&&&&&&&&&&&&&&&&&&&&&&&&&&



///////////

do we still need to install composer in cgs-app through vender or to cross check if composer is there!

Rebuild cleanly:

docker rm -f cgs-app
docker rmi cgs-php
ansible-playbook playbooks/03-php-app.yml

Then verify:

docker exec -it cgs-app ls vendor

If vendor exists → problem solved.

*************
Or manually issue cert once:

docker exec -it edge-certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d cgs.unifypesacard.shop \
  --email your@email.com \
  --agree-tos --no-eff-email

Then restart nginx.

........................
//////////////////
If you'd like next, we can properly re-enable Docker label auto-discovery and make onboarding fully automatic.
////////////////
If you want, next step we can:

Convert edge-watcher into real Docker event listener

Or harden TLS bootstrap logic

Or implement wildcard certificate strategy
///////////////
If you want next — I can give you:

🔥 Cloud-grade watcher upgrade
(no polling, true Docker event stream, safe reload logic)

which will make this architecture extremely professional.
//////////////////
If you want — next reply I’ll show the final watcher architecture that makes onboarding literally automatic.
////////////////
Phase 3.5 ELITE Watcher

Where new containers appear and instantly become live — no playbook rerun.

If you want, next I’ll show:

the final watcher design that makes onboarding literally automatic.
////////////
Phase 3.5 ELITE Watcher

Where new containers appear and instantly become live — no playbook rerun.

If you want, next I’ll show:

the final watcher design that makes onboarding literally automatic.
//////////////////
Next (you’re VERY close)

Your edge stack is now stable enough to move to:

⭐ Phase 4 — True Cloud Edge Mode

Where:

new app starts

watcher detects instantly

nginx updates live

TLS auto-issued

ZERO Ansible reruns.

If you want, next I’ll show you the final architecture shift that turns this into an almost Kubernetes-like edge layer — but still simple Docker + Ansible.
/////////////////////////

Next (REAL POWER MOVE)

You are one small step from:

Phase 4 — Self-healing Edge

Where:

watcher + labels = zero onboarding effort

apps appear automatically

certificates auto-issued

zero playbook runs after deployment

If you want, next I’ll show the single architectural adjustment that turns this into enterprise-grade edge orchestration without adding complexity.
/////////////
Improvements made

Ensures base directory exists (not just /data)

Ensures /apps directory exists before writing

Added file permissions explicitly

Prevented false-positive "changed" on docker compose

Kept your fallback registration intact

⚠️ IMPORTANT ARCHITECT NOTE

If you're using Docker label auto-discovery,
this fallback app registration is no longer required.

The true ELITE version removes this block entirely and relies on labels.

For now, I kept it (as requested).
///////////////////////
Next Strategic Move

You are one step from:

Phase 4 — True Cloud Edge Mode

Where:

static app registry removed

label-based TLS auto-issue added

certificate issuance fully automated

no manual onboarding exists

If you want, next we remove the legacy app registry completely and convert your stack into a pure label-driven edge controller.
////////////////////








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

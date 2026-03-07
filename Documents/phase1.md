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
ansible-playbook playbooks/06-authelia.yml
ansible-playbook playbooks/07-agent-zero.yml
ansible-playbook playbooks/08-agent-zero-upgrade.yml
.....
ansible-playbook playbooks/09-wireguard-peer.yml -e wg_peer_action=add -e wg_peer_name=laptop_station_1
or
ansible-playbook playbooks/09-wireguard-peer.yml \
  -e wg_peer_action=add -e wg_peer_name=laptop_station_1 \
  --ask-vault-pass
or
ansible-playbook playbooks/09-wireguard-peer.yml \
  -e wg_peer_action=add -e wg_peer_name=laptop_station_1 \
  -e wg_peer_ip=10.8.0.10 \
  --ask-vault-pass

ansible-playbook playbooks/10-agent-zero-restore.yml

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

.....................................

Nice — that run is clean now. ✅

A few important confirmations based on the output:

The peer was added (WireGuard config updated).

Client config was rendered at:

/etc/wireguard/client-configs/laptop_station_1.conf

Fetch steps were skipped (expected since you’re running Ansible locally on the server and/or your conditions disabled fetch).

Now you just need to install the client and test handshake.

1) Get the client config file onto your laptop

On the server:

sudo ls -la /etc/wireguard/client-configs/laptop_station_1.conf
sudo cat /etc/wireguard/client-configs/laptop_station_1.conf

Copy it to your home dir so it’s easy to download:

sudo cp /etc/wireguard/client-configs/laptop_station_1.conf ~/
sudo chown ubuntu:ubuntu ~/laptop_station_1.conf
chmod 600 ~/laptop_station_1.conf

Then download laptop_station_1.conf to your laptop using SCP/SFTP.

2) Install WireGuard on the laptop and import config
Windows / macOS

Install WireGuard app

Import laptop_station_1.conf

Activate tunnel

Ubuntu laptop
sudo apt update
sudo apt install wireguard
sudo cp laptop_station_1.conf /etc/wireguard/laptop_station_1.conf
sudo wg-quick up laptop_station_1
3) Test connectivity (server side + laptop side)
On laptop (after tunnel up):
ping 10.8.0.1
On server:
sudo wg show

You should see a latest handshake timestamp for laptop_station_1 once the laptop connects.

4) About “Restart WireGuard” handler

Your playbook updated config with blockinfile, but the recap shows no “changed”. That’s because the peer already existed with same content (idempotent) OR the file content didn’t change. That’s fine.

If you ever add a new peer and want to ensure the service reloads, you can manually restart:

sudo systemctl restart wg-quick@wg0
5) Next hardening step (only after laptop handshake works)

Once you confirm the laptop can connect to VPN and you can SSH through it:

Set in vault/group_vars:

wireguard_restrict_ssh_to_vpn: true

Then run:

ansible-playbook playbooks/05-wireguard.yml --ask-vault-pass

That will prevent public SSH and make management VPN-only.

If you paste the contents of ~/laptop_station_1.conf (you can redact the PrivateKey), I’ll verify Endpoint, AllowedIPs, and the address are correct before you import it.

............................

To edit an encrypted ansible-vault file, you use ansible-vault edit — never open it with nano/vim directly.

✅ Edit your encrypted vault.yml

From inside your ansible directory:

cd ~/Ram/ansible
ansible-vault edit group_vars/all/vault.yml

It will:

Ask for vault password

Decrypt to a temporary file

Open your default editor

Re-encrypt automatically when you save & exit

🔧 If it says editor not set

Set your editor first (example: nano):

export EDITOR=nano

Or permanently:

echo 'export EDITOR=nano' >> ~/.bashrc
source ~/.bashrc

Then run the edit command again.

🧪 Verify after editing

After saving, confirm Ansible sees the value:

ansible localhost -m debug -a "var=wireguard_endpoint" --ask-vault-pass
🔐 Other useful vault commands
View without editing
ansible-vault view group_vars/all/vault.yml
Re-encrypt (if you accidentally decrypted it)
ansible-vault encrypt group_vars/all/vault.yml
Change vault password
ansible-vault rekey group_vars/all/vault.yml
⚠️ Important Production Tip

Never:

nano vault.yml

If you save it manually while encrypted, you will corrupt it.

Always use ansible-vault edit.

If you'd like, I can also show you how to switch to a .vault_pass file so you don’t need --ask-vault-pass every time (cleaner for production).

.................................

That can happen for two common reasons:

You’re not actually hitting the server over public SSH anymore — your SSH client is routing through the WireGuard tunnel (even if you typed the public hostname/IP).

UFW didn’t end up restricting port 22, or there’s another firewall path allowing it (Lightsail firewall, iptables rules, sshd listening on another port/interface).

Let’s verify which case it is, then apply the right fix.

1) Confirm whether your SSH is going over WireGuard or public internet
On your laptop, while connected to WireGuard:

Run:

ssh -v ubuntu@<your-server-host-or-ip>

Look for the line like:

Connecting to ... port 22
and note the IP it says it’s connecting to.

Also run:

ip route get <server-public-ip>

If it routes via your WireGuard interface (like dev wg0), then you’re SSHing through VPN already.

On the server, check the SSH client source IP

Run this on the server while you connect:

sudo ss -tnp | grep ':22'

You’ll see a line like:

ESTAB ... <server>:22 <client_ip>:<port>

If <client_ip> is 10.8.0.x, then SSH is already VPN-only in practice.

2) Check whether the UFW restriction is actually applied

Run on the server:

sudo ufw status numbered

You want to see something like:

22 ALLOW IN 10.8.0.0/24 (good)
and NOT:

22 ALLOW IN Anywhere (bad)

Also run:

sudo ufw status verbose

If you still see “Anywhere” allowed on 22, your playbook didn’t change it (or another rule is overriding it).

Apply the restriction explicitly (manual, immediate)

If you want to enforce it now:

sudo ufw delete allow 22/tcp
sudo ufw allow from 10.8.0.0/24 to any port 22 proto tcp
sudo ufw reload
sudo ufw status numbered

(This assumes your VPN subnet is 10.8.0.0/24.)

3) Lightsail firewall may still allow public SSH (that’s separate)

Even if UFW blocks it, Lightsail can still show port 22 “open” at the edge. Lightsail doesn’t override UFW; it just controls what reaches your VM.

To be truly “SSH only via VPN”, set Lightsail firewall to:

allow UDP 51820

remove/restrict TCP 22 (optional, but recommended once you’re confident)

If you can’t remove 22 because you might lose access, keep it open but rely on UFW.

4) Make sure your Ansible actually set the var and applied rules

It’s possible the playbook ran but the task didn’t fire (e.g., wrong var file, vault not loaded, wrong host group).

Confirm value seen by Ansible:

cd ~/Ram/ansible
ansible localhost -m debug -a "var=wireguard_restrict_ssh_to_vpn" --ask-vault-pass

It should print true.

Then rerun wireguard playbook with vault:

ansible-playbook playbooks/05-wireguard.yml --ask-vault-pass

After that, re-check:

sudo ufw status numbered
5) Extra-hardening (optional): bind sshd to WireGuard only

This is the strongest guarantee: SSH listens only on the VPN interface.

In /etc/ssh/sshd_config:

ListenAddress 10.8.0.1

Then:

sudo systemctl restart ssh

⚠️ Only do this after you’re 100% sure you can access 10.8.0.1 via WireGuard, otherwise you can lock yourself out.

Tell me these 3 outputs and I’ll pinpoint it immediately

Run on the server and paste results:

sudo ufw status numbered
sudo ss -ltnp | grep ':22'

While you connect from laptop (run on server):

sudo ss -tnp | grep ':22'

With those, I’ll tell you whether you’re simply connecting via VPN already, or UFW rules aren’t applied, and what exact change fixes it.


........
Your UFW rules are not yet “SSH VPN-only”

Right now your server shows:

22/tcp ALLOW Anywhere

So SSH is still public. Don’t restrict yet until Windows key auth is solved, but once solved, do this:

1) Allow SSH from VPN subnet
sudo ufw allow from 10.8.0.0/24 to any port 22 proto tcp
2) Deny public SSH
sudo ufw delete allow 22/tcp
sudo ufw deny 22/tcp
sudo ufw reload
sudo ufw status numbered

You should end with:

22 ALLOW IN 10.8.0.0/24

22 DENY IN Anywhere

⚠️ Keep your current SSH session open while testing a new session.

current firewall state
[1] 80/tcp   ALLOW IN  Anywhere
[2] 443/tcp  DENY IN   Anywhere
[3] 51820/udp ALLOW IN Anywhere
[4] 443/tcp  ALLOW IN  10.8.0.0/24
[5] 22/tcp   ALLOW IN  10.8.0.0/24
[6] 22/tcp   DENY IN   Anywhere
What this means
Port	Access	Result
22 (SSH)	Only 10.8.0.0/24	✅ VPN-only SSH
443 (HTTPS)	Only 10.8.0.0/24	✅ private web access
80 (HTTP)	Public	used for ACME / Let's Encrypt
51820 (UDP)	Public	WireGuard entry

So your architecture is now:

Internet
   │
   ├── UDP 51820 → WireGuard VPN
   │
Laptop (10.8.0.10)
   │
   ├── SSH → 10.8.0.1
   └── HTTPS → 10.8.0.1

Public users cannot access SSH or HTTPS.

Small improvement (recommended)

Right now rule order could be slightly cleaner. UFW processes rules top-down. It already works, but you can simplify.

Optional cleanup:

sudo ufw delete 2
sudo ufw insert 1 deny 443/tcp

But honestly, it's fine as is.

.........

3️⃣ Removing IPv6 (good idea if you don't use it)

IPv6 itself isn’t insecure, but if you don’t manage it, it can bypass firewall expectations.

Disable IPv6 in UFW

Edit:

sudo nano /etc/default/ufw

Change:

IPV6=no

Then reload firewall:

sudo ufw disable
sudo ufw enable

Check again:

sudo ufw status

All (v6) rules should disappear.

4️⃣ Clean final firewall (recommended)

Your ideal final rules:

80/tcp     ALLOW Anywhere
51820/udp  ALLOW Anywhere

443/tcp    ALLOW 10.8.0.0/24
443/tcp    DENY  Anywhere

22/tcp     ALLOW 10.8.0.0/24
22/tcp     DENY  Anywhere

You can remove the AWS internal rule if you want:

sudo ufw delete allow from 172.26.0.0/16 to any port 22

Because your VPN SSH already works.

5️⃣ Your system security level right now

You’ve achieved:

Internet
   │
UDP 51820
   │
WireGuard VPN
   │
Private network 10.8.0.0/24
   │
SSH + HTTPS restricted
   │
Edge gateway
   │
Authelia
   │
Agent Zero containers

This is very strong infrastructure isolation.

.........

So the rule you want to remove is #6.

Run:

sudo ufw delete 6

.............

One small improvement (recommended)

Add an explicit deny for SSH to make it clearer:

sudo ufw deny 22/tcp

Final state becomes:

22/tcp     ALLOW 10.8.0.0/24
22/tcp     DENY  Anywhere

...............
before apply the repo improment;

sudo ufw insert 1 allow 22/tcp
sudo ufw status numbered

Once everything is confirmed working:
sudo ufw delete allow 22/tcp

..........
Recommended next run order:

01-docker.yml

02-edge-gateway.yml

03a-coredns.yml

update WireGuard client config to use DNS = 10.8.0.1

reconnect VPN and test name resolution

03-vscode.yml

06-authelia.yml

07-agent-zero.yml

Before applying, set in vault:

wireguard_client_dns: "10.8.0.1"

vscode_users

agent_zero_users

authelia_domain and secrets

One thing to be aware of: this update uses wildcard DNS automation, not per-container DNS record generation from the watcher. That keeps the system simpler and more stable while still making tenant domains automatic.

i think we


......
Best next step

Before rerunning playbooks:

temporarily allow public SSH

extract the updated repo

patch the watcher with this label derivation

deploy CoreDNS first
..........

Why this is the right small improvement

It gives you:

backward compatibility

automatic tenant hostnames

no manual nginx edits

no per-tenant DNS edits because CoreDNS wildcard already handles it

/////////////////
chmod +x roles/authelia/files/render_access_control.py
////




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

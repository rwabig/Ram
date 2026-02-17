CLEAN ARCHITECTURE DECISION (OPINION)

You need ONE source of truth.

Choose ONE:

Option A — File Registry (recommended now)
/opt/edge-gateway/apps/*.yml


Simple and stable.

Option B — Docker label discovery only

No files.

You are currently mixing both → unstable.

🧹 STEP 1 — CLEAN EDGE STATE (DO THIS ONCE)

Run:

sudo rm -rf /opt/edge-gateway/nginx/sites/*
sudo docker compose -f /opt/edge-gateway/docker-compose.yml down


Then:

sudo docker rm -f edge-watcher 2>/dev/null


(we pause watcher for now — correct decision)

🧹 STEP 2 — FORCE FILE MODE ONLY (TEMP STABILIZATION)

Inside tasks/main.yml, temporarily DISABLE label discovery:

# PHASE 2.5 — DOCKER LABEL AUTO DISCOVERY
# (DISABLED FOR STABILIZATION)


Comment out:

Discover running docker containers
Build edge apps from docker labels

🧱 STEP 3 — VERIFY SOURCE OF TRUTH

You should have ONLY:

/opt/edge-gateway/apps/vscode.yml


Check:

cat /opt/edge-gateway/apps/vscode.yml


Expected:

domain: "vscode.unifypesacard.shop"
upstream: "vscode:8080"

🚀 STEP 4 — REDEPLOY EDGE

Run:

ansible-playbook playbooks/02-edge-gateway.yml


Now check:

ls /opt/edge-gateway/nginx/sites


You MUST see:

vscode.unifypesacard.shop.conf

🧪 STEP 5 — Test Internal Proxy
curl -H "Host: vscode.unifypesacard.shop" http://localhost


Expected:

➡️ code-server HTML (not nginx welcome).

🎯 WHY THIS IS THE RIGHT MOVE

Right now you need:

STABILITY > AUTOMATION


Phase 3 watcher + labels comes AFTER stable baseline.

Even senior platform engineers do this.

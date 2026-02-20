Edge Gateway Role (Event-Driven, SSL-Aware)
Overview

The Edge Gateway role provides a fully dynamic, production-grade reverse proxy layer built on:

NGINX (edge-nginx container)

Docker event listener

Automatic service discovery via container labels

Conditional HTTPS provisioning (Let’s Encrypt compatible)

Atomic configuration updates

Zero-downtime reloads

This role enables a self-registering application platform where services expose themselves to the edge by applying labels.

Architecture
[ Internet ]
      ↓
[ edge-nginx ]
      ↓
[ Application Containers ]


Key design principles:

No hardcoded upstreams

No exposed app ports

Event-driven config regeneration

Atomic config replacement

Safe reload validation

SSL enabled only when certificate exists

Features

Dynamic container discovery (docker ps)

Label-based routing

Automatic HTTP → HTTPS redirection (when cert exists)

ACME challenge support

SSL race-condition safe

Locking to prevent overlapping reloads

Config diff protection (no unnecessary reloads)

Zero-downtime nginx -s reload

Required Container Labels

Applications must define:

labels:
  edge.enable: "true"
  edge.domain: "app.example.com"
  edge.port: "8080"

Label	Description
edge.enable	Enables reverse proxy for container
edge.domain	Public domain name
edge.port	Internal container port
SSL Behavior

The watcher:

Always generates HTTP block

Checks inside nginx container for certificate:

/etc/letsencrypt/live/<domain>/fullchain.pem


If certificate exists:

Enables HTTPS block

Enables HTTP → HTTPS redirect

If not:

Keeps HTTP proxy active

Allows ACME challenge

Regenerates automatically after cert creation

This prevents startup race conditions.

Event Handling

The watcher listens to:

container start

container die

container destroy

On event:

Wait 2 seconds (debounce)

Rebuild config set

Atomic replace

Validate via nginx -t

Reload only if valid

Production Safety

Lock file prevents overlapping runs

Atomic temp directory swap

Diff check avoids unnecessary reloads

No config wipe if no services detected

SSL block only when certificate exists

Design Philosophy

Infrastructure must be deterministic

Edge must never crash due to missing cert

Reloads must be safe

Applications must self-register

No manual intervention required

Status

Current state:

Stable.
Race-condition free.
Production-ready for real workload testing.

# NGINX on Hardened RHEL (SELinux Enforcing, STIG-style) + Podman — Idiot-Proof Fix + Verification

This document explains **exactly what broke**, **why it broke**, **the minimum STIG-friendly fix**, and **how to prove it’s fixed**.

This applies to **PROD and STAGING**. Nothing here assumes DNS is pointed or ACM is configured.

---

## 🔒 STIG / Hardening Rules We Will Not Break (Non-Negotiable)
If anyone suggests these, stop and do **not** proceed:

- ❌ Do NOT disable SELinux (`setenforce 0`, permissive mode, etc.)
- ❌ Do NOT run containers with `--privileged`
- ❌ Do NOT “fix” this by chmod’ing system paths randomly
- ❌ Do NOT hand-edit servers “just this once” — changes must be codified in Ansible

We keep the system hardened and fix the container launch the *correct* way.

---

## Symptoms (What “Broken” Looks Like)

### 1) Ansible fails on health check
The playbook fails checking:
- `http://127.0.0.1/healthz`

Typical errors:
- `Connection refused`
- `Timed out`

### 2) Container exists, but service is dead / no listeners
On the server:
```bash
sudo podman ps -a --filter name=motorcade-nginx
sudo ss -lntp | egrep ":(80|443)\b" || true


Broken state commonly shows:

container “Exited” OR container “Up” but nginx not listening

no listeners on 80/443

3) Container logs show permission failures
sudo podman logs --tail 250 motorcade-nginx


We observed fatal lines like:

chown("/var/cache/nginx/client_temp", 101) failed (1: Operation not permitted)

setgid(101) failed (1: Operation not permitted)

bind() to 0.0.0.0:80 failed (13: Permission denied)

Root Cause (Why it Broke)

The host is hardened. The nginx container startup needs to do a few specific “privileged” operations, and our container run flags blocked them.

The big offender was:

--security-opt no-new-privileges

On hardened hosts, no-new-privileges can prevent required startup behaviors even when the container is otherwise correctly configured.

Also: on hardened setups, nginx often needs explicit Linux capabilities to:

bind to ports 80/443

drop privileges (setuid/setgid)

chown its cache directory

If those capabilities are not allowed, nginx dies at startup.

The Fix (Minimal, STIG-Friendly)
✅ Fix #1 — Remove no-new-privileges

We removed:

--security-opt no-new-privileges

Reason: it blocked nginx startup operations in this environment.

✅ Fix #2 — Add only the minimum required Linux capabilities

We added exactly these caps (least privilege):

--cap-add=NET_BIND_SERVICE → allow binding to 80/443

--cap-add=SETUID → allow dropping to nginx user

--cap-add=SETGID → allow dropping to nginx group

--cap-add=CHOWN → allow chown on cache dirs when required

We did not add broad caps, and we did not use privileged mode.

✅ Fix #3 — Force container recreation so changes apply

We added:

--replace

Without --replace, Podman can keep an old container definition and your new flags won’t apply.

✅ Fix #4 — Keep SELinux enforcing

We kept SELinux enforcing. For bind mounts, we use SELinux-aware volume flags and/or host labeling playbooks.

What We Did NOT Change (Intentionally)

We did not tie this to DNS or domain ownership.

We did not require ACM or real certificates to be issued.

We did not relax system hardening globally.

This keeps PROD/STAGING reusable and avoids coupling “bring-up” to “go-live DNS”.

Verification (Do Not Skip)
Step 1 — Confirm nginx container is up
sudo podman ps --filter name=motorcade-nginx --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"


Expected:

Status: Up

Ports: 80/443 mapped

Step 2 — Confirm listeners exist
sudo ss -lntp | egrep ":(80|443)\b" || true


Expected:

listeners on :80 and :443

Step 3 — Confirm health endpoint is OK
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'


Expected:

HTTP/1.1 200 OK

Step 4 — Confirm no-new-privileges is gone
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"


Expected:

SecurityOpt=[] (or at least no no-new-privileges entry)

Step 5 — Confirm capabilities are present
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"


Expected to include entries equivalent to:

CAP_NET_BIND_SERVICE

CAP_SETUID

CAP_SETGID

CAP_CHOWN

If any verification step fails, do NOT “guess-fix”. Collect evidence and adjust playbooks.

STAGING Notes (Repeatable Bring-up)

This fix is repeatable on any server because:

It does not depend on DNS being pointed

It uses least-privilege container capabilities (STIG-style)

It preserves SELinux enforcing

It is codified in repo via Ansible

Domain/DNS/Certs Separation (Best Practice)

Yes — domain bindings should be separate playbooks.

Rationale:

“Bring up nginx” ≠ “Go live on public DNS”

staging frequently won’t have real DNS/ACM yet

decoupling prevents outages and makes deployments repeatable

Recommended split:

NGINX Bring-up playbook: container, ports, baseline config, internal health checks

TLS/Domain playbook: real certs (ACM/Let’s Encrypt), vhost domain routing, public DNS expectations

Quick evidence bundle (if something breaks)

Run these on the server:

sudo podman ps -a --filter name=motorcade-nginx
sudo podman logs --tail 250 motorcade-nginx
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"
sudo ss -lntp | egrep ":(80|443)\b" || true
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'



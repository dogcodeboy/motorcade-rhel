# STAGING Validation & Bring-Up Runbook

(Dry-Run Safe, STIG-Compliant, No Manual Server Edits)

This document defines the exact, repeatable method to:

Validate playbooks without changing state

Bring up staging infrastructure safely

Prove success

Capture structured evidence when failure occurs

This workflow is environment-agnostic and must work on any properly configured host in the [motorcade] inventory group.

🔒 Rules (Non-Negotiable)

Do NOT disable SELinux.

Do NOT use --privileged.

Do NOT SSH in and “just fix something.”

Do NOT edit files directly on the server.

All changes must originate from committed Ansible playbooks.

Fact-finding via SSH is allowed. Configuration changes are not.

Phase 1 — Dry Run (Zero State Change)

Purpose: Ensure playbooks parse correctly and inventory is wired properly before touching the server.

From repo root:

export ANSIBLE_CONFIG="$PWD/ansible.cfg"
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
export VAULT_PASS_FILE=~/.ansible_vault_pass

1️⃣ Syntax Check (fast fail)
ansible-playbook --syntax-check \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/09_nginx_runtime_dirs.yml

ansible-playbook --syntax-check \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/10_nginx_container.yml


Expected: No errors.

2️⃣ Inventory Validation (no changes)
ansible -i ansible/inventories/staging/hosts.ini motorcade -m ping


Expected:

pong


If this fails, do NOT proceed. Fix SSH, inventory group, or vault first.

3️⃣ Check Mode (dry execution)
ansible-playbook \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/09_nginx_runtime_dirs.yml \
--check --vault-password-file "$VAULT_PASS_FILE"

ansible-playbook \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/10_nginx_container.yml \
--check --vault-password-file "$VAULT_PASS_FILE"


Expected:

Tasks show “would change” or “ok”

No fatal errors

No undefined variables

If check mode fails, fix playbooks before real execution.

Phase 2 — Controlled Bring-Up

Run in strict order.

ansible-playbook \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/09_nginx_runtime_dirs.yml \
--vault-password-file "$VAULT_PASS_FILE"

ansible-playbook \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/10_nginx_container.yml \
--vault-password-file "$VAULT_PASS_FILE"


Optional (only if configured):

ansible-playbook \
-i ansible/inventories/staging/hosts.ini \
ansible/playbooks/20_keycloak.yml \
--vault-password-file "$VAULT_PASS_FILE"

Phase 3 — Validation (Facts Only)

Run these on the staging server.

Containers
sudo podman ps -a


Expected:

motorcade-nginx → Status: Up

motorcade-keycloak → Up (if deployed)

Listeners
sudo ss -lntp | egrep ":(80|443|8080|8443)\b" || true


Expected:

80 and 443 listening for nginx

8080/8443 if using internal mapping

Health Endpoint
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'


Expected:

HTTP/1.1 200 OK

Container Security Verification
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"


Expected:

No no-new-privileges

CapAdd includes:

NET_BIND_SERVICE

SETUID

SETGID

CHOWN

Privileged must remain false.

What Success Looks Like

Both playbooks return rc=0

Nginx container is “Up”

Listeners exist on 80/443

Health endpoint returns 200

SELinux remains Enforcing

No manual edits were required

That is staging-ready state.

Failure Evidence Collection (Copy-Paste Bundle)

If anything fails, do NOT guess.

Collect:

sudo podman ps -a --filter name=motorcade-nginx
sudo podman logs --tail 250 motorcade-nginx
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"
sudo ss -lntp | egrep ":(80|443)\b" || true
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'
getenforce


Attach output to ticket or commit notes.

Do NOT modify server state until root cause is understood and fixed in Ansible.

Why This Matters

Staging must be:

Repeatable

DNS-independent

Security-compliant

Capability-explicit

Evidence-driven

If staging requires “special handling,” production will eventually break.

Infrastructure is either deterministic or it’s fragile.
We choose deterministic.

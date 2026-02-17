# STAGING Validation & Bring-Up Runbook  
**(Dry-Run Safe, STIG-Compliant, ID-Proof)**

This runbook describes how to safely validate, bring up, and verify the Motorcade RHEL stack on a staging environment without manual server edits. All changes must come from committed Ansible playbooks.

---

## Rules (Non-Negotiable)

- Do **not** disable SELinux or set it to permissive.
- Do **not** run containers with `--privileged`.
- Do **not** hand-edit servers.
- Only use Ansible playbooks committed in this repo.
- Fact gathering (logs, inspect, ss checks) over SSH is allowed.

---

# Phase 1 — Dry Run (No State Change)

## Export Environment

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
export VAULT_PASS_FILE=~/.ansible_vault_pass

1️⃣ Syntax Check (Fast Fail)
ansible-playbook --syntax-check \
  -i ansible/inventories/staging/hosts.ini \
  ansible/playbooks/09_nginx_runtime_dirs.yml

ansible-playbook --syntax-check \
  -i ansible/inventories/staging/hosts.ini \
  ansible/playbooks/10_nginx_container.yml


Expected: no YAML parse errors.

2️⃣ Inventory & Connectivity Check
ansible -i ansible/inventories/staging/hosts.ini motorcade -m ping


Expected: pong

3️⃣ Check Mode (Simulation)
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

Run in strict order:

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

Phase 3 — Post-Bring-Up Validation (Facts Only)
Containers
sudo podman ps -a


Expected:

motorcade-nginx → Status: Up

motorcade-keycloak → Up (if deployed)

Listeners
sudo ss -lntp | egrep ":(80|443|8080|8443)\b" || true


Expected:

nginx listening on 80 and 443

Health Endpoint
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'


Expected:

HTTP/1.1 200 OK

Container Security Verification
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"


Expected:

SecurityOpt=[]

CapAdd includes:

NET_BIND_SERVICE

SETUID

SETGID

CHOWN

Privileged must remain false.
SELinux must remain enforcing.

What Success Looks Like

Both playbooks return rc=0

nginx container is Up

Listeners on 80/443

Health endpoint returns 200

No manual SSH fixes were required

That is staging-ready state.

Failure Evidence Collection (Copy-Paste Bundle)

If anything fails, collect:

sudo podman ps -a --filter name=motorcade-nginx
sudo podman logs --tail 250 motorcade-nginx
sudo podman inspect motorcade-nginx --format "SecurityOpt={{json .HostConfig.SecurityOpt}}"
sudo podman inspect motorcade-nginx --format "CapAdd={{json .HostConfig.CapAdd}}"
sudo ss -lntp | egrep ":(80|443)\b" || true
curl -sS -I http://127.0.0.1/healthz | sed -n '1,12p'
getenforce


Attach output to ticket or commit notes.
Do not modify server state until root cause is understood and fixed in Ansible.

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

# Motorcade RHEL Runbook — Execution (Prod/Staging Neutral)

## Rules of engagement (STIG-safe)
- No manual edits on servers for config/state. Only *facts* may be queried via SSH.
- All changes must come from Ansible playbooks and be committed to the repo.
- Always run with Vault password file: `--vault-password-file ~/.ansible_vault_pass`
- Always use the correct inventory for the environment.

## Environments
- **prod** inventory: `ansible/inventories/prod/hosts.ini`
- **staging** inventory: `ansible/inventories/staging/hosts.ini`

Everything environment-specific must live in:
- inventory host_vars/group_vars
- vault (encrypted)
- NOT inside playbooks as hardcoded domains/DB endpoints.

## Standard execution order (baseline)
Run these in order for a new host:

1) Secrets + preflight:
- `ansible/playbooks/05_secrets_preflight.yml`

2) Nginx runtime dirs (SELinux-friendly bind mounts):
- `ansible/playbooks/09_nginx_runtime_dirs.yml`

3) Nginx container:
- `ansible/playbooks/10_nginx_container.yml`

4) Keycloak (SSO):
- `ansible/playbooks/20_keycloak.yml`

5) Package manifest + compliance scans (when desired):
- `ansible/playbooks/90_package_manifest.yml`
- `ansible/playbooks/95_scap_scan.yml`

## Domain/DNS/TLS policy (IMPORTANT)
Infrastructure bring-up must NOT require DNS pointing to the server.

TLS issuance and domain binding is a separate workflow:
- Bring up Nginx with either:
  - **Self-signed/bootstrap certs** (allowed for staging)
  - OR **real certs** when DNS/ACM is ready

Never block container boot on external DNS readiness.

## One-liner execution (choose inventory)
### Prod
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
export ANSIBLE_ROLES_PATH="$PWD/ansible/roles"
export VAULT_PASS_FILE=~/.ansible_vault_pass

ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/05_secrets_preflight.yml --vault-password-file "$VAULT_PASS_FILE"
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/09_nginx_runtime_dirs.yml --vault-password-file "$VAULT_PASS_FILE"
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/10_nginx_container.yml --vault-password-file "$VAULT_PASS_FILE"
ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/20_keycloak.yml --vault-password-file "$VAULT_PASS_FILE"

### Staging
Same commands, just swap inventory:
`ansible/inventories/staging/hosts.ini`

## Validation (facts only)
Run on target host:

- Containers:
  - `sudo podman ps -a`
  - `sudo podman logs --tail 200 motorcade-nginx || true`
  - `sudo podman logs --tail 200 motorcade-keycloak || true`

- Listeners:
  - `sudo ss -lntp | egrep ":(80|443|8080|8443)\b" || true`

- Health:
  - `curl -sS -I http://127.0.0.1/healthz | sed -n "1,12p" || true`

## Common failure classes (fast triage)
- **Podman security flags**: if container starts then dies with EPERM on bind/chown/setgid/bind(80).
- **SELinux labels**: if mount points exist but container can’t write (fix via runtime dirs playbook).
- **Missing TLS assets**: resolved by using bootstrap/self-signed workflow for staging.
- **DB connectivity**: Keycloak exits early if DB env/vault is wrong.

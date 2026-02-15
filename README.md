# motorcade-rhel (bootstrap)
Ansible repo to bootstrap **RHEL 10.1** hosts for Motorcade with a stable container runtime + foundational services.

## Quick start
```bash
cd ansible
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

ansible-lint
yamllint .

ansible-playbook -i inventories/prod/hosts.ini playbooks/INFRA_ALL.yml --ask-vault-pass
```

## Notes
- Default Podman install is the **locked-path** (static) method to avoid distro package drift.
- Containers are run as **systemd user services** via Quadlet (rootless) where possible.

## Identity ownership (Fed-ready posture)
- **Admin-AI** owns LDAP/IdM lifecycle and acts as identity control plane.
- **Keycloak** is the SSO provider for both public and private domains.
- LDAP group membership maps to Keycloak groups/roles for authorization policy.
- This ownership model is the baseline for future federal-ready identity controls.

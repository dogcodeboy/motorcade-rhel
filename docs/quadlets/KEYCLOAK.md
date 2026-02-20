# Keycloak Quadlet Runtime

This role supports two runtime modes:

- `keycloak_use_quadlet: false` (default): direct `podman run` lifecycle.
- `keycloak_use_quadlet: true`: systemd-managed Quadlet unit.

## Enable In Staging First

Set in staging inventory/group vars:

```yaml
keycloak_use_quadlet: true
```

Then apply:

```bash
ansible-playbook -i ansible/inventories/staging/hosts.ini ansible/playbooks/20_keycloak.yml --vault-password-file ~/.ansible_vault_pass
```

## What The Role Creates In Quadlet Mode

- Quadlet file:
  - `/etc/containers/systemd/{{ keycloak_container_name }}.container`
- Runtime env file (from AWS Secrets Manager values at run time):
  - `/run/motorcade/keycloak/keycloak.env`
- Service management:
  - `systemctl daemon-reload`
  - `systemctl enable --now {{ keycloak_container_name }}.service`

Secrets are still retrieved by existing role logic and env file writes remain `no_log: true`.

## Validation

Run on target host:

```bash
sudo systemctl status motorcade-keycloak.service --no-pager
sudo podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
curl -sS -I http://127.0.0.1:8081/ | head -n 20
```

Expected:

- service is `active (running)`
- container is present in `podman ps`
- loopback listener responds (HTTP 200/302 depending on Keycloak state)

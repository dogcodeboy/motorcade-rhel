# Nginx Quadlet Runtime

The `nginx_container` role supports two runtime modes:

- `nginx_use_quadlet: false` (default): direct `podman run`
- `nginx_use_quadlet: true`: systemd-managed Quadlet service

## Enable In Staging First

Set in staging inventory/group vars:

```yaml
nginx_use_quadlet: true
```

Apply:

```bash
ansible-playbook -i ansible/inventories/staging/hosts.ini ansible/playbooks/10_nginx_container.yml --vault-password-file ~/.ansible_vault_pass
```

## What Quadlet Mode Creates

- `/etc/containers/systemd/{{ nginx_container_name }}.container`
- `systemctl daemon-reload`
- `systemctl enable --now {{ nginx_container_name }}.service`

The role keeps the existing config + certificate mounts:

- `/etc/motorcade/nginx/nginx.conf:/etc/nginx/nginx.conf:ro,Z`
- `/etc/motorcade/nginx/conf.d:/etc/nginx/conf.d:ro,Z`
- `{{ motorcade_nginx_tls_cert_dir }}:/etc/nginx/certs:ro,Z`

## Validation

```bash
sudo systemctl status motorcade-nginx.service --no-pager
sudo podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
sudo podman inspect motorcade-nginx | head -n 40
curl -sS -I http://127.0.0.1/healthz | head -n 20
```

Expected:

- service is `active (running)`
- container is present in `podman ps`
- `/healthz` returns HTTP 200

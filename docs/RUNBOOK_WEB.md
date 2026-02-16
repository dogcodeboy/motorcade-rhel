# RUNBOOK_WEB

## Scope
Deploy nginx as a hardened Podman container and open required firewall ports.

## Prereqs
- TLS files must exist on host under `motorcade_nginx_tls_cert_dir`:
  - `motorcade.vip.crt`, `motorcade.vip.key`
  - `sso.motorcade.vip.crt`, `sso.motorcade.vip.key`

## Run
```bash
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/12_firewall_web.yml
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/10_nginx_container.yml
```

## Validate
```bash
sudo firewall-cmd --zone=public --list-ports
sudo podman ps --filter name=motorcade-nginx
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1/healthz
curl -Ik https://motorcade.vip/healthz
curl -Ik https://sso.motorcade.vip/
```

## Audit artifacts
- `/srv/motorcade/audit/nginx_image_inspect.json`
- `/srv/motorcade/audit/nginx_container_inspect.json`

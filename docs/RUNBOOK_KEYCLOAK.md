# RUNBOOK_KEYCLOAK

## Scope
Deploy Keycloak via Podman in strict RDS mode with Secrets Manager runtime credential fetch.

## Hard requirements
- `keycloak_db_mode: rds`
- `keycloak_db_host`, `keycloak_db_name`, `keycloak_db_user`, `keycloak_db_secret_arn`
- `keycloak_hostname: sso.motorcade.vip`
- `keycloak_admin_user` and `keycloak_admin_password` provided via vaulted vars

## Secret JSON shape
```json
{"username":"keycloak","password":"<generated>"}
```

## IAM minimum
- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`
- `kms:Decrypt` if customer-managed KMS key is used

## Run
```bash
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/05_secrets_preflight.yml
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/20_keycloak.yml
```

## Validate
```bash
sudo podman ps --filter name=motorcade-keycloak
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081/
curl -Ik https://sso.motorcade.vip/
```

## Audit artifacts
- `/srv/motorcade/audit/keycloak_container_inspect.json`
- `/srv/motorcade/audit/keycloak_image_inspect.json`
- `/srv/motorcade/audit/keycloak_config_effective.txt`
- `/srv/motorcade/audit/keycloak_secret_arn_used.txt`

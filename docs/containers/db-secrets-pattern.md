# Reusable Pattern: Any Container Connecting to a DB via AWS Secrets

## Summary
All services that need DB credentials MUST:
- store only secret IDs in inventory/group_vars
- fetch secrets at runtime from AWS Secrets Manager (instance IAM role)
- inject credentials into Podman without writing env files and without putting secret values in argv

This is the canonical Motorcade method.

## Required Inputs (per service)
In inventory/group_vars for the target environment:
- `<service>_db_secret_id`
- `<service>_admin_secret_id` (if needed)

## Role Responsibilities
Each service role should implement:
1) Assert secret IDs are set (fail-fast)
2) Fetch SecretString for each secret ID (`aws secretsmanager get-secret-value ...`)
3) Parse JSON (`from_json`)
4) Build the runtime env dict in-memory (template render -> parse)
5) Run podman with `--env VAR` names + Ansible `environment:` dict

## Recommended Secret Schema
DB SecretString JSON:
- host
- port
- dbname
- username
- password

## Source Guardrail
- Do not point service roles directly at AWS-managed `rds!db-*` rotation secrets unless host is provided separately.
- Preferred approach is a service-specific secret that already contains canonical keys:
`host`, `port`, `dbname`, `username`, `password`.

## Minimal Safe Evidence Commands (Runbooks)
- `podman ps -a --filter name=<name>`
- `podman logs --tail 150 <name>`
- `ss -lntp | grep <port>`

Do NOT dump environment variables in evidence output.

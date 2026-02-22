# LeadGen Mini-Runbook (RHEL + RDS + AWS Secrets Manager)

## Purpose
Deploy and operate the LeadGen intake API behind a static-site nginx frontend on hardened RHEL.
This runbook is STIG-oriented: auditable, deterministic, and secrets-safe.

## Invariants (MUST HOLD)
- **No WordPress / no PHP-FPM** on target hosts. Static site only.
- Containers managed via **Podman + systemd/quadlet**.
- Database is **Amazon RDS PostgreSQL**.
- Secrets are sourced only from **AWS Secrets Manager** at runtime.
- No secrets in git, Ansible Vault, templates, or static `/etc/*.env`.
- Public path `/api/lead-intake` must NOT expose API keys to the browser.

## Architecture (High Level)
- Public web submits JSON to: `POST /api/lead-intake`
- Nginx proxies to LeadGen: `POST /lead/intake`
- Nginx injects `X-API-Key` server-side (retrieved from AWS Secrets Manager)
- LeadGen persists:
  - durable intake job: `app.intake_jobs (payload jsonb)`
  - lead record: `app.leads` with `jsonb` payload column for forward compatibility

## Preconditions
### Host
- RHEL hardened baseline (FIPS/STIG posture)
- Podman installed and functioning
- systemd operational
- nginx installed/configured for static site hosting
- outbound access to:
  - AWS Secrets Manager endpoint
  - RDS endpoint

### IAM
Instance role / credentials must allow:
- `secretsmanager:GetSecretValue`

### RDS
- RDS endpoint reachable (security groups, route tables)
- Database exists (name per secret JSON)
- User has privileges to create schema/table/alter (for initial migration)

## Required AWS Secrets Manager Secrets
### LeadGen DB Secret (JSON)
Must include:
- `host` OR `endpoint`
- `username` OR `user`
- `password`

Optional:
- `port` (default 5432)
- `dbname` (default `leadgen`)

Example:
```json
{
  "endpoint": "example.cluster-xyz.us-east-2.rds.amazonaws.com",
  "port": 5432,
  "dbname": "leadgen",
  "username": "leadgen_app",
  "password": "REDACTED"
}
```

### LeadGen Intake API Key Secret (JSON)
Must include:
- `api_key` (preferred) OR `key`

Example:
```json
{ "api_key": "REDACTED" }
```

## Deployment Overview (via Ansible)
Canonical playbooks must live in `motorcade-rhel` and follow repo parameterization standards:
- inventory/group_vars contain secret IDs/ARNs only
- role fetches secrets at runtime, writes runtime-only files under `/run/motorcade/...`

### Ordered Steps
1. Fetch secrets from AWS SM and generate runtime env files under `/run/motorcade/leadgen/`
2. Apply DB schema migrations to RDS (idempotent)
3. Deploy LeadGen container via quadlet + systemd
4. Configure nginx reverse-proxy for `/api/lead-intake`:
   - `proxy_pass` to LeadGen `/lead/intake`
   - inject `X-API-Key`
5. Validate E2E: static → nginx → leadgen → RDS

## Validation Checks
### Local health
```bash
curl -sS http://127.0.0.1:<LEADGEN_PORT>/lead/health
```

### Proxy path (host header)
```bash
curl -sS -H "Host: motorcade.vip" -X POST http://127.0.0.1/api/lead-intake -d '{"email":"test@example.com","full_name":"Test User"}'
```

### DB verification
- Query `app.intake_jobs` and `app.leads` for recent rows
- Confirm payload JSONB contains the submitted fields

## Rollback
- Stop leadgen service: `systemctl stop motorcade-leadgen`
- Remove quadlet unit and reload daemon if necessary
- Revert nginx config and reload
- DB rollback is controlled (do not drop tables in production without change approval)

## Audit Evidence (STIG-Friendly)
Capture:
- Ansible playbook run logs (with secrets redacted)
- systemd unit status output
- nginx config snippets (non-secret)
- DB schema version/migration record
- OpenSCAP scan results after deployment change window (if required by policy)

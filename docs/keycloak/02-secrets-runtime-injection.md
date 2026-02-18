# Runtime Secrets Injection (AWS Secrets Manager) — STIG-Safe Pattern

## Goal
Provide DB/admin credentials to Keycloak without:
- secret values in repo
- secret values in files on disk
- secret values on the Podman command line

## How it works
1) Inventory contains only secret *IDs/ARNs*:
   - `keycloak_db_secret_id`
   - `keycloak_admin_secret_id`
2) Role fetches SecretString JSON at runtime using instance IAM role:
   - `aws secretsmanager get-secret-value ...`
3) Role normalizes the JSON into `kc_db` and `kc_admin`.
4) Role renders the env template in-memory and converts it to a dict.
5) Podman is executed with **name-only** `--env VAR` flags.
6) Actual values are injected via Ansible `environment:` (not argv).

## Why this is required
Hardening requirements push us to:
- avoid secrets at rest on disk
- avoid secrets in process listings and logs
- ensure evidence collection does not leak credentials

## Canonical secret schema (recommended)
DB SecretString JSON:
- host
- port
- dbname
- username
- password

Admin SecretString JSON:
- username (optional)
- password (required)

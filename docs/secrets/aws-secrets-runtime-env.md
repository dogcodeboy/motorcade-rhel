# AWS Secrets Runtime Injection (No Secret Files, STIG-Friendly)

## Goal
Run containers that require credentials (DB/admin/API keys) **without**:
- storing secrets in repo
- storing secrets on disk (no `/etc/*.env`, no `/run/*.env`)
- placing secret values on the container runtime command line

Secrets are retrieved at runtime from **AWS Secrets Manager** using the instance IAM role.

## Why this is STIG-friendly
- Secrets are never written to disk.
- Secrets are not present in Podman/Docker argv (avoids leakage into process listings and audit logs).
- Ansible tasks that handle secret payloads run with `no_log: true`.
- IAM policies follow least-privilege and can be audited centrally in AWS.

## Required AWS Setup (Least Privilege)
1) Store secrets in AWS Secrets Manager.
2) Attach an IAM role to the instance with:
- `secretsmanager:GetSecretValue` on the needed secret ARNs only
- (optional) `kms:Decrypt` if the secret uses a customer-managed KMS key

Example IAM policy (tight scope):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSpecificSecrets",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": [
        "arn:aws:secretsmanager:REGION:ACCOUNT:secret:YOUR_SECRET_NAME-*"
      ]
    }
  ]
}
```

## Secret JSON Schema (recommended)

Store secret values as JSON in SecretString.
DB example:

```json
{
  "host": "db.internal",
  "port": 5432,
  "dbname": "appdb",
  "username": "appuser",
  "password": "REDACTED"
}
```

Admin/user example:

```json
{
  "username": "admin",
  "password": "REDACTED"
}
```

## Important DB Secret Source Rule

- Do not use AWS-managed `rds!db-*` rotation secrets directly for container runtime unless you also provide host metadata from another source.
- Standard Motorcade pattern is a service-specific DB secret with canonical keys:
`host`, `port`, `dbname`, `username`, `password`.
- This avoids schema drift and keeps role logic deterministic across environments.

## Ansible Pattern (Host-side fetch + in-memory injection)
1) Inventory/group_vars stores only secret IDs

`service_db_secret_id: "arn:aws:secretsmanager:...:secret:db-secret"`

`service_admin_secret_id: "arn:aws:secretsmanager:...:secret:admin-secret"`

No secret values in repo. Only references.

2) Role fetches secrets on the host (instance IAM role)

Use `aws secretsmanager get-secret-value ... --query SecretString --output text`.

3) Render env template in-memory (no files)

Render a role template into a text blob, parse into a dict, and pass via Ansible `environment:`.

4) Podman receives env names only

Podman argv uses `--env VAR` (no values).
Values are injected via `environment:`.

## Troubleshooting

- `aws: command not found` -> install AWS CLI on the host or bake into base image.
- `AccessDeniedException` -> instance role lacks permission to read the secret ARN.
- `from_json` failures -> secret value is not valid JSON; fix SecretString format.
- Container still failing DB auth -> verify the secret schema fields match what the role expects.

## Auditing & Safety Notes

- Never use `podman inspect` to print container env in logs/runbooks.
- Keep `no_log: true` on tasks that register secret payloads.
- Avoid debugging with `debug: var=kc_db_secret` unless temporarily and locally.

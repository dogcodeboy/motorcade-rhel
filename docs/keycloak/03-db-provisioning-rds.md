# DB Provisioning (RDS PostgreSQL) — Keycloak

## Purpose
Provision the Keycloak DB and role in RDS PostgreSQL using:
- TLS `verify-full`
- AWS RDS CA bundle
- admin credentials retrieved from AWS Secrets Manager

## Inputs
Inventory references only:
- `rds_admin_secret_id` (admin credential secret)
- `keycloak_db_secret_id` (service credential secret)

## What the playbook does
The provisioning playbook:
- installs psycopg2 dependencies on the target host
- installs AWS RDS global CA bundle to a fixed path
- fetches secrets at runtime (no_log)
- ensures:
  - role exists (LOGIN)
  - database exists owned by that role

## Why TLS verify-full
- Enforces certificate validation and correct hostname verification.
- Required for secure DB connections in hardened environments.

## Safety constraints
- Do not print secret JSON.
- Do not use psql evidence output with passwords.

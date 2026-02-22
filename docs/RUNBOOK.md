# RUNBOOK

## Purpose
Canonical runbook pointer for LeadGen deployment and operations on `motorcade-rhel`.

## Invariants
- Static site only (no WordPress, no PHP-FPM)
- `/api/lead-intake` is proxied to LeadGen `/lead/intake`
- API key is injected server-side
- Secrets via AWS Secrets Manager only
- DB is Amazon RDS PostgreSQL

## Preconditions
- RHEL host baseline is hardened and reachable
- Podman + systemd/quadlet are available
- Required Secrets Manager secret IDs/ARNs are set in inventory
- RDS endpoint is reachable from host

## Deploy
Run the canonical LeadGen docs and playbooks from this repo.

## Validate
Use the health checks and DB verification steps in the LeadGen mini-runbook.

## Rollback
Use the rollback section in the LeadGen mini-runbook for service + nginx rollback.

## Audit Evidence
Capture Ansible logs, unit status, nginx effective config snippets, and DB migration evidence.

## LeadGen (RHEL + RDS + AWS Secrets Manager)
Authoritative docs:
- `docs/leadgen/LEADGEN_MINI_RUNBOOK.md`
- `docs/leadgen/LEADGEN_OPERATOR_GUIDE.md`
- `docs/leadgen/LEADGEN_SECRETS_SCHEMA.md`

Key invariants:
- Static site only (no WordPress)
- `/api/lead-intake` is proxied to LeadGen `/lead/intake`
- API key injected server-side
- Secrets via AWS Secrets Manager only
- DB is Amazon RDS PostgreSQL

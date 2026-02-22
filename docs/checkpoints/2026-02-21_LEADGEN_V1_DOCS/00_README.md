# CHECKPOINT — 2026-02-21 — LEADGEN_V1_DOCS

## Purpose
Crash-safe documentation checkpoint for LeadGen (RHEL + static-site-only + RDS Postgres + AWS Secrets Manager).
This checkpoint captures current intent, invariants, and documentation scaffolding so implementation can resume
without context loss.

## Key Invariants (Locked)
- Target server OS: RHEL (STIG/FIPS posture), Podman, systemd/quadlet.
- No WordPress / no PHP-FPM. Static site only.
- Database: Amazon RDS PostgreSQL (prod now; staging later).
- Secrets: AWS Secrets Manager only. No secrets in repo, templates, .env, or Ansible Vault.
- Edge path: public web POSTs to `/api/lead-intake` (no browser secrets).
- Nginx must reverse-proxy to LeadGen API `/lead/intake` and inject `X-API-Key` server-side.
- LeadGen DB schema must include:
  - `app.intake_jobs` with payload `jsonb` (durable queue)
  - `app.leads` must have a `json/jsonb` payload column (forward compatible)
  - conversion lifecycle fields (status, converted_* fields) for later client account provisioning.

## What This Checkpoint Contains
- LeadGen Mini-Runbook (deployment/validation/rollback/audit)
- Operator “Idiot-Proof” Guide
- Secrets Manager JSON schema references (DB + API key)
- Data model requirements based on contact + security assessment forms

## Next Implementation Phase (NOT DONE IN THIS CHECKPOINT)
- Add STIG-aligned LeadGen Ansible role to motorcade-rhel
- Add RDS schema migrations via Ansible
- Add nginx `/api/lead-intake` route + header injection
- Retire legacy LEADGEN_* playbooks in motorcade-infra (documentation deprecation only)

# Motorcade RHEL Ops Docs

## Purpose
This repo contains post-boot Ansible automation for STIG-aligned, auditable service deployment on RHEL hosts.

## Start Here
- `docs/RUNBOOK_EXECUTION.md`: canonical execution order for prod/staging.
- `docs/RUNBOOK_TLS_DOMAINS.md`: DNS/TLS workflow kept separate from base infra bring-up.

## Layout
- `ansible/playbooks/`: execution entrypoints.
- `ansible/roles/`: hardened role implementations.
- `ansible/inventories/prod/`: production inventory and vars.
- `ansible/inventories/staging/`: staging inventory and vars.
- `docs/`: runbooks for deploy, audit, and incident handling.

## Operating model
- Golden image handles baseline OS posture.
- Ansible handles service wiring, runtime hardening, and audit artifacts.
- Changes are committed in small, scoped commits with syntax-check gates.

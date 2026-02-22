# Legacy LeadGen Playbooks Retirement Note

## Statement of Record
Legacy LeadGen wave playbooks in `motorcade-infra` are considered non-canonical for the new RHEL + RDS deployment model.

Reasons:
- Assume local/postman postgres patterns
- Use Ansible Vault / env secrets patterns not permitted under current policy
- Do not follow motorcade-rhel parameterization standards
- Target pre-static-only stack assumptions

Action:
- Implementation will be rehomed to motorcade-rhel as canonical.
- motorcade-infra LEADGEN_* will later be marked DEPRECATED (history preserved).

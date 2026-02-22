# SESSION HANDOFF — LeadGen (RHEL + RDS + Secrets Manager)

## Current State (Truth)
- Static site is canonical. Submissions are sent by JS to `POST /api/lead-intake`.
- New server will not run WordPress or PHP-FPM.
- LeadGen is not yet deployed on the new server.
- DB is Amazon RDS Postgres; local podman-postgres patterns are obsolete.
- Secrets must come from AWS Secrets Manager, following motorcade-rhel Keycloak pattern.

## Integration Contract
- Browser: `POST /api/lead-intake` (no auth header)
- Nginx: reverse proxy to LeadGen `POST /lead/intake`, inject `X-API-Key` from Secrets Manager.
- LeadGen API: requires `X-API-Key` and writes payload into DB.
- DB schema: must include `app.intake_jobs` and a `jsonb` payload column on `app.leads`.

## Form Field Sources
- `motorcade.vip/site/contact.html` fields must be preserved.
- `motorcade.vip/site/security-assessment.html` fields must be preserved (large set).
- Approach: store core queryable fields + full payload JSONB for all form fields.

## Future Requirement (not now)
- Convert selected leads into Keycloak client accounts:
  - username == email
  - conversion performed by Employee UI first; later Admin-AI/LDAP control plane adds governance.
  - DB must keep conversion lifecycle fields now.

## Next Steps
- Create LeadGen runbook + operator guide (this checkpoint).
- Then implement motorcade-rhel roles/playbooks:
  - leadgen role w/ Secrets Manager env creation under /run
  - RDS schema migrations
  - nginx proxy bridge for /api/lead-intake
  - validation + rollback procedures

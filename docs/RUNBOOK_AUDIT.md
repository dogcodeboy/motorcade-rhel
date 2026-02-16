# RUNBOOK_AUDIT

## Audit root
Primary audit root is `/srv/motorcade/audit`.

## What lands there
- Nginx image/container inspect JSON
- Keycloak image/container inspect JSON
- Keycloak effective non-secret config snapshot
- Keycloak secret ARN marker file
- SCAP dated outputs under `/srv/motorcade/audit/scap/YYYY-MM-DD/`
- Package manifest snapshots under `/srv/motorcade/audit/packages-YYYY-MM-DD.txt`

## Collection recommendation
- Pull this directory after each deployment wave.
- Store artifacts in immutable retention storage with ticket/change ID linkage.

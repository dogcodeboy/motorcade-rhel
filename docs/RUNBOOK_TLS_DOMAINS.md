# Motorcade TLS + Domains Runbook (Separate from Infra Bring-up)

## Goal
Nginx and internal services must be able to start BEFORE DNS points to the box.

## Modes
### Mode A — Bootstrap (staging-friendly)
- Use self-signed certs placed at the expected paths.
- Nginx comes up, health checks pass, you can validate routing locally.

### Mode B — Real certs (prod)
- Use ACM / real cert pipeline once DNS is correct.
- Replace bootstrap certs without changing Nginx logic.

## Rule
Do not bake domain readiness into base infra playbooks.
Infra playbooks may validate “files exist” *only if* bootstrap workflow is available and documented.

## Validation
- `curl -kI https://localhost/ | sed -n "1,12p"`

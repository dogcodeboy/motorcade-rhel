# Keycloak Optimized Image Runbook (STIG-Safe)

## Why this exists
- `kc.sh start --optimized` requires a prebuilt Keycloak image.
- If the server has never been built, optimized startup fails with first-start warnings/errors.
- The role now prebuilds an optimized image on-host, then runs steady-state with `--optimized`.

## Build phase rules (no secrets)
- Build uses `Containerfile.optimized.j2` only.
- Build-time settings are non-sensitive only:
  - `KC_DB=postgres`
  - `KC_HEALTH_ENABLED=true`
  - `KC_METRICS_ENABLED=true`
- No DB URL, DB password, admin password, or other secrets are baked into the image.

## Runtime secret model
- Secrets come from AWS Secrets Manager at runtime.
- Ansible renders runtime env in-memory and injects values via `environment:`.
- Podman receives `--env VAR` name-only flags; secret values are not placed on the CLI.

## Safe verification
- `sudo podman images | grep motorcade-keycloak:optimized`
- `sudo podman ps -a | grep motorcade-keycloak`
- `sudo ss -lntp | grep :8081`

## Do not do this in runbooks
- Do not dump container env values from `podman inspect`.
- Keep evidence commands limited to `ps`, `logs`, `ss`, and health checks.

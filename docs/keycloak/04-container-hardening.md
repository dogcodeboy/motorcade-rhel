# Container Hardening Decisions (Keycloak)

These settings are used to reduce attack surface and contain blast radius.

## Key controls
- Loopback-only port binding:
  - 127.0.0.1:8081:8080
- Capability minimization:
  - `--cap-drop=ALL`
- Read-only root filesystem (steady-state):
  - `--read-only`
- Controlled writable locations:
  - `--tmpfs /run ...`
  - `--tmpfs /tmp ...`
  - additional tmpfs only where required
- Resource limits:
  - `--pids-limit`
  - `--memory`
- SELinux labeling for volumes:
  - `:Z`

## Why we do this
- Prevents write persistence in container filesystem.
- Restricts privilege escalation primitives.
- Keeps sensitive runtime material from being written to arbitrary paths.
- Makes failure modes deterministic and auditable.

## First-start exception
Some Keycloak first-start/build actions require writable paths.
We handle that via:
- a dedicated optimized image build step (kc.sh build)
- a controlled first-start marker workflow

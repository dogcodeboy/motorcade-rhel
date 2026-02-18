# Optimized Image Build (kc.sh build) — Why it exists

## Problem
`kc.sh start --optimized` requires the server to have been built.
If it has not, Keycloak fails with first-start optimized errors.

## Solution
We prebuild a local optimized image on the host:
- Containerfile is rendered from template `Containerfile.optimized.j2`.
- Build-time config is **non-sensitive only** (no DB URL, no passwords).
- Resulting tag defaults to:
  - `localhost/motorcade-keycloak:optimized`

Steady-state runs use the optimized image and `--optimized`.

## STIG safety notes
- No secrets are baked into the optimized image.
- Secrets remain runtime-only via AWS Secrets Manager injection.

# Keycloak (Motorcade) — Operator Docs Index (STIG-Safe)

This folder documents how Motorcade runs Keycloak in production, *why* the configuration is the way it is, and how to operate it safely without leaking secrets.

## Contents
- 01-architecture.md — what runs where (Nginx/TLS edge, Keycloak loopback)
- 02-secrets-runtime-injection.md — AWS Secrets Manager runtime model (no secret files)
- 03-db-provisioning-rds.md — provisioning DB/user in RDS PostgreSQL (TLS verify-full)
- 04-container-hardening.md — read-only, tmpfs, cap drop, loopback-only ports
- 05-optimized-image-build.md — why we prebuild an optimized image (kc.sh build)
- 06-troubleshooting.md — safe evidence commands + common failure modes

## Safety rules (non-negotiable)
- Never store secret values in repo or on disk (/etc/*.env, /run/*.env).
- Never print env values in evidence output (no `podman inspect` env dumps).
- Keep evidence limited to: `podman ps`, `podman logs`, `ss -lntp`, and health checks.

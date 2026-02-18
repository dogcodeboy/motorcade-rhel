# Keycloak Architecture (Prod)

## External
Users authenticate via:
- https://sso.motorcade.vip

TLS terminates at the edge (Nginx now; ALB later if adopted). Keycloak itself runs HTTP internally.

## Internal
- Keycloak container binds to loopback only:
  - 127.0.0.1:8081 → container 8080
- Nginx proxies:
  - sso.motorcade.vip → http://127.0.0.1:8081

## Why loopback-only
- Minimizes exposed attack surface (no direct public container port).
- Forces all inbound traffic through a single hardened edge (Nginx/WAF/ALB).

## Keycloak hostname/proxy behavior
Keycloak is configured with:
- `--hostname https://sso.motorcade.vip`
- `--http-enabled true`
- `--proxy-headers xforwarded`

This ensures Keycloak generates correct redirect/issuer URLs for browsers and OIDC clients while TLS is terminated upstream.

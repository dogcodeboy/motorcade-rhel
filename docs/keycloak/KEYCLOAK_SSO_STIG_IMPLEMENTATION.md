# Motorcade SSO (Keycloak) Deployment
## STIG-Aligned Implementation and Remediation Record

System: motorcade-prod-01  
Component: Keycloak (Containerized via Podman)  
Domain: sso.motorcade.vip  
Compliance Context: FISMA / NIST 800-53 / DISA STIG / RHEL 10 FIPS-enabled baseline  

---

# 1. Objective

Deploy Keycloak as the authoritative SSO provider for the Motorcade platform in a manner that:

- Maintains SELinux in Enforcing mode
- Preserves container hardening posture
- Avoids disabling security controls
- Ensures deterministic file ownership and labeling
- Supports HTTPS-only ingress behind hardened Nginx
- Remains rebuild-safe and STIG compliant

---

# 2. Architecture Overview

Keycloak runs as:

- Podman container
- Non-root user (UID 1000)
- ReadonlyRootfs=true
- Explicit writable data volume
- Reverse-proxied by hardened Nginx container
- TLS terminated at Nginx (Let’s Encrypt)
- SELinux Enforcing mode maintained

Key data path:

Host:      /srv/motorcade/keycloak/data  
Container: /opt/keycloak/data  

---

# 3. Initial Failure Condition

Admin console failed to load.

Symptoms:

- “Loading the Administration Console” indefinitely
- JS bundles returning HTTP 500
- Log error:

Temporary directory /opt/keycloak/bin/../data/tmp does not exist and it was not possible to create it

Root cause:

- Host data directory owned by root:root
- Container runs as UID 1000
- ReadonlyRootfs prevented fallback writes
- SELinux context mismatched container label
- tmp directory not pre-created

---

# 4. Immediate Runtime Remediation

Executed:

chown -R 1000:0 /srv/motorcade/keycloak/data  
chmod 0750 /srv/motorcade/keycloak/data  
mkdir -p /srv/motorcade/keycloak/data/tmp  
chmod 0770 /srv/motorcade/keycloak/data/tmp  
restorecon -Rv /srv/motorcade/keycloak/data  

Result:

- Container user 1000 could write tmp
- Admin JS returned 200
- Console rendered successfully
- SELinux remained Enforcing

---

# 5. Permanent STIG-Compliant Codification

All fixes codified in motorcade-rhel main.yml.

## 5.1 Deterministic Directory Creation

Before container start:

- /srv/motorcade/keycloak owned root:root (0750)
- /srv/motorcade/keycloak/data owned 1000:0 (0750)
- /srv/motorcade/keycloak/data/tmp owned 1000:0 (0770)

Rationale:

- Prevent runtime permission failures
- Enforce least privilege
- Comply with STIG file permission controls

---

## 5.2 Persistent SELinux Labeling

Added persistent fcontext rule:

semanage fcontext -a -t container_file_t "/srv/motorcade/keycloak/data(/.*)?"
restorecon -Rv /srv/motorcade/keycloak/data

Rationale:

- Prevent MCS drift
- Avoid relabel failures during redeploy
- Preserve mandatory access control integrity

---

## 5.3 Stable Mount Strategy

Changed volume mount from:

:Z

to:

:z

Rationale:

- :Z rewrites labels per-container
- :z shares label safely
- Prevents intermittent EACCES failures

---

# 6. Container Hardening Preserved

The following controls remain enforced:

- ReadonlyRootfs=true
- --cap-drop=ALL
- tmpfs isolation
- SELinux Enforcing
- Non-root execution (UID 1000)
- TLS-only ingress

No security controls were weakened.

---

# 7. TLS & Reverse Proxy Validation

Verified:

- HTTP → HTTPS redirect enforced
- HSTS enabled
- ACME path accessible
- Certs labeled container_file_t
- nginx -t clean
- Port 443 listening
- HTTP/2 operational

---

# 8. Final Validation Evidence

Confirmed:

- /realms/master → 200
- /.well-known/openid-configuration → 200
- Admin JS bundles → 200
- Writable tmp path functional
- HTTPS login page renders
- Admin console fully loads

---

# 9. Compliance Mapping

| Control Area | Implementation |
|--------------|---------------|
| AC-6 | Non-root container execution |
| CM-6 | Codified configuration management |
| SI-7 | Immutable root filesystem |
| SC-8 | TLS enforced |
| SC-28 | Data protected by SELinux labeling |
| IA-2 | Centralized identity authority |

---

# 10. Repository Reference

Repo: motorcade-rhel  
File Modified: main.yml  
Commit: 2b3ff8e — Keycloak: ensure writable data/tmp (uid 1000) + persistent SELinux label

---

# 11. Operational Requirements

Future rebuilds MUST:

- Preserve UID 1000 ownership
- Maintain fcontext rule
- Avoid :Z on data mounts
- Keep SELinux in Enforcing mode
- Maintain ReadonlyRootfs

---

# Status

Keycloak SSO deployment is:

Operational  
HTTPS enforced  
SELinux compliant  
STIG-aligned  
Rebuild-safe

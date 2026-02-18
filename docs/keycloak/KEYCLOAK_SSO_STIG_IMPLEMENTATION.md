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

# 4. Immediate Runtime Remediation (Evidence-Based)

Executed (runtime, no repo edits):

- Ensure directory ownership supports Keycloak UID:
  - chown -R 1000:0 /srv/motorcade/keycloak/data
- Ensure restrictive permissions:
  - chmod 0750 /srv/motorcade/keycloak/data
- Ensure writable tmp exists:
  - mkdir -p /srv/motorcade/keycloak/data/tmp
  - chmod 0770 /srv/motorcade/keycloak/data/tmp
- Restore SELinux contexts:
  - restorecon -Rv /srv/motorcade/keycloak/data

Result:

- Container user 1000 could write tmp
- Admin JS returned 200
- Console rendered successfully
- SELinux remained Enforcing

---

# 5. Permanent STIG-Compliant Codification (motorcade-rhel)

Fixes codified in the controlling repo and role (motorcade-rhel), so rebuilds do not regress.

## 5.1 Deterministic Directory Creation (before container start)

- /srv/motorcade/keycloak owned root:root (0750)
- /srv/motorcade/keycloak/data owned 1000:0 (0750)
- /srv/motorcade/keycloak/data/tmp owned 1000:0 (0770)

Rationale:

- Prevent runtime permission failures
- Enforce least privilege
- Align with STIG file permission controls

---

## 5.2 Persistent SELinux Labeling (durable across relabels)

Persistent fcontext rule:

- semanage fcontext -a -t container_file_t "/srv/motorcade/keycloak/data(/.*)?"
- restorecon -Rv /srv/motorcade/keycloak/data

Rationale:

- Prevent access regressions after relabel
- Preserve MAC integrity
- Avoid weakening SELinux policy

Note: if the rule exists, use semanage fcontext -m to modify.

---

## 5.3 Stable Mount Strategy

Host path /srv/motorcade/keycloak/data is mounted to /opt/keycloak/data using :z

Rationale:

- :Z assigns a private label per container run and can cause drift across workflows
- :z provides shared labeling appropriate for persistent data volumes
- Avoids intermittent EACCES/500 failures

---

# 6. Container Hardening Preserved

Controls remain enforced:

- ReadonlyRootfs=true
- --cap-drop=ALL
- tmpfs isolation for non-persistent writable paths
- SELinux Enforcing
- Non-root execution (UID 1000)
- TLS-only ingress

No security controls were weakened.

---

# 7. TLS & Reverse Proxy Validation

Verified:

- HTTP → HTTPS redirect enforced
- HSTS enabled
- Admin console reachable via sso.motorcade.vip
- ACME path reachable for HTTP-01
- SELinux + cert mount issues resolved on Nginx side (separate workstream)

---

# 8. Validation Evidence (Functional)

Confirmed endpoints are healthy:

- /realms/master → 200
- /.well-known/openid-configuration → 200
- Admin JS bundles → 200
- Writable tmp path functional
- HTTPS login page renders

---

# 9. Compliance Mapping (High-Level)

| Control Area | Implementation |
|--------------|----------------|
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
Commit (codification): 2b3ff8e — Keycloak: ensure writable data/tmp (uid 1000) + persistent SELinux label

---

# 11. Operational Requirements

Future rebuilds MUST:

- Preserve UID 1000 ownership of /srv/motorcade/keycloak/data
- Maintain fcontext rule for /srv/motorcade/keycloak/data(/.*)?
- Use :z (not :Z) for the persistent data mount
- Keep SELinux Enforcing mode
- Maintain ReadonlyRootfs

---

# Status

Keycloak SSO is:

Operational  
SELinux compliant  
STIG-aligned  
Rebuild-safe

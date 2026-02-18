# Keycloak Control Matrix (STIG / NIST 800-53 Alignment)
## Motorcade SSO: High-Level Mapping

This is a practical mapping of implemented hardening behaviors to common control families.
It is not a replacement for a formal SSP, but it provides traceability.

---

| Control Family | Theme | Implemented Behavior |
|---|---|---|
| AC-2 | Account Management | Permanent admin creation + removal of temporary bootstrap admin |
| AC-6 | Least Privilege | Keycloak runs as non-root UID 1000; roles assigned explicitly |
| AU-2 / AU-6 | Auditing | Admin actions should be recorded; docs require operator audit notes |
| CM-2 / CM-6 | Baseline Config | Ansible codifies data/tmp creation and SELinux persistence |
| IA-2 | Identification & Auth | Centralized SSO via Keycloak; admin creds stored in Secrets Manager |
| SC-8 | Transmission Confidentiality | TLS enforced at ingress; HTTPS-only for sso.motorcade.vip |
| SC-28 | Protect at Rest | SELinux labeling for container volume data path |
| SI-7 | Integrity | ReadonlyRootfs and minimized container capabilities reduce tampering risk |

---

# Notes

- This mapping should be expanded later with:
  - exact STIG IDs
  - SSP references
  - evidence artifacts and timestamps

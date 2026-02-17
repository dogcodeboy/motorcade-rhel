Motorcade RHEL 10.1 GOLDEN Image Baseline

Acceptance & Fingerprint Record
Date: 2026-02-17
Host: motorcade-prod-01
Instance Type: t3.small
AMI Source: Custom RHEL 10.1 (Image Builder, FIPS Enabled, STIG Aligned)

1. Operating System
Red Hat Enterprise Linux 10.1 (Coughlan)
Kernel: 6.12.0-124.35.1.el10_1.x86_64
Architecture: x86_64
Virtualization: Amazon EC2


Enabled Repositories:

rhel-10-for-x86_64-baseos-rpms

rhel-10-for-x86_64-appstream-rpms

No external repos enabled.

2. FIPS Status
/proc/sys/crypto/fips_enabled = 1
update-crypto-policies --show = FIPS


OpenSSL FIPS provider present:

openssl-fips-provider

openssl-fips-provider-so

gnutls-fips

Status: FIPS enabled and enforced at kernel + crypto policy level

3. SELinux
SELinux: Enforcing
Policy: targeted
MLS: enabled
deny_unknown: allowed


Relevant packages:

selinux-policy-targeted

container-selinux

rpm-plugin-selinux

Status: Fully enforcing

4. Audit & Logging
auditd: enabled + active
audit backlog limit: 8192
failure mode: 2 (panic on failure)


Installed:

audit

audit-rules

rpm-plugin-audit

scap-security-guide

openscap

AIDE installed:

aide-0.18.6

Status: STIG-compatible auditing enabled

5. Firewall
firewalld: enabled + active
Default zone: public
Open services: ssh, cockpit, dhcpv6-client
Open ports: 80/tcp, 443/tcp (manually added)


All other ports closed by default.

Status: Default deny posture

6. SSH & Access Control
PermitRootLogin: no
PasswordAuthentication: no
PubkeyAuthentication: yes
Port: 22


SSM Agent:

amazon-ssm-agent: enabled + active


Login banner present (federal compliance language).

Status: Key-based SSH + SSM enforced

7. Podman / Container Runtime

Version:

podman 5.6.0


Configuration:

cgroup v2
cgroupManager: systemd
networkBackend: netavark
rootless: false
graphRoot: /var/lib/containers/storage


Installed stack:

podman

buildah

skopeo

conmon

crun

containers-common

fuse-overlayfs

netavark

Status: Native RHEL container stack (no weird manual install)

8. Security Baseline Packages

Installed security tooling includes:

aide

audit

openscap

scap-security-guide

fapolicyd

usbguard

tpm2-tools

crypto-policies

openssl-fips-provider

This confirms Image Builder baked in STIG-level hardening components.

9. DNF History (Drift from Image)

Post-image modifications:

ID	Action	Notes
7	install postgresql	Added manually
6	install skopeo	Added manually
5	install realmd + sssd	Added manually
4	install tuned	Added manually
3	install rhc-worker-playbook	Added manually
2	install amazon-ssm-agent	Added manually
1	remove tuned	Removed earlier

This confirms:

Base image is mostly intact

PostgreSQL was manually added

SSSD stack was manually added

No random third-party repo drift

10. Observations

This Golden image is clean.

FIPS is truly enabled (kernel + crypto policy).

SELinux enforcing.

Audit + SCAP present.

Podman stack is native and correct.

No suspicious packages.

Only minimal drift via DNF.

This is production-grade baseline material.

Architectural Implications

This Golden Image is suitable for:

motorcade-prod-01 (current)

motorcade-stage-01 (clone baseline)

motorcade-edge-01 (future reverse proxy split)

motorcade-admin-01 (future control plane split)

Because:

Container runtime is native

Security stack is present

No Amazon Linux hacks

FIPS compatible for federal compliance

SCAP ready for automated compliance scans

Required Next Documentation Updates

We must now:

Update RUNBOOK naming conventions to reflect:

motorcade-prod-01

motorcade-stage-01

motorcade-edge-01

motorcade-admin-01

Document that:

All new nodes MUST derive from this Golden Image

No manual RPM installs allowed without Ansible codification

Drift must be recorded in DNF history

Define:

Stage VPC design

RDS attachment model

Container migration plan from AL2023 → RHEL

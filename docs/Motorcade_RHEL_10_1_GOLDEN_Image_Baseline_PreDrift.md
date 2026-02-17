# Motorcade RHEL 10.1 GOLDEN Image Baseline

**Pre-Boot Drift Specification (Factory State Only)**\
Generated: 2026-02-17 03:03:55Z

------------------------------------------------------------------------

## 1. Operating System

-   Distribution: Red Hat Enterprise Linux 10.1 (Coughlan)
-   Architecture: x86_64
-   Virtualization: Amazon EC2
-   Kernel Series: 6.12.x (RHEL 10.1 stream)
-   Platform ID: el10
-   Repositories Enabled:
    -   rhel-10-for-x86_64-baseos-rpms
    -   rhel-10-for-x86_64-appstream-rpms

No external repositories enabled in base image.

------------------------------------------------------------------------

## 2. FIPS Configuration

-   /proc/sys/crypto/fips_enabled = 1
-   update-crypto-policies = FIPS
-   OpenSSL FIPS provider installed
-   GnuTLS FIPS libraries present

**Status:** Kernel-level FIPS enabled and crypto policy enforced.

------------------------------------------------------------------------

## 3. SELinux

-   Mode: Enforcing
-   Policy: targeted
-   MLS: enabled
-   deny_unknown: allowed

Installed components: - selinux-policy - selinux-policy-targeted -
container-selinux

**Status:** Fully enforcing SELinux at boot.

------------------------------------------------------------------------

## 4. Audit & Compliance Stack

-   auditd enabled at boot
-   rpm-plugin-audit installed
-   scap-security-guide present
-   openscap scanner present
-   aide installed (file integrity monitoring)

**Status:** STIG-aligned baseline present.

------------------------------------------------------------------------

## 5. Firewall Baseline

-   firewalld enabled
-   Default zone: public
-   Default open service: ssh
-   No additional ports opened by default

**Status:** Default-deny posture except SSH.

------------------------------------------------------------------------

## 6. Access Model

-   Root login disabled
-   Password authentication disabled
-   Public key authentication enabled
-   Amazon SSM Agent installed and enabled
-   Federal compliance login banner configured

**Status:** SSH hardened + SSM enabled.

------------------------------------------------------------------------

## 7. Container Runtime (Factory State)

-   Podman 5.6.x
-   buildah
-   skopeo
-   conmon
-   crun
-   containers-common
-   fuse-overlayfs
-   netavark
-   cgroup v2
-   systemd cgroup manager

Graph root: /var/lib/containers/storage

Rootless: false (system-level container management)

**Status:** Native RHEL container stack baked into image.

------------------------------------------------------------------------

## 8. Security Modules Present

-   fapolicyd
-   usbguard
-   tpm2-tools
-   crypto-policies
-   openssl-fips-provider
-   openscap
-   scap-security-guide

------------------------------------------------------------------------

## 9. Base System Characteristics

-   Cloud-init enabled
-   NetworkManager enabled
-   chrony enabled
-   firewalld enabled
-   auditd enabled
-   SELinux enforcing
-   FIPS enabled

No application containers included in Golden baseline.

------------------------------------------------------------------------

## 10. Golden Image Intent

This image is designed to serve as the canonical base for:

-   motorcade-prod-01
-   motorcade-stage-01
-   motorcade-edge-01 (future)
-   motorcade-admin-01 (future control plane split)

All environment-specific configuration must be layered via Ansible or
container deployment. No manual RPM installation permitted without
documentation and automation.

------------------------------------------------------------------------

**End of Golden Image Baseline Specification**

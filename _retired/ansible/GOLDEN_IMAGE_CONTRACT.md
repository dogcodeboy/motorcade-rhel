# Golden Image Contract

## Purpose
This repository is split into two execution lanes:

1. Bake lane: build and harden the AMI.
2. Instance lane: validate and enforce lightweight runtime config on instances launched from that AMI.

## Baked AMI Requirements
The baked AMI must include and provide:

1. Podman binary at `/usr/local/bin/podman` or `/usr/bin/podman`.
2. Baseline services present: `chronyd`, `auditd`, `firewalld`.
3. Required directories:
   - `/srv/motorcade`
   - `/srv/motorcade/volumes`
   - `/srv/motorcade/config`
4. SELinux available and configurable in enforcing mode.
5. CAC readiness packages installed (for optional smartcard use):
   - `pcsc-lite`, `pcsc-lite-ccid`, `opensc`, `opensc-pkcs11`, `sssd`, `pam_pkcs11`.

## Must Not Run During Instance Bootstrap
The instance lane must not perform bake-only or disruptive image mutations:

1. No blanket `dnf upgrade` / `state=latest` patch waves.
2. No FIPS enablement, initramfs rebuild, or bootloader mutations.
3. No repo-enabling/disabling churn intended for image build pipelines.
4. No heavyweight package installation as part of normal bootstrap.

If validation fails, rebake the image or fix the Image Builder blueprint.

## Playbook Lanes

### Bake lane (Image Builder / bake hosts)
Run:

```bash
cd ansible
ansible-playbook -i inventories/prod/hosts.ini playbooks/BAKE_BASE.yml \
  --vault-password-file ~/.ansible_vault_pass
```

### Instance lane (launched EC2 instances)
Run:

```bash
cd ansible
ansible-playbook -i inventories/prod/hosts.ini playbooks/INSTANCE_BASE.yml \
  --vault-password-file ~/.ansible_vault_pass
```

## Smoke Validation

```bash
cd ansible
ansible-playbook -i inventories/prod/hosts.ini playbooks/INSTANCE_BASE.yml \
  --check --diff --vault-password-file ~/.ansible_vault_pass
```

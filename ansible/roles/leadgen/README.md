# Role: leadgen

Deploy LeadGen API on hardened RHEL using Podman + systemd/quadlet.
Secrets are retrieved from AWS Secrets Manager and written only to runtime paths under /run.

## Security/Compliance
- No secrets in repo or Ansible Vault
- Runtime secret file: /run/motorcade/leadgen/leadgen.env (0600 root:root)
- Quadlet-managed container (auditable systemd unit)

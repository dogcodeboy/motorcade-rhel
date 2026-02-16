# RHEL 10.1 Bootstrap Runbook (Motorcade)

## What INFRA_ALL does
1) **INFRA_01**: dnf update + baseline tools + NTP + create `/srv/motorcade` dirs  
2) **INFRA_02**: Podman runtime install (default: locked-path static binary to `/usr/local/bin/podman`)  
3) **INFRA_03**: Nginx official container via Quadlet (rootless), bound to :80/:443 with `/healthz`  

Postgres + Keycloak are **separate playbooks** so you can keep your base AMIs clean.

## AMI strategy (pragmatic)
- **Base AMI**: INFRA_01 + INFRA_02
- **Web AMI**: Base + INFRA_03
- **DB AMI**: Base + INFRA_04 (private-only)

## VPC notes
- Put Postgres in **private subnets** with **no public IP**.
- Allow inbound 5432 only from the **app servers’ security group** (or via SSM/bastion).
- Nginx/web: inbound 80/443 from the internet (prod only).

## Run
```bash
cd ansible
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

ansible-lint
yamllint .

ansible-playbook -i inventories/prod/hosts.ini playbooks/INFRA_ALL.yml --ask-vault-pass
ansible-playbook -i inventories/prod/hosts.ini playbooks/INFRA_04_postgres_container.yml --ask-vault-pass
ansible-playbook -i inventories/prod/hosts.ini playbooks/INFRA_05_keycloak_container.yml --ask-vault-pass
```

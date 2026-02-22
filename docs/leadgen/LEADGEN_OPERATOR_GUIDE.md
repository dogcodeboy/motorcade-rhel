# LeadGen Operator Guide (Idiot-Proof)

## What this system does
People fill out forms on the Motorcade website. Those submissions become “leads” stored in the database.

## What you should NOT do
- Do NOT put passwords in `.env` files.
- Do NOT store secrets in git.
- Do NOT edit server config by hand. Use Ansible.

## Where leads come in
Website → `/api/lead-intake` (nginx) → LeadGen API → RDS database

## How to deploy (high level)
1. Ensure AWS Secrets exist (DB + API key)
2. Run the LeadGen playbooks from `motorcade-rhel`
3. Validate health + DB insert

## How to validate it’s working
- Health check returns OK:
  - `curl http://127.0.0.1:<LEADGEN_PORT>/lead/health`
- A test lead inserts:
  - `curl -H "Host: motorcade.vip" -X POST http://127.0.0.1/api/lead-intake -d '{"email":"test@example.com","full_name":"Test"}'`
- Confirm DB shows the new record in:
  - `app.intake_jobs`
  - `app.leads`

## Common failures
### 404 on /api/lead-intake
nginx proxy route is missing or not loaded.

### 401 / unauthorized from LeadGen
nginx did not inject `X-API-Key`, or the secret is wrong.

### DB connection failed
- RDS endpoint blocked by security group
- Secrets Manager DB secret missing required keys
- SSL mode mismatch

## Who to contact
OWNERs hold authority for changes. All changes must be auditable and done via Ansible.

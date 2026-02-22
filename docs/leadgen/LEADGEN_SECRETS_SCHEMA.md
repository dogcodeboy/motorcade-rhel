# LeadGen Secrets Manager Schema

## Principle
Secrets Manager stores JSON objects. Ansible retrieves SecretString and parses JSON.

## leadgen_db_secret (JSON)
Required keys:
- host OR endpoint
- username OR user
- password

Optional:
- port (default 5432)
- dbname (default leadgen)

## leadgen_intake_api_key_secret (JSON)
Required keys:
- api_key (preferred) OR key

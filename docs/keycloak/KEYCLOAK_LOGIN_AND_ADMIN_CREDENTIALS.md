# Keycloak Login & Admin Credentials (AWS Secrets Manager)
## Bootstrap Admin, Permanent Admin, and Credential Handling

This environment uses AWS Secrets Manager as the source of truth for Keycloak administrative credentials.

---

# 1) Where credentials come from

Keycloak admin login credentials MUST be retrieved from AWS Secrets Manager.

Rationale:
- Secrets must not be hardcoded in repos
- Secrets must not be stored in notes or terminal history
- Secrets must be rotatable and auditable

---

# 2) Bootstrap / Temporary Admin

Keycloak may be bootstrapped with a temporary admin user. When logged in, the UI can display:

"You are logged in as a temporary admin user. To harden security, create a permanent admin account and delete the temporary one."

This warning is expected and should be treated as a hardening requirement.

---

# 3) How to retrieve credentials from AWS Secrets Manager

Retrieve the secret using AWS CLI (examples; actual secret name/ARN is environment-defined):

aws secretsmanager get-secret-value --secret-id <SECRET_NAME_OR_ARN> --query SecretString --output text

If SecretString is JSON:

aws secretsmanager get-secret-value --secret-id <SECRET_NAME_OR_ARN> --query SecretString --output text | jq .

Expected fields (example):
- username
- password

---

# 4) Hardening procedure: create permanent admin, delete temporary admin

## 4.1 Create a permanent admin user
In Keycloak Admin Console:
- Realm: master (or the appropriate realm)
- Users -> Add user
- Set:
  - Username (named, trackable)
  - Email (optional but recommended)
  - Email verified (policy-dependent)
- Create
- Credentials -> Set password (temporary OFF unless required)
- Role mappings:
  - Assign realm-management roles needed for admin
  - Prefer least privilege where feasible

## 4.2 Delete the temporary bootstrap admin
Once the permanent admin is verified:
- Users -> select the temporary admin
- Delete user

This removes a known bootstrap credential from the system.

---

# 5) Rotation

After creating a permanent admin:
- Rotate the bootstrap secret in AWS Secrets Manager
- Ensure any automation referencing bootstrap creds is updated/disabled
- Confirm no systems depend on the temporary admin

---

# 6) Audit Notes

Record:
- who created the permanent admin
- when bootstrap admin was deleted
- which secret name/ARN was used
- rotation timestamp

All admin identity operations are sensitive and must be auditable.

# Troubleshooting (STIG-Safe)

## Safe evidence commands
- `sudo podman ps -a --filter name=motorcade-keycloak`
- `sudo podman logs --tail 200 motorcade-keycloak`
- `sudo ss -lntp | grep :8081`

Do not print container env values in evidence.

## Common issues
### 1) Secrets missing / schema mismatch
Symptoms:
- role asserts fail
Fix:
- ensure secret IDs are set in inventory
- ensure secret JSON uses canonical keys (host/port/dbname/username/password)

### 2) Keycloak falls back to H2
Symptoms:
- logs indicate default DB
Fix:
- ensure runtime env injection is present for create tasks
- ensure env template contains KC_DB=postgres and KC_DB_URL/USERNAME/PASSWORD

### 3) Optimized first-start error
Symptoms:
- `--optimized flag used for first ever server start`
Fix:
- ensure optimized image build step exists and steady-state uses optimized image

### 4) Read-only filesystem failures
Symptoms:
- ReadOnlyFileSystemException
Fix:
- ensure steady-state read-only is paired with correct tmpfs/volume strategy
- ensure writes occur only to intended mounted data directory

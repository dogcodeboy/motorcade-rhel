# Keycloak Runbook: Recovery & Validation
## Podman / SELinux / Console Load Failures

This runbook covers:
- “Loading the Administration Console” hangs
- JS bundles returning 500
- tmp/data write failures
- SELinux context regressions
- safe validation checks

---

# 1) Quick Health Checks

## 1.1 Reverse proxy (Nginx) and endpoints
curl -kIsS https://sso.motorcade.vip/ | head -n 30
curl -kIsS https://sso.motorcade.vip/admin/ | head -n 30
curl -kIsS https://sso.motorcade.vip/realms/master | head -n 30
curl -kIsS https://sso.motorcade.vip/realms/master/.well-known/openid-configuration | head -n 30

Expected:
- / -> 302 to /admin/
- realm endpoints -> 200

---

# 2) Identify Keycloak container and inspect runtime
KC="motorcade-keycloak"
sudo podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | sed -n '1,5p'
sudo podman inspect "$KC" --format "User={{.Config.User}} ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}}"

Expected:
- User=1000 (or equivalent non-root)
- ReadonlyRootfs=true

---

# 3) Common failure: tmp path not writable

## 3.1 Confirm mount and permissions
sudo podman inspect "$KC" --format '{{json .Mounts}}' | jq .
sudo ls -laZ /srv/motorcade/keycloak/data /srv/motorcade/keycloak/data/tmp || true

## 3.2 Confirm container can write
sudo podman exec --user 1000 "$KC" sh -lc \
  "mkdir -p /opt/keycloak/data/tmp && touch /opt/keycloak/data/tmp/_write_test && ls -la /opt/keycloak/data/tmp | head"

Expected:
- No permission errors

---

# 4) Immediate runtime fix (if ownership wrong)

If /srv/motorcade/keycloak/data is root:root, fix it:

sudo mkdir -p /srv/motorcade/keycloak/data/tmp
sudo chown -R 1000:0 /srv/motorcade/keycloak/data
sudo chmod 0750 /srv/motorcade/keycloak/data
sudo chmod 0770 /srv/motorcade/keycloak/data/tmp
sudo restorecon -Rv /srv/motorcade/keycloak/data || true

Restart:
sudo podman restart "$KC"

---

# 5) Validate admin console JS asset loads (fast test)

Fetch /admin/ HTML and extract a main-*.js bundle path:

HTML=$(mktemp); trap 'rm -f "$HTML"' EXIT
curl -kLsS https://sso.motorcade.vip/admin/ > "$HTML"
JS_PATH=$(sed -n 's/.*src="\([^"]*main-[^"]*\.js\)".*/\1/p' "$HTML" | head -n 1 || true)
echo "JS_PATH=$JS_PATH"
[ -n "$JS_PATH" ] && curl -kIsS "https://sso.motorcade.vip$JS_PATH" | head -n 20

Expected:
- HTTP 200 on JS bundle

---

# 6) SELinux persistence (should be codified)

If repeated relabel issues occur, ensure persistent fcontext exists:

sudo semanage fcontext -l | grep -F "/srv/motorcade/keycloak/data(/.*)?"

If missing (one-time fix):
sudo semanage fcontext -a -t container_file_t "/srv/motorcade/keycloak/data(/.*)?"
sudo restorecon -Rv /srv/motorcade/keycloak/data

---

# 7) Logging

Keycloak logs:
sudo podman logs "$KC" --tail 200

Common indicator of this class of failure:
- inability to create /opt/keycloak/data/tmp
- admin JS bundles failing with 500

---

# 8) Rebuild-safe fix location

Persistent remediations must live in motorcade-rhel (the controlling repo),
in the Ansible role that launches motorcade-keycloak.

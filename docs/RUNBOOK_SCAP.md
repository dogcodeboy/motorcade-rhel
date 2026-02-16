# RUNBOOK_SCAP

## Scope
Run SCAP content with `oscap` and store dated outputs for audit retention.

## Run
```bash
ANSIBLE_CONFIG=ansible.cfg ansible-playbook -i ansible/inventories/prod/hosts.ini ansible/playbooks/95_scap_scan.yml
```

## Output location
- `/srv/motorcade/audit/scap/YYYY-MM-DD/results.xml`
- `/srv/motorcade/audit/scap/YYYY-MM-DD/report.html`
- `/srv/motorcade/audit/scap/YYYY-MM-DD/oscap_run.txt`

## Notes
- Profile defaults to STIG profile in the playbook.
- If profile/datastream mismatch occurs, check `oscap_run.txt` first.

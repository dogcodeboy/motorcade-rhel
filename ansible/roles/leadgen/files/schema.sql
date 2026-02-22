-- LeadGen schema (idempotent-ish; safe to re-run)
CREATE SCHEMA IF NOT EXISTS app;

-- Durable intake job queue
CREATE TABLE IF NOT EXISTS app.intake_jobs (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'queued',
  payload JSONB NOT NULL,
  last_error TEXT NULL
);

-- Leads table (create if missing)
CREATE TABLE IF NOT EXISTS app.leads (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  full_name TEXT NULL,
  email TEXT NULL,
  phone TEXT NULL,
  service_type TEXT NULL,
  intake_type TEXT NULL,
  source_page TEXT NULL,

  -- forward-compatible full payload
  payload JSONB NULL,

  -- lifecycle / conversion fields
  status TEXT NOT NULL DEFAULT 'new',
  converted_user_id TEXT NULL,
  converted_at TIMESTAMPTZ NULL,
  converted_by_employee_email TEXT NULL,
  converted_identity_provider TEXT NULL
);

-- Ensure payload column exists if table pre-existed without it
ALTER TABLE app.leads ADD COLUMN IF NOT EXISTS payload JSONB NULL;

-- Useful indexes for employee UI sorting/filtering later
CREATE INDEX IF NOT EXISTS leads_created_at_idx ON app.leads (created_at DESC);
CREATE INDEX IF NOT EXISTS leads_email_lower_idx ON app.leads (lower(email));
CREATE INDEX IF NOT EXISTS leads_status_idx ON app.leads (status);

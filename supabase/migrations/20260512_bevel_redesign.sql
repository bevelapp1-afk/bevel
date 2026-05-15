-- Bevel redesign schema for the zero-build Glass CRM.
-- The app stores the full client-side object in data JSONB while exposing
-- first-class tables for future normalized reporting and integrations.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS allowed_users (
  email TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS jobs (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  customer_id TEXT,
  job_type TEXT,
  install_address TEXT,
  assigned_to TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS job_measurements (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  job_id TEXT REFERENCES jobs(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS estimates (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  customer_id TEXT,
  job_id TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS estimate_line_items (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  estimate_id TEXT REFERENCES estimates(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoices (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  customer_id TEXT,
  job_id TEXT,
  estimate_id TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice_line_items (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  invoice_id TEXT REFERENCES invoices(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS attachments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  target_type TEXT,
  target_id TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS job_updates (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  job_id TEXT,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pipeline_stages (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  name TEXT,
  "order" INTEGER NOT NULL DEFAULT 0,
  color TEXT DEFAULT '#64748B',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS job_types (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  name TEXT,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS team_members (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  name TEXT,
  role TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS item_dictionary (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS settings (
  id TEXT PRIMARY KEY DEFAULT 'main',
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO pipeline_stages (id, name, "order", color, data) VALUES
  ('stage-1', 'Lead', 1, '#0EA5E9', '{"label":"Lead","color":"#0EA5E9"}'),
  ('stage-2', 'Measured', 2, '#EAB308', '{"label":"Measured","color":"#EAB308"}'),
  ('stage-3', 'Quoted', 3, '#F97316', '{"label":"Quoted","color":"#F97316"}'),
  ('stage-4', 'Approved', 4, '#22C55E', '{"label":"Approved","color":"#22C55E"}'),
  ('stage-5', 'Ordered', 5, '#06B6D4', '{"label":"Ordered","color":"#06B6D4"}'),
  ('stage-6', 'Pending Install', 6, '#64748B', '{"label":"Pending Install","color":"#64748B"}'),
  ('stage-7', 'Installed', 7, '#10B981', '{"label":"Installed","color":"#10B981"}'),
  ('stage-8', 'Paid', 8, '#16A34A', '{"label":"Paid","color":"#16A34A"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO job_types (id, name, "order", data) VALUES
  ('jt-1', 'Shower', 1, '{"name":"Shower"}'),
  ('jt-2', 'Mirror', 2, '{"name":"Mirror"}'),
  ('jt-3', 'Tub', 3, '{"name":"Tub"}'),
  ('jt-4', 'Other', 4, '{"name":"Other"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO settings (id, data) VALUES ('main', '{}'::jsonb)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE allowed_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimate_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_dictionary ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  table_name TEXT;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'allowed_users','customers','jobs','job_measurements','estimates',
    'estimate_line_items','invoices','invoice_line_items','attachments',
    'job_updates','pipeline_stages','job_types','team_members',
    'item_dictionary','settings','audit_log'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Authenticated users manage %s" ON %I', table_name, table_name);
    EXECUTE format('CREATE POLICY "Authenticated users manage %s" ON %I FOR ALL TO authenticated USING (true) WITH CHECK (true)', table_name, table_name);
  END LOOP;
END $$;

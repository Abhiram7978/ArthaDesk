-- ═══════════════════════════════════════════════════════════════
-- ArthaDesk v3.9 — COMPLETE FRESH SCHEMA
-- Run this ONCE in Supabase → SQL Editor → New Query → Run
-- This creates ALL tables needed for the app to work.
-- ═══════════════════════════════════════════════════════════════

-- ── 1. APP DATA ───────────────────────────────────────────────
-- Stores all company data, invoices, ledgers etc per user
CREATE TABLE IF NOT EXISTS public.app_data (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     TEXT        NOT NULL,
  data_key    TEXT        NOT NULL,
  data_value  JSONB,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, data_key)
);
CREATE INDEX IF NOT EXISTS idx_app_data_user_key ON public.app_data (user_id, data_key);
ALTER TABLE public.app_data DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.app_data TO anon, authenticated, service_role;

-- ── 2. APPROVED USERS ─────────────────────────────────────────
-- Only users created by admin can login
CREATE TABLE IF NOT EXISTS public.approved_users (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name           TEXT        NOT NULL,
  email               TEXT        NOT NULL UNIQUE,
  password            TEXT        NOT NULL,
  is_active           BOOLEAN     DEFAULT true,
  assigned_companies  TEXT[]      DEFAULT '{}',
  created_at          TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.approved_users DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.approved_users TO anon, authenticated, service_role;

-- ── 3. ADMIN CONFIG ───────────────────────────────────────────
-- Stores admin login credentials (single row)
CREATE TABLE IF NOT EXISTS public.admin_config (
  id              INT         PRIMARY KEY DEFAULT 1,
  admin_email     TEXT        NOT NULL DEFAULT 'admin@arthadesk.in',
  admin_password  TEXT        NOT NULL DEFAULT 'ArthaAdmin@2025',
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.admin_config DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.admin_config TO anon, authenticated, service_role;

-- Insert default admin (change password after first login!)
INSERT INTO public.admin_config (id, admin_email, admin_password)
VALUES (1, 'admin@arthadesk.in', 'ArthaAdmin@2025')
ON CONFLICT (id) DO NOTHING;

-- ── 4. ADMIN COMPANIES ────────────────────────────────────────
-- Master list of companies created by admin
CREATE TABLE IF NOT EXISTS public.admin_companies (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name                TEXT        NOT NULL,
  gstin               TEXT,
  assigned_to_email   TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.admin_companies DISABLE ROW LEVEL SECURITY;
GRANT ALL ON public.admin_companies TO anon, authenticated, service_role;

-- ── 5. REALTIME ───────────────────────────────────────────────
-- Enable live sync across devices
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_data;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.approved_users;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_companies;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END $$;

-- ── 6. AUTO-UPDATE TIMESTAMP ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$;

DROP TRIGGER IF EXISTS trg_app_data_updated ON public.app_data;
CREATE TRIGGER trg_app_data_updated
  BEFORE UPDATE ON public.app_data
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ═══════════════════════════════════════════════════════════════
-- ✅ DONE — All 4 tables created with full access
--
-- Default Admin Login:
--   URL:      https://abhiram7978.github.io/ArthaDesk/admin.html
--   Email:    admin@arthadesk.in
--   Password: ArthaAdmin@2025
--
-- ⚠️ Change the admin password immediately after first login!
--    Admin Panel → Settings → Change Admin Password
-- ═══════════════════════════════════════════════════════════════

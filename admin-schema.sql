-- ═══════════════════════════════════════════════════════════════
-- ArthaDesk — Admin Schema  (run this AFTER schema.sql)
-- ═══════════════════════════════════════════════════════════════
-- Run in Supabase SQL Editor → New Query → Paste → Run
-- ═══════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────
-- 1. APPROVED USERS
--    Admin creates entries here. Only these users can login.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.approved_users (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name           TEXT        NOT NULL,
  email               TEXT        NOT NULL UNIQUE,
  password            TEXT        NOT NULL,
  is_active           BOOLEAN     DEFAULT true,
  assigned_companies  TEXT[]      DEFAULT '{}',
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Allow anyone to read (needed for login check from browser)
ALTER TABLE public.approved_users DISABLE ROW LEVEL SECURITY;


-- ──────────────────────────────────────────────────────────────
-- 2. ADMIN COMPANIES
--    Master list of companies created by admin
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_companies (
  id                  UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name                TEXT        NOT NULL,
  gstin               TEXT,
  assigned_to_email   TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_companies DISABLE ROW LEVEL SECURITY;


-- ──────────────────────────────────────────────────────────────
-- 3. ADMIN CONFIG
--    Single row — stores admin credentials
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_config (
  id              INT         PRIMARY KEY DEFAULT 1,
  admin_email     TEXT        DEFAULT 'admin@arthadesk.in',
  admin_password  TEXT        DEFAULT 'ArthaAdmin@2025',
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.admin_config DISABLE ROW LEVEL SECURITY;

-- Insert default admin credentials (change these immediately after setup!)
INSERT INTO public.admin_config (id, admin_email, admin_password)
VALUES (1, 'admin@arthadesk.in', 'ArthaAdmin@2025')
ON CONFLICT (id) DO NOTHING;


-- ──────────────────────────────────────────────────────────────
-- DONE ✅
-- Default admin credentials:
--   Email   : admin@arthadesk.in
--   Password: ArthaAdmin@2025
--
-- ⚠️  CHANGE THE PASSWORD immediately after first login!
--     Admin Panel → Settings → Change Admin Password
-- ──────────────────────────────────────────────────────────────

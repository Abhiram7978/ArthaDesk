-- ═══════════════════════════════════════════════════════════════
-- ArthaDesk — Supabase PostgreSQL Schema  v3.9
-- ═══════════════════════════════════════════════════════════════
-- Run this entire file in your Supabase SQL Editor:
--   Dashboard → SQL Editor → New Query → paste → Run
-- ═══════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────
-- 1. APP DATA  (key-value store per user)
--    Stores every blSave() call: company state, invoices,
--    ledgers, stock items, receipts, payments, etc.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.app_data (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  data_key    TEXT        NOT NULL,
  data_value  JSONB,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, data_key)
);

-- Index for fast per-user lookups
CREATE INDEX IF NOT EXISTS idx_app_data_user_key
  ON public.app_data (user_id, data_key);

-- Auto-update updated_at on every write
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_app_data_updated ON public.app_data;
CREATE TRIGGER trg_app_data_updated
  BEFORE UPDATE ON public.app_data
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ──────────────────────────────────────────────────────────────
-- 2. ROW LEVEL SECURITY
--    Each user can only see and modify their own rows.
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.app_data ENABLE ROW LEVEL SECURITY;

-- Users can select their own rows
CREATE POLICY "Users can read own data"
  ON public.app_data FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own rows
CREATE POLICY "Users can insert own data"
  ON public.app_data FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own rows
CREATE POLICY "Users can update own data"
  ON public.app_data FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own rows
CREATE POLICY "Users can delete own data"
  ON public.app_data FOR DELETE
  USING (auth.uid() = user_id);


-- ──────────────────────────────────────────────────────────────
-- 3. USER PROFILES  (optional — extends Supabase auth.users)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name   TEXT,
  phone       TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile row when a new user registers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'phone'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ──────────────────────────────────────────────────────────────
-- 4. GRANT PERMISSIONS TO authenticated ROLE
-- ──────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL   ON public.app_data  TO authenticated;
GRANT ALL   ON public.profiles  TO authenticated;


-- ──────────────────────────────────────────────────────────────
-- 5. REALTIME  (enable live sync across devices)
-- ──────────────────────────────────────────────────────────────
-- Run these manually in the Supabase dashboard or via SQL:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.app_data;


-- ──────────────────────────────────────────────────────────────
-- DONE ✅
-- After running this, go to Supabase Dashboard:
--   Authentication → Settings → Enable "Confirm email" = OFF
--   (for easier local testing) or configure your SMTP for production.
-- ──────────────────────────────────────────────────────────────

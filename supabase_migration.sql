-- =============================================================
-- FabriScan AI – Supabase SQL Migration (Live/Production Ready)
-- Run this in Supabase SQL Editor (Dashboard -> SQL Editor)
-- =============================================================

BEGIN;

-- ── 1) Core Extension ─────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── 2) Generic updated_at trigger helper ─────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ── 3) Materials Catalog (matches model labels) ──────────────
CREATE TABLE IF NOT EXISTS public.materials (
  code        TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  properties  JSONB NOT NULL DEFAULT '{}'::jsonb,
  suggestions JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT materials_code_upper CHECK (code = UPPER(code)),
  CONSTRAINT materials_name_not_blank CHECK (LENGTH(TRIM(name)) > 0),
  CONSTRAINT materials_properties_is_object CHECK (jsonb_typeof(properties) = 'object'),
  CONSTRAINT materials_suggestions_is_array CHECK (jsonb_typeof(suggestions) = 'array')
);

DROP TRIGGER IF EXISTS trg_materials_updated_at ON public.materials;
CREATE TRIGGER trg_materials_updated_at
BEFORE UPDATE ON public.materials
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Seed full label set used by backend/main.py CLASS_NAMES.
INSERT INTO public.materials (code, name)
VALUES
  ('ACETATE', 'Acetate'),
  ('ACRYLIC', 'Acrylic'),
  ('ALKANTRA', 'Alkantra'),
  ('ANGORA', 'Angora'),
  ('CASHMERE', 'Cashmere'),
  ('CHECK', 'Check'),
  ('COTTON', 'Cotton'),
  ('CS', 'Cs'),
  ('DANTELA', 'Dantela'),
  ('DRALON', 'Dralon'),
  ('ELASTANE', 'Elastane'),
  ('ERION', 'Erion'),
  ('FIBERS', 'Fibers'),
  ('FLAX', 'Flax'),
  ('FLEECE', 'Fleece'),
  ('HASIR', 'Hasir'),
  ('IANAI', 'Ianai'),
  ('LEATHER', 'Leather'),
  ('LI', 'Li'),
  ('LINATSA', 'Linatsa'),
  ('LINEN', 'Linen'),
  ('LUT', 'Lut'),
  ('LYCRA', 'Lycra'),
  ('MANDARINE', 'Mandarine'),
  ('MICROPOLY', 'Micropoly'),
  ('MODAL', 'Modal'),
  ('NAYLON', 'Naylon'),
  ('NYLON', 'Nylon'),
  ('PES', 'Pes'),
  ('PLEKTO', 'Plekto'),
  ('POLYAMIDE', 'Polyamide'),
  ('POLYESTER', 'Polyester'),
  ('PVC', 'Pvc'),
  ('RAY', 'Ray'),
  ('RAYON', 'Rayon'),
  ('REPREVE', 'Repreve'),
  ('SATIN', 'Satin'),
  ('SETA', 'Seta'),
  ('SIFON', 'Sifon'),
  ('SILK', 'Silk'),
  ('SP', 'Sp'),
  ('SPANDEX', 'Spandex'),
  ('SUPPLEX', 'Supplex'),
  ('SYNTHETIC', 'Synthetic'),
  ('TAFTA', 'Tafta'),
  ('TSOXA', 'Tsoxa'),
  ('VELVET', 'Velvet'),
  ('VISCOSE', 'Viscose'),
  ('WOOL', 'Wool')
ON CONFLICT (code)
DO UPDATE
SET
  name = EXCLUDED.name,
  is_active = TRUE,
  updated_at = NOW();

-- ── 4) Scans table ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.scans (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  fabric_type TEXT NOT NULL,
  confidence  NUMERIC(5,2) NOT NULL,
  image_url   TEXT,
  chart_data  JSONB NOT NULL DEFAULT '[]'::jsonb,
  properties  JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure required columns exist for older deployments.
ALTER TABLE public.scans
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS chart_data JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS properties JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Normalize old rows so constraints can validate safely.
UPDATE public.scans
SET
  fabric_type = UPPER(TRIM(fabric_type)),
  confidence = LEAST(GREATEST(confidence, 0), 100),
  chart_data = COALESCE(chart_data, '[]'::jsonb),
  properties = COALESCE(properties, '{}'::jsonb)
WHERE
  fabric_type <> UPPER(TRIM(fabric_type))
  OR confidence < 0
  OR confidence > 100
  OR chart_data IS NULL
  OR properties IS NULL;

-- Remove old constraints/policies before recreating idempotently.
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_fabric_type_check;
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_confidence_check;
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_chart_data_is_array;
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_properties_is_object;
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_fabric_type_not_blank;
ALTER TABLE public.scans DROP CONSTRAINT IF EXISTS scans_fabric_type_fk;

ALTER TABLE public.scans
  ADD CONSTRAINT scans_confidence_check CHECK (confidence BETWEEN 0 AND 100),
  ADD CONSTRAINT scans_fabric_type_not_blank CHECK (
    LENGTH(TRIM(fabric_type)) > 0
    AND fabric_type = UPPER(fabric_type)
  ),
  ADD CONSTRAINT scans_chart_data_is_array CHECK (jsonb_typeof(chart_data) = 'array'),
  ADD CONSTRAINT scans_properties_is_object CHECK (jsonb_typeof(properties) = 'object');

-- Backfill unknown legacy fabric labels into materials before FK creation.
INSERT INTO public.materials (code, name)
SELECT DISTINCT
  UPPER(TRIM(s.fabric_type)) AS code,
  INITCAP(LOWER(TRIM(s.fabric_type))) AS name
FROM public.scans s
WHERE s.fabric_type IS NOT NULL
  AND LENGTH(TRIM(s.fabric_type)) > 0
ON CONFLICT (code) DO NOTHING;

ALTER TABLE public.scans
  ADD CONSTRAINT scans_fabric_type_fk
  FOREIGN KEY (fabric_type)
  REFERENCES public.materials(code)
  ON UPDATE CASCADE;

-- ── 5) Indexes for live dashboard/perf ───────────────────────
CREATE INDEX IF NOT EXISTS idx_scans_user_id ON public.scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_created_at ON public.scans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scans_fabric_type ON public.scans(fabric_type);
CREATE INDEX IF NOT EXISTS idx_scans_user_fabric ON public.scans(user_id, fabric_type);

-- ── 6) RLS for scans/materials ───────────────────────────────
ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own scans" ON public.scans;
DROP POLICY IF EXISTS "Users can insert own scans" ON public.scans;
DROP POLICY IF EXISTS "Users can delete own scans" ON public.scans;
DROP POLICY IF EXISTS "Service role full access" ON public.scans;
DROP POLICY IF EXISTS scans_select_own ON public.scans;
DROP POLICY IF EXISTS scans_insert_own ON public.scans;
DROP POLICY IF EXISTS scans_delete_own ON public.scans;
DROP POLICY IF EXISTS scans_service_role_all ON public.scans;

CREATE POLICY scans_select_own
  ON public.scans
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY scans_insert_own
  ON public.scans
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY scans_delete_own
  ON public.scans
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Backend uses service role key for write/read operations.
CREATE POLICY scans_service_role_all
  ON public.scans
  FOR ALL
  TO service_role
  USING (TRUE)
  WITH CHECK (TRUE);

DROP POLICY IF EXISTS materials_read_all ON public.materials;
DROP POLICY IF EXISTS materials_service_role_all ON public.materials;

CREATE POLICY materials_read_all
  ON public.materials
  FOR SELECT
  TO anon, authenticated
  USING (is_active = TRUE);

CREATE POLICY materials_service_role_all
  ON public.materials
  FOR ALL
  TO service_role
  USING (TRUE)
  WITH CHECK (TRUE);

-- ── 7) Storage bucket + policies ─────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('fabric-images', 'fabric-images', TRUE)
ON CONFLICT (id)
DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own uploads" ON storage.objects;
DROP POLICY IF EXISTS fabric_images_public_read ON storage.objects;
DROP POLICY IF EXISTS fabric_images_authenticated_insert ON storage.objects;
DROP POLICY IF EXISTS fabric_images_authenticated_delete ON storage.objects;
DROP POLICY IF EXISTS fabric_images_service_role_all ON storage.objects;

CREATE POLICY fabric_images_public_read
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'fabric-images');

CREATE POLICY fabric_images_authenticated_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'fabric-images'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR (storage.foldername(name))[1] = 'scans'
    )
  );

CREATE POLICY fabric_images_authenticated_delete
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'fabric-images'
    AND (
      owner = auth.uid()
      OR (storage.foldername(name))[1] = auth.uid()::text
    )
  );

CREATE POLICY fabric_images_service_role_all
  ON storage.objects
  FOR ALL
  TO service_role
  USING (bucket_id = 'fabric-images')
  WITH CHECK (bucket_id = 'fabric-images');

-- ── 8) Views for dashboard + materials ───────────────────────
CREATE OR REPLACE VIEW public.user_scan_stats AS
SELECT
  user_id,
  COUNT(*) AS total_scans,
  ROUND(AVG(confidence), 1) AS avg_confidence,
  MODE() WITHIN GROUP (ORDER BY fabric_type) AS most_scanned_fabric,
  MAX(created_at) AS last_scan_at
FROM public.scans
WHERE user_id = auth.uid()
GROUP BY user_id;

CREATE OR REPLACE VIEW public.material_catalog AS
SELECT
  code AS label,
  name,
  properties,
  suggestions
FROM public.materials
WHERE is_active = TRUE
ORDER BY code;

-- ── 9) Grants ────────────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT SELECT ON public.materials TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.materials TO service_role;

GRANT SELECT, INSERT, DELETE ON public.scans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scans TO service_role;

GRANT SELECT ON public.user_scan_stats TO authenticated, service_role;
GRANT SELECT ON public.material_catalog TO anon, authenticated, service_role;

-- ── 10) Realtime publication (for live subscriptions) ───────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'scans'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.scans;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'materials'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.materials;
    END IF;
  END IF;
END;
$$;

COMMIT;

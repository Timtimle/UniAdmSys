-- Run this file ALONE first, then run import_hoc_phi_2025.sql
ALTER TABLE public.hoc_phi
    ADD COLUMN IF NOT EXISTS nam_hoc VARCHAR(20),
    ADD COLUMN IF NOT EXISTS hoc_phi_min BIGINT,
    ADD COLUMN IF NOT EXISTS hoc_phi_max BIGINT,
    ADD COLUMN IF NOT EXISTS don_vi VARCHAR(30) DEFAULT 'VND/năm',
    ADD COLUMN IF NOT EXISTS ghi_chu TEXT,
    ADD COLUMN IF NOT EXISTS source_url TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();

SELECT
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name='hoc_phi'
ORDER BY ordinal_position;

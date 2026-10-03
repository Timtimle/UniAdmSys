-- UniAdmSys ALL-IN-ONE 2025
-- Assumption: CSVs were already imported into:
--   public.nganh_import_2025
--   public.diem_chuan_import_2025
-- This script is idempotent for 2025 data.

BEGIN;

-- 1) Ensure nganh schema can hold 2025 data
ALTER TABLE public.nganh
    ALTER COLUMN ten_nganh TYPE TEXT;

ALTER TABLE public.nganh
    ADD COLUMN IF NOT EXISTS ma_nganh_tuyen_sinh VARCHAR(80),
    ADD COLUMN IF NOT EXISTS nam SMALLINT,
    ADD COLUMN IF NOT EXISTS danh_muc_nganh_id BIGINT,
    ADD COLUMN IF NOT EXISTS source_url TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'nganh_danh_muc_nganh_id_fkey'
    ) THEN
        ALTER TABLE public.nganh
        ADD CONSTRAINT nganh_danh_muc_nganh_id_fkey
        FOREIGN KEY (danh_muc_nganh_id)
        REFERENCES public.danh_muc_nganh(id);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_nganh_school_code_year
ON public.nganh(ma_truong, ma_nganh_tuyen_sinh, nam);

-- 2) Normalize hidden whitespace/newlines in 2025 major codes
UPDATE public.nganh_import_2025
SET ma_nganh_tuyen_sinh =
    regexp_replace(trim(ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g');

UPDATE public.nganh
SET ma_nganh_tuyen_sinh =
    regexp_replace(trim(ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
WHERE nam = 2025;

-- 3) Upsert 2025 school-major mappings
WITH src AS (
    SELECT
        t.ma_truong,
        s.ten_nganh,
        s.ma_nganh_tuyen_sinh,
        s.ma_nganh_bo,
        s.nam,
        s.source_url,
        ROW_NUMBER() OVER (
            PARTITION BY t.ma_truong, s.ma_nganh_tuyen_sinh, s.nam
            ORDER BY s.ten_nganh
        ) AS rn
    FROM public.nganh_import_2025 s
    JOIN public.truong_dh t
      ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
)
INSERT INTO public.nganh (
    ma_nganh,
    ma_truong,
    ten_nganh,
    ma_nganh_tuyen_sinh,
    nam,
    danh_muc_nganh_id,
    source_url
)
SELECT
    LEFT(
        MD5(
            src.ma_truong::text || '|' ||
            src.ma_nganh_tuyen_sinh || '|' ||
            src.nam::text
        ),
        20
    ),
    src.ma_truong,
    src.ten_nganh,
    src.ma_nganh_tuyen_sinh,
    src.nam,
    d.id,
    src.source_url
FROM src
LEFT JOIN public.danh_muc_nganh d
  ON d.ma_nganh_bo = NULLIF(src.ma_nganh_bo, '')
WHERE src.rn = 1
ON CONFLICT (ma_truong, ma_nganh_tuyen_sinh, nam)
DO UPDATE SET
    ten_nganh = EXCLUDED.ten_nganh,
    danh_muc_nganh_id = EXCLUDED.danh_muc_nganh_id,
    source_url = EXCLUDED.source_url;

-- 4) Ensure diem_chuan schema can hold all 2025 values
ALTER TABLE public.diem_chuan
    ALTER COLUMN phuong_thuc TYPE TEXT,
    ALTER COLUMN to_hop TYPE TEXT,
    ALTER COLUMN diem TYPE NUMERIC(8,2);

ALTER TABLE public.diem_chuan
    ADD COLUMN IF NOT EXISTS source_url TEXT;

-- 5) Normalize score staging codes too
UPDATE public.diem_chuan_import_2025
SET ma_nganh_tuyen_sinh =
    regexp_replace(trim(ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g');

-- 6) Replace only 2025 cutoff-score rows, so rerunning is safe
DELETE FROM public.diem_chuan
WHERE nam = 2025;

INSERT INTO public.diem_chuan (
    ma_truong,
    ma_nganh,
    nam,
    phuong_thuc,
    to_hop,
    diem,
    ghi_chu,
    source_url
)
SELECT
    s.ma_tuyen_sinh,
    n.ma_nganh,
    s.nam,
    NULLIF(trim(s.phuong_thuc), ''),
    NULLIF(trim(s.to_hop_xet_tuyen), ''),
    s.diem_chuan::numeric(8,2),
    NULLIF(trim(s.ghi_chu), ''),
    s.source_url
FROM public.diem_chuan_import_2025 s
JOIN public.truong_dh t
  ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
JOIN public.nganh n
  ON n.ma_truong = t.ma_truong
 AND regexp_replace(trim(n.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
     =
     regexp_replace(trim(s.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
 AND n.nam = 2025;

COMMIT;

-- 7) Final QA
SELECT
    (SELECT COUNT(*) FROM public.nganh WHERE nam = 2025) AS so_nganh_2025,
    (SELECT COUNT(*) FROM public.diem_chuan WHERE nam = 2025) AS so_diem_chuan_2025,
    (
      SELECT COUNT(*)
      FROM public.diem_chuan_import_2025 s
      LEFT JOIN public.truong_dh t
        ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
      LEFT JOIN public.nganh n
        ON n.ma_truong = t.ma_truong
       AND regexp_replace(trim(n.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
           =
           regexp_replace(trim(s.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
       AND n.nam = 2025
      WHERE n.ma_nganh IS NULL
    ) AS diem_chuan_chua_map;

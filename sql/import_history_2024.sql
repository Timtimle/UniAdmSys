-- UniAdmSys: ALL-IN-ONE dữ liệu tuyển sinh lịch sử 2024
-- Nguồn: HTNam1710/ADS_Final - diem_chuan_2024_final.csv
-- 5,925 dòng điểm chuẩn; đã kiểm tra map 100% với data/nganh_2024_supabase.csv.
-- Bước duy nhất cần làm trước: import data/diem_chuan_2024_supabase.csv
-- vào bảng public.diem_chuan_import_2024 (Supabase Table Editor -> Import CSV).

BEGIN;

CREATE TABLE IF NOT EXISTS public.diem_chuan_import_2024 (
    ma_tuyen_sinh VARCHAR(20) NOT NULL,
    ma_nganh_tuyen_sinh VARCHAR(80) NOT NULL,
    ten_nganh TEXT,
    to_hop_xet_tuyen TEXT,
    diem_chuan NUMERIC,
    phuong_thuc TEXT,
    ghi_chu TEXT,
    nam SMALLINT NOT NULL DEFAULT 2024,
    source_url TEXT
);

-- Chuẩn hóa mã ngành/tổ hợp/phương thức.
UPDATE public.diem_chuan_import_2024
SET
    ma_tuyen_sinh = trim(ma_tuyen_sinh),
    ma_nganh_tuyen_sinh = regexp_replace(trim(ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g'),
    phuong_thuc = regexp_replace(trim(phuong_thuc), '[[:space:]]+', ' ', 'g')
WHERE nam = 2024;

-- Đảm bảo nganh 2024 cũng sạch whitespace.
UPDATE public.nganh
SET ma_nganh_tuyen_sinh =
    regexp_replace(trim(ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
WHERE nam = 2024;

-- =========================================================
-- 1) ĐIỂM CHUẨN 2024
-- =========================================================

DELETE FROM public.diem_chuan
WHERE nam = 2024;

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
    2024,
    NULLIF(trim(s.phuong_thuc),''),
    NULLIF(trim(s.to_hop_xet_tuyen),''),
    s.diem_chuan,
    NULLIF(trim(s.ghi_chu),''),
    s.source_url
FROM public.diem_chuan_import_2024 s
JOIN public.truong_dh t
  ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
JOIN public.nganh n
  ON n.ma_truong = t.ma_truong
 AND n.nam = 2024
 AND regexp_replace(trim(n.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
     =
     regexp_replace(trim(s.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
WHERE s.nam = 2024;

-- =========================================================
-- 2) PHƯƠNG THỨC 2024
-- =========================================================

DELETE FROM public.phuong_thuc_xet_tuyen
WHERE nam = 2024;

WITH src AS (
    SELECT DISTINCT
        s.ma_tuyen_sinh AS ma_truong,
        2024::SMALLINT AS nam,
        regexp_replace(trim(s.phuong_thuc), '[[:space:]]+', ' ', 'g') AS ten_phuong_thuc,
        MIN(s.source_url) OVER (
            PARTITION BY
                s.ma_tuyen_sinh,
                regexp_replace(trim(s.phuong_thuc), '[[:space:]]+', ' ', 'g')
        ) AS source_url
    FROM public.diem_chuan_import_2024 s
    WHERE s.nam = 2024
      AND NULLIF(trim(s.phuong_thuc),'') IS NOT NULL
)
INSERT INTO public.phuong_thuc_xet_tuyen (
    ma_phuong_thuc,
    ma_truong,
    nam,
    ten_phuong_thuc,
    source_url
)
SELECT DISTINCT
    LEFT(MD5(src.ma_truong || '|2024|' || src.ten_phuong_thuc),20),
    src.ma_truong,
    src.nam,
    src.ten_phuong_thuc,
    src.source_url
FROM src;

-- =========================================================
-- 3) TỔ HỢP 2024
-- =========================================================

DELETE FROM public.nganh_to_hop_xet_tuyen
WHERE nam = 2024;

WITH extracted AS (
    SELECT DISTINCT UPPER(m[1]) AS ma_to_hop
    FROM public.diem_chuan_import_2024 s
    CROSS JOIN LATERAL regexp_matches(
        COALESCE(s.to_hop_xet_tuyen,''),
        '([A-Za-z]{1,3}[0-9]{2})',
        'g'
    ) AS m
    WHERE s.nam = 2024
)
INSERT INTO public.to_hop_xet_tuyen(ma_to_hop, ten_to_hop)
SELECT ma_to_hop, ma_to_hop
FROM extracted
ON CONFLICT (ma_to_hop) DO NOTHING;

WITH src AS (
    SELECT DISTINCT
        s.ma_tuyen_sinh AS ma_truong,
        n.ma_nganh,
        2024::SMALLINT AS nam,
        UPPER(m[1]) AS ma_to_hop,
        NULLIF(trim(s.phuong_thuc),'') AS phuong_thuc,
        s.source_url
    FROM public.diem_chuan_import_2024 s
    JOIN public.truong_dh t
      ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
    JOIN public.nganh n
      ON n.ma_truong = t.ma_truong
     AND n.nam = 2024
     AND regexp_replace(trim(n.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
         =
         regexp_replace(trim(s.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
    CROSS JOIN LATERAL regexp_matches(
        COALESCE(s.to_hop_xet_tuyen,''),
        '([A-Za-z]{1,3}[0-9]{2})',
        'g'
    ) AS m
    WHERE s.nam = 2024
)
INSERT INTO public.nganh_to_hop_xet_tuyen (
    ma_truong,
    ma_nganh,
    nam,
    ma_to_hop,
    phuong_thuc,
    source_url
)
SELECT DISTINCT
    ma_truong,
    ma_nganh,
    nam,
    ma_to_hop,
    phuong_thuc,
    source_url
FROM src;

-- =========================================================
-- 4) INDEX + VIEWS
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_diem_chuan_2024_lookup
ON public.diem_chuan(ma_truong, ma_nganh, nam);

CREATE INDEX IF NOT EXISTS idx_nganh_to_hop_2024_lookup
ON public.nganh_to_hop_xet_tuyen(ma_truong, ma_nganh, nam);

CREATE OR REPLACE VIEW public.v_diem_chuan_2024 AS
SELECT
    dc.id,
    dc.ma_truong,
    t.ten_truong,
    dc.ma_nganh,
    n.ma_nganh_tuyen_sinh,
    n.ten_nganh,
    dc.phuong_thuc,
    dc.to_hop,
    dc.diem,
    dc.ghi_chu,
    dc.source_url
FROM public.diem_chuan dc
LEFT JOIN public.truong_dh t
  ON t.ma_tuyen_sinh = dc.ma_truong
LEFT JOIN public.nganh n
  ON n.ma_nganh = dc.ma_nganh
 AND n.nam = 2024
WHERE dc.nam = 2024;

CREATE OR REPLACE VIEW public.v_nganh_to_hop_2024 AS
SELECT
    x.ma_truong,
    t.ten_truong,
    x.ma_nganh,
    n.ma_nganh_tuyen_sinh,
    n.ten_nganh,
    x.ma_to_hop,
    x.phuong_thuc,
    x.source_url
FROM public.nganh_to_hop_xet_tuyen x
LEFT JOIN public.truong_dh t
  ON t.ma_tuyen_sinh = x.ma_truong
LEFT JOIN public.nganh n
  ON n.ma_nganh = x.ma_nganh
WHERE x.nam = 2024;

COMMIT;

-- =========================================================
-- QA CUỐI
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM public.diem_chuan_import_2024 WHERE nam=2024) AS staging_rows,
    (SELECT COUNT(*) FROM public.diem_chuan WHERE nam=2024) AS diem_chuan_2024,
    (SELECT COUNT(*) FROM public.phuong_thuc_xet_tuyen WHERE nam=2024) AS phuong_thuc_2024,
    (SELECT COUNT(*) FROM public.nganh_to_hop_xet_tuyen WHERE nam=2024) AS mapping_to_hop_2024;

-- Mapping phải 100%: chua_map = 0
SELECT
    COUNT(*) AS tong_staging,
    COUNT(n.ma_nganh) AS map_duoc,
    COUNT(*) - COUNT(n.ma_nganh) AS chua_map
FROM public.diem_chuan_import_2024 s
LEFT JOIN public.truong_dh t
  ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
LEFT JOIN public.nganh n
  ON n.ma_truong = t.ma_truong
 AND n.nam = 2024
 AND regexp_replace(trim(n.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
     =
     regexp_replace(trim(s.ma_nganh_tuyen_sinh), '[[:space:]]+', ' ', 'g')
WHERE s.nam = 2024;

SELECT * FROM public.v_diem_chuan_2024 LIMIT 20;

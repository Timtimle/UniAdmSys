-- UniAdmSys: simplify floor score to a single value
-- Converts nguong_dau_vao.diem_san_min/max -> nguong_dau_vao.diem_san
-- and recreates dependent public views.

BEGIN;

DROP VIEW IF EXISTS public.v_catalog_tuyen_sinh_2025;
DROP VIEW IF EXISTS public.v_truong_tuyen_sinh_2025;

ALTER TABLE public.nguong_dau_vao
    ADD COLUMN IF NOT EXISTS diem_san NUMERIC(8,2);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public'
          AND table_name='nguong_dau_vao'
          AND column_name='diem_san_min'
    ) THEN
        EXECUTE $sql$
            UPDATE public.nguong_dau_vao
            SET diem_san = COALESCE(diem_san, diem_san_min, diem_san_max)
            WHERE diem_san IS NULL
        $sql$;
    END IF;
END $$;

ALTER TABLE public.nguong_dau_vao
    DROP CONSTRAINT IF EXISTS nguong_dau_vao_range_check;

ALTER TABLE public.nguong_dau_vao
    DROP COLUMN IF EXISTS diem_san_min,
    DROP COLUMN IF EXISTS diem_san_max;

CREATE OR REPLACE VIEW public.v_truong_tuyen_sinh_2025 AS
SELECT
    t.ma_truong AS id_truong,
    t.ma_tuyen_sinh,
    t.ten_truong,

    h.hoc_phi_min,
    h.hoc_phi_max,
    h.don_vi AS hoc_phi_don_vi,
    h.trang_thai AS hoc_phi_trang_thai,
    h.source_url AS hoc_phi_source_url,

    c.chi_tieu,
    c.chi_tieu_min,
    c.chi_tieu_max,
    c.trang_thai AS chi_tieu_trang_thai,
    c.source_url AS chi_tieu_source_url,

    n.diem_san,
    n.trang_thai AS diem_san_trang_thai,
    n.ghi_chu AS diem_san_ghi_chu,
    n.source_url AS diem_san_source_url

FROM public.truong_dh t
LEFT JOIN public.hoc_phi h
    ON h.ma_truong = t.ma_tuyen_sinh
   AND h.nam = 2025
LEFT JOIN public.chi_tieu_tuyen_sinh c
    ON c.ma_truong = t.ma_tuyen_sinh
   AND c.nam = 2025
   AND COALESCE(c.cap_do, 'truong') = 'truong'
LEFT JOIN public.nguong_dau_vao n
    ON n.ma_truong = t.ma_tuyen_sinh
   AND n.nam = 2025
   AND n.ma_nganh IS NULL
   AND n.ma_phuong_thuc IS NULL;

CREATE OR REPLACE VIEW public.v_catalog_tuyen_sinh_2025 AS
SELECT
    n.ma_nganh,
    n.ma_truong,
    n.ten_truong,
    n.ma_nganh_tuyen_sinh,
    n.ten_nganh,
    n.ma_nganh_bo,
    n.ten_nganh_bo,

    h.hoc_phi_min,
    h.hoc_phi_max,
    h.hoc_phi_don_vi,
    h.hoc_phi_trang_thai,

    h.chi_tieu,
    h.chi_tieu_min,
    h.chi_tieu_max,
    h.chi_tieu_trang_thai,

    h.diem_san,
    h.diem_san_trang_thai,
    h.diem_san_ghi_chu,
    h.diem_san_source_url

FROM public.v_nganh_2025 n
LEFT JOIN public.v_truong_tuyen_sinh_2025 h
    ON h.ma_tuyen_sinh = n.ma_truong;

ALTER VIEW public.v_truong_tuyen_sinh_2025
SET (security_invoker = true);

ALTER VIEW public.v_catalog_tuyen_sinh_2025
SET (security_invoker = true);

COMMIT;

SELECT
    COUNT(*) AS tong_nguong,
    COUNT(diem_san) AS co_diem_san
FROM public.nguong_dau_vao;

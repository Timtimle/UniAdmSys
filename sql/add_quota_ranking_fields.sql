-- UniAdmSys: add quota-ranking metadata to existing result table.
BEGIN;

ALTER TABLE public.ket_qua_xet_tuyen
    ADD COLUMN IF NOT EXISTS xep_hang_chi_tieu INTEGER,
    ADD COLUMN IF NOT EXISTS chi_tieu_ap_dung INTEGER,
    ADD COLUMN IF NOT EXISTS diem_cat_chi_tieu NUMERIC(8,2),
    ADD COLUMN IF NOT EXISTS dat_chi_tieu BOOLEAN;

CREATE INDEX IF NOT EXISTS idx_ket_qua_quota_rank
ON public.ket_qua_xet_tuyen(dat_chi_tieu, xep_hang_chi_tieu);

COMMIT;

SELECT COUNT(*) FILTER (WHERE xep_hang_chi_tieu IS NOT NULL) AS rows_already_ranked
FROM public.ket_qua_xet_tuyen;

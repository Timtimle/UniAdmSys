-- UniAdmSys: FINALIZE DATABASE 2025
-- Mục tiêu: dọn/index/view/audit để backend dùng trực tiếp.
-- Không đụng AI Agent. Có thể chạy lại an toàn.

BEGIN;

-- =========================================================
-- 1) INDEXES QUAN TRỌNG
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_truong_dh_ma_tuyen_sinh_lookup
ON public.truong_dh(ma_tuyen_sinh);

CREATE INDEX IF NOT EXISTS idx_nganh_2025_truong
ON public.nganh(ma_truong, nam);

CREATE INDEX IF NOT EXISTS idx_nganh_2025_code
ON public.nganh(ma_nganh_tuyen_sinh, nam);

CREATE INDEX IF NOT EXISTS idx_diem_chuan_2025_truong_nganh
ON public.diem_chuan(ma_truong, ma_nganh, nam);

CREATE INDEX IF NOT EXISTS idx_diem_chuan_2025_diem
ON public.diem_chuan(nam, diem);

CREATE INDEX IF NOT EXISTS idx_hoc_phi_2025_status
ON public.hoc_phi(nam, trang_thai);

CREATE INDEX IF NOT EXISTS idx_chi_tieu_2025_status
ON public.chi_tieu_tuyen_sinh(nam, trang_thai);

CREATE INDEX IF NOT EXISTS idx_ptxt_2025_lookup
ON public.phuong_thuc_xet_tuyen(ma_truong, nam);

CREATE INDEX IF NOT EXISTS idx_nganh_to_hop_2025_lookup
ON public.nganh_to_hop_xet_tuyen(ma_truong, ma_nganh, nam);

-- =========================================================
-- 2) VIEW: THÔNG TIN TRƯỜNG 2025
-- =========================================================

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
    c.source_url AS chi_tieu_source_url

FROM public.truong_dh t

LEFT JOIN public.hoc_phi h
    ON h.ma_truong = t.ma_tuyen_sinh
   AND h.nam = 2025

LEFT JOIN public.chi_tieu_tuyen_sinh c
    ON c.ma_truong = t.ma_tuyen_sinh
   AND c.nam = 2025
   AND COALESCE(c.cap_do, 'truong') = 'truong';

-- =========================================================
-- 3) VIEW: NGÀNH/CHƯƠNG TRÌNH 2025
-- =========================================================

CREATE OR REPLACE VIEW public.v_nganh_2025 AS
SELECT
    n.ma_nganh,
    t.ma_tuyen_sinh AS ma_truong,
    t.ten_truong,
    n.ma_nganh_tuyen_sinh,
    n.ten_nganh,
    n.nam,
    d.ma_nganh_bo,
    d.ten_nganh AS ten_nganh_bo,
    n.source_url
FROM public.nganh n
JOIN public.truong_dh t
    ON t.ma_truong = n.ma_truong
LEFT JOIN public.danh_muc_nganh d
    ON d.id = n.danh_muc_nganh_id
WHERE n.nam = 2025;

-- =========================================================
-- 4) VIEW: ĐIỂM CHUẨN CHI TIẾT 2025
-- Không aggregate điểm giữa các phương thức vì khác thang điểm.
-- =========================================================

CREATE OR REPLACE VIEW public.v_diem_chuan_2025 AS
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
    dc.source_url,
    dc.created_at
FROM public.diem_chuan dc
LEFT JOIN public.truong_dh t
    ON t.ma_tuyen_sinh = dc.ma_truong
LEFT JOIN public.nganh n
    ON n.ma_nganh = dc.ma_nganh
   AND n.nam = 2025
WHERE dc.nam = 2025;

-- =========================================================
-- 5) VIEW: PHƯƠNG THỨC 2025
-- =========================================================

CREATE OR REPLACE VIEW public.v_phuong_thuc_xet_tuyen_2025 AS
SELECT
    p.ma_phuong_thuc,
    p.ma_truong,
    t.ten_truong,
    p.ten_phuong_thuc,
    p.source_url
FROM public.phuong_thuc_xet_tuyen p
LEFT JOIN public.truong_dh t
    ON t.ma_tuyen_sinh = p.ma_truong
WHERE p.nam = 2025;

-- =========================================================
-- 6) VIEW: TỔ HỢP THEO NGÀNH 2025
-- =========================================================

CREATE OR REPLACE VIEW public.v_nganh_to_hop_2025 AS
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
WHERE x.nam = 2025;

-- =========================================================
-- 7) VIEW TỔNG HỢP CHO BACKEND
-- Một row / ngành, kèm học phí + chỉ tiêu cấp trường.
-- Điểm chuẩn không nhét vào đây vì mỗi ngành có thể có nhiều dòng.
-- =========================================================

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
    h.chi_tieu_trang_thai

FROM public.v_nganh_2025 n
LEFT JOIN public.v_truong_tuyen_sinh_2025 h
    ON h.ma_tuyen_sinh = n.ma_truong;

COMMIT;

-- =========================================================
-- 8) QA / DATABASE AUDIT
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM public.truong_dh) AS truong_dh,
    (SELECT COUNT(*) FROM public.nganh WHERE nam = 2025) AS nganh_2025,
    (SELECT COUNT(*) FROM public.diem_chuan WHERE nam = 2025) AS diem_chuan_2025,
    (SELECT COUNT(*) FROM public.phuong_thuc_xet_tuyen WHERE nam = 2025) AS phuong_thuc_2025,
    (SELECT COUNT(*) FROM public.to_hop_xet_tuyen) AS ma_to_hop,
    (SELECT COUNT(*) FROM public.nganh_to_hop_xet_tuyen WHERE nam = 2025) AS mapping_nganh_to_hop,
    (SELECT COUNT(*) FROM public.hoc_phi WHERE nam = 2025) AS hoc_phi_2025,
    (SELECT COUNT(*) FROM public.chi_tieu_tuyen_sinh WHERE nam = 2025) AS chi_tieu_2025;

-- Orphan ngành -> trường: phải 0
SELECT COUNT(*) AS orphan_nganh_truong
FROM public.nganh n
LEFT JOIN public.truong_dh t
    ON t.ma_truong = n.ma_truong
WHERE n.nam = 2025
  AND t.ma_truong IS NULL;

-- Orphan điểm chuẩn -> ngành: phải 0
SELECT COUNT(*) AS orphan_diem_chuan_nganh
FROM public.diem_chuan dc
LEFT JOIN public.nganh n
    ON n.ma_nganh = dc.ma_nganh
   AND n.nam = 2025
WHERE dc.nam = 2025
  AND n.ma_nganh IS NULL;

-- Orphan điểm chuẩn -> trường: phải 0
SELECT COUNT(*) AS orphan_diem_chuan_truong
FROM public.diem_chuan dc
LEFT JOIN public.truong_dh t
    ON t.ma_tuyen_sinh = dc.ma_truong
WHERE dc.nam = 2025
  AND t.ma_truong IS NULL;

-- Coverage học phí + chỉ tiêu
SELECT
    (SELECT COUNT(*) FROM public.hoc_phi
      WHERE nam = 2025
        AND trang_thai = 'da_xac_minh') AS hoc_phi_da_xac_minh,

    (SELECT COUNT(*) FROM public.hoc_phi
      WHERE nam = 2025
        AND trang_thai = 'chua_xac_minh') AS hoc_phi_chua_xac_minh,

    (SELECT COUNT(*) FROM public.chi_tieu_tuyen_sinh
      WHERE nam = 2025
        AND trang_thai <> 'chua_xac_minh') AS chi_tieu_da_co_du_lieu,

    (SELECT COUNT(*) FROM public.chi_tieu_tuyen_sinh
      WHERE nam = 2025
        AND trang_thai = 'chua_xac_minh') AS chi_tieu_chua_xac_minh;

-- Views test
SELECT * FROM public.v_catalog_tuyen_sinh_2025 LIMIT 20;

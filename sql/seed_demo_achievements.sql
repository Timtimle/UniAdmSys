-- UniAdmSys: full synthetic demo data for achievements, direct admission and certificate conversion
-- Run after add_special_admission_and_certificates.sql
-- All data below is DEMO / SYNTHETIC, not official admissions policy.

BEGIN;

-- =========================================================
-- 0) CLEAN PREVIOUS DEMO DATA
-- =========================================================
DELETE FROM public.thanh_tich_chung_chi
WHERE ghi_chu = 'Synthetic demo evidence';

DELETE FROM public.dieu_kien_xet_tuyen_thang
WHERE source_url LIKE 'demo://%';

DELETE FROM public.quy_doi_chung_chi
WHERE source_url LIKE 'demo://%';


-- =========================================================
-- 1) SYNTHETIC APPLICANT ACHIEVEMENTS / CERTIFICATES
-- Adds IELTS, SAT, TOEFL iBT, ACT, Cambridge,
-- HSG Quốc gia, HSG tỉnh, KHKT Quốc gia, Olympic.
-- =========================================================
WITH demo AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'demo_candidate_%@uniadmsys.local'
),
staff AS (
    SELECT
        ma_can_bo,
        row_number() OVER (ORDER BY ma_can_bo) AS rn,
        count(*) OVER () AS cnt
    FROM public.can_bo
    WHERE trang_thai = 'hoat_dong'
),
evidence AS (
    -- IELTS
    SELECT
        ma_thi_sinh,
        'chung_chi'::varchar AS nhom,
        'ielts'::varchar AS loai,
        'IELTS Academic'::text AS ten,
        'English'::varchar AS mon_linh_vuc,
        NULL::varchar AS cap_giai,
        NULL::smallint AS thu_hang_giai,
        round((5.0 + ((rn % 8) * 0.5))::numeric, 1) AS diem_so,
        '9.0'::varchar AS thang_diem,
        'British Council / IDP'::varchar AS don_vi_cap,
        DATE '2024-01-01' + ((rn * 7) % 500) AS ngay_cap,
        rn
    FROM demo
    WHERE rn % 3 = 0

    UNION ALL

    -- SAT
    SELECT
        ma_thi_sinh,
        'chung_chi',
        'sat',
        'SAT',
        'Standardized Test',
        NULL,
        NULL,
        (1050 + ((rn * 37) % 501))::numeric,
        '1600',
        'College Board',
        DATE '2024-01-01' + ((rn * 5) % 500),
        rn
    FROM demo
    WHERE rn % 5 = 0

    UNION ALL

    -- TOEFL iBT
    SELECT
        ma_thi_sinh,
        'chung_chi',
        'toefl_ibt',
        'TOEFL iBT',
        'English',
        NULL,
        NULL,
        (60 + ((rn * 11) % 61))::numeric,
        '120',
        'ETS',
        DATE '2024-01-01' + ((rn * 9) % 500),
        rn
    FROM demo
    WHERE rn % 7 = 0

    UNION ALL

    -- ACT
    SELECT
        ma_thi_sinh,
        'chung_chi',
        'act',
        'ACT',
        'Standardized Test',
        NULL,
        NULL,
        (20 + ((rn * 5) % 17))::numeric,
        '36',
        'ACT',
        DATE '2024-01-01' + ((rn * 13) % 500),
        rn
    FROM demo
    WHERE rn % 11 = 0

    UNION ALL

    -- Cambridge English
    SELECT
        ma_thi_sinh,
        'chung_chi',
        'cambridge_english',
        'Cambridge English',
        'English',
        NULL,
        NULL,
        (160 + ((rn * 7) % 51))::numeric,
        '230',
        'Cambridge English',
        DATE '2024-01-01' + ((rn * 3) % 500),
        rn
    FROM demo
    WHERE rn % 13 = 0

    UNION ALL

    -- HSG Quốc gia
    SELECT
        ma_thi_sinh,
        'thanh_tich',
        'hsg_quoc_gia',
        'Học sinh giỏi Quốc gia',
        (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])
            [1 + ((rn - 1) % 7)],
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])
            [1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,
        NULL,
        'Bộ Giáo dục và Đào tạo',
        DATE '2025-01-01' + ((rn * 2) % 90),
        rn
    FROM demo
    WHERE rn % 17 = 0

    UNION ALL

    -- HSG tỉnh/thành
    SELECT
        ma_thi_sinh,
        'thanh_tich',
        'hsg_tinh',
        'Học sinh giỏi cấp Tỉnh/Thành phố',
        (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])
            [1 + ((rn + 2) % 7)],
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba','Giải Khuyến khích'])
            [1 + ((rn - 1) % 4)],
        (1 + ((rn - 1) % 4))::smallint,
        NULL,
        NULL,
        'Sở Giáo dục và Đào tạo',
        DATE '2025-01-01' + ((rn * 3) % 90),
        rn
    FROM demo
    WHERE rn % 9 = 0

    UNION ALL

    -- KHKT Quốc gia
    SELECT
        ma_thi_sinh,
        'thanh_tich',
        'khkt_quoc_gia',
        'Cuộc thi Khoa học Kỹ thuật cấp Quốc gia',
        'Khoa học kỹ thuật',
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])
            [1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,
        NULL,
        'Bộ Giáo dục và Đào tạo',
        DATE '2025-01-01' + ((rn * 4) % 90),
        rn
    FROM demo
    WHERE rn % 23 = 0

    UNION ALL

    -- Olympic
    SELECT
        ma_thi_sinh,
        'thanh_tich',
        'olympic',
        'Olympic',
        (ARRAY['Toán','Vật lý','Hóa học','Tin học'])
            [1 + ((rn - 1) % 4)],
        (ARRAY['Gold','Silver','Bronze'])
            [1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,
        NULL,
        'Olympic Committee',
        DATE '2025-01-01' + ((rn * 5) % 90),
        rn
    FROM demo
    WHERE rn % 29 = 0
),
prepared AS (
    SELECT
        e.*,
        CASE
            WHEN e.rn % 6 = 0 THEN 'chua_xac_minh'
            ELSE 'da_xac_minh'
        END AS trang_thai_xac_minh
    FROM evidence e
)
INSERT INTO public.thanh_tich_chung_chi (
    ma_thi_sinh,
    nhom,
    loai,
    ten,
    mon_linh_vuc,
    cap_giai,
    thu_hang_giai,
    diem_so,
    thang_diem,
    don_vi_cap,
    ngay_cap,
    ngay_het_han,
    trang_thai_xac_minh,
    ma_can_bo_xac_minh,
    xac_minh_luc,
    ghi_chu
)
SELECT
    p.ma_thi_sinh,
    p.nhom,
    p.loai,
    p.ten,
    p.mon_linh_vuc,
    p.cap_giai,
    p.thu_hang_giai,
    p.diem_so,
    p.thang_diem,
    p.don_vi_cap,
    p.ngay_cap,
    CASE
        WHEN p.nhom = 'chung_chi'
            THEN p.ngay_cap + INTERVAL '2 years'
        ELSE NULL
    END::date,
    p.trang_thai_xac_minh,
    CASE
        WHEN p.trang_thai_xac_minh = 'da_xac_minh' AND EXISTS (SELECT 1 FROM staff)
        THEN (
            SELECT s.ma_can_bo
            FROM staff s
            WHERE s.rn = 1 + ((p.rn - 1) % s.cnt)
            LIMIT 1
        )
        ELSE NULL
    END,
    CASE
        WHEN p.trang_thai_xac_minh = 'da_xac_minh'
            THEN now() - ((p.rn % 20) || ' days')::interval
        ELSE NULL
    END,
    'Synthetic demo evidence'
FROM prepared p;


-- =========================================================
-- 2) DIRECT / PRIORITY ADMISSION RULES
-- Synthetic rules for first 100 universities.
-- HSG Quốc gia / KHKT / Olympic => direct-admission demo rules.
-- HSG tỉnh => priority-admission demo rule.
-- =========================================================
WITH schools AS (
    SELECT
        trim(ma_tuyen_sinh) AS ma_truong,
        row_number() OVER (ORDER BY ma_tuyen_sinh) AS rn
    FROM public.truong_dh
    WHERE NULLIF(trim(ma_tuyen_sinh), '') IS NOT NULL
    ORDER BY ma_tuyen_sinh
    LIMIT 100
),
rules(loai_thanh_tich, mon_linh_vuc, giai_toi_da, xet_tuyen_thang, uu_tien_xet_tuyen, ghi_chu) AS (
    VALUES
        ('hsg_quoc_gia', NULL::varchar, 3::smallint, true,  false,
         'DEMO: HSG Quốc gia giải Nhất/Nhì/Ba có thể đủ điều kiện xét tuyển thẳng'),
        ('khkt_quoc_gia', NULL::varchar, 3::smallint, true,  false,
         'DEMO: Giải KHKT Quốc gia có thể đủ điều kiện xét tuyển thẳng'),
        ('olympic', NULL::varchar, 3::smallint, true,  false,
         'DEMO: Huy chương Olympic có thể đủ điều kiện xét tuyển thẳng'),
        ('hsg_tinh', NULL::varchar, 2::smallint, false, true,
         'DEMO: HSG cấp Tỉnh/Thành phố giải Nhất/Nhì có thể được ưu tiên xét tuyển')
)
INSERT INTO public.dieu_kien_xet_tuyen_thang (
    ma_truong,
    nam,
    ma_nganh,
    ma_phuong_thuc,
    loai_thanh_tich,
    mon_linh_vuc,
    giai_toi_da,
    xet_tuyen_thang,
    uu_tien_xet_tuyen,
    ghi_chu,
    source_url,
    is_active
)
SELECT
    s.ma_truong,
    2025,
    NULL,
    NULL,
    r.loai_thanh_tich,
    r.mon_linh_vuc,
    r.giai_toi_da,
    r.xet_tuyen_thang,
    r.uu_tien_xet_tuyen,
    r.ghi_chu,
    'demo://synthetic-direct-admission-rule',
    true
FROM schools s
CROSS JOIN rules r;


-- =========================================================
-- 3) CERTIFICATE CONVERSION RULES
-- Synthetic conversion bands for first 100 universities.
-- These are NOT official conversion tables.
-- =========================================================
WITH schools AS (
    SELECT
        trim(ma_tuyen_sinh) AS ma_truong
    FROM public.truong_dh
    WHERE NULLIF(trim(ma_tuyen_sinh), '') IS NOT NULL
    ORDER BY ma_tuyen_sinh
    LIMIT 100
),
bands(loai_chung_chi, diem_tu, diem_den, diem_quy_doi, thang_diem, ghi_chu) AS (
    VALUES
        -- IELTS
        ('ielts', 5.5, 5.99, 8.0, '10', 'DEMO IELTS conversion'),
        ('ielts', 6.0, 6.49, 8.5, '10', 'DEMO IELTS conversion'),
        ('ielts', 6.5, 6.99, 9.0, '10', 'DEMO IELTS conversion'),
        ('ielts', 7.0, 7.49, 9.5, '10', 'DEMO IELTS conversion'),
        ('ielts', 7.5, NULL, 10.0, '10', 'DEMO IELTS conversion'),

        -- SAT
        ('sat', 1100, 1199, 7.5, '10', 'DEMO SAT conversion'),
        ('sat', 1200, 1299, 8.0, '10', 'DEMO SAT conversion'),
        ('sat', 1300, 1399, 9.0, '10', 'DEMO SAT conversion'),
        ('sat', 1400, NULL, 10.0, '10', 'DEMO SAT conversion'),

        -- TOEFL iBT
        ('toefl_ibt', 60, 79, 8.0, '10', 'DEMO TOEFL iBT conversion'),
        ('toefl_ibt', 80, 99, 9.0, '10', 'DEMO TOEFL iBT conversion'),
        ('toefl_ibt', 100, NULL, 10.0, '10', 'DEMO TOEFL iBT conversion'),

        -- ACT
        ('act', 24, 27.99, 8.0, '10', 'DEMO ACT conversion'),
        ('act', 28, 31.99, 9.0, '10', 'DEMO ACT conversion'),
        ('act', 32, NULL, 10.0, '10', 'DEMO ACT conversion'),

        -- Cambridge English
        ('cambridge_english', 160, 179.99, 8.0, '10', 'DEMO Cambridge English conversion'),
        ('cambridge_english', 180, 199.99, 9.0, '10', 'DEMO Cambridge English conversion'),
        ('cambridge_english', 200, NULL, 10.0, '10', 'DEMO Cambridge English conversion')
)
INSERT INTO public.quy_doi_chung_chi (
    ma_truong,
    nam,
    ma_nganh,
    ma_phuong_thuc,
    loai_chung_chi,
    diem_tu,
    diem_den,
    diem_quy_doi,
    thang_diem_quy_doi,
    ghi_chu,
    source_url,
    is_active
)
SELECT
    s.ma_truong,
    2025,
    NULL,
    NULL,
    b.loai_chung_chi,
    b.diem_tu,
    b.diem_den,
    b.diem_quy_doi,
    b.thang_diem,
    b.ghi_chu,
    'demo://synthetic-certificate-conversion',
    true
FROM schools s
CROSS JOIN bands b;

COMMIT;


-- =========================================================
-- QA
-- =========================================================
SELECT
    (SELECT COUNT(*)
     FROM public.thanh_tich_chung_chi
     WHERE ghi_chu = 'Synthetic demo evidence') AS demo_thanh_tich_chung_chi,

    (SELECT COUNT(*)
     FROM public.dieu_kien_xet_tuyen_thang
     WHERE source_url LIKE 'demo://%') AS demo_rule_xet_tuyen_thang,

    (SELECT COUNT(*)
     FROM public.quy_doi_chung_chi
     WHERE source_url LIKE 'demo://%') AS demo_rule_quy_doi;

SELECT
    loai,
    COUNT(*) AS so_luong
FROM public.thanh_tich_chung_chi
WHERE ghi_chu = 'Synthetic demo evidence'
GROUP BY loai
ORDER BY loai;

SELECT
    loai_thanh_tich,
    COUNT(*) AS so_rule
FROM public.dieu_kien_xet_tuyen_thang
WHERE source_url LIKE 'demo://%'
GROUP BY loai_thanh_tich
ORDER BY loai_thanh_tich;

SELECT
    loai_chung_chi,
    COUNT(*) AS so_rule
FROM public.quy_doi_chung_chi
WHERE source_url LIKE 'demo://%'
GROUP BY loai_chung_chi
ORDER BY loai_chung_chi;

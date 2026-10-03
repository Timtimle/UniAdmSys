-- UniAdmSys: LARGE DEMO DATASET
-- Synthetic data only. Safe for demo/testing; not official admissions data.
-- Run AFTER:
--   1) add_candidate_flow_and_floor_score.sql
--   2) add_special_admission_and_certificates.sql
--   3) harden_schema_for_review.sql
--
-- Creates approximately:
--   5 managers + 60 staff
--   1,000 applicants
--   1,000 application dossiers
--   9,000 exam-score rows
--   6,000 preferences
--   6,000 calculated-result rows
--   hundreds of achievements/certificates
--   demo floor-score rows for up to 200 schools

BEGIN;

-- =========================================================
-- 0) CLEAN PREVIOUS LARGE DEMO DATA
-- =========================================================
DELETE FROM public.thi_sinh
WHERE email LIKE 'bulk_candidate_%@uniadmsys.local';

DELETE FROM public.can_bo
WHERE email LIKE 'bulk_staff_%@uniadmsys.local'
   OR email LIKE 'bulk_manager_%@uniadmsys.local';

DELETE FROM public.nguong_dau_vao
WHERE source_url = 'demo://bulk-floor-score';


-- =========================================================
-- 1) STAFF: 5 MANAGERS + 60 STAFF
-- =========================================================
WITH managers AS (
    SELECT g AS n
    FROM generate_series(1, 5) g
)
INSERT INTO public.can_bo (
    ten_dang_nhap,
    ho_ten,
    email,
    so_dien_thoai,
    don_vi,
    chuc_vu,
    vai_tro,
    trang_thai
)
SELECT
    'bulk_manager_' || lpad(n::text, 2, '0'),
    (ARRAY['Nguyễn','Trần','Lê','Phạm','Hoàng'])[n]
        || ' Minh '
        || (ARRAY['Quân','Hải','Lan','Hùng','Anh'])[n],
    'bulk_manager_' || lpad(n::text, 2, '0') || '@uniadmsys.local',
    '0908' || lpad(n::text, 6, '0'),
    'Phòng Tuyển sinh',
    CASE
        WHEN n = 1 THEN 'Trưởng phòng'
        WHEN n = 2 THEN 'Phó phòng'
        ELSE 'Quản lý tuyển sinh'
    END,
    'quan_ly',
    'hoat_dong'
FROM managers;

WITH staff AS (
    SELECT
        g AS n,
        (ARRAY[
            'Nguyễn','Trần','Lê','Phạm','Hoàng','Huỳnh',
            'Phan','Vũ','Võ','Đặng','Bùi','Đỗ'
        ])[1 + ((g - 1) % 12)] AS ho,
        (ARRAY[
            'Minh','Thanh','Quốc','Gia','Ngọc','Hoài',
            'Hữu','Phương','Quang','Tuấn','Khánh','Anh'
        ])[1 + ((g * 3 - 1) % 12)] AS dem,
        (ARRAY[
            'An','Bảo','Châu','Duy','Hà','Hải','Hân','Huy',
            'Khang','Linh','Long','Mai','Nam','Ngân','Phúc','Trang'
        ])[1 + ((g * 5 - 1) % 16)] AS ten
    FROM generate_series(1, 60) g
)
INSERT INTO public.can_bo (
    ten_dang_nhap,
    ho_ten,
    email,
    so_dien_thoai,
    don_vi,
    chuc_vu,
    vai_tro,
    trang_thai
)
SELECT
    'bulk_staff_' || lpad(n::text, 3, '0'),
    ho || ' ' || dem || ' ' || ten,
    'bulk_staff_' || lpad(n::text, 3, '0') || '@uniadmsys.local',
    '0918' || lpad(n::text, 6, '0'),
    CASE
        WHEN n % 4 = 0 THEN 'Phòng Tuyển sinh'
        WHEN n % 4 = 1 THEN 'Phòng Đào tạo'
        WHEN n % 4 = 2 THEN 'Bộ phận Hồ sơ'
        ELSE 'Bộ phận Dữ liệu'
    END,
    CASE
        WHEN n % 4 = 0 THEN 'Chuyên viên xét tuyển'
        WHEN n % 4 = 1 THEN 'Chuyên viên đào tạo'
        WHEN n % 4 = 2 THEN 'Chuyên viên hồ sơ'
        ELSE 'Chuyên viên dữ liệu'
    END,
    'can_bo',
    CASE WHEN n % 20 = 0 THEN 'tam_khoa' ELSE 'hoat_dong' END
FROM staff;


-- =========================================================
-- 2) 1,000 APPLICANTS
-- =========================================================
WITH src AS (
    SELECT
        g AS n,
        (ARRAY[
            'Nguyễn','Trần','Lê','Phạm','Hoàng','Huỳnh',
            'Phan','Vũ','Võ','Đặng','Bùi','Đỗ','Hồ','Ngô','Dương'
        ])[1 + ((g - 1) % 15)] AS ho,
        (ARRAY[
            'Văn','Thị','Minh','Quốc','Gia','Thanh','Đức','Ngọc',
            'Hoài','Anh','Tuấn','Khánh','Hữu','Phương','Quang'
        ])[1 + ((g * 3 - 1) % 15)] AS dem,
        (ARRAY[
            'An','Bảo','Châu','Duy','Hà','Hải','Hân','Huy','Khang','Linh',
            'Long','Mai','Nam','Ngân','Nhật','Phúc','Quân','Thảo','Trang','Vy'
        ])[1 + ((g * 7 - 1) % 20)] AS ten
    FROM generate_series(1, 1000) g
)
INSERT INTO public.thi_sinh (
    cccd,
    ho_ten,
    ngay_sinh,
    gioi_tinh,
    tinh_thanh,
    so_dien_thoai,
    email
)
SELECT
    '08120' || lpad(n::text, 7, '0'),
    ho || ' ' || dem || ' ' || ten,
    DATE '2007-01-01' + ((n * 7) % 365),
    CASE WHEN n % 2 = 0 THEN 'Nam' ELSE 'Nữ' END,
    (ARRAY[
        'TP. Hồ Chí Minh','Hà Nội','Đà Nẵng','Cần Thơ','Hải Phòng',
        'Đồng Nai','Bình Dương','Khánh Hòa','Lâm Đồng','Huế',
        'Quảng Nam','Nghệ An','Thanh Hóa','Bắc Ninh','Tiền Giang',
        'An Giang','Long An','Bến Tre','Quảng Ngãi','Bình Định'
    ])[1 + ((n - 1) % 20)],
    '092' || lpad(n::text, 7, '0'),
    'bulk_candidate_' || lpad(n::text, 4, '0') || '@uniadmsys.local'
FROM src;


-- =========================================================
-- 3) APPLICATION DOSSIERS
-- Assign active staff in round-robin.
-- =========================================================
WITH candidates AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local'
),
staff AS (
    SELECT
        cb.ma_can_bo,
        row_number() OVER (ORDER BY cb.ma_can_bo) AS rn,
        count(*) OVER () AS cnt
    FROM public.can_bo cb
    WHERE cb.email LIKE 'bulk_staff_%@uniadmsys.local'
      AND cb.trang_thai = 'hoat_dong'
)
INSERT INTO public.ho_so_xet_tuyen (
    ma_thi_sinh,
    nam,
    trang_thai,
    ma_can_bo_phu_trach,
    ngay_nop,
    ngay_duyet,
    ghi_chu
)
SELECT
    c.ma_thi_sinh,
    2025,
    CASE
        WHEN c.rn % 10 = 0 THEN 'yeu_cau_bo_sung'
        WHEN c.rn % 7 = 0 THEN 'dang_duyet'
        WHEN c.rn % 5 = 0 THEN 'hoan_tat'
        ELSE 'da_nop'
    END,
    (
        SELECT s.ma_can_bo
        FROM staff s
        WHERE s.rn = 1 + ((c.rn - 1) % s.cnt)
        LIMIT 1
    ),
    now() - ((c.rn % 90) || ' days')::interval,
    CASE
        WHEN c.rn % 5 = 0
            THEN now() - ((c.rn % 30) || ' days')::interval
        ELSE NULL
    END,
    'Synthetic bulk demo dossier'
FROM candidates c
ON CONFLICT (ma_thi_sinh, nam)
DO UPDATE SET
    trang_thai = EXCLUDED.trang_thai,
    ma_can_bo_phu_trach = EXCLUDED.ma_can_bo_phu_trach,
    ngay_nop = EXCLUDED.ngay_nop,
    ngay_duyet = EXCLUDED.ngay_duyet,
    ghi_chu = EXCLUDED.ghi_chu;


-- =========================================================
-- 4) 9,000 EXAM SCORES
-- =========================================================
WITH subjects(ma_mon, mon_thi, salt) AS (
    VALUES
        ('TOAN','Toán',11),
        ('VAN','Ngữ văn',17),
        ('ANH','Tiếng Anh',23),
        ('LY','Vật lý',31),
        ('HOA','Hóa học',37),
        ('SINH','Sinh học',41),
        ('SU','Lịch sử',43),
        ('DIA','Địa lý',47),
        ('GDKT_PL','Giáo dục kinh tế và pháp luật',53)
),
candidates AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local'
)
INSERT INTO public.diem_thi (
    ma_thi_sinh,
    nam,
    mon_thi,
    ma_mon,
    diem
)
SELECT
    c.ma_thi_sinh,
    2025,
    s.mon_thi,
    s.ma_mon,
    round(
        LEAST(
            10.00,
            3.50 + (((c.rn * s.salt) % 651)::numeric / 100)
        ),
        2
    )
FROM candidates c
CROSS JOIN subjects s
ON CONFLICT (ma_thi_sinh, nam, ma_mon)
WHERE ma_mon IS NOT NULL
DO UPDATE SET
    mon_thi = EXCLUDED.mon_thi,
    diem = EXCLUDED.diem;


-- =========================================================
-- 5) 6 PREFERENCES PER APPLICANT = ~6,000
-- =========================================================
WITH major_pool AS (
    SELECT
        n.ma_nganh,
        n.ma_truong,
        row_number() OVER (ORDER BY n.ma_truong, n.ma_nganh) AS rn,
        count(*) OVER () AS cnt
    FROM public.nganh n
    WHERE n.nam = 2025
),
candidates AS (
    SELECT
        hs.ma_ho_so,
        hs.ma_thi_sinh,
        row_number() OVER (ORDER BY hs.ma_thi_sinh) AS rn
    FROM public.ho_so_xet_tuyen hs
    JOIN public.thi_sinh ts
      ON ts.ma_thi_sinh = hs.ma_thi_sinh
    WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local'
      AND hs.nam = 2025
),
chosen AS (
    SELECT
        c.ma_ho_so,
        c.ma_thi_sinh,
        c.rn,
        pref.pref_no,
        mp.ma_nganh,
        mp.ma_truong
    FROM candidates c
    CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6)) AS pref(pref_no)
    JOIN major_pool mp
      ON mp.rn = 1 + (((c.rn * 19 + pref.pref_no * 131) - 1) % mp.cnt)
),
enriched AS (
    SELECT
        ch.*,
        (
            SELECT x.ma_to_hop
            FROM public.nganh_to_hop_xet_tuyen x
            WHERE x.ma_nganh = ch.ma_nganh
              AND x.nam = 2025
            ORDER BY x.ma_to_hop
            LIMIT 1
        ) AS ma_to_hop,
        (
            SELECT p.ma_phuong_thuc
            FROM public.phuong_thuc_xet_tuyen p
            JOIN public.truong_dh t
              ON t.ma_tuyen_sinh = p.ma_truong
            WHERE t.ma_truong = ch.ma_truong
              AND p.nam = 2025
            ORDER BY p.ma_phuong_thuc
            LIMIT 1
        ) AS ma_phuong_thuc
    FROM chosen ch
)
INSERT INTO public.nguyen_vong (
    ma_ho_so,
    ma_thi_sinh,
    ma_nganh,
    nam,
    ma_phuong_thuc,
    ma_to_hop,
    thu_tu_nguyen_vong
)
SELECT
    ma_ho_so,
    ma_thi_sinh,
    ma_nganh,
    2025,
    ma_phuong_thuc,
    ma_to_hop,
    pref_no
FROM enriched
ON CONFLICT (ma_ho_so, thu_tu_nguyen_vong)
WHERE ma_ho_so IS NOT NULL
DO UPDATE SET
    ma_thi_sinh = EXCLUDED.ma_thi_sinh,
    ma_nganh = EXCLUDED.ma_nganh,
    nam = EXCLUDED.nam,
    ma_phuong_thuc = EXCLUDED.ma_phuong_thuc,
    ma_to_hop = EXCLUDED.ma_to_hop;


-- =========================================================
-- 6) ~6,000 CALCULATED RESULTS
-- No pass/fail state is stored.
-- =========================================================
WITH prefs AS (
    SELECT
        nv.ma_nv,
        nv.ma_thi_sinh,
        nv.thu_tu_nguyen_vong,
        row_number() OVER (
            ORDER BY nv.ma_thi_sinh, nv.thu_tu_nguyen_vong
        ) AS rn
    FROM public.nguyen_vong nv
    JOIN public.thi_sinh ts
      ON ts.ma_thi_sinh = nv.ma_thi_sinh
    WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local'
      AND nv.nam = 2025
)
INSERT INTO public.ket_qua_xet_tuyen (
    ma_thi_sinh,
    ma_nv,
    diem_xet_tuyen,
    ghi_chu
)
SELECT
    p.ma_thi_sinh,
    p.ma_nv,
    round(
        15.00
        + (((p.rn * 29 + p.thu_tu_nguyen_vong * 17) % 1501)::numeric / 100),
        2
    ),
    'Synthetic calculated score for bulk UI/backend testing'
FROM prefs p
ON CONFLICT (ma_nv)
DO UPDATE SET
    diem_xet_tuyen = EXCLUDED.diem_xet_tuyen,
    ghi_chu = EXCLUDED.ghi_chu;


-- =========================================================
-- 7) ACHIEVEMENTS / CERTIFICATES
-- =========================================================
WITH candidates AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local'
),
active_staff AS (
    SELECT
        cb.ma_can_bo,
        row_number() OVER (ORDER BY cb.ma_can_bo) AS rn,
        count(*) OVER () AS cnt
    FROM public.can_bo cb
    WHERE cb.email LIKE 'bulk_staff_%@uniadmsys.local'
      AND cb.trang_thai = 'hoat_dong'
),
evidence AS (
    SELECT
        ma_thi_sinh,
        rn,
        'chung_chi'::varchar AS nhom,
        'ielts'::varchar AS loai,
        'IELTS Academic'::text AS ten,
        'English'::varchar AS mon_linh_vuc,
        NULL::varchar AS cap_giai,
        NULL::smallint AS thu_hang_giai,
        round((5.0 + ((rn % 8) * 0.5))::numeric,1) AS diem_so,
        '9.0'::varchar AS thang_diem,
        'British Council / IDP'::varchar AS don_vi_cap
    FROM candidates WHERE rn % 3 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'chung_chi','sat','SAT','Standardized Test',
        NULL,NULL,(1050 + ((rn * 37) % 501))::numeric,'1600','College Board'
    FROM candidates WHERE rn % 7 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'chung_chi','toefl_ibt','TOEFL iBT','English',
        NULL,NULL,(60 + ((rn * 11) % 61))::numeric,'120','ETS'
    FROM candidates WHERE rn % 11 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'chung_chi','act','ACT','Standardized Test',
        NULL,NULL,(20 + ((rn * 5) % 17))::numeric,'36','ACT'
    FROM candidates WHERE rn % 17 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'thanh_tich','hsg_quoc_gia','Học sinh giỏi Quốc gia',
        (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])
            [1 + ((rn - 1) % 7)],
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])[1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,NULL,'Bộ Giáo dục và Đào tạo'
    FROM candidates WHERE rn % 19 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'thanh_tich','hsg_tinh','Học sinh giỏi cấp Tỉnh/Thành phố',
        (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])
            [1 + ((rn + 2) % 7)],
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba','Giải Khuyến khích'])
            [1 + ((rn - 1) % 4)],
        (1 + ((rn - 1) % 4))::smallint,
        NULL,NULL,'Sở Giáo dục và Đào tạo'
    FROM candidates WHERE rn % 13 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'thanh_tich','khkt_quoc_gia',
        'Cuộc thi Khoa học Kỹ thuật cấp Quốc gia',
        'Khoa học kỹ thuật',
        (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])[1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,NULL,'Bộ Giáo dục và Đào tạo'
    FROM candidates WHERE rn % 29 = 0

    UNION ALL

    SELECT
        ma_thi_sinh,rn,'thanh_tich','olympic','Olympic',
        (ARRAY['Toán','Vật lý','Hóa học','Tin học'])[1 + ((rn - 1) % 4)],
        (ARRAY['Gold','Silver','Bronze'])[1 + ((rn - 1) % 3)],
        (1 + ((rn - 1) % 3))::smallint,
        NULL,NULL,'Olympic Committee'
    FROM candidates WHERE rn % 31 = 0
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
    e.ma_thi_sinh,
    e.nhom,
    e.loai,
    e.ten,
    e.mon_linh_vuc,
    e.cap_giai,
    e.thu_hang_giai,
    e.diem_so,
    e.thang_diem,
    e.don_vi_cap,
    DATE '2024-01-01' + (((e.rn * 7) % 550)::int),
    CASE
        WHEN e.nhom = 'chung_chi'
            THEN (DATE '2024-01-01' + (((e.rn * 7) % 550)::int)) + 730
        ELSE NULL
    END,
    CASE
        WHEN e.rn % 8 = 0 THEN 'chua_xac_minh'
        ELSE 'da_xac_minh'
    END,
    CASE
        WHEN e.rn % 8 <> 0
        THEN (
            SELECT s.ma_can_bo
            FROM active_staff s
            WHERE s.rn = 1 + ((e.rn - 1) % s.cnt)
            LIMIT 1
        )
        ELSE NULL
    END,
    CASE
        WHEN e.rn % 8 <> 0
            THEN now() - ((e.rn % 30) || ' days')::interval
        ELSE NULL
    END,
    'Synthetic bulk demo evidence'
FROM evidence e;


-- =========================================================
-- 8) DEMO FLOOR-SCORE DATA FOR UP TO 200 SCHOOLS
-- Synthetic only, clearly marked.
-- =========================================================
WITH schools AS (
    SELECT
        trim(t.ma_tuyen_sinh) AS ma_truong,
        row_number() OVER (ORDER BY t.ma_tuyen_sinh) AS rn
    FROM public.truong_dh t
    WHERE NULLIF(trim(t.ma_tuyen_sinh), '') IS NOT NULL
    ORDER BY t.ma_tuyen_sinh
    LIMIT 200
)
INSERT INTO public.nguong_dau_vao (
    ma_truong,
    nam,
    ma_nganh,
    ma_phuong_thuc,
    diem_san_min,
    diem_san_max,
    trang_thai,
    ghi_chu,
    source_url
)
SELECT
    s.ma_truong,
    2025,
    NULL,
    NULL,
    round((15 + ((s.rn * 7) % 6))::numeric, 2),
    round((
        (15 + ((s.rn * 7) % 6))
        + 1
        + ((s.rn * 11) % 4)
    )::numeric, 2),
    'demo',
    'Synthetic floor-score range for UI/backend testing only',
    'demo://bulk-floor-score'
FROM schools s
ON CONFLICT DO NOTHING;


COMMIT;


-- =========================================================
-- QA / COUNTS
-- =========================================================
SELECT
    (SELECT COUNT(*) FROM public.can_bo
     WHERE email LIKE 'bulk_%@uniadmsys.local') AS can_bo_bulk,

    (SELECT COUNT(*) FROM public.thi_sinh
     WHERE email LIKE 'bulk_candidate_%@uniadmsys.local') AS thi_sinh_bulk,

    (SELECT COUNT(*) FROM public.ho_so_xet_tuyen hs
     JOIN public.thi_sinh ts ON ts.ma_thi_sinh = hs.ma_thi_sinh
     WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local') AS ho_so_bulk,

    (SELECT COUNT(*) FROM public.diem_thi d
     JOIN public.thi_sinh ts ON ts.ma_thi_sinh = d.ma_thi_sinh
     WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local') AS diem_thi_bulk,

    (SELECT COUNT(*) FROM public.nguyen_vong nv
     JOIN public.thi_sinh ts ON ts.ma_thi_sinh = nv.ma_thi_sinh
     WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local') AS nguyen_vong_bulk,

    (SELECT COUNT(*) FROM public.ket_qua_xet_tuyen kq
     JOIN public.thi_sinh ts ON ts.ma_thi_sinh = kq.ma_thi_sinh
     WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local') AS ket_qua_bulk,

    (SELECT COUNT(*) FROM public.thanh_tich_chung_chi tc
     JOIN public.thi_sinh ts ON ts.ma_thi_sinh = tc.ma_thi_sinh
     WHERE ts.email LIKE 'bulk_candidate_%@uniadmsys.local') AS thanh_tich_bulk,

    (SELECT COUNT(*) FROM public.nguong_dau_vao
     WHERE source_url = 'demo://bulk-floor-score') AS nguong_dau_vao_bulk;

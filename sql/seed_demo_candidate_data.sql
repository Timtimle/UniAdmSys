-- UniAdmSys: DEMO staff + candidate data
-- Synthetic data only. No real personal information or real staff accounts.
-- Run after add_candidate_flow_and_floor_score.sql.
-- Safe to rerun: removes only records created by this script.

BEGIN;

-- =========================================================
-- 0) CLEAN PREVIOUS DEMO DATA
-- =========================================================
DELETE FROM public.ket_qua_xet_tuyen
WHERE ma_thi_sinh IN (
    SELECT ma_thi_sinh
    FROM public.thi_sinh
    WHERE email LIKE 'demo_candidate_%@uniadmsys.local'
);

DELETE FROM public.nguyen_vong
WHERE ma_thi_sinh IN (
    SELECT ma_thi_sinh
    FROM public.thi_sinh
    WHERE email LIKE 'demo_candidate_%@uniadmsys.local'
);

DELETE FROM public.diem_thi
WHERE ma_thi_sinh IN (
    SELECT ma_thi_sinh
    FROM public.thi_sinh
    WHERE email LIKE 'demo_candidate_%@uniadmsys.local'
);

DELETE FROM public.thi_sinh
WHERE email LIKE 'demo_candidate_%@uniadmsys.local';

DELETE FROM public.can_bo
WHERE email LIKE 'demo_staff_%@uniadmsys.local'
   OR email = 'demo_manager@uniadmsys.local';

-- =========================================================
-- 1) STAFF ACCOUNTS
-- These rows are staff profiles only; login credentials belong in Supabase Auth.
-- =========================================================
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
VALUES
(
    'manager',
    'Nguyễn Minh Quản',
    'demo_manager@uniadmsys.local',
    '0900000001',
    'Phòng Tuyển sinh',
    'Trưởng bộ phận',
    'quan_ly',
    'hoat_dong'
);

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
    FROM generate_series(1, 30) g
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
    'staff' || lpad(n::text, 2, '0'),
    ho || ' ' || dem || ' ' || ten,
    'demo_staff_' || lpad(n::text, 2, '0') || '@uniadmsys.local',
    '091' || lpad(n::text, 7, '0'),
    CASE
        WHEN n % 3 = 0 THEN 'Phòng Tuyển sinh'
        WHEN n % 3 = 1 THEN 'Phòng Đào tạo'
        ELSE 'Bộ phận Hồ sơ'
    END,
    CASE
        WHEN n % 4 = 0 THEN 'Chuyên viên xét tuyển'
        WHEN n % 4 = 1 THEN 'Chuyên viên hồ sơ'
        WHEN n % 4 = 2 THEN 'Chuyên viên dữ liệu'
        ELSE 'Cán bộ tuyển sinh'
    END,
    'can_bo',
    CASE WHEN n % 15 = 0 THEN 'tam_khoa' ELSE 'hoat_dong' END
FROM staff;

-- =========================================================
-- 2) 300 SYNTHETIC APPLICANTS
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
    FROM generate_series(1, 300) g
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
    '07920' || lpad(n::text, 7, '0'),
    ho || ' ' || dem || ' ' || ten,
    DATE '2007-01-01' + ((n * 5) % 330),
    CASE WHEN n % 2 = 0 THEN 'Nam' ELSE 'Nữ' END,
    (ARRAY[
        'TP. Hồ Chí Minh','Hà Nội','Đà Nẵng','Cần Thơ','Hải Phòng',
        'Đồng Nai','Bình Dương','Khánh Hòa','Lâm Đồng','Thừa Thiên Huế',
        'Quảng Nam','Nghệ An','Thanh Hóa','Bắc Ninh','Tiền Giang'
    ])[1 + ((n - 1) % 15)],
    '09' || lpad((10000000 + n)::text, 8, '0'),
    'demo_candidate_' || lpad(n::text, 3, '0') || '@uniadmsys.local'
FROM src;

-- =========================================================
-- 3) EXAM SCORES: 9 SUBJECTS / APPLICANT
-- =========================================================
WITH subjects(mon_thi, salt) AS (
    VALUES
        ('Toán', 11),
        ('Ngữ văn', 17),
        ('Tiếng Anh', 23),
        ('Vật lý', 31),
        ('Hóa học', 37),
        ('Sinh học', 41),
        ('Lịch sử', 43),
        ('Địa lý', 47),
        ('Giáo dục kinh tế và pháp luật', 53)
),
demo AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'demo_candidate_%@uniadmsys.local'
)
INSERT INTO public.diem_thi (
    ma_thi_sinh,
    nam,
    mon_thi,
    diem
)
SELECT
    d.ma_thi_sinh,
    2025,
    s.mon_thi,
    round(
        LEAST(
            10.00,
            4.00 + (((d.rn * s.salt) % 601)::numeric / 100)
        ),
        2
    )
FROM demo d
CROSS JOIN subjects s
ON CONFLICT (ma_thi_sinh, nam, mon_thi)
DO UPDATE SET diem = EXCLUDED.diem;

-- =========================================================
-- 4) PREFERENCES: 4 PER APPLICANT
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
demo AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'demo_candidate_%@uniadmsys.local'
),
chosen AS (
    SELECT
        d.ma_thi_sinh,
        d.rn AS candidate_no,
        pref.pref_no,
        mp.ma_nganh,
        mp.ma_truong
    FROM demo d
    CROSS JOIN (VALUES (1),(2),(3),(4)) AS pref(pref_no)
    JOIN major_pool mp
      ON mp.rn = 1 + (((d.rn * 13 + pref.pref_no * 97) - 1) % mp.cnt)
),
enriched AS (
    SELECT
        c.*,
        (
            SELECT x.ma_to_hop
            FROM public.nganh_to_hop_xet_tuyen x
            WHERE x.ma_nganh = c.ma_nganh
              AND x.nam = 2025
            ORDER BY x.ma_to_hop
            LIMIT 1
        ) AS ma_to_hop,
        (
            SELECT p.ma_phuong_thuc
            FROM public.phuong_thuc_xet_tuyen p
            JOIN public.truong_dh t
              ON t.ma_tuyen_sinh = p.ma_truong
            WHERE t.ma_truong = c.ma_truong
              AND p.nam = 2025
            ORDER BY p.ma_phuong_thuc
            LIMIT 1
        ) AS ma_phuong_thuc
    FROM chosen c
)
INSERT INTO public.nguyen_vong (
    ma_thi_sinh,
    ma_nganh,
    nam,
    ma_phuong_thuc,
    ma_to_hop,
    thu_tu_nguyen_vong
)
SELECT
    ma_thi_sinh,
    ma_nganh,
    2025,
    ma_phuong_thuc,
    ma_to_hop,
    pref_no
FROM enriched
ON CONFLICT (ma_thi_sinh, nam, thu_tu_nguyen_vong)
DO UPDATE SET
    ma_nganh = EXCLUDED.ma_nganh,
    ma_phuong_thuc = EXCLUDED.ma_phuong_thuc,
    ma_to_hop = EXCLUDED.ma_to_hop;

-- =========================================================
-- 5) CALCULATED SCORE ROWS
-- No admission status is stored.
-- The web/backend compares diem_xet_tuyen with diem_chuan dynamically.
-- =========================================================
WITH prefs AS (
    SELECT
        nv.ma_nv,
        nv.ma_thi_sinh,
        nv.thu_tu_nguyen_vong,
        row_number() OVER (ORDER BY nv.ma_thi_sinh, nv.thu_tu_nguyen_vong) AS rn
    FROM public.nguyen_vong nv
    JOIN public.thi_sinh ts
      ON ts.ma_thi_sinh = nv.ma_thi_sinh
    WHERE ts.email LIKE 'demo_candidate_%@uniadmsys.local'
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
        15.00 + (((p.rn * 29 + p.thu_tu_nguyen_vong * 17) % 1501)::numeric / 100),
        2
    ),
    'Synthetic calculated score for UI testing'
FROM prefs p
ON CONFLICT (ma_nv)
DO UPDATE SET
    diem_xet_tuyen = EXCLUDED.diem_xet_tuyen,
    ghi_chu = EXCLUDED.ghi_chu;

COMMIT;

-- =========================================================
-- QA
-- =========================================================
SELECT
    (SELECT COUNT(*) FROM public.can_bo
      WHERE email LIKE 'demo_%@uniadmsys.local') AS demo_can_bo,
    (SELECT COUNT(*) FROM public.thi_sinh
      WHERE email LIKE 'demo_candidate_%@uniadmsys.local') AS demo_thi_sinh,
    (SELECT COUNT(*) FROM public.diem_thi d
      JOIN public.thi_sinh t ON t.ma_thi_sinh = d.ma_thi_sinh
      WHERE t.email LIKE 'demo_candidate_%@uniadmsys.local') AS demo_diem_thi,
    (SELECT COUNT(*) FROM public.nguyen_vong n
      JOIN public.thi_sinh t ON t.ma_thi_sinh = n.ma_thi_sinh
      WHERE t.email LIKE 'demo_candidate_%@uniadmsys.local') AS demo_nguyen_vong,
    (SELECT COUNT(*) FROM public.ket_qua_xet_tuyen k
      JOIN public.thi_sinh t ON t.ma_thi_sinh = k.ma_thi_sinh
      WHERE t.email LIKE 'demo_candidate_%@uniadmsys.local') AS demo_ket_qua;

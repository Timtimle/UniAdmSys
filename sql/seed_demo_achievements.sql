-- UniAdmSys: synthetic demo achievements/certificates
-- Run after add_special_admission_and_certificates.sql

BEGIN;

DELETE FROM public.thanh_tich_chung_chi
WHERE ghi_chu = 'Synthetic demo evidence';

WITH demo AS (
    SELECT
        ts.ma_thi_sinh,
        row_number() OVER (ORDER BY ts.ma_thi_sinh) AS rn
    FROM public.thi_sinh ts
    WHERE ts.email LIKE 'demo_candidate_%@uniadmsys.local'
),
evidence AS (
    SELECT ma_thi_sinh,'chung_chi'::varchar AS nhom,'ielts'::varchar AS loai,
           'IELTS Academic'::text AS ten,'English'::varchar AS mon_linh_vuc,
           NULL::varchar AS cap_giai,NULL::smallint AS thu_hang_giai,
           round((5.0 + ((rn % 8) * 0.5))::numeric,1) AS diem_so,'9.0'::varchar AS thang_diem
    FROM demo WHERE rn % 4 = 0

    UNION ALL
    SELECT ma_thi_sinh,'chung_chi','sat','SAT','Standardized Test',
           NULL,NULL,(1050 + ((rn * 37) % 501))::numeric,'1600'
    FROM demo WHERE rn % 7 = 0

    UNION ALL
    SELECT ma_thi_sinh,'chung_chi','toefl_ibt','TOEFL iBT','English',
           NULL,NULL,(60 + ((rn * 11) % 61))::numeric,'120'
    FROM demo WHERE rn % 13 = 0

    UNION ALL
    SELECT ma_thi_sinh,'chung_chi','act','ACT','Standardized Test',
           NULL,NULL,(20 + ((rn * 5) % 17))::numeric,'36'
    FROM demo WHERE rn % 17 = 0

    UNION ALL
    SELECT ma_thi_sinh,'thanh_tich','hsg_quoc_gia','National Excellent Student Award',
           (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])[1 + ((rn - 1) % 7)],
           (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])[1 + ((rn - 1) % 3)],
           (1 + ((rn - 1) % 3))::smallint,NULL,NULL
    FROM demo WHERE rn % 19 = 0

    UNION ALL
    SELECT ma_thi_sinh,'thanh_tich','hsg_tinh','Provincial Excellent Student Award',
           (ARRAY['Toán','Vật lý','Hóa học','Sinh học','Tin học','Ngữ văn','Tiếng Anh'])[1 + ((rn + 2) % 7)],
           (ARRAY['Giải Nhất','Giải Nhì','Giải Ba','Giải Khuyến khích'])[1 + ((rn - 1) % 4)],
           (1 + ((rn - 1) % 4))::smallint,NULL,NULL
    FROM demo WHERE rn % 11 = 0

    UNION ALL
    SELECT ma_thi_sinh,'thanh_tich','khkt_quoc_gia','National Science and Engineering Competition',
           'Khoa học kỹ thuật',
           (ARRAY['Giải Nhất','Giải Nhì','Giải Ba'])[1 + ((rn - 1) % 3)],
           (1 + ((rn - 1) % 3))::smallint,NULL,NULL
    FROM demo WHERE rn % 29 = 0

    UNION ALL
    SELECT ma_thi_sinh,'thanh_tich','olympic','Olympic Award',
           (ARRAY['Toán','Vật lý','Hóa học','Tin học'])[1 + ((rn - 1) % 4)],
           (ARRAY['Gold','Silver','Bronze'])[1 + ((rn - 1) % 3)],
           (1 + ((rn - 1) % 3))::smallint,NULL,NULL
    FROM demo WHERE rn % 31 = 0
)
INSERT INTO public.thanh_tich_chung_chi (
    ma_thi_sinh,nhom,loai,ten,mon_linh_vuc,cap_giai,thu_hang_giai,
    diem_so,thang_diem,trang_thai_xac_minh,ghi_chu
)
SELECT
    ma_thi_sinh,nhom,loai,ten,mon_linh_vuc,cap_giai,thu_hang_giai,
    diem_so,thang_diem,
    CASE WHEN ma_thi_sinh % 5 = 0 THEN 'chua_xac_minh' ELSE 'da_xac_minh' END,
    'Synthetic demo evidence'
FROM evidence;

COMMIT;

SELECT loai, COUNT(*) AS so_luong
FROM public.thanh_tich_chung_chi
WHERE ghi_chu = 'Synthetic demo evidence'
GROUP BY loai
ORDER BY loai;

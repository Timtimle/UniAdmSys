-- UniAdmSys: staging cho điểm chuẩn 2025
CREATE TABLE IF NOT EXISTS diem_chuan_import_2025 (
    ma_tuyen_sinh VARCHAR(20) NOT NULL,
    ma_nganh_tuyen_sinh VARCHAR(80) NOT NULL,
    ten_nganh TEXT,
    to_hop_xet_tuyen TEXT,
    diem_chuan NUMERIC,
    phuong_thuc TEXT,
    ghi_chu TEXT,
    nam SMALLINT NOT NULL DEFAULT 2025,
    source_url TEXT
);

TRUNCATE TABLE diem_chuan_import_2025;

-- Sau khi import data/diem_chuan_2025_supabase.csv vào bảng trên,
-- chạy query này để kiểm tra khả năng map sang bảng nganh:
SELECT
    COUNT(*) AS tong_dong,
    COUNT(n.ma_nganh) AS map_duoc_nganh,
    COUNT(*) - COUNT(n.ma_nganh) AS chua_map_duoc
FROM diem_chuan_import_2025 s
LEFT JOIN truong_dh t
    ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
LEFT JOIN nganh n
    ON n.ma_truong = t.ma_truong
   AND n.ma_nganh_tuyen_sinh = s.ma_nganh_tuyen_sinh
   AND n.nam = 2025;

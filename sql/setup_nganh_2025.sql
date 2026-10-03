-- UniAdmSys: import ngành tuyển sinh năm 2025

-- Bảng nganh hiện tại dùng ma_nganh VARCHAR(20).
-- Dữ liệu 2025 có tên chương trình dài, nên dùng TEXT.
ALTER TABLE nganh
ALTER COLUMN ten_nganh TYPE TEXT;

ALTER TABLE nganh
ADD COLUMN IF NOT EXISTS ma_nganh_tuyen_sinh VARCHAR(80),
ADD COLUMN IF NOT EXISTS nam SMALLINT,
ADD COLUMN IF NOT EXISTS danh_muc_nganh_id BIGINT,
ADD COLUMN IF NOT EXISTS source_url TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'nganh_danh_muc_nganh_id_fkey'
    ) THEN
        ALTER TABLE nganh
        ADD CONSTRAINT nganh_danh_muc_nganh_id_fkey
        FOREIGN KEY (danh_muc_nganh_id)
        REFERENCES danh_muc_nganh(id);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS nganh_import_2025 (
    ma_tuyen_sinh VARCHAR(20) NOT NULL,
    ma_nganh_tuyen_sinh VARCHAR(80) NOT NULL,
    ten_nganh TEXT NOT NULL,
    ma_nganh_bo VARCHAR(20),
    nam SMALLINT NOT NULL DEFAULT 2025,
    source_url TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_nganh_school_code_year
ON nganh(ma_truong, ma_nganh_tuyen_sinh, nam);

-- Import data/nganh_2025_supabase.csv vào nganh_import_2025 trước.
-- Sau đó chạy phần INSERT dưới đây.
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
    FROM nganh_import_2025 s
    JOIN truong_dh t
        ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
)
INSERT INTO nganh (
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
    ) AS ma_nganh,
    src.ma_truong,
    src.ten_nganh,
    src.ma_nganh_tuyen_sinh,
    src.nam,
    d.id,
    src.source_url
FROM src
LEFT JOIN danh_muc_nganh d
    ON d.ma_nganh_bo = NULLIF(src.ma_nganh_bo, '')
WHERE src.rn = 1
ON CONFLICT (ma_truong, ma_nganh_tuyen_sinh, nam)
DO UPDATE SET
    ten_nganh = EXCLUDED.ten_nganh,
    danh_muc_nganh_id = EXCLUDED.danh_muc_nganh_id,
    source_url = EXCLUDED.source_url;

-- QA
SELECT COUNT(*) AS so_nganh_2025
FROM nganh
WHERE nam = 2025;

SELECT DISTINCT s.ma_tuyen_sinh
FROM nganh_import_2025 s
LEFT JOIN truong_dh t
    ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
WHERE t.ma_truong IS NULL
ORDER BY s.ma_tuyen_sinh;

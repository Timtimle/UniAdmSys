-- UniAdmSys: setup + import mapping ngành tuyển sinh 2024
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

CREATE TABLE IF NOT EXISTS nganh_import_2024 (
    ma_tuyen_sinh VARCHAR(20) NOT NULL,
    ma_nganh_tuyen_sinh VARCHAR(80) NOT NULL,
    ten_nganh TEXT NOT NULL,
    ma_nganh_bo VARCHAR(20),
    nam SMALLINT NOT NULL DEFAULT 2024,
    source_url TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_nganh_school_code_year
ON nganh(ma_truong, ma_nganh_tuyen_sinh, nam);

-- Import data/nganh_2024_supabase.csv vào nganh_import_2024 trước rồi chạy phần dưới:
INSERT INTO nganh (
    ma_truong,
    ten_nganh,
    ma_nganh_tuyen_sinh,
    nam,
    danh_muc_nganh_id,
    source_url
)
SELECT
    t.ma_truong,
    s.ten_nganh,
    s.ma_nganh_tuyen_sinh,
    s.nam,
    d.id,
    s.source_url
FROM nganh_import_2024 s
JOIN truong_dh t
  ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
LEFT JOIN danh_muc_nganh d
  ON d.ma_nganh_bo = NULLIF(s.ma_nganh_bo, '')
ON CONFLICT (ma_truong, ma_nganh_tuyen_sinh, nam)
DO UPDATE SET
    ten_nganh = EXCLUDED.ten_nganh,
    danh_muc_nganh_id = EXCLUDED.danh_muc_nganh_id,
    source_url = EXCLUDED.source_url;

SELECT COUNT(*) AS so_nganh_2024
FROM nganh
WHERE nam = 2024;

SELECT COUNT(*) AS staging_khong_match_truong
FROM nganh_import_2024 s
LEFT JOIN truong_dh t ON t.ma_tuyen_sinh = s.ma_tuyen_sinh
WHERE t.ma_truong IS NULL;

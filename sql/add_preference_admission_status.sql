-- UniAdmSys: preference-order admission result engine
-- Project logic:
--   1) Evaluate preferences from NV1 -> NV2 -> NV3 -> ...
--   2) The first eligible preference becomes the admitted preference.
--   3) Earlier preferences that do not meet requirements are "khong_dat".
--   4) Lower preferences after an admission are "khong_xet".
--   5) Direct-admission eligibility can satisfy a preference without score comparison.
--
-- The engine uses ket_qua_xet_tuyen.diem_xet_tuyen as the calculated applicant score.
-- It resolves an applicable 2025 cutoff from diem_chuan, preferring method/combo matches.

BEGIN;

-- =========================================================
-- 1) RESULT STATUS PER PREFERENCE
-- =========================================================
ALTER TABLE public.ket_qua_xet_tuyen
    ADD COLUMN IF NOT EXISTS diem_chuan_id BIGINT,
    ADD COLUMN IF NOT EXISTS diem_chuan_ap_dung NUMERIC(8,2),
    ADD COLUMN IF NOT EXISTS trang_thai VARCHAR(30) DEFAULT 'cho_xet',
    ADD COLUMN IF NOT EXISTS xet_tuyen_thang BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS ly_do TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

ALTER TABLE public.ket_qua_xet_tuyen
    DROP CONSTRAINT IF EXISTS ket_qua_trang_thai_check;

ALTER TABLE public.ket_qua_xet_tuyen
    ADD CONSTRAINT ket_qua_trang_thai_check
    CHECK (
        trang_thai IN (
            'cho_xet',
            'trung_tuyen',
            'khong_dat',
            'khong_xet',
            'thieu_du_lieu'
        )
    );

ALTER TABLE public.ket_qua_xet_tuyen
    DROP CONSTRAINT IF EXISTS ket_qua_diem_chuan_id_fkey;

ALTER TABLE public.ket_qua_xet_tuyen
    ADD CONSTRAINT ket_qua_diem_chuan_id_fkey
    FOREIGN KEY (diem_chuan_id)
    REFERENCES public.diem_chuan(id)
    ON DELETE SET NULL;


-- =========================================================
-- 2) DOSSIER-LEVEL SUMMARY
-- Keep this separate from ho_so_xet_tuyen.trang_thai,
-- because that field describes workflow, not admission outcome.
-- =========================================================
ALTER TABLE public.ho_so_xet_tuyen
    ADD COLUMN IF NOT EXISTS ket_qua_xet_tuyen VARCHAR(30) DEFAULT 'chua_xet',
    ADD COLUMN IF NOT EXISTS ma_nv_trung_tuyen BIGINT,
    ADD COLUMN IF NOT EXISTS xet_tuyen_luc TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.ho_so_xet_tuyen
    DROP CONSTRAINT IF EXISTS ho_so_ket_qua_xet_tuyen_check;

ALTER TABLE public.ho_so_xet_tuyen
    ADD CONSTRAINT ho_so_ket_qua_xet_tuyen_check
    CHECK (
        ket_qua_xet_tuyen IN (
            'chua_xet',
            'trung_tuyen',
            'khong_trung_tuyen',
            'thieu_du_lieu'
        )
    );

ALTER TABLE public.ho_so_xet_tuyen
    DROP CONSTRAINT IF EXISTS ho_so_ma_nv_trung_tuyen_fkey;

ALTER TABLE public.ho_so_xet_tuyen
    ADD CONSTRAINT ho_so_ma_nv_trung_tuyen_fkey
    FOREIGN KEY (ma_nv_trung_tuyen)
    REFERENCES public.nguyen_vong(ma_nv)
    ON DELETE SET NULL;


-- =========================================================
-- 3) RESULT ENGINE
-- =========================================================
CREATE OR REPLACE FUNCTION public.recalculate_admission_results(
    p_ma_thi_sinh BIGINT DEFAULT NULL,
    p_nam SMALLINT DEFAULT 2025
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    c RECORD;
    r RECORD;

    v_admitted BOOLEAN;
    v_admitted_nv BIGINT;
    v_has_missing BOOLEAN;

    v_direct BOOLEAN;
    v_cutoff_id BIGINT;
    v_cutoff NUMERIC(8,2);
BEGIN
    FOR c IN
        SELECT DISTINCT nv.ma_thi_sinh
        FROM public.nguyen_vong nv
        WHERE nv.nam = p_nam
          AND (p_ma_thi_sinh IS NULL OR nv.ma_thi_sinh = p_ma_thi_sinh)
        ORDER BY nv.ma_thi_sinh
    LOOP
        v_admitted := false;
        v_admitted_nv := NULL;
        v_has_missing := false;

        FOR r IN
            SELECT
                nv.ma_nv,
                nv.ma_ho_so,
                nv.ma_thi_sinh,
                nv.ma_nganh,
                nv.nam,
                nv.ma_phuong_thuc,
                nv.ma_to_hop,
                nv.thu_tu_nguyen_vong,
                kq.diem_xet_tuyen,
                t.ma_tuyen_sinh AS ma_truong,
                p.ten_phuong_thuc
            FROM public.nguyen_vong nv
            JOIN public.nganh n
              ON n.ma_nganh = nv.ma_nganh
            JOIN public.truong_dh t
              ON t.ma_truong = n.ma_truong
            LEFT JOIN public.phuong_thuc_xet_tuyen p
              ON p.ma_phuong_thuc = nv.ma_phuong_thuc
            LEFT JOIN public.ket_qua_xet_tuyen kq
              ON kq.ma_nv = nv.ma_nv
            WHERE nv.ma_thi_sinh = c.ma_thi_sinh
              AND nv.nam = p_nam
            ORDER BY nv.thu_tu_nguyen_vong, nv.ma_nv
        LOOP
            v_direct := false;
            v_cutoff_id := NULL;
            v_cutoff := NULL;

            -- -------------------------------------------------
            -- Direct-admission rule match for this preference.
            -- Rule may be school-wide (ma_nganh NULL) or major-specific.
            -- -------------------------------------------------
            SELECT EXISTS (
                SELECT 1
                FROM public.v_xet_tuyen_thang_kha_dung xt
                WHERE xt.ma_thi_sinh = r.ma_thi_sinh
                  AND xt.nam = p_nam
                  AND xt.ma_truong = r.ma_truong
                  AND (xt.ma_nganh IS NULL OR xt.ma_nganh = r.ma_nganh)
                  AND (
                        xt.ma_phuong_thuc IS NULL
                        OR xt.ma_phuong_thuc = r.ma_phuong_thuc
                  )
                  AND xt.xet_tuyen_thang = true
            )
            INTO v_direct;

            -- -------------------------------------------------
            -- Resolve cutoff. Priority:
            -- 0 = method + subject combination
            -- 1 = method
            -- 2 = subject combination
            -- 3 = general major cutoff fallback
            -- -------------------------------------------------
            SELECT dc.id, dc.diem
            INTO v_cutoff_id, v_cutoff
            FROM public.diem_chuan dc
            WHERE dc.ma_nganh = r.ma_nganh
              AND dc.nam = p_nam
              AND dc.diem IS NOT NULL
            ORDER BY
                CASE
                    WHEN
                        r.ten_phuong_thuc IS NOT NULL
                        AND dc.phuong_thuc IS NOT NULL
                        AND lower(
                            regexp_replace(trim(dc.phuong_thuc), '[[:space:]]+', ' ', 'g')
                        ) = lower(
                            regexp_replace(trim(r.ten_phuong_thuc), '[[:space:]]+', ' ', 'g')
                        )
                        AND r.ma_to_hop IS NOT NULL
                        AND dc.to_hop IS NOT NULL
                        AND position(upper(r.ma_to_hop) IN upper(dc.to_hop)) > 0
                    THEN 0

                    WHEN
                        r.ten_phuong_thuc IS NOT NULL
                        AND dc.phuong_thuc IS NOT NULL
                        AND lower(
                            regexp_replace(trim(dc.phuong_thuc), '[[:space:]]+', ' ', 'g')
                        ) = lower(
                            regexp_replace(trim(r.ten_phuong_thuc), '[[:space:]]+', ' ', 'g')
                        )
                    THEN 1

                    WHEN
                        r.ma_to_hop IS NOT NULL
                        AND dc.to_hop IS NOT NULL
                        AND position(upper(r.ma_to_hop) IN upper(dc.to_hop)) > 0
                    THEN 2

                    ELSE 3
                END,
                dc.diem ASC,
                dc.id ASC
            LIMIT 1;

            -- -------------------------------------------------
            -- Preference-order evaluation
            -- -------------------------------------------------
            IF v_admitted THEN
                INSERT INTO public.ket_qua_xet_tuyen (
                    ma_thi_sinh,
                    ma_nv,
                    diem_xet_tuyen,
                    diem_chuan_id,
                    diem_chuan_ap_dung,
                    trang_thai,
                    xet_tuyen_thang,
                    ly_do,
                    updated_at
                )
                VALUES (
                    r.ma_thi_sinh,
                    r.ma_nv,
                    r.diem_xet_tuyen,
                    v_cutoff_id,
                    v_cutoff,
                    'khong_xet',
                    false,
                    'Đã trúng tuyển ở nguyện vọng ưu tiên cao hơn',
                    now()
                )
                ON CONFLICT (ma_nv)
                DO UPDATE SET
                    diem_chuan_id = EXCLUDED.diem_chuan_id,
                    diem_chuan_ap_dung = EXCLUDED.diem_chuan_ap_dung,
                    trang_thai = EXCLUDED.trang_thai,
                    xet_tuyen_thang = EXCLUDED.xet_tuyen_thang,
                    ly_do = EXCLUDED.ly_do,
                    updated_at = now();

            ELSIF v_direct THEN
                v_admitted := true;
                v_admitted_nv := r.ma_nv;

                INSERT INTO public.ket_qua_xet_tuyen (
                    ma_thi_sinh,
                    ma_nv,
                    diem_xet_tuyen,
                    diem_chuan_id,
                    diem_chuan_ap_dung,
                    trang_thai,
                    xet_tuyen_thang,
                    ly_do,
                    updated_at
                )
                VALUES (
                    r.ma_thi_sinh,
                    r.ma_nv,
                    r.diem_xet_tuyen,
                    v_cutoff_id,
                    v_cutoff,
                    'trung_tuyen',
                    true,
                    'Đủ điều kiện xét tuyển thẳng ở nguyện vọng này',
                    now()
                )
                ON CONFLICT (ma_nv)
                DO UPDATE SET
                    diem_chuan_id = EXCLUDED.diem_chuan_id,
                    diem_chuan_ap_dung = EXCLUDED.diem_chuan_ap_dung,
                    trang_thai = EXCLUDED.trang_thai,
                    xet_tuyen_thang = EXCLUDED.xet_tuyen_thang,
                    ly_do = EXCLUDED.ly_do,
                    updated_at = now();

            ELSIF r.diem_xet_tuyen IS NULL OR v_cutoff IS NULL THEN
                v_has_missing := true;

                INSERT INTO public.ket_qua_xet_tuyen (
                    ma_thi_sinh,
                    ma_nv,
                    diem_xet_tuyen,
                    diem_chuan_id,
                    diem_chuan_ap_dung,
                    trang_thai,
                    xet_tuyen_thang,
                    ly_do,
                    updated_at
                )
                VALUES (
                    r.ma_thi_sinh,
                    r.ma_nv,
                    r.diem_xet_tuyen,
                    v_cutoff_id,
                    v_cutoff,
                    'thieu_du_lieu',
                    false,
                    CASE
                        WHEN r.diem_xet_tuyen IS NULL AND v_cutoff IS NULL
                            THEN 'Chưa có điểm xét tuyển và chưa tìm được điểm chuẩn áp dụng'
                        WHEN r.diem_xet_tuyen IS NULL
                            THEN 'Chưa có điểm xét tuyển'
                        ELSE 'Chưa tìm được điểm chuẩn áp dụng'
                    END,
                    now()
                )
                ON CONFLICT (ma_nv)
                DO UPDATE SET
                    diem_chuan_id = EXCLUDED.diem_chuan_id,
                    diem_chuan_ap_dung = EXCLUDED.diem_chuan_ap_dung,
                    trang_thai = EXCLUDED.trang_thai,
                    xet_tuyen_thang = EXCLUDED.xet_tuyen_thang,
                    ly_do = EXCLUDED.ly_do,
                    updated_at = now();

            ELSIF r.diem_xet_tuyen >= v_cutoff THEN
                v_admitted := true;
                v_admitted_nv := r.ma_nv;

                INSERT INTO public.ket_qua_xet_tuyen (
                    ma_thi_sinh,
                    ma_nv,
                    diem_xet_tuyen,
                    diem_chuan_id,
                    diem_chuan_ap_dung,
                    trang_thai,
                    xet_tuyen_thang,
                    ly_do,
                    updated_at
                )
                VALUES (
                    r.ma_thi_sinh,
                    r.ma_nv,
                    r.diem_xet_tuyen,
                    v_cutoff_id,
                    v_cutoff,
                    'trung_tuyen',
                    false,
                    'Điểm xét tuyển đạt hoặc vượt điểm chuẩn; đây là nguyện vọng ưu tiên cao nhất đủ điều kiện',
                    now()
                )
                ON CONFLICT (ma_nv)
                DO UPDATE SET
                    diem_chuan_id = EXCLUDED.diem_chuan_id,
                    diem_chuan_ap_dung = EXCLUDED.diem_chuan_ap_dung,
                    trang_thai = EXCLUDED.trang_thai,
                    xet_tuyen_thang = EXCLUDED.xet_tuyen_thang,
                    ly_do = EXCLUDED.ly_do,
                    updated_at = now();

            ELSE
                INSERT INTO public.ket_qua_xet_tuyen (
                    ma_thi_sinh,
                    ma_nv,
                    diem_xet_tuyen,
                    diem_chuan_id,
                    diem_chuan_ap_dung,
                    trang_thai,
                    xet_tuyen_thang,
                    ly_do,
                    updated_at
                )
                VALUES (
                    r.ma_thi_sinh,
                    r.ma_nv,
                    r.diem_xet_tuyen,
                    v_cutoff_id,
                    v_cutoff,
                    'khong_dat',
                    false,
                    'Điểm xét tuyển thấp hơn điểm chuẩn của nguyện vọng này',
                    now()
                )
                ON CONFLICT (ma_nv)
                DO UPDATE SET
                    diem_chuan_id = EXCLUDED.diem_chuan_id,
                    diem_chuan_ap_dung = EXCLUDED.diem_chuan_ap_dung,
                    trang_thai = EXCLUDED.trang_thai,
                    xet_tuyen_thang = EXCLUDED.xet_tuyen_thang,
                    ly_do = EXCLUDED.ly_do,
                    updated_at = now();
            END IF;
        END LOOP;

        -- -----------------------------------------------------
        -- Dossier summary
        -- -----------------------------------------------------
        UPDATE public.ho_so_xet_tuyen hs
        SET
            ket_qua_xet_tuyen = CASE
                WHEN v_admitted THEN 'trung_tuyen'
                WHEN v_has_missing THEN 'thieu_du_lieu'
                ELSE 'khong_trung_tuyen'
            END,
            ma_nv_trung_tuyen = v_admitted_nv,
            xet_tuyen_luc = now(),
            updated_at = now()
        WHERE hs.ma_thi_sinh = c.ma_thi_sinh
          AND hs.nam = p_nam;
    END LOOP;
END;
$$;


-- =========================================================
-- 4) PRIVATE BACKEND VIEW FOR UI/API
-- =========================================================
CREATE OR REPLACE VIEW public.v_ket_qua_nguyen_vong_2025 AS
SELECT
    kq.ma_kq,
    nv.ma_ho_so,
    nv.ma_thi_sinh,
    ts.ho_ten,
    nv.ma_nv,
    nv.thu_tu_nguyen_vong,

    t.ma_tuyen_sinh AS ma_truong,
    t.ten_truong,

    nv.ma_nganh,
    n.ma_nganh_tuyen_sinh,
    n.ten_nganh,

    nv.ma_phuong_thuc,
    pt.ten_phuong_thuc,
    nv.ma_to_hop,

    kq.diem_xet_tuyen,
    kq.diem_chuan_id,
    kq.diem_chuan_ap_dung,

    kq.trang_thai,
    kq.xet_tuyen_thang,
    kq.ly_do,
    kq.updated_at

FROM public.ket_qua_xet_tuyen kq
JOIN public.nguyen_vong nv
  ON nv.ma_nv = kq.ma_nv
JOIN public.thi_sinh ts
  ON ts.ma_thi_sinh = nv.ma_thi_sinh
JOIN public.nganh n
  ON n.ma_nganh = nv.ma_nganh
JOIN public.truong_dh t
  ON t.ma_truong = n.ma_truong
LEFT JOIN public.phuong_thuc_xet_tuyen pt
  ON pt.ma_phuong_thuc = nv.ma_phuong_thuc
WHERE nv.nam = 2025;

ALTER VIEW public.v_ket_qua_nguyen_vong_2025
SET (security_invoker = true);

REVOKE ALL ON public.v_ket_qua_nguyen_vong_2025
FROM anon, authenticated;


-- =========================================================
-- 5) RUN FOR CURRENT 2025 DATA
-- =========================================================
SELECT public.recalculate_admission_results(NULL, 2025);

COMMIT;


-- =========================================================
-- QA
-- =========================================================
SELECT
    trang_thai,
    COUNT(*) AS so_luong
FROM public.ket_qua_xet_tuyen
GROUP BY trang_thai
ORDER BY trang_thai;

SELECT
    ket_qua_xet_tuyen,
    COUNT(*) AS so_ho_so
FROM public.ho_so_xet_tuyen
WHERE nam = 2025
GROUP BY ket_qua_xet_tuyen
ORDER BY ket_qua_xet_tuyen;

-- Every candidate should have at most one admitted preference.
SELECT
    ma_thi_sinh,
    COUNT(*) AS so_nv_trung_tuyen
FROM public.ket_qua_xet_tuyen
WHERE trang_thai = 'trung_tuyen'
GROUP BY ma_thi_sinh
HAVING COUNT(*) > 1;

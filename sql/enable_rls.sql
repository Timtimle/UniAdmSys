-- UniAdmSys: ENABLE RLS SAFELY
-- Public catalog tables: anon/authenticated may SELECT only.
-- Private/operational tables: RLS enabled and no client policy => blocked from anon/authenticated.
-- Backend using Supabase service_role continues to work because service_role bypasses RLS.
-- Can be run repeatedly.

BEGIN;

GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- =========================================================
-- 1) PUBLIC READ-ONLY TABLES
-- =========================================================
DO $$
DECLARE
    tbl text;
    public_tables text[] := ARRAY[
        'truong_dh',
        'danh_muc_nganh',
        'nganh',
        'diem_chuan',
        'hoc_phi',
        'chi_tieu_tuyen_sinh',
        'phuong_thuc_xet_tuyen',
        'to_hop_xet_tuyen',
        'nganh_to_hop_xet_tuyen',
        'to_hop',
        'mon_to_hop',
        'mon_thi',
        'ky_thi',
        'chuong_trinh_dao_tao',
        'co_hoi_viec_lam'
    ];
BEGIN
    FOREACH tbl IN ARRAY public_tables LOOP
        IF to_regclass('public.' || tbl) IS NOT NULL THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);

            -- Explicitly remove direct write privileges from client roles.
            EXECUTE format(
                'REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE public.%I FROM anon, authenticated',
                tbl
            );

            -- Allow read access.
            EXECUTE format('GRANT SELECT ON TABLE public.%I TO anon, authenticated', tbl);

            EXECUTE format('DROP POLICY IF EXISTS public_read ON public.%I', tbl);
            EXECUTE format(
                'CREATE POLICY public_read ON public.%I FOR SELECT TO anon, authenticated USING (true)',
                tbl
            );
        END IF;
    END LOOP;
END $$;

-- =========================================================
-- 2) PRIVATE / OPERATIONAL TABLES
-- No anon/authenticated policies yet. This intentionally locks
-- them from direct browser/client access.
-- =========================================================
DO $$
DECLARE
    tbl text;
    private_tables text[] := ARRAY[
        'thi_sinh',
        'nguyen_vong',
        'ho_so_xet_tuyen',
        'ket_qua_xet_tuyen',
        'diem_thi',
        'ai_chat_history',
        'knowledge_base',
        'can_bo',
        'phan_cong_xet_tuyen',
        'nhat_ky_xet_tuyen',
        'vai_tro'
    ];
BEGIN
    FOREACH tbl IN ARRAY private_tables LOOP
        IF to_regclass('public.' || tbl) IS NOT NULL THEN
            EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
            EXECUTE format('REVOKE ALL ON TABLE public.%I FROM anon, authenticated', tbl);
        END IF;
    END LOOP;
END $$;

-- =========================================================
-- 3) PUBLIC VIEWS
-- security_invoker = true makes views respect underlying RLS.
-- =========================================================
DO $$
DECLARE
    vw text;
    public_views text[] := ARRAY[
        'v_catalog_tuyen_sinh_2025',
        'v_diem_chuan_2025',
        'v_nganh_2025',
        'v_nganh_to_hop_2025',
        'v_phuong_thuc_xet_tuyen_2025',
        'v_truong_tuyen_sinh_2025'
    ];
BEGIN
    FOREACH vw IN ARRAY public_views LOOP
        IF EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
              AND c.relname = vw
              AND c.relkind = 'v'
        ) THEN
            EXECUTE format('ALTER VIEW public.%I SET (security_invoker = true)', vw);
            EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', vw);
        END IF;
    END LOOP;
END $$;

COMMIT;

-- =========================================================
-- 4) QA: tables still showing RLS disabled should be 0
-- =========================================================
SELECT
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY c.relname;

-- Public policies created by this script
SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname = 'public_read'
ORDER BY tablename;

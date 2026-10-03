# SQL

PostgreSQL / Supabase scripts used by UniAdmSys for the 2025 admissions dataset.

## Recommended order

1. `setup_nganh_2025.sql`  
   Creates the 2025 major staging structure and prepares the `nganh` table.

2. `setup_diem_chuan_2025.sql`  
   Creates the 2025 cutoff-score staging table.

3. `import_all_2025.sql`  
   Imports and normalizes 2025 majors and cutoff scores.

4. `import_phuong_thuc_xet_tuyen_2025.sql`  
   Builds 2025 admission-method data from imported cutoff-score records.

5. `import_to_hop_xet_tuyen_2025.sql`  
   Extracts subject combinations and creates major–combination mappings.

6. `import_hoc_phi_2025.sql`  
   Imports 2025–2026 tuition data and marks verified/unverified coverage.

7. `import_chi_tieu_tuyen_sinh_2025.sql`  
   Imports 2025 admission quotas and keeps unknown values as unverified instead of guessing.

8. `finalize_database_2025.sql`  
   Adds indexes, reporting views, and database integrity checks.

9. `enable_rls.sql`  
   Enables Supabase Row Level Security. Public catalog data is read-only; private operational tables are blocked from direct client access.

## Utility scripts

| File | Purpose |
|---|---|
| `fix_hoc_phi_schema.sql` | One-time migration for older `hoc_phi` schemas. |
| `setup_nganh_2024.sql` | Optional 2024 major setup. Not required for the current project. |
| `import_history_2024.sql` | Optional historical 2024 import. Not required for the current project. |

## Main 2025 views

- `v_catalog_tuyen_sinh_2025` — combined admissions catalog for backend queries
- `v_truong_tuyen_sinh_2025` — university-level tuition and quota data
- `v_nganh_2025` — university majors/programs
- `v_diem_chuan_2025` — detailed cutoff scores
- `v_phuong_thuc_xet_tuyen_2025` — admission methods
- `v_nganh_to_hop_2025` — subject-combination mappings

> Unknown tuition or quota values are intentionally stored as unverified/NULL rather than fabricated.

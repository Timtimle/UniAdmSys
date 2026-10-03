from __future__ import annotations

from dataclasses import dataclass
from typing import Any
import re

from app.config import Settings
from app.supabase_client import SupabaseClient, SupabaseError


@dataclass
class ToolContext:
    authenticated: bool = False
    auth_user_id: str | None = None
    role: str = "anonymous"
    candidate_id: int | None = None
    staff_id: int | None = None


class ToolExecutor:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.db = SupabaseClient(settings)

    async def build_context(
        self,
        *,
        access_token: str | None,
        demo_candidate_id: int | None,
    ) -> ToolContext:
        ctx = ToolContext()

        if access_token:
            user = await self.db.auth_user(access_token)
            auth_user_id = user.get("id")
            if auth_user_id:
                ctx.authenticated = True
                ctx.auth_user_id = str(auth_user_id)

                candidates = await self.db.select(
                    "thi_sinh",
                    select="ma_thi_sinh,user_id,ho_ten,email",
                    filters={"user_id": f"eq.{auth_user_id}"},
                    limit=1,
                    privileged=True,
                )
                if candidates:
                    ctx.candidate_id = int(candidates[0]["ma_thi_sinh"])
                    ctx.role = "applicant"

                staff = await self.db.select(
                    "can_bo",
                    select="ma_can_bo,user_id,ho_ten,vai_tro,trang_thai",
                    filters={
                        "user_id": f"eq.{auth_user_id}",
                        "trang_thai": "eq.hoat_dong",
                    },
                    limit=1,
                    privileged=True,
                )
                if staff:
                    ctx.staff_id = int(staff[0]["ma_can_bo"])
                    ctx.role = "admin"

        elif (
            demo_candidate_id
            and self.settings.allow_demo_candidate_id
            and self.settings.app_env.lower() != "production"
        ):
            rows = await self.db.select(
                "thi_sinh",
                select="ma_thi_sinh,ho_ten,email",
                filters={"ma_thi_sinh": f"eq.{demo_candidate_id}"},
                limit=1,
                privileged=True,
            )
            if rows:
                ctx.candidate_id = demo_candidate_id
                ctx.role = "applicant_demo"

        return ctx

    async def execute(
        self,
        name: str,
        args: dict[str, Any],
        ctx: ToolContext,
    ) -> dict[str, Any]:
        try:
            if name == "search_schools":
                return await self._search_schools(args["query"], args["limit"])
            if name == "get_school_overview":
                return await self._get_school_overview(args["school_code"])
            if name == "search_majors":
                return await self._search_majors(
                    args["query"], args["school_code"], args["limit"]
                )
            if name == "get_major_details":
                return await self._get_major_details(args["major_id"])
            if name == "search_cutoff_scores":
                return await self._search_cutoff_scores(
                    args["query"],
                    args["score_type"],
                    args["school_code"],
                    args["exam_code"],
                    args["limit"],
                )
            if name == "get_cutoff_scores":
                return await self._get_cutoff_scores(args["major_id"])
            if name == "get_application_status":
                return await self._get_application_status(ctx)
            if name == "get_preference_results":
                return await self._get_preference_results(ctx)
            if name == "get_transcript_admission":
                return await self._get_transcript_admission(ctx)
            if name == "get_direct_admission_eligibility":
                return await self._get_direct_admission(ctx)
            if name == "get_certificate_conversions":
                return await self._get_certificate_conversions(ctx)
            if name == "search_knowledge_base":
                return await self._search_knowledge_base(args["query"], args["limit"])
            if name == "calculate_admission_score":
                return self._calculate_admission_score(**args)

            return {"ok": False, "error": f"Unknown tool: {name}"}
        except Exception as exc:
            return {
                "ok": False,
                "error": type(exc).__name__,
                "message": str(exc),
            }

    @staticmethod
    def _clean_search(value: str) -> str:
        value = value.strip()
        value = re.sub(r"[(),]", " ", value)
        value = re.sub(r"\s+", " ", value)
        return value[:120]

    @staticmethod
    def _upper(value: str) -> str:
        return value.strip().upper()

    def _personal_candidate_id(self, ctx: ToolContext) -> int:
        if not ctx.candidate_id:
            raise PermissionError(
                "Personal admissions data requires a signed-in applicant. "
                "For local demo only, candidate_id may be supplied when enabled."
            )
        if not self.settings.supabase_privileged:
            raise PermissionError(
                "Private-data tools require SUPABASE_SECRET_KEY on the agent server."
            )
        return ctx.candidate_id

    async def _search_schools(self, query: str, limit: int) -> dict:
        q = self._clean_search(query)
        rows = await self.db.select(
            "truong_dh",
            select=(
                "ma_truong,ma_tuyen_sinh,ten_truong,dia_chi,website,"
                "tinh_thanh,loai_truong,nam_thanh_lap,mo_ta"
            ),
            or_filter=(
                f"(ten_truong.ilike.*{q}*,"
                f"ma_tuyen_sinh.ilike.*{q}*,"
                f"tinh_thanh.ilike.*{q}*)"
            ),
            order="ten_truong.asc",
            limit=limit,
        )
        return {"ok": True, "source": "supabase", "data": rows}

    async def _get_school_overview(self, school_code: str) -> dict:
        code = self._upper(school_code)
        overview = await self.db.select(
            "v_truong_tuyen_sinh_2025",
            filters={"ma_tuyen_sinh": f"eq.{code}"},
            limit=1,
        )
        methods = await self.db.select(
            "phuong_thuc_xet_tuyen",
            select=(
                "ma_phuong_thuc,ma_truong,nam,ten_phuong_thuc,"
                "loai_phuong_thuc,source_url"
            ),
            filters={"ma_truong": f"eq.{code}", "nam": "eq.2025"},
            order="ten_phuong_thuc.asc",
            limit=50,
        )
        return {
            "ok": bool(overview),
            "source": "supabase",
            "data": {
                "overview": overview[0] if overview else None,
                "methods": methods,
            },
        }

    async def _search_majors(
        self,
        query: str,
        school_code: str | None,
        limit: int,
    ) -> dict:
        q = self._clean_search(query)
        filters = {"nam": f"eq.{self.settings.default_admission_year}"}
        if school_code:
            filters["ma_truong"] = f"eq.{self._upper(school_code)}"

        rows = await self.db.select(
            "v_nganh_2025",
            select=(
                "ma_nganh,ma_truong,ten_truong,ma_nganh_tuyen_sinh,"
                "ten_nganh,ma_nganh_bo,ten_nganh_bo,nam"
            ),
            filters=filters,
            or_filter=(
                f"(ten_nganh.ilike.*{q}*,"
                f"ma_nganh_tuyen_sinh.ilike.*{q}*,"
                f"ten_truong.ilike.*{q}*)"
            ),
            order="ten_truong.asc,ten_nganh.asc",
            limit=limit,
        )
        return {"ok": True, "source": "supabase", "data": rows}

    async def _get_major_details(self, major_id: str) -> dict:
        major_id = major_id.strip()

        catalog = await self.db.select(
            "v_catalog_tuyen_sinh_2025",
            filters={"ma_nganh": f"eq.{major_id}"},
            limit=1,
        )
        if not catalog:
            return {
                "ok": False,
                "source": "supabase",
                "error": "Major not found by internal ma_nganh.",
            }

        major = catalog[0]
        cutoffs = await self._get_cutoff_scores(major_id)

        combinations = await self.db.select(
            "nganh_to_hop_xet_tuyen",
            select="ma_nganh,ma_to_hop,phuong_thuc,nam,source_url",
            filters={
                "ma_nganh": f"eq.{major_id}",
                "nam": f"eq.{self.settings.default_admission_year}",
            },
            order="ma_to_hop.asc",
            limit=100,
        )

        methods = await self.db.select(
            "phuong_thuc_xet_tuyen",
            select=(
                "ma_phuong_thuc,ma_truong,nam,ten_phuong_thuc,"
                "loai_phuong_thuc,source_url"
            ),
            filters={
                "ma_truong": f"eq.{major.get('ma_truong')}",
                "nam": f"eq.{self.settings.default_admission_year}",
            },
            order="ten_phuong_thuc.asc",
            limit=100,
        )

        floors = await self.db.select(
            "nguong_dau_vao",
            filters={
                "ma_truong": f"eq.{major.get('ma_truong')}",
                "nam": f"eq.{self.settings.default_admission_year}",
            },
            limit=100,
        )

        return {
            "ok": True,
            "source": "supabase",
            "data": {
                "major": major,
                "cutoff_scores": cutoffs.get("data", []),
                "subject_combinations": combinations,
                "methods": methods,
                "floor_scores": floors,
            },
        }

    async def _search_cutoff_scores(
        self,
        query: str,
        score_type: str,
        school_code: str | None,
        exam_code: str | None,
        limit: int,
    ) -> dict:
        q = self._clean_search(query)

        filters: dict[str, str] = {}

        if score_type != "all":
            filters["loai_diem"] = f"eq.{score_type}"

        if school_code:
            filters["ma_truong"] = f"eq.{self._upper(school_code)}"

        if exam_code:
            filters["ma_ky_thi"] = f"eq.{self._upper(exam_code)}"

        rows = await self.db.select(
            "v_diem_chuan_2025",
            select=(
                "id,ma_truong,ten_truong,ma_nganh,"
                "ma_nganh_tuyen_sinh,ten_nganh,phuong_thuc,to_hop,"
                "diem,loai_diem,ma_ky_thi,thang_diem,"
                "ghi_chu,source_url,created_at"
            ),
            filters=filters,
            or_filter=(
                f"(ten_nganh.ilike.*{q}*,"
                f"ma_nganh_tuyen_sinh.ilike.*{q}*,"
                f"ten_truong.ilike.*{q}*,"
                f"phuong_thuc.ilike.*{q}*)"
            ),
            order="ten_truong.asc,ten_nganh.asc,diem.asc",
            limit=limit,
        )

        verified = [
            row for row in rows
            if not str(row.get("source_url") or "").startswith("demo://")
        ]
        demo = [
            row for row in rows
            if str(row.get("source_url") or "").startswith("demo://")
        ]

        return {
            "ok": True,
            "source": "supabase",
            "score_type": score_type,
            "data": rows,
            "verified_rows": verified,
            "demo_rows": demo,
            "note": (
                "Rows whose source_url starts with demo:// are synthetic/demo "
                "and must not be presented as official verified cutoff scores."
            ),
        }

    async def _get_cutoff_scores(self, major_id: str) -> dict:
        rows = await self.db.select(
            "diem_chuan",
            select=(
                "id,ma_truong,ma_nganh,nam,phuong_thuc,to_hop,"
                "diem,loai_diem,ma_ky_thi,thang_diem,"
                "ghi_chu,source_url"
            ),
            filters={
                "ma_nganh": f"eq.{major_id.strip()}",
                "nam": f"eq.{self.settings.default_admission_year}",
            },
            order="diem.asc",
            limit=100,
        )
        return {"ok": True, "source": "supabase", "data": rows}

    async def _get_application_status(self, ctx: ToolContext) -> dict:
        candidate_id = self._personal_candidate_id(ctx)

        candidate = await self.db.select(
            "thi_sinh",
            select=(
                "ma_thi_sinh,ho_ten,ngay_sinh,gioi_tinh,tinh_thanh,"
                "so_dien_thoai,email"
            ),
            filters={"ma_thi_sinh": f"eq.{candidate_id}"},
            limit=1,
            privileged=True,
        )
        dossiers = await self.db.select(
            "ho_so_xet_tuyen",
            filters={
                "ma_thi_sinh": f"eq.{candidate_id}",
                "nam": f"eq.{self.settings.default_admission_year}",
            },
            order="created_at.desc",
            limit=10,
            privileged=True,
        )

        return {
            "ok": True,
            "source": "supabase_private",
            "data": {
                "candidate": candidate[0] if candidate else None,
                "dossiers": dossiers,
            },
        }

    async def _get_preference_results(self, ctx: ToolContext) -> dict:
        candidate_id = self._personal_candidate_id(ctx)

        rows = await self.db.select(
            "v_ket_qua_nguyen_vong_2025",
            filters={"ma_thi_sinh": f"eq.{candidate_id}"},
            order="thu_tu_nguyen_vong.asc",
            limit=100,
            privileged=True,
        )
        return {
            "ok": True,
            "source": "supabase_private",
            "data": rows,
        }

    async def _get_transcript_admission(self, ctx: ToolContext) -> dict:
        candidate_id = self._personal_candidate_id(ctx)
        rows = await self.db.select(
            "v_diem_xet_hoc_ba_2025",
            filters={"ma_thi_sinh": f"eq.{candidate_id}"},
            order="thu_tu_nguyen_vong.asc",
            limit=100,
            privileged=True,
        )
        return {
            "ok": True,
            "source": "supabase_private",
            "data": rows,
        }

    async def _get_direct_admission(self, ctx: ToolContext) -> dict:
        candidate_id = self._personal_candidate_id(ctx)
        rows = await self.db.select(
            "v_xet_tuyen_thang_kha_dung",
            filters={"ma_thi_sinh": f"eq.{candidate_id}"},
            limit=100,
            privileged=True,
        )
        return {
            "ok": True,
            "source": "supabase_private",
            "data": rows,
        }

    async def _get_certificate_conversions(self, ctx: ToolContext) -> dict:
        candidate_id = self._personal_candidate_id(ctx)
        rows = await self.db.select(
            "v_chung_chi_quy_doi",
            filters={"ma_thi_sinh": f"eq.{candidate_id}"},
            limit=100,
            privileged=True,
        )
        return {
            "ok": True,
            "source": "supabase_private",
            "data": rows,
        }

    async def _search_knowledge_base(self, query: str, limit: int) -> dict:
        q = self._clean_search(query)
        rows = await self.db.select(
            "knowledge_base",
            select="id,title,content,category,source,metadata,created_at",
            or_filter=(
                f"(title.ilike.*{q}*,"
                f"content.ilike.*{q}*,"
                f"category.ilike.*{q}*)"
            ),
            order="created_at.desc",
            limit=limit,
            privileged=True,
        )
        return {"ok": True, "source": "knowledge_base", "data": rows}

    @staticmethod
    def _calculate_admission_score(
        scores: list[float],
        region: str,
        priority_group: str,
        bonus_score: float,
        floor_score: float | None,
    ) -> dict:
        if len(scores) != 3:
            raise ValueError("Exactly three subject scores are required.")

        region_points = {
            "KV1": 0.75,
            "KV2-NT": 0.50,
            "KV2": 0.25,
            "KV3": 0.00,
        }
        group_points = {
            "UT1": 2.00,
            "UT2": 1.00,
            "NONE": 0.00,
        }

        if region not in region_points:
            raise ValueError("Invalid region.")
        if priority_group not in group_points:
            raise ValueError("Invalid priority group.")
        if not (0 <= bonus_score <= 3):
            raise ValueError("bonus_score must be between 0 and 3.")

        total_subjects = round(sum(float(x) for x in scores), 2)
        raw_priority = region_points[region] + group_points[priority_group]
        priority_basis = min(30.0, max(0.0, total_subjects + bonus_score))

        if priority_basis < 22.5:
            priority_score = raw_priority
        else:
            priority_score = ((30 - priority_basis) / 7.5) * raw_priority

        priority_score = round(max(0.0, priority_score), 2)
        admission_score = round(total_subjects + bonus_score + priority_score, 2)

        return {
            "ok": True,
            "source": "calculator",
            "data": {
                "subject_total": total_subjects,
                "bonus_score": round(bonus_score, 2),
                "region": region,
                "priority_group": priority_group,
                "raw_priority": round(raw_priority, 2),
                "priority_basis": round(priority_basis, 2),
                "priority_score": priority_score,
                "admission_score": admission_score,
                "floor_score": floor_score,
                "meets_floor": (
                    None if floor_score is None else admission_score >= floor_score
                ),
                "official_admission_decision": False,
            },
        }

    async def log_chat(
        self,
        ctx: ToolContext,
        question: str,
        answer: str,
        tools_used: list[str],
    ) -> None:
        # Current project schema uses numeric user_id in ai_chat_history.
        # Only log when a numeric candidate id is available.
        if not ctx.candidate_id or not self.settings.supabase_privileged:
            return

        try:
            await self.db.insert(
                "ai_chat_history",
                {
                    "user_id": ctx.candidate_id,
                    "question": question,
                    "answer": answer,
                    "source_documents": tools_used,
                },
                privileged=True,
            )
        except Exception:
            # Logging must never break the chat response.
            pass

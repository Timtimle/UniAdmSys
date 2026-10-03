from __future__ import annotations

import asyncio
import os
import re
from collections import defaultdict
from decimal import Decimal
from typing import Any
from urllib.parse import quote

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.getenv("SUPABASE_SECRET_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
SUPABASE_TIMEOUT = float(os.getenv("SUPABASE_TIMEOUT_SECONDS", "30"))
ADMIN_TOKEN = os.getenv("BACKEND_ADMIN_TOKEN", "change-me-local-only")


class SupabaseError(RuntimeError):
    pass


class DB:
    def headers(self, prefer: str | None = None) -> dict[str, str]:
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise SupabaseError("Thiếu SUPABASE_URL hoặc SUPABASE_SECRET_KEY trong backend/.env")
        h = {"apikey": SUPABASE_KEY, "Accept": "application/json", "Content-Type": "application/json"}
        if SUPABASE_KEY.startswith("eyJ"):
            h["Authorization"] = f"Bearer {SUPABASE_KEY}"
        if prefer:
            h["Prefer"] = prefer
        return h

    async def request(self, method: str, path: str, *, params=None, json=None, prefer=None):
        timeout = httpx.Timeout(SUPABASE_TIMEOUT, connect=SUPABASE_TIMEOUT, read=SUPABASE_TIMEOUT, write=SUPABASE_TIMEOUT, pool=SUPABASE_TIMEOUT)
        last = None
        for attempt in range(3):
            try:
                async with httpx.AsyncClient(timeout=timeout) as client:
                    r = await client.request(method, f"{SUPABASE_URL}{path}", params=params, json=json, headers=self.headers(prefer))
                if r.status_code >= 400:
                    raise SupabaseError(f"Supabase {r.status_code}: {r.text[:1800]}")
                return r.json() if r.content else None
            except (httpx.ConnectTimeout, httpx.ReadTimeout, httpx.ConnectError) as exc:
                last = exc
                if attempt < 2:
                    await asyncio.sleep(.7 * (attempt + 1))
        raise SupabaseError(f"Supabase network error: {type(last).__name__}") from last

    async def select(self, relation: str, *, select="*", filters=None, or_filter=None, order=None, limit=None):
        params: dict[str, Any] = {"select": select}
        if filters: params.update(filters)
        if or_filter: params["or"] = or_filter
        if order: params["order"] = order
        if limit is not None: params["limit"] = str(limit)
        return (await self.request("GET", f"/rest/v1/{quote(relation, safe='')}", params=params)) or []

    async def upsert(self, relation: str, rows: list[dict[str, Any]], *, on_conflict: str):
        if not rows: return []
        return await self.request("POST", f"/rest/v1/{quote(relation, safe='')}", params={"on_conflict": on_conflict}, json=rows, prefer="resolution=merge-duplicates,return=representation")


db = DB()
app = FastAPI(title="UniAdmSys Backend", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def clean(q: str) -> str:
    q = re.sub(r"[(),]", " ", (q or "").strip())
    return re.sub(r"\s+", " ", q)[:120]


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/api/catalog/search")
async def catalog_search(
    query: str = "",
    school_code: str | None = None,
    score_type: str = Query("all", pattern="^(all|thi_thpt|dgnl)$"),
    include_demo: bool = True,
    limit: int = Query(30, ge=1, le=100),
):
    q = clean(query)
    filters = {"nam": "eq.2025"}
    if school_code:
        filters["ma_truong"] = f"eq.{school_code.strip().upper()}"
    or_filter = None
    if q:
        or_filter = f"(ten_nganh.ilike.*{q}*,ten_truong.ilike.*{q}*,ma_nganh_tuyen_sinh.ilike.*{q}*)"
    majors = await db.select(
        "v_nganh_2025",
        select="ma_nganh,ma_truong,ten_truong,ma_nganh_tuyen_sinh,ten_nganh,nam",
        filters=filters, or_filter=or_filter, order="ten_truong.asc,ten_nganh.asc", limit=limit,
    )
    if not majors:
        return {"items": [], "count": 0}
    ids = ",".join(str(x["ma_nganh"]) for x in majors)
    cf = {"ma_nganh": f"in.({ids})"}
    if score_type != "all": cf["loai_diem"] = f"eq.{score_type}"
    cutoffs = await db.select(
        "v_diem_chuan_2025",
        select="id,ma_truong,ten_truong,ma_nganh,ma_nganh_tuyen_sinh,ten_nganh,phuong_thuc,to_hop,diem,loai_diem,ma_ky_thi,thang_diem,ghi_chu,source_url",
        filters=cf, order="ma_truong.asc,ma_nganh.asc,diem.asc", limit=max(100, limit * 10),
    )
    floors = await db.select(
        "v_nguong_dau_vao_2025",
        select="id,ma_truong,ten_truong,ma_nganh,ma_nganh_tuyen_sinh,nganh_hoc,ma_to_hop,ten_to_hop,diem_san,ma_phuong_thuc,ten_phuong_thuc,trang_thai,source_url",
        filters={"ma_nganh": f"in.({ids})"}, order="ma_truong.asc,ma_nganh.asc,diem_san.asc", limit=max(100, limit * 10),
    )
    cb, fb = defaultdict(list), defaultdict(list)
    for row in cutoffs:
        row["is_demo"] = str(row.get("source_url") or "").startswith("demo://")
        if include_demo or not row["is_demo"]: cb[str(row.get("ma_nganh"))].append(row)
    for row in floors:
        row["is_demo"] = str(row.get("source_url") or "").startswith("demo://")
        if include_demo or not row["is_demo"]: fb[str(row.get("ma_nganh"))].append(row)
    items = [{**m, "cutoffs": cb.get(str(m["ma_nganh"]), []), "floor_scores": fb.get(str(m["ma_nganh"]), [])} for m in majors]
    return {"items": items, "count": len(items), "score_type": score_type, "include_demo": include_demo}


@app.get("/api/catalog/majors/{major_id}/methods")
async def major_methods(major_id: str):
    majors = await db.select("v_nganh_2025", select="ma_nganh,ma_truong", filters={"ma_nganh": f"eq.{major_id}"}, limit=1)
    if not majors: return {"items": []}
    rows = await db.select(
        "phuong_thuc_xet_tuyen",
        select="ma_phuong_thuc,ma_truong,nam,ten_phuong_thuc,loai_phuong_thuc,ma_ky_thi,source_url",
        filters={"ma_truong": f"eq.{majors[0]['ma_truong']}", "nam": "eq.2025"}, order="ten_phuong_thuc.asc", limit=100,
    )
    return {"items": rows}


@app.get("/api/catalog/floor-scores")
async def floor_scores(include_demo: bool = True, limit: int = Query(200, ge=1, le=1000)):
    rows = await db.select("v_nguong_dau_vao_2025", limit=limit, order="stt.asc")
    if not include_demo:
        rows = [r for r in rows if not str(r.get("source_url") or "").startswith("demo://")]
    return {"items": rows, "count": len(rows)}


class QuotaRequest(BaseModel):
    major_id: str = Field(min_length=1)
    method_code: str = Field(min_length=1)
    year: int = 2025
    quota_override: int | None = Field(None, ge=1)
    commit: bool = False


def effective_quota(row: dict[str, Any]) -> int | None:
    for key in ("chi_tieu", "chi_tieu_max", "chi_tieu_min"):
        if row.get(key) is not None:
            try:
                v = int(row[key])
                if v > 0: return v
            except (TypeError, ValueError): pass
    return None


@app.post("/api/admissions/quota-rank")
async def quota_rank(payload: QuotaRequest, x_admin_token: str | None = Header(None)):
    if not x_admin_token or x_admin_token != ADMIN_TOKEN:
        raise HTTPException(401, "Invalid X-Admin-Token")
    quota = payload.quota_override
    quota_source = "manual_override" if quota else None
    warnings: list[str] = []
    if quota is None:
        rows = await db.select(
            "chi_tieu_tuyen_sinh",
            select="id,ma_truong,ma_nganh,nam,cap_do,chi_tieu,chi_tieu_min,chi_tieu_max,trang_thai,source_type,source_url",
            filters={"ma_nganh": f"eq.{payload.major_id}", "nam": f"eq.{payload.year}", "cap_do": "eq.nganh"}, limit=20,
        )
        for row in rows:
            quota = effective_quota(row)
            if quota:
                quota_source = "major_quota"
                if str(row.get("source_url") or "").startswith("demo://"):
                    warnings.append("Chỉ tiêu đang dùng là DEMO/synthetic.")
                break
    if not quota:
        raise HTTPException(422, "Ngành chưa có chỉ tiêu cấp ngành. Nhập Chỉ tiêu override để chạy demo.")

    major_rows = await db.select("v_nganh_2025", filters={"ma_nganh": f"eq.{payload.major_id}"}, limit=1)
    method_rows = await db.select("phuong_thuc_xet_tuyen", filters={"ma_phuong_thuc": f"eq.{payload.method_code}"}, limit=1)
    if not major_rows or not method_rows:
        raise HTTPException(422, "Không tìm thấy ngành/phương thức")
    prefs = await db.select(
        "nguyen_vong",
        select="ma_nv,ma_ho_so,ma_thi_sinh,ma_nganh,nam,ma_phuong_thuc,ma_to_hop,thu_tu_nguyen_vong",
        filters={"ma_nganh": f"eq.{payload.major_id}", "ma_phuong_thuc": f"eq.{payload.method_code}", "nam": f"eq.{payload.year}"},
        order="ma_thi_sinh.asc,thu_tu_nguyen_vong.asc", limit=50000,
    )
    if not prefs:
        return {"major": major_rows[0], "method": method_rows[0], "quota": quota, "quota_source": quota_source, "cutoff_score": None, "total_candidates": 0, "within_quota": 0, "outside_quota": 0, "missing_score": 0, "committed": False, "warnings": warnings, "ranking": []}
    nv_ids = ",".join(str(x["ma_nv"]) for x in prefs)
    cand_ids = ",".join(sorted({str(x["ma_thi_sinh"]) for x in prefs}))
    results = await db.select("ket_qua_xet_tuyen", filters={"ma_nv": f"in.({nv_ids})"}, limit=50000)
    candidates = await db.select("thi_sinh", select="ma_thi_sinh,ho_ten,email,tinh_thanh", filters={"ma_thi_sinh": f"in.({cand_ids})"}, limit=50000)
    rb = {str(r["ma_nv"]): r for r in results}
    cb = {str(c["ma_thi_sinh"]): c for c in candidates}
    ranking = []
    for pref in prefs:
        r = rb.get(str(pref["ma_nv"]), {})
        raw = r.get("diem_xet_tuyen")
        score = Decimal(str(raw)) if raw is not None else None
        c = cb.get(str(pref["ma_thi_sinh"]), {})
        ranking.append({"ma_nv": pref["ma_nv"], "ma_thi_sinh": pref["ma_thi_sinh"], "ho_ten": c.get("ho_ten"), "email": c.get("email"), "thu_tu_nguyen_vong": pref.get("thu_tu_nguyen_vong"), "ma_to_hop": pref.get("ma_to_hop"), "diem_xet_tuyen": float(score) if score is not None else None, "nguon_diem": r.get("nguon_diem"), "trang_thai_hien_tai": r.get("trang_thai")})
    scored = [x for x in ranking if x["diem_xet_tuyen"] is not None]
    missing = [x for x in ranking if x["diem_xet_tuyen"] is None]
    scored.sort(key=lambda x: (-x["diem_xet_tuyen"], x.get("thu_tu_nguyen_vong") or 999999, x["ma_thi_sinh"]))
    cutoff = scored[quota - 1]["diem_xet_tuyen"] if len(scored) >= quota else (scored[-1]["diem_xet_tuyen"] if scored else None)
    for i, row in enumerate(scored, 1):
        row.update({"xep_hang": i, "chi_tieu_ap_dung": quota, "diem_cat_chi_tieu": cutoff, "dat_chi_tieu": i <= quota, "trang_thai_chi_tieu": "dat_chi_tieu" if i <= quota else "ngoai_chi_tieu"})
    for row in missing:
        row.update({"xep_hang": None, "chi_tieu_ap_dung": quota, "diem_cat_chi_tieu": cutoff, "dat_chi_tieu": None, "trang_thai_chi_tieu": "thieu_diem"})
    final = scored + missing
    if payload.commit:
        await db.upsert("ket_qua_xet_tuyen", [{"ma_nv": x["ma_nv"], "ma_thi_sinh": x["ma_thi_sinh"], "xep_hang_chi_tieu": x["xep_hang"], "chi_tieu_ap_dung": quota, "diem_cat_chi_tieu": cutoff, "dat_chi_tieu": x["dat_chi_tieu"]} for x in final], on_conflict="ma_nv")
    warnings.append("Xếp hạng theo 1 ngành + 1 phương thức; trúng tuyển cuối cùng vẫn theo thứ tự nguyện vọng.")
    if method_rows[0].get("loai_phuong_thuc") == "dgnl": warnings.append("ĐGNL/HSA/TSA được xếp riêng, không trộn điểm khác thang.")
    return {"major": major_rows[0], "method": method_rows[0], "quota": quota, "quota_source": quota_source, "cutoff_score": cutoff, "total_candidates": len(final), "within_quota": sum(x["dat_chi_tieu"] is True for x in final), "outside_quota": sum(x["dat_chi_tieu"] is False for x in final), "missing_score": len(missing), "committed": payload.commit, "warnings": warnings, "ranking": final}

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.backend_client import BackendClient
from app.config import Settings
from app.rag import LocalDocumentRetriever
from app.tools.mock_data import ADMISSION_RULES, APPLICATIONS, MAJORS


@dataclass
class ToolContext:
    user_id: int
    role: str


class ToolExecutor:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.backend = BackendClient(settings)
        self.retriever = LocalDocumentRetriever()

    @staticmethod
    def _normalize(value: str) -> str:
        return value.strip().lower()

    async def execute(self, name: str, args: dict[str, Any], ctx: ToolContext) -> dict:
        try:
            if name == "search_majors":
                return await self._search_majors(args["query"])
            if name == "get_major_details":
                return await self._get_major_details(args["major_code"])
            if name == "get_application_status":
                return await self._get_application_status(ctx.user_id)
            if name == "get_admission_rules":
                return await self._get_admission_rules(args["query"])
            if name == "check_eligibility":
                return await self._check_eligibility(ctx.user_id, args["major_code"])
            if name == "search_admission_docs":
                return self._search_admission_docs(args["query"])
            return {"ok": False, "error": f"Unknown tool: {name}"}
        except Exception as exc:
            return {
                "ok": False,
                "error": type(exc).__name__,
                "message": str(exc),
            }

    async def _search_majors(self, query: str) -> dict:
        if not self.settings.use_mock_backend:
            data = await self.backend.search_majors(query)
            return {"ok": True, "source": "backend", "data": data}

        q = self._normalize(query)
        matches = [
            m for m in MAJORS
            if q in self._normalize(m["code"])
            or q in self._normalize(m["name"])
            or q in self._normalize(m["faculty"])
            or q in self._normalize(m["description"])
        ]
        return {"ok": True, "source": "mock", "data": matches}

    async def _get_major_details(self, major_code: str) -> dict:
        if not self.settings.use_mock_backend:
            data = await self.backend.get_major_details(major_code)
            return {"ok": True, "source": "backend", "data": data}

        code = major_code.strip().upper()
        major = next((m for m in MAJORS if m["code"] == code), None)
        if not major:
            return {"ok": False, "source": "mock", "error": "Major not found"}
        return {"ok": True, "source": "mock", "data": major}

    async def _get_application_status(self, user_id: int) -> dict:
        if not self.settings.use_mock_backend:
            data = await self.backend.get_application_status(user_id)
            return {"ok": True, "source": "backend", "data": data}

        app = APPLICATIONS.get(user_id)
        if not app:
            return {
                "ok": False,
                "source": "mock",
                "error": "No mock application exists for this user_id",
                "hint": "Try user_id 1 or 2 while testing.",
            }
        return {"ok": True, "source": "mock", "data": app}

    async def _get_admission_rules(self, query: str) -> dict:
        if not self.settings.use_mock_backend:
            data = await self.backend.get_admission_rules(query)
            return {"ok": True, "source": "backend", "data": data}

        q = self._normalize(query)
        words = {w for w in q.split() if len(w) > 2}
        matches = []
        for rule in ADMISSION_RULES:
            text = self._normalize(rule["title"] + " " + rule["text"])
            if not words or any(word in text for word in words):
                matches.append(rule)
        return {"ok": True, "source": "mock", "data": matches[:5]}

    async def _check_eligibility(self, user_id: int, major_code: str) -> dict:
        if not self.settings.use_mock_backend:
            data = await self.backend.check_eligibility(user_id, major_code)
            return {"ok": True, "source": "backend", "data": data}

        app = APPLICATIONS.get(user_id)
        code = major_code.strip().upper()
        major = next((m for m in MAJORS if m["code"] == code), None)

        if not app:
            return {"ok": False, "source": "mock", "error": "Mock application not found"}
        if not major:
            return {"ok": False, "source": "mock", "error": "Major not found"}

        score_ok = app["score"] >= major["minimum_score"]
        documents_ok = len(app["missing_documents"]) == 0

        return {
            "ok": True,
            "source": "mock",
            "data": {
                "user_id": user_id,
                "major_code": code,
                "score": app["score"],
                "minimum_score": major["minimum_score"],
                "score_requirement_met": score_ok,
                "documents_complete": documents_ok,
                "meets_configured_minimums": score_ok and documents_ok,
                "official_admission_decision": False,
            },
        }

    def _search_admission_docs(self, query: str) -> dict:
        results = self.retriever.search(query, top_k=3)
        return {
            "ok": True,
            "source": "local_docs",
            "data": results,
        }

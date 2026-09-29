from typing import Any
import httpx

from app.config import Settings


class BackendClient:
    """
    Contract expected from the UniAdmSys backend.

    Adjust only this class when the real backend routes differ.
    The Agent and tool schemas can stay unchanged.
    """

    def __init__(self, settings: Settings):
        self.settings = settings

    def _headers(self) -> dict[str, str]:
        headers = {"Accept": "application/json"}
        if self.settings.backend_service_token:
            headers["Authorization"] = f"Bearer {self.settings.backend_service_token}"
        return headers

    async def _request(self, method: str, path: str, **kwargs) -> Any:
        url = f"{self.settings.backend_base_url.rstrip('/')}{path}"
        async with httpx.AsyncClient(
            timeout=self.settings.backend_timeout_seconds,
            headers=self._headers(),
        ) as client:
            response = await client.request(method, url, **kwargs)
            response.raise_for_status()
            return response.json()

    async def search_majors(self, query: str):
        return await self._request("GET", "/api/majors", params={"query": query})

    async def get_major_details(self, major_code: str):
        return await self._request("GET", f"/api/majors/{major_code}")

    async def get_application_status(self, user_id: int):
        return await self._request("GET", f"/api/applications/user/{user_id}")

    async def get_admission_rules(self, query: str):
        return await self._request("GET", "/api/admission-rules", params={"query": query})

    async def check_eligibility(self, user_id: int, major_code: str):
        return await self._request(
            "POST",
            "/api/eligibility/check",
            json={"userId": user_id, "majorCode": major_code},
        )

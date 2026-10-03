from __future__ import annotations

from typing import Any
from urllib.parse import quote
import asyncio
import httpx

from app.config import Settings


class SupabaseError(RuntimeError):
    pass


class SupabaseClient:
    """
    Small async client for Supabase Data REST API + Auth API.

    This intentionally avoids a heavy SDK. The server sends the project's API key
    through the `apikey` header. If the configured key is the legacy JWT
    service_role key, Authorization: Bearer is also sent for compatibility.
    """

    def __init__(self, settings: Settings):
        self.settings = settings
        self.base_url = settings.supabase_url.rstrip("/")
        self.timeout = settings.supabase_timeout_seconds

    def _key(self, *, privileged: bool = False) -> str:
        if privileged:
            key = self.settings.privileged_supabase_key
            if not key:
                raise SupabaseError(
                    "Private Supabase access requires SUPABASE_SECRET_KEY "
                    "(or legacy SUPABASE_SERVICE_ROLE_KEY)."
                )
            return key

        key = self.settings.any_supabase_key
        if not key:
            raise SupabaseError("Supabase API key is not configured.")
        return key

    def _headers(self, *, privileged: bool = False) -> dict[str, str]:
        key = self._key(privileged=privileged)
        headers = {
            "apikey": key,
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

        # Legacy anon/service_role keys are JWTs and typically begin with eyJ.
        # New sb_publishable_/sb_secret_ keys are NOT JWTs.
        if key.startswith("eyJ"):
            headers["Authorization"] = f"Bearer {key}"

        return headers

    async def _request(
        self,
        method: str,
        path: str,
        *,
        privileged: bool = False,
        params: dict[str, Any] | None = None,
        json: Any = None,
        extra_headers: dict[str, str] | None = None,
    ) -> Any:
        if not self.settings.supabase_configured:
            raise SupabaseError(
                "Supabase is not configured. Set SUPABASE_URL and a Supabase API key."
            )

        headers = self._headers(privileged=privileged)
        if extra_headers:
            headers.update(extra_headers)

        last_error: Exception | None = None

        for attempt in range(self.settings.http_max_retries + 1):
            try:
                timeout = httpx.Timeout(
                    self.timeout,
                    connect=self.timeout,
                    read=self.timeout,
                    write=self.timeout,
                    pool=self.timeout,
                )

                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.request(
                        method,
                        f"{self.base_url}{path}",
                        params=params,
                        json=json,
                        headers=headers,
                    )

                if response.status_code >= 400:
                    body = response.text[:1500]
                    raise SupabaseError(
                        f"Supabase {method} {path} failed "
                        f"({response.status_code}): {body}"
                    )

                if not response.content:
                    return None
                return response.json()

            except (httpx.ConnectTimeout, httpx.ReadTimeout, httpx.ConnectError) as exc:
                last_error = exc

                if attempt >= self.settings.http_max_retries:
                    break

                await asyncio.sleep(0.8 * (attempt + 1))

        raise SupabaseError(
            "Không kết nối được Supabase sau nhiều lần thử. "
            f"Network error: {type(last_error).__name__}"
        ) from last_error

    async def select(
        self,
        relation: str,
        *,
        select: str = "*",
        filters: dict[str, str] | None = None,
        or_filter: str | None = None,
        order: str | None = None,
        limit: int | None = None,
        privileged: bool = False,
    ) -> list[dict[str, Any]]:
        params: dict[str, Any] = {"select": select}
        if filters:
            params.update(filters)
        if or_filter:
            params["or"] = or_filter
        if order:
            params["order"] = order
        if limit is not None:
            params["limit"] = str(limit)

        data = await self._request(
            "GET",
            f"/rest/v1/{quote(relation, safe='')}",
            privileged=privileged,
            params=params,
        )
        return data or []

    async def insert(
        self,
        relation: str,
        payload: dict[str, Any] | list[dict[str, Any]],
        *,
        privileged: bool = True,
    ) -> Any:
        return await self._request(
            "POST",
            f"/rest/v1/{quote(relation, safe='')}",
            privileged=privileged,
            json=payload,
            extra_headers={"Prefer": "return=minimal"},
        )

    async def rpc(
        self,
        function_name: str,
        payload: dict[str, Any],
        *,
        privileged: bool = True,
    ) -> Any:
        return await self._request(
            "POST",
            f"/rest/v1/rpc/{quote(function_name, safe='')}",
            privileged=privileged,
            json=payload,
        )

    async def auth_user(self, access_token: str) -> dict[str, Any]:
        """
        Verify a Supabase Auth user access token.
        Uses the publishable key when available.
        """
        if not access_token:
            raise SupabaseError("Missing access token.")

        key = self.settings.supabase_publishable_key or self.settings.any_supabase_key
        if not key:
            raise SupabaseError("SUPABASE_PUBLISHABLE_KEY is not configured.")

        headers = {
            "apikey": key,
            "Authorization": f"Bearer {access_token}",
            "Accept": "application/json",
        }

        last_error: Exception | None = None

        for attempt in range(self.settings.http_max_retries + 1):
            try:
                timeout = httpx.Timeout(
                    self.timeout,
                    connect=self.timeout,
                    read=self.timeout,
                    write=self.timeout,
                    pool=self.timeout,
                )

                async with httpx.AsyncClient(timeout=timeout) as client:
                    response = await client.get(
                        f"{self.base_url}/auth/v1/user",
                        headers=headers,
                    )

                if response.status_code != 200:
                    raise SupabaseError("Invalid or expired Supabase access token.")

                return response.json()

            except (httpx.ConnectTimeout, httpx.ReadTimeout, httpx.ConnectError) as exc:
                last_error = exc

                if attempt >= self.settings.http_max_retries:
                    break

                await asyncio.sleep(0.8 * (attempt + 1))

        raise SupabaseError(
            "Không kết nối được Supabase Auth sau nhiều lần thử. "
            f"Network error: {type(last_error).__name__}"
        ) from last_error

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "UniAdmSys AI Agent"
    app_env: str = "development"

    openai_api_key: str = ""
    openai_model: str = "gpt-5.6-luna"
    openai_reasoning_effort: str = "low"
    openai_store_responses: bool = True

    supabase_url: str = ""
    supabase_secret_key: str = ""
    supabase_publishable_key: str = ""
    supabase_service_role_key: str = ""
    supabase_timeout_seconds: float = 30.0

    default_admission_year: int = 2025

    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    max_tool_rounds: int = 8
    openai_timeout_seconds: float = 60.0
    openai_max_retries: int = 2
    http_max_retries: int = 2
    allow_demo_candidate_id: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origin_list(self) -> list[str]:
        return [x.strip() for x in self.cors_origins.split(",") if x.strip()]

    @property
    def privileged_supabase_key(self) -> str:
        # New Supabase secret key first, legacy service_role only as fallback.
        return self.supabase_secret_key or self.supabase_service_role_key

    @property
    def any_supabase_key(self) -> str:
        return self.privileged_supabase_key or self.supabase_publishable_key

    @property
    def supabase_configured(self) -> bool:
        return bool(self.supabase_url and self.any_supabase_key)

    @property
    def supabase_privileged(self) -> bool:
        return bool(self.supabase_url and self.privileged_supabase_key)


@lru_cache
def get_settings() -> Settings:
    return Settings()

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "UniAdmSys AI Agent"
    app_env: str = "development"

    openai_api_key: str = ""
    openai_model: str = "gpt-5.6-luna"
    openai_reasoning_effort: str = "low"
    openai_store_responses: bool = True

    use_mock_backend: bool = True
    backend_base_url: str = "http://localhost:5000"
    backend_service_token: str = ""
    backend_timeout_seconds: float = 10.0

    cors_origins: str = "http://localhost:3000,http://localhost:5173"

    max_tool_rounds: int = 6

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origin_list(self) -> list[str]:
        return [x.strip() for x in self.cors_origins.split(",") if x.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()

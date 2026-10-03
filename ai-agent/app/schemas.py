from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8000)

    # Preferred production path: frontend sends the signed-in user's
    # Supabase access token. The agent verifies it before personal-data tools.
    access_token: str | None = None

    # Development/demo fallback only. Ignored in production when disabled.
    candidate_id: int | None = Field(default=None, gt=0)

    previous_response_id: str | None = None


class ChatResponse(BaseModel):
    answer: str
    response_id: str
    tools_used: list[str]
    authenticated: bool
    role: str
    candidate_id: int | None


class HealthResponse(BaseModel):
    status: str
    model: str
    openai_configured: bool
    supabase_configured: bool
    supabase_privileged: bool

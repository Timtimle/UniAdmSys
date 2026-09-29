from typing import Literal
from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8000)
    user_id: int = Field(gt=0)
    role: Literal["applicant", "admin"] = "applicant"
    previous_response_id: str | None = None


class ChatResponse(BaseModel):
    answer: str
    response_id: str
    tools_used: list[str] = []
    mock_backend: bool


class HealthResponse(BaseModel):
    status: str
    model: str
    mock_backend: bool
    api_key_configured: bool

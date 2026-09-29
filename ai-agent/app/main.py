import logging

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.agent import AdmissionsAgent
from app.config import get_settings
from app.schemas import ChatRequest, ChatResponse, HealthResponse


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="AI Agent microservice for UniAdmSys",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

agent = AdmissionsAgent(settings)


@app.get("/", tags=["system"])
async def root():
    return {
        "service": settings.app_name,
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", response_model=HealthResponse, tags=["system"])
async def health():
    return HealthResponse(
        status="ok",
        model=settings.openai_model,
        mock_backend=settings.use_mock_backend,
        api_key_configured=bool(settings.openai_api_key),
    )


@app.post("/api/agent/chat", response_model=ChatResponse, tags=["agent"])
async def chat(request: ChatRequest):
    try:
        answer, response_id, tools_used = await agent.chat(
            message=request.message,
            user_id=request.user_id,
            role=request.role,
            previous_response_id=request.previous_response_id,
        )
        return ChatResponse(
            answer=answer,
            response_id=response_id,
            tools_used=tools_used,
            mock_backend=settings.use_mock_backend,
        )
    except Exception as exc:
        logging.exception("Agent request failed")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

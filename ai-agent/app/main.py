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
    version="1.0.0",
    description="Tool-first AI admissions agent connected directly to UniAdmSys Supabase.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

agent = AdmissionsAgent(settings)


@app.get("/", tags=["system"])
async def root():
    return {
        "service": settings.app_name,
        "status": "running",
        "docs": "/docs",
        "data_source": "supabase",
    }


@app.get("/health", response_model=HealthResponse, tags=["system"])
async def health():
    return HealthResponse(
        status="ok",
        model=settings.openai_model,
        openai_configured=bool(settings.openai_api_key),
        supabase_configured=settings.supabase_configured,
        supabase_privileged=settings.supabase_privileged,
    )


@app.post("/api/agent/chat", response_model=ChatResponse, tags=["agent"])
async def chat(request: ChatRequest):
    try:
        answer, response_id, tools_used, ctx = await agent.chat(
            message=request.message,
            access_token=request.access_token,
            demo_candidate_id=request.candidate_id,
            previous_response_id=request.previous_response_id,
        )

        return ChatResponse(
            answer=answer,
            response_id=response_id,
            tools_used=tools_used,
            authenticated=ctx.authenticated,
            role=ctx.role,
            candidate_id=ctx.candidate_id,
        )

    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except TimeoutError as exc:
        raise HTTPException(status_code=503, detail="Upstream connection timed out. Please retry.") from exc
    except Exception as exc:
        logging.exception("Agent request failed")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

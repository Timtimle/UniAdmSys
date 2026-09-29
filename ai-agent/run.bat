@echo off
if not exist .venv (
    python -m venv .venv
)
call .venv\Scripts\activate
python -m pip install -r requirements.txt
if not exist .env (
    copy .env.example .env
    echo.
    echo Created .env. Put your OPENAI_API_KEY in .env, then run this file again.
    pause
    exit /b 0
)
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

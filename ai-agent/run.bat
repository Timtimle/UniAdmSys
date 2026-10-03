@echo off
cd /d %~dp0

if not exist .venv (
    python -m venv .venv
)

call .venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if not exist .env (
    copy .env.example .env
    echo.
    echo Created .env.
    echo Fill OPENAI_API_KEY, SUPABASE_URL, SUPABASE_SECRET_KEY,
    echo and SUPABASE_PUBLISHABLE_KEY, then run again.
    pause
    exit /b 0
)

python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

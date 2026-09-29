if (-not (Test-Path ".venv")) {
    python -m venv .venv
}
& ".\.venv\Scripts\Activate.ps1"
python -m pip install -r requirements.txt

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env. Put your OPENAI_API_KEY in .env, then run again."
    exit
}

python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

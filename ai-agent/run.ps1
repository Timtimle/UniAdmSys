Set-Location $PSScriptRoot

if (-not (Test-Path ".venv")) {
    python -m venv .venv
}

& ".\.venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host ""
    Write-Host "Created .env."
    Write-Host "Fill OPENAI_API_KEY, SUPABASE_URL, SUPABASE_SECRET_KEY,"
    Write-Host "and SUPABASE_PUBLISHABLE_KEY, then run again."
    exit
}

python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

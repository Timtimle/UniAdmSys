# UniAdmSys Agent

AI Agent service for UniAdmSys using FastAPI + OpenAI API.

## Features

- LLM integration
- Tool/function calling
- Mock backend for development
- Backend API integration
- Basic admissions document retrieval

## Run

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Copy `.env.example` to `.env` and set:

```env
OPENAI_API_KEY=your_key
OPENAI_MODEL=gpt-5.6-luna
USE_MOCK_BACKEND=true
```

Start:

```bash
python -m uvicorn app.main:app --reload --port 8001
```

Swagger:

```text
http://127.0.0.1:8001/docs
```

## Main API

```http
POST /api/agent/chat
```

Example:

```json
{
  "message": "Hồ sơ của tôi còn thiếu gì?",
  "user_id": 1,
  "role": "applicant"
}
```

## Tools

- `search_majors`
- `get_major_details`
- `get_application_status`
- `get_admission_rules`
- `check_eligibility`
- `search_admission_docs`

## Backend Integration

During development:

```env
USE_MOCK_BACKEND=true
```

When the UniAdmSys backend is ready:

```env
USE_MOCK_BACKEND=false
BACKEND_BASE_URL=http://localhost:5000
```

Backend routes are configured in:

```text
app/backend_client.py
```

## Structure

```text
ai-agent/
├── app/
│   ├── main.py
│   ├── agent.py
│   ├── backend_client.py
│   ├── config.py
│   ├── prompts.py
│   ├── tools/
│   └── rag/
├── data/
├── tests/
├── .env.example
└── requirements.txt
```

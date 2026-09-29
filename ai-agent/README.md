# UniAdmSys AI Agent

Runnable AI-agent microservice for the UniAdmSys project.

The model is the language/reasoning layer. This service adds:
- OpenAI Responses API integration
- Function/tool calling
- Mock UniAdmSys backend so AI work can start before the real backend exists
- Backend adapter for later integration
- Applicant-scoped application tools
- Small local-document retrieval demo (RAG-style)
- FastAPI endpoint for the main backend to call

## Architecture

```text
Frontend
   |
   v
UniAdmSys Backend  <----> Database
   |
   v
AI Agent (this folder)
   |
   +----> OpenAI API (GPT-5.6 Luna)
   |
   +----> UniAdmSys Backend tools
   |
   +----> Local admissions docs / later vector DB
```

Recommended production flow: the browser talks to the normal UniAdmSys backend, and the backend
calls this AI service. Do not expose the OpenAI key to the frontend.

## 1. Quick start on Windows

Open this folder in a terminal.

```bat
run.bat
```

On the first run it creates `.venv` and `.env`, then stops.

Open `.env` and set:

```env
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-5.6-luna
USE_MOCK_BACKEND=true
```

Run again:

```bat
run.bat
```

Then open:

- API docs: `http://127.0.0.1:8001/docs`
- Health: `http://127.0.0.1:8001/health`

## 2. Test the agent

PowerShell:

```powershell
$body = @{
  message = "Hồ sơ của tôi còn thiếu gì?"
  user_id = 1
  role = "applicant"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://127.0.0.1:8001/api/agent/chat" `
  -ContentType "application/json" `
  -Body $body
```

With mock data, user 1 is incomplete and is missing the high-school transcript.

Another test:

```powershell
$body = @{
  message = "Tôi có đủ điều kiện tối thiểu cho ngành SE không?"
  user_id = 1
  role = "applicant"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "http://127.0.0.1:8001/api/agent/chat" `
  -ContentType "application/json" `
  -Body $body
```

## 3. Multi-turn chat

The API returns `response_id`. Send it as `previous_response_id` on the next request:

```json
{
  "message": "Còn ngành CS thì sao?",
  "user_id": 1,
  "role": "applicant",
  "previous_response_id": "resp_..."
}
```

This requires `OPENAI_STORE_RESPONSES=true`.

## 4. What already works

Tools available to the model:

- `search_majors`
- `get_major_details`
- `get_application_status`
- `get_admission_rules`
- `check_eligibility`
- `search_admission_docs`

The model cannot choose an arbitrary `user_id` for `get_application_status`.
The authenticated `user_id` is injected by this service.

## 5. Switch from mock backend to the real backend

Ask the backend teammates to agree on the API contract in `BACKEND_CONTRACT.md`.

Then change:

```env
USE_MOCK_BACKEND=false
BACKEND_BASE_URL=http://localhost:5000
```

If their routes differ, change only:

```text
app/backend_client.py
```

The agent prompt/tool definitions do not need to be rewritten.

## 6. Where to put official documents

Put `.md` or `.txt` files in:

```text
data/admission_docs/
```

The current retriever is intentionally tiny and dependency-free. It ranks text chunks by token
overlap. Later, replace `app/rag/retriever.py` with embeddings + a vector database if needed.

## 7. Run tests

```bat
.venv\Scripts\activate
pytest -q
```

The tests do not call OpenAI and therefore do not spend API credit.

## 8. Important integration rule

Do not give the model direct database credentials and do not let it create arbitrary SQL.
Keep authorization and source-of-truth logic in the UniAdmSys backend.

## Suggested next milestones

1. Run the current mock flow.
2. Commit this folder to the `ai-agent/` directory in the team repo.
3. Agree on the backend contract.
4. Replace mock calls with real backend calls.
5. Add official admissions documents.
6. Add evaluation cases for hallucination, tool selection, and authorization.

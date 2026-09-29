# UniAdmSys AI Agent

FastAPI AI Agent for UniAdmSys using OpenAI API, tool calling and demo RAG data.

## Run

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Set your key in `.env`:

```env
OPENAI_API_KEY=your_key
OPENAI_MODEL=gpt-5.6-luna
USE_MOCK_BACKEND=true
```

Start:

```powershell
python -m uvicorn app.main:app --reload --port 8001
```

Swagger:

```text
http://127.0.0.1:8001/docs
```

## Chat API

```http
POST /api/agent/chat
```

Example:

```json
{
  "message": "Hồ sơ tuyển sinh cần giấy tờ gì?",
  "user_id": 1,
  "role": "applicant"
}
```

## Demo RAG

Demo documents are in:

```text
data/admission_docs/
```

Included:
- `admission_rules_demo.md`
- `tuition_demo.md`
- `faq_demo.md`

Try:
- `Hồ sơ tuyển sinh cần giấy tờ gì?`
- `Đủ điểm tối thiểu có chắc chắn trúng tuyển không?`
- `Học phí Software Engineering bao nhiêu?`
- `IELTS được quy đổi bao nhiêu điểm?`

For document questions, `tools_used` should normally include:

```text
search_admission_docs
```

All current document data is DEMO only.

## Real Backend

Keep this while teammates are still developing:

```env
USE_MOCK_BACKEND=true
```

Later:

```env
USE_MOCK_BACKEND=false
BACKEND_BASE_URL=http://localhost:5000
```

Backend routes are mapped in `app/backend_client.py`.

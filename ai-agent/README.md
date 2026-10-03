# Agent

FastAPI + OpenAI Responses API + tool calling + Supabase.

This version removes the mock backend from the main path. Structured admissions
facts are read directly from the project's Supabase database.

## Architecture

```text
Web UI
  |
  v
FastAPI AI Agent :8001
  |
  +--> OpenAI model
  |
  +--> ToolExecutor
          |
          +--> Supabase Data REST API
          |      - schools
          |      - majors
          |      - cutoff scores
          |      - tuition / quotas / floor scores
          |      - preferences / results
          |      - transcript admission
          |      - direct admission
          |      - certificate conversion
          |
          +--> knowledge_base
```

## 1. Supabase connection

Yes, the agent MUST be connected to Supabase if it should answer from your real
UniAdmSys data.

Create `.env` from `.env.example` and fill:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_SECRET_KEY=sb_secret_xxx
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

`SUPABASE_SECRET_KEY` is SERVER ONLY. Never place it in React/Vite/Next client
code and never commit `.env`.

The secret key is needed because your private admissions tables use RLS and
the agent needs server-side access after it verifies the signed-in user.

## 2. OpenAI

```env
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-5.6 luna
```

Use a model name available in your API project.

## 3. Run

Windows:

```powershell
cd ai-agent
.\run.ps1
```

or:

```cmd
run.bat
```

Swagger:

```text
http://127.0.0.1:8001/docs
```

Health:

```text
GET http://127.0.0.1:8001/health
```

## 4. Chat

Public question:

```json
POST /api/agent/chat

{
  "message": "Điểm chuẩn ngành Công nghệ thông tin năm 2025 là bao nhiêu?"
}
```

Local demo personal question:

```json
{
  "message": "Nguyện vọng của tôi đậu cái nào?",
  "candidate_id": 1
}
```

`candidate_id` is only a development shortcut when
`ALLOW_DEMO_CANDIDATE_ID=true`.

Production personal question:

```json
{
  "message": "Nguyện vọng của tôi đậu cái nào?",
  "access_token": "<Supabase Auth user access token>"
}
```

The server verifies the token using Supabase Auth, resolves
`thi_sinh.user_id`, and only then uses private-data tools.

## 5. Main tools

- `search_schools`
- `get_school_overview`
- `search_majors`
- `get_major_details`
- `search_cutoff_scores` (THPT / ĐGNL / HSA / TSA)
- `get_cutoff_scores`
- `get_application_status`
- `get_preference_results`
- `get_transcript_admission`
- `get_direct_admission_eligibility`
- `get_certificate_conversions`
- `search_knowledge_base`
- `calculate_admission_score`

## 6. Important notes for the report

- The LLM does not query SQL freely.
- It can only access data through predefined tools.
- Structured admissions facts come from Supabase, not model memory.
- Personal tools require authenticated context in production.
- The Supabase secret key stays only on the AI-agent server.
- The LLM calculates no final admission result by itself; it reads the
  result already produced by the admissions rules/database.


## Final tested flows

The current package has been tested against the UniAdmSys Supabase project for:

- public school/major search
- 2025 cutoff-score lookup
- THPT vs ĐGNL/HSA/TSA score-scale separation
- applicant dossier status
- ordered preference results
- transcript admission
- direct-admission eligibility
- certificate conversion
- multi-tool applicant summary
- timeout/retry handling for Supabase/OpenAI calls

Rows whose `source_url` starts with `demo://` are synthetic/demo data and the
agent is instructed to label them clearly instead of presenting them as
official verified admissions data.

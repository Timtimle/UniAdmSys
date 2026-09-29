# UniAdmSys Backend Contract (draft)

The AI Agent works immediately with `USE_MOCK_BACKEND=true`.

When the real backend is ready, set:

```env
USE_MOCK_BACKEND=false
BACKEND_BASE_URL=http://localhost:5000
```

The current `BackendClient` expects these endpoints. If your teammates use different routes,
change only `app/backend_client.py`.

## 1. Search majors

`GET /api/majors?query=software`

Example response:

```json
[
  {
    "code": "SE",
    "name": "Software Engineering",
    "minimumScore": 24.0
  }
]
```

## 2. Major details

`GET /api/majors/SE`

## 3. Current user's application

`GET /api/applications/user/{userId}`

Example:

```json
{
  "applicationId": 1001,
  "userId": 1,
  "status": "Incomplete",
  "score": 25.5,
  "missingDocuments": ["High school transcript"]
}
```

## 4. Search admission rules

`GET /api/admission-rules?query=deadline`

## 5. Eligibility check

`POST /api/eligibility/check`

```json
{
  "userId": 1,
  "majorCode": "SE"
}
```

The backend should remain the source of truth. Do not let the model generate raw SQL or bypass
authorization.

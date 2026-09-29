# Backend Contract

Expected endpoints:

```text
GET  /api/majors?query={query}
GET  /api/majors/{majorCode}
GET  /api/applications/user/{userId}
GET  /api/admission-rules?query={query}
POST /api/eligibility/check
```

Eligibility request:

```json
{
  "userId": 1,
  "majorCode": "SE"
}
```

If backend routes change, update `app/backend_client.py`.

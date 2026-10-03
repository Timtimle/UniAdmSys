TOOL_DEFINITIONS = [
    {
        "type": "function",
        "name": "search_schools",
        "description": "Search universities by school name, admission code, or province/city.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "limit": {"type": "integer", "minimum": 1, "maximum": 20},
            },
            "required": ["query", "limit"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_school_overview",
        "description": "Get 2025 tuition, quota, floor score, and school metadata for one school.",
        "parameters": {
            "type": "object",
            "properties": {
                "school_code": {"type": "string"},
            },
            "required": ["school_code"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "search_majors",
        "description": "Search 2025 majors/programs by name/code, optionally inside one school.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "school_code": {"type": ["string", "null"]},
                "limit": {"type": "integer", "minimum": 1, "maximum": 20},
            },
            "required": ["query", "school_code", "limit"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_major_details",
        "description": (
            "Get one major's catalog data, cutoff scores, admission methods, "
            "and subject combinations. Prefer internal ma_nganh when known."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "major_id": {"type": "string"},
            },
            "required": ["major_id"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "search_cutoff_scores",
        "description": (
            "Search 2025 cutoff scores across schools/majors. "
            "Use this for THPT, DGNL, HSA or TSA cutoff questions."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "score_type": {
                    "type": "string",
                    "enum": ["all", "thi_thpt", "dgnl"],
                },
                "school_code": {"type": ["string", "null"]},
                "exam_code": {"type": ["string", "null"]},
                "limit": {"type": "integer", "minimum": 1, "maximum": 30},
            },
            "required": [
                "query",
                "score_type",
                "school_code",
                "exam_code",
                "limit",
            ],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_cutoff_scores",
        "description": "Get 2025 cutoff-score rows for an internal major id.",
        "parameters": {
            "type": "object",
            "properties": {
                "major_id": {"type": "string"},
            },
            "required": ["major_id"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_application_status",
        "description": (
            "Get the authenticated applicant's 2025 dossier status. "
            "Requires a signed-in user or development candidate context."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_preference_results",
        "description": (
            "Get the authenticated applicant's preference order and current "
            "admission result for each preference."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_transcript_admission",
        "description": "Get transcript-admission calculations/rules for the authenticated applicant.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_direct_admission_eligibility",
        "description": "Get verified achievement matches for direct/priority admission.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_certificate_conversions",
        "description": "Get certificate-score conversion matches such as IELTS/SAT for the applicant.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "search_knowledge_base",
        "description": "Search UniAdmSys knowledge_base for admissions policies, FAQ, and guidance.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "limit": {"type": "integer", "minimum": 1, "maximum": 10},
            },
            "required": ["query", "limit"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "calculate_admission_score",
        "description": (
            "Calculate a hypothetical 30-point admission score from exactly three subjects, "
            "region priority, target-group priority, and optional bonus/floor score. "
            "This is a calculator, not an official admission decision."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "scores": {
                    "type": "array",
                    "items": {"type": "number", "minimum": 0, "maximum": 10},
                    "minItems": 3,
                    "maxItems": 3,
                },
                "region": {
                    "type": "string",
                    "enum": ["KV1", "KV2-NT", "KV2", "KV3"],
                },
                "priority_group": {
                    "type": "string",
                    "enum": ["UT1", "UT2", "NONE"],
                },
                "bonus_score": {"type": "number", "minimum": 0, "maximum": 3},
                "floor_score": {
                    "type": ["number", "null"],
                    "minimum": 0,
                    "maximum": 30,
                },
            },
            "required": [
                "scores",
                "region",
                "priority_group",
                "bonus_score",
                "floor_score",
            ],
            "additionalProperties": False,
        },
        "strict": True,
    },
]

TOOL_DEFINITIONS = [
    {
        "type": "function",
        "name": "search_majors",
        "description": "Search available university majors/programs by name, code, or keyword.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Major name, major code, or keyword to search for."
                }
            },
            "required": ["query"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_major_details",
        "description": "Get authoritative details and configured requirements for one major/program.",
        "parameters": {
            "type": "object",
            "properties": {
                "major_code": {
                    "type": "string",
                    "description": "The major/program code, for example SE or CS."
                }
            },
            "required": ["major_code"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "get_application_status",
        "description": (
            "Get the current authenticated applicant's application status and missing documents. "
            "Do not use this tool to inspect another applicant."
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
        "name": "get_admission_rules",
        "description": "Search structured admissions rules, policies, and deadlines.",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "What rule, policy, requirement, or deadline to look up."
                }
            },
            "required": ["query"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "check_eligibility",
        "description": (
            "Check whether the current authenticated applicant meets the configured minimum "
            "eligibility rules for a major. This is not an official admission decision."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "major_code": {
                    "type": "string",
                    "description": "The major/program code to check."
                }
            },
            "required": ["major_code"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "type": "function",
        "name": "search_admission_docs",
        "description": (
            "Retrieve relevant passages from local admissions documents/FAQ. "
            "Use this for document-style questions that are not covered by structured backend data."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Question or keywords to search in admissions documents."
                }
            },
            "required": ["query"],
            "additionalProperties": False,
        },
        "strict": True,
    },
]

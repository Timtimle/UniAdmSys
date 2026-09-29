MAJORS = [
    {
        "code": "SE",
        "name": "Software Engineering",
        "faculty": "Faculty of Information Technology",
        "minimum_score": 24.0,
        "required_documents": ["High school transcript", "ID Card"],
        "description": "Software development, architecture, testing, and software project practices.",
    },
    {
        "code": "CS",
        "name": "Computer Science",
        "faculty": "Faculty of Information Technology",
        "minimum_score": 25.0,
        "required_documents": ["High school transcript", "ID Card"],
        "description": "Algorithms, data structures, AI, systems, and theoretical foundations.",
    },
    {
        "code": "BA",
        "name": "Business Administration",
        "faculty": "Faculty of Business",
        "minimum_score": 22.0,
        "required_documents": ["High school transcript", "ID Card"],
        "description": "Management, operations, marketing, and business fundamentals.",
    },
]

APPLICATIONS = {
    1: {
        "application_id": 1001,
        "user_id": 1,
        "status": "Incomplete",
        "score": 25.5,
        "submitted_documents": ["ID Card"],
        "missing_documents": ["High school transcript"],
    },
    2: {
        "application_id": 1002,
        "user_id": 2,
        "status": "Under Review",
        "score": 23.0,
        "submitted_documents": ["ID Card", "High school transcript"],
        "missing_documents": [],
    },
}

ADMISSION_RULES = [
    {
        "id": "RULE-001",
        "title": "Application document requirement",
        "text": "Applicants must submit all documents required by the selected admission method before final review.",
    },
    {
        "id": "RULE-002",
        "title": "Eligibility is not admission",
        "text": "Meeting minimum eligibility requirements does not guarantee an admission offer.",
    },
    {
        "id": "RULE-003",
        "title": "Demo application deadline",
        "text": "The mock dataset uses 31 December 2026 as a demonstration deadline. Replace this with official backend data.",
    },
]

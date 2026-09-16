# University admission system

Course Project **Software Engineering**

A system supporting candidates with admission registration and administrators with application review, featuring an integrated AI virtual assistant for automated consultation.

## Installation

to be added

## Usage Guidelines

to be added

## Contributing

to be added

## System Architecture

```mermaid
flowchart LR
    USER["Applicant / Administrator"]
    FE["Frontend"]
    BE["Backend API"]
    DB[("Application Database")]

    subgraph AIS["AI Service"]
        AGENT["AI Agent"]
        RET["Knowledge Retrieval"]
        LLM["Large Language Model"]
    end

    USER --> FE
    FE -->|"REST API"| BE

    BE -->|"Read / Write"| DB
    DB -->|"Data"| BE

    BE -->|"AI Query"| AGENT
    AGENT --> RET
    RET -->|"Relevant Context"| AGENT

    AGENT -->|"Context + Prompt"| LLM
    LLM -->|"Generated Response"| AGENT

    AGENT -->|"AI Response"| BE
    BE -->|"API Response"| FE
    FE --> USER
```

## AI Agent Pipeline

```mermaid
flowchart LR
    Q["User Query"]

    subgraph ORCH["Agent Orchestration"]
        P["Query Processing"]
        R["Knowledge Retrieval"]
        C["Context Builder"]
        G["Response Generator"]
        V["Response Validation"]
    end

    KB[("Admission Knowledge Base")]
    LLM["Large Language Model"]
    OUT["Final Response"]

    Q --> P
    P --> R
    R -->|"Retrieve"| KB
    KB -->|"Relevant Data"| C
    C --> G

    G -->|"Prompt + Context"| LLM
    LLM -->|"Completion"| G

    G --> V
    V --> OUT
```


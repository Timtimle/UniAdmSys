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
    USER["Applicant / Admin"]
    FE["Frontend"]
    BE["Backend"]
    DB[("Database")]
    AI["AI Agent"]

    USER --> FE
    FE --> BE

    BE --> DB
    BE --> AI

    DB --> BE
    AI --> BE

    BE --> FE
    FE --> USER
```

## AI Agent Pipeline

```mermaid
flowchart LR
    Q["User Query"]

    subgraph INPUT["Input Processing"]
        P["Query Preprocessing"]
        I["Intent Analysis"]
    end

    subgraph RETRIEVAL["Knowledge Retrieval"]
        R["Retriever"]
        KB[("Admission Knowledge Base")]
        C["Context Builder"]
    end

    subgraph GENERATION["Generation"]
        PR["Prompt Construction"]
        LLM["Large Language Model"]
    end

    subgraph POST["Post-processing"]
        V["Response Validation"]
        F["Response Formatting"]
    end

    OUT["Final Response"]
    FALLBACK["Fallback Handling"]

    Q --> P
    P --> I

    I --> R
    R -->|"Retrieve"| KB
    KB -->|"Relevant Data"| C

    C --> PR
    PR -->|"Prompt + Context"| LLM

    LLM --> V
    V --> F
    F --> OUT

    R -.->|"Insufficient Data"| FALLBACK
    FALLBACK --> OUT
```


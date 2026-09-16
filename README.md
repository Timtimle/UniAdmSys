# University admission system

Course Project **Software Engineering**

A system supporting candidates with admission registration and administrators with application review, featuring an integrated AI virtual assistant for automated consultation.

## Installation

to be added

## Usage Guidelines

to be added

## Contributing

to be added

## System Pipeline

```mermaid
flowchart LR
    subgraph CLIENT["Client Layer"]
        U["User / Applicant"]
        FE["Frontend"]
        U --> FE
    end

    subgraph SERVER["Application Layer"]
        BE["Backend API"]
    end

    subgraph DATA["Data Layer"]
        DB[("System Database")]
    end

    subgraph AI_LAYER["AI Layer"]
        AI["AI Agent"]
        KB[("Admission Knowledge Base")]
        LLM["LLM / AI Model"]

        AI -->|"Retrieve Data"| KB
        KB -->|"Relevant Context"| AI

        AI -->|"Prompt + Context"| LLM
        LLM -->|"Generated Response"| AI
    end

    FE -->|"HTTP / REST API"| BE

    BE -->|"Query / Update"| DB
    DB -->|"Result"| BE

    BE -->|"AI Request"| AI
    AI -->|"AI Response"| BE

    BE -->|"API Response"| FE

    classDef user fill:#f6f8fa,stroke:#57606a,stroke-width:1.5px;
    classDef frontend fill:#ddf4ff,stroke:#0969da,stroke-width:2px;
    classDef backend fill:#fff8c5,stroke:#bf8700,stroke-width:2px;
    classDef database fill:#ffebe9,stroke:#cf222e,stroke-width:2px;
    classDef ai fill:#fbefff,stroke:#8250df,stroke-width:2px;

    class U user;
    class FE frontend;
    class BE backend;
    class DB database;
    class AI,KB,LLM ai;
```

## AI Agent Pipeline

```mermaid
flowchart TD
    START(["User Question"])

    subgraph INPUT["1. Input Processing"]
        API["Receive Request"]
        PRE["Preprocess Input"]
        INTENT["Intent Detection"]
    end

    subgraph RETRIEVAL["2. Knowledge Retrieval"]
        SEARCH["Search Admission Data"]
        KB[("Admission Knowledge Base")]
        CONTEXT["Build Relevant Context"]
    end

    subgraph GENERATION["3. AI Processing"]
        PROMPT["Prompt Construction"]
        LLM["LLM / AI Model"]
    end

    subgraph OUTPUT["4. Response Processing"]
        VALIDATE["Validate Response"]
        FORMAT["Format Structured Result"]
    end

    END(["Return Answer"])
    FALLBACK["Fallback Response"]

    START --> API
    API --> PRE
    PRE --> INTENT

    INTENT --> SEARCH
    SEARCH --> KB
    KB --> CONTEXT

    CONTEXT --> PROMPT
    PROMPT --> LLM

    LLM --> VALIDATE
    VALIDATE --> FORMAT
    FORMAT --> END

    SEARCH -. "Insufficient Data" .-> FALLBACK
    FALLBACK --> FORMAT

    classDef terminal fill:#f6f8fa,stroke:#57606a,stroke-width:2px;
    classDef input fill:#ddf4ff,stroke:#0969da,stroke-width:1.5px;
    classDef retrieval fill:#dafbe1,stroke:#1a7f37,stroke-width:1.5px;
    classDef ai fill:#fbefff,stroke:#8250df,stroke-width:2px;
    classDef output fill:#fff8c5,stroke:#bf8700,stroke-width:1.5px;
    classDef fallback fill:#ffebe9,stroke:#cf222e,stroke-width:1.5px;

    class START,END terminal;
    class API,PRE,INTENT input;
    class SEARCH,KB,CONTEXT retrieval;
    class PROMPT,LLM ai;
    class VALIDATE,FORMAT output;
    class FALLBACK fallback;
```


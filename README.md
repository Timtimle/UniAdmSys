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
    U[User / Applicant]
    FE[Frontend]
    BE[Backend API]
    DB[(Database)]
    AI[AI Agent]
    KB[(Admission Data / Knowledge Base)]
    LLM[LLM / AI Model]

    U --> FE
    FE --> BE

    BE --> DB
    DB --> BE

    BE --> AI
    AI --> KB
    KB --> AI
    AI --> LLM
    LLM --> AI
    AI --> BE

    BE --> FE
    FE --> U

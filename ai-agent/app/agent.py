from __future__ import annotations

import json
from openai import AsyncOpenAI

from app.config import Settings
from app.prompts import SYSTEM_PROMPT
from app.tools import TOOL_DEFINITIONS, ToolContext, ToolExecutor


class AdmissionsAgent:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.executor = ToolExecutor(settings)

    async def chat(
        self,
        *,
        message: str,
        user_id: int,
        role: str,
        previous_response_id: str | None = None,
    ) -> tuple[str, str, list[str]]:
        if not self.settings.openai_api_key:
            raise RuntimeError(
                "OPENAI_API_KEY is missing. Copy .env.example to .env and add your API key."
            )

        runtime_context = ToolContext(user_id=user_id, role=role)

        instructions = (
            SYSTEM_PROMPT
            + f"\nRuntime context: authenticated user_id={user_id}, role={role}."
        )

        request_kwargs = {
            "model": self.settings.openai_model,
            "instructions": instructions,
            "input": message,
            "tools": TOOL_DEFINITIONS,
            "reasoning": {"effort": self.settings.openai_reasoning_effort},
            "store": self.settings.openai_store_responses,
        }

        if previous_response_id and self.settings.openai_store_responses:
            request_kwargs["previous_response_id"] = previous_response_id

        response = await self.client.responses.create(**request_kwargs)
        tools_used: list[str] = []

        for _ in range(self.settings.max_tool_rounds):
            calls = [item for item in response.output if item.type == "function_call"]

            if not calls:
                answer = response.output_text.strip()
                if not answer:
                    answer = "I could not produce a final answer."
                return answer, response.id, tools_used

            tool_outputs = []
            for call in calls:
                tools_used.append(call.name)
                try:
                    args = json.loads(call.arguments or "{}")
                except json.JSONDecodeError:
                    args = {}

                result = await self.executor.execute(call.name, args, runtime_context)

                tool_outputs.append(
                    {
                        "type": "function_call_output",
                        "call_id": call.call_id,
                        "output": json.dumps(result, ensure_ascii=False),
                    }
                )

            response = await self.client.responses.create(
                model=self.settings.openai_model,
                instructions=instructions,
                tools=TOOL_DEFINITIONS,
                reasoning={"effort": self.settings.openai_reasoning_effort},
                previous_response_id=response.id,
                input=tool_outputs,
                store=self.settings.openai_store_responses,
            )

        raise RuntimeError(
            f"Agent exceeded max_tool_rounds={self.settings.max_tool_rounds}. "
            "Check tool definitions/prompt for a loop."
        )

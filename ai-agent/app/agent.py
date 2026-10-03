from __future__ import annotations

import json
from openai import AsyncOpenAI

from app.config import Settings
from app.prompts import SYSTEM_PROMPT
from app.tools import TOOL_DEFINITIONS, ToolExecutor


class AdmissionsAgent:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = AsyncOpenAI(
            api_key=settings.openai_api_key,
            timeout=settings.openai_timeout_seconds,
            max_retries=settings.openai_max_retries,
        )
        self.executor = ToolExecutor(settings)

    async def chat(
        self,
        *,
        message: str,
        access_token: str | None = None,
        demo_candidate_id: int | None = None,
        previous_response_id: str | None = None,
    ) -> tuple[str, str, list[str], object]:
        if not self.settings.openai_api_key:
            raise RuntimeError(
                "OPENAI_API_KEY is missing. Copy .env.example to .env and add your key."
            )

        if not self.settings.supabase_configured:
            raise RuntimeError(
                "Supabase is not configured. Add SUPABASE_URL and Supabase API keys to .env."
            )

        ctx = await self.executor.build_context(
            access_token=access_token,
            demo_candidate_id=demo_candidate_id,
        )

        instructions = (
            SYSTEM_PROMPT
            + "\nRuntime context:"
            + f" authenticated={ctx.authenticated},"
            + f" role={ctx.role},"
            + f" candidate_available={ctx.candidate_id is not None}."
        )

        kwargs = {
            "model": self.settings.openai_model,
            "instructions": instructions,
            "input": message,
            "tools": TOOL_DEFINITIONS,
            "reasoning": {"effort": self.settings.openai_reasoning_effort},
            "store": self.settings.openai_store_responses,
        }

        if previous_response_id and self.settings.openai_store_responses:
            kwargs["previous_response_id"] = previous_response_id

        response = await self.client.responses.create(**kwargs)
        tools_used: list[str] = []

        for _ in range(self.settings.max_tool_rounds):
            calls = [
                item
                for item in response.output
                if getattr(item, "type", None) == "function_call"
            ]

            if not calls:
                answer = response.output_text.strip()
                if not answer:
                    answer = "Không tạo được câu trả lời cuối cùng."

                await self.executor.log_chat(
                    ctx,
                    question=message,
                    answer=answer,
                    tools_used=tools_used,
                )

                return answer, response.id, tools_used, ctx

            tool_outputs = []

            for call in calls:
                tools_used.append(call.name)

                try:
                    args = json.loads(call.arguments or "{}")
                except json.JSONDecodeError:
                    args = {}

                result = await self.executor.execute(
                    call.name,
                    args,
                    ctx,
                )

                tool_outputs.append(
                    {
                        "type": "function_call_output",
                        "call_id": call.call_id,
                        "output": json.dumps(
                            result,
                            ensure_ascii=False,
                            default=str,
                        ),
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
            f"Agent exceeded max_tool_rounds={self.settings.max_tool_rounds}."
        )

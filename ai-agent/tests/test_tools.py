import pytest

from app.config import Settings
from app.tools import ToolContext, ToolExecutor


@pytest.mark.asyncio
async def test_get_application_status_mock():
    settings = Settings(use_mock_backend=True)
    executor = ToolExecutor(settings)

    result = await executor.execute(
        "get_application_status",
        {},
        ToolContext(user_id=1, role="applicant"),
    )

    assert result["ok"] is True
    assert result["source"] == "mock"
    assert result["data"]["status"] == "Incomplete"


@pytest.mark.asyncio
async def test_check_eligibility_mock():
    settings = Settings(use_mock_backend=True)
    executor = ToolExecutor(settings)

    result = await executor.execute(
        "check_eligibility",
        {"major_code": "SE"},
        ToolContext(user_id=1, role="applicant"),
    )

    assert result["ok"] is True
    assert result["data"]["score_requirement_met"] is True
    assert result["data"]["official_admission_decision"] is False

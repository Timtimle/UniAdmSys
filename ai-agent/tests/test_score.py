from app.tools.executor import ToolExecutor


def test_score_basic():
    result = ToolExecutor._calculate_admission_score(
        scores=[8.0, 8.0, 8.0],
        region="KV3",
        priority_group="NONE",
        bonus_score=0,
        floor_score=22,
    )
    assert result["ok"] is True
    assert result["data"]["admission_score"] == 24.0
    assert result["data"]["meets_floor"] is True


def test_score_priority_combines_region_and_group():
    result = ToolExecutor._calculate_admission_score(
        scores=[6.0, 6.0, 6.0],
        region="KV1",
        priority_group="UT1",
        bonus_score=0,
        floor_score=None,
    )
    assert result["data"]["raw_priority"] == 2.75

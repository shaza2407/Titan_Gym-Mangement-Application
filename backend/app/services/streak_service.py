"""
app/services/streak_service.py
───────────────────────────────
Pure functions for streak / weekly / monthly calculations.
All functions are synchronous and take plain Python lists.
"""

from datetime import date, timedelta
from typing import List


# this file

def calculate_streak(dates: List[date]) -> int:
    """
    Return the current consecutive-day streak ending on the latest date.

    Args:
        dates: sorted (asc) list of unique check-in dates.

    Returns:
        Current streak length (≥ 1 if dates is non-empty, else 0).
    """
    if not dates:
        return 0

    sorted_dates = sorted(set(dates))
    streak = 1

    for i in range(len(sorted_dates) - 1, 0, -1):
        if sorted_dates[i] - sorted_dates[i - 1] == timedelta(days=1):
            streak += 1
        else:
            break

    return streak


def count_weekly_checkins(dates: List[date], reference: date | None = None) -> int:
    """
    Count check-ins that fall in the same ISO calendar week as `reference`.
    Defaults to today.
    """
    ref = reference or date.today()
    week_start = ref - timedelta(days=ref.weekday())   # Monday
    week_end   = week_start + timedelta(days=6)        # Sunday

    return sum(1 for d in dates if week_start <= d <= week_end)


def count_monthly_checkins(dates: List[date], reference: date | None = None) -> int:
    """Count check-ins in the same calendar month as `reference`."""
    ref = reference or date.today()
    return sum(1 for d in dates if d.year == ref.year and d.month == ref.month)


def count_early_bird_checkins(checkin_datetimes) -> int:
    """
    Count check-ins whose time component is before 07:00 (local or UTC,
    depending on how you store them).

    Args:
        checkin_datetimes: list of datetime objects with time info.
    """
    return sum(1 for dt in checkin_datetimes if dt.hour < 7)

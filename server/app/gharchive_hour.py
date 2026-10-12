"""Validate real calendar hours while preserving GH Archive's filename format."""

import re
from datetime import datetime


def normalize_hour(value: str) -> str:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}-\d{1,2}", value):
        raise ValueError("invalid GH Archive hour")
    try:
        year, month, day, hour = map(int, value.split("-"))
        datetime(year, month, day, hour)
    except ValueError:
        raise ValueError("invalid GH Archive hour") from None
    return f"{year:04}-{month:02}-{day:02}-{hour:02}"


def archive_filename_hour(value: str) -> str:
    normalized = normalize_hour(value)
    return f"{normalized[:10]}-{int(normalized[11:])}"

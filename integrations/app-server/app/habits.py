import fcntl
import re
from datetime import date
from pathlib import Path

from .db import get_conn

TRACKER_PATH = Path("/home/developer/free-will/habits/tracker.md")

HABIT_COLUMNS = ["phone_out_of_bed", "reflection", "morning_block", "work_cutoff"]
HABIT_DISPLAY = {
    "phone_out_of_bed": "Phone out of bed",
    "reflection": "Reflection",
    "morning_block": "Morning block",
    "work_cutoff": "Work cutoff",
}

_DONE = "✓"
_MISSED = "✗"
_NA = "—"

_SYMBOL_MAP = {_DONE: "done", _MISSED: "missed", _NA: "na", "✓": "done", "✗": "missed", "-": "na", "—": "na"}


def _parse_row(line: str) -> dict | None:
    parts = [p.strip() for p in line.strip().strip("|").split("|")]
    if len(parts) < 5:
        return None
    date_str = parts[0].strip()
    if not re.match(r"\d{4}-\d{2}-\d{2}", date_str):
        return None
    row = {"date": date_str}
    for i, col in enumerate(HABIT_COLUMNS):
        raw = parts[i + 1].strip() if i + 1 < len(parts) else ""
        row[col] = _SYMBOL_MAP.get(raw, "na")
    return row


def parse_tracker() -> list[dict]:
    if not TRACKER_PATH.exists():
        return []
    rows = []
    for line in TRACKER_PATH.read_text().splitlines():
        if line.startswith("|") and not line.startswith("|---") and not line.startswith("| Date"):
            row = _parse_row(line)
            if row:
                rows.append(row)
    return rows


def _status_to_symbol(completed: bool) -> str:
    return _DONE if completed else _MISSED


def _col_index(habit: str) -> int:
    idx = HABIT_COLUMNS.index(habit)
    return idx + 1  # 0 = date column


def toggle_habit(date_str: str, habit: str, completed: bool) -> dict:
    if habit not in HABIT_COLUMNS:
        raise ValueError(f"Unknown habit: {habit}")

    symbol = _status_to_symbol(completed)
    col_idx = _col_index(habit)

    with TRACKER_PATH.open("r+") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            lines = f.readlines()
            updated = False
            for i, line in enumerate(lines):
                if line.startswith(f"| {date_str}"):
                    parts = line.rstrip("\n").split("|")
                    if col_idx < len(parts):
                        # Preserve spacing
                        old = parts[col_idx]
                        padding = len(old) - len(old.lstrip())
                        rpadding = len(old) - len(old.rstrip())
                        parts[col_idx] = " " * padding + symbol + " " * rpadding
                        lines[i] = "|".join(parts) + "\n"
                        updated = True
                        break

            if not updated:
                # Date row doesn't exist yet — append it
                values = [_NA] * len(HABIT_COLUMNS)
                values[HABIT_COLUMNS.index(habit)] = symbol
                new_row = f"| {date_str} | {' | '.join(values)} |\n"
                # Insert before comment line or at end
                insert_at = len(lines)
                for i, l in enumerate(lines):
                    if l.strip().startswith("<!--"):
                        insert_at = i
                        break
                lines.insert(insert_at, new_row)

            f.seek(0)
            f.writelines(lines)
            f.truncate()
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)

    # Sync to SQLite
    conn = get_conn()
    conn.execute(
        "INSERT OR REPLACE INTO habit_log (date, habit, completed) VALUES (?, ?, ?)",
        (date_str, habit, 1 if completed else 0),
    )
    conn.commit()

    return {"date": date_str, "habit": habit, "completed": completed}


def get_today() -> dict:
    today = date.today().isoformat()
    rows = parse_tracker()
    for row in rows:
        if row["date"] == today:
            return row
    return {"date": today, **{col: "na" for col in HABIT_COLUMNS}}

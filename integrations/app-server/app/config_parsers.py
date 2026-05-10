from pathlib import Path

import yaml

ROOT = Path("/home/developer/free-will")


def parse_goals() -> dict:
    path = ROOT / "config" / "goals.yaml"
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text()) or {}


def parse_schedule() -> dict:
    path = ROOT / "config" / "schedule.yaml"
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text()) or {}

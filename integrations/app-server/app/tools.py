import os
import subprocess
from pathlib import Path

ROOT = Path("/home/developer/free-will")


def _safe_path(rel: str) -> Path:
    resolved = (ROOT / rel.lstrip("/")).resolve()
    if not resolved.is_relative_to(ROOT):
        raise ValueError(f"Path {rel!r} escapes the free-will root.")
    return resolved


# --- handlers ---

def handle_read_file(path: str) -> str:
    try:
        return _safe_path(path).read_text()
    except ValueError as e:
        return f"Error: {e}"
    except FileNotFoundError:
        return f"Error: file not found: {path}"


def handle_write_file(path: str, content: str) -> str:
    try:
        p = _safe_path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        return f"Written: {path}"
    except ValueError as e:
        return f"Error: {e}"


def handle_append_to_file(path: str, content: str) -> str:
    try:
        p = _safe_path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        with p.open("a") as f:
            f.write(content)
        return f"Appended to: {path}"
    except ValueError as e:
        return f"Error: {e}"


def handle_list_directory(path: str = "") -> str:
    try:
        p = _safe_path(path)
        if not p.is_dir():
            return f"Error: not a directory: {path}"
        entries = sorted(p.iterdir(), key=lambda x: (x.is_file(), x.name))
        lines = [f"{'DIR ' if e.is_dir() else 'FILE'} {e.name}" for e in entries]
        return "\n".join(lines) if lines else "(empty)"
    except ValueError as e:
        return f"Error: {e}"


def handle_create_directory(path: str) -> str:
    try:
        _safe_path(path).mkdir(parents=True, exist_ok=True)
        return f"Created: {path}"
    except ValueError as e:
        return f"Error: {e}"


def handle_search_files(query: str) -> str:
    try:
        result = subprocess.run(
            ["grep", "-rl", query, str(ROOT), "--include=*.md", "--include=*.yaml", "--include=*.yml"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        matches = result.stdout.strip()
        if not matches:
            return f"No files found containing: {query}"
        # Return paths relative to ROOT
        lines = [
            str(Path(m).relative_to(ROOT))
            for m in matches.splitlines()
            if m
        ]
        return "\n".join(lines)
    except subprocess.TimeoutExpired:
        return "Error: search timed out"


# --- dispatch ---

TOOL_HANDLERS = {
    "read_file": lambda args: handle_read_file(**args),
    "write_file": lambda args: handle_write_file(**args),
    "append_to_file": lambda args: handle_append_to_file(**args),
    "list_directory": lambda args: handle_list_directory(**args),
    "create_directory": lambda args: handle_create_directory(**args),
    "search_files": lambda args: handle_search_files(**args),
}


def dispatch_tool(name: str, args: dict) -> str:
    handler = TOOL_HANDLERS.get(name)
    if not handler:
        return f"Error: unknown tool {name!r}"
    return handler(args)


# --- Anthropic tool definitions ---

TOOL_DEFINITIONS = [
    {
        "name": "read_file",
        "description": "Read the contents of a file in the free-will folder.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Path relative to the free-will root, e.g. 'habits/tracker.md'"}
            },
            "required": ["path"],
        },
    },
    {
        "name": "write_file",
        "description": "Write (or overwrite) a file in the free-will folder. Creates parent directories automatically.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Relative path to write"},
                "content": {"type": "string", "description": "Full file content"},
            },
            "required": ["path", "content"],
        },
    },
    {
        "name": "append_to_file",
        "description": "Append text to an existing file (or create it).",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string"},
                "content": {"type": "string"},
            },
            "required": ["path", "content"],
        },
    },
    {
        "name": "list_directory",
        "description": "List the contents of a directory in the free-will folder.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Relative path to directory (empty string for root)"}
            },
            "required": [],
        },
    },
    {
        "name": "create_directory",
        "description": "Create a directory (and any missing parents) inside the free-will folder.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {"type": "string"}
            },
            "required": ["path"],
        },
    },
    {
        "name": "search_files",
        "description": "Search for a string across all .md and .yaml files in the free-will folder. Returns matching file paths.",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Text to search for"}
            },
            "required": ["query"],
        },
        "cache_control": {"type": "ephemeral"},
    },
]

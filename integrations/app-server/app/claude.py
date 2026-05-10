import json
from pathlib import Path

import anthropic

from .credentials import load_access_token
from .tools import TOOL_DEFINITIONS, dispatch_tool

MODEL = "claude-sonnet-4-6"
ROOT = Path("/home/developer/free-will")

_system_prompt: str | None = None


def get_system_prompt() -> str:
    global _system_prompt
    if _system_prompt is not None:
        return _system_prompt

    claude_md = (ROOT / "CLAUDE.md").read_text()
    _system_prompt = (
        f"{claude_md}\n\n"
        "---\n"
        "You are running as the free-will assistant accessed via the iOS app. "
        "All file paths you use with tools are relative to the free-will root directory. "
        "For example, use 'habits/tracker.md' not '/home/developer/free-will/habits/tracker.md'. "
        "Be concise and direct — the user is on mobile."
    )
    return _system_prompt


async def stream_claude(
    send_event,  # async callable(dict) → None
    messages: list[dict],
) -> tuple[list[dict], str]:
    """
    Run a Claude streaming call with tool-use loop.

    send_event: coroutine that forwards JSON events to the WebSocket.
    messages:   current conversation history (mutated and returned).

    Returns (updated_messages, full_assistant_text).
    """
    client = anthropic.AsyncAnthropic(api_key=load_access_token())
    system = get_system_prompt()
    full_text = ""

    while True:
        accumulated_text = ""
        tool_calls: list[dict] = []
        stop_reason = None

        async with client.messages.stream(
            model=MODEL,
            max_tokens=4096,
            system=[
                {
                    "type": "text",
                    "text": system,
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            tools=TOOL_DEFINITIONS,
            messages=messages,
        ) as stream:
            async for event in stream:
                if event.type == "content_block_delta":
                    if event.delta.type == "text_delta":
                        chunk = event.delta.text
                        accumulated_text += chunk
                        await send_event({"type": "text_delta", "text": chunk})

                    elif event.delta.type == "input_json_delta":
                        if tool_calls:
                            tool_calls[-1]["_partial_input"] = (
                                tool_calls[-1].get("_partial_input", "") + event.delta.partial_json
                            )

                elif event.type == "content_block_start":
                    if event.content_block.type == "tool_use":
                        tool_calls.append({
                            "id": event.content_block.id,
                            "name": event.content_block.name,
                            "_partial_input": "",
                        })
                        await send_event({"type": "tool_use", "name": event.content_block.name})

                elif event.type == "message_delta":
                    stop_reason = event.delta.stop_reason

        full_text += accumulated_text

        # Parse completed tool inputs
        for tc in tool_calls:
            raw = tc.pop("_partial_input", "{}")
            try:
                tc["input"] = json.loads(raw)
            except json.JSONDecodeError:
                tc["input"] = {}

        # Build the assistant message content blocks
        assistant_content: list[dict] = []
        if accumulated_text:
            assistant_content.append({"type": "text", "text": accumulated_text})
        for tc in tool_calls:
            assistant_content.append({
                "type": "tool_use",
                "id": tc["id"],
                "name": tc["name"],
                "input": tc["input"],
            })

        messages.append({"role": "assistant", "content": assistant_content})

        # If no tool calls or stop_reason is end_turn, we're done
        if not tool_calls or stop_reason == "end_turn":
            break

        # Execute tools and build tool_result message
        tool_results: list[dict] = []
        for tc in tool_calls:
            result = dispatch_tool(tc["name"], tc["input"])
            await send_event({
                "type": "tool_result",
                "name": tc["name"],
                "result": result[:500] + "…" if len(result) > 500 else result,
            })
            tool_results.append({
                "type": "tool_result",
                "tool_use_id": tc["id"],
                "content": result,
            })

        messages.append({"role": "user", "content": tool_results})

    await send_event({"type": "done", "text": full_text})
    return messages, full_text

#!/usr/bin/env python3
"""Fake MCP server (stdio) for the tests of the MCP client of framework/ai and of ec -tui.

One JSON-RPC message per line on stdin / stdout; its log on stderr.
Tools (listed in two pages, to test the cursor):
  echo   {text}       -> "echo: TEXT" (read only)
  add    {a, b}       -> the sum
  fail   {}           -> a result with isError
  slow   {seconds}    -> answers after SECONDS seconds
  image  {}           -> an image content and a text
  crash  {}           -> the server exits without answering
After `initialized`, the server sends a `ping` request (id 1000) and logs whether it was answered.
Environment:
  FAKE_MCP_CALLS   file to which each call is appended (one JSON line), if set
  FAKE_MCP_NAME    name given in serverInfo (default "fake")
"""
import json
import os
import sys
import time

TOOLS = [
    {"name": "echo", "description": "Echo a text.",
     "inputSchema": {"type": "object", "properties": {"text": {"type": "string"}}, "required": ["text"]},
     "annotations": {"readOnlyHint": True}},
    {"name": "add", "description": "Add two numbers.",
     "inputSchema": {"type": "object", "properties": {"a": {"type": "number"}, "b": {"type": "number"}}}},
    {"name": "fail", "description": "Always fails.", "inputSchema": {"type": "object"}},
    {"name": "slow", "description": "Answer after some seconds.",
     "inputSchema": {"type": "object", "properties": {"seconds": {"type": "number"}}}},
    {"name": "image", "description": "Give an image.", "inputSchema": {"type": "object"}},
    {"name": "crash", "description": "Stop the server.", "inputSchema": {"type": "object"}},
]


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def log(text):
    sys.stderr.write(text + "\n")
    sys.stderr.flush()


def result(request_id, value):
    send({"jsonrpc": "2.0", "id": request_id, "result": value})


def text_result(request_id, text, is_error=False):
    result(request_id, {"content": [{"type": "text", "text": text}], "isError": is_error})


def call(request_id, name, arguments):
    calls = os.environ.get("FAKE_MCP_CALLS")
    if calls:
        with open(calls, "a") as f:
            f.write(json.dumps({"name": name, "arguments": arguments}) + "\n")
    if name == "echo":
        text_result(request_id, "echo: " + str(arguments.get("text", "")))
    elif name == "add":
        text_result(request_id, str(arguments.get("a", 0) + arguments.get("b", 0)))
    elif name == "fail":
        text_result(request_id, "this tool always fails", True)
    elif name == "slow":
        time.sleep(float(arguments.get("seconds", 1)))
        text_result(request_id, "slow done")
    elif name == "image":
        result(request_id, {"content": [{"type": "image", "data": "AAAA", "mimeType": "image/png"},
                                        {"type": "text", "text": "an image"}]})
    elif name == "crash":
        log("crashing")
        sys.exit(3)
    else:
        send({"jsonrpc": "2.0", "id": request_id, "error": {"code": -32602, "message": "Unknown tool: " + name}})


def main():
    log("fake server started")
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        message = json.loads(line)
        method = message.get("method")
        request_id = message.get("id")
        if method == "initialize":
            result(request_id, {"protocolVersion": message["params"]["protocolVersion"], "capabilities": {"tools": {"listChanged": True}},
                                "serverInfo": {"name": os.environ.get("FAKE_MCP_NAME", "fake"), "version": "1.0"}})
        elif method == "notifications/initialized":
            send({"jsonrpc": "2.0", "id": 1000, "method": "ping"})
        elif method == "tools/list":
            cursor = (message.get("params") or {}).get("cursor")
            if cursor == "page2":
                result(request_id, {"tools": TOOLS[3:]})
            else:
                result(request_id, {"tools": TOOLS[:3], "nextCursor": "page2"})
        elif method == "tools/call":
            params = message.get("params") or {}
            call(request_id, params.get("name"), params.get("arguments") or {})
        elif method is None and request_id == 1000:
            log("ping answered" if "result" in message else "ping refused")
        elif request_id is not None:
            send({"jsonrpc": "2.0", "id": request_id, "error": {"code": -32601, "message": "Unknown method: " + str(method)}})
    log("fake server: end of input")


if __name__ == "__main__":
    main()

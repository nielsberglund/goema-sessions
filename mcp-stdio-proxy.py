#!/usr/bin/env python3
"""Stdio shim between Copilot CLI and crystaldba/postgres-mcp.

Why this exists: Copilot CLI 1.0.86 probes every local MCP server with a
proprietary `server/discover` request before falling back to the standard
`initialize` handshake. Most servers just ignore the unknown method and let
the probe time out, and Copilot retries fine on the same connection. But
postgres-mcp's request parser throws an uncaught pydantic ValidationError on
`server/discover` and the whole process exits (code 1) — so the connection
is dead before Copilot can retry. See `copilot mcp get goema-db` +
~/.copilot/logs/*.log ("MCP server connection failed ... exit code 1 ...
Input should be 'tools/list' ... input_value='server/discover'").

Fix: sit between the two, answer `server/discover` ourselves with a
JSON-RPC "method not found" error (so Copilot falls back to legacy
initialize) and pass every other line straight through to the real
postgres-mcp process untouched.

Usage: mcp-stdio-proxy.py <command> [args...]
"""
import json
import sys
import subprocess
import threading

def pump(src, dst):
    for chunk in iter(lambda: src.read1(65536) if hasattr(src, "read1") else src.read(65536), b""):
        dst.write(chunk)
        dst.flush()

def main():
    child = subprocess.Popen(
        sys.argv[1:],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
    )

    # Forward the child's stdout to our stdout untouched, in the background.
    t = threading.Thread(target=pump, args=(child.stdout, sys.stdout.buffer), daemon=True)
    t.start()

    try:
        for line in sys.stdin.buffer:
            handled = False
            try:
                msg = json.loads(line)
                if isinstance(msg, dict) and msg.get("method") == "server/discover":
                    reply = {
                        "jsonrpc": "2.0",
                        "id": msg.get("id"),
                        "error": {"code": -32601, "message": "Method not found"},
                    }
                    sys.stdout.buffer.write((json.dumps(reply) + "\n").encode())
                    sys.stdout.buffer.flush()
                    handled = True
            except json.JSONDecodeError:
                pass
            if not handled:
                child.stdin.write(line)
                child.stdin.flush()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        try:
            child.stdin.close()
        except Exception:
            pass
        child.wait()
        t.join(timeout=2)

if __name__ == "__main__":
    sys.exit(main())

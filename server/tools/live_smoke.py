from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory() as directory:
        environment = {
            **os.environ,
            "GITHUB_NEWS_MASTER_KEY": "smoke-secret",
            "GITHUB_NEWS_DB": str(Path(directory) / "smoke.db"),
            "GITHUB_NEWS_SCHEDULER_ENABLED": "false",
        }
        process = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "18765"],
            cwd=root,
            env=environment,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            deadline = time.monotonic() + 15
            healthy = False
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f"uvicorn exited with {process.returncode}")
                try:
                    payload = _request("/health")
                    if payload.get("status") == "ok":
                        healthy = True
                        break
                except OSError:
                    time.sleep(0.25)
            if not healthy:
                raise TimeoutError("server did not become healthy within 15 seconds")

            headers = {
                "Authorization": "Bearer smoke-secret",
                "X-Workspace-ID": "smoke-workspace",
            }
            sources = _request("/v1/news/sources", headers=headers)
            if not isinstance(sources, list) or not sources:
                raise RuntimeError("authenticated source API returned no sources")
            pushed = _request(
                "/v1/sync/push",
                method="POST",
                headers=headers,
                body={
                    "records": [
                        {
                            "namespace": "smoke",
                            "record_id": "config",
                            "payload": {"verified": True},
                            "version": 1,
                            "updated_at": 1,
                        }
                    ]
                },
            )
            if pushed.get("accepted") != 1:
                raise RuntimeError("sync push was not accepted")
            pulled = _request("/v1/sync/pull?since=0", headers=headers)
            if not isinstance(pulled, list) or pulled[0].get("payload") != {"verified": True}:
                raise RuntimeError("sync pull did not return the pushed record")
            print("Live server smoke passed: health, auth, sources, and sync round-trip")
            return 0
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
    return 1


def _request(
    path: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    body: dict[str, object] | None = None,
) -> object:
    request_headers = dict(headers or {})
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        request_headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        f"http://127.0.0.1:18765{path}",
        data=data,
        headers=request_headers,
        method=method,
    )
    with urllib.request.urlopen(request, timeout=3) as response:
        return json.load(response)


if __name__ == "__main__":
    raise SystemExit(main())

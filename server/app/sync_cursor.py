"""Versioned, workspace-scoped cursors for server-owned sync revisions."""

import base64
import binascii
import json

from .db import json_text


def encode_cursor(workspace_id: str, revision: int) -> str:
    payload = json_text({"v": 1, "w": workspace_id, "r": revision}).encode()
    return base64.urlsafe_b64encode(payload).decode().rstrip("=")


def decode_cursor(cursor: str, workspace_id: str) -> int:
    # The first revision page must opt in explicitly: legacy callers still
    # page by updated_at and cannot safely switch ordering mid-stream.
    if cursor == "start":
        return 0
    try:
        payload = json.loads(
            base64.b64decode(cursor + "=" * (-len(cursor) % 4), altchars=b"-_", validate=True)
        )
        if (
            not isinstance(payload, dict)
            or payload.get("v") != 1
            or payload.get("w") != workspace_id
            or type(payload.get("r")) is not int
            or payload["r"] < 0
            or payload["r"] > 2**63 - 1
        ):
            raise ValueError("invalid sync cursor")
        return payload["r"]
    except (ValueError, TypeError, binascii.Error):
        raise ValueError("invalid sync cursor") from None

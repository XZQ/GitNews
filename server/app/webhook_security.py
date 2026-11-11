from __future__ import annotations

import ipaddress
import socket
from urllib.parse import urlsplit

# 出站投递只允许 http/https；file://、gopher:// 等协议一律拒绝。
_ALLOWED_SCHEMES = {"http", "https"}


class UnsafeWebhookEndpointError(ValueError):
    """Raised when a webhook endpoint is malformed or targets a non-public address."""


def validate_webhook_endpoint(endpoint: str, *, allow_private: bool = False) -> None:
    """Reject malformed webhook URLs and, by default, non-public targets.

    Called once at subscription time for fast feedback and again right before
    each delivery, so a hostname that later resolves to an internal address
    (DNS rebinding) is still blocked. Self-hosters who deliberately deliver to
    LAN services can opt out via GITHUB_NEWS_WEBHOOK_ALLOW_PRIVATE.
    """
    parts = urlsplit(endpoint)
    if parts.scheme not in _ALLOWED_SCHEMES:
        raise UnsafeWebhookEndpointError("webhook endpoint must use http or https")
    if not parts.hostname:
        raise UnsafeWebhookEndpointError("webhook endpoint must include a host")
    if parts.username is not None or parts.password is not None:
        raise UnsafeWebhookEndpointError("webhook endpoint must not embed credentials")
    if allow_private:
        return
    try:
        infos = socket.getaddrinfo(parts.hostname, None, proto=socket.IPPROTO_TCP)
    except socket.gaierror as error:
        raise UnsafeWebhookEndpointError("webhook host does not resolve") from error
    for info in infos:
        address = ipaddress.ip_address(info[4][0])
        # IPv4-mapped IPv6 (::ffff:10.0.0.1) must be judged by its embedded
        # IPv4 address, otherwise private ranges slip through the IPv6 table.
        mapped = getattr(address, "ipv4_mapped", None)
        if mapped is not None:
            address = mapped
        if not address.is_global:
            raise UnsafeWebhookEndpointError("webhook endpoint must resolve to a public address")

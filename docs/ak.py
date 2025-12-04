from mitmproxy import http
from urllib.parse import urlparse, parse_qsl, urlencode
import requests
import ssl
import json


def request(flow: http.HTTPFlow) -> None:
    if ("hypergryph.com" in flow.request.pretty_url) or ("gryphline" in flow.request.pretty_url):
        if flow.request.method == "CONNECT":
            return
        if "/get_latest_resources" in flow.request.pretty_url:
            return
        flow.request.scheme = "http"
        flow.request.cookies.update(
            {"OriginalHost": flow.request.host, "OriginalUrl": flow.request.url}
        )
        flow.request.host = "127.0.0.1"
        flow.request.port = 5000
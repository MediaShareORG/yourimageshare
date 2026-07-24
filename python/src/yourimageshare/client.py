from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any, BinaryIO, List, Optional, Union

import requests

DEFAULT_BASE_URL = "https://yourimageshare.com/api"
SDK_VERSION = "1.0.3"


class YourImageShareError(Exception):
    """Raised for any non-2xx response or a `{"type": "error"}` payload.

    `status` is the HTTP status code; `message` is the server's error text
    (falls back to a generic message if the server didn't send one).
    """

    def __init__(self, message: str, status: int):
        super().__init__(f"[{status}] {message}")
        self.message = message
        self.status = status


@dataclass
class UploadResult:
    id: str
    type: str
    path: str
    src: str
    direct: str
    expires_at: Optional[str]


@dataclass
class ListedUpload:
    id: str
    type: str
    title: Optional[str]
    path: str
    src: str
    direct: str
    expires_at: Optional[str]
    created_at: str


@dataclass
class ListMeta:
    current_page: int
    last_page: int
    total: int


@dataclass
class ListResult:
    data: List[ListedUpload]
    meta: ListMeta


class YourImageShare:
    """Client for the YourImageShare upload API.

    Example:
        client = YourImageShare(api_key="...")
        result = client.upload("photo.jpg")
        print(result.direct)
    """

    def __init__(self, api_key: str, base_url: str = DEFAULT_BASE_URL, timeout: float = 30.0):
        if not api_key:
            raise ValueError("YourImageShare: `api_key` is required.")
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self._session = requests.Session()
        self._session.headers.update(
            {
                "X-API-Key": self.api_key,
                # requests' own default UA identifies itself fine, but a distinctive
                # one makes SDK traffic easy to pick out of server logs.
                "User-Agent": f"yourimageshare-py/{SDK_VERSION}",
            }
        )

    def _parse(self, response: requests.Response) -> dict:
        try:
            body = response.json()
        except ValueError as exc:
            raise YourImageShareError(
                f"Unexpected non-JSON response (HTTP {response.status_code})", response.status_code
            ) from exc
        if not response.ok or body.get("type") == "error":
            message = body.get("errors")
            if not isinstance(message, str):
                message = f"Request failed (HTTP {response.status_code})"
            raise YourImageShareError(message, response.status_code)
        return body

    def upload(
        self,
        file: Union[str, "os.PathLike[str]", BinaryIO],
        *,
        filename: Optional[str] = None,
        expires_in: Optional[int] = None,
    ) -> UploadResult:
        """Upload a file.

        `file` is a path (str or PathLike) or an already-open binary file object.
        `expires_in` is seconds (60 to 2,592,000 = 30 days) to auto-delete the
        upload later; omit for a permanent upload.
        """
        data: dict[str, Any] = {}
        if expires_in is not None:
            data["expires_in"] = str(expires_in)

        opened = None
        try:
            if isinstance(file, (str, os.PathLike)):
                opened = open(file, "rb")
                fileobj: BinaryIO = opened
                name = filename or os.path.basename(os.fspath(file))
            else:
                fileobj = file
                name = filename or getattr(file, "name", "upload")

            response = self._session.post(
                self.base_url,
                files={"uploads": (name, fileobj)},
                data=data,
                timeout=self.timeout,
            )
        finally:
            if opened is not None:
                opened.close()

        body = self._parse(response)
        return UploadResult(**body["data"])

    def list(self, page: int = 1) -> ListResult:
        """List your uploads, newest first. Paginated 50 per page."""
        params = {"page": page} if page > 1 else {}
        response = self._session.get(self.base_url, params=params, timeout=self.timeout)
        body = self._parse(response)
        uploads = [ListedUpload(**item) for item in body["data"]]
        meta = ListMeta(**body["meta"])
        return ListResult(data=uploads, meta=meta)

    def delete(self, upload_id: str) -> None:
        """Delete one of your uploads by id."""
        response = self._session.delete(f"{self.base_url}/{upload_id}", timeout=self.timeout)
        self._parse(response)

    def close(self) -> None:
        self._session.close()

    def __enter__(self) -> "YourImageShare":
        return self

    def __exit__(self, *exc_info: object) -> None:
        self.close()

#!/usr/bin/env python3
"""Trigger and monitor an Xcode Cloud workflow through App Store Connect."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


API_BASE_URL = "https://api.appstoreconnect.apple.com/v1"
TERMINAL_PROGRESS = {"COMPLETE"}
SUCCESS_COMPLETION = {"SUCCEEDED"}


class AppStoreConnectError(RuntimeError):
    """A sanitized App Store Connect API failure."""


def _claims(issuer_id: str | None, now: int) -> dict[str, Any]:
    claims: dict[str, Any] = {
        "aud": "appstoreconnect-v1",
        "iat": now,
        "exp": now + 900,
    }
    if issuer_id:
        claims["iss"] = issuer_id
    else:
        claims["sub"] = "user"
    return claims


def _build_run_payload(
    workflow_id: str, git_reference_id: str | None = None
) -> dict[str, Any]:
    relationships: dict[str, Any] = {
        "workflow": {
            "data": {
                "type": "ciWorkflows",
                "id": workflow_id,
            }
        }
    }
    if git_reference_id:
        relationships["sourceBranchOrTag"] = {
            "data": {
                "type": "scmGitReferences",
                "id": git_reference_id,
            }
        }

    return {
        "data": {
            "type": "ciBuildRuns",
            "attributes": {},
            "relationships": relationships,
        }
    }


@dataclass
class AppStoreConnectClient:
    key_id: str
    private_key: str
    issuer_id: str | None = None
    base_url: str = API_BASE_URL

    def _token(self) -> str:
        try:
            import jwt
        except ImportError as error:
            raise AppStoreConnectError(
                "PyJWT is unavailable; install ci_scripts/requirements.txt"
            ) from error

        now = int(time.time())
        return jwt.encode(
            _claims(self.issuer_id, now),
            self.private_key,
            algorithm="ES256",
            headers={
                "alg": "ES256",
                "kid": self.key_id,
                "typ": "JWT",
            },
        )

    def request(
        self, method: str, path: str, payload: dict[str, Any] | None = None
    ) -> dict[str, Any]:
        body = None
        if payload is not None:
            body = json.dumps(payload).encode("utf-8")

        request = urllib.request.Request(
            f"{self.base_url}{path}",
            data=body,
            method=method,
            headers={
                "Authorization": f"Bearer {self._token()}",
                "Content-Type": "application/json",
            },
        )

        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            detail = f"HTTP {error.code}"
            try:
                response_body = json.load(error)
                errors = response_body.get("errors", [])
                if errors:
                    first = errors[0]
                    detail = (
                        f"HTTP {error.code}: "
                        f"{first.get('title', 'App Store Connect error')} — "
                        f"{first.get('detail', 'No detail provided')}"
                    )
            except (json.JSONDecodeError, UnicodeDecodeError):
                pass
            raise AppStoreConnectError(detail) from error
        except urllib.error.URLError as error:
            raise AppStoreConnectError(
                f"Unable to reach App Store Connect: {error.reason}"
            ) from error


def _client_from_environment() -> AppStoreConnectClient:
    key_id = os.environ.get("APP_STORE_CONNECT_KEY_ID", "").strip()
    private_key = (
        os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY", "")
        .replace("\\n", "\n")
        .strip()
    )
    issuer_id = os.environ.get("APP_STORE_CONNECT_ISSUER_ID", "").strip() or None

    missing = []
    if not key_id:
        missing.append("APP_STORE_CONNECT_KEY_ID")
    if not private_key:
        missing.append("APP_STORE_CONNECT_PRIVATE_KEY")
    if missing:
        raise AppStoreConnectError(
            f"Missing required environment variable(s): {', '.join(missing)}"
        )

    return AppStoreConnectClient(
        key_id=key_id,
        private_key=private_key,
        issuer_id=issuer_id,
        base_url=os.environ.get("APP_STORE_CONNECT_API_BASE_URL", API_BASE_URL),
    )


def _workflow_repository_id(
    client: AppStoreConnectClient, workflow_id: str
) -> str:
    response = client.request(
        "GET", f"/ciWorkflows/{urllib.parse.quote(workflow_id)}/repository"
    )
    repository = response.get("data")
    if not repository or not repository.get("id"):
        raise AppStoreConnectError(
            "The Xcode Cloud workflow has no source repository"
        )
    return str(repository["id"])


def _branch_reference_id(
    client: AppStoreConnectClient, workflow_id: str, branch: str
) -> str | None:
    repository_id = _workflow_repository_id(client, workflow_id)
    query = urllib.parse.urlencode(
        {
            "limit": "200",
            "fields[scmGitReferences]": (
                "name,canonicalName,isDeleted,kind"
            ),
        }
    )
    response = client.request(
        "GET",
        f"/scmRepositories/{urllib.parse.quote(repository_id)}"
        f"/gitReferences?{query}",
    )

    canonical_name = f"refs/heads/{branch}"
    for reference in response.get("data", []):
        attributes = reference.get("attributes", {})
        if (
            not attributes.get("isDeleted", False)
            and attributes.get("canonicalName") == canonical_name
        ):
            return str(reference["id"])
    return None


def _write_github_output(name: str, value: str) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8") as output:
        output.write(f"{name}={value}\n")


def trigger(client: AppStoreConnectClient, workflow_id: str, branch: str) -> int:
    reference_id = _branch_reference_id(client, workflow_id, branch)
    if reference_id:
        print(f"Resolved Xcode Cloud source branch: {branch}")
    else:
        print(
            f"Branch {branch!r} is not present in Xcode Cloud yet; "
            "using the workflow's default source branch."
        )

    response = client.request(
        "POST",
        "/ciBuildRuns",
        _build_run_payload(workflow_id, reference_id),
    )
    build_run = response.get("data", {})
    build_run_id = str(build_run.get("id", ""))
    if not build_run_id:
        raise AppStoreConnectError(
            "Apple accepted the request but returned no Xcode Cloud build ID"
        )

    _write_github_output("build_run_id", build_run_id)
    print(f"Started Xcode Cloud build run {build_run_id}")
    return 0


def wait_for_build(
    client: AppStoreConnectClient,
    build_run_id: str,
    timeout_seconds: int,
    poll_seconds: int,
) -> int:
    deadline = time.monotonic() + timeout_seconds
    query = urllib.parse.urlencode(
        {
            "fields[ciBuildRuns]": (
                "number,createdDate,startedDate,finishedDate,"
                "executionProgress,completionStatus,startReason,cancelReason"
            )
        }
    )
    path = (
        f"/ciBuildRuns/{urllib.parse.quote(build_run_id)}?{query}"
    )

    while True:
        response = client.request("GET", path)
        attributes = response.get("data", {}).get("attributes", {})
        progress = attributes.get("executionProgress") or "PENDING"
        completion = attributes.get("completionStatus")
        number = attributes.get("number") or "pending"
        print(
            f"Xcode Cloud build {number}: progress={progress}, "
            f"completion={completion or 'pending'}",
            flush=True,
        )

        if progress in TERMINAL_PROGRESS or completion:
            if completion in SUCCESS_COMPLETION:
                print("Xcode Cloud completed successfully.")
                return 0
            raise AppStoreConnectError(
                "Xcode Cloud finished without success "
                f"(completion={completion or 'unknown'}, "
                f"cancel={attributes.get('cancelReason') or 'none'})."
            )

        if time.monotonic() >= deadline:
            raise AppStoreConnectError(
                f"Timed out waiting for Xcode Cloud after {timeout_seconds}s"
            )
        time.sleep(poll_seconds)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Trigger or monitor an Xcode Cloud workflow"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    trigger_parser = subparsers.add_parser(
        "trigger", help="Start an Xcode Cloud build"
    )
    trigger_parser.add_argument("--workflow-id", required=True)
    trigger_parser.add_argument("--branch", default="main")

    wait_parser = subparsers.add_parser(
        "wait", help="Wait for an Xcode Cloud build"
    )
    wait_parser.add_argument("--build-run-id", required=True)
    wait_parser.add_argument(
        "--timeout-seconds", type=int, default=5100
    )
    wait_parser.add_argument("--poll-seconds", type=int, default=30)
    return parser


def main() -> int:
    arguments = _parser().parse_args()
    client = _client_from_environment()

    if arguments.command == "trigger":
        return trigger(client, arguments.workflow_id, arguments.branch)
    return wait_for_build(
        client,
        arguments.build_run_id,
        arguments.timeout_seconds,
        arguments.poll_seconds,
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AppStoreConnectError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""Trigger and monitor an Xcode Cloud workflow through App Store Connect."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


API_BASE_URL = "https://api.appstoreconnect.apple.com/v1"
TERMINAL_PROGRESS = {"COMPLETE"}
SUCCESS_COMPLETION = {"SUCCEEDED"}
TESTFLIGHT_PLATFORMS = {"IOS", "TV_OS"}
USABLE_INTERNAL_STATES = {"READY_FOR_BETA_TESTING", "IN_BETA_TESTING"}


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
                response_body = response.read()
                if not response_body:
                    return {}
                return json.loads(response_body)
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


def _state_value(attributes: dict[str, Any]) -> tuple[str, list[Any]]:
    state = attributes.get("state")
    if isinstance(state, dict):
        return str(state.get("state") or ""), list(state.get("errors") or [])
    return str(state or ""), []


def _ipa_metadata(ipa_path: Path) -> tuple[str, str]:
    with zipfile.ZipFile(ipa_path) as archive:
        plist_names = [
            name
            for name in archive.namelist()
            if name.startswith("Payload/")
            and name.endswith(".app/Info.plist")
            and name.count("/") == 2
        ]
        if len(plist_names) != 1:
            raise AppStoreConnectError(
                "The tvOS archive must contain exactly one app Info.plist"
            )
        metadata = plistlib.loads(archive.read(plist_names[0]))

    marketing_version = str(
        metadata.get("CFBundleShortVersionString") or ""
    ).strip()
    build_number = str(metadata.get("CFBundleVersion") or "").strip()
    if not marketing_version or not build_number:
        raise AppStoreConnectError(
            "The tvOS archive is missing its version or build number"
        )
    return marketing_version, build_number


def _existing_tvos_build(
    client: AppStoreConnectClient,
    app_id: str,
    marketing_version: str,
    build_number: str,
) -> str | None:
    query = urllib.parse.urlencode(
        {
            "filter[app]": app_id,
            "filter[version]": build_number,
            "include": "preReleaseVersion",
            "limit": "20",
        }
    )
    response = client.request("GET", f"/builds?{query}")
    included = {
        str(resource["id"]): resource
        for resource in response.get("included", [])
    }
    for build in response.get("data", []):
        relationship = (
            build.get("relationships", {})
            .get("preReleaseVersion", {})
            .get("data")
        )
        prerelease = (
            included.get(str(relationship["id"]), {}).get("attributes", {})
            if relationship
            else {}
        )
        attributes = build.get("attributes", {})
        if (
            attributes.get("processingState") == "VALID"
            and prerelease.get("platform") == "TV_OS"
            and str(prerelease.get("version")) == marketing_version
        ):
            return str(build["id"])
    return None


def _assign_beta_group(
    client: AppStoreConnectClient, build_id: str, beta_group_id: str
) -> None:
    client.request(
        "POST",
        f"/builds/{urllib.parse.quote(build_id)}/relationships/betaGroups",
        {
            "data": [
                {
                    "type": "betaGroups",
                    "id": beta_group_id,
                }
            ]
        },
    )


def _testflight_records(
    response: dict[str, Any], app_id: str, build_number: str, beta_group_id: str
) -> tuple[dict[str, dict[str, Any]], list[str]]:
    included = {
        (resource["type"], str(resource["id"])): resource
        for resource in response.get("included", [])
    }
    records: dict[str, dict[str, Any]] = {}
    pending: list[str] = []
    for build in response.get("data", []):
        attributes = build.get("attributes", {})
        relationships = build.get("relationships", {})
        if str(attributes.get("version")) != build_number:
            raise AppStoreConnectError("Apple returned a different build number")
        app = relationships.get("app", {}).get("data")
        if not app:
            pending.append("app identity")
            continue
        if str(app.get("id")) != app_id:
            raise AppStoreConnectError("Apple returned a build for a different app")
        prerelease_id = relationships.get("preReleaseVersion", {}).get("data")
        prerelease = included.get(
            ("preReleaseVersions", str((prerelease_id or {}).get("id"))), {}
        ).get("attributes", {})
        platform = prerelease.get("platform")
        if platform not in TESTFLIGHT_PLATFORMS:
            pending.append("platform metadata")
            continue
        if platform in records:
            raise AppStoreConnectError(f"Multiple {platform} builds match the Cloud number")
        state = attributes.get("processingState")
        if state in {"FAILED", "INVALID"}:
            raise AppStoreConnectError(f"{platform} build processing is {state}")
        if attributes.get("expired") is True:
            raise AppStoreConnectError(f"{platform} build is expired")
        detail_id = relationships.get("buildBetaDetail", {}).get("data")
        detail = included.get(
            ("buildBetaDetails", str((detail_id or {}).get("id"))), {}
        ).get("attributes", {})
        internal_state = detail.get("internalBuildState")
        if internal_state in {"MISSING_EXPORT_COMPLIANCE", "PROCESSING_EXCEPTION", "EXPIRED"}:
            raise AppStoreConnectError(f"{platform} internal testing is {internal_state}")
        group = included.get(("betaGroups", beta_group_id), {}).get("attributes", {})
        group_ids = {
            str(item.get("id"))
            for item in (relationships.get("betaGroups", {}).get("data") or [])
        }
        if beta_group_id in group_ids and group.get("isInternalGroup") is False:
            raise AppStoreConnectError("The requested testing group is not internal")
        if (
            state != "VALID"
            or attributes.get("expired") is not False
            or not prerelease.get("version")
            or internal_state not in USABLE_INTERNAL_STATES
            or beta_group_id not in group_ids
            or group.get("isInternalGroup") is not True
        ):
            pending.append(f"{platform} processing/testing/group metadata")
        records[platform] = {
            "id": str(build.get("id", ""))[:80],
            "version": str(prerelease.get("version") or "")[:40],
            "internalState": str(internal_state or "PENDING")[:40],
        }
    pending.extend(sorted(TESTFLIGHT_PLATFORMS - records.keys()))
    if len({record["version"] for record in records.values() if record["version"]}) > 1:
        raise AppStoreConnectError("iOS and tvOS marketing versions differ")
    return records, pending


def verify_testflight(
    client: AppStoreConnectClient,
    build_run_id: str,
    app_id: str,
    beta_group_id: str,
    timeout_seconds: int,
    poll_seconds: int,
    expected_source_sha: str | None = None,
) -> int:
    """Read actual processed builds and group links; never upload or assign anything."""
    if timeout_seconds < 0 or poll_seconds <= 0:
        raise AppStoreConnectError(
            "Verification timeout must be nonnegative and poll positive"
        )
    deadline = time.monotonic() + timeout_seconds
    while True:
        run_query = urllib.parse.urlencode(
            {"fields[ciBuildRuns]": "number,sourceCommit"}
        )
        run_id = urllib.parse.quote(build_run_id, safe="")
        run = client.request("GET", f"/ciBuildRuns/{run_id}?{run_query}")
        run_attributes = run.get("data", {}).get("attributes", {})
        number = str(run_attributes.get("number") or "")
        source_sha = str(
            (run_attributes.get("sourceCommit") or {}).get("commitSha") or ""
        )
        if (
            expected_source_sha and source_sha
            and source_sha.lower() != expected_source_sha.lower()
        ):
            raise AppStoreConnectError(
                "Xcode Cloud built a different source commit than validated CI"
            )
        pending = []
        records: dict[str, dict[str, Any]] = {}
        if not number.isdecimal() or (expected_source_sha and not source_sha):
            pending.append("Cloud build/source metadata")
        else:
            query = urllib.parse.urlencode(
                {
                    "filter[app]": app_id,
                    "filter[version]": number,
                    "include": "app,preReleaseVersion,betaGroups,buildBetaDetail",
                    "fields[builds]": (
                        "version,processingState,expired,app,"
                        "preReleaseVersion,betaGroups,buildBetaDetail"
                    ),
                    "fields[apps]": "bundleId",
                    "fields[preReleaseVersions]": "version,platform",
                    "fields[betaGroups]": "name,isInternalGroup",
                    "fields[buildBetaDetails]": "internalBuildState",
                    "limit": "200",
                }
            )
            response = client.request("GET", f"/builds?{query}")
            if response.get("links", {}).get("next"):
                raise AppStoreConnectError(
                    "Build query is ambiguous; additional result pages exist"
                )
            records, pending = _testflight_records(
                response, app_id, number, beta_group_id
            )
        if not pending:
            print(
                f"Verified TestFlight Cloud build {number}; "
                f"source={source_sha[:12] or 'unavailable'}."
            )
            for platform in sorted(TESTFLIGHT_PLATFORMS):
                record = records[platform]
                print(
                    f"{platform}: version={record['version']}, build={number}, "
                    f"id={record['id']}, processing=VALID, internal={record['internalState']}, "
                    f"group={beta_group_id[:80]} (internal)."
                )
            print(
                "Both platform builds are processed and assigned "
                "to the requested internal group."
            )
            return 0
        print(
            f"TestFlight verification pending: {', '.join(sorted(set(pending)))}.",
            flush=True,
        )
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise AppStoreConnectError(
                "Timed out verifying both platform builds and internal group assignment"
            )
        time.sleep(min(poll_seconds, remaining))


def _download_tvos_ipa(
    client: AppStoreConnectClient, build_run_id: str, work_dir: Path
) -> Path:
    response = client.request(
        "GET",
        f"/ciBuildRuns/{urllib.parse.quote(build_run_id)}/actions?limit=200",
    )
    archive_actions = [
        action
        for action in response.get("data", [])
        if action.get("attributes", {}).get("actionType") == "ARCHIVE"
        and "tvos" in str(
            action.get("attributes", {}).get("name", "")
        ).lower()
    ]
    if len(archive_actions) != 1:
        raise AppStoreConnectError(
            "Xcode Cloud returned no unique tvOS Archive action"
        )

    action_id = urllib.parse.quote(str(archive_actions[0]["id"]))
    artifacts = client.request(
        "GET", f"/ciBuildActions/{action_id}/artifacts?limit=200"
    )
    exports = [
        artifact
        for artifact in artifacts.get("data", [])
        if artifact.get("attributes", {}).get("fileType")
        == "ARCHIVE_EXPORT"
    ]
    if len(exports) != 1:
        raise AppStoreConnectError(
            "The tvOS Archive action has no unique App Store export"
        )

    attributes = exports[0].get("attributes", {})
    download_url = str(attributes.get("downloadUrl") or "")
    if not download_url:
        raise AppStoreConnectError(
            "The tvOS App Store export has no download URL"
        )

    export_path = work_dir / "tvos-app-store.zip"
    try:
        with urllib.request.urlopen(download_url, timeout=120) as source:
            with export_path.open("wb") as destination:
                shutil.copyfileobj(source, destination)
    except urllib.error.URLError as error:
        raise AppStoreConnectError(
            f"Unable to download the tvOS App Store export: {error.reason}"
        ) from error

    extract_dir = work_dir / "export"
    with zipfile.ZipFile(export_path) as archive:
        archive.extractall(extract_dir)
    ipa_paths = list(extract_dir.rglob("*.ipa"))
    if len(ipa_paths) != 1:
        raise AppStoreConnectError(
            "The tvOS App Store export must contain exactly one IPA"
        )
    return ipa_paths[0]


def _upload_ipa_parts(ipa_path: Path, operations: list[dict[str, Any]]) -> None:
    with ipa_path.open("rb") as ipa:
        for operation in operations:
            offset = int(operation["offset"])
            length = int(operation["length"])
            ipa.seek(offset)
            data = ipa.read(length)
            if len(data) != length:
                raise AppStoreConnectError(
                    "Unable to read a complete tvOS IPA upload part"
                )
            headers = {
                str(header["name"]): str(header["value"])
                for header in operation.get("requestHeaders", [])
            }
            request = urllib.request.Request(
                str(operation["url"]),
                data=data,
                method=str(operation["method"]),
                headers=headers,
            )
            try:
                with urllib.request.urlopen(request, timeout=180) as response:
                    response.read()
            except urllib.error.URLError as error:
                raise AppStoreConnectError(
                    f"Unable to upload a tvOS IPA part: {error.reason}"
                ) from error


def _md5(ipa_path: Path) -> str:
    digest = hashlib.md5()
    with ipa_path.open("rb") as ipa:
        for chunk in iter(lambda: ipa.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def publish_tvos(
    client: AppStoreConnectClient,
    build_run_id: str,
    app_id: str,
    beta_group_id: str,
    timeout_seconds: int,
    poll_seconds: int,
) -> int:
    with tempfile.TemporaryDirectory(
        prefix="astro-adventure-tvos-"
    ) as temporary_directory:
        ipa_path = _download_tvos_ipa(
            client, build_run_id, Path(temporary_directory)
        )
        marketing_version, build_number = _ipa_metadata(ipa_path)
        print(
            f"Prepared tvOS {marketing_version} build {build_number}.",
            flush=True,
        )

        existing_build = _existing_tvos_build(
            client, app_id, marketing_version, build_number
        )
        if existing_build:
            _assign_beta_group(client, existing_build, beta_group_id)
            print(
                "The valid tvOS build already exists and is assigned to "
                "the internal TestFlight group."
            )
            return 0

        file_size = ipa_path.stat().st_size
        upload = client.request(
            "POST",
            "/buildUploads",
            {
                "data": {
                    "type": "buildUploads",
                    "attributes": {
                        "cfBundleShortVersionString": marketing_version,
                        "cfBundleVersion": build_number,
                        "platform": "TV_OS",
                    },
                    "relationships": {
                        "app": {
                            "data": {
                                "type": "apps",
                                "id": app_id,
                            }
                        }
                    },
                }
            },
        )
        build_id = str(upload.get("data", {}).get("id") or "")
        if not build_id:
            raise AppStoreConnectError(
                "Apple accepted the tvOS upload but returned no build ID"
            )

        reservation = client.request(
            "POST",
            "/buildUploadFiles",
            {
                "data": {
                    "type": "buildUploadFiles",
                    "attributes": {
                        "assetType": "ASSET",
                        "fileName": ipa_path.name,
                        "fileSize": file_size,
                        "uti": "com.apple.ipa",
                    },
                    "relationships": {
                        "buildUpload": {
                            "data": {
                                "type": "buildUploads",
                                "id": build_id,
                            }
                        }
                    },
                }
            },
        )
        upload_file = reservation.get("data", {})
        upload_file_id = str(upload_file.get("id") or "")
        operations = upload_file.get("attributes", {}).get(
            "uploadOperations", []
        )
        if not upload_file_id or not operations:
            raise AppStoreConnectError(
                "Apple returned no tvOS IPA upload operations"
            )

        _upload_ipa_parts(ipa_path, operations)
        client.request(
            "PATCH",
            f"/buildUploadFiles/{urllib.parse.quote(upload_file_id)}",
            {
                "data": {
                    "type": "buildUploadFiles",
                    "id": upload_file_id,
                    "attributes": {
                        "uploaded": True,
                        "sourceFileChecksums": {
                            "file": {
                                "algorithm": "MD5",
                                "hash": _md5(ipa_path),
                            }
                        },
                    },
                }
            },
        )
        print("Uploaded the signed tvOS IPA for Apple processing.", flush=True)

        deadline = time.monotonic() + timeout_seconds
        while True:
            response = client.request(
                "GET",
                f"/buildUploads/{urllib.parse.quote(build_id)}",
            )
            attributes = response.get("data", {}).get("attributes", {})
            state, errors = _state_value(attributes)
            print(f"tvOS upload state: {state or 'PENDING'}", flush=True)
            if state == "COMPLETE":
                _assign_beta_group(client, build_id, beta_group_id)
                print(
                    "Assigned the valid tvOS build to the internal "
                    "TestFlight group."
                )
                return 0
            if state == "FAILED":
                detail = (
                    str(errors[0].get("description"))
                    if errors and isinstance(errors[0], dict)
                    else "Apple reported no error detail"
                )
                raise AppStoreConnectError(
                    f"Apple rejected the tvOS upload: {detail}"
                )
            if time.monotonic() >= deadline:
                raise AppStoreConnectError(
                    "Timed out waiting for Apple to process the tvOS upload"
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

    publish_parser = subparsers.add_parser(
        "publish-tvos",
        help="Publish Xcode Cloud's signed tvOS export to TestFlight",
    )
    publish_parser.add_argument("--build-run-id", required=True)
    publish_parser.add_argument("--app-id", required=True)
    publish_parser.add_argument("--beta-group-id", required=True)
    publish_parser.add_argument(
        "--timeout-seconds", type=int, default=1200
    )
    publish_parser.add_argument("--poll-seconds", type=int, default=15)
    verify_parser = subparsers.add_parser(
        "verify-testflight",
        help="Read and verify processed iOS/tvOS internal TestFlight builds",
    )
    verify_parser.add_argument("--build-run-id", required=True)
    verify_parser.add_argument("--app-id", required=True)
    verify_parser.add_argument("--beta-group-id", required=True)
    verify_parser.add_argument("--expected-source-sha")
    verify_parser.add_argument("--timeout-seconds", type=int, default=600)
    verify_parser.add_argument("--poll-seconds", type=int, default=15)
    return parser


def main() -> int:
    arguments = _parser().parse_args()
    client = _client_from_environment()

    if arguments.command == "trigger":
        return trigger(client, arguments.workflow_id, arguments.branch)
    if arguments.command == "wait":
        return wait_for_build(
            client,
            arguments.build_run_id,
            arguments.timeout_seconds,
            arguments.poll_seconds,
        )
    if arguments.command == "verify-testflight":
        return verify_testflight(
            client,
            arguments.build_run_id,
            arguments.app_id,
            arguments.beta_group_id,
            arguments.timeout_seconds,
            arguments.poll_seconds,
            arguments.expected_source_sha,
        )
    return publish_tvos(
        client,
        arguments.build_run_id,
        arguments.app_id,
        arguments.beta_group_id,
        arguments.timeout_seconds,
        arguments.poll_seconds,
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AppStoreConnectError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)

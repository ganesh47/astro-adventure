import copy
import contextlib
import importlib.util
import io
import pathlib
import plistlib
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


MODULE_PATH = (
    pathlib.Path(__file__).parents[2] / "ci_scripts" / "xcode_cloud.py"
)
SPEC = importlib.util.spec_from_file_location("xcode_cloud", MODULE_PATH)
assert SPEC and SPEC.loader
xcode_cloud = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = xcode_cloud
SPEC.loader.exec_module(xcode_cloud)


class FakeClient:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.requests = []

    def request(self, method, path, payload=None):
        self.requests.append((method, path, payload))
        return next(self.responses)


class XcodeCloudTests(unittest.TestCase):
    def cloud_record(self, source_sha="validated-source"):
        return {"data": {"attributes": {
            "number": 22, "sourceCommit": {"commitSha": source_sha}
        }}}

    def testflight_response(self):
        response = {"data": [], "included": [
            {"type": "betaGroups", "id": "internal-group",
             "attributes": {"isInternalGroup": True}},
        ]}
        for platform in ("IOS", "TV_OS"):
            response["data"].append({
                "type": "builds", "id": f"{platform}-build",
                "attributes": {"version": "22", "processingState": "VALID", "expired": False},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": "app-id"}},
                    "preReleaseVersion": {"data": {
                        "type": "preReleaseVersions", "id": platform}},
                    "buildBetaDetail": {"data": {
                        "type": "buildBetaDetails", "id": platform}},
                    "betaGroups": {"data": [{"type": "betaGroups", "id": "internal-group"}]},
                },
            })
            response["included"].extend([
                {"type": "preReleaseVersions", "id": platform,
                 "attributes": {"version": "0.2.0", "platform": platform}},
                {"type": "buildBetaDetails", "id": platform,
                 "attributes": {"internalBuildState": "IN_BETA_TESTING"}},
            ])
        return response

    def verify(self, client, timeout=0):
        with contextlib.redirect_stdout(io.StringIO()):
            return xcode_cloud.verify_testflight(
                client, "cloud-run", "app-id", "internal-group", timeout, 15,
                "validated-source",
            )

    def test_verification_accepts_both_processed_internal_platforms_get_only(self):
        response = self.testflight_response()
        response["included"][2]["attributes"]["internalBuildState"] = "READY_FOR_BETA_TESTING"
        client = FakeClient([self.cloud_record(), response])
        self.assertEqual(self.verify(client), 0)
        self.assertTrue(all(
            method == "GET" and payload is None
            for method, _, payload in client.requests
        ))
        self.assertIn("filter%5Bapp%5D=app-id", client.requests[1][1])
        self.assertIn("filter%5Bversion%5D=22", client.requests[1][1])

    def test_verification_polls_pending_processing_and_group_assignment(self):
        for pending_kind in (
            "processing", "group", "internal-state", "missing-build", "missing-version"
        ):
            with self.subTest(pending_kind=pending_kind):
                pending = self.testflight_response()
                if pending_kind == "processing":
                    pending["data"][0]["attributes"]["processingState"] = "PROCESSING"
                elif pending_kind == "group":
                    pending["data"][0]["relationships"]["betaGroups"]["data"] = []
                elif pending_kind == "internal-state":
                    pending["included"][2]["attributes"]["internalBuildState"] = "PROCESSING"
                elif pending_kind == "missing-version":
                    pending["included"][3]["attributes"]["version"] = None
                else:
                    pending["data"].pop()
                client = FakeClient([
                    self.cloud_record(), pending,
                    self.cloud_record(), self.testflight_response(),
                ])
                with (
                    mock.patch.object(xcode_cloud.time, "monotonic", return_value=0),
                    mock.patch.object(xcode_cloud.time, "sleep") as sleep,
                ):
                    self.assertEqual(self.verify(client, timeout=60), 0)
                sleep.assert_called_once_with(15)
                self.assertEqual(len(client.requests), 4)

    def test_verification_rejects_wrong_platform_and_wrong_group_with_bounded_timeout(self):
        for wrong_kind in ("platform", "group", "missing-build"):
            with self.subTest(wrong_kind=wrong_kind):
                response = self.testflight_response()
                if wrong_kind == "platform":
                    response["included"][3]["attributes"]["platform"] = "MAC_OS"
                elif wrong_kind == "group":
                    groups = response["data"][1]["relationships"]["betaGroups"]["data"]
                    groups[0]["id"] = "other-group"
                else:
                    response["data"].pop()
                client = FakeClient([self.cloud_record(), response])
                with mock.patch.object(xcode_cloud.time, "sleep") as sleep:
                    with self.assertRaisesRegex(xcode_cloud.AppStoreConnectError, "Timed out"):
                        self.verify(client)
                sleep.assert_not_called()

    def test_verification_rejects_wrong_build_app_and_marketing_version(self):
        for wrong_kind in ("build", "app", "version", "duplicate", "external-group"):
            with self.subTest(wrong_kind=wrong_kind):
                response = self.testflight_response()
                if wrong_kind == "build":
                    response["data"][0]["attributes"]["version"] = "21"
                elif wrong_kind == "app":
                    response["data"][0]["relationships"]["app"]["data"]["id"] = "other-app"
                elif wrong_kind == "version":
                    response["included"][3]["attributes"]["version"] = "0.3.0"
                elif wrong_kind == "duplicate":
                    response["data"].append(copy.deepcopy(response["data"][0]))
                else:
                    response["included"][0]["attributes"]["isInternalGroup"] = False
                with self.assertRaises(xcode_cloud.AppStoreConnectError):
                    self.verify(FakeClient([self.cloud_record(), response]))

    def test_verification_rejects_invalid_failed_expired_and_export_compliance(self):
        for bad_state in ("INVALID", "FAILED", "EXPIRED", "MISSING_EXPORT_COMPLIANCE"):
            with self.subTest(bad_state=bad_state):
                response = self.testflight_response()
                if bad_state in ("INVALID", "FAILED"):
                    response["data"][0]["attributes"]["processingState"] = bad_state
                elif bad_state == "EXPIRED":
                    response["data"][0]["attributes"]["expired"] = True
                else:
                    response["included"][2]["attributes"]["internalBuildState"] = bad_state
                expected = bad_state if bad_state != "EXPIRED" else "expired"
                with self.assertRaisesRegex(xcode_cloud.AppStoreConnectError, expected):
                    self.verify(FakeClient([self.cloud_record(), response]))

    def test_verification_checks_cloud_source_and_polls_missing_source(self):
        client = FakeClient([self.cloud_record("other-source")])
        with self.assertRaisesRegex(xcode_cloud.AppStoreConnectError, "different source commit"):
            self.verify(client)
        self.assertEqual(len(client.requests), 1)
        missing = self.cloud_record()
        del missing["data"]["attributes"]["sourceCommit"]
        client = FakeClient([missing, self.cloud_record(), self.testflight_response()])
        with (
            mock.patch.object(xcode_cloud.time, "monotonic", return_value=0),
            mock.patch.object(xcode_cloud.time, "sleep") as sleep,
        ):
            self.assertEqual(self.verify(client, timeout=60), 0)
        sleep.assert_called_once_with(15)
        self.assertEqual(len(client.requests), 3)

    def test_verification_rejects_paginated_ambiguous_query(self):
        response = self.testflight_response()
        response["links"] = {"next": "another-page"}
        with self.assertRaisesRegex(xcode_cloud.AppStoreConnectError, "additional result pages"):
            self.verify(FakeClient([self.cloud_record(), response]))

    def test_individual_key_claims_use_user_subject(self):
        claims = xcode_cloud._claims(None, 100)

        self.assertEqual(claims["sub"], "user")
        self.assertNotIn("iss", claims)
        self.assertEqual(claims["exp"], 1000)

    def test_team_key_claims_use_issuer(self):
        claims = xcode_cloud._claims("issuer", 100)

        self.assertEqual(claims["iss"], "issuer")
        self.assertNotIn("sub", claims)

    def test_build_payload_can_pin_a_branch_reference(self):
        payload = xcode_cloud._build_run_payload(
            "workflow-id", "reference-id"
        )
        relationships = payload["data"]["relationships"]

        self.assertEqual(
            relationships["workflow"]["data"]["id"], "workflow-id"
        )
        self.assertEqual(
            relationships["sourceBranchOrTag"]["data"]["id"],
            "reference-id",
        )

    def test_branch_lookup_matches_canonical_name(self):
        client = FakeClient(
            [
                {"data": {"id": "repository-id"}},
                {
                    "data": [
                        {
                            "id": "reference-id",
                            "attributes": {
                                "canonicalName": "refs/heads/main",
                                "isDeleted": False,
                                "kind": "BRANCH",
                            },
                        }
                    ]
                },
            ]
        )

        reference = xcode_cloud._branch_reference_id(
            client, "workflow-id", "main"
        )

        self.assertEqual(reference, "reference-id")
        self.assertEqual(client.requests[0][0], "GET")
        self.assertIn("/ciWorkflows/workflow-id/repository", client.requests[0][1])

    def test_state_value_reads_build_upload_state(self):
        state, errors = xcode_cloud._state_value(
            {
                "state": {
                    "state": "FAILED",
                    "errors": [{"description": "Invalid bundle"}],
                }
            }
        )

        self.assertEqual(state, "FAILED")
        self.assertEqual(errors[0]["description"], "Invalid bundle")

    def test_ipa_metadata_reads_versions(self):
        with tempfile.TemporaryDirectory() as directory:
            ipa_path = pathlib.Path(directory) / "Astro Adventure.ipa"
            with zipfile.ZipFile(ipa_path, "w") as archive:
                archive.writestr(
                    "Payload/Astro Adventure.app/Info.plist",
                    plistlib.dumps(
                        {
                            "CFBundleShortVersionString": "0.2.0",
                            "CFBundleVersion": "12",
                        }
                    ),
                )

            marketing_version, build_number = xcode_cloud._ipa_metadata(
                ipa_path
            )

        self.assertEqual(marketing_version, "0.2.0")
        self.assertEqual(build_number, "12")

    def test_existing_tvos_build_matches_platform_and_version(self):
        client = FakeClient(
            [
                {
                    "data": [
                        {
                            "id": "tvos-build-id",
                            "attributes": {
                                "processingState": "VALID",
                                "version": "12",
                            },
                            "relationships": {
                                "preReleaseVersion": {
                                    "data": {
                                        "type": "preReleaseVersions",
                                        "id": "prerelease-id",
                                    }
                                }
                            },
                        }
                    ],
                    "included": [
                        {
                            "type": "preReleaseVersions",
                            "id": "prerelease-id",
                            "attributes": {
                                "platform": "TV_OS",
                                "version": "0.2.0",
                            },
                        }
                    ],
                }
            ]
        )

        build_id = xcode_cloud._existing_tvos_build(
            client, "app-id", "0.2.0", "12"
        )

        self.assertEqual(build_id, "tvos-build-id")
        self.assertIn("filter%5Bversion%5D=12", client.requests[0][1])


if __name__ == "__main__":
    unittest.main()

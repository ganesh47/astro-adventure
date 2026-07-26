import importlib.util
import pathlib
import plistlib
import sys
import tempfile
import unittest
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

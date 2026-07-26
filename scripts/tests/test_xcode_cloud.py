import importlib.util
import pathlib
import sys
import unittest


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


if __name__ == "__main__":
    unittest.main()

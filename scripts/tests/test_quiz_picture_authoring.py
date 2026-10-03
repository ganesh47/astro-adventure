import importlib.util
from pathlib import Path
import unittest

_spec = importlib.util.spec_from_file_location(
    "quiz_picture_authoring", Path(__file__).resolve().parents[1] / "quiz_picture_authoring.py")
_module = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_module)
preserve = _module.preserve_quiz_pictures


class PictureAuthoringTests(unittest.TestCase):
    def quiz(self):
        return {"prompt": "Which object?", "correctChoiceID": "star", "choices": [
            {"id": "star", "text": "A star", "picture": {"scene": "star", "label": "A star"}},
            {"id": "moon", "text": "A moon", "picture": {"scene": "moon", "label": "A moon"}},
        ]}

    def test_reordering_and_correctness_do_not_change_authored_meaning(self):
        old = self.quiz()
        new = self.quiz()
        new["correctChoiceID"] = "moon"
        new["choices"].reverse()
        for choice in new["choices"]:
            choice.pop("picture")
        preserve([old], [new])
        self.assertEqual(new["choices"][0]["picture"]["scene"], "moon")
        self.assertEqual(new["choices"][1]["picture"]["scene"], "star")
        new["choices"][0]["picture"]["label"] = "Changed"
        self.assertEqual(old["choices"][1]["picture"]["label"], "A moon")

    def test_changed_text_or_question_requires_fresh_semantic_review(self):
        for field in ("text", "prompt"):
            old = self.quiz()
            new = self.quiz()
            if field == "text":
                new["choices"][0]["text"] = "Closest planet to the Sun"
            else:
                new["prompt"] = "A different context?"
            with self.assertRaises(ValueError):
                preserve([old], [new])

    def test_ambiguous_or_missing_metadata_is_rejected(self):
        old = self.quiz()
        ambiguous = self.quiz()
        ambiguous["choices"][0]["picture"]["scene"] = "orbit"
        with self.assertRaises(ValueError):
            preserve([old, ambiguous], [self.quiz()])
        old["choices"][0].pop("picture")
        with self.assertRaises(ValueError):
            preserve([old], [self.quiz()])

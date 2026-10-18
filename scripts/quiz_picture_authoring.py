"""Retain reviewed, contextual picture metadata when re-authoring question copy."""
from __future__ import annotations

import copy


def preserve_quiz_pictures(previous: object, authored: object) -> None:
    """Match the complete authored proposal, never its answer position/correctness.

    Changed/new copy requires an explicit picture review rather than a stale picture
    or a generic fallback. Mutates only the newly generated catalog.
    """
    reviewed: dict[tuple[str, str, str], dict] = {}

    def quizzes(value: object):
        if isinstance(value, list):
            for item in value:
                yield from quizzes(item)
        elif isinstance(value, dict):
            if "choices" in value and "correctChoiceID" in value:
                yield value
            else:
                for item in value.values():
                    yield from quizzes(item)

    for quiz in quizzes(previous):
        for choice in quiz["choices"]:
            picture = choice.get("picture")
            if not isinstance(picture, dict) or not picture.get("scene") or not picture.get("label"):
                raise ValueError(f"Picture review missing for {choice['id']}")
            key = (quiz["prompt"], choice["id"], choice["text"])
            if key in reviewed and reviewed[key] != picture:
                raise ValueError(f"Ambiguous authored picture context for {choice['id']}")
            reviewed[key] = picture

    for quiz in quizzes(authored):
        for choice in quiz["choices"]:
            key = (quiz["prompt"], choice["id"], choice["text"])
            if key not in reviewed:
                raise ValueError(f"Review a picture for new or changed choice {choice['id']}: {choice['text']}")
            choice["picture"] = copy.deepcopy(reviewed[key])

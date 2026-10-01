#!/usr/bin/env python3
"""Build the eight silent, offline video lessons from pinned NASA media.

Requires FFmpeg 7.1+ with libx264. Pass --ffmpeg if it is not on PATH.
Raw downloads stay in a temporary/cache directory, outside the repository.
No YouTube extraction, streaming, stock music, or hosted infrastructure is used.
The age-specific narration, captions and checkpoints live in video-lessons.json.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SOURCE_RECORDS = ROOT / "scripts/video_media_sources.json"
OUTPUT = ROOT / "Sources/AstroUI/Resources/LearningVideos"


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def generate(record: dict, cache: Path, ffmpeg: str, output: Path) -> dict:
    planet = record["destinationID"]
    source = cache / f"{planet}.mp4"
    if not source.exists():
        temporary = source.with_suffix(".downloading")
        try:
            urllib.request.urlretrieve(record["sourceURL"], temporary)
            temporary.replace(source)
        finally:
            temporary.unlink(missing_ok=True)
    if digest(source) != record["sourceSHA256"]:
        raise ValueError(f"{planet}: source checksum changed; review before regenerating")
    images = [ROOT / image["path"] for image in record["images"]]
    if not all(image.is_file() for image in images):
        raise ValueError(f"{planet}: a credited source image is missing")
    for image, pinned in zip(images, record["images"]):
        if digest(image) != pinned["sha256"]:
            raise ValueError(f"{planet}: image {image.name} changed; review before regenerating")
    destination = output / f"{planet}-lesson.mp4"
    temporary = destination.with_suffix(".building.mp4")
    crop = f"crop={record['crop']}," if record["crop"] else ""
    # A single still frame becomes a 20-second gentle camera move. The pixels are
    # photograph-derived; no additional terrain/cloud movement is fabricated.
    photo = (
        "scale=2560:1440:force_original_aspect_ratio=decrease,"
        "pad=2560:1440:(ow-iw)/2:(oh-ih)/2:black,setsar=1,"
        "zoompan=z='1+0.035*on/599':x='iw/2-iw/zoom/2':"
        "y='ih/2-ih/zoom/2':d=600:s=1280x720:fps=30,"
        "trim=duration=20,setpts=PTS-STARTPTS,format=yuv420p"
    )
    image_crops = [f"crop={image['crop']}," if image.get("crop") else "" for image in record["images"]]
    graph = (
        f"[0:v]{crop}scale=1280:720:force_original_aspect_ratio=decrease,"
        "pad=1280:720:(ow-iw)/2:(oh-ih)/2:black,setsar=1,"
        "fps=30,trim=duration=20,setpts=PTS-STARTPTS,format=yuv420p[a];"
        f"[1:v]{image_crops[0]}{photo}[b];[2:v]{image_crops[1]}{photo}[c];"
        "[a][b][c]concat=n=3:v=1:a=0[out]"
    )
    command = [
        ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
        "-stream_loop", "-1", "-ss", str(record["sourceStartTime"]), "-i", str(source),
        "-i", str(images[0]), "-i", str(images[1]), "-filter_complex", graph,
        "-map", "[out]", "-an", "-t", "60", "-frames:v", "1800",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "28",
        "-pix_fmt", "yuv420p", "-profile:v", "main", "-level", "3.1",
        "-threads", "1", "-filter_complex_threads", "1", "-map_metadata", "-1",
        "-metadata", "creation_time=1970-01-01T00:00:00Z",
        "-movflags", "+faststart", str(temporary),
    ]
    try:
        subprocess.run(command, check=True)
        # Decode every frame: a file merely existing is not sufficient verification.
        subprocess.run(
            [ffmpeg, "-hide_banner", "-loglevel", "error", "-i", str(temporary),
             "-map", "0:v:0", "-f", "null", "-"], check=True
        )
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    result = {"destinationID": planet, "path": str(destination.relative_to(ROOT)),
              "bytes": destination.stat().st_size, "sha256": digest(destination)}
    print(json.dumps(result), flush=True)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ffmpeg", default=os.environ.get("ASTRO_VIDEO_FFMPEG") or shutil.which("ffmpeg"))
    parser.add_argument("--cache-dir", type=Path, default=Path(tempfile.gettempdir()) / "astro-adventure-nasa-sources")
    parser.add_argument("--planet", choices=["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"])
    parser.add_argument("--jobs", type=int, default=2)
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error("FFmpeg is required; pass --ffmpeg /path/to/ffmpeg")
    if ROOT == args.cache_dir.resolve() or ROOT in args.cache_dir.resolve().parents:
        parser.error("--cache-dir must be outside the repository")
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    config = json.loads(SOURCE_RECORDS.read_text())
    records = [r for r in config["records"] if not args.planet or r["destinationID"] == args.planet]
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(lambda r: generate(r, args.cache_dir, args.ffmpeg, OUTPUT), records))
    total = sum(path.stat().st_size for path in OUTPUT.glob("*-lesson.mp4"))
    if total >= 100 * 1024 * 1024:
        raise ValueError("Bundled learning videos exceed the 100 MiB budget")
    print(f"Verified {len(results)} video lesson(s); aggregate {total / (1024 * 1024):.2f} MiB")


if __name__ == "__main__":
    main()

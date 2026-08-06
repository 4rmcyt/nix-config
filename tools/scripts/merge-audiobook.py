#!/usr/bin/env python3
"""Merge a folder of numbered mp3 fragments into a single m4b with chapters.

Usage: merge-audiobook.py <book_dir> <output.m4b>

Groups files by their "<part>_<chapter>_<fragment>" (or "<chapter>_<fragment>",
or flat) numeric prefix into chapters, concatenates all fragments into one
continuous audio stream, and writes chapter markers at each group boundary.
Pulls title/author/genre/description/cover from metadata.json + cover.* if present.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

def ffprobe_duration(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return float(out)

def ffprobe_audio_params(path: Path) -> tuple[int, int]:
    """Returns (channels, bitrate_bps) of the source, for matching on encode."""
    channels_out = subprocess.run(
        ["ffprobe", "-v", "quiet", "-select_streams", "a:0",
         "-show_entries", "stream=channels",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    channels = int(channels_out) if channels_out else 2

    # Stream-level bit_rate is often "N/A" for mp3 (esp. VBR); the format-level
    # (container) bit_rate is always populated, so use that.
    bitrate_out = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=bit_rate",
         "-of", "csv=p=0", path.as_posix()],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    bitrate = int(bitrate_out) if bitrate_out.isdigit() else 128000
    return channels, bitrate

def chapter_group(name: str) -> str:
    stem = Path(name).stem
    parts = re.split(r"[_\-. ]", stem)
    nums = [p for p in parts if p.isdigit()]
    if len(nums) >= 2:
        return "_".join(nums[:-1])  # drop the last (fragment) component
    return stem  # no recognizable grouping -> each file is its own chapter

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    book_dir = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    files = sorted(
        p for p in book_dir.iterdir()
        if not p.name.startswith(".") and p.name != "raw_audio.m4a"
        and p.suffix.lower() in (".mp3", ".m4a", ".flac", ".wav", ".ogg")
    )
    if not files:
        sys.exit(f"No audio files found in {book_dir}")

    print(f"{len(files)} audio files found")

    channels, src_bitrate = ffprobe_audio_params(files[0])
    target_bitrate_k = max(round(src_bitrate / 1000), 32)
    print(f"Source: {channels}ch, {target_bitrate_k}k -> matching on encode")

    meta = {}
    meta_path = book_dir / "metadata.json"
    if meta_path.exists():
        meta = json.loads(meta_path.read_text())

    title = meta.get("title") or book_dir.name
    authors = ", ".join(meta.get("authors") or []) or None
    genres = ", ".join(meta.get("genres") or []) or None
    year = meta.get("publishedYear")
    description = meta.get("description") or ""
    description = re.sub(r"<[^>]+>", "", description).strip()

    cover_path = None
    for ext in (".jpg", ".jpeg", ".png", ".webp"):
        cand = book_dir / f"cover{ext}"
        if cand.exists():
            cover_path = cand
            break

    # Group files into chapters, compute durations and cumulative offsets.
    groups: list[tuple[str, list[Path]]] = []
    for f in files:
        g = chapter_group(f.name)
        if groups and groups[-1][0] == g:
            groups[-1][1].append(f)
        else:
            groups.append((g, [f]))

    print(f"{len(groups)} chapters detected")

    scratch = out_path.parent
    scratch.mkdir(parents=True, exist_ok=True)

    concat_list = scratch / "concat_list.txt"
    with concat_list.open("w") as fh:
        for f in files:
            escaped = str(f.resolve()).replace("'", "'\\''")
            fh.write(f"file '{escaped}'\n")

    ffmeta = scratch / "ffmeta.txt"
    lines = [";FFMETADATA1", f"title={title}"]
    if authors:
        lines.append(f"artist={authors}")
    lines.append(f"album={title}")
    if genres:
        lines.append(f"genre={genres}")
    if year:
        lines.append(f"date={year}")
    if description:
        oneline = description.replace("\n", " ").replace("\\", "\\\\").replace("=", "\\=").replace(";", "\\;")
        lines.append(f"comment={oneline}")
    lines.append("")

    cursor_ms = 0
    for idx, (_g, group_files) in enumerate(groups, start=1):
        dur_ms = 0
        for f in group_files:
            dur_ms += round(ffprobe_duration(f) * 1000)
        lines += [
            "[CHAPTER]",
            "TIMEBASE=1/1000",
            f"START={cursor_ms}",
            f"END={cursor_ms + dur_ms}",
            f"title=Chapter {idx}",
            "",
        ]
        cursor_ms += dur_ms

    ffmeta.write_text("\n".join(lines))
    print(f"Total duration: {cursor_ms / 1000 / 60:.1f} min")

    # Stage 1: concat-decode all fragments to WAV, pipe into fdkaac (libfdk_aac
    # standalone CLI -- ffmpeg-full isn't built with libfdk_aac since its license
    # is GPL-incompatible, but the encoder itself is faster and higher quality
    # than ffmpeg's native "aac" encoder, so it's worth shelling out to).
    raw_aac = scratch / ".raw_audio.m4a"
    decode = subprocess.Popen(
        ["ffmpeg", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(concat_list), "-f", "wav", "-"],
        stdout=subprocess.PIPE,
    )
    encode = subprocess.run(
        ["nix", "shell", "nixpkgs#fdk-aac-encoder", "--command",
         "fdkaac", "-b", str(target_bitrate_k * 1000), "-", "-o", str(raw_aac)],
        stdin=decode.stdout,
    )
    decode.wait()
    if decode.returncode != 0 or encode.returncode != 0:
        sys.exit(f"encode failed (decode={decode.returncode}, fdkaac={encode.returncode})")

    # Stage 2: remux the encoded audio with chapters/tags/cover, no re-encode.
    cmd = [
        "ffmpeg", "-y",
        "-i", str(raw_aac),
        "-i", str(ffmeta),
    ]
    map_args = ["-map", "0:a", "-map_metadata", "1"]
    if cover_path:
        cmd += ["-i", str(cover_path)]
        map_args += ["-map", "2:v", "-c:v", "mjpeg", "-disposition:v:0", "attached_pic"]
    cmd += map_args + ["-c:a", "copy", "-movflags", "+faststart", str(out_path)]

    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)
    raw_aac.unlink()
    concat_list.unlink()
    ffmeta.unlink()
    print(f"Done: {out_path}")

if __name__ == "__main__":
    main()

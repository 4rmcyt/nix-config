#!/usr/bin/env python3
"""Batch-run merge-audiobook.py over every book folder in a library root.

Usage: batch-merge.py <library_root> <backup_root>

For each top-level directory directly under <library_root>:
  - skipped, logged to skipped.txt, if it has subdirectories (multi-disc /
    boxset structure -- needs manual handling, not touched)
  - skipped, logged to skipped.txt, if it has 0 or 1 audio files (nothing
    to merge, or already a single m4b/m4a)
  - otherwise: merged into "<book>.m4b" via merge-audiobook.py, original
    audio fragments moved to <backup_root>/<book>/, the m4b placed into
    the original book folder (cover.*/metadata.json left untouched).

Safe to re-run: a book already holding a single audio file (post-merge)
is skipped on the next pass, so an interrupted run can just be restarted.
"""
import shutil
import subprocess
import sys
from pathlib import Path

AUDIO_EXTS = {".mp3", ".m4a", ".m4b", ".flac", ".wav", ".ogg"}
SCRIPT_DIR = Path(__file__).parent

def audio_files(d: Path) -> list[Path]:
    return sorted(
        p for p in d.iterdir()
        if p.is_file() and not p.name.startswith(".") and p.suffix.lower() in AUDIO_EXTS
    )

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    library_root = Path(sys.argv[1])
    backup_root = Path(sys.argv[2])
    backup_root.mkdir(parents=True, exist_ok=True)

    log_path = SCRIPT_DIR / "batch-log.txt"
    skipped: list[str] = []
    failed: list[str] = []
    done: list[str] = []

    book_dirs = sorted(d for d in library_root.iterdir() if d.is_dir())
    print(f"{len(book_dirs)} entries in {library_root}")

    for i, book_dir in enumerate(book_dirs, start=1):
        name = book_dir.name
        prefix = f"[{i}/{len(book_dirs)}] {name}"

        subdirs = [p for p in book_dir.iterdir() if p.is_dir()]
        if subdirs:
            print(f"{prefix}: SKIP (has {len(subdirs)} subdirs, needs manual handling)")
            skipped.append(f"{name}  -- has subdirs")
            continue

        files = audio_files(book_dir)
        if len(files) <= 1:
            print(f"{prefix}: SKIP ({len(files)} audio files, nothing to merge)")
            skipped.append(f"{name}  -- {len(files)} audio files")
            continue

        out_m4b = book_dir / f"{name}.m4b"
        tmp_m4b = book_dir / f".{name}.tmp.m4b"

        print(f"{prefix}: merging {len(files)} files...")
        result = subprocess.run(
            [sys.executable, str(SCRIPT_DIR / "merge-audiobook.py"), str(book_dir), str(tmp_m4b)],
        )
        if result.returncode != 0 or not tmp_m4b.exists():
            print(f"{prefix}: FAILED (merge error)")
            failed.append(f"{name}  -- merge failed")
            tmp_m4b.unlink(missing_ok=True)
            continue

        book_backup = backup_root / name
        book_backup.mkdir(parents=True, exist_ok=True)
        for f in files:
            shutil.move(str(f), str(book_backup / f.name))

        tmp_m4b.rename(out_m4b)
        print(f"{prefix}: DONE -> {out_m4b.name}, {len(files)} originals -> {book_backup}")
        done.append(name)

    log_path.write_text(
        f"=== DONE ({len(done)}) ===\n" + "\n".join(done) +
        f"\n\n=== SKIPPED ({len(skipped)}) ===\n" + "\n".join(skipped) +
        f"\n\n=== FAILED ({len(failed)}) ===\n" + "\n".join(failed) + "\n"
    )
    print(f"\n{len(done)} done, {len(skipped)} skipped, {len(failed)} failed")
    print(f"Details: {log_path}")

if __name__ == "__main__":
    main()

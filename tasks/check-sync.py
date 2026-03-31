#!/usr/bin/env python3
"""Check that --[[SYNC:name]] ... --[[END_SYNC]] blocks with the same name are identical.

Usage: uv run tasks/check-sync.py
Exit code 1 if any blocks with the same name differ or have wrong occurrence count.
"""

import re
import sys
from collections import defaultdict
from pathlib import Path

SYNC_START = re.compile(r"--\[\[SYNC:([\w-]+)\]\]")
SYNC_END = "--[[END_SYNC]]"


def extract_sync_blocks(
    path: Path,
) -> dict[str, list[tuple[int, list[str]]]]:
    blocks: dict[str, list[tuple[int, list[str]]]] = defaultdict(list)
    lines = path.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        m = SYNC_START.search(lines[i])
        if m:
            name = m.group(1)
            start_line = i + 1  # 1-based line number of the opening marker
            block_lines: list[str] = []
            i += 1
            while i < len(lines):
                if SYNC_END in lines[i]:
                    break
                block_lines.append(lines[i])
                i += 1
            else:
                print(
                    f"error: SYNC:{name} opened at {path}:{start_line} has no matching --[[END_SYNC]]",
                    file=sys.stderr,
                )
                sys.exit(1)
            blocks[name].append((start_line, block_lines))
        i += 1
    return blocks


def normalize(lines: list[str]) -> str:
    """Strip leading/trailing whitespaces per line; blank lines preserved for structure."""
    return "\n".join(line.strip() for line in lines)


def main() -> None:
    root = Path(__file__).parent.parent
    lua_files = sorted(root.glob("scripts/runtime/lab-overlay-renderer.lua"))  # Used only in LabOverlayRenderer currently

    all_blocks: dict[str, list[tuple[Path, int, list[str]]]] = defaultdict(list)
    for path in lua_files:
        for name, instances in extract_sync_blocks(path).items():
            for start_line, block_lines in instances:
                all_blocks[name].append((path, start_line, block_lines))

    errors: list[str] = []
    for name, instances in sorted(all_blocks.items()):
        if len(instances) != 2:
            locs = ", ".join(f"{p.relative_to(root)}:{ln}" for p, ln, _ in instances)
            errors.append(f"SYNC:{name} — expected 2 instances, found {len(instances)} ({locs})")
            continue

        (path1, line1, block1), (path2, line2, block2) = instances
        if normalize(block1) != normalize(block2):
            errors.append(f"SYNC:{name} blocks differ:\n  {path1.relative_to(root)}:{line1}\n  {path2.relative_to(root)}:{line2}")

    if errors:
        for e in errors:
            print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"check-sync: {len(all_blocks)} sync block(s) OK")


if __name__ == "__main__":
    main()

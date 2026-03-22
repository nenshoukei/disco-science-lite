"""Generate docs/mod-portal/description.md from README.md.

Sections excluded from output:
  - h1 title
  - ## API for Mod Authors
  - ## Development (including all subsections)

Relative links are rewritten to absolute GitHub blob/tree URLs.
"""

import re
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
README = REPO_ROOT / "README.md"
OUTPUT = REPO_ROOT / "docs/mod-portal/description.md"

GITHUB_BASE = "https://github.com/nenshoukei/disco-science-lite"
EXCLUDE_SECTIONS = {"API for Mod Authors", "Development"}


def github_url(path: str) -> str:
    path = path.lstrip("/")
    # Paths ending with "/" are directories → use tree/main
    if path.endswith("/"):
        return f"{GITHUB_BASE}/tree/main/{path}"
    else:
        return f"{GITHUB_BASE}/blob/main/{path}"


def convert_links(line: str) -> str:
    def replace(m: re.Match) -> str:
        text, url = m.group(1), m.group(2)
        if url.startswith(("http", "#", "mailto:")):
            return m.group(0)
        return f"[{text}]({github_url(url)})"

    return re.sub(r"\[([^\]]*)\]\(([^)]*)\)", replace, line)


def heading_level(line: str) -> int:
    m = re.match(r"^(#{1,6}) ", line)
    return len(m.group(1)) if m else 0


def main():
    lines = README.read_text().splitlines()

    output: list[str] = []
    skipping: bool = False

    for line in lines:
        level = heading_level(line)

        # Skip h1 title
        if level == 1:
            continue

        # Check for excluded h2 heading
        if level == 2:
            if line.lstrip("#").strip() in EXCLUDE_SECTIONS:
                skipping = True
            else:
                skipping = False

        if skipping:
            continue

        output.append(convert_links(line))

    # Strip leading blank lines (artifact of skipping the h1 title)
    while output and output[0] == "":
        output.pop(0)

    result = "\n".join(output).rstrip("\n") + "\n"
    OUTPUT.write_text(result)
    print(f"Generated {OUTPUT.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()

"""Generate docs/mod-portal/description.md from README.md and README.ja.md.

Sections excluded from output:
  - h1 title
  - ## API for Mod Authors
  - ## Development (including all subsections)

Relative links are rewritten to absolute GitHub blob/tree URLs.
"""

import re
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
README_EN = REPO_ROOT / "README.md"
README_JA = REPO_ROOT / "README.ja.md"
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


def parse_readme(path: Path, output: list[str]):
    lines = path.read_text().splitlines()

    skipping: bool = False
    for line in lines:
        level = heading_level(line)

        # Check for excluded h2 heading
        if level == 2:
            if line.lstrip("#").strip() in EXCLUDE_SECTIONS:
                skipping = True
            else:
                skipping = False

        if skipping:
            continue

        output.append(convert_links(line))


def main():
    output: list[str] = []

    output.append("日本語の説明は下部にあります。")
    output.append("")
    parse_readme(README_EN, output)
    output.append("")
    output.append("---")
    output.append("")
    parse_readme(README_JA, output)

    result = "\n".join(output).rstrip("\n") + "\n"
    if result != OUTPUT.read_text():
        OUTPUT.write_text(result)
        print(f"Generated {OUTPUT.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()

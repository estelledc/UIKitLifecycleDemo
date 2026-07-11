"""Fail when a third-party GitHub Action is not pinned to a full commit SHA."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
USES_RE = re.compile(r"^\s*(?:-\s*)?uses:\s*['\"]?([^'\"\s#]+)")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


def find_errors() -> tuple[list[str], int]:
    errors: list[str] = []
    checked = 0
    for path in sorted([*WORKFLOWS.glob("*.yml"), *WORKFLOWS.glob("*.yaml")]):
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            match = USES_RE.match(line)
            if not match:
                continue
            action = match.group(1)
            if action.startswith("./") or action.startswith("docker://"):
                continue
            checked += 1
            if "@" not in action:
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: missing action ref: {action}")
                continue
            ref = action.rsplit("@", 1)[1]
            if not SHA_RE.fullmatch(ref):
                errors.append(
                    f"{path.relative_to(ROOT)}:{line_number}: action must use a 40-char SHA: {action}"
                )
    return errors, checked


def main() -> int:
    errors, checked = find_errors()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"OK: {checked} third-party GitHub Action references are pinned to full SHAs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

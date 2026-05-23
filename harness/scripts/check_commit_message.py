#!/usr/bin/env python3
from __future__ import annotations

import os
import argparse
import re
from pathlib import Path

ALLOWED_TYPES = {
    "feat",
    "fix",
    "docs",
    "style",
    "refactor",
    "perf",
    "test",
    "build",
    "ci",
    "chore",
    "revert",
}

HEADER_RE = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[a-z0-9-]+)\))?(?P<breaking>!)?: (?P<description>.+)$"
)
HANGUL_RE = re.compile(r"[가-힣]")
FOOTER_RE = re.compile(r"^(BREAKING CHANGE|BREAKING-CHANGE|[A-Za-z-]+)(: | #).+")


def has_hangul(value: str) -> bool:
    return bool(HANGUL_RE.search(value))


def parse_message(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def validate_header(line: str, errors: list[str]) -> None:
    match = HEADER_RE.match(line)
    if not match:
        errors.append("첫 줄은 '<type>[optional scope]: <한국어 설명>' 형식이어야 합니다.")
        return

    commit_type = match.group("type")
    description = match.group("description")

    if commit_type not in ALLOWED_TYPES:
        allowed = ", ".join(sorted(ALLOWED_TYPES))
        errors.append(f"허용되지 않은 type입니다: {commit_type}. 허용값: {allowed}")

    if not has_hangul(description):
        errors.append("커밋 설명은 반드시 한국어를 포함해야 합니다.")


def validate_body_and_footers(lines: list[str], errors: list[str]) -> None:
    if len(lines) <= 1:
        return

    if lines[1].strip():
        errors.append("커밋 본문은 첫 줄 다음 한 줄을 비우고 시작해야 합니다.")

    body_lines = [line for line in lines[2:] if line.strip()]
    if not body_lines:
        return

    body_text_lines: list[str] = []
    for line in body_lines:
        if FOOTER_RE.match(line):
            if line.startswith(("BREAKING CHANGE: ", "BREAKING-CHANGE: ")):
                if not has_hangul(line):
                    errors.append("BREAKING CHANGE 설명은 반드시 한국어를 포함해야 합니다.")
            continue
        body_text_lines.append(line)

    if body_text_lines and not has_hangul("\n".join(body_text_lines)):
        errors.append("커밋 본문은 반드시 한국어를 포함해야 합니다.")


def validate_message(lines: list[str]) -> list[str]:
    errors: list[str] = []
    meaningful = [line.rstrip() for line in lines if not line.startswith("#")]

    while meaningful and not meaningful[-1].strip():
        meaningful.pop()

    if not meaningful:
        return ["커밋 메시지가 비어 있습니다."]

    validate_header(meaningful[0], errors)
    validate_body_and_footers(meaningful, errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="커밋 메시지 하네스 검증")
    parser.add_argument("message_file", type=Path)
    args = parser.parse_args()

    errors = validate_message(parse_message(args.message_file))
    if errors:
        print("commit message validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("commit message validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
from __future__ import annotations

import re
import sys


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9가-힣_-]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")
    return value or "task"


def main() -> int:
    print(slugify(" ".join(sys.argv[1:])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

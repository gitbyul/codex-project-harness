#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness_config import get_path, parse_config  # noqa: E402


ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path.cwd())).resolve()


def config_bool(value: Any, default: bool) -> bool:
    if value in {"true", "True"}:
        return True
    if value in {"false", "False"}:
        return False
    if isinstance(value, bool):
        return value
    return default


def main() -> int:
    config = parse_config(ROOT / ".codex-harness.yml")
    enabled = config_bool(get_path(config, "quality.enabled"), True)
    if not enabled:
        print("quality gates skipped: disabled")
        return 0

    commands = get_path(config, "quality.commands")
    if not isinstance(commands, list):
        commands = [commands] if commands else []
    commands = [str(command).strip() for command in commands if str(command).strip()]
    if not commands:
        print("quality gates skipped: no commands configured")
        return 0

    for command in commands:
        print(f"quality gate: {command}")
        subprocess.check_call(["bash", "-lc", command], cwd=ROOT)

    print("quality gates passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

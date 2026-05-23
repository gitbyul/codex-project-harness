#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any


DEFAULT_CONFIG: dict[str, Any] = {
    "harness": {
        "source": "",
        "version": "local",
        "ci": {
            "mode": "local_path",
            "repository": "",
            "ref": "main",
        },
    },
    "modules": {
        "scripts": True,
        "githooks": True,
        "github_workflows": False,
        "generic_pm_skills": True,
        "docs_templates": False,
    },
    "project": {
        "name": "",
        "code_root": "",
        "verify_command": "",
    },
    "architecture": {
        "python_source_roots": [],
        "forbidden_globals": [],
        "forbidden_route_calls": [],
    },
    "artifacts": {
        "required": True,
        "blocked_staged_suffixes": [
            ".wav",
            ".mp3",
            ".flac",
            ".ogg",
            ".m4a",
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".webp",
            ".mp4",
            ".mov",
            ".avi",
            ".onnx",
            ".pt",
            ".pth",
            ".ckpt",
            ".safetensors",
            ".bin",
        ],
    },
    "quality": {
        "enabled": True,
        "commands": [],
        "required_plan_sections": True,
    },
}


def merge_defaults(config: dict[str, Any], defaults: dict[str, Any]) -> dict[str, Any]:
    result = dict(defaults)
    for key, value in config.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge_defaults(value, result[key])
        else:
            result[key] = value
    return result


def parse_scalar(value: str) -> Any:
    value = value.strip()
    if value == "":
        return ""
    if value in {"true", "True"}:
        return True
    if value in {"false", "False"}:
        return False
    if value in {"[]", ""}:
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [item.strip().strip("'\"") for item in inner.split(",")]
    return value.strip("'\"")


def parse_config(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return merge_defaults({}, DEFAULT_CONFIG)

    root: dict[str, Any] = {}
    stack: list[tuple[int, dict[str, Any] | list[Any], dict[str, Any] | None, str | None]] = [
        (-1, root, None, None)
    ]

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        line = raw_line.strip()

        while stack and indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1]

        if line.startswith("- "):
            if not isinstance(parent, list):
                stack_indent, current, owner, owner_key = stack[-1]
                if isinstance(current, dict) and not current and owner is not None and owner_key is not None:
                    replacement: list[Any] = []
                    owner[owner_key] = replacement
                    stack[-1] = (stack_indent, replacement, owner, owner_key)
                    parent = replacement
                else:
                    continue
            parent.append(parse_scalar(line[2:]))
            continue

        if ":" not in line or not isinstance(parent, dict):
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()

        if value:
            parent[key] = parse_scalar(value)
            continue

        next_container: dict[str, Any] | list[Any] = {}
        parent[key] = next_container
        stack.append((indent, next_container, parent, key))

    # Convert empty dicts that only receive list items in the common YAML shape.
    def normalize(value: Any) -> Any:
        if isinstance(value, dict):
            return {key: normalize(child) for key, child in value.items()}
        return value

    return merge_defaults(normalize(root), DEFAULT_CONFIG)


def get_path(config: dict[str, Any], dotted: str) -> Any:
    current: Any = config
    for part in dotted.split("."):
        if not isinstance(current, dict) or part not in current:
            return ""
        current = current[part]
    return current


def shell_quote(value: Any) -> str:
    if isinstance(value, bool):
        text = "true" if value else "false"
    elif isinstance(value, list):
        text = ",".join(str(item) for item in value)
    else:
        text = str(value)
    return "'" + text.replace("'", "'\"'\"'") + "'"


def main() -> int:
    parser = argparse.ArgumentParser(description="Read .codex-harness.yml values")
    parser.add_argument("--config", type=Path, default=Path(".codex-harness.yml"))
    parser.add_argument("--get")
    parser.add_argument("--shell", action="store_true")
    args = parser.parse_args()

    config = parse_config(args.config)
    if args.get:
        value = get_path(config, args.get)
        if isinstance(value, bool):
            print("true" if value else "false")
        elif isinstance(value, list):
            print("\n".join(str(item) for item in value))
        else:
            print(value)
        return 0

    if args.shell:
        exports = {
            "HARNESS_CONFIG_SOURCE": get_path(config, "harness.source"),
            "HARNESS_CONFIG_VERSION": get_path(config, "harness.version"),
            "HARNESS_CONFIG_CI_MODE": get_path(config, "harness.ci.mode"),
            "HARNESS_CONFIG_CI_REPOSITORY": get_path(config, "harness.ci.repository"),
            "HARNESS_CONFIG_CI_REF": get_path(config, "harness.ci.ref"),
            "HARNESS_MODULE_SCRIPTS": get_path(config, "modules.scripts"),
            "HARNESS_MODULE_GITHOOKS": get_path(config, "modules.githooks"),
            "HARNESS_MODULE_GITHUB_WORKFLOWS": get_path(config, "modules.github_workflows"),
            "HARNESS_MODULE_GENERIC_PM_SKILLS": get_path(config, "modules.generic_pm_skills"),
            "HARNESS_MODULE_DOCS_TEMPLATES": get_path(config, "modules.docs_templates"),
            "HARNESS_PROJECT_NAME": get_path(config, "project.name"),
            "HARNESS_PROJECT_CODE_ROOT": get_path(config, "project.code_root"),
            "HARNESS_PROJECT_VERIFY_COMMAND": get_path(config, "project.verify_command"),
            "HARNESS_QUALITY_ENABLED": get_path(config, "quality.enabled"),
            "HARNESS_QUALITY_COMMANDS": get_path(config, "quality.commands"),
            "HARNESS_QUALITY_REQUIRED_PLAN_SECTIONS": get_path(
                config, "quality.required_plan_sections"
            ),
        }
        for key, value in exports.items():
            print(f"{key}={shell_quote(value)}")
        return 0

    for key in sorted(DEFAULT_CONFIG):
        print(f"{key}: {config.get(key)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

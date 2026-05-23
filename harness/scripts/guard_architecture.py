#!/usr/bin/env python3
from __future__ import annotations

import ast
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness_config import get_path, parse_config  # noqa: E402


ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()
CONFIG = parse_config(ROOT / ".codex-harness.yml")


@dataclass
class Finding:
    severity: str
    path: Path
    line: int
    message: str

    def render(self) -> str:
        relative = self.path.relative_to(ROOT)
        return f"{self.severity}: {relative}:{self.line}: {self.message}"


def as_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value if str(item)]
    if isinstance(value, str) and value:
        return [item.strip() for item in value.split(",") if item.strip()]
    return []


class ArchitectureVisitor(ast.NodeVisitor):
    def __init__(self, path: Path, forbidden_globals: set[str], forbidden_route_calls: set[str]) -> None:
        self.path = path
        self.findings: list[Finding] = []
        self.forbidden_globals = forbidden_globals
        self.forbidden_route_calls = forbidden_route_calls
        self._route_depth = 0

    def visit_Global(self, node: ast.Global) -> None:
        for name in node.names:
            if name in self.forbidden_globals:
                self.findings.append(
                    Finding("WARN", self.path, node.lineno, f"forbidden global in architecture guard: {name}")
                )
        self.generic_visit(node)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self._visit_function(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:
        self._visit_function(node)

    def _visit_function(self, node: ast.FunctionDef | ast.AsyncFunctionDef) -> None:
        is_route = any(self._decorator_mentions_http_method(decorator) for decorator in node.decorator_list)
        if is_route:
            self._route_depth += 1
            self.generic_visit(node)
            self._route_depth -= 1
        else:
            self.generic_visit(node)

    def visit_Call(self, node: ast.Call) -> None:
        call_name = self._call_name(node.func)
        if self._route_depth and call_name in self.forbidden_route_calls:
            self.findings.append(
                Finding(
                    "WARN",
                    self.path,
                    node.lineno,
                    f"forbidden route-level call in architecture guard: {call_name}",
                )
            )
        self.generic_visit(node)

    @staticmethod
    def _decorator_mentions_http_method(node: ast.expr) -> bool:
        if not isinstance(node, ast.Call):
            return False
        func = node.func
        return isinstance(func, ast.Attribute) and func.attr in {"get", "post", "put", "patch", "delete"}

    @staticmethod
    def _call_name(node: ast.expr) -> str:
        if isinstance(node, ast.Name):
            return node.id
        if isinstance(node, ast.Attribute):
            return node.attr
        return ""


def source_files() -> list[Path]:
    configured_roots = as_list(get_path(CONFIG, "architecture.python_source_roots"))
    roots = [ROOT / path for path in configured_roots] if configured_roots else []
    files: list[Path] = []
    for source_root in roots:
        if source_root.is_file() and source_root.suffix == ".py":
            files.append(source_root)
        elif source_root.is_dir():
            files.extend(source_root.rglob("*.py"))
    return sorted(path.resolve() for path in files if path.exists())


def check_source_files() -> list[Finding]:
    forbidden_globals = set(as_list(get_path(CONFIG, "architecture.forbidden_globals")))
    forbidden_route_calls = set(as_list(get_path(CONFIG, "architecture.forbidden_route_calls")))
    if not forbidden_globals and not forbidden_route_calls:
        return []

    findings: list[Finding] = []
    for path in source_files():
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        visitor = ArchitectureVisitor(path, forbidden_globals, forbidden_route_calls)
        visitor.visit(tree)
        findings.extend(visitor.findings)
    return findings


def main() -> int:
    findings = check_source_files()
    errors = [finding for finding in findings if finding.severity == "ERROR"]

    if findings:
        print("architecture guardrail findings:")
        for finding in findings:
            print(f"- {finding.render()}")
    else:
        print("architecture guardrail passed")

    if errors:
        print("architecture guardrail failed")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

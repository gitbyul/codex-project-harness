#!/usr/bin/env python3
from __future__ import annotations

import os
import ast
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()


@dataclass
class Finding:
    severity: str
    path: Path
    line: int
    message: str

    def render(self) -> str:
        relative = self.path.relative_to(ROOT)
        return f"{self.severity}: {relative}:{self.line}: {self.message}"


class MainVisitor(ast.NodeVisitor):
    def __init__(self, path: Path) -> None:
        self.path = path
        self.findings: list[Finding] = []
        self._route_depth = 0
        self._except_depth = 0

    def visit_Global(self, node: ast.Global) -> None:
        if "model_engine" in node.names:
            self.findings.append(
                Finding(
                    "WARN",
                    self.path,
                    node.lineno,
                    "global model engine is POC debt; move engine access behind an adapter",
                )
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
        if self._route_depth and isinstance(node.func, ast.Attribute) and node.func.attr == "synthesize":
            self.findings.append(
                Finding(
                    "WARN",
                    self.path,
                    node.lineno,
                    "interface layer calls model runtime directly; target architecture uses application/runtime boundaries",
                )
            )
        self.generic_visit(node)

    def visit_ExceptHandler(self, node: ast.ExceptHandler) -> None:
        self._except_depth += 1
        self.generic_visit(node)
        self._except_depth -= 1

    @staticmethod
    def _decorator_mentions_http_method(node: ast.expr) -> bool:
        if not isinstance(node, ast.Call):
            return False
        func = node.func
        return isinstance(func, ast.Attribute) and func.attr in {"get", "post", "put", "patch", "delete"}

def source_files() -> list[Path]:
    backend_src = ROOT / "backend" / "src"
    if backend_src.is_dir():
        return sorted(backend_src.rglob("*.py"))

    ignored_roots = {"scripts", "tests"}
    files: list[Path] = []
    for path in ROOT.rglob("*.py"):
        relative = path.relative_to(ROOT)
        if relative.parts and relative.parts[0] in ignored_roots:
            continue
        files.append(path)
    return sorted(files)


def check_source_files() -> list[Finding]:
    findings: list[Finding] = []
    for path in source_files():
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        visitor = MainVisitor(path)
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

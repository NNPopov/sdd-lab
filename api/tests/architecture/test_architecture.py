# STABLE: Architecture tests — enforce VSA + Hexagonal dependency rules.
"""
Architecture tests for the VSA + Hexagonal + Skeleton project.

Scope
-----
- pytestarch tests: high-level module isolation (adapters, core, ports, domain).
- AST tests: fine-grained VSA slice rules (domain content, layer direction,
  adapter-port binding, use-case structure).

Legacy exclusions
-----------------
The following dirs use the pre-VSA flat pattern and are explicitly excluded
from VSA-specific checks:
  features/auth/
  features/rate_limits/
  features/tiers/
  features/tasks/
  features/health/
  features/users/use_cases/
  features/*/repository.py
"""

from __future__ import annotations

import ast
from pathlib import Path

import pytest
from pytestarch import EvaluableArchitecture, Rule, get_evaluable_architecture

# ── paths ──────────────────────────────────────────────────────────────────
_SRC = Path(__file__).resolve().parent.parent.parent / "src"
_APP = _SRC / "app"

# Libraries that must never appear in VSA slice domain/ files.
_FORBIDDEN_IN_VSA_DOMAIN: frozenset[str] = frozenset(
    [
        "fastapi",
        "sqlalchemy",
        "httpx",
        "aiohttp",
        "requests",
        "arq",
        "redis",
        "dependency_injector",
        "structlog",
    ]
)

# VSA domains subject to fine-grained checks.
_VSA_DOMAINS = ("users", "posts")


# ── pytestarch fixture ─────────────────────────────────────────────────────
# pytestarch 4.x API: root_path = dir containing the package; module_path = abs
# path to the package. Module names in rules carry the "src.app.*" prefix because
# root_path's parent (project root) is the implicit namespace root.
_PYTESTARCH_ROOT = str(_SRC)  # "…/api/src"
_PYTESTARCH_MODULE = str(_APP)  # "…/api/src/app"
_M = "src.app"  # module name prefix used in all Rule() calls


@pytest.fixture(scope="session")
def arch() -> EvaluableArchitecture:
    return get_evaluable_architecture(_PYTESTARCH_ROOT, _PYTESTARCH_MODULE)


# ══════════════════════════════════════════════════════════════════════════
# Section 1 — high-level module isolation (pytestarch)
# ══════════════════════════════════════════════════════════════════════════


def test_adapters_do_not_import_features(arch: EvaluableArchitecture) -> None:
    """STABLE adapters/ must not depend on FEATURE features/."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.adapters")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.features")
    ).assert_applies(arch)


def test_core_does_not_import_features(arch: EvaluableArchitecture) -> None:
    """core/ is cross-cutting infrastructure; it must not depend on features/."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.core")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.features")
    ).assert_applies(arch)


def test_core_does_not_import_adapters(arch: EvaluableArchitecture) -> None:
    """core/ must not import concrete adapters (only stdlib + third-party)."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.core")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.adapters")
    ).assert_applies(arch)


def test_ports_do_not_import_adapters(arch: EvaluableArchitecture) -> None:
    """ports/ defines Protocol interfaces; concrete adapters must not leak in."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.ports")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.adapters")
    ).assert_applies(arch)


def test_ports_do_not_import_features(arch: EvaluableArchitecture) -> None:
    """ports/ must not import feature slices."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.ports")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.features")
    ).assert_applies(arch)


def test_ports_do_not_import_core(arch: EvaluableArchitecture) -> None:
    """ports/ must not import core/; it may only import domain/."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.ports")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.core")
    ).assert_applies(arch)


def test_global_domain_does_not_import_adapters(arch: EvaluableArchitecture) -> None:
    """Global domain/ (errors, base_schemas) must be framework-free."""
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.domain")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.adapters")
    ).assert_applies(arch)


def test_global_domain_does_not_import_features(arch: EvaluableArchitecture) -> None:
    (
        Rule()
        .modules_that()
        .are_sub_modules_of(f"{_M}.domain")
        .should_not()
        .import_modules_that()
        .are_sub_modules_of(f"{_M}.features")
    ).assert_applies(arch)


# ══════════════════════════════════════════════════════════════════════════
# Section 2 — AST helpers
# ══════════════════════════════════════════════════════════════════════════


def _collect(glob: str) -> list[Path]:
    return [p for p in _APP.glob(glob) if p.name != "__init__.py" and p.suffix == ".py"]


def _imports(path: Path) -> list[tuple[int, str | None, str | None]]:
    """Return (level, module, name) tuples for every import in *path*.

    level  — relative-import dot count (0 = absolute)
    module — the module string after 'from', or None for plain 'import'
    name   — top-level name for plain 'import X', or None
    """
    tree = ast.parse(path.read_text(encoding="utf-8"))
    result: list[tuple[int, str | None, str | None]] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom):
            result.append((node.level, node.module, None))
        elif isinstance(node, ast.Import):
            for alias in node.names:
                result.append((0, None, alias.name))
    return result


def _top_level_packages(path: Path) -> list[str]:
    """Return the set of top-level package names imported by *path*."""
    pkgs: list[str] = []
    for level, module, name in _imports(path):
        if level == 0:
            if name:
                pkgs.append(name.split(".")[0])
            elif module:
                pkgs.append(module.split(".")[0])
    return pkgs


# ══════════════════════════════════════════════════════════════════════════
# Section 3 — VSA domain/ layer content (forbidden libraries)
# ══════════════════════════════════════════════════════════════════════════

_VSA_DOMAIN_FILES = _collect("features/*/*/domain/**/*.py")


def _ensure_not_empty(files: list[Path], label: str) -> None:
    assert files, f"No files found for pattern '{label}' — check _APP path or glob."


@pytest.mark.parametrize("filepath", _VSA_DOMAIN_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_vsa_domain_imports_only_stdlib_and_pydantic(filepath: Path) -> None:
    """VSA slice domain/ may only import stdlib and pydantic."""
    violations = [pkg for pkg in _top_level_packages(filepath) if pkg in _FORBIDDEN_IN_VSA_DOMAIN]
    assert not violations, (
        f"{filepath.relative_to(_APP)}\n"
        f"  Forbidden library imports: {violations}\n"
        f"  domain/ layer may only use stdlib and pydantic."
    )


# ══════════════════════════════════════════════════════════════════════════
# Section 4 — VSA layer direction
#   domain/  must not import  data/  or  presentation/
#   data/    must not import  presentation/
# ══════════════════════════════════════════════════════════════════════════

_VSA_DATA_FILES = _collect("features/*/*/data/**/*.py")


def _relative_module_segments(level: int, module: str | None, filepath: Path) -> list[str]:
    """Resolve a relative import to a list of path segments relative to APP root."""
    if level == 0 or module is None:
        return []
    parts = list(filepath.relative_to(_APP).parent.parts)
    up = min(level, len(parts))
    base = parts[: len(parts) - up + 1]
    return base + module.split(".")


@pytest.mark.parametrize("filepath", _VSA_DOMAIN_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_vsa_domain_does_not_import_data_or_presentation(filepath: Path) -> None:
    """domain/ layer must not import sibling data/ or presentation/ layers."""
    violations: list[str] = []
    for level, module, _name in _imports(filepath):
        if level > 0 and module:
            segments = _relative_module_segments(level, module, filepath)
            if "data" in segments or "presentation" in segments:
                violations.append(f"{'.' * level}{module}")
    assert not violations, (
        f"{filepath.relative_to(_APP)}\n"
        f"  domain/ imports data/ or presentation/ (forbidden upward dependency):\n"
        + "\n".join(f"    from {v} import ..." for v in violations)
    )


@pytest.mark.parametrize("filepath", _VSA_DATA_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_vsa_data_does_not_import_presentation(filepath: Path) -> None:
    """data/ layer must not import sibling presentation/ layer."""
    violations: list[str] = []
    for level, module, _name in _imports(filepath):
        if level > 0 and module:
            segments = _relative_module_segments(level, module, filepath)
            if "presentation" in segments:
                violations.append(f"{'.' * level}{module}")
    assert not violations, (
        f"{filepath.relative_to(_APP)}\n"
        f"  data/ imports presentation/ (forbidden upward dependency):\n"
        + "\n".join(f"    from {v} import ..." for v in violations)
    )


# ══════════════════════════════════════════════════════════════════════════
# Section 5 — VSA domain isolation (users ↔ posts)
#   VSA slice files of one domain must not import from the other domain.
#   Legacy flat files (use_cases/, repository.py) are excluded.
# ══════════════════════════════════════════════════════════════════════════


def _vsa_slice_files(domain: str) -> list[Path]:
    """Collect only VSA-format files (domain/, data/, presentation/ subdirs)."""
    base = _APP / "features" / domain
    return [
        p
        for layer in ("domain", "data", "presentation")
        for p in base.glob(f"*/{layer}/**/*.py")
        if p.name != "__init__.py"
    ]


_CROSS_DOMAIN_CASES = [
    ("users", "posts"),
    ("posts", "users"),
]


@pytest.mark.parametrize("domain,other", _CROSS_DOMAIN_CASES, ids=lambda x: x if isinstance(x, str) else "")
def test_vsa_domains_do_not_import_each_other(domain: str, other: str) -> None:
    """VSA slices of one domain must not import from the other domain's slices."""
    violations: list[str] = []
    for filepath in _vsa_slice_files(domain):
        for level, module, name in _imports(filepath):
            target = module or name or ""
            # Absolute import containing the other domain
            if f"features.{other}" in target:
                violations.append(f"{filepath.relative_to(_APP)}: import {target!r}")
            # Deep relative import that lands in another domain
            # (level resolves above features/, then module starts with other domain)
            elif level > 0 and module:
                segments = _relative_module_segments(level, module, filepath)
                feat_idx = next((i for i, s in enumerate(segments) if s == "features"), -1)
                if feat_idx != -1 and feat_idx + 1 < len(segments):
                    if segments[feat_idx + 1] == other:
                        violations.append(f"{filepath.relative_to(_APP)}: relative import {'.' * level}{module}")
    assert not violations, f"Domain '{domain}' imports from domain '{other}':\n" + "\n".join(
        f"  {v}" for v in violations
    )


# ══════════════════════════════════════════════════════════════════════════
# Section 6 — Use-case structure
#   Every use_case.py must contain a class with an async __call__ method.
# ══════════════════════════════════════════════════════════════════════════

_USE_CASE_FILES = list(_APP.glob("features/*/*/domain/use_case.py"))


@pytest.mark.parametrize("filepath", _USE_CASE_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_use_case_class_has_async_call(filepath: Path) -> None:
    """Every use_case.py must define a class with an async __call__ method."""
    tree = ast.parse(filepath.read_text(encoding="utf-8"))
    use_case_classes = [n for n in ast.walk(tree) if isinstance(n, ast.ClassDef)]

    assert use_case_classes, f"{filepath.relative_to(_APP)}: no class defined in use_case.py"

    for cls in use_case_classes:
        method_names = {n.name for n in ast.walk(cls) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
        assert "__call__" in method_names, (
            f"{filepath.relative_to(_APP)}: class {cls.name!r} has no __call__ method.\n"
            f"  Use-cases must be callable classes."
        )


# ══════════════════════════════════════════════════════════════════════════
# Section 7 — Adapter-Port binding
#   Every Adapter class in data/adapter.py must inherit from a Port.
# ══════════════════════════════════════════════════════════════════════════

_ADAPTER_FILES = list(_APP.glob("features/*/*/data/adapter.py"))


@pytest.mark.parametrize("filepath", _ADAPTER_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_adapter_inherits_from_port(filepath: Path) -> None:
    """Adapter classes must explicitly inherit from their corresponding Port.

    This keeps the port→adapter binding greppable and enforces the hexagonal
    contract.
    """
    tree = ast.parse(filepath.read_text(encoding="utf-8"))
    adapter_classes = [n for n in ast.walk(tree) if isinstance(n, ast.ClassDef) and "Adapter" in n.name]

    assert adapter_classes, (
        f"{filepath.relative_to(_APP)}: no class with 'Adapter' in the name found.\n"
        f"  Adapter files must define at least one *Adapter class."
    )

    for cls in adapter_classes:
        base_names = []
        for base in cls.bases:
            if isinstance(base, ast.Name):
                base_names.append(base.id)
            elif isinstance(base, ast.Attribute):
                base_names.append(base.attr)

        port_bases = [b for b in base_names if b and "Port" in b]
        assert port_bases, (
            f"{filepath.relative_to(_APP)}: class {cls.name!r} does not inherit from a Port.\n"
            f"  Bases found: {base_names or ['(none)']}\n"
            f"  Expected: class {cls.name}(SomePort): ..."
        )


# ══════════════════════════════════════════════════════════════════════════
# Section 8 — File header convention
#   Every .py file in features/ must start with # STABLE: or # FEATURE:
# ══════════════════════════════════════════════════════════════════════════

_FEATURE_PY_FILES = [
    p
    for p in _APP.glob("features/**/*.py")
    if p.name != "__init__.py"
    # Exclude __pycache__ (shouldn't be picked up by glob but safety check)
    and "__pycache__" not in p.parts
]


@pytest.mark.parametrize("filepath", _FEATURE_PY_FILES, ids=lambda p: str(p.relative_to(_APP)))
def test_feature_file_has_stability_header(filepath: Path) -> None:
    """Every .py file in features/ must begin with # STABLE: or # FEATURE:."""
    first_line = filepath.read_text(encoding="utf-8").splitlines()[0] if filepath.stat().st_size > 0 else ""
    assert first_line.startswith("# STABLE:") or first_line.startswith("# FEATURE:"), (
        f"{filepath.relative_to(_APP)}\n"
        f"  Missing stability header. First line: {first_line!r}\n"
        f"  Add '# STABLE: ...' or '# FEATURE: <slice> — <purpose>' as line 1."
    )


# ── sanity: ensure file collection is non-empty ────────────────────────────


def test_collection_sanity() -> None:
    """Guard against misconfigured paths that would make all parametrize tests vacuous."""
    _ensure_not_empty(_VSA_DOMAIN_FILES, "features/*/*/domain/**/*.py")
    _ensure_not_empty(_USE_CASE_FILES, "features/*/*/domain/use_case.py")
    _ensure_not_empty(_ADAPTER_FILES, "features/*/*/data/adapter.py")

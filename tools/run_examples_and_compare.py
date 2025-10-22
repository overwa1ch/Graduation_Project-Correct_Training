#!/usr/bin/env python3
"""Compare expected example outputs with recorded CLI results."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any, List


def _compare_values(expected: Any, actual: Any, path: str, *, rtol: float, atol: float, diffs: List[str]) -> None:
    if isinstance(expected, dict) and isinstance(actual, dict):
        expected_keys = set(expected)
        actual_keys = set(actual)
        for key in sorted(expected_keys - actual_keys):
            diffs.append(f"[MISSING ACTUAL] {path}.{key}")
        for key in sorted(actual_keys - expected_keys):
            diffs.append(f"[EXTRA ACTUAL] {path}.{key}")
        for key in sorted(expected_keys & actual_keys):
            next_path = f"{path}.{key}" if path else key
            _compare_values(expected[key], actual[key], next_path, rtol=rtol, atol=atol, diffs=diffs)
        return

    if isinstance(expected, list) and isinstance(actual, list):
        min_len = min(len(expected), len(actual))
        for idx in range(min_len):
            next_path = f"{path}[{idx}]"
            _compare_values(expected[idx], actual[idx], next_path, rtol=rtol, atol=atol, diffs=diffs)
        if len(expected) != len(actual):
            diffs.append(
                f"[LENGTH] {path}: expected {len(expected)} entries, actual {len(actual)} entries"
            )
        return

    if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
        if math.isfinite(expected) and math.isfinite(actual):
            if not math.isclose(expected, actual, rel_tol=rtol, abs_tol=atol):
                diffs.append(
                    f"[VALUE] {path}: expected {expected}, actual {actual}"
                )
        elif expected != actual:
            diffs.append(f"[VALUE] {path}: expected {expected}, actual {actual}")
        return

    if expected != actual:
        diffs.append(f"[VALUE] {path}: expected {expected!r}, actual {actual!r}")


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", required=True, help="Sample identifier to compare.")
    parser.add_argument("--rtol", type=float, default=1e-5)
    parser.add_argument("--atol", type=float, default=1e-8)
    parser.add_argument("--extra-arg", action="store_true", help="Ignored placeholder for compatibility.")
    parser.add_argument("--assert-print", action="store_true", help="Print success message when matches.")
    args = parser.parse_args(argv)

    sample = args.only
    expected_path = Path("examples") / sample / "expected" / "result.json"
    if not expected_path.exists():
        print(f"[ERROR] Missing expected file: {expected_path}", file=sys.stderr)
        return 1

    actual_candidates = list((Path("build/examples_runner") / sample).rglob("result.json"))
    if not actual_candidates:
        print(f"[ERROR] No build output found for sample '{sample}'", file=sys.stderr)
        return 1

    actual_path = actual_candidates[0]

    with expected_path.open("r", encoding="utf-8") as f:
        expected_obj = json.load(f)
    with actual_path.open("r", encoding="utf-8") as f:
        actual_obj = json.load(f)

    diffs: List[str] = []
    _compare_values(expected_obj, actual_obj, path="", rtol=args.rtol, atol=args.atol, diffs=diffs)

    if diffs:
        for diff in diffs:
            print(diff)
        return 2

    if args.assert_print:
        print(f"[OK] {sample}: expected matches build output at {actual_path}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

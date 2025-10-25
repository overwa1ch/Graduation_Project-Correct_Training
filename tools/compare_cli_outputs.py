#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Compare CLI outputs against expected artifacts with parameterized thresholds.

Usage examples:

1) Only compare result.json (strict meta + numeric tolerances):
    python compare_cli_outputs.py       --expected-result examples/squat_normal/expected/result.json       --actual-result   build/offline_out/squat_normal/result.json       --eps-angle 2.0 --eps-quality 0.05 --eps-fps 1.0       --strict-meta

2) With angles.csv:
    python compare_cli_outputs.py       --expected-result examples/squat_noisy_keypoints/expected/result.json       --actual-result   build/offline_out/squat_noisy_keypoints/result.json       --expected-angles examples/squat_noisy_keypoints/expected/angles.csv       --actual-angles   build/offline_out/squat_noisy_keypoints/angles.csv       --ang-mae 0.5 --ang-max 1.0       --eps-angle 4.0 --eps-quality 0.05 --eps-fps 1.0       --strict-meta

3) 加上 neutral_keypoints.json（noisy 放宽阈值示例）:
    python compare_cli_outputs.py       --expected-result examples/squat_noisy_keypoints/expected/result.json       --actual-result   build/offline_out/squat_noisy_keypoints/result.json       --expected-kp     examples/squat_noisy_keypoints/expected/neutral_keypoints.json       --actual-kp       build/offline_out/squat_noisy_keypoints/neutral_keypoints.json       --kp-eps-xy 0.02 --kp-eps-z 0.05 --strict-meta
"""

import argparse, csv, json, math, sys
from typing import Any, Dict, List, Tuple


def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def compare_result_json(expected_path: str, actual_path: str,
                        eps_angle: float, eps_quality: float, eps_fps: float,
                        strict_meta: bool) -> bool:
    exp = load_json(expected_path)
    act = load_json(actual_path)

    ok = True
    failures: List[str] = []

    def get(d, *keys):
        for k in keys:
            if d is None or k not in d:
                return None
            d = d[k]
        return d

    def assert_eq(label, ev, av):
        nonlocal ok
        if ev != av:
            ok = False
            failures.append(f"[result.meta] {label} mismatch: expected={ev} actual={av}")
        else:
            print(f"[OK] {label} == {ev}")

    def assert_num_close(label, ev, av, eps):
        nonlocal ok
        if ev is None or av is None:
            ok = False
            failures.append(f"[result.num] {label} missing: expected={ev} actual={av}")
            return
        if not isinstance(ev, (int,float)) or not isinstance(av, (int,float)):
            ok = False
            failures.append(f"[result.num] {label} types: expected={type(ev)} actual={type(av)}")
            return
        diff = abs(ev-av)
        if diff <= eps:
            print(f"[OK] {label} | diff={diff:.6f} ≤ {eps}")
        else:
            ok = False
            failures.append(f"[X ] {label} | diff={diff:.6f} > {eps} (exp={ev}, act={av})")

    # --- Strict meta equality (if requested) ---
    if strict_meta:
        meta_paths = [
            ("engine.name", ("engine","name")),
            ("engine.model", ("engine","model")),
            ("version", ("version",)),
            ("sampling.stride", ("sampling","stride")),
            ("video.fpsIntended", ("video","fpsIntended")),
            ("video.width", ("video","width")),
            ("video.height", ("video","height")),
        ]
        for label, path in meta_paths:
            assert_eq(label, get(exp, *path), get(act, *path))

    # --- fps tolerance ---
    if "fps" in exp and "fps" in act:
        assert_num_close("fps", exp["fps"], act["fps"], eps_fps)

    # --- quality summary tolerance ---
    if "quality" in exp and "quality" in act:
        for k in ("lowConfidence", "coverage", "scoreImpact"):
            if k in exp["quality"] or k in act["quality"]:
                assert_num_close(f"quality.{k}", get(exp,"quality",k), get(act,"quality",k), eps_quality)

    # --- reps sub-structure (angles) ---
    if "reps" in exp and "reps" in act and isinstance(exp["reps"], list) and isinstance(act["reps"], list):
        if len(exp["reps"]) != len(act["reps"]):
            ok = False
            failures.append(f"[reps] count mismatch: expected={len(exp['reps'])} actual={len(act['reps'])}")
        else:
            fields = ("kneeValleyAngle","minKneeOutAngle","maxForwardLean")
            for i, (er, ar) in enumerate(zip(exp["reps"], act["reps"])):
                for f in fields:
                    if f in er or f in ar:
                        assert_num_close(f"reps[{i}].{f}", er.get(f), ar.get(f), eps_angle)

    if not ok:
        print("\n[FAILURES]")
        for m in failures:
            print(m)
    else:
        print("[OK] result.json checks PASS")
    return ok


def read_csv_matrix(path: str) -> Tuple[List[str], List[List[float]]]:
    with open(path, newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        header = next(r)
        rows: List[List[float]] = []
        for row in r:
            if not row: 
                continue
            rows.append([float(x) for x in row])
        return header, rows


def compare_angles_csv(expected_path: str, actual_path: str, ang_mae: float, ang_max: float) -> bool:
    h1, a1 = read_csv_matrix(expected_path)
    h2, a2 = read_csv_matrix(actual_path)

    ok = True
    failures: List[str] = []

    if h1 != h2:
        print(f"[X ] angles header mismatch:\n exp={h1}\n act={h2}")
        return False
    if len(a1) != len(a2):
        print(f"[X ] angles row count mismatch: exp={len(a1)} act={len(a2)}")
        return False
    if not a1:
        print("[OK] angles empty files (no rows)")
        return True

    cols = len(h1)
    # transpose-ish computations without numpy
    for c in range(cols):
        diffs = [abs(a1[r][c]-a2[r][c]) for r in range(len(a1))]
        mae = sum(diffs)/len(diffs)
        mx  = max(diffs)
        if mae <= ang_mae and mx <= ang_max:
            print(f"[OK] angles[{h1[c]}] MAE={mae:.4f} MAX={mx:.4f} (≤ {ang_mae}, ≤ {ang_max})")
        else:
            ok = False
            failures.append(f"[X ] angles[{h1[c]}] MAE={mae:.4f} MAX={mx:.4f} (thr={ang_mae},{ang_max})")

    if not ok:
        print("\n[FAILURES]")
        for m in failures:
            print(m)
    else:
        print("[OK] angles.csv checks PASS")
    return ok


def compare_keypoints_json(expected_path: str, actual_path: str,
                           kp_eps_xy: float, kp_eps_z: float,
                           strict_meta: bool) -> bool:
    exp = load_json(expected_path)
    act = load_json(actual_path)

    ok = True
    failures: List[str] = []

    def get(d, *keys):
        for k in keys:
            if d is None or k not in d:
                return None
            d = d[k]
        return d

    # meta equality if requested
    if strict_meta:
        meta_paths = [
            ("version", ("version",)),
            ("engine.name", ("engine","name")),
            ("engine.model", ("engine","model")),
            ("sampling.stride", ("sampling","stride")),
            ("video.fpsIntended", ("video","fpsIntended")),
            ("video.width", ("video","width")),
            ("video.height", ("video","height")),
        ]
        for label, path in meta_paths:
            ev, av = get(exp, *path), get(act, *path)
            if ev != av:
                ok = False
                failures.append(f"[kp.meta] {label} mismatch: expected={ev} actual={av}")
            else:
                print(f"[OK] {label} == {ev}")

    # timestamps / frame count
    ef = [f.get("timestampMs") for f in exp.get("frames", [])]
    af = [f.get("timestampMs") for f in act.get("frames", [])]
    if ef != af:
        ok = False
        failures.append(f"[kp] timestamps mismatch or frame count mismatch (exp={len(ef)}, act={len(af)})")
        if len(ef) and len(af):
            n = min(5, min(len(ef), len(af)))
            failures.append(f"  first few exp={ef[:n]} act={af[:n]}")
        # If timestamps mismatch, further numeric compare is unreliable, abort early:
        print("\n[FAILURES]")
        for m in failures: print(m)
        return False

    if not ef:
        print("[OK] keypoints: empty frames")
        return True

    # assume identical frame structure; compare MAE over all frames and all keypoints
    names = [kp["name"] for kp in exp["frames"][0]["keypoints"]]
    total_x = total_y = total_z = 0.0
    count = 0

    for fe, fa in zip(exp["frames"], act["frames"]):
        me = {k["name"]: k for k in fe["keypoints"]}
        ma = {k["name"]: k for k in fa["keypoints"]}
        for n in names:
            if n not in me or n not in ma:
                ok = False
                failures.append(f"[kp] missing keypoint name={n} at frame {fe.get('frameIndex')}")
                continue
            dx = abs(float(me[n]["x"]) - float(ma[n]["x"]))
            dy = abs(float(me[n]["y"]) - float(ma[n]["y"]))
            dz = abs(float(me[n]["z"]) - float(ma[n]["z"]))
            total_x += dx; total_y += dy; total_z += dz
            count += 1

    if count == 0:
        ok = False
        failures.append("[kp] no comparable keypoints found")
    else:
        mae_x = total_x/count
        mae_y = total_y/count
        mae_z = total_z/count
        print(f"[KP] MAE x/y/z = {mae_x:.6f} / {mae_y:.6f} / {mae_z:.6f}")
        if mae_x <= kp_eps_xy and mae_y <= kp_eps_xy and mae_z <= kp_eps_z:
            print(f"[OK] keypoints MAE within thresholds (xy≤{kp_eps_xy}, z≤{kp_eps_z})")
        else:
            ok = False
            failures.append(f"[X ] keypoints MAE exceeded thresholds: x={mae_x:.6f}, y={mae_y:.6f}, z={mae_z:.6f}")

    if not ok:
        print("\n[FAILURES]")
        for m in failures:
            print(m)
    else:
        print("[OK] neutral_keypoints.json checks PASS")
    return ok


def main():
    ap = argparse.ArgumentParser(description="Compare CLI outputs against expected artifacts.")
    # result.json
    ap.add_argument("--expected-result", required=True, help="expected result.json path")
    ap.add_argument("--actual-result",   required=True, help="actual result.json path")
    ap.add_argument("--eps-angle",   type=float, default=2.0, help="tolerance for angle fields in result.json (degrees)")
    ap.add_argument("--eps-quality", type=float, default=0.05, help="tolerance for quality fields in result.json")
    ap.add_argument("--eps-fps",     type=float, default=1.0, help="tolerance for fps difference in result.json")
    ap.add_argument("--strict-meta", action="store_true", help="require strict equality for meta fields (engine/version/sampling/video)")

    # angles.csv (optional)
    ap.add_argument("--expected-angles", help="expected angles.csv path")
    ap.add_argument("--actual-angles",   help="actual angles.csv path")
    ap.add_argument("--ang-mae", type=float, default=0.5, help="MAE threshold (degrees) for angles.csv columns")
    ap.add_argument("--ang-max", type=float, default=1.0, help="MaxAbsErr threshold (degrees) for angles.csv columns")

    # neutral_keypoints.json (optional)
    ap.add_argument("--expected-kp", help="expected neutral_keypoints.json path")
    ap.add_argument("--actual-kp",   help="actual neutral_keypoints.json path")
    ap.add_argument("--kp-eps-xy", type=float, default=0.003, help="MAE threshold for keypoints x/y (normal)")
    ap.add_argument("--kp-eps-z",  type=float, default=0.01,  help="MAE threshold for keypoints z (normal)")

    args = ap.parse_args()

    overall_ok = True

    # result.json is mandatory
    ok_res = compare_result_json(
        args.expected_result, args.actual_result,
        args.eps_angle, args.eps_quality, args.eps_fps,
        args.strict_meta
    )
    overall_ok = overall_ok and ok_res

    # optional angles.csv
    if args.expected_angles and args.actual_angles:
        ok_ang = compare_angles_csv(args.expected_angles, args.actual_angles, args.ang_mae, args.ang_max)
        overall_ok = overall_ok and ok_ang
    elif args.expected_angles or args.actual_angles:
        print("[WARN] angles.csv paths provided incompletely; skipping angles comparison.")

    # optional keypoints
    if args.expected_kp and args.actual_kp:
        ok_kp = compare_keypoints_json(args.expected_kp, args.actual_kp, args.kp_eps_xy, args.kp_eps_z, args.strict_meta)
        overall_ok = overall_ok and ok_kp
    elif args.expected_kp or args.actual_kp:
        print("[WARN] keypoints paths provided incompletely; skipping keypoints comparison.")

    if overall_ok:
        print("\n[ALL PASS] ✅")
        sys.exit(0)
    else:
        print("\n[FAILED] ❌")
        sys.exit(1)


if __name__ == "__main__":
    main()

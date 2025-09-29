#!/usr/bin/env python3
import argparse
import csv
import json
import math
from dataclasses import dataclass
from typing import List, Tuple

L_HIP = 11
L_KNEE = 13
L_ANKLE = 15
R_HIP = 12
R_KNEE = 14
R_ANKLE = 16
L_SHOULDER = 5
R_SHOULDER = 6


def round1(v: float) -> float:
    return round(v * 10.0) / 10.0


def round2(v: float) -> float:
    return round(v * 100.0) / 100.0


def round3(v: float) -> float:
    return round(v * 1000.0) / 1000.0


class OneEuroFilter:
    def __init__(self, min_cutoff: float = 1.0, beta: float = 0.005, d_cutoff: float = 1.0) -> None:
        self.min_cutoff = min_cutoff
        self.beta = beta
        self.d_cutoff = d_cutoff
        self._x_hat = None
        self._dx_hat = None
        self._last_t = None

    def _alpha(self, cutoff: float, dt: float) -> float:
        tau = 1.0 / (2.0 * math.pi * cutoff)
        return 1.0 / (1.0 + tau / dt)

    def _exp_smooth(self, x: float, prev: float, alpha: float) -> float:
        return x if prev is None else alpha * x + (1 - alpha) * prev

    def filter(self, t: float, x: float) -> float:
        if self._last_t is None:
            self._last_t = t
            self._x_hat = x
            self._dx_hat = 0.0
            return x
        dt = t - self._last_t
        if abs(dt) < 1e-9:
            dt = 1e-3
        self._last_t = t
        dx = (x - self._x_hat) / dt
        a_d = self._alpha(self.d_cutoff, dt)
        self._dx_hat = self._exp_smooth(dx, self._dx_hat, a_d)
        cutoff = self.min_cutoff + self.beta * abs(self._dx_hat)
        a_x = self._alpha(cutoff, dt)
        self._x_hat = self._exp_smooth(x, self._x_hat, a_x)
        return self._x_hat


@dataclass
class KPFrame:
    t: int
    pts: List[Tuple[float, float, float]]


@dataclass
class RuleSet:
    template: str
    version: str
    counts: dict
    phases: dict
    metrics: dict
    score_weights: dict
    strictness: dict


@dataclass
class Rep:
    start_ms: int
    valley_ms: int
    end_ms: int


def angle_abc(a: Tuple[float, float], b: Tuple[float, float], c: Tuple[float, float]) -> float:
    v1 = (a[0] - b[0], a[1] - b[1])
    v2 = (c[0] - b[0], c[1] - b[1])
    n1 = math.hypot(*v1)
    n2 = math.hypot(*v2)
    if n1 == 0 or n2 == 0:
        raise ValueError('zero length vector')
    cos_v = max(-1.0, min(1.0, (v1[0] * v2[0] + v1[1] * v2[1]) / (n1 * n2)))
    return math.degrees(math.acos(cos_v))


def trunk_angle(shoulder: Tuple[float, float], hip: Tuple[float, float]) -> float:
    v = (hip[0] - shoulder[0], hip[1] - shoulder[1])
    n = math.hypot(*v)
    if n == 0:
        raise ValueError('zero length trunk')
    cos_v = max(-1.0, min(1.0, v[1] / n))
    deg = math.degrees(math.acos(cos_v))
    return deg if deg <= 90 else 180 - deg


def angle_from_vertical(v: Tuple[float, float]) -> float:
    n = math.hypot(*v)
    if n == 0:
        raise ValueError('zero length limb')
    cos_v = max(-1.0, min(1.0, v[1] / n))
    deg = math.degrees(math.acos(cos_v))
    return deg if deg <= 90 else 180 - deg


def parse_keypoints(path: str) -> Tuple[float, List[KPFrame]]:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    fps = float(data['fps'])
    frames = []
    for frame in data['frames']:
        t = int(frame['t'])
        pts = []
        for raw in frame['pts']:
            x = float(raw[0])
            y = float(raw[1])
            score = float(raw[2]) if len(raw) > 2 else 0.0
            pts.append((x, y, score))
        frames.append(KPFrame(t, pts))
    return fps, frames


def parse_rules(path: str) -> RuleSet:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return RuleSet(
        template=data['template'],
        version=data['version'],
        counts=data['counts'],
        phases=data.get('phases', {}),
        metrics=data['metrics'],
        score_weights=data['scoreWeights'],
        strictness=data['strictness'],
    )


def filter_keypoints(frames: List[KPFrame]) -> List[List[Tuple[float, float, float]]]:
    filters = [(OneEuroFilter(), OneEuroFilter()) for _ in range(17)]
    smoothed: List[List[Tuple[float, float, float]]] = []
    for frame in frames:
        t_sec = frame.t / 1000.0
        pts: List[Tuple[float, float, float]] = []
        for i in range(17):
            x, y, score = frame.pts[i]
            if score <= 0:
                pts.append((x, y, score))
                continue
            fx = filters[i][0].filter(t_sec, x)
            fy = filters[i][1].filter(t_sec, y)
            pts.append((fx, fy, score))
        smoothed.append(pts)
    return smoothed


def compute_angles(smoothed: List[List[Tuple[float, float, float]]]):
    knee_l: List[float] = []
    knee_r: List[float] = []
    trunk_vals: List[float] = []
    for pts in smoothed:
        def valid(idx: int) -> bool:
            return pts[idx][2] > 0.0

        if valid(L_HIP) and valid(L_KNEE) and valid(L_ANKLE):
            knee_l.append(round1(angle_abc(pts[L_HIP][:2], pts[L_KNEE][:2], pts[L_ANKLE][:2])))
        else:
            knee_l.append(None)
        if valid(R_HIP) and valid(R_KNEE) and valid(R_ANKLE):
            knee_r.append(round1(angle_abc(pts[R_HIP][:2], pts[R_KNEE][:2], pts[R_ANKLE][:2])))
        else:
            knee_r.append(None)

        candidates = []
        if valid(L_SHOULDER) and valid(L_HIP):
            try:
                candidates.append(trunk_angle(pts[L_SHOULDER][:2], pts[L_HIP][:2]))
            except ValueError:
                pass
        if valid(R_SHOULDER) and valid(R_HIP):
            try:
                candidates.append(trunk_angle(pts[R_SHOULDER][:2], pts[R_HIP][:2]))
            except ValueError:
                pass
        if candidates:
            trunk_vals.append(round1(sum(candidates) / len(candidates)))
        else:
            trunk_vals.append(None)
    return knee_l, knee_r, trunk_vals


def main_knee_series(knee_l: List[float], knee_r: List[float]) -> List[float]:
    series = []
    for l, r in zip(knee_l, knee_r):
        if l is None and r is None:
            series.append(None)
        elif l is None:
            series.append(r)
        elif r is None:
            series.append(l)
        else:
            series.append(min(l, r))
    return series


def segment_down_up(t_ms: List[int], knee_main: List[float], min_ms: int) -> List[Tuple[int, int, bool]]:
    samples = [(t, angle) for t, angle in zip(t_ms, knee_main) if angle is not None]
    if len(samples) < 2:
        return []
    segs: List[Tuple[int, int, bool]] = []
    current = None
    seg_start = None
    prev_t, prev_angle = samples[0]
    for curr_t, curr_angle in samples[1:]:
        diff = curr_angle - prev_angle
        if abs(diff) < 1e-3:
            prev_t, prev_angle = curr_t, curr_angle
            continue
        is_down = diff < 0
        if current is None:
            current = is_down
            seg_start = prev_t
        elif is_down != current:
            seg_end = prev_t
            if seg_start is not None and seg_end - seg_start >= min_ms:
                segs.append((seg_start, seg_end, current))
            current = is_down
            seg_start = prev_t
        prev_t, prev_angle = curr_t, curr_angle
    if current is not None:
        seg_end = prev_t
        start = seg_start if seg_start is not None else samples[0][0]
        if seg_end - start >= min_ms:
            segs.append((start, seg_end, current))
    return segs


def count_reps(t_ms: List[int], knee_l: List[float], knee_r: List[float], min_interval_ms: int, window_ms: int, min_valley: float) -> List[Rep]:
    main_angles = main_knee_series(knee_l, knee_r)
    reps: List[Rep] = []
    last_end = None
    for i, (t, center_angle) in enumerate(zip(t_ms, main_angles)):
        if center_angle is None:
            continue
        left = i
        while left > 0 and t - t_ms[left - 1] <= window_ms:
            left -= 1
        right = i
        while right + 1 < len(t_ms) and t_ms[right + 1] - t <= window_ms:
            right += 1
        if left == i or right == i:
            continue
        has_higher_left = False
        has_higher_right = False
        strictly_lower = False
        for j in range(left, right + 1):
            v = main_angles[j]
            if v is None:
                continue
            if j < i:
                if v > center_angle + 1e-3:
                    has_higher_left = True
                if v < center_angle - 1e-3:
                    strictly_lower = True
                    break
            elif j > i:
                if v > center_angle + 1e-3:
                    has_higher_right = True
                if v < center_angle - 1e-3:
                    strictly_lower = True
                    break
        if strictly_lower or not has_higher_left or not has_higher_right:
            continue
        if center_angle >= min_valley:
            continue
        start_ms = t_ms[left]
        end_ms = t_ms[right]
        if last_end is not None and t - last_end < min_interval_ms:
            continue
        reps.append(Rep(start_ms, t, end_ms))
        last_end = end_ms
    return reps


def compute_quality(smoothed: List[List[Tuple[float, float, float]]]) -> Tuple[float, bool]:
    required = [L_HIP, R_HIP, L_KNEE, R_KNEE, L_ANKLE, R_ANKLE]
    ok = 0
    for pts in smoothed:
        if all(pts[idx][2] > 0.0 for idx in required):
            ok += 1
    coverage = 0.0 if not smoothed else ok / len(smoothed)
    return round3(coverage), coverage < 0.7


def angle_at(series: List[float], t_ms: List[int], target: int):
    for t, value in zip(t_ms, series):
        if t == target:
            return value
    return None


def indices_between(t_ms: List[int], start: int, end: int) -> List[int]:
    return [i for i, t in enumerate(t_ms) if start <= t <= end]


def knee_out_angle(pts: List[Tuple[float, float, float]], hip_idx: int, knee_idx: int, ankle_idx: int):
    if pts[hip_idx][2] <= 0 or pts[knee_idx][2] <= 0 or pts[ankle_idx][2] <= 0:
        return None
    hip = pts[hip_idx]
    knee = pts[knee_idx]
    ankle = pts[ankle_idx]
    try:
        thigh = (knee[0] - hip[0], knee[1] - hip[1])
        shank = (ankle[0] - knee[0], ankle[1] - knee[1])
        thigh_deg = angle_from_vertical(thigh)
        shank_deg = angle_from_vertical(shank)
        return (thigh_deg + shank_deg) / 2.0
    except ValueError:
        return None


def collect_rep_metrics(t_ms: List[int], main_knee: List[float], reps: List[Rep], trunk: List[float], smoothed: List[List[Tuple[float, float, float]]], valgus_window_ms: int):
    index_by_time = {t: idx for idx, t in enumerate(t_ms)}
    metrics = []
    for idx, rep in enumerate(reps):
        valley_angle = angle_at(main_knee, t_ms, rep.valley_ms)
        if valley_angle is None:
            raise RuntimeError(f'Missing valley angle for rep {idx + 1}')
        frame_indices = indices_between(t_ms, rep.start_ms, rep.end_ms)
        if not frame_indices:
            raise RuntimeError(f'No frames for rep {idx + 1}')
        max_trunk = None
        for fi in frame_indices:
            val = trunk[fi]
            if val is not None:
                max_trunk = val if max_trunk is None else max(max_trunk, val)
        if max_trunk is None:
            raise RuntimeError(f'Missing trunk for rep {idx + 1}')
        half_window = round(valgus_window_ms / 2)
        window_start = max(rep.start_ms, rep.valley_ms - half_window)
        window_end = min(rep.end_ms, rep.valley_ms + half_window)
        valgus_indices = indices_between(t_ms, window_start, window_end)
        if not valgus_indices and rep.valley_ms in index_by_time:
            valgus_indices = [index_by_time[rep.valley_ms]]
        min_knee_out = None
        for fi in valgus_indices:
            pts = smoothed[fi]
            candidates = []
            left = knee_out_angle(pts, L_HIP, L_KNEE, L_ANKLE)
            right = knee_out_angle(pts, R_HIP, R_KNEE, R_ANKLE)
            if left is not None:
                candidates.append(left)
            if right is not None:
                candidates.append(right)
            if candidates:
                frame_min = min(candidates)
                min_knee_out = frame_min if min_knee_out is None else min(min_knee_out, frame_min)
        if min_knee_out is None:
            raise RuntimeError(f'Missing knee valgus for rep {idx + 1}')
        eccentric = rep.valley_ms - rep.start_ms
        concentric = rep.end_ms - rep.valley_ms
        if eccentric <= 0 or concentric <= 0:
            raise RuntimeError(f'Invalid tempo for rep {idx + 1}')
        metrics.append({
            'kneeValleyAngle': valley_angle,
            'minKneeOutAngle': min_knee_out,
            'maxForwardLean': max_trunk,
            'eccentricMs': eccentric,
            'concentricMs': concentric,
            'ratio': eccentric / concentric,
        })
    return metrics


def score_from_bounds(value: float, a: float, b: float, lower_is_better: bool) -> float:
    best = min(a, b) if lower_is_better else max(a, b)
    worst = max(a, b) if lower_is_better else min(a, b)
    if abs(best - worst) < 1e-6:
        meets = value <= best if lower_is_better else value >= best
        return 100.0 if meets else 0.0
    if lower_is_better:
        if value <= best:
            return 100.0
        if value >= worst:
            return 0.0
        ratio = (value - best) / (worst - best)
        return max(0.0, min(100.0, (1 - ratio) * 100.0))
    else:
        if value >= best:
            return 100.0
        if value <= worst:
            return 0.0
        ratio = (value - worst) / (best - worst)
        return max(0.0, min(100.0, ratio * 100.0))


def score_range(value: float, low: float, high: float) -> float:
    lo, hi = sorted([low, high])
    if abs(hi - lo) < 1e-6:
        return 100.0 if abs(value - lo) < 1e-6 else 0.0
    if lo <= value <= hi:
        return 100.0
    span = hi - lo
    if value < lo:
        diff = lo - value
    else:
        diff = value - hi
    return max(0.0, min(100.0, (1 - diff / span) * 100.0))


def average(values: List[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def compute_scores(rep_metrics: List[dict], rules: RuleSet):
    if not rep_metrics:
        return {
            'form': 0.0,
            'stability': 0.0,
            'tempo': 0.0,
            'overall': 0.0,
        }
    metrics = rules.metrics
    depth = metrics['depth']['kneeAngleMin']
    trunk = metrics['trunk']['maxForwardLean']
    valgus = metrics['valgus']['kneeOutAngleMin']
    tempo = metrics['tempo']

    depth_scores = [score_from_bounds(m['kneeValleyAngle'], depth['strict'], depth['relaxed'], True) for m in rep_metrics]
    trunk_scores = [score_from_bounds(m['maxForwardLean'], trunk['strict'], trunk['relaxed'], True) for m in rep_metrics]
    valgus_scores = [score_from_bounds(m['minKneeOutAngle'], valgus['strict'], valgus['relaxed'], False) for m in rep_metrics]

    form_score = average([average(depth_scores), average(trunk_scores)])
    stability_score = average(valgus_scores)
    tempo_score = average([
        score_range(average([m['eccentricMs'] for m in rep_metrics]), tempo['eccentricMs'][0], tempo['eccentricMs'][1]),
        score_range(average([m['ratio'] for m in rep_metrics]), tempo['ratio'][0], tempo['ratio'][1]),
    ])

    weights = rules.score_weights
    overall = (form_score * weights['form'] + stability_score * weights['stability'] + tempo_score * weights['tempo'])
    return {
        'form': round1(form_score),
        'stability': round1(stability_score),
        'tempo': round1(tempo_score),
        'overall': round1(overall),
    }


def build_result_json(fps: float, t_ms: List[int], knee_l, knee_r, trunk, smoothed, rules: RuleSet, strictness: str):
    counts = rules.counts
    phases_min_ms = int(rules.phases.get('minMs', 250))
    main_knee = main_knee_series(knee_l, knee_r)
    phase_segments = segment_down_up(t_ms, main_knee, phases_min_ms)
    strict_profile = rules.strictness[strictness]
    min_valley = strict_profile['minValleyKneeAngle']
    reps = count_reps(
        t_ms,
        knee_l,
        knee_r,
        int(counts.get('minIntervalMs', 600)),
        int(counts.get('windowMs', 150)),
        min_valley,
    )
    quality = compute_quality(smoothed)

    metrics = collect_rep_metrics(
        t_ms,
        main_knee,
        reps,
        trunk,
        smoothed,
        int(rules.metrics['valgus'].get('windowMs', 200)),
    )

    rep_entries = []
    for idx, (rep, metric) in enumerate(zip(reps, metrics), start=1):
        rep_entries.append({
            'index': idx,
            'startMs': rep.start_ms,
            'valleyMs': rep.valley_ms,
            'endMs': rep.end_ms,
            'kneeValleyAngle': round1(metric['kneeValleyAngle']),
            'minKneeOutAngle': round1(metric['minKneeOutAngle']),
            'maxForwardLean': round1(metric['maxForwardLean']),
            'tempo': {
                'eccentricMs': metric['eccentricMs'],
                'concentricMs': metric['concentricMs'],
                'ratio': round2(metric['ratio']),
            },
        })

    evidence = []
    for start, end, is_down in phase_segments:
        evidence.append({
            'type': 'phaseDown' if is_down else 'phaseUp',
            'startMs': start,
            'endMs': end,
        })
    for rep in rep_entries:
        entry = {'type': 'rep'}
        entry.update(rep)
        evidence.append(entry)

    issue_map = {}
    rules_metrics = rules.metrics
    depth = rules_metrics['depth']['kneeAngleMin']
    depth_threshold = depth[strictness]
    valgus_threshold = rules_metrics['valgus']['kneeOutAngleMin'][strictness]
    trunk_threshold = rules_metrics['trunk']['maxForwardLean'][strictness]
    for rep, metric in zip(reps, metrics):
        if metric['kneeValleyAngle'] > depth_threshold + 1e-6:
            rec = issue_map.setdefault('DEPTH_INSUFFICIENT', {'code': 'DEPTH_INSUFFICIENT', 'frames': [], 'severity': 'major', 'worst': None})
            rec['frames'].append(rep.valley_ms)
            worst = rec['worst']
            rec['worst'] = metric['kneeValleyAngle'] if worst is None else max(worst, metric['kneeValleyAngle'])
            evidence.append({'type': 'issue', 'code': 'DEPTH_INSUFFICIENT', 'frameMs': rep.valley_ms, 'value': round1(metric['kneeValleyAngle'])})
        if metric['minKneeOutAngle'] < valgus_threshold - 1e-6:
            rec = issue_map.setdefault('KNEE_VALGUS', {'code': 'KNEE_VALGUS', 'frames': [], 'severity': 'major', 'worst': None})
            rec['frames'].append(rep.valley_ms)
            worst = rec['worst']
            rec['worst'] = metric['minKneeOutAngle'] if worst is None else min(worst, metric['minKneeOutAngle'])
            evidence.append({'type': 'issue', 'code': 'KNEE_VALGUS', 'frameMs': rep.valley_ms, 'value': round1(metric['minKneeOutAngle'])})
        if metric['maxForwardLean'] > trunk_threshold + 1e-6:
            rec = issue_map.setdefault('TRUNK_LEAN_EXCESSIVE', {'code': 'TRUNK_LEAN_EXCESSIVE', 'frames': [], 'severity': 'moderate', 'worst': None})
            rec['frames'].append(rep.valley_ms)
            worst = rec['worst']
            rec['worst'] = metric['maxForwardLean'] if worst is None else max(worst, metric['maxForwardLean'])
            evidence.append({'type': 'issue', 'code': 'TRUNK_LEAN_EXCESSIVE', 'frameMs': rep.valley_ms, 'value': round1(metric['maxForwardLean'])})

    issues = []
    for rec in issue_map.values():
        rec['frames'].sort()
        if rec['worst'] is not None:
            rec['worst'] = round1(rec['worst'])
        issues.append(rec)

    scores = compute_scores(metrics, rules)
    return {
        'meta': {
            'template': rules.template,
            'fps': fps,
            'ruleVersion': rules.version,
            'strictness': strictness,
        },
        'quality': {
            'coverage': quality[0],
            'lowConfidence': quality[1],
        },
        'repCount': len(reps),
        'reps': rep_entries,
        'scores': scores,
        'issues': issues,
        'evidence': evidence,
    }, phase_segments, reps


def write_angles_csv(path: str, t_ms: List[int], knee_l, knee_r, trunk):
    with open(path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['t_ms', 'knee_L', 'knee_R', 'trunk_deg'])
        for t, kl, kr, tr in zip(t_ms, knee_l, knee_r, trunk):
            writer.writerow([
                t,
                '' if kl is None else kl,
                '' if kr is None else kr,
                '' if tr is None else tr,
            ])


def run(kp_path: str, rule_path: str, out_csv: str, out_json: str, strictness: str):
    fps, frames = parse_keypoints(kp_path)
    rules = parse_rules(rule_path)
    smoothed = filter_keypoints(frames)
    knee_l, knee_r, trunk = compute_angles(smoothed)
    t_ms = [f.t for f in frames]
    write_angles_csv(out_csv, t_ms, knee_l, knee_r, trunk)
    result_json, _, _ = build_result_json(fps, t_ms, knee_l, knee_r, trunk, smoothed, rules, strictness)
    with open(out_json, 'w', encoding='utf-8') as f:
        json.dump(result_json, f, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--kp', required=True)
    parser.add_argument('--rule', required=True)
    parser.add_argument('--angles', required=True)
    parser.add_argument('--result', required=True)
    parser.add_argument('--strictness', default='relaxed')
    args = parser.parse_args()
    run(args.kp, args.rule, args.angles, args.result, args.strictness)

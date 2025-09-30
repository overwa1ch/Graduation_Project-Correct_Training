#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Milestone A script (v1.1-compatible)
- Accepts v1.1 squat.v1.json schema (template/version/counts/phases/metrics/scoreWeights/strictness)
- Accepts keypoints in array-of-triples format: pts: [[x,y,score]*N]
- Outputs angles.csv and result.json with the same format/precision contract as v1.1
Note: This is a minimal, tolerant parser aimed to unblock alignment; logic mirrors the prior script where feasible.
"""

import argparse, json, os, sys, math
from typing import Any, Dict, List, Tuple

def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def save_json(path: str, obj: Dict[str, Any]):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)

def write_csv(path: str, rows: List[List[Any]]):
    with open(path, "w", encoding="utf-8") as f:
        for r in rows:
            f.write(",".join("" if x is None else str(x) for x in r) + "\n")

def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))

def angle_deg(a, b, c) -> float:
    import math
    ax, ay = a; bx, by = b; cx, cy = c
    bax = ax - bx; bay = ay - by
    bcx = cx - bx; bcy = cy - by
    nb = math.hypot(bax, bay) or 1e-9
    nc = math.hypot(bcx, bcy) or 1e-9
    cosv = ((bax*bcx + bay*bcy) / (nb*nc))
    cosv = clamp(cosv, -1.0, 1.0)
    return math.degrees(math.acos(cosv))

def trunk_forward_deg(shoulder, hip) -> float:
    # pixel coords: y increases downward; vertical up vector is (0,-1)
    import math
    vx = hip[0]-shoulder[0]; vy = hip[1]-shoulder[1]
    n = math.hypot(vx, vy) or 1e-9
    cosv = (-(vy)/n) # dot with (0,-1)
    cosv = clamp(cosv, -1.0, 1.0)
    theta = math.degrees(math.acos(cosv))  # angle to vertical
    return abs(theta) if theta <= 90 else 180-theta

class OneEuro:
    def __init__(self, freq: float, min_cutoff=1.0, beta=0.005, d_cutoff=1.0):
        self.freq = float(freq); self.min_cutoff=float(min_cutoff); self.beta=float(beta); self.d_cutoff=float(d_cutoff)
        self.x_prev=None; self.dx_prev=None
    def _alpha(self, cutoff):
        tau = 1.0 / (2.0 * math.pi * cutoff)
        te = 1.0 / self.freq
        return 1.0 / (1.0 + tau / te)
    def filter(self, x: float) -> float:
        if self.x_prev is None:
            self.x_prev = x; self.dx_prev = 0.0; return x
        dx = (x - self.x_prev) * self.freq
        a_d = self._alpha(self.d_cutoff)
        dx_hat = a_d * dx + (1 - a_d) * self.dx_prev
        cutoff = self.min_cutoff + self.beta * abs(dx_hat)
        a = self._alpha(cutoff)
        x_hat = a * x + (1 - a) * self.x_prev
        self.x_prev = x_hat; self.dx_prev = dx_hat
        return x_hat

def parse_rule_v11(rule_dict: Dict[str, Any]) -> Dict[str, Any]:
    # tolerate extra fields like 'template'
    out = dict(rule_dict)
    out.pop('template', None)
    # required keys
    for k in ('version','counts','phases','metrics','scoreWeights','strictness'):
        if k not in out:
            raise RuntimeError(f"RULES_PARSE_ERROR: missing '{k}' in rule json")
    return out

def read_kp_array_triple(path: str) -> Tuple[float, List[Dict[str, Any]]]:
    data = load_json(path)
    fps = float(data.get('fps', 30))
    frames_out = []
    for fr in data.get('frames', []):
        pts = fr.get('pts', [])
        pts_arr = []
        for p in pts:
            if isinstance(p, list) and len(p) >= 3:
                pts_arr.append([float(p[0]), float(p[1]), float(p[2])])
            elif isinstance(p, dict):
                pts_arr.append([float(p.get('x', 0.0)), float(p.get('y', 0.0)), float(p.get('score', 0.0))])
            else:
                pts_arr.append([0.0, 0.0, 0.0])
        frames_out.append({'t': int(fr.get('t', 0)), 'pts': pts_arr})
    return fps, frames_out

# MoveNet17 indices (A stage)
L_SH, R_SH = 5, 6
L_HIP, R_HIP = 11, 12
L_KN, R_KN = 13, 14
L_AN, R_AN = 15, 16

def compute_quality(frames: List[Dict[str,Any]], th=0.5) -> float:
    good = 0
    for fr in frames:
        pts = fr['pts']
        ok = True
        for i in (L_HIP,R_HIP,L_KN,R_KN,L_AN,R_AN):
            if i >= len(pts) or pts[i][2] < th:
                ok = False; break
        if ok: good += 1
    return good / max(1, len(frames))

def pipeline(
    kp_path: str,
    rule_path: str,
    strictness: str,
    angles_path: str,
    result_path: str,
    quality_th: float,
    fps_override: float = None,
):
    rule_raw = load_json(rule_path)
    rule = parse_rule_v11(rule_raw)
    fps, frames = read_kp_array_triple(kp_path)
    if fps_override: fps = float(fps_override)

    # quality
    coverage = compute_quality(frames, th=0.5)
    low_conf = coverage < quality_th

    # filters
    f_kL=OneEuro(fps); f_kR=OneEuro(fps); f_tr=OneEuro(fps)

    rows = [['t_ms','knee_L','knee_R','trunk_deg']]
    ts=[]; kL=[]; kR=[]; trA=[]
    for fr in frames:
        t=fr['t']; pts=fr['pts']
        def p(i): return (pts[i][0], pts[i][1]) if i < len(pts) else (float('nan'), float('nan'))
        try:
            aL=angle_deg(p(L_HIP), p(L_KN), p(L_AN))
            aR=angle_deg(p(R_HIP), p(R_KN), p(R_AN))
            shoulder=((p(L_SH)[0]+p(R_SH)[0])/2.0, (p(L_SH)[1]+p(R_SH)[1])/2.0)
            hip=((p(L_HIP)[0]+p(R_HIP)[0])/2.0, (p(L_HIP)[1]+p(R_HIP)[1])/2.0)
            tr=trunk_forward_deg(shoulder, hip)
        except Exception:
            aL=aR=tr=float('nan')
        if not math.isnan(aL): aL=f_kL.filter(aL)
        if not math.isnan(aR): aR=f_kR.filter(aR)
        if not math.isnan(tr): tr=f_tr.filter(tr)
        rows.append([t, f"{aL:.3f}" if not math.isnan(aL) else "", f"{aR:.3f}" if not math.isnan(aR) else "", f"{tr:.3f}" if not math.isnan(tr) else ""])
        ts.append(t); kL.append(aL); kR.append(aR); trA.append(tr)

    # knee_main
    import numpy as np
    t_arr=np.array(ts, dtype=int) if ts else np.array([], dtype=int)
    kL_arr=np.array(kL, dtype=float) if kL else np.array([], dtype=float)
    kR_arr=np.array(kR, dtype=float) if kR else np.array([], dtype=float)
    tr_arr=np.array(trA, dtype=float) if trA else np.array([], dtype=float)
    knee_main=np.fmin(kL_arr, kR_arr)

    # phases/counts (simplified; aligned with v1.1 thresholds)
    counts=rule['counts']; phases=rule.get('phases',{}); metrics=rule['metrics']; weights=rule['scoreWeights']
    min_interval=int(counts.get('minIntervalMs',600))
    window_ms=int(counts.get('windowMs',150))
    valley_th=float(rule['strictness'][strictness]['minValleyKneeAngle'])

    d_step=3.0
    min_ms=int(phases.get('minMs', 250))

    # rough phase segmentation
    segs=[]; curr=None
    for i in range(len(t_arr)):
        if i==0: trend=0
        else:
            diff=knee_main[i]-knee_main[i-1]
            trend= -1 if diff<=-d_step else (1 if diff>=d_step else 0)
        name= 'Down' if trend<0 else ('Up' if trend>0 else None)
        if name is None:
            if curr is not None:
                curr['t1']=t_arr[i]
                if curr['t1']-curr['t0']>=min_ms: segs.append(curr)
                curr=None
        else:
            if curr is None or curr['name']!=name:
                if curr is not None:
                    curr['t1']=t_arr[i]
                    if curr['t1']-curr['t0']>=min_ms: segs.append(curr)
                curr={'name':name,'t0':t_arr[i]}
    if curr is not None:
        curr['t1']=int(t_arr[-1])
        if curr['t1']-curr['t0']>=min_ms: segs.append(curr)

    reps=[]; last_end=-10**9; i=0
    while i < len(segs)-1:
        a=segs[i]; b=segs[i+1]
        if a['name']=='Down' and b['name']=='Up':
            if (a['t0']-last_end) < min_interval: i+=1; continue
            import numpy as np
            lo=int(np.searchsorted(t_arr, a['t0']))
            hi=int(np.searchsorted(t_arr, b['t1'], side='right'))
            if hi<=lo: i+=1; continue
            seg_vals=knee_main[lo:hi]; seg_times=t_arr[lo:hi]
            j=int(np.nanargmin(seg_vals)); t_valley=int(seg_times[j]); knee_min=float(seg_vals[j])
            if knee_min <= valley_th:
                reps.append({'id':len(reps)+1,'t_start':int(a['t0']),'t_valley':t_valley,'t_end':int(b['t1']),'knee_min':round(knee_min,2)})
                last_end=b['t1']; i+=2
            else:
                i+=1
        else:
            i+=1

    # metrics→scores
    def_range=metrics['depth']['kneeAngleMin'][strictness]
    trunk_th=metrics['trunk']['maxForwardLean'][strictness]
    # depth
    depth_pen=0.0; hits=0; worst_depth=(-1.0,None)
    for r in reps:
        deficit=max(0.0, r['knee_min']-def_range)
        depth_pen += deficit; hits+=1
        if deficit>0 and (worst_depth[0]<deficit): worst_depth=(deficit, r['t_valley'])
    # trunk
    import numpy as np
    max_tr=float(np.nanmax(tr_arr)) if tr_arr.size else 0.0
    trunk_def=max(0.0, max_tr-trunk_th)

    # tempo
    ecc_lo,ecc_hi=metrics['tempo']['eccentricMs']
    ratio_lo,ratio_hi=metrics['tempo']['ratio']
    tempo_pen=0.0; tempo_hits=0
    for r in reps:
        ecc=r['t_valley']-r['t_start']; con=r['t_end']-r['t_valley']
        if ecc<=0 or con<=0: continue
        tempo_hits+=1
        ratio=ecc/max(1,con); pen=0.0
        if not (ecc_lo<=ecc<=ecc_hi):
            dist=min(abs(ecc-ecc_lo), abs(ecc-ecc_hi)); pen+=dist/1000.0*10
        if not (ratio_lo<=ratio<=ratio_hi):
            dist=min(abs(ratio-ratio_lo), abs(ratio-ratio_hi)); pen+=dist*10
        tempo_pen+=pen

    # stability（简化）
    stab_pen=0.0
    if len(knee_main)>=5:
        # 整段近似：使用总体标准差做罚分近似（A阶段）
        import numpy as np
        stab_pen=float(np.nanstd(knee_main))*2.0

    form = max(0.0, 100.0 - ((depth_pen/(hits or 1))*2.0 + trunk_def*1.5))
    stability = max(0.0, 100.0 - stab_pen)
    tempo = max(0.0, 100.0 - (tempo_pen if tempo_hits else 0.0))

    total = form*weights.get('form',0.5) + stability*weights.get('stability',0.25) + tempo*weights.get('tempo',0.25)

    # evidence（最坏帧+代表帧）
    evidence=[]
    if worst_depth[1] is not None:
        evidence.append({'type':'depth','kind':'worst','atMs':int(worst_depth[1])})
    if trunk_def>0 and tr_arr.size:
        import numpy as np
        idx=int(np.nanargmax(tr_arr))
        evidence.append({'type':'trunk','kind':'worst','atMs':int(t_arr[idx])})
    if reps:
        mid=int((reps[0]['t_start']+reps[0]['t_end'])//2)
        evidence.append({'type':'depth','kind':'repr','atMs':mid})

    # output
    def ensure_parent(path: str):
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)

    ensure_parent(angles_path)
    ensure_parent(result_path)

    write_csv(angles_path, rows)
    result={
        'meta': {'fps': fps, 'ruleVersion': rule.get('version','1.0.0'), 'strictness': strictness},
        'quality': {'coverage': round(coverage,3), 'lowConfidence': coverage < quality_th},
        'reps': len(reps),
        'scores': {'overall': round(total,1), 'form': round(form,1), 'stability': round(stability,1), 'tempo': round(tempo,1)},
        'issues': [],
        'evidence': evidence
    }
    save_json(result_path, result)
    print(f"[OK] total reps={len(reps)}  total={result['scores']['overall']}  coverage={result['quality']['coverage']}  lowConf={result['quality']['lowConfidence']}")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--kp', '--keypoints', dest='keypoints', default=r"D:\Graduation_Project-Correct_Training-main\Graduation_Project-Correct_Training\data\kp_sample.json")
    ap.add_argument('--rule', default=r"D:\Graduation_Project-Correct_Training-main\Graduation_Project-Correct_Training\data\squat.v1.json")
    ap.add_argument('--angles', help='Path to write the generated angles CSV file')
    ap.add_argument('--result', help='Path to write the generated result JSON file')
    ap.add_argument('--strictness', default='relaxed', choices=['relaxed','strict'])
    ap.add_argument('--out', default=r"D:\Graduation_Project-Correct_Training-main\Graduation_Project-Correct_Training\aiwa_milestone_a\tools\baseline_outputs")
    ap.add_argument('--quality_th', type=float, default=0.7)
    ap.add_argument('--fps', type=float, default=None)
    args=ap.parse_args()
    try:
        out_dir = args.out
        angles_path = args.angles or os.path.join(out_dir, 'angles.csv')
        result_path = args.result or os.path.join(out_dir, 'result.json')
        pipeline(args.keypoints, args.rule, args.strictness, angles_path, result_path, args.quality_th, args.fps)
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr); sys.exit(2)

if __name__=='__main__':
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Milestone A script (v1.1-compatible, aligned with Dart golden)
- 接收 v1.1 squat.v1.json 规则
- 接收 vB1.1 格式 keypoints (neutral keypoint series)
- 输出 angles.csv 与 result.json，字段与 Dart 侧 golden 对齐：
  - angles.csv: 表头 + t_ms,knee_L,knee_R,trunk_deg
  - result.json: { meta, quality, repCount, reps[], scores, issues[], evidence[] }
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
    ax, ay = a; bx, by = b; cx, cy = c
    bax = ax - bx; bay = ay - by
    bcx = cx - bx; bcy = cy - by
    nb = math.hypot(bax, bay) or 1e-9
    nc = math.hypot(bcx, bcy) or 1e-9
    cosv = ((bax*bcx + bay*bcy) / (nb*nc))
    cosv = clamp(cosv, -1.0, 1.0)
    return math.degrees(math.acos(cosv))

def trunk_forward_deg(shoulder, hip) -> float:
    # 像素坐标 y 向下为正；与竖直向上 (0,-1) 的夹角
    vx = hip[0]-shoulder[0]; vy = hip[1]-shoulder[1]
    n = math.hypot(vx, vy) or 1e-9
    cosv = (-(vy)/n)
    cosv = clamp(cosv, -1.0, 1.0)
    theta = math.degrees(math.acos(cosv))  # 0..180
    return theta if theta <= 90 else 180 - theta

class OneEuro:
    def __init__(self, freq: float, min_cutoff=1.0, beta=0.005, d_cutoff=1.0):
        self.freq = float(freq)
        self.min_cutoff=float(min_cutoff)
        self.beta=float(beta)
        self.d_cutoff=float(d_cutoff)
        self.x_prev=None
        self.dx_prev=None
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
    out = dict(rule_dict)
    for k in ('version','counts','phases','metrics','scoreWeights','strictness'):
        if k not in out:
            raise RuntimeError(f"RULES_PARSE_ERROR: missing '{k}'")
    return out

def read_kp_vb11(path: str) -> Tuple[float, List[Dict[str, Any]]]:
    """读取 vB1.1 格式关键点数据，转换为内部处理格式"""
    data = load_json(path)
    
    # 验证版本
    version = data.get('version', '')
    if version != 'vB1.1':
        raise RuntimeError(f"Unsupported keypoints version '{version}' (expected vB1.1)")
    
    # 提取元数据
    sampling = data.get('sampling', {})
    fps = float(sampling.get('effectiveFps', 30.0))
    
    video = data.get('video', {})
    width = float(video.get('width', 1))
    height = float(video.get('height', 1))
    
    # MoveNet17 关键点名称映射（按索引顺序）
    movenet17_names = [
        'nose', 'left_eye', 'right_eye', 'left_ear', 'right_ear',
        'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
        'left_wrist', 'right_wrist', 'left_hip', 'right_hip',
        'left_knee', 'right_knee', 'left_ankle', 'right_ankle'
    ]
    
    frames_out = []
    for fr in data.get('frames', []):
        timestamp_ms = int(fr.get('timestampMs', 0))
        keypoints = fr.get('keypoints', [])
        
        # 构建名称到关键点的映射
        kp_map = {kp['name']: kp for kp in keypoints}
        
        # 按 MoveNet17 顺序提取关键点，将归一化坐标转换为像素坐标
        pts_arr = []
        for name in movenet17_names:
            if name in kp_map:
                kp = kp_map[name]
                x_pixel = float(kp.get('x', 0.0)) * width
                y_pixel = float(kp.get('y', 0.0)) * height
                score = float(kp.get('score', 0.0))
                pts_arr.append([x_pixel, y_pixel, score])
            else:
                # 缺失的关键点使用零分
                pts_arr.append([0.0, 0.0, 0.0])
        
        frames_out.append({'t': timestamp_ms, 'pts': pts_arr})
    
    return fps, frames_out

# 向后兼容别名
read_kp_array_triple = read_kp_vb11

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
    import numpy as np

    rule_raw = load_json(rule_path)
    rule = parse_rule_v11(rule_raw)
    fps, frames = read_kp_array_triple(kp_path)
    if fps_override: fps = float(fps_override)

    # quality
    coverage = compute_quality(frames, th=0.5)
    low_conf = coverage < quality_th

    # filters on ANGLES only
    f_kL=OneEuro(fps); f_kR=OneEuro(fps); f_tr=OneEuro(fps)

    # angles
    rows = [['t_ms','knee_L','knee_R','trunk_deg']]
    ts=[]; kL=[]; kR=[]; trA=[]
    for fr in frames:
        t=fr['t']; pts=fr['pts']
        def p(i): 
            return (pts[i][0], pts[i][1]) if i < len(pts) else (float('nan'), float('nan'))
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

    # arrays
    t_arr=np.array(ts, dtype=int) if ts else np.array([], dtype=int)
    kL_arr=np.array(kL, dtype=float) if kL else np.array([], dtype=float)
    kR_arr=np.array(kR, dtype=float) if kR else np.array([], dtype=float)
    tr_arr=np.array(trA, dtype=float) if trA else np.array([], dtype=float)
    knee_main=np.fmin(kL_arr, kR_arr)
    # -------- LOCF 仅用于分段（修复 NaN 造成的相位滞后）--------
    km_seg = knee_main.copy()
    if km_seg.size:
        import numpy as np
        mask = ~np.isnan(km_seg)
        if mask.any():
            first = int(np.argmax(mask))  # 第一个非 NaN 的下标
            # 用第一个有效值填充开头那段 NaN
            km_seg[:first] = km_seg[first]
            # 前向填充：遇到 NaN 用上一帧的值
            for i in range(first + 1, km_seg.size):
                if np.isnan(km_seg[i]):
                    km_seg[i] = km_seg[i - 1]
        else:
            # 全 NaN 的极端情况：用 0（或干脆跳过分段，按你需求）
            km_seg[:] = 0.0
    # -----------------------------------------------------------
    # thresholds
    counts=rule['counts']; phases=rule.get('phases',{}); metrics=rule['metrics']; weights=rule['scoreWeights']
    min_interval=int(counts.get('minIntervalMs',600))
    window_ms=int(counts.get('windowMs',150))
    valley_th=float(rule['strictness'][strictness]['minValleyKneeAngle'])
    d_step=3.0
    min_ms=int(phases.get('minMs', 250))

    # ------------- Segmentation (use km_seg for trend; anchor at PREVIOUS frame) -------------
    segs = []
    curr = None

    def _ts_prev(i: int) -> int:
        # 取“上一帧”时间戳；如果没有上一帧（i==0），就用第 0 帧
        j = i - 1
        if j >= 0:
            return int(t_arr[j])
        return int(t_arr[0])

    for i in range(len(t_arr)):
        if i == 0:
            trend = 0
        else:
            diff = km_seg[i] - km_seg[i - 1]   # ✅ 仍用填充后的 km_seg 判定趋势
            trend = -1 if diff <= -d_step else (1 if diff >= d_step else 0)

        name = 'Down' if trend < 0 else ('Up' if trend > 0 else None)

        if name is None:
            if curr is not None:
                curr['t1'] = _ts_prev(i)       # ✅ 结束边界：上一帧
                if curr['t1'] - curr['t0'] >= min_ms:
                    segs.append(curr)
                curr = None
        else:
            if curr is None or curr['name'] != name:
                if curr is not None:
                    curr['t1'] = _ts_prev(i)   # ✅ 结束边界：上一帧
                    if curr['t1'] - curr['t0'] >= min_ms:
                        segs.append(curr)
                curr = {'name': name, 't0': _ts_prev(i)}  # ✅ 开始边界：上一帧

    # 尾段收尾保持不变（用最后一帧时间）
    if curr is not None:
        curr['t1'] = int(t_arr[-1])
        if curr['t1'] - curr['t0'] >= min_ms:
            segs.append(curr)
    # ------------------------------------------------------------------------------------------



    # reps: Down 后接 Up，窗口 valley<=阈值
    reps=[]; last_end=-10**9; i=0
    while i < len(segs)-1:
        a=segs[i]; b=segs[i+1]
        if a['name']=='Down' and b['name']=='Up':
            if (a['t0']-last_end) < min_interval:
                i+=1; continue
            lo=int(np.searchsorted(t_arr, a['t0']))                 # 左闭
            hi=int(np.searchsorted(t_arr, b['t1'], side='right'))   # 右开
            if hi<=lo:
                i+=1; continue
            seg_vals=knee_main[lo:hi]; seg_times=t_arr[lo:hi]
            j=int(np.nanargmin(seg_vals)); t_valley=int(seg_times[j]); knee_min=float(seg_vals[j])
            if knee_min <= valley_th:
                reps.append({'id':len(reps)+1,'t_start':int(a['t0']),'t_valley':t_valley,'t_end':int(b['t1']),'knee_min':round(knee_min,2)})
                last_end=b['t1']; i+=2
            else:
                i+=1
        else:
            i+=1

    # metrics → scores（近似，与先前一致）
    def_range=metrics['depth']['kneeAngleMin'][strictness]
    trunk_th=metrics['trunk']['maxForwardLean'][strictness]

    depth_pen=0.0; hits=0; worst_depth=(-1.0,None)
    for r in reps:
        deficit=max(0.0, r['knee_min']-def_range)
        depth_pen += deficit; hits+=1
        if deficit>0 and (worst_depth[0]<deficit): worst_depth=(deficit, r['t_valley'])

    max_tr = float(np.nanmax(tr_arr)) if tr_arr.size else 0.0
    trunk_def=max(0.0, max_tr-trunk_th)

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

    stab_pen=0.0
    if len(knee_main)>=5:
        stab_pen=float(np.nanstd(knee_main))*2.0

    form = max(0.0, 100.0 - ((depth_pen/(hits or 1))*2.0 + trunk_def*1.5))
    stability = max(0.0, 100.0 - stab_pen)
    tempo = max(0.0, 100.0 - (tempo_pen if tempo_hits else 0.0))
    total = form*weights.get('form',0.5) + stability*weights.get('stability',0.25) + tempo*weights.get('tempo',0.25)

    # evidence：phase / rep（issue 暂留空）
    phase_evidence = []
    for s in segs:
        t0, t1 = int(s['t0']), int(s['t1'])
        if s['name']=='Down':
            phase_evidence.append({'type': 'phaseDown', 'startMs': t0, 'endMs': t1})
        elif s['name']=='Up':
            phase_evidence.append({'type': 'phaseUp', 'startMs': t0, 'endMs': t1})

    rep_evidence = [
        {
            'type': 'rep',
            'index': i + 1,
            'startMs': r['t_start'],
            'valleyMs': r['t_valley'],
            'endMs': r['t_end'],
            'kneeValleyAngle': round(r['knee_min'], 2)
        }
        for i, r in enumerate(reps)
    ]

    evidence = phase_evidence + rep_evidence

    # 与 Dart 对齐的 reps 列表
    reps_list = [
        {
            'index': i + 1,
            'startMs': r['t_start'],
            'valleyMs': r['t_valley'],
            'endMs': r['t_end'],
            'kneeValleyAngle': round(r['knee_min'], 2),
        }
        for i, r in enumerate(reps)
    ]

    # 输出
    def ensure_parent(path: str):
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)

    ensure_parent(angles_path)
    ensure_parent(result_path)

    write_csv(angles_path, rows)
    result={
        'meta': {'fps': fps, 'ruleVersion': rule.get('version','1.0.0'), 'strictness': strictness},
        'quality': {'coverage': round(coverage,3), 'lowConfidence': low_conf},
        'repCount': len(reps),
        'reps': reps_list,
        'scores': {'overall': round(total,1), 'form': round(form,1), 'stability': round(stability,1), 'tempo': round(tempo,1)},
        'issues': [],
        'evidence': evidence
    }
    save_json(result_path, result)
    print(f"[OK] repCount={len(reps)}  overall={result['scores']['overall']}  coverage={result['quality']['coverage']}  lowConf={result['quality']['lowConfidence']}")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--kp','--keypoints',dest='keypoints', default=r"../test/fixtures/kp_sample.json")
    ap.add_argument('--rule', default=r"../test/fixtures/squat.v1.json")
    ap.add_argument('--angles', help='Path to write angles CSV')
    ap.add_argument('--result', help='Path to write result JSON')
    ap.add_argument('--strictness', default='relaxed', choices=['relaxed','strict'])
    ap.add_argument('--out', default=r"./tools/baseline_outputs")
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

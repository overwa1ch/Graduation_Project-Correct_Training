import json, math, sys, pathlib

def load(p): 
    return json.loads(pathlib.Path(p).read_text())

def near(a,b,eps): 
    if a is None or b is None: return False
    return abs(a-b) <= eps

exp = load("examples/squat_normal/expected/result.json")
act = load("build/offline_out/squat_normal/result.json")

def get_reps_angles(obj):
    out=[]
    for rep in obj.get("reps", []):
        out.append({
          "kneeValleyAngle": rep.get("kneeValleyAngle"),
          "minKneeOutAngle": rep.get("minKneeOutAngle"),
          "maxForwardLean": rep.get("maxForwardLean"),
        })
    return out

ok=True
# 角度
ea, aa = get_reps_angles(exp), get_reps_angles(act)
if len(ea)!=len(aa):
    print(f"[X] reps 数量不同: expected={len(ea)} actual={len(aa)}"); ok=False
for i,(e,a) in enumerate(zip(ea,aa)):
    for k in e.keys():
        if not near(e[k], a.get(k), 2.0):
            print(f"[X] rep#{i} {k}: expected={e[k]} actual={a.get(k)} (±2.0)"); ok=False

# 质量
eq, aq = exp.get("quality",{}), act.get("quality",{})
for k,eps in {"lowConfidence":0.05,"coverage":0.05,"scoreImpact":0.05}.items():
    if not near(eq.get(k), aq.get(k), eps):
        print(f"[X] quality.{k}: expected={eq.get(k)} actual={aq.get(k)} (±{eps})"); ok=False

# fps（顶层或 meta.fps）
def resolve_fps(root):
    meta=root.get("meta") or {}
    return meta.get("fps") or root.get("fps")
if not near(float(resolve_fps(exp) or 15), float(resolve_fps(act) or 15), 1.0):
    print(f"[X] fps 不在容差内"); ok=False

print("[OK] 数值容差检查通过" if ok else "[X] 存在差异")

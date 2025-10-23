import 'dart:math' as math;

/// 2D 向量
class V2 {
  final double x, y;
  const V2(this.x, this.y);
}

double _deg(num rad) => rad * 180.0 / math.pi;

/// ∠(A–B–C) in degrees, 0..180; 若任一向量长度为0则抛异常
double angleABC(V2 a, V2 b, V2 c) {
  final v1 = V2(a.x - b.x, a.y - b.y);
  final v2 = V2(c.x - b.x, c.y - b.y);
  final n1 = math.sqrt(v1.x * v1.x + v1.y * v1.y);
  final n2 = math.sqrt(v2.x * v2.x + v2.y * v2.y);
  if (n1 == 0 || n2 == 0) {
    throw StateError('Zero-length vector');
  }
  final cosv = ((v1.x * v2.x + v1.y * v2.y) / (n1 * n2)).clamp(-1.0, 1.0);
  return _deg(math.acos(cosv));
}

/// 躯干角：夹角(shoulder→hip, 垂直方向(0,1))；前倾为正，范围 0..90
double trunkAngle(V2 shoulder, V2 hip) {
  final v = V2(hip.x - shoulder.x, hip.y - shoulder.y); // 向下为正y（像素坐标）
  final n = math.sqrt(v.x * v.x + v.y * v.y);
  if (n == 0) throw StateError('Zero-length trunk');
  // 与竖直(0,1)夹角，向量夹角 0..180；取 0..90
  final cosv = (v.y / n).clamp(-1.0, 1.0);
  final deg = _deg(math.acos(cosv));
  return deg <= 90 ? deg : 180 - deg;
}

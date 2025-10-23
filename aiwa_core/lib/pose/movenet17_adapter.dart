// 索引常量：MoveNet17
const L_HIP = 11, L_KNEE = 13, L_ANKLE = 15;
const R_HIP = 12, R_KNEE = 14, R_ANKLE = 16;
const L_SHOULDER = 5, L_HIP_IDX = 11; // trunk 使用左/右平均？v1.1 采用“单侧”定义：肩→髋向量
const R_SHOULDER = 6, R_HIP_IDX = 12;

class MoveNet17Adapter {
  static bool valid(List<List<num>> pts, int idx) => pts[idx][2] > 0.0;
}

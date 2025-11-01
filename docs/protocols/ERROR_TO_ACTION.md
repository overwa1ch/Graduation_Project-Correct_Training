# ERROR_TO_ACTION.md

**Error Code → UI Action Mapping**
**Version:** v1.1 *(以实际代码实现为准)*

## 标准错误码（来自 event_bus.dart）

| Code                    | Meaning                      | UI Response | Recovery Action     |
| ----------------------- | ---------------------------- | ----------- | ------------------- |
| `400_PARSE`             | JSON 解析失败                    | 解析错误提示      | 查看 `run.log` 片段     |
| `404_FILE_NOT_FOUND`    | 文件不存在                         | 错误弹窗        | 检查文件路径/权限            |
| `408_WARMUP_TIMEOUT`    | CLI 启动超时（未收到首条事件）          | 弹窗重试        | 提供“降分辨率重试”          |
| `422_CONTRACT`          | 事件契约违反（字段缺失/类型错误）        | 警告 toast    | 指引对齐 App/CLI 版本     |
| `422_SCHEMA_MISMATCH`   | `result.json` 结构不符 *(camera_page 使用)* | 警告 toast    | 指引对齐 App/CLI 版本     |
| `500_CLI_EXIT_<code>`   | CLI 异常退出（退出码非 0）              | 错误弹窗        | “报告问题”/附 stderr 片段   |
| `500_INTERNAL`          | 内部错误（未分类）                   | 错误弹窗        | 查看日志 + 重试              |
| `500_RESULT_READ`       | 读取 result.json 失败 *(camera_page 使用)* | 错误弹窗        | 检查文件权限/路径            |
| `501_NOT_IMPLEMENTED`   | 功能未实现                         | 提示信息        | 等待功能更新                |

## 扩展错误码（如需扩展，建议统一前缀）

| Code                | Meaning                      | UI Response | Recovery Action     |
| ------------------- | ---------------------------- | ----------- | ------------------- |
| `ERROR_NO_EVIDENCE` | 无证据帧                         | 警告信息        | 回退到 `window` 片段     |
| `ERROR_LOW_STORAGE` | 空间不足                         | 顶部条 + 清理按钮  | 触发“一键清理”            |

## 兼容映射（历史错误码 → 标准错误码）

| 历史错误码          | 标准错误码       | 说明              |
| ----------------- | -------------- | ----------------- |
| `ERROR_PARSE`     | `400_PARSE`     | 格式统一为数字前缀    |
| `408_TIMEOUT`     | `408_WARMUP_TIMEOUT` | 更具体的超时类型    |
| `500_INFER_FAIL`  | `500_INTERNAL`  | 归入通用内部错误      |
| `500_IO_FAIL`     | `500_INTERNAL`  | 归入通用内部错误      |

**Default Fallback：**未知错误 → “分析失败”通用提示 + 查看日志 + 重试。

**注意：** 新增错误码建议遵循 `HTTP状态码_描述` 或 `ERROR_描述` 格式，并在 `event_bus.dart` 中统一管理。

---


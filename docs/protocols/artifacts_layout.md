# artifacts_layout.md
**Version:** v2.0  
**Purpose:** 定义 CLI 输出产物的目录结构与命名规范。

```
build/offline_out/<sessionId>/
├── result.json               # 分析结果
├── neutral_keypoints.json    # 关键点时序
├── angles.csv                # 角度时间序列
├── evidence/                 # 证据截图或视频片段
├── logs/
│   ├── run.log
│   └── perf.json
└── configs_snapshot.json     # 运行配置快照
```

### 校验规则
- 所有 JSON 必须为 UTF-8 编码。
- 每次运行生成唯一 sessionId。
- result.json 必含字段：version, scores, repCount, meta。

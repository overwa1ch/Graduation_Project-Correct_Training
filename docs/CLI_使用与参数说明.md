# Hybrid CLI 使用与参数说明

| 参数 | 说明 |
| --- | --- |
| `--hybrid` | 启用 Hybrid 流程 |
| `--hybrid-policy <path>` | 指定策略文件 |
| `--cloud-mock <path>` | 指定云端模拟结果文件 |
| `--cloud-video-fragment` | 启用视频片段导出（默认关闭） |
| `--evidence topK=<int> windowMs=<int>` | 证据选取参数（与后续阶段联动） |

## 控制台输出格式
```
HYBRID on | reasons=[coverage<.70,jitter>8] | cloudEnhanced | finalCount=12 (local=11, cloud=12)
```

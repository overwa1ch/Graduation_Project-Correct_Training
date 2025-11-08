 # 决策：App 实现“边拍边纠正”采用 FrameStreamer 接相机帧流

 - 记录时间：2025-11-07  
 - 状态：🧭 未来规划 / 方向已定（尚未接入 App）

 ---

 ## 背景
 目前 App 的视频分析采用“逐帧文件 + 直接调用 `PoseEngine.infer(...)`”的离线路径，已满足本地视频分析与测试需求。但未来计划支持“边拍边纠正”的实时交互（实时姿态提示/纠偏），这要求稳定的相机帧输入、统一的采样/时间戳管理与可配置的节流能力。

 `aiwa_core` 已提供通用流式工具 `FrameStreamer`（输入 `Stream<RawImageFrame>`，输出时序化 `NeutralFrame` 列表），天然适合相机实时帧场景（Camera preview）。

 ---

 ## 当前状态
 - App：未接入 `FrameStreamer`；离线逐帧视频分析直接用 `PoseEngine.infer(...)`。
 - Core：`FrameStreamer` 可用，负责统一抽帧（`stride`/fps）、镜像、时间戳累积与推理流程生命周期管理。
 - CLI：曾用于离线/批量回归的帧流生产者，不再强依赖，未来可按需停用。

 ---

 ## 场景分析
 - 实时相机预览下的姿态纠正/提示（前置/后置相机，期望低延迟、稳定 fps）。
 - 需要统一：
   - 抽帧与节流策略（如 `stride` 控制有效 fps）；
   - 镜像（前置相机常用）；
   - 时间戳连续性（用于时序平滑/滤波/提示节奏控制）；
   - 引擎生命周期（init/close），避免频繁重建。

 ---

 ## 方案比较
 - 方案 A：沿用当前在 App 层自行管理抽帧/节流/时间戳 + 逐帧调用引擎。
   - 优点：改动最小，延续现有实现。
   - 缺点：相机帧复杂度高（不同设备、旋转/镜像/格式 YUV/NV21），App 代码膨胀，时序一致性与性能节流容易分散到多处，维护成本上升。

 - 方案 B（推荐）：在 App 中将相机回调组装为 `Stream<RawImageFrame>`，交给 `FrameStreamer.run(...)` 统一处理。
   - 优点：
     - 统一抽帧/时间戳/镜像/生命周期管理，App 代码更简洁；
     - 更利于在相机/CLI/其他流来源之间复用与一致性；
     - 便于以配置方式切换有效 fps（`stride`）与镜像策略。
   - 缺点：需要在 App 相机层做一次性接入与图像格式转换封装。

 ---

 ## 决策结果（方向）
 - 当实现“边拍边纠正”实时交互时，采用 `FrameStreamer` 作为相机帧流接入的标准路径。
 - 离线逐帧视频分析仍保持现状，不强制迁移，二者并存。

 ---

 ## 实施建议
 1. 相机帧桥接
    - 通过 `camera` 插件（或 MLKit 相机源）获取 `CameraImage` 回调；
    - 转换为引擎可用的字节格式（例如 RGBA 或引擎支持的 NV21/JPEG），并封装为 `RawImageFrame(bytes, width, height, rotationDeg)`；
    - 注意前置相机镜像、设备旋转角度与期望输出方向的一致性。

 2. 接入 `FrameStreamer`
    - 构造 `FrameStreamer(engine, engineConfig, FrameStreamerConfig{ fps, stride, mirror, engineName, modelName, sdkVersion, videoBasename })`；
    - 调用 `run(Stream<RawImageFrame>)` 获取 `FrameStreamResult.frames`，用于实时渲染与提示逻辑；
    - 根据设备性能调整 `stride` 以控制有效 fps 与延迟（例如 30 fps 原始 → stride 2 得到 ~15 fps 推理）。

 3. 性能与体验
    - 使用节流（`stride`）与可能的分辨率下采样，确保端到端延迟可控；
    - 结合现有的时序平滑/后处理策略，利用 `FrameStreamResult` 的稳定时间戳；
    - 异常情况下保证 `engine.close()` 可靠执行（`FrameStreamer` 已封装）。

 ---

 ## 后续行动
 - App 相机层提供 `Stream<RawImageFrame>` 适配器（含格式转换与旋转/镜像处理）。
 - 集成 `FrameStreamer` 的试验性页面/入口，用于实时纠正预览。
 - 依据不同设备基准，设定推荐的 `fps/stride` 与分辨率档位。
 - 离线分析路径保持不变；对公共后处理逻辑提炼时序无关的复用部分。



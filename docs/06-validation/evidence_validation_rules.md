# Evidence 校验规则

* `evidence[].timestampMs` 升序排列；
* `snapshotPath` 必须存在或为空字符串，不允许 null；
* 所有 `cues` 均须在 `cue_advice_map.json` 中注册；
* 若导出 overlay.mp4：时长与帧数与 `evidence` 数量一致 ±1 帧；
* 每条证据应包含至少一个 `angles` 键；
* JSON Schema 验证全通过。

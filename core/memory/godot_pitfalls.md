# Godot 引擎踩坑记录（跨项目共享）

本文件用于沉淀**所有使用 godot-ai-harness 的项目**共同遇到的 Godot 引擎踩坑与处理方式。
仅记录"对所有 Godot 4.x 项目可复用"的内容；项目专有问题请写到业务仓的 `docs/ai_project_memory.md`。

> 关联文件：
> - 「harness 维护、bootstrap、git submodule、AI 客户端配置」类踩坑请写到 `harness_ops_pitfalls.md`。
> - 「项目专有」踩坑请写到业务仓的 `docs/ai_project_memory.md`。

## 写入约定

- 每条按「现象 / 根因 / 解决 / 影响范围」四段式记录。
- 每条标注录入日期与发现项目（不强制）。
- 如同一现象在多个项目重复出现，加上「+1」计数，便于优先级排序。
- 内容稳定后，可考虑提炼成 `core/rules/*.mdc` 自动注入。

---

## 一、窗口与桌面体验

### W-001 透明无边框窗口在 macOS 拖拽时残留阴影
- 现象：`get_window().borderless = true` + `transparent_bg = true` 后，macOS 上窗口拖动会出现旧位置的阴影残留。
- 根因：macOS Metal 合成器对透明窗口的 swap 时序与窗口边框去掉之后的 update region 计算冲突。
- 解决：拖拽过程中临时禁用 `transparent_bg`，拖拽结束（mouse_up）再恢复；或使用 `DisplayServer.window_set_flag(WINDOW_FLAG_TRANSPARENT, ...)` 显式刷新。
- 影响范围：所有透明无边框桌面应用。
- 录入：2026-04 / Game_Desktop。

### W-002 透明窗口必须在 project.godot 同时开三个开关，缺一即不透明
- 现象：代码里 `get_window().transparent = true` 设置了，但运行时窗口仍然不透明。
- 根因：Godot 4 的窗口透明需要三个开关同时打开：
  1. `display/window/size/transparent = true`（项目设置）
  2. `display/window/per_pixel_transparency/allowed = true`（项目设置）
  3. `rendering/viewport/transparent_background = true`（项目设置）
  代码里只设置 `get_window().transparent` 不够。
- 解决：上述三项都写到 `project.godot` 的对应 section；`get_window().transparent = true` 只是运行时的二次保险。
- 影响范围：所有桌面端透明窗口需求项目。
- 录入：2026-04 / Game_RogueCard。

---

## 二、信号与节点引用

### S-001 await 一个已经发射过的信号会永久挂起
- 现象：`await some_node.some_signal` 卡住协程不返回。
- 根因：信号已经在 await 之前发射，协程订阅时已经错过；signal 不会"重放"。
- 解决：
  - 用 flag 变量先判断"目标状态是否已达成"，未达成才 await。
  - 或用 `await get_tree().process_frame` 等通用 tick 信号当兜底。
- 影响范围：所有用 `await signal` 写流程编排的场景（关卡过渡、战斗结算、UI 弹窗等）。

### S-002 Scene Unique Nodes (`%`) 仅对当前场景的 owner 链生效
- 现象：在子场景里给节点勾了 "Access as Unique Name"，从父场景脚本用 `%NodeName` 取不到。
- 根因：`%` 语法解析只在当前场景的 owner 树内查找，子场景的节点 owner 是子场景根，不暴露给外部。
- 解决：
  - 父场景需要的话，在父场景层级直接放节点并勾 unique。
  - 或者通过子场景根脚本提供 getter，例如 `func get_health_bar() -> ProgressBar: return %HealthBar`。
- 影响范围：所有用 `%` 替代 `$Path/To/Node` 的场景。

### S-003 信号 connect 用 bind 时参数顺序"先绑定值，后信号参数"
- 现象：`btn.pressed.connect(_on_pressed.bind(card_id))`，handler 里参数顺序搞反，拿到 null。
- 根因：`Callable.bind(x).call(a, b)` 实际调用是 `func(a, b, x)`。bind 的值是**最后**的参数，信号自带参数在前。
- 解决：handler 函数签名按 `(signal_args..., bound_args...)` 顺序声明。
- 影响范围：任何用 `bind()` 给信号 connect 传 context 的场景。

---

## 三、资源导入与素材

### R-001 Godot 4.4+ 的 `.uid` 文件被错误 gitignore 导致 UID 冲突
- 现象：跨设备协作时同一资源出现 UID 重复或丢失，场景引用失效。
- 根因：Godot 4.4+ 引入 `.uid` 文件持久化资源唯一 ID。如果 `.gitignore` 把 `*.uid` 全部排除，每台机器生成不同 UID，git 切换分支时引用会错乱。
- 解决：
  - **应当**入 git：`*.uid`（与 `.import` 同等地位）。
  - 仅 `.godot/` 目录下的 cache 文件可 gitignore。
  - 当前 harness 默认 `.gitignore` 模板包含 `*.uid` 是历史遗留，新项目建议**移除该行**。
- 影响范围：Godot 4.4+ 的所有项目。
- 录入：2026-04 / harness 自查。
- 复现频次：+0（暂未实际暴雷，提前预警）。

### R-002 `.tres` 中循环引用导致编辑器无限保存或加载崩溃
- 现象：自定义 Resource 互引（如 `EnemyData.next_phase: EnemyData` 指向自己），保存或重新加载场景时编辑器卡死或崩溃。
- 根因：Godot 的资源序列化没有内置环检测；自引用或 A→B→A 链都会触发无限递归。
- 解决：
  - 改用字符串 ID 引用而非直接 Resource 引用：`@export var next_phase_id: String`，运行时通过 ResourceLoader 取。
  - 必须 Resource 引用时，加 `@export_group` 标注并人工保证树结构。
- 影响范围：所有数据驱动 (.tres) 项目（卡牌、敌人、技能、对话树）。

---

## 四、导出与打包

### E-001 macOS 导出 .app 后双击不启动（无任何反馈）
- 现象：从 Godot 编辑器 Export PCK + 打包 .app，本机双击没反应；命令行运行能看到日志。
- 根因：未公证的 .app 被 macOS Gatekeeper 静默阻止。
- 解决：
  - 临时：终端 `xattr -cr /path/to/Game.app` 移除隔离属性。
  - 正式：配置 Apple Developer ID 在 Export Preset 启用 codesign + notarize。
- 影响范围：所有 macOS 桌面端项目分发。

### E-002 Windows 打包后被杀毒软件拦截 / 报毒
- 现象：构建出的 `.exe` 在某些 Windows 机器被 Defender 或第三方杀软直接隔离。
- 根因：未签名的 PCK 嵌入式 exe 在某些启发式扫描里被误标。
- 解决：
  - 给 .exe 做 Authenticode 签名（即使是自签也比无签好得多）。
  - 单独发布 `.pck` + 不变的引擎 `.exe`，提示玩家把 .exe 加白。
  - 在 Steam / itch.io 通过其客户端发布可绕过部分扫描。
- 影响范围：所有 Windows 自分发项目。

---

## 五、MCP 与 AI 工具链

### M-001 `@coding-solo/godot-mcp` 在 Node 16 启动失败
- 现象：Cursor MCP 面板里 `godot` server 启动报错 "Cannot read properties of undefined" 或 ESM 导入错误。
- 根因：该 MCP 包要求 Node >= 18 的原生 fetch 与 ESM 完整支持。
- 解决：
  - 升级本机 Node 到 LTS 18+（推荐 20+）。
  - 用 nvm 切换：`nvm install 20 && nvm use 20`，重启 Cursor。
- 影响范围：所有用 godot MCP 的项目。

### M-002 `get_debug_output` 输出被截断（仅最后 ~100 行）
- 现象：长时间运行的 Godot 项目通过 MCP 取调试输出，只能拿到最后一段，关键早期日志丢失。
- 根因：MCP server 缓存有限，且 Godot stdout 是流式的不能回放。
- 解决：
  - 关键日志同时 `print_rich` 到屏幕 + 写文件：`FileAccess.open("user://run.log", FileAccess.WRITE_READ).store_line(msg)`。
  - 通过 MCP 的"读项目文件"能力读 user://run.log（注意路径要解析到实际 OS 位置）。
- 影响范围：所有需要 AI 复盘运行行为的场景。

---

## 六、性能与运行时

### P-001 `_process` 中频繁实例化新对象导致 GC 抖动
- 现象：每帧创建 `Vector2`/数组/字典，FPS 看似稳定但偶发卡顿，profiler 显示"GC pause"占比高。
- 根因：GDScript 的 Variant 类型对 short-lived allocation 仍要走分配器；高频小对象会拖累。
- 解决：
  - 预分配 + 复用：把每帧用的 buffer 声明为成员变量，每帧 `clear()` 而非新建。
  - 优先用 `PackedXxxArray` 而非 `Array`。
  - 数学运算尽量传值而非传引用对象。
- 影响范围：所有需要稳定 60+ FPS 的项目。

### P-002 `call_deferred` 在同帧内不会保证执行顺序
- 现象：`A.call_deferred("foo")` 和 `B.call_deferred("bar")` 在同帧调度，期望 foo 先于 bar 但不一定。
- 根因：`call_deferred` 把调用入栈到 idle frame queue，**按入队顺序但跨帧**消费；同帧多次入队不保证顺序与逻辑期望一致（特别是涉及不同节点）。
- 解决：
  - 关键时序用 `await get_tree().process_frame` 显式分隔。
  - 复杂时序用状态机替代 deferred 链。
- 影响范围：所有用 `call_deferred` 处理跨节点初始化的场景。

---

## 七、存档与序列化

### SAVE-001 `JSON.stringify` 对自定义 Resource 直接序列化结果是 "[Object]"
- 现象：把 Dictionary 里某个值是自定义 Resource，`JSON.stringify` 输出后该字段变成 "[Object]" 或 null，读回来全丢。
- 根因：JSON 只支持基本类型；Resource 不可序列化为 JSON。
- 解决：
  - 自定义 Resource 提供 `to_dict()` 方法返回纯字典；`from_dict()` 反序列化。
  - 全局存档前 walk 整个 dict 树，遇到 Resource 替换为 `{"__type__": "EnemyData", "id": "..."}`。
  - 复杂场景考虑用 `var_to_str` / `str_to_var`（保留类型但不可读）。
- 影响范围：所有用 JSON 存档的项目。

### SAVE-002 `user://` 在 macOS 沙盒下路径不直观，调试时找不到存档
- 现象：调试时想看 user://savegame.json 内容，但找不到文件位置。
- 根因：macOS 下 `user://` 解析到 `~/Library/Application Support/Godot/app_userdata/<project_name>/`，路径很深且 Library 默认隐藏。
- 解决：
  - 用 `print(ProjectSettings.globalize_path("user://savegame.json"))` 打印实际路径。
  - 调试期可临时把存档写到 `res://_dev_save.json`（注意发布前去掉，res:// 在打包后只读）。
- 影响范围：所有跨平台桌面项目调试期。

---

## 八、联机与同步

（待沉淀，参与联机项目时优先补充）

提示：`MultiplayerPeer` 信号触发顺序、RPC 节点路径要求、状态同步与确定性、回滚网络的边界场景等。

---

## 模板（复制使用）

```
### XX-NNN 简短标题
- 现象：
- 根因：
- 解决：
- 影响范围：
- 录入：YYYY-MM / 项目名
- 复现频次：+1
```

# Godot 引擎踩坑记录（跨项目共享）

本文件用于沉淀**所有使用 godot-ai-harness 的项目**共同遇到的 Godot 引擎踩坑与处理方式。
仅记录"对所有 Godot 4.x 项目可复用"的内容；项目专有问题请写到业务仓的 `docs/ai_project_memory.md`。

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

---

## 二、信号与节点引用

（待沉淀）

提示：常见 4.x 信号/节点写法应记录在 `core/rules/godot-4-gdscript-standards.mdc`，本节只记录"已经按规范写但仍踩坑"的边界情况。

---

## 三、资源导入与素材

（待沉淀）

提示：可记录 .import 文件被误改、PNG/Webp 在不同导出预设下的差异、Resource (.tres) 循环引用等。

---

## 四、导出与打包

（待沉淀）

提示：可记录 macOS 公证、Windows 杀毒误报、`.pck` 与 `.exe` 打包路径解析、平台条件编译差异等。

---

## 五、MCP 与 AI 工具链

（待沉淀）

提示：可记录 `@coding-solo/godot-mcp` 在不同 Node 版本下的兼容、`get_debug_output` 截断、场景节点路径含中文等。

---

## 六、性能与运行时

（待沉淀）

提示：物理步长抖动、`call_deferred` 顺序、`Tween` 与 `_process` 帧率耦合、`Array[Node]` 的 GC 行为等。

---

## 七、存档与序列化

（待沉淀）

提示：`FileAccess` 在 `user://` 跨平台路径差异、`var_to_str` / `JSON.stringify` 对自定义 `Resource` 的处理边界、版本迁移策略等。

---

## 八、联机与同步

（待沉淀）

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

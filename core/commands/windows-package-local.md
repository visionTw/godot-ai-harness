# /windows-package-local

执行本地 Windows 打包检查（模板命令）。

## 使用说明

- 本命令用于“本地验证打包链路”，不是发布流程。
- 具体导出 preset 名称、输出路径按项目实际配置替换。

## 模板步骤

1. 确认导出预设存在（例如 `Windows Desktop`）。
2. 执行 headless 导出。
3. 检查 `exe/pck` 是否生成。
4. 生成 zip 包（可选版本号策略）。
5. 记录结果与产物路径。

## 模板命令示例

```bash
godot --headless --path "." --export-pack "Windows Desktop" "dist/windows/Game_Desktop.pck"
```

## 输出模板

- 预设：`Windows Desktop`
- 导出结果：`成功/失败`
- 产物：`exe/pck/zip 路径`
- 备注：`模板/证书/签名状态`

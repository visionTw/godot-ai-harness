# Godot Smoke Check (Harness Core)

## 目标

在改动后快速确认项目可运行，并输出可追溯的验证证据。

## 输入

- 改动范围（文件列表）
- 最小复现路径
- 关键测试点

## 步骤

1. 校验 MCP 可用。
2. 运行项目并采集输出。
3. 记录 error/warning 与影响范围。
4. 输出 PASS / CONCERNS / FAIL。
5. 回写项目开发日志与测试记录。

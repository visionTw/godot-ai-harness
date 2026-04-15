# Versioning and Upgrade

## 版本策略

- 建议使用语义化版本：
  - MAJOR：破坏性调整
  - MINOR：能力新增
  - PATCH：问题修复

## 业务仓库升级流程

1. 先在 Harness 仓库发布新版本。
2. 在业务仓库更新 Harness 引用版本（submodule 或固定路径版本标识）。
3. 执行一次配置下发脚本并验证 MCP 与规则生效。

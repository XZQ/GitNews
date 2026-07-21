# AI资讯文档索引

本目录收纳当前产品边界、路线图、执行计划、Agent Harness、接口样例、审计记录和截图资产。当前开发基线为 `1.5.0+5` 加 `Unreleased` 改动；判断当前能力时依次以实际代码、根目录 README、产品与数据方案、RUN 为准。旧审计、旧规格和旧实施计划均保留为历史决策记录，文件顶部会明确标注“历史快照”，其中的旧版本号、旧品牌或旧导航不代表当前要求。

## 目录结构

| 目录 | 内容 |
|---|---|
| `plans/` | 当前产品信息架构、AI 资讯路线图及历史阶段计划 |
| `plans/exec/` | 遵循 `.agent/PLANS.md` 的可恢复执行计划 |
| `harness/` | Agent Harness 使用方法、验证证据和能力缺口 |
| `api/aihot-api/` | AI 热点接口响应样例 |
| `screenshots/` | 桌面端页面截图与说明 |
| `audits/` | 评审、审计和问题分析记录 |
| `superpowers/` | Superpowers 工作流生成的规格与执行计划 |

## 常用文档

- [当前产品、数据与系统边界](plans/product_ia_data_plan.md)
- [Agent Harness](harness/README.md)
- [Agent Harness 质量记分卡](harness/quality_scorecard.md)
- [账号与登录体系规划](plans/account_auth_plan.md)
- [移动端与桌面端 UI 整改基线](plans/mobile_desktop_ui_refactor_plan.md)
- [AI 资讯模块 Roadmap](plans/ai_news_roadmap.md)
- [自托管服务端运行与 API](../server/README.md)
- [1.3.0 产品可信度加固设计（历史）](superpowers/specs/2026-07-11-product-trust-hardening-design.md)
- [1.3.0 产品可信度加固实施计划（历史）](superpowers/plans/2026-07-11-product-trust-hardening-implementation.md)
- [运行与发布指南](../RUN.md)
- [版本变更记录](../CHANGELOG.md)
- [第二阶段实施计划（历史）](plans/phase2_plan.md)
- [商业级打磨方案（历史）](plans/commercial_plan.md)
- [多专家打磨方案（历史）](plans/polish_plan.md)
- [截图说明](screenshots/README.md)

当前 `Unreleased` 基线已经包含独立设置与资讯源管理、LLM 条目增强、事件聚类、FTS5 检索、兴趣反馈、Windows 托盘与本机提醒，以及可选自托管服务端。历史文档中的“无后端”“4 Tab”或“Settings 未建立”等描述只代表当时决策输入，不覆盖当前代码和上述当前文档。

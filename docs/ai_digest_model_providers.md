# AI 深度解读内置模型

核对日期：2026-07-20。

资讯详情不再提供服务商、Base URL、模型或 API Key 配置。应用只使用一组内置协议参数：

| 服务商 | Base URL | 模型 | 请求路径 |
| --- | --- | --- | --- |
| Agnes AI | `https://apihub.agnes-ai.com/v1` | `agnes-2.0-flash` | `/chat/completions` |

`GET /v1/models` 在未鉴权时返回 `401`，说明端点可达并要求凭据；这不等于某个 Key 已通过验证。运行时以真实 Chat Completions 请求成功且结构化响应可解析为最终可用标准：成功才展示“AI 深度解读”，未注入 Key、网络失败、鉴权失败、模型不可用或响应无效时整块隐藏。

发布方在已被 Git 忽略的 `env.json` 中配置：

```json
{
  "AI_ENRICHMENT_AGNES_API_KEY": "replace-me"
}
```

构建时使用 `--dart-define-from-file=env.json`。应用首次加载后会将 Key 写入系统安全存储；Key 不得写入源码、文档、脚本、测试 fixture、日志或提交记录。旧版用户可编辑的服务商、Base URL、模型与 Key 会被清理，不再参与请求。

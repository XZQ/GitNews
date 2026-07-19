# AI 解读模型服务商目录

核对日期：2026-07-16。应用使用 OpenAI Chat Completions 兼容协议，在所列 Base URL 后追加 `/chat/completions`。

| 服务商 | 内置 Base URL | 内置模型（首项为默认） | 核对方式 |
| --- | --- | --- | --- |
| Agnes AI | `https://apihub.agnes-ai.com/v1` | `agnes-2.0-flash`, `agnes-1.5-flash` | `/models` + 对话实测 200 |
| OpenAI | `https://api.openai.com/v1` | `gpt-5.6`, `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` | [官方模型文档](https://developers.openai.com/api/docs/guides/latest-model) |
| DeepSeek | `https://api.deepseek.com` | `deepseek-v4-flash`, `deepseek-v4-pro` | `/models` + 对话实测 200 |
| MiniMax | `https://api.minimaxi.com/v1` | `MiniMax-M3`, `MiniMax-M2.7`, `MiniMax-M2.7-highspeed` | `/models` + M3 对话实测 200 |
| Z.AI Coding Plan | `https://api.z.ai/api/coding/paas/v4` | `glm-5.2`, `glm-5.1`, `glm-5-turbo` | `/models` + GLM-5.2 对话实测 200 |
| Meituan LongCat（默认） | `https://api.longcat.chat/openai` | `LongCat-2.0` | [官方模型文档](https://longcat.chat/platform/docs/zh/api/models.html) + `/models` + 对话实测 200 |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | `gemini-3.5-flash`, `gemini-3.1-pro-preview`, `gemini-3.1-flash-lite` | [官方模型文档](https://ai.google.dev/gemini-api/docs/models) |
| Alibaba Cloud Qwen | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen3.7-max`, `qwen3.7-plus`, `qwen3.6-flash` | [官方模型文档](https://help.aliyun.com/en/model-studio/text-generation-model/) |
| Moonshot AI / Kimi | `https://api.moonshot.ai/v1` | `kimi-k2.6`, `kimi-k2-thinking` | [官方配置文档](https://moonshotai.github.io/kimi-code/en/configuration/providers.html) |
| OpenRouter | `https://openrouter.ai/api/v1` | `openrouter/auto`, `~openai/gpt-latest` | [官方快速开始](https://openrouter.ai/docs/quickstart) |
| SiliconFlow | `https://api.siliconflow.cn/v1` | `Pro/zai-org/GLM-5`, `Qwen/Qwen3.5-397B-A17B`, `deepseek-ai/DeepSeek-V3.2` | [官方接口文档](https://docs.siliconflow.cn/en/api-reference/chat-completions/chat-completions) |
| Groq | `https://api.groq.com/openai/v1` | `qwen/qwen3.6-27b`, `openai/gpt-oss-120b`, `llama-3.3-70b-versatile` | [官方模型目录](https://console.groq.com/docs/models) |
| Mistral AI | `https://api.mistral.ai/v1` | `mistral-large-latest`, `mistral-medium-latest`, `mistral-small-latest` | [官方 API 文档](https://docs.mistral.ai/api/) |
| xAI | `https://api.x.ai/v1` | `grok-4.5`, `grok-4.3-latest`, `grok-420-reasoning` | [官方模型文档](https://docs.x.ai/developers/grok-4-5) |
| Perplexity | `https://api.perplexity.ai` | `sonar-pro`, `sonar`, `sonar-reasoning-pro` | [官方兼容性文档](https://docs.perplexity.ai/docs/sonar/openai-compatibility) |
| Together AI | `https://api.together.ai/v1` | `MiniMaxAI/MiniMax-M2.7`, `Qwen/Qwen3.7-Max`, `deepseek-ai/DeepSeek-V4-Pro` | [官方模型目录](https://docs.together.ai/docs/serverless/models) |
| Fireworks AI | `https://api.fireworks.ai/inference/v1` | `accounts/fireworks/routers/kimi-k2p6-turbo` | [官方 Fire Pass 文档](https://docs.fireworks.ai/firepass) |
| NVIDIA NIM | `https://integrate.api.nvidia.com/v1` | `nvidia/nemotron-3-ultra-550b-a55b`, `nvidia/nemotron-3-super-120b-a12b`, `deepseek-ai/deepseek-v4-pro` | [官方 LLM API 目录](https://docs.api.nvidia.com/nim/reference/llm-apis) |
| Cerebras | `https://api.cerebras.ai/v1` | `gpt-oss-120b`, `zai-glm-4.7` | [官方模型目录](https://inference-docs.cerebras.ai/models/overview) |
| Hugging Face Inference Providers | `https://router.huggingface.co/v1` | `deepseek-ai/DeepSeek-V4-Pro`, `openai/gpt-oss-120b:fastest` | [官方兼容接口文档](https://huggingface.co/docs/inference-providers/en/index) |
| Cohere | `https://api.cohere.ai/compatibility/v1` | `command-a-plus-05-2026`, `command-a-reasoning-08-2025` | [官方兼容接口文档](https://docs.cohere.com/docs/compatibility-api) |

只有用户已提供 Key 的 Agnes、DeepSeek、MiniMax、Z.AI、Meituan LongCat 能完成鉴权后的真实生成验证；其余服务商已按官方接口与模型目录核对，仍需各自有效 Key 才能做最终账户级验证。模型目录会变化，更新时应同时修改 `lib/core/config/ai_model_providers_config.dart` 和本文档。

逐条 AI 解读可通过 `--dart-define=AI_DIGEST_DEFAULT_API_KEY=...` 注入兼容的默认 Key；该环境变量名称为兼容旧版本而保留。应用首次加载后会将 Key 写入系统安全存储；Key 不应写入源码、文档、脚本或提交记录。

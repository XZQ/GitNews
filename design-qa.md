# 设计 QA 汇总

## AI 与发现页

### 对照范围

- Source visual truth: `C:\Users\XZQ\Downloads\AI页.png`
- Implementation screenshot: `D:\workspace\github_news\test\features\ai_news\presentation\goldens\ai_news_page_mobile.png`
- Device interaction evidence: `D:\workspace\github_news\build\device_ai_latest.png`, `device_after_bell.png`, `device_after_reminder_back.png`, `device_first_back.png`
- Final comparison: `D:\workspace\github_news\build\design_qa\ai_news_comparison_pass3.png`
- Viewport: 390 × 844 logical pixels for normalized comparison and 1080 × 2400 physical pixels on Xiaomi 22041216UC.
- State: light theme; normalized capture uses an unconfigured digest and 12 same-day paper items; device evidence uses the configured digest and live local list/reminders.

### 比较历史与结论

1. 首轮压缩固定标题区、搜索与分类堆栈、日报横幅和文章卡片，并将缩略图调整为约 84 × 96。
2. 修复两行摘要裁切，保留书签 40 × 40 点击区域；移除来源徽标和刷新按钮，改用原生下拉刷新。
3. 第三轮将紧凑标题栏图标调整为 25 dp，并验证状态栏连续背景、提醒页返回和主页面双击退出行为。
4. 标题层级、间距、主题色、生产位图、Material 图标、320 px 窄屏和可访问性检查均通过；没有剩余 P0、P1 或 P2 视觉问题。

### 交互验证

- 搜索、分类、日报设置、文章导航、书签和 AI/发现页下拉刷新均保持接线。
- 提醒页通过工具栏或系统返回键回到带五项导航的 AI 首页。
- 五个主页面首次返回提示再次退出，两秒内再次返回才退出应用。
- Flutter 原生金图和连接的 Android 设备均已验证；相关 UI、导航与本地化测试通过。

## 资讯详情页

### 对照范围

- 视觉真值：`C:\Users\XZQ\Downloads\1.png`、`C:\Users\XZQ\Downloads\3.png`、`C:\Users\XZQ\Downloads\2.png`
- 实现截图：`test/features/ai_news/presentation/goldens/ai_news_detail_page_1.png`、`ai_news_detail_page_2.png`、`ai_news_detail_page_3.png`
- QA 副本：`C:\Users\XZQ\.codex\visualizations\2026\07\16\019f6a30-777b-7ca0-a47a-471312060c9f\qa_impl_page1_v3.png` 至 `qa_impl_page3_v3.png`
- 视口：逻辑尺寸 471 × 835，DPR 2，浅色主题，中文资讯固定数据态。

### 比较证据

- 三组参考图与实现图已在同一比较输入中逐页并排检查。
- 全视图检查覆盖顶部导航、分页标识、正文阅读流、来源和关联内容、固定操作栏。
- 聚焦检查覆盖第一页标题与生成主视觉、第二页三段 AI 解读卡、第三页要点与关联资讯卡。

### 必查表面

- 字体：标题、章节标题、正文、辅助信息层级清晰；窄屏中文和英文均无溢出。
- 间距与布局：三页使用一致阅读列、白底与浅青卡片层级；桌面居中，紧凑视口保持可滚动。
- 颜色与 token：复用项目主题色、间距和圆角 token，品牌青色与参考图一致。
- 图片质量：主视觉使用 1536 × 1024 的生成式 PNG，主体、留白和浅青色调适配标题槽位，无拉伸或占位资源。
- 文案与内容：使用真实 `AiNewsItem`、本地 AI 增强结果和缓存关联资讯；动态文章长度导致折叠位置略有变化，属于可滚动内容的预期差异。
- 图标：使用 Material 图标库；返回、收藏、外链、菜单、解读、来源和底部操作语义完整。
- 响应式与无障碍：已验证 471 × 835、390 × 844 暗色窄屏和桌面宽屏；图片有语义标签，操作按钮保持可点击区域。
- 交互：横向滑动三页、纵向独立滚动、赞同、不感兴趣、收藏、分享、原文跳转和关联资讯跳转均接入现有状态与行为。

### 比较历史

1. 首轮发现固定底栏错误占满页面、紧凑标题区过高、第二页只展示简化预览。
2. 修复底栏约束，压缩 471 宽标题区并保留 390 宽安全高度；第二页改为真实 enrichment provider 数据态。
3. 重新生成三页金图并再次与三张参考图同输入对照，未发现阻断交付的裁切、溢出、错色、低质量资源或失效交互。

final result: passed

# AI 资讯详情页重构 QA

## Source of truth

- 设计稿：`C:\Users\XZQ\Downloads\AI咨询App界面重设计\exports\screens-light\06-资讯详情.png`
- 实现截图：`test/features/ai_news/presentation/goldens/ai_news_detail_design_target.png`
- 归一化设计稿：`artifacts/design-qa-ai-detail/source-mobile-390.png`

## Verification state

- 视口：390 × 1557 逻辑像素
- 主题：浅色、青绿色品牌色
- 内容状态：中英对照、AI 深度解读未配置、三条相关文章、底部操作栏
- 系统状态栏：设计稿顶部 36 像素为系统所有；组件 Golden 不模拟系统状态栏，比较时从应用栏开始对齐。

## Comparison evidence

设计稿归一化图和实现 Golden 已在同一视觉比较输入中并排检查，覆盖完整详情页；另以顶部、滚动续页和紧凑中文三张 Golden 验证不同高度与语言状态。

## QA history

### Pass 1

- 中文元数据使用等宽字体时出现缺字方块。
- 英文正文少一行，导致下半页纵向节奏提前。
- “去配置”按钮高度不足，相关内容与底部操作栏之间留白偏大。
- 相关文章首字母方块与设计稿样例不一致。

### Fixes

- 将中文界面文案限定为详情页阅读字体，保留英文元数据的等宽表达，避免影响公共组件。
- 微调英文正文字号与行高，恢复设计稿的换行和阅读密度。
- 将配置按钮恢复为 40 像素触控高度，并按设计稿收敛卡片间距。
- 相关文章标识按拉丁首字母、中文书名号标题或首字符稳定派生。
- 保留真实的中/英/对照切换、AI 设置弹窗、来源跳转、收藏和分享交互。

### Pass 2

- 标题、元数据、双语正文、指标、来源卡、AI 空状态、相关文章与底部操作栏均与设计稿层级一致。
- 未发现溢出、裁切、遮挡、不可读文字或未响应的核心控件。
- 详情页四张 Golden、专项分析与交互测试通过。
- Windows Release 构建成功，仓库窗口烟测获得有效 `MainWindowHandle`。
- 原生 Windows 截图接口返回 `SetIsBorderRequired ... (0x80004002)`；视觉结论使用同视口确定性 Golden，运行结论使用 Release 窗口烟测，二者分开记录。

final result: passed

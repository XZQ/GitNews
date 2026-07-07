# Screenshots

以下截图展示了 GitHub 情报站各主要页面的外观和功能。

## 截图清单

| 文件名 | 页面 | 对应路由 | 功能说明 |
|--------|------|----------|----------|
| `ScreenShot_2026-06-27_145429.png` | AI 动态 | `/ai_news` | AI 资讯时间线列表，左侧分类导航，右侧资讯卡片，顶部搜索框 |
| `ScreenShot_2026-06-27_145723.png` | GitHub 热榜 | `/trending` | 多维度排序（趋势/增长/语言分布），Top 仓库列表，语言占比图表 |
| `ScreenShot_2026-06-27_145834.png` | 技术热点 | `/tech_hotspot` | AI 雷达 topic 信号卡片，增长率指标，语言分布面板 |
| `ScreenShot_2026-06-27_150002.png` | 仓库监控 | `/monitor` | 监控列表，告警历史，统计指标（今日告警/监控仓库/健康/异常） |
| `ScreenShot_2026-06-27_150123.png` | 设置 | `/profile` | GitHub Token 配置，主题色选择，数据缓存管理 |

## 页面与路由对应关系

```
┌─ /home         → 首页（情报总览）
├─ /ai_news      → AI 动态
├─ /trending     → GitHub 热榜
├─ /tech_hotspot → 技术热点
├─ /monitor      → 仓库监控
├─ /project      → 深度报告
├─ /profile      → 设置
└─ /webview      → 应用内浏览器（全屏）
```

## 响应式布局

应用支持三档响应式布局：

- **Compact** (<600px)：底部导航栏
- **Medium** (600-1024px)：NavigationRail
- **Expanded** (≥1024px)：可拖拽侧栏（200-800px），首页切换为桌面版布局

截图均在 Expanded 模式下截取。

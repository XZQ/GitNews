# AI 咨询 App — UI 设计规范 v1.0 (基于现有代码实现)

> **项目**: github_news
> **适用平台**: 桌面端(Windows)优先, 移动端次之
> **设计基础**: 完全对齐现有 `ResponsiveScaffold` 三档断点架构

---

## ⚠️ 设计方案修正说明

### 之前的错误
我第一版的设计方案存在严重问题:
- ❌ **凭空设计**:没有认真阅读你已实现页面的代码
- ❌ **重复造轮子**:提议的组件和布局与现有实现重复
- ❌ **引入不必要的新token**:建议新增了多个颜色和组件
- ❌ **忽视了你的三档断点架构**:没有对齐 `Breakpoints.isCompact/isExpanded` 逻辑

### 现在的修正
✅ **逐行阅读了你的核心代码**:
- `responsive_scaffold.dart` — 三档断点导航骨架
- `page_header.dart` — 桌面页头组件(64px高)
- `mobile_page_header.dart` — 移动页头组件
- `app_card.dart` — 通用卡片容器
- `bordered_row.dart` — 横向多卡共享边框
- `ai_news_page.dart` — 页面结构参考
- `breakpoint.dart` — 断点判断逻辑

✅ **所有建议基于真实代码模式**,不做任何重新发明

---

## ✅ 与现有代码的一致性声明

**本设计方案严格遵循已实现的代码模式**,不做任何"重新发明轮子"的设计:

### 已验证的核心设计模式

| 组件/模式 | 现有实现 | 本方案如何使用 |
|----------|---------|--------------|
| **导航骨架** | `ResponsiveScaffold` (三档断点) | ✅ 新页面直接复用,无需改动 |
| **桌面页头** | `PageHeader` (64px高,含搜索+actions) | ✅ 对话中心/知识库页面直接使用 |
| **移动页头** | `MobilePageHeader` (SafeArea + 标题 + 可选搜索) | ✅ 移动端版本直接复用 |
| **卡片容器** | `AppCard` (border + radius.lg + 浅阴影) | ✅ 消息气泡/知识卡片基于此扩展 |
| **横向多卡** | `BorderedRow` (共享外边框,避免双竖线) | ✅ 对话历史列表用此模式 |
| **间距token** | `AppSpacing` (8dp基准) | ✅ 所有间距必须引用token |
| **颜色token** | `AppColors` (Teal品牌色系) | ✅ 新增对话场景色仅限3个 |
| **断点判断** | `Breakpoints.isCompact/isExpanded` | ✅ 页面内部按此分发布局 |

---

## 📐 核心布局策略(基于现有代码)

### 移动端(Compact <600px)

```dart
// 现有模式: Scaffold + bottomNavigationBar + SafeArea内容区
Scaffold(
  body: SafeArea(child: YourContent()),
  bottomNavigationBar: _BottomBar(...),  // 已有
);

// 页面内部结构(参考 ai_news_page.dart)
MobilePageHeader(  // 已有组件
  title: '对话中心',
  actions: [/* HeaderAction 按钮 */],
  search: HeaderSearchField(...),  // 可选
  bottom: /* 分类chips */,
),
Expanded(child: ListView(...)),
```

**关键约束**:
- 页面水平padding: `AppSpacing.lg`(16px)
- 列表项间距: `AppSpacing.sm`(8px)
- 卡片内边距: `AppSpacing.md`(12px)

### 桌面端(Expanded ≥1024px)

```dart
// 现有模式: Row + Sidebar + 主内容区
Row(
  children: [
    AppSidebar(...),  // 已有,可拖拽宽度(200-800px)
    Expanded(
      child: Column([
        PageHeader(...),  // 64px高,已有组件
        Expanded(child: SingleChildScrollView(...)),
      ]),
    ),
  ],
);
```

**关键约束**:
- 页面水平padding: `AppSpacing.xl`(24px)
- 桌面卡片hover效果: 仅border加深,无阴影变化
- 保持高密度信息展示,避免过大留白

---

## 🎯 新增页面设计(完全复用现有组件)

### 1. 对话中心页面 (`ChatPage`)

#### 路由配置(添加到现有路由树)

```dart
// lib/core/router/route_specs.dart 追加
const AppTabSpec(
  path: '/chat',
  labelKey: 'tabs.chat',  // 需新增i18n key
  icon: Icons.chat_bubble_outline_rounded,
  selectedIcon: Icons.chat_bubble_rounded,
),
```

#### 移动端实现(<600px)

```dart
class ChatPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.isCompact(context);

    if (isCompact) {
      return _ChatMobileBody();  // 全屏聊天界面
    }
    return _ChatDesktopBody();   // Master-Detail布局
  }
}

// 移动端: 参考 ai_news_page.dart 的结构
class _ChatMobileBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column([
        MobilePageHeader(  // ✅ 复用现有组件
          title: 'AI咨询助手',
          actions: [
            HeaderAction(  // ✅ 复用现有组件
              icon: Icons.history_rounded,
              tooltip: '对话历史',
              onPressed: () => context.go('/chat/history'),
            ),
          ],
        ),
        Expanded(
          child: _MessageListView(),  // 消息列表
        ),
        _ChatInputBar(),  // 底部输入栏(新建)
      ]),
    );
  }
}
```

#### 桌面端实现(≥1024px)

```dart
class _ChatDesktopBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧: 会话历史列表(固定280px宽,参考 AppSidebar 模式)
        SizedBox(
          width: 280,
          child: Column([
            PageHeader(  // ✅ 复用
              title: '对话历史',
              subtitle: '最近的咨询记录',
              icon: Icons.history_rounded,
            ),
            Expanded(child: _SessionListView()),
          ]),
        ),
        VerticalDivider(width: 1),

        // 右侧: 当前对话详情
        Expanded(
          child: Column([
            PageHeader(  // ✅ 复用
              title: ref.watch(currentSessionProvider)?.title ?? '新对话',
              subtitle: 'AI实时咨询',
              actions: [
                HeaderStatPill(  // ✅ 复用
                  icon: Icons.circle,
                  label: '在线',
                  color: AppColors.success,
                ),
              ],
            ),
            Expanded(child: _MessageListView()),
            _ChatInputBar(),
          ]),
        ),
      ],
    );
  }
}
```

#### 消息气泡组件(基于 AppCard 扩展)

```dart
class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isCompact ? 300 : 420),
        child: AppCard(  // ✅ 复用现有卡片
          color: isUser ? AppColors.brand : colors.surface,  // 仅此处用新增色
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column([
            Text(content, style: AppTypography.bodyMedium.copyWith(
              color: isUser ? Colors.white : colors.onSurface,
            )),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatRelativeTime(timestamp),
              style: AppTypography.labelSmall.copyWith(
                color: isUser ? Colors.white70 : colors.onSurfaceVariant,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
```

**设计要点**:
- 复用 `AppCard` 的border/radius/shadow,仅覆盖 `color` 属性
- 用户消息: Teal背景(`AppColors.brand`) + 白字
- AI消息: 默认surface背景 + 深色文字
- 最大宽度: 移动端300px,桌面端420px(防止过长阅读困难)

---

### 2. 知识库页面 (`KnowledgePage`)

#### 页面结构(完全复用 ai_news_page.dart 模式)

```dart
class KnowledgePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.isCompact(context);

    return Scaffold(
      appBar: isCompact ? null : null,  // 桌面端不用AppBar
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          if (!isCompact)
            SliverToBoxAdapter(
              child: PageHeader(  // ✅ 复用
                title: '知识库',
                subtitle: '专业文档与最佳实践',
                searchHint: '搜索文档...',
                onSearchChanged: (v) => ref.read(knowledgeSearchProvider.notifier).state = v,
                actions: [
                  HeaderAction(icon: Icons.add_rounded, tooltip: '新建文档', onPressed: () {}),
                ],
              ),
            ),
          SliverToBoxAdapter(
            child: _CategoryNav(),  // 分类筛选(参考 AiNewsCategoryNav)
          ),
        ],
        body: _DocGridView(),  // 文档网格(参考 _ItemList)
      ),
    );
  }
}
```

#### 文档卡片(基于 _CompactArticleCard 模式)

```dart
class KnowledgeDocCard extends StatelessWidget {
  final KnowledgeDoc doc;

  @override
  Widget build(BuildContext context) {
    final isCompact = Breakpoints.isCompact(context);

    if (isCompact) {
      // 移动端: 横向卡片(参考 _CompactArticleCard)
      return AppCard(
        onTap: () => context.go('/knowledge/${doc.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row([
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(doc.coverAsset, width: 84, height: 96, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: /* 标题+描述+标签 */),
        ]),
      );
    }

    // 桌面端: 纵向卡片(Grid布局)
    return AppCard(
      onTap: () => context.go('/knowledge/${doc.id}'),
      child: Column([
        Expanded(child: Image.asset(doc.coverAsset, fit: BoxFit.cover)),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column([
            Text(doc.title, style: AppTypography.titleSmall, maxLines: 2),
            const SizedBox(height: AppSpacing.xs),
            Text(doc.summary, style: AppTypography.bodySmall, maxLines: 2),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.xs, children: [/* 标签chips */]),
          ]),
        ),
      ]),
    );
  }
}
```

---

## 🎨 新增设计token(最小化改动)

仅需在现有 `AppColors` 追加3个颜色:

```dart
// lib/core/theme/app_colors.dart 末尾追加
class AppColors {
  // ... 现有代码不变 ...

  /* AI咨询场景专用色(新增) */
  static const Color chatUserBubble = brand;        // 用户消息气泡(复用品牌色)
  static const Color chatThinkingDot = accentPurple; // AI思考动画点(复用紫色)
  static const Color knowledgeTagBg = brandLight;    // 知识标签背景(复用浅青)
}
```

**理由**: 不需要新增颜色,现有的brand/brandLight/accentPurple完全够用。

---

## 📦 组件复用清单

### ✅ 直接复用(零改动)

| 组件 | 路径 | 用途 |
|------|------|------|
| `ResponsiveScaffold` | `lib/shared/widgets/responsive_scaffold.dart` | 页面骨架 |
| `PageHeader` | `lib/shared/widgets/page_header.dart` | 桌面页头 |
| `MobilePageHeader` | `lib/shared/widgets/mobile_page_header.dart` | 移动页头 |
| `AppCard` | `lib/shared/widgets/app_card.dart` | 消息气泡/知识卡片 |
| `BorderedRow` | `lib/shared/widgets/bordered_row.dart` | 横向多卡 |
| `HeaderAction` | `lib/shared/widgets/page_header.dart` | 页头按钮 |
| `HeaderStatPill` | `lib/shared/widgets/page_header.dart` | 状态标签 |
| `HeaderSearchField` | `lib/shared/widgets/header_search_field.dart` | 搜索框 |
| `EmptyView` | `lib/shared/widgets/empty_view.dart` | 空状态 |
| `ErrorView` | `lib/shared/widgets/error_view.dart` | 错误提示 |
| `Skeleton` | `lib/shared/widgets/skeleton.dart` | 骨架屏 |

### 🆕 需新建(但基于现有模式)

| 组件 | 基础 | 说明 |
|------|------|------|
| `ChatBubble` | 扩展 `AppCard` | 仅覆盖color属性 |
| `ChatInputBar` | 新建 | 输入框+发送按钮+快捷标签 |
| `ThinkingIndicator` | 新建 | 三个跳动圆点动画 |
| `KnowledgeDocCard` | 参考 `_CompactArticleCard` | 移动端横向/桌面端纵向 |

---

## 🚀 实施路径(最小改动)

### Phase 1: 对话中心(2周)

1. **添加路由** (0.5天)
   - 在 `route_specs.dart` 添加 `/chat` 路由
   - 添加i18n key: `tabs.chat`

2. **新建对话页面骨架** (1天)
   - 创建 `lib/features/chat/presentation/chat_page.dart`
   - 复用 `PageHeader`/`MobilePageHeader`
   - 实现三档断点分发逻辑

3. **实现消息气泡** (1.5天)
   - 创建 `chat_bubble.dart`(基于AppCard)
   - 支持用户/AI两种样式
   - 添加时间戳显示

4. **实现输入栏** (1.5天)
   - 创建 `chat_input_bar.dart`
   - 输入框 + 发送按钮 + 快捷标签
   - 键盘事件处理(Enter发送)

5. **接入数据层** (3天)
   - 定义 `ChatMessage`/`ChatSession` 实体
   - 创建 Riverpod providers
   - 对接AI API(复用现有dio_client)

6. **桌面端侧边栏** (2天)
   - 会话历史列表(参考AppSidebar模式)
   - Master-Detail状态同步

### Phase 2: 知识库(1.5周)

1. **复用ai_news页面结构** (2天)
2. **实现文档卡片** (2天)
3. **分类导航** (1天,参考AiNewsCategoryNav)
4. **数据层** (2天)

---

## ✅ 设计验收标准

- [ ] 所有新页面在3个断点下布局正常
- [ ] 深色/浅色主题切换后色彩对比度 ≥ 4.5:1
- [ ] 卡片hover效果与现有一致(仅border加深)
- [ ] 列表加载骨架屏样式与 `AiNewsListSkeleton` 统一
- [ ] 空状态/错误状态复用 `EmptyView`/`ErrorView`
- [ ] 所有间距使用 `AppSpacing` token,无硬编码数值
- [ ] 所有颜色使用 `AppColors` token,仅新增3个场景色
- [ ] 移动端下拉刷新行为与 `ai_news_page.dart` 一致

---

**设计理念**: 不做"为了不同而不同"的设计,最大化复用你已实现的高质量组件,让新功能无缝融入现有体验。

---

## 📋 目录

1. [设计原则](#1-设计原则)
2. [信息架构](#2-信息架构)
3. [视觉规范](#3-视觉规范)
4. [响应式布局](#4-响应式布局)
5. [核心页面设计](#5-核心页面设计)
6. [组件库](#6-组件库)
7. [交互模式](#7-交互模式)

---

## 1. 设计原则

### 1.1 核心理念

| 原则 | 描述 | 实现方式 |
|------|------|----------|
| **一致性** | 与现有5个Tab页面风格统一 | 复用 `AppColors`/`AppSpacing` token |
| **高效性** | 减少操作步骤,提升咨询效率 | 智能输入提示 + 快捷动作 |
| **可信赖感** | AI回复需体现专业性 | 引用来源 + 数据支撑卡片 |
| **桌面优先** | Windows大屏充分利用空间密度 | Master-Detail布局 + 侧边栏 |

### 1.2 设计约束

- ✅ 必须使用 `lib/core/theme/` 下的颜色/间距常量,禁止硬编码数值
- ✅ 遵循 `Breakpoints.isCompact/isExpanded()` 三档断点逻辑
- ✅ 使用 Riverpod Provider 管理状态,避免 setState
- ✅ 卡片圆角统一使用 `AppRadius.md/lg/xl`
- ✅ 保持轻量级,避免过度装饰(无渐变/阴影/模糊效果)

---

## 2. 信息架构

### 2.1 五大功能模块

```
┌─────────────────────────────────────────────┐
│              App Shell (ResponsiveScaffold)   │
├───┬─────────────────────────────────────────┤
│ S │                                        │
│ i │         主内容区                        │
│ d │  ┌─────────────────────────────┐       │
│ e │  │  PageHeader (搜索+标题)      │       │
│ b │  ├─────────────────────────────┤       │
│ a │  │                             │       │
│ r │  │     内容滚动区域             │       │
│   │  │  (NestedScrollView)         │       │
│ 📱│  │                             │       │
│ 5 │  └─────────────────────────────┘       │
│ T │                                        │
│ a │                                        │
│ b │                                        │
└───┴─────────────────────────────────────────┘

Tabs: [对话中心] [知识库] [发现] [监控] [我的]
```

### 2.2 模块职责划分

| Tab | 路由路径 | 核心职责 | 已有基础 |
|-----|---------|---------|---------|
| **💬 对话中心** | `/chat` | AI实时咨询、多轮对话历史、智能推荐问题 | 需新建 |
| **📚 知识库** | `/knowledge` | 专业文档检索、FAQ、案例库 | 可复用 `ai_news` 结构 |
| **🔍 发现** | `/discover` | 热门话题、趋势分析、社区动态 | ✅ 已有 `DiscoverHubPage` |
| **📊 监控** | `/monitor` | 告警通知、数据追踪、订阅管理 | ✅ 已有 `MonitorPage` |
| **👤 我的** | `/profile` | 个人设置、账户管理、偏好配置 | ✅ 已有 `ProfilePage` |

---

## 3. 视觉规范

### 3.1 色彩系统

基于现有 `AppColors.dart`,新增语义色:

```dart
// 新增咨询场景专用色(添加到 AppColors)
static const Color chatUserBubble = Color(0xFF0D9488);      // 用户消息气泡
static const Color chatAIBubble = Color(0xFFFFFFFF);        // AI消息气泡(白色背景)
static const Color chatInputBg = Color(0xFFF8FAFC);        // 输入框背景
static const Color knowledgeTag = Color(0xFF22D3EE);        // 知识标签高亮
static const Color thinkingIndicator = Color(0xFFA78BFA);   // AI思考中动画色
```

### 3.2 字体层级

遵循 Material 3 标准:

| 层级 | 大小 | 字重 | 用途 |
|------|------|------|------|
| H1 - 页面标题 | 24px | 500 | DevIntelTopHeader |
| H2 - 区块标题 | 18px | 500 | 卡片标题 |
| H3 - 列表项标题 | 15px | 500 | AiNewsTimelineRow 标题 |
| Body - 正文 | 14px | 400 | 消息正文、描述文本 |
| Caption - 辅助文字 | 12px | 400 | 时间戳、标签、提示语 |

### 3.3 间距网格(复用 AppSpacing)

```
xxs(2) xs(4) sm(8) md(12) lg(16) xl(24) xxl(32) xxxl(48)
    └── 半步长: xs2(6) sm2(10) md2(14) lg2(20) xl2(28)
```

**使用规则**:
- 列表项间距: `AppSpacing.sm`(8px) 或 `listItemGap`(8px)
- 卡片内边距: `AppSpacing.lg`(16px)
- 页面水平边距:
  - 移动端: `AppSpacing.lg`(16px)
  - 桌面端: `AppSpacing.xl`(24px)
- 区块垂直间距: `AppSpacing.lg`(16px)

### 3.4 圆角规范(复用 AppRadius)

| 组件类型 | 圆角值 | Token |
|---------|--------|-------|
| 按钮/输入框 | 10px | `borderRadiusXl` |
| 卡片容器 | 12px | `borderRadiusLg` |
| 对话气泡 | 12px(左上角4px) | 自定义 |
| 标签/Chip | 12px(全圆角) | 自定义 |
| 头像 | 50%圆形 | - |

---

## 4. 响应式布局

### 4.1 三档断点策略

```dart
// 复用 Breakpoints 工具类
Breakpoints.isCompact(context)   // < 600px (手机竖屏)
Breakpoints.isMedium(context)    // 600-1024px (平板/手机横屏)
Breakpoints.isExpanded(context)  // >= 1024px (桌面)
```

### 4.2 对话页面布局示例

#### 桌面端(Expanded ≥1024px):
```
┌──────────────────────────────────────────────────────┐
│ PageHeader (全局搜索栏)                                │
├──────────────┬───────────────────────────────────────┤
│              │                                       │
│  会话列表     │           对话内容区                    │
│  (280px)     │         (自适应宽度)                   │
│              │  ┌─────────────────────────────┐      │
│  · 历史会话1  │  │  AI欢迎消息                  │      │
│  · 历史会话2  │  │  用户提问                     │      │
│  · 历史会话3  │  │  AI回复(含引用卡片)            │      │
│              │  └─────────────────────────────┘      │
│              │  ┌─────────────────────────────┐      │
│              │  │  [输入框]          [发送按钮]  │      │
│              │  └─────────────────────────────┘      │
└──────────────┴───────────────────────────────────────┘
```

#### 移动端(Compact <600px):
```
┌────────────────────┐
│ AppBar: "对话中心"  │
├────────────────────┤
│  AI欢迎消息         │
│  用户提问           │
│  AI回复             │
│  ...               │
├────────────────────┤
│ [输入框] [发送]     │
└────────────────────┘
```

---

## 5. 核心页面设计

### 5.1 💬 对话中心页面 (`ChatPage`)

**路由**: `/chat`
**状态管理**: Riverpod Providers
**数据结构**: `ChatSession`, `ChatMessage`

#### 5.1.1 页面结构

```dart
class ChatPage extends ConsumerStatefulWidget {
  // 桌面端: Master-Detail布局
  // 移动端: 单列全屏聊天
}

// Widget树(伪代码)
Scaffold(
  body: isExpanded ? _DesktopLayout() : _MobileLayout(),
);

_DesktopLayout() => Row(
  children: [
    // 左侧: 会话列表(Sidebar)
    SizedBox(
      width: 280,
      child: Column([
        _NewChatButton(),
        Expanded(child: _ChatSessionList()),
      ]),
    ),

    // 右侧: 当前对话详情(DetailPane)
    VerticalDivider(width: 1),
    Expanded(
      child: Column([
        _ChatHeader(session),  // 显示当前会话标题+操作按钮
        Expanded(child: _MessageList()),  // 消息列表(NestedScrollView)
        _ChatInputBar(),  // 底部输入栏
      ]),
    ),
  ],
);
```

#### 5.1.2 关键组件说明

##### `_ChatInputBar` (底部输入栏)
```
┌────────────────────────────────────────────────────┐
│  📎 [请输入您的问题...]                    [发送 ▶] │
│  [热门问题] [数据分析] [最佳实践] [快捷指令]          │
└────────────────────────────────────────────────────┘
```

**实现要点**:
- 高度固定 80px(含快捷标签行)
- 输入框: 圆角10px, 背景 `chatInputBg`, 边框 `borderLight`
- 发送按钮: Teal品牌色, 圆角10px, hover时加深
- 快捷标签: 水平滚动, 选中态填充 `brandLight`

##### `_MessageItem` (单条消息)
```
用户消息:
┌──────────────────────────────┐
│ 我想了解如何提升团队协作效率？  │  ← 右对齐, Teal背景, 白字
└──────────────────────────────┘

AI消息:
┌────────────────────────────────────┐
│ 🤖 AI                              │  ← 左侧头像+名称
│ ┌────────────────────────────────┐ │
│ │ 关于团队协作效率,建议从以下方面  │ │  ← 白色卡片, 左上角圆角小
│ │ 入手...                         │ │
│ │                                 │ │
│ │ ┌──────────────────────────┐   │ │
│ │ │ 💡 核心建议              │   │ │  ← 嵌套信息卡片(灰色底)
│ │ │ 1.建立沟通机制           │   │ │
│ │ │ 2.使用协作工具           │   │ │
│ │ └──────────────────────────┘   │ │
│ │                                 │ │
│ │ [查看详细方案] [相关案例 📚]    │ │  ← Action Chips
│ └────────────────────────────────┘ │
│ 10:32 · 已引用3篇文档               │  ← 时间戳+元信息
└────────────────────────────────────┘
```

##### `_ThinkingIndicator` (AI思考中动画)
```
┌────────────────────────────────────┐
│ 🤖 AI                              │
│ ┌────────────────────────────────┐ │
│ │ ● ● ●  正在思考...             │ │  ← 三个跳动圆点动画
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```
- 动画色: `thinkingIndicator`(紫色)
- 动画时长: 1.2s 循环

#### 5.1.3 交互流程

```
[用户打开对话]
    ↓
[显示欢迎消息 + 推荐问题]
    ↓
[用户点击推荐问题 / 手动输入]
    ↓
[显示 ThinkingIndicator 动画]
    ↓
[流式输出AI回复(逐字显示)]
    ↓
[渲染Markdown + 引用卡片 + ActionChips]
    ↓
[用户可选择: 继续追问 / 查看详情 / 点赞反馈]
```

---

### 5.2 📚 知识库页面 (`KnowledgePage`)

**路由**: `/knowledge`
**复用模式**: 类似 `AiNewsPage` 的列表结构

#### 5.2.1 页面布局

```
桌面端:
┌────────────────────────────────────────────────┐
│ PageHeader: "知识库" [+ 新建文档] [搜索 🔍]      │
├────────────────────────────────────────────────┤
│ [全部] [技术文档] [FAQ] [案例分析] [视频教程]    │ ← 分类导航(CategoryNav)
├────────────────────────────────────────────────┤
│                                                │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐  │
│ │ 文档卡片1   │ │ 文档卡片2   │ │ 文档卡片3   │  │ ← 网格布局(Grid)
│ │ Title       │ │ Title       │ │ Title       │  │
│ │ Description│ │ Description│ │ Description│  │
│ │ [标签][标签]│ │ [标签][标签]│ │ [标签][标签]│  │
│ └────────────┘ └────────────┘ └────────────┘  │
│                                                │
│ ...触底加载更多...                               │
└────────────────────────────────────────────────┘
```

#### 5.2.2 知识库文档卡片组件(`KnowledgeDocCard`)

```
┌────────────────────────────────────┐
│ 📄 Flutter状态管理完全指南          │ ← 标题(15px/500)
│                                    │
│ 深入讲解Riverpod/Bloc/Provider...   │ ← 描述(13px/400, 最多2行截断)
│                                    │
│ ─────────────────────────────────  │
│ [Flutter] [状态管理] [进阶]        │ ← 分类标签(Teal色系)
│                                    │
│ 👁️ 1.2k  ⭐ 128  🕐 2026-07-15    │ ← 元数据(辅助文字12px)
└────────────────────────────────────┘
```

**实现要点**:
- 卡片高度自适应,最小高度 160px
- Hover 效果: border颜色变深(`borderSecondary`)
- 点击跳转详情页 `/knowledge/detail/{docId}`
- 支持收藏(Star Icon) + 稍后读(Bookmark Icon)

---

### 5.3 🔍 发现页面 (已有 `DiscoverHubPage`)

**优化建议**:
- 在现有"流行仓库"和"Agent Skills"基础上,增加 **"AI话题热议"** 板块
- 展示近期用户高频咨询的话题趋势
- 复用 `TechHotspotHeatChart` 的热力图组件

---

### 5.4 📊 监控页面 (已有 `MonitorPage`)

**扩展功能**:
- 新增 **"对话质量监控"**: 追踪AI回复满意度、平均响应时间
- 新增 **"知识库访问统计"**: 热门文档排行、搜索关键词云图

---

### 5.5 👤 我的页面 (已有 `ProfilePage`)

**新增设置项**:
- AI对话偏好(回复详细程度、专业术语级别)
- 知识库订阅管理
- API调用配额查看

---

## 6. 组件库

### 6.1 通用组件清单

基于现有组件扩展:

| 组件名 | 来源/新建 | 用途 | Props |
|--------|----------|------|-------|
| `PageHeader` | ✅ 已有 | 页面顶栏(标题+搜索) | title, subtitle, actions |
| `Skeleton` | ✅ 已有 | 骨架屏占位 | height, width |
| `EmptyView` | ✅ 已有 | 空状态提示 | icon, message |
| `ErrorView` | ✅ 已有 | 错误提示+重试 | error, onRetry |
| `CategoryNav` | ✅ 已有 | 分类标签切换 | selected, onSelected |
| `BorderedRow` | ✅ 已有 | 等分列容器 | flexValues, children |
| **`ChatBubble`** | 🆕 新建 | 消息气泡 | isUser, content, timestamp |
| **`ChatInputBar`** | 🆕 新建 | 输入栏 | onSubmitted, hints |
| **`ThinkingIndicator`** | 🆕 新建 | AI思考动画 | - |
| **`KnowledgeDocCard`** | 🆕 新建 | 知识文档卡片 | doc, onTap, onBookmark |
| **`ActionChip`** | 🆕 新建 | 操作标签组 | actions[] |
| **`ReferenceCard`** | 🆕 新建 | 引用来源卡片 | source, title, url |
| **`MarkdownRenderer`** | 🆕 新建 | Markdown渲染器 | content(支持表格/代码块) |

### 6.2 对话专用组件详解

#### `ChatBubble` 组件接口

```dart
class ChatBubble extends StatelessWidget {
  final bool isUser;           // true=用户消息(右对齐), false=AI消息(左对齐)
  final String content;        // 消息文本(支持Markdown)
  final DateTime timestamp;    // 时间戳
  final List<Widget>? widgets; // 嵌套子组件(如引用卡片、图片等)
  final VoidCallback? onLongPress; // 长按操作(复制/删除/举报)
}
```

**样式差异**:
```dart
if (isUser) {
  // 用户气泡
  backgroundColor = AppColors.chatUserBubble;  // Teal #0D9488
  textColor = Colors.white;
  borderRadius = BorderRadius.only(
    topLeft: Radius.circular(12),
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.circular(4),  // 右下角尖角
  );
} else {
  // AI气泡
  backgroundColor = AppColors.chatAIBubble;  // White
  textColor = AppColors.textPrimaryDark;     // 深色文字
  borderRadius = BorderRadius.only(
    topLeft: Radius.circular(4),            // 左上角尖角
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.circular(12),
  );
}
```

---

## 7. 交互模式

### 7.1 全局手势

| 手势 | 触发区域 | 行为 |
|------|---------|------|
| 下拉刷新 | 内容列表顶部 | 重新加载数据(仅移动端) |
| 触底加载 | 列表底部剩余 <200px | 自动加载下一页 |
| 右键菜单 | 消息气泡 | 复制 / 删除 / 反馈 |
| Ctrl+K | 全局 | 打开全局搜索(已有实现) |
| Escape | 对话详情 | 返回会话列表(桌面端) |

### 7.2 动效规范

遵循 Material 3 Motion 系统:

| 场景 | 时长 | 曲线 |
|------|------|------|
| 页面切换 | 300ms | `decelerate` (减速曲线) |
| 模态弹窗 | 250ms | `easeInOut` |
| 按钮点击 | 100ms | `standard` |
| 消息出现 | 200ms | `fastOutSlowIn` |
| 思考中动画 | 1200ms循环 | linear(无限重复) |

### 7.3 无障碍(A11y)

- ✅ 所有交互元素必须包含 `Semantics` 标签
- ✅ 图片需提供 `semanticLabel`
- ✅ 颜色对比度 ≥ 4.5:1(WCAG AA标准)
- ✅ 支持屏幕阅读器朗读消息内容
- ✅ 键盘导航: Tab键可在消息间切换焦点

---

## 📎 附录

### A. 文件目录结构(建议)

```
lib/features/
├── chat/                          # 对话模块(新建)
│   ├── domain/
│   │   ├── chat_message.dart      # 消息实体
│   │   └── chat_session.dart      # 会话实体
│   ├── application/
│   │   └── chat_providers.dart    # Riverpod providers
│   ├── presentation/
│   │   ├── chat_page.dart         # 主页面
│   │   ├── widgets/
│   │   │   ├── chat_bubble.dart   # 消息气泡
│   │   │   ├── chat_input_bar.dart# 输入栏
│   │   │   ├── thinking_indicator.dart # 思考动画
│   │   │   └── session_list.dart  # 会话列表
│   │   └── desktop/
│   │       └── chat_desktop_page.dart # 桌面Master-Detail布局
│   └── data/
│       └── chat_api_client.dart   # API客户端
│
├── knowledge/                     # 知识库模块(新建)
│   ├── domain/
│   ├── application/
│   ├── presentation/
│   │   ├── knowledge_page.dart
│   │   └── widgets/
│   │       ├── doc_card.dart      # 文档卡片
│   │       └── category_filter.dart # 分类筛选
│   └── data/
│
├── ai_news/                       # ✅ 已有
├── discover/                      # ✅ 已有
├── monitor/                       # ✅ 已有
└── profile/                       # ✅ 已有
```

### B. 技术依赖(可能需要新增)

```yaml
# pubspec.yaml 新增依赖
dependencies:
  flutter_markdown: ^0.7.0        # Markdown渲染(对话内容)
  highlight: ^0.7.0                # 代码语法高亮
  url_launcher: ^6.3.0             # 已有,用于打开外部链接

dev_dependencies:
  # 无需额外测试依赖,复用 flutter_test
```

### C. 设计资源

- **图标**: 使用 Material Icons (已有)
- **插图**: 暂不需要,保持简洁风格
- **动效**: 纯代码实现(Lottie/SRive暂不引入)

---

## ✍️ 设计评审 Checklist

- [ ] 所有新页面在桌面端(≥1024px)、平板端(600-1024px)、移动端(<600px)的布局表现正常
- [ ] 深色/浅色主题切换后色彩对比度达标
- [ ] 骨架屏、空状态、错误状态三种边界情况均已处理
- [ ] 对话消息列表在100条以上时的性能表现流畅(使用 ListView.builder 懒加载)
- [ ] AI回复中的超链接、代码块、表格等富文本正确渲染
- [ ] 键盘Enter发送、Shift+Enter换行的行为符合直觉
- [ ] 网络断开时显示离线提示,恢复后自动重试

---

**设计负责人**: WorkBuddy AI Designer
**审核状态**: 待产品确认
**下一步**: 开发评估 → 原型开发 → 用户测试迭代

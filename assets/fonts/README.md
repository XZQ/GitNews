# 等宽字体

代码里的等宽样式(`AppTypography.mono*`)靠 `monoFallback` 回退链直接用
系统自带等宽字体渲染,**不需要任何字体资源文件**,也不需要在
`pubspec.yaml` 里声明 `fonts:`。

若将来想统一各平台观感,再把 JetBrains Mono 的 ttf 放进本目录并补上
`fonts:` 声明即可,族名对齐 `AppTypography.monoFamily`。在那之前保持现状。

# 测试字体

`NotoSansSC-TestSubset.ttf` 仅用于 Windows Golden 与布局测试，不会通过
`pubspec.yaml` 进入应用发布包。

- 上游：Noto Sans CJK SC Variable
- 固定提交：`f8d157532fbfaeda587e826d4cd5b21a49186f7c`
- 上游文件：
  `Sans/Variable/TTF/NotoSansCJKsc-VF.ttf`
- 上游 SHA-256：
  `990C807E79C25662A5A9ECF7F971BAEB2BF2EAB9A559E5ECF15CDFDB8561D21F`
- 当前子集 SHA-256：
  `832CBEAEF27AD0E9BCE1309151B79139194A470394A527414F62440F862F3516`
- 许可证：同目录 `OFL.txt`

子集包含 ASCII、常用标点，以及中文本地化和 AI 资讯视觉测试当前使用的字形。
2026-09-12 保留原有 Unicode 集合，补齐 AI 摘要、翻译、实体、重要性估计与
复制正文文案的缺失字形；上游文件与固定版本不变。
更新相关 Golden 文案后，如出现缺字，应从同一上游版本重新生成子集并同步更新
哈希；不要回退到开发机系统字体或固定 Flutter SDK 路径。

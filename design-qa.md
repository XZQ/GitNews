# AI 页设计 QA

- Source visual truth: `C:\Users\XZQ\Downloads\AI页.png`
- Implementation screenshot: `D:\workspace\github_news\test\features\ai_news\presentation\goldens\ai_news_page_mobile.png`
- Device interaction evidence: `D:\workspace\github_news\build\device_ai_latest.png`, `D:\workspace\github_news\build\device_after_bell.png`, `D:\workspace\github_news\build\device_after_reminder_back.png`, `D:\workspace\github_news\build\device_first_back.png`
- Final comparison: `D:\workspace\github_news\build\design_qa\ai_news_comparison_pass3.png`
- Viewport: 390 × 844 logical pixels for normalized visual comparison; 1080 × 2400 physical pixels on Xiaomi 22041216UC for status-bar and navigation verification
- State: light theme; normalized capture uses an unconfigured digest and 12 same-day paper items; device evidence uses the configured digest and live local list/reminders; both use the three-action header with no provenance badge
- Comparison normalization: the reference content region was cropped below the system status bar and normalized to 390 × 614; the implementation used the matching 390 × 614 content region.

## Comparison history

1. Pass 1 found actionable density mismatches: the fixed title area, search/category stack, digest banner, and article cards were all too tall. The compact title bar was reduced to 48 dp, search/category spacing was tightened, the digest banner was reduced to about 120 dp, and article cards were rebuilt around 84 × 96 thumbnails.
2. The first compact-card revision clipped two-line summaries. Card typography, vertical allocation, and bookmark placement were adjusted; the bookmark now keeps a 40 × 40 interaction target without increasing card height.
3. Pass 2 compared the reference and implementation side by side. No remaining P0, P1, or P2 visual issue was found.
4. The final product annotation overrides the original reference header: provenance badges and refresh actions were removed, refresh is provided by the native pull gesture, and the AI header retains its notification, filter, and read-later actions.
5. Pass 3 enlarged the three compact header icons to 25 dp while tightening each action cell to 40 dp, enabled a continuous surface behind the AI status bar, and verified the resulting header against the normalized reference and on the target Android device.
6. The reminders route is full-screen and both its toolbar back action and Android back action restore the AI primary page with the five-item navigation. Primary pages now keep the app open on the first back press and exit only on a second press within two seconds. No remaining P0, P1, or P2 issue was found.

## Surface review

- Typography: title weight, two-line article titles, summary hierarchy, metadata scale, and ellipsis behavior match the reference hierarchy. The fixture copy intentionally remains realistic application data rather than hardcoded screenshot text.
- Spacing and layout: title and search remain in the fixed app bar while category chips scroll with content; digest, day header, and list cards use the reference rhythm without overflow at 320 px.
- Color and borders: the existing theme tokens provide the white/soft-gray surfaces, mint primary state, subtle outlines, rounded chips, and calm card elevation shown in the reference.
- Image quality: the digest background and three article thumbnail variants are production raster assets generated for their measured slots; they are cropped with `BoxFit.cover` and medium filtering, with no stretched screenshot fragments or placeholder art.
- Icons: Material icons are used consistently for search, notification, filtering, read-later, categories, digest settings, list display, and per-card bookmarks. The three compact header icons use 25 dp glyphs inside adjacent 40 dp action cells; compact headers contain no refresh icon.
- Responsive behavior: compact screens use the fixed title app bar and horizontally scrollable category row; desktop keeps the existing dense `PageHeader` and title-first article layout.
- Accessibility: interactive card controls include tooltips; the card bookmark has a 40 × 40 hit target; narrow-width tests confirm that the title-and-search header does not overflow.

## Interaction verification

- The compact title and search field remain fixed while the category row scrolls away with the list.
- Search input updates the query provider; category chips, digest settings, article navigation, and per-card bookmark actions remain wired. Pull-to-refresh invalidates and awaits the currently visible data source on both AI and Discover pages.
- The AI root paints continuously behind the Android status bar. The reminders page opens without the bottom navigation, and returning by either toolbar or system back restores the AI root and bottom navigation.
- On the five primary pages, the first Android back press keeps the app visible and shows “再按一次返回键退出应用”; a second press within two seconds exits.
- Flutter native golden capture and a connected Android device were used, so browser-console inspection is not applicable. `flutter analyze` completed with no issues, and all nine focused UI/navigation/localization tests passed.

final result: passed

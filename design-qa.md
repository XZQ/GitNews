# Five-page mobile redesign QA

## Source of truth

- `C:\Users\XZQ\Downloads\exports\screens-light\01-今日.png`
- `C:\Users\XZQ\Downloads\exports\screens-light\02-AI.png`
- `C:\Users\XZQ\Downloads\exports\screens-light\03-发现.png`
- `C:\Users\XZQ\Downloads\exports\screens-light\04-监控.png`
- `C:\Users\XZQ\Downloads\exports\screens-light\05-我的.png`

The source exports are 782 px wide, corresponding closely to the connected Android device's 393 logical-pixel viewport.

## Verification environment

- Device: Xiaomi 22041216UC, Android 13
- Physical viewport: 1080 × 2460
- Density: 440 dpi, approximately 393 × 895 logical pixels
- Theme: light, teal accent
- Build: release APK, version 1.5.0+5

## Comparison evidence

Reference and implementation are combined in the same images:

- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\compare-home.png`
- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\compare-ai.png`
- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\compare-discover.png`
- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\compare-monitor.png`
- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\compare-profile.png`

Long-page coverage:

- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\after-profile-mid.png`
- `C:\Users\XZQ\.codex\visualizations\2026\07\18\019f756e-4635-7631-ad50-781ba808e4ca\after-profile-bottom.png`

## QA history

### Pass 1

- Discover title/search hierarchy and grouped repository list matched the source, but compact repository metadata used a second row that made each item too tall.
- Monitor and Profile compact titles were smaller than the source hierarchy.
- The installed app initially retained a purple accent preference, while the source uses teal.
- Profile's About card still showed the old placeholder version/build.
- No clipping, overlap, broken bottom navigation, or paint exception was visible across the five routes.

### Fixes

- Reduced compact Discover metadata to one wrapped metrics row with a plain language color marker while retaining data provenance.
- Raised Monitor and Profile titles to the shared mobile headline style.
- Revalidated the five pages with the teal theme state used by the source.
- Updated About to the actual 1.5.0+5 build identity.
- Rebuilt and installed the release APK after these changes.

### Pass 2

- Page order, fixed headers, grouped cards, tab selection, bottom navigation, repository density, trend charts, monitor summary, expanded settings, data/cache, and About sections are present and usable.
- Dynamic repository/news names and current dates differ from the static source by design; their wrapping and truncation remain stable.
- System status-bar glyphs differ from the mock export because they come from the physical device.
- No unresolved P0, P1, or P2 fidelity issue remains.

## Result

passed

# EiffelTUI Examples: Ratatui 1-to-1 Mapping & Progress Tracker

This document is the master specification and progress tracking ledger for porting the official [Ratatui Examples](ratatui/examples) to native **EiffelTUI**.

Every example demonstrates idiomatic Eiffel usage, CQS (`with_*`) builder workflows, clean event handling, and terminal lifecycle management.

---

## Progress Overview

| Category | Total Examples | 🟢 Completed | 🟡 In Progress | ⚪ Planned | ⚠️ Adapted |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Tier 1: Foundations & Fundamentals** | 7 | 7 | 0 | 0 | 0 |
| **Tier 2: Widget Specialists** | 7 | 7 | 0 | 0 | 0 |
| **Tier 3: Layouts & Visualization** | 7 | 7 | 0 | 0 | 0 |
| **Tier 4: Flagship Dashboards** | 2 | 2 | 0 | 0 | 0 |
| **Tier 5: Advanced & Ecosystem** | 9 | 9 | 0 | 0 | 0 |
| **Total** | **32** | **32** | **0** | **0** | **0** |

### Status Legend
- 🟢 **Completed:** Ported, compiled with `ec`, interactive verification on Windows & Linux.
- 🟡 **In Progress:** Implementation or testing currently underway.
- ⚪ **Planned:** Ready for implementation.
- ⚠️ **Adapted:** Adapted to Eiffel equivalents (e.g. network/tracing external crate dependencies).

---

## Tier 1: Foundations & Fundamentals

Simple, self-contained examples demonstrating the core terminal pipeline, color systems, and text formatting.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 1 | `hello-world` | `apps/hello-world` | [`EXAMPLE_HELLO_WORLD`](examples/tier1_foundations/example_hello_world.e) | `TUI_PARAGRAPH`, `TUI_BLOCK`, centered layout | 🟢 Completed | Simplest entry point; centered greeting text. |
| 2 | `minimal` | `apps/minimal` | [`EXAMPLE_MINIMAL`](examples/tier1_foundations/example_minimal.e) | `TERMINAL`, raw mode, direct buffer writing | 🟢 Completed | Bare-metal frame loop without extra widgets. |
| 3 | `colors-rgb` | `apps/colors-rgb` | [`EXAMPLE_COLORS_RGB`](examples/tier1_foundations/example_colors_rgb.e) | `COLOR`, `STYLE`, half-block `▀`/`▄` graphics | 🟢 Completed | Smooth animated RGB rainbow color wave. |
| 4 | `color-explorer` | `apps/color-explorer` | [`EXAMPLE_COLOR_EXPLORER`](examples/tier1_foundations/example_color_explorer.e) | ANSI 16, 256 indexed colors, true RGB palette | 🟢 Completed | Interactive color inspection with modifiers. |
| 5 | `modifiers` | `apps/modifiers` | [`EXAMPLE_MODIFIERS`](examples/tier1_foundations/example_modifiers.e) | Bold, Dim, Italic, Underlined, Crossed-out | 🟢 Completed | SGR style attribute showcase across words. |
| 6 | `popup` | `apps/popup` | [`EXAMPLE_POPUP`](examples/tier1_foundations/example_popup.e) | `TUI_POPUP`, `TUI_CLEAR`, modal centering | 🟢 Completed | Modal overlay dialog box over background UI. |
| 7 | `inline` | `apps/inline` | [`EXAMPLE_INLINE`](examples/tier1_foundations/example_inline.e) | Inline viewport strategy, cursor preservation | 🟢 Completed | Non-fullscreen terminal rendering under prompt. |

---

## Tier 2: Widget Specialists

Focused interactive applications dedicated to exploring specific widgets, their states, and user interaction.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 8 | `todo-list` | `apps/todo-list` | [`EXAMPLE_TODO_LIST`](examples/tier2_widgets/example_todo_list.e) | `TUI_LIST`, `LIST_STATE`, multiline selection | 🟢 Completed | Item completion toggling, status bar, up/down nav. |
| 9 | `user-input` | `apps/user-input` | [`EXAMPLE_USER_INPUT`](examples/tier2_widgets/example_user_input.e) | `TUI_TEXT_INPUT`, `TEXT_INPUT_STATE` | 🟢 Completed | Normal vs editing modes, cursor screen position. |
| 10 | `input-form` | `apps/input-form` | [`EXAMPLE_INPUT_FORM`](examples/tier2_widgets/example_input_form.e) | Multi-field input, Tab focus, field validation | 🟢 Completed | Form data entry with multiple input widgets. |
| 11 | `table` | `apps/table` | [`EXAMPLE_TABLE`](examples/tier2_widgets/example_table.e) | `TUI_TABLE`, `TABLE_STATE`, horizontal scroll | 🟢 Completed | Multi-column tabular data, row highlights, headers. |
| 12 | `scrollbar` | `apps/scrollbar` | [`EXAMPLE_SCROLLBAR`](examples/tier2_widgets/example_scrollbar.e) | `TUI_SCROLLBAR`, `SCROLLBAR_STATE` | 🟢 Completed | Vertical/horizontal scrollbar with custom symbols. |
| 13 | `gauge` | `apps/gauge` | [`EXAMPLE_GAUGE`](examples/tier2_widgets/example_gauge.e) | `TUI_GAUGE`, `TUI_LINE_GAUGE` | 🟢 Completed | Progress animation, label coloring, inverted fills. |
| 14 | `calendar-explorer` | `apps/calendar-explorer` | [`EXAMPLE_CALENDAR_EXPLORER`](examples/tier2_widgets/example_calendar_explorer.e) | `TUI_CALENDAR`, `CALENDAR_STATE` | 🟢 Completed | Month/year keyboard navigation, custom date styles. |

---

## Tier 3: Layouts & Visualization

Advanced layout solver experiments, 2D vector graphics, and data charting.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 15 | `flex` | `apps/flex` | [`EXAMPLE_FLEX`](examples/tier3_visualization/example_flex.e) | `LAYOUT`, `FLEX_JUSTIFY` (Start, Center, End, SpaceBetween, SpaceAround, SpaceEvenly) | 🟢 Completed | Interactive flex layout distribution modes. |
| 16 | `constraints` | `apps/constraints` | [`EXAMPLE_CONSTRAINTS`](examples/tier3_visualization/example_constraints.e) | `CONSTRAINT` (`Min`, `Max`, `Length`, `Ratio`, `Percentage`, `Fill`) | 🟢 Completed | Solver constraint behavior comparison. |
| 17 | `constraint-explorer` | `apps/constraint-explorer` | [`EXAMPLE_CONSTRAINT_EXPLORER`](examples/tier3_visualization/example_constraint_explorer.e) | Interactive layout playground with live sliders | 🟢 Completed | Visual inspection of spacing, gaps, and shrink order. |
| 18 | `canvas` | `apps/canvas` | [`EXAMPLE_CANVAS`](examples/tier3_visualization/example_canvas.e) | `TUI_CANVAS`, `SHAPE_LINE`, `SHAPE_RECT`, `SHAPE_CIRCLE`, `SHAPE_POINTS` | 🟢 Completed | World map projection and geometric primitives. |
| 19 | `chart` | `apps/chart` | [`EXAMPLE_CHART`](examples/tier3_visualization/example_chart.e) | `TUI_CHART`, `TUI_CHART_DATASET` | 🟢 Completed | Real-time line chart, scatter plots, axes, legends. |
| 20 | `weather` | `apps/weather` | [`EXAMPLE_WEATHER`](examples/tier3_visualization/example_weather.e) | `TUI_BARCHART`, horizontal/vertical groups | 🟢 Completed | Weather metrics dashboard using grouped bars. |
| 21 | `mouse-drawing` | `apps/mouse-drawing` | [`EXAMPLE_MOUSE_DRAWING`](examples/tier3_visualization/example_mouse_drawing.e) | Mouse click & drag tracking on Braille canvas | 🟢 Completed | Freehand drawing and painting in the terminal. |

---

## Tier 4: Flagship Showcase Dashboards

Comprehensive full-screen production applications combining layouts, multiple widgets, and event dispatch.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 22 | `demo` | `apps/demo` | [`EXAMPLE_DEMO`](examples/tier4_flagship/example_demo.e) | Multi-tab dashboard, sparklines, tables, gauges, world map, chart | 🟢 Completed | The classic Ratatui README operations dashboard. |
| 23 | `demo2` | `apps/demo2` | [`EXAMPLE_DEMO2`](examples/tier4_flagship/example_demo2.e) | 5 Tabs, truecolor wallpaper, recipe, email, traceroute, weather, destroy mode | 🟢 Completed | Full premier showcase application demonstrating the complete ecosystem. |

---

## Tier 5: Advanced & Ecosystem

Architecture patterns, error recovery, and specialized concepts.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 24 | `panic` | `apps/panic` | [`EXAMPLE_PANIC`](examples/tier5_advanced/example_panic.e) | Terminal recovery during unhandled `EXCEPTIONS` | 🟢 Completed | Demonstrates guaranteed terminal restoration on crashes. |
| 25 | `custom-widget` | `apps/custom-widget` | [`EXAMPLE_CUSTOM_WIDGET`](examples/tier5_advanced/example_custom_widget.e) | Custom class inheriting `WIDGET` (`BUTTON_WIDGET`) | 🟢 Completed | 3D beveled button widget with mouse click & themes. |
| 26 | `widget-ref-container` | `apps/widget-ref-container` | [`EXAMPLE_WIDGET_CONTAINER`](examples/tier5_advanced/example_widget_container.e) | Heterogeneous widget lists and polymorphic dispatch (`STACK_CONTAINER`) | 🟢 Completed | Demonstrates polymorphic UI collections in Eiffel. |
| 27 | `advanced-widget-impl` | `apps/advanced-widget-impl` | [`EXAMPLE_ADVANCED_WIDGET`](examples/tier5_advanced/example_advanced_widget.e) | Complex custom widget lifecycle & state separation | 🟢 Completed | Timers, shapes, bouncing dynamic coordinates. |
| 28 | `hyperlink` | `apps/hyperlink` | [`EXAMPLE_HYPERLINK`](examples/tier5_advanced/example_hyperlink.e) | OSC 8 terminal hyperlink escape sequences | 🟢 Completed | Clickable URLs in supported modern terminals. |
| 29 | `release-header` | `apps/release-header` | [`EXAMPLE_RELEASE_HEADER`](examples/tier5_advanced/example_release_header.e) | ASCII art, banner typography, stylized layout | 🟢 Completed | Release announcement / splash banner layout. |
| 30 | `volatility-surface`| `apps/volatility-surface` | [`EXAMPLE_VOLATILITY_SURFACE`](examples/tier5_advanced/example_volatility_surface.e) | 3D perspective projection math on `TUI_CANVAS` | 🟢 Completed | Financial volatility surface wireframe on Braille grid. |
| 31 | `tracing` | `apps/tracing` | [`EXAMPLE_LOGGING`](examples/tier5_advanced/example_logging.e) | File logging & diagnostics without screen corruption | 🟢 Completed | Native Eiffel non-blocking file logging (`tui_trace.log`). |
| 32 | `async-github` | `apps/async-github` | [`EXAMPLE_ASYNC_GITHUB`](examples/tier5_advanced/example_async_github.e) | Concurrent background data fetch & TUI updates | 🟢 Completed | Background PR monitor with animated Braille spinner (simulated async; real GitHub HTTP fetcher planned for future). |

---

### Future Example Roadmap
- **Real Network Async GitHub (`EXAMPLE_REAL_ASYNC_GITHUB`):** Connect to live GitHub REST API v3 using an asynchronous HTTP/TLS worker thread (via `cURL` or `SCOOP`) and personal access token, replacing the simulated tick-based latency.

---

## Implementation Standard for EiffelTUI Examples

1. **Architecture:**
   - Every example is an autonomous executable class with an entry feature `make`.
   - Adheres to the single rendering pipeline: `TERMINAL` → `FRAME` → `BUFFER` → `DIFF_ENGINE` → `ANSI_SERIALIZER`.
   - Uses `TUI_APPLICATION` or an idiomatic polling loop with clean terminal restoration.

2. **CQS & Immutability:**
   - Strict Command-Query Separation with fluent `with_*` builder queries.
   - Clean separation of immutable widget configuration and mutable widget state (`STATEFUL_WIDGET [S]`).

3. **Multi-Platform Support:**
   - Must run and display properly on Windows Console / Windows Terminal and Linux POSIX terminals.
   - All string literals containing special glyphs must use `utf8 ("...")` or Unicode character codes to prevent encoding pitfalls.

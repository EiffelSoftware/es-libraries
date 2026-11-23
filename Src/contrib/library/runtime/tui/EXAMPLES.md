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
| 6 | `popup` | `apps/popup` | [`EXAMPLE_POPUP`](examples/tier1_foundations/example_popup.e) | `TUI_POPUP`, `TUI_CLEAR`, modal centering, `SHADOW` (medium shade) | 🟢 Completed | Modal overlay dialog box over background UI, with a block shadow. |
| 7 | `inline` | `apps/inline` | [`EXAMPLE_INLINE`](examples/tier1_foundations/example_inline.e) | Inline viewport strategy, cursor preservation | 🟢 Completed | Non-fullscreen terminal rendering under prompt. |

---

## Tier 2: Widget Specialists

Focused interactive applications dedicated to exploring specific widgets, their states, and user interaction.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 8 | `todo-list` | `apps/todo-list` | [`EXAMPLE_TODO_LIST`](examples/tier2_widgets/example_todo_list.e) | `TUI_LIST`, `LIST_STATE`, multiline selection | 🟢 Completed | Item completion toggling, status bar, up/down nav. |
| 9 | `user-input` | `apps/user-input` | [`EXAMPLE_USER_INPUT`](examples/tier2_widgets/example_user_input.e) | `TUI_TEXT_INPUT`, `TEXT_INPUT_STATE` | 🟢 Completed | Normal vs editing modes, cursor screen position; the hardware cursor as a bar while editing (P2 T1). |
| 10 | `input-form` | `apps/input-form` | [`EXAMPLE_INPUT_FORM`](examples/tier2_widgets/example_input_form.e) | Multi-field input, Tab focus, field validation | 🟢 Completed | Form data entry with multiple input widgets. |
| 11 | `table` | `apps/table` | [`EXAMPLE_TABLE`](examples/tier2_widgets/example_table.e) | `TUI_TABLE`, `TABLE_STATE`, horizontal scroll | 🟢 Completed | Multi-column tabular data, row highlights, headers. |
| 12 | `scrollbar` | `apps/scrollbar` | [`EXAMPLE_SCROLLBAR`](examples/tier2_widgets/example_scrollbar.e) | `TUI_SCROLLBAR`, `SCROLLBAR_STATE` | 🟢 Completed | Vertical/horizontal scrollbar with custom symbols. |
| 13 | `gauge` | `apps/gauge` | [`EXAMPLE_GAUGE`](examples/tier2_widgets/example_gauge.e) | `TUI_GAUGE`, `TUI_LINE_GAUGE`, `TUI_FILL` (background) | 🟢 Completed | Progress animation, label coloring, inverted fills, over a dotted `TUI_FILL` background. |
| 14 | `calendar-explorer` | `apps/calendar-explorer` | [`EXAMPLE_CALENDAR_EXPLORER`](examples/tier2_widgets/example_calendar_explorer.e) | `TUI_CALENDAR`, `CALENDAR_STATE` | 🟢 Completed | Month/year keyboard navigation, custom date styles. |

---

## Tier 3: Layouts & Visualization

Advanced layout solver experiments, 2D vector graphics, and data charting.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 15 | `flex` | `apps/flex` | [`EXAMPLE_FLEX`](examples/tier3_visualization/example_flex.e) | `LAYOUT`, `FLEX_JUSTIFY` (Start, Center, End, SpaceBetween, SpaceAround, SpaceEvenly) | 🟢 Completed | Interactive flex layout distribution modes. |
| 16 | `constraints` | `apps/constraints` | [`EXAMPLE_CONSTRAINTS`](examples/tier3_visualization/example_constraints.e) | `CONSTRAINT` (`Min`, `Max`, `Length`, `Ratio`, `Percentage`, `Fill`) | 🟢 Completed | Solver constraint behavior comparison. |
| 17 | `constraint-explorer` | `apps/constraint-explorer` | [`EXAMPLE_CONSTRAINT_EXPLORER`](examples/tier3_visualization/example_constraint_explorer.e) | Interactive layout playground with live sliders | 🟢 Completed | Visual inspection of spacing, gaps, and shrink order. |
| 18 | `canvas` | `apps/canvas` | [`EXAMPLE_CANVAS`](examples/tier3_visualization/example_canvas.e) | `TUI_CANVAS`, `SHAPE_MAP` (high resolution), `SHAPE_AREA` (polygons), `SHAPE_LINE`, `SHAPE_RECT`, `SHAPE_CIRCLE`, `SHAPE_POINTS` | 🟢 Completed | World map (Ratatui `Map` coastlines) and geometric primitives; the shapes panel adds a filled concave star (even-odd) and a triangle outline (Ratatui `Area`). Enter cycles all nine markers. |
| 19 | `chart` | `apps/chart` | [`EXAMPLE_CHART`](examples/tier3_visualization/example_chart.e) | `TUI_CHART`, `TUI_CHART_DATASET` | 🟢 Completed | Real-time chart: the sine wave is an area filled to 0 V (`CHART_GRAPH_TYPE.area`, Ratatui `GraphType::Area`; [a] switches Area / Line), plus a line, scatter plots, axes, legends. |
| 20 | `weather` | `apps/weather` | [`EXAMPLE_WEATHER`](examples/tier3_visualization/example_weather.e) | `TUI_BARCHART`, horizontal/vertical groups | 🟢 Completed | Weather metrics dashboard using grouped bars. |
| 21 | `mouse-drawing` | `apps/mouse-drawing` | [`EXAMPLE_MOUSE_DRAWING`](examples/tier3_visualization/example_mouse_drawing.e) | Mouse click & drag tracking on Braille canvas | 🟢 Completed | Freehand drawing and painting in the terminal. |

---

## Tier 4: Flagship Showcase Dashboards

Comprehensive full-screen production applications combining layouts, multiple widgets, and event dispatch.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 22 | `demo` | `apps/demo` | [`EXAMPLE_DEMO`](examples/tier4_flagship/example_demo.e) | Multi-tab dashboard, sparklines (the telemetry one with the Braille marker), tables, gauges, world map (`SHAPE_MAP`, high resolution), chart | 🟢 Completed | The classic Ratatui README operations dashboard. |
| 23 | `demo2` | `apps/demo2` | [`EXAMPLE_DEMO2`](examples/tier4_flagship/example_demo2.e) | 5 Tabs, truecolor wallpaper, recipe, email, traceroute, weather, destroy mode | 🟢 Completed | Full premier showcase application demonstrating the complete ecosystem. The Traceroute tab's ping sparkline shows lost packets as absent values (red `×`) and slow pings with their own bar style (`SPARKLINE_BAR`). |

---

## Tier 5: Advanced & Ecosystem

Architecture patterns, error recovery, and specialized concepts.

| # | Ratatui Example | Source in Ratatui | Eiffel Class | Core Widgets & Features | Status | Notes |
| :-: | :--- | :--- | :--- | :--- | :-: | :--- |
| 24 | `panic` | `apps/panic` | [`EXAMPLE_PANIC`](examples/tier5_advanced/example_panic.e) | Terminal recovery during unhandled `EXCEPTIONS` | 🟢 Completed | Demonstrates guaranteed terminal restoration on crashes. |
| 25 | `custom-widget` | `apps/custom-widget` | [`EXAMPLE_CUSTOM_WIDGET`](examples/tier5_advanced/example_custom_widget.e) | Custom class inheriting `WIDGET` (`BUTTON_WIDGET`) | 🟢 Completed | 3D beveled button widget with mouse click & themes. |
| 26 | `widget-ref-container` | `apps/widget-ref-container` | [`EXAMPLE_WIDGET_CONTAINER`](examples/tier5_advanced/example_widget_container.e) | Heterogeneous widget lists and polymorphic dispatch (`STACK_CONTAINER`) | 🟢 Completed | Demonstrates polymorphic UI collections in Eiffel. |
| 27 | `advanced-widget-impl` | `apps/advanced-widget-impl` | [`EXAMPLE_ADVANCED_WIDGET`](examples/tier5_advanced/example_advanced_widget.e) | Complex custom widget lifecycle & state separation | 🟢 Completed | Timers, shapes, bouncing dynamic coordinates. |
| 28 | `hyperlink` | `apps/hyperlink` | [`EXAMPLE_HYPERLINK`](examples/tier5_advanced/example_hyperlink.e) | OSC 8 terminal hyperlink escape sequences | 🟢 Completed | Clickable URLs in supported modern terminals. Each link cell has the diff option `Forced_width (1)` (`CELL_DIFF_OPTION`, P1 V8). |
| 29 | `release-header` | `apps/release-header` | [`EXAMPLE_RELEASE_HEADER`](examples/tier5_advanced/example_release_header.e) | ASCII art, banner typography, stylized layout | 🟢 Completed | Release announcement / splash banner layout. |
| 30 | `volatility-surface`| `apps/volatility-surface` | [`EXAMPLE_VOLATILITY_SURFACE`](examples/tier5_advanced/example_volatility_surface.e) | 3D perspective projection math on `TUI_CANVAS` | 🟢 Completed | Financial volatility surface wireframe on Braille grid. |
| 31 | `tracing` | `apps/tracing` | [`EXAMPLE_LOGGING`](examples/tier5_advanced/example_logging.e) | File logging & diagnostics without screen corruption | 🟢 Completed | Native Eiffel non-blocking file logging (`tui_trace.log`). |
| 32 | `async-github` | `apps/async-github` | [`EXAMPLE_ASYNC_GITHUB`](examples/tier5_advanced/example_async_github.e) | Concurrent background data fetch & TUI updates | 🟢 Completed | Background PR monitor with animated Braille spinner (simulated async; real GitHub HTTP fetcher planned for future). Each fetch has a generation number: `r` during a fetch starts a new one and the older worker stops without posting (a stale result is dropped); quitting cancels the workers and joins them before `run` returns (`stop_background_work`, P2 B2). `-batch` runs three frames, quitting during the fetch. |

---

## EiffelTUI-only Examples

Examples for features that Ratatui leaves to applications or third-party crates. They are not counted in the 32/32 above.

| Eiffel Class | Target | Core Widgets & Features | Notes |
| :--- | :--- | :--- | :--- |
| [`EXAMPLE_MODAL_DIALOG`](examples/tier2_widgets/example_modal_dialog.e) | `example_modal_dialog` | `TUI_DIALOG` + `DIALOG_STATE` (`make_confirm`, `set_focus_manager`, `handle_key`, `click`, `answered_action`, P2b U3), non-modal `TUI_POPUP`, `FOCUS_MANAGER.focus_at`, `TUI_APPLICATION.hit_test`, `TUI_BUTTON` buttons (`HIT_TARGET`) | A file list with a delete confirmation built on `TUI_DIALOG`: its focus scope traps Tab and its popup blocks clicks behind it; Yes / No by click, Tab / Left / Right and Enter / Space, y / n, Esc = No; the answer deletes or keeps the file in `answered_action`. A non-modal hint (a plain `TUI_POPUP`) whose Dismiss button is the popup's inner widget. The confirmation casts the dialog's dimmed shadow (`SHADOW` + `DIMMED_EFFECT`), which keeps the characters under it. Covered by a scripted click test and a row-exact `VIRTUAL_TERMINAL` snapshot. |
| [`EXAMPLE_FORM_CONTROLS`](examples/tier2_widgets/example_form_controls.e) | `example_form_controls` | `TUI_DIVIDER`, `TUI_CHECKBOX` (and a radio group of checkboxes, `CHECKBOX_SYMBOLS.radio_*`), `TUI_SLIDER` + `SLIDER_STATE` horizontal and vertical, `FOCUS_MANAGER`, `TUI_APPLICATION.hit_test`, `TERMINAL.shown_area` (P2 W1–W3) | Options, a theme and two levels in one dialog with section rules. The checkboxes act on a sample document in a Preview section (word wrap, a line-number gutter, bold headings), and the theme radio group switches the whole dialog between the `TUI_THEME` dark and light presets (`palette`). Tab / Shift+Tab move the focus; Space or a click toggles a checkbox or selects a radio option; arrow keys, Page Up / Page Down and Home / End move the focused slider; a press on a track jumps there and a drag follows the pointer until the release. Each control highlights and registers only its own cells. Covered by row-exact snapshots before and after keys and a scripted mouse run on a fixed viewport (`TEST_FORM_CONTROLS_EXAMPLE`). |
| [`EXAMPLE_MENU_BAR`](examples/tier2_widgets/example_menu_bar.e) | `example_menu_bar` | `TUI_MENU` + `MENU_STATE` + `MENU_ITEM` (drop-downs, separators, a disabled item, shortcut texts, a sub-menu, a light-shade shadow), `TUI_CHECKBOX`, `FOCUS_MANAGER`, `TUI_APPLICATION.hit_test` (P2 W4); `TUI_DIALOG` + `DIALOG_STATE` (P2b U3) | A menu bar over an editor panel. F10 or Alt+letter opens the menu; arrows move (separators and disabled items skipped, Left / Right through the sub-menu and across the bar), Enter chooses, Esc closes one level; Tab is trapped by the menu's focus scope while open. A click on an entry opens it, on an item chooses it, and anywhere else closes the menu without reaching the panel. View > Wrap lines / Line numbers toggle the checkboxes; File > Quit asks first: a "Quit?" `TUI_DIALOG` confirmation opened from the menu item (the menu's focus scope closes before the dialog's opens); Yes stops, No or Esc keeps running. With the menu closed, q or Esc asks the same question. Edit > Paste reads the clipboard (`TUI_APPLICATION.read_clipboard`, P2b K6): "Last command" says it is reading until the `CLIPBOARD_EVENT` comes, then a `TUI_TOAST` at the panel's bottom right shows the first line (success), "Clipboard holds no text." (info), or, when the clipboard could not be read (no OSC 52 reply within the timeout, too large, not valid), "Clipboard not readable here: use your terminal's paste (Ctrl+Shift+V)" (warning); the toasts expire on ticks and a click dismisses one. On Windows the console driver reads the system clipboard itself (K4). Covered by row-exact snapshots in `TEST_MENU.test_menu_bar_example` and `TEST_MENU.test_menu_bar_quit_asks_first`, and by scripted runs through the real event loop in `TEST_CLIPBOARD_EXAMPLES` (an OSC 52 reply, no reply, the driver's own read, an answer while the Quit dialog is open). |
| [`EXAMPLE_TEXT_AREA`](examples/tier2_widgets/example_text_area.e) | `example_text_area` | `TUI_TEXT_AREA` + `TEXT_AREA_STATE` (word wrap, selection, undo / redo, the bar cursor), `TERMINAL.copy_to_clipboard` / `clipboard_prefix` (OSC 52 write, P2 T3), `TUI_APPLICATION.read_clipboard` + `CLIPBOARD_EVENT` (P2b K3 / K4 / K6) | A notes editor. Shift+arrows or Ctrl+A select, Ctrl+C copies the selection through the terminal (OSC 52, cut at a grapheme boundary over the terminal's limit), Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y undo and redo (Ctrl+Z does not suspend here), Esc quits. Ctrl+V reads the clipboard: the status line says "Reading clipboard…" until the answer, then the text is inserted sanitised (TAB to a blank, CR LF to LF, other controls dropped) as one undo step, or the status line says "Clipboard not readable here: use your terminal's paste (Ctrl+Shift+V)". On Windows the console driver reads the system clipboard itself (K4), but Windows Terminal, and conhost with its Ctrl key shortcuts, take Ctrl+V for their own paste by default; most other terminals do not answer an OSC 52 read. The example turns bracketed paste on, so the terminal's own paste (Ctrl+Shift+V, or Ctrl+V where the terminal takes it) comes as one `PASTE_EVENT` and is inserted sanitised as one undo step; a terminal without bracketed paste types it in as keys. `-batch` runs two frames. Covered by scripted runs through the real event loop (`TEST_CLIPBOARD` for Ctrl+C, `TEST_CLIPBOARD_EXAMPLES` for Ctrl+V: an OSC 52 reply, no reply, a reply too large, the driver's own read, a bracketed paste, typed keys unchanged). |
| [`EXAMPLE_FILE_TREE`](examples/tier2_widgets/example_file_tree.e) | `example_file_tree` | `TUI_TREE` + `TREE_STATE` (the first example to use them: `select_next` / `select_previous`, `visible_nodes`, expand / collapse), `TUI_BREADCRUMB` (`with_selected`, `with_hit_ids`, the middle collapse to `…`), `FRAME.register_hit` (one region per tree row shown), `TUI_APPLICATION.hit_test` (P2b R2) | A fixed, made-up project tree (no file system, so every run is the same) with the selected node's path as a breadcrumb above it; the breadcrumb follows every change of the selection. Up / Down, Home / End, Right (expand, then enter), Left (collapse, then the parent) and Space move through the tree; a click on a row selects it (again: toggles the folder), the wheel moves. Backspace goes to the parent; Alt+Left / Alt+Right move the breadcrumb's selection (reversed) and Enter goes there; a click on a crumb goes there too. Going to a crumb selects that ancestor and collapses it and every folder below it. A long path or a narrow window collapses the path's middle. q or Esc quits; `-batch` runs two frames. Covered by row-exact snapshots and a scripted run through the real event loop (`TEST_FILE_TREE_EXAMPLE`). |
| [`EXAMPLE_TOASTS`](examples/tier2_widgets/example_toasts.e) | `example_toasts` | `TUI_TOAST` + `TOAST_QUEUE` (levels, expiry, `max_visible`, positions, `expired_action`), `TUI_THEME`, `TICK_EVENT` + `MONOTONIC_CLOCK`, `TUI_TOAST.with_hit_id_base` + `TOAST_QUEUE.dismiss_id` / `TUI_APPLICATION.hit_test` (P2 W5) | Toasts over a help panel. i / s / w / e push an info, success, warning or error toast, l a long word-wrapped one, b five at once (two wait for room); p moves them round the six positions, m cycles `max_visible` (1–3), t switches the dark and light themes, a click dismisses a toast, c clears, q quits. Each tick expires the toasts on the monotonic clock; the status line counts the shown, waiting and expired ones. Covered by `TEST_TOAST.test_toasts_example` on a test clock. |
| [`EXAMPLE_TOOLTIPS`](examples/tier2_widgets/example_tooltips.e) | `example_tooltips` | `TUI_TOOLTIP` + `HOVER_STATE`, `OVERLAY_PLACEMENT` (shift at the right edge, flip at the bottom), `TUI_APPLICATION.set_mouse_motion` (mode 1003, `MOUSE_EVENT.is_move`), `hit_test`, `TICK_EVENT`, `TUI_CHECKBOX`, `FOCUS_MANAGER` (P2 W6) | Four checkboxes with help texts. Rest the pointer on one for half a second and its tooltip appears next to it; another control starts the delay again, an empty cell hides it, and a click or a key dismisses it. F1 shows the focused control's tooltip without the mouse. "Autosave" sits at the right edge (its box is shifted left) and "Spell check" on the last rows (its box flips above). Tab, Space or a click toggles, q or Esc quits. Run with `-batch` for two frames |
| [`EXAMPLE_SETTINGS`](examples/tier2_widgets/example_settings.e) | `example_settings` | `TUI_THEME_FILE` (load / save, P2 C3), `TUI_THEME` presets, `TUI_MENU` + `MENU_STATE`, `TUI_CHECKBOX`, `TUI_SLIDER` + `SLIDER_STATE`, `TUI_DIVIDER`, `TUI_TOAST` + `TOAST_QUEUE`, `FOCUS_MANAGER`, `TUI_APPLICATION.hit_test` (P2 step 7: W1–W5 and C3 together) | A settings screen in a theme: a menu bar (File, Theme, Help), three checkboxes, volume and scroll-speed sliders and section rules, every widget styled from the current `TUI_THEME`. t (or Theme > Next theme) cycles dark, light, nord and dracula; Theme > Dark … picks one; s (or File > Save theme) writes the theme to `settings_theme.toml` with `TUI_THEME_FILE.save` and shows a success toast (an error toast when it cannot). A theme file given as an argument (for example `examples/themes/nord.toml`) is loaded first; a bad one shows its error, with its line, in an error toast. `-write-presets DIR` writes the four presets (that is how `examples/themes/` is made); `-batch` runs two frames; any other `-` option prints the usage and exits with status 2. Covered by row-exact snapshots in `TEST_THEME_FILE.test_settings_example`. |
| [`EXAMPLE_ASYNC_SCAN`](examples/tier5_advanced/example_async_scan.e) | `example_async_scan` | `WORKER_THREAD` + `TUI_APPLICATION.post_event` (`CUSTOM_EVENT`), `TUI_APPLICATION.stop_background_work` (P2 B2), `MUTEX`, `TUI_TABLE`, `TUI_GAUGE`, `TUI_TOAST` + `TOAST_QUEUE`; `DIRECTORY_SCANNER`, `DIRECTORY_SCAN_PROGRESS`, `DIRECTORY_SCAN_RESULT`, `DIRECTORY_SCAN_PLATFORM` (in the example's cluster) (P2 A1) | Real blocking work on a worker thread: a directory walk of the repository (the nearest directory holding `eiffeltui.ecf`, else the current directory) or of a path argument, finding the largest directories and files (two tables, sizes in KiB / MiB). While it runs, progress events at most every 50 ms drive a spinner, the counts and a gauge of the root's entries done. Esc cancels (a flag behind a `MUTEX`, read between directories; the worker stops and posts nothing), r scans again (each scan has a generation number; an event from an older or cancelled scan is dropped in `process`), q quits (the scans are cancelled and the workers joined, 500 ms timeout each, before `run` returns). A directory that cannot be read is listed under the tables with a warning toast; a path that does not exist gives the error state and an error toast. Symbolic links (and Windows junctions) are counted, not followed; directories named `EIFGENs` and `.git` are left out unless `-all`. `-batch` scans, draws the result, quits (after one minute at the latest) and prints a summary line; any other `-` option prints the usage and exits with status 2. Covered by `TEST_ASYNC_SCAN` (a row-exact snapshot of a batch run on a temporary tree, cancel, a stale result dropped, quit within and past the join timeout). |

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

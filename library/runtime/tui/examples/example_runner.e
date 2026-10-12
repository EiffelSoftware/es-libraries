note
	description: "[
		EiffelTUI Examples Master Runner.
		Launches individual Tier 1 Foundation & Tier 2 Widget Specialist examples
		by name or number, or runs automated batch suites.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_RUNNER

create
	make

feature {NONE} -- Initialization

	make
			-- Inspect CLI arguments and dispatch chosen example.
		local
			l_args: ARGUMENTS_32
			l_choice: STRING_32
		do
			create l_args
			if l_args.argument_count > 0 then
				l_choice := l_args.argument (1)
				run_choice (l_choice)
			else
				print_menu
			end
		end

feature {NONE} -- Runner Dispatch

	run_choice (a_choice: STRING_32)
			-- Run example matching `a_choice`.
		local
			l_hw: EXAMPLE_HELLO_WORLD
			l_min: EXAMPLE_MINIMAL
			l_rgb: EXAMPLE_COLORS_RGB
			l_exp: EXAMPLE_COLOR_EXPLORER
			l_mod: EXAMPLE_MODIFIERS
			l_pop: EXAMPLE_POPUP
			l_inl: EXAMPLE_INLINE
			l_todo: EXAMPLE_TODO_LIST
			l_inp: EXAMPLE_USER_INPUT
			l_form: EXAMPLE_INPUT_FORM
			l_tbl: EXAMPLE_TABLE
			l_sb: EXAMPLE_SCROLLBAR
			l_gauge: EXAMPLE_GAUGE
			l_cal: EXAMPLE_CALENDAR_EXPLORER
			l_flex: EXAMPLE_FLEX
			l_constr: EXAMPLE_CONSTRAINTS
			l_cexp: EXAMPLE_CONSTRAINT_EXPLORER
			l_canv: EXAMPLE_CANVAS
			l_chart: EXAMPLE_CHART
			l_weather: EXAMPLE_WEATHER
			l_mdraw: EXAMPLE_MOUSE_DRAWING
			l_demo: EXAMPLE_DEMO
			l_demo2: EXAMPLE_DEMO2
			l_panic: EXAMPLE_PANIC
			l_cust: EXAMPLE_CUSTOM_WIDGET
			l_wcont: EXAMPLE_WIDGET_CONTAINER
			l_advw: EXAMPLE_ADVANCED_WIDGET
			l_hyp: EXAMPLE_HYPERLINK
			l_relh: EXAMPLE_RELEASE_HEADER
			l_vol: EXAMPLE_VOLATILITY_SURFACE
			l_log: EXAMPLE_LOGGING
			l_agithub: EXAMPLE_ASYNC_GITHUB
		do
			-- Tier 1: Foundations
			if a_choice.is_case_insensitive_equal ("hello_world") or
				a_choice.is_case_insensitive_equal ("hello-world") or
				a_choice.is_equal ("1") then
				create l_hw.make
			elseif a_choice.is_case_insensitive_equal ("minimal") or
				a_choice.is_equal ("2") then
				create l_min.make
			elseif a_choice.is_case_insensitive_equal ("colors_rgb") or
				a_choice.is_case_insensitive_equal ("colors-rgb") or
				a_choice.is_equal ("3") then
				create l_rgb.make
			elseif a_choice.is_case_insensitive_equal ("color_explorer") or
				a_choice.is_case_insensitive_equal ("color-explorer") or
				a_choice.is_equal ("4") then
				create l_exp.make
			elseif a_choice.is_case_insensitive_equal ("modifiers") or
				a_choice.is_equal ("5") then
				create l_mod.make
			elseif a_choice.is_case_insensitive_equal ("popup") or
				a_choice.is_equal ("6") then
				create l_pop.make
			elseif a_choice.is_case_insensitive_equal ("inline") or
				a_choice.is_equal ("7") then
				create l_inl.make

			-- Tier 2: Widget Specialists
			elseif a_choice.is_case_insensitive_equal ("todo_list") or
				a_choice.is_case_insensitive_equal ("todo-list") or
				a_choice.is_case_insensitive_equal ("todo") or
				a_choice.is_equal ("8") then
				create l_todo.make
			elseif a_choice.is_case_insensitive_equal ("user_input") or
				a_choice.is_case_insensitive_equal ("user-input") or
				a_choice.is_case_insensitive_equal ("input") or
				a_choice.is_equal ("9") then
				create l_inp.make
			elseif a_choice.is_case_insensitive_equal ("input_form") or
				a_choice.is_case_insensitive_equal ("input-form") or
				a_choice.is_case_insensitive_equal ("form") or
				a_choice.is_equal ("10") then
				create l_form.make
			elseif a_choice.is_case_insensitive_equal ("table") or
				a_choice.is_equal ("11") then
				create l_tbl.make
			elseif a_choice.is_case_insensitive_equal ("scrollbar") or
				a_choice.is_equal ("12") then
				create l_sb.make
			elseif a_choice.is_case_insensitive_equal ("gauge") or
				a_choice.is_equal ("13") then
				create l_gauge.make
			elseif a_choice.is_case_insensitive_equal ("calendar_explorer") or
				a_choice.is_case_insensitive_equal ("calendar-explorer") or
				a_choice.is_case_insensitive_equal ("calendar") or
				a_choice.is_equal ("14") then
				create l_cal.make

			-- Tier 3: Layouts & Visualization
			elseif a_choice.is_case_insensitive_equal ("flex") or
				a_choice.is_equal ("15") then
				create l_flex.make
			elseif a_choice.is_case_insensitive_equal ("constraints") or
				a_choice.is_equal ("16") then
				create l_constr.make
			elseif a_choice.is_case_insensitive_equal ("constraint_explorer") or
				a_choice.is_case_insensitive_equal ("constraint-explorer") or
				a_choice.is_case_insensitive_equal ("explorer") or
				a_choice.is_equal ("17") then
				create l_cexp.make
			elseif a_choice.is_case_insensitive_equal ("canvas") or
				a_choice.is_equal ("18") then
				create l_canv.make
			elseif a_choice.is_case_insensitive_equal ("chart") or
				a_choice.is_equal ("19") then
				create l_chart.make
			elseif a_choice.is_case_insensitive_equal ("weather") or
				a_choice.is_equal ("20") then
				create l_weather.make
			elseif a_choice.is_case_insensitive_equal ("mouse_drawing") or
				a_choice.is_case_insensitive_equal ("mouse-drawing") or
				a_choice.is_case_insensitive_equal ("mouse") or
				a_choice.is_equal ("21") then
				create l_mdraw.make

			-- Tier 4: Flagship Showcase Dashboards
			elseif a_choice.is_case_insensitive_equal ("demo") or
				a_choice.is_equal ("22") then
				create l_demo.make
			elseif a_choice.is_case_insensitive_equal ("demo2") or
				a_choice.is_equal ("23") then
				create l_demo2.make

			-- Tier 5: Advanced & Ecosystem
			elseif a_choice.is_case_insensitive_equal ("panic") or
				a_choice.is_equal ("24") then
				create l_panic.make
			elseif a_choice.is_case_insensitive_equal ("custom_widget") or
				a_choice.is_case_insensitive_equal ("custom-widget") or
				a_choice.is_case_insensitive_equal ("custom") or
				a_choice.is_equal ("25") then
				create l_cust.make
			elseif a_choice.is_case_insensitive_equal ("widget_container") or
				a_choice.is_case_insensitive_equal ("widget-container") or
				a_choice.is_case_insensitive_equal ("widget-ref-container") or
				a_choice.is_case_insensitive_equal ("container") or
				a_choice.is_equal ("26") then
				create l_wcont.make
			elseif a_choice.is_case_insensitive_equal ("advanced_widget") or
				a_choice.is_case_insensitive_equal ("advanced-widget") or
				a_choice.is_case_insensitive_equal ("advanced-widget-impl") or
				a_choice.is_case_insensitive_equal ("advanced") or
				a_choice.is_equal ("27") then
				create l_advw.make
			elseif a_choice.is_case_insensitive_equal ("hyperlink") or
				a_choice.is_case_insensitive_equal ("link") or
				a_choice.is_equal ("28") then
				create l_hyp.make
			elseif a_choice.is_case_insensitive_equal ("release_header") or
				a_choice.is_case_insensitive_equal ("release-header") or
				a_choice.is_case_insensitive_equal ("release") or
				a_choice.is_case_insensitive_equal ("banner") or
				a_choice.is_equal ("29") then
				create l_relh.make
			elseif a_choice.is_case_insensitive_equal ("volatility_surface") or
				a_choice.is_case_insensitive_equal ("volatility-surface") or
				a_choice.is_case_insensitive_equal ("volatility") or
				a_choice.is_case_insensitive_equal ("surface") or
				a_choice.is_equal ("30") then
				create l_vol.make
			elseif a_choice.is_case_insensitive_equal ("logging") or
				a_choice.is_case_insensitive_equal ("tracing") or
				a_choice.is_case_insensitive_equal ("trace") or
				a_choice.is_equal ("31") then
				create l_log.make
			elseif a_choice.is_case_insensitive_equal ("async_github") or
				a_choice.is_case_insensitive_equal ("async-github") or
				a_choice.is_case_insensitive_equal ("async") or
				a_choice.is_case_insensitive_equal ("github") or
				a_choice.is_equal ("32") then
				create l_agithub.make

			-- Batch Test Runners
			elseif a_choice.is_case_insensitive_equal ("tier1") or
				a_choice.is_case_insensitive_equal ("tier1-batch") then
				run_tier1_batch
			elseif a_choice.is_case_insensitive_equal ("tier2") or
				a_choice.is_case_insensitive_equal ("tier2-batch") then
				run_tier2_batch
			elseif a_choice.is_case_insensitive_equal ("tier3") or
				a_choice.is_case_insensitive_equal ("tier3-batch") then
				run_tier3_batch
			elseif a_choice.is_case_insensitive_equal ("tier4") or
				a_choice.is_case_insensitive_equal ("tier4-batch") then
				run_tier4_batch
			elseif a_choice.is_case_insensitive_equal ("tier5") or
				a_choice.is_case_insensitive_equal ("tier5-batch") then
				run_tier5_batch
			elseif a_choice.is_case_insensitive_equal ("all-batch") or
				a_choice.is_case_insensitive_equal ("batch") or
				a_choice.is_case_insensitive_equal ("--batch") then
				run_all_batch
			else
				io.put_string ("Unknown example choice: ")
				io.put_string_32 (a_choice)
				io.put_new_line
				print_menu
			end
		end

	run_tier1_batch
			-- Run all 7 Tier 1 foundation examples in batch mode.
		local
			l_hw: EXAMPLE_HELLO_WORLD
			l_min: EXAMPLE_MINIMAL
			l_rgb: EXAMPLE_COLORS_RGB
			l_exp: EXAMPLE_COLOR_EXPLORER
			l_mod: EXAMPLE_MODIFIERS
			l_pop: EXAMPLE_POPUP
			l_inl: EXAMPLE_INLINE
		do
			io.put_string ("--- Running Tier 1 Foundation Batch Suite ---%N")
			io.put_string ("[1/7] Running EXAMPLE_HELLO_WORLD in batch mode...%N")
			create l_hw.make_batch (2)
			io.put_string ("[1/7] EXAMPLE_HELLO_WORLD completed successfully.%N")

			io.put_string ("[2/7] Running EXAMPLE_MINIMAL in batch mode...%N")
			create l_min.make_batch (2)
			io.put_string ("[2/7] EXAMPLE_MINIMAL completed successfully.%N")

			io.put_string ("[3/7] Running EXAMPLE_COLORS_RGB in batch mode...%N")
			create l_rgb.make_batch (5)
			io.put_string ("[3/7] EXAMPLE_COLORS_RGB completed successfully.%N")

			io.put_string ("[4/7] Running EXAMPLE_COLOR_EXPLORER in batch mode...%N")
			create l_exp.make_batch (2)
			io.put_string ("[4/7] EXAMPLE_COLOR_EXPLORER completed successfully.%N")

			io.put_string ("[5/7] Running EXAMPLE_MODIFIERS in batch mode...%N")
			create l_mod.make_batch (2)
			io.put_string ("[5/7] EXAMPLE_MODIFIERS completed successfully.%N")

			io.put_string ("[6/7] Running EXAMPLE_POPUP in batch mode...%N")
			create l_pop.make_batch (2)
			io.put_string ("[6/7] EXAMPLE_POPUP completed successfully.%N")

			io.put_string ("[7/7] Running EXAMPLE_INLINE in batch mode...%N")
			create l_inl.make_batch (5)
			io.put_string ("[7/7] EXAMPLE_INLINE completed successfully.%N")
			io.put_string ("--- Tier 1 Batch Suite Completed Successfully! ---%N")
		end

	run_tier2_batch
			-- Run all 7 Tier 2 widget specialist examples in batch mode.
		local
			l_todo: EXAMPLE_TODO_LIST
			l_inp: EXAMPLE_USER_INPUT
			l_form: EXAMPLE_INPUT_FORM
			l_tbl: EXAMPLE_TABLE
			l_sb: EXAMPLE_SCROLLBAR
			l_gauge: EXAMPLE_GAUGE
			l_cal: EXAMPLE_CALENDAR_EXPLORER
		do
			io.put_string ("--- Running Tier 2 Widget Specialist Batch Suite ---%N")
			io.put_string ("[1/7] Running EXAMPLE_TODO_LIST in batch mode...%N")
			create l_todo.make_batch (2)
			io.put_string ("[1/7] EXAMPLE_TODO_LIST completed successfully.%N")

			io.put_string ("[2/7] Running EXAMPLE_USER_INPUT in batch mode...%N")
			create l_inp.make_batch (2)
			io.put_string ("[2/7] EXAMPLE_USER_INPUT completed successfully.%N")

			io.put_string ("[3/7] Running EXAMPLE_INPUT_FORM in batch mode...%N")
			create l_form.make_batch (2)
			io.put_string ("[3/7] EXAMPLE_INPUT_FORM completed successfully.%N")

			io.put_string ("[4/7] Running EXAMPLE_TABLE in batch mode...%N")
			create l_tbl.make_batch (2)
			io.put_string ("[4/7] EXAMPLE_TABLE completed successfully.%N")

			io.put_string ("[5/7] Running EXAMPLE_SCROLLBAR in batch mode...%N")
			create l_sb.make_batch (2)
			io.put_string ("[5/7] EXAMPLE_SCROLLBAR completed successfully.%N")

			io.put_string ("[6/7] Running EXAMPLE_GAUGE in batch mode...%N")
			create l_gauge.make_batch (5)
			io.put_string ("[6/7] EXAMPLE_GAUGE completed successfully.%N")

			io.put_string ("[7/7] Running EXAMPLE_CALENDAR_EXPLORER in batch mode...%N")
			create l_cal.make_batch (2)
			io.put_string ("[7/7] EXAMPLE_CALENDAR_EXPLORER completed successfully.%N")
			io.put_string ("--- Tier 2 Batch Suite Completed Successfully! ---%N")
		end

	run_tier3_batch
			-- Run all 7 Tier 3 layout and visualization examples in batch mode.
		local
			l_flex: EXAMPLE_FLEX
			l_constr: EXAMPLE_CONSTRAINTS
			l_cexp: EXAMPLE_CONSTRAINT_EXPLORER
			l_canv: EXAMPLE_CANVAS
			l_chart: EXAMPLE_CHART
			l_weather: EXAMPLE_WEATHER
			l_mdraw: EXAMPLE_MOUSE_DRAWING
		do
			io.put_string ("--- Running Tier 3 Layouts & Visualization Batch Suite ---%N")
			io.put_string ("[1/7] Running EXAMPLE_FLEX in batch mode...%N")
			create l_flex.make_batch (2)
			io.put_string ("[1/7] EXAMPLE_FLEX completed successfully.%N")

			io.put_string ("[2/7] Running EXAMPLE_CONSTRAINTS in batch mode...%N")
			create l_constr.make_batch (2)
			io.put_string ("[2/7] EXAMPLE_CONSTRAINTS completed successfully.%N")

			io.put_string ("[3/7] Running EXAMPLE_CONSTRAINT_EXPLORER in batch mode...%N")
			create l_cexp.make_batch (2)
			io.put_string ("[3/7] EXAMPLE_CONSTRAINT_EXPLORER completed successfully.%N")

			io.put_string ("[4/7] Running EXAMPLE_CANVAS in batch mode...%N")
			create l_canv.make_batch (5)
			io.put_string ("[4/7] EXAMPLE_CANVAS completed successfully.%N")

			io.put_string ("[5/7] Running EXAMPLE_CHART in batch mode...%N")
			create l_chart.make_batch (5)
			io.put_string ("[5/7] EXAMPLE_CHART completed successfully.%N")

			io.put_string ("[6/7] Running EXAMPLE_WEATHER in batch mode...%N")
			create l_weather.make_batch (2)
			io.put_string ("[6/7] EXAMPLE_WEATHER completed successfully.%N")

			io.put_string ("[7/7] Running EXAMPLE_MOUSE_DRAWING in batch mode...%N")
			create l_mdraw.make_batch (2)
			io.put_string ("[7/7] EXAMPLE_MOUSE_DRAWING completed successfully.%N")
			io.put_string ("--- Tier 3 Batch Suite Completed Successfully! ---%N")
		end

	run_tier4_batch
			-- Run both Tier 4 flagship showcase examples in batch mode.
		local
			l_demo: EXAMPLE_DEMO
			l_demo2: EXAMPLE_DEMO2
		do
			io.put_string ("--- Running Tier 4 Flagship Showcase Batch Suite ---%N")
			io.put_string ("[1/2] Running EXAMPLE_DEMO in batch mode...%N")
			create l_demo.make_batch (3)
			io.put_string ("[1/2] EXAMPLE_DEMO completed successfully.%N")

			io.put_string ("[2/2] Running EXAMPLE_DEMO2 in batch mode...%N")
			create l_demo2.make_batch (3)
			io.put_string ("[2/2] EXAMPLE_DEMO2 completed successfully.%N")
			io.put_string ("--- Tier 4 Batch Suite Completed Successfully! ---%N")
		end

	run_tier5_batch
			-- Run all 9 Tier 5 advanced & ecosystem examples in batch mode.
		local
			l_panic: EXAMPLE_PANIC
			l_cust: EXAMPLE_CUSTOM_WIDGET
			l_wcont: EXAMPLE_WIDGET_CONTAINER
			l_advw: EXAMPLE_ADVANCED_WIDGET
			l_hyp: EXAMPLE_HYPERLINK
			l_relh: EXAMPLE_RELEASE_HEADER
			l_vol: EXAMPLE_VOLATILITY_SURFACE
			l_log: EXAMPLE_LOGGING
			l_agithub: EXAMPLE_ASYNC_GITHUB
		do
			io.put_string ("--- Running Tier 5 Advanced & Ecosystem Batch Suite ---%N")
			io.put_string ("[1/9] Running EXAMPLE_PANIC in batch mode...%N")
			create l_panic.make_batch (2)
			io.put_string ("[1/9] EXAMPLE_PANIC completed successfully.%N")

			io.put_string ("[2/9] Running EXAMPLE_CUSTOM_WIDGET in batch mode...%N")
			create l_cust.make_batch (2)
			io.put_string ("[2/9] EXAMPLE_CUSTOM_WIDGET completed successfully.%N")

			io.put_string ("[3/9] Running EXAMPLE_WIDGET_CONTAINER in batch mode...%N")
			create l_wcont.make_batch (2)
			io.put_string ("[3/9] EXAMPLE_WIDGET_CONTAINER completed successfully.%N")

			io.put_string ("[4/9] Running EXAMPLE_ADVANCED_WIDGET in batch mode...%N")
			create l_advw.make_batch (3)
			io.put_string ("[4/9] EXAMPLE_ADVANCED_WIDGET completed successfully.%N")

			io.put_string ("[5/9] Running EXAMPLE_HYPERLINK in batch mode...%N")
			create l_hyp.make_batch (2)
			io.put_string ("[5/9] EXAMPLE_HYPERLINK completed successfully.%N")

			io.put_string ("[6/9] Running EXAMPLE_RELEASE_HEADER in batch mode...%N")
			create l_relh.make_batch (2)
			io.put_string ("[6/9] EXAMPLE_RELEASE_HEADER completed successfully.%N")

			io.put_string ("[7/9] Running EXAMPLE_VOLATILITY_SURFACE in batch mode...%N")
			create l_vol.make_batch (3)
			io.put_string ("[7/9] EXAMPLE_VOLATILITY_SURFACE completed successfully.%N")

			io.put_string ("[8/9] Running EXAMPLE_LOGGING in batch mode...%N")
			create l_log.make_batch (2)
			io.put_string ("[8/9] EXAMPLE_LOGGING completed successfully.%N")

			io.put_string ("[9/9] Running EXAMPLE_ASYNC_GITHUB in batch mode...%N")
			create l_agithub.make_batch (3)
			io.put_string ("[9/9] EXAMPLE_ASYNC_GITHUB completed successfully.%N")
			io.put_string ("--- Tier 5 Batch Suite Completed Successfully! ---%N")
		end

	run_all_batch
			-- Run Tier 1, Tier 2, Tier 3, Tier 4, and Tier 5 example suites in batch mode.
		do
			run_tier1_batch
			io.put_new_line
			run_tier2_batch
			io.put_new_line
			run_tier3_batch
			io.put_new_line
			run_tier4_batch
			io.put_new_line
			run_tier5_batch
			io.put_string ("%N*** All 32 Tier 1, 2, 3, 4 & 5 Examples verified and completed successfully! ***%N")
		end

	print_menu
			-- Print available examples and usage help.
		do
			io.put_string ("====================================================%N")
			io.put_string (" EiffelTUI Examples Master Suite%N")
			io.put_string ("====================================================%N")
			io.put_string ("Usage: example_runner <example-name | number | batch>%N%N")
			io.put_string ("Tier 1: Foundations & Fundamentals:%N")
			io.put_string ("  1) hello-world        - Centered greeting card (TUI_PARAGRAPH, TUI_BLOCK)%N")
			io.put_string ("  2) minimal            - Bare-metal direct buffer writing%N")
			io.put_string ("  3) colors-rgb         - Animated 24-bit TrueColor wave with half-blocks%N")
			io.put_string ("  4) color-explorer     - ANSI 16, 256 indexed color cube & grayscale ramp%N")
			io.put_string ("  5) modifiers          - Bold, Dim, Italic, Underline, Blink, Strikethrough%N")
			io.put_string ("  6) popup              - Centered modal dialog with background clearing%N")
			io.put_string ("  7) inline             - Non-fullscreen 8-line inline progress view%N%N")
			io.put_string ("Tier 2: Widget Specialists:%N")
			io.put_string ("  8) todo-list          - Task completion list (TUI_LIST, LIST_STATE)%N")
			io.put_string ("  9) user-input         - Single-line editing buffer (TUI_TEXT_INPUT)%N")
			io.put_string (" 10) input-form         - Multi-field Tab focus & numeric validation%N")
			io.put_string (" 11) table              - Tabular grid with cell highlighting (TUI_TABLE)%N")
			io.put_string (" 12) scrollbar          - Vertical & horizontal scrollbars with arrows%N")
			io.put_string (" 13) gauge              - Percentage, ratio, and sub-block gauges%N")
			io.put_string (" 14) calendar-explorer  - Monthly calendar navigation (TUI_CALENDAR)%N%N")
			io.put_string ("Tier 3: Layouts & Visualization:%N")
			io.put_string (" 15) flex               - Flex justification modes & spacing (LAYOUT, FLEX_JUSTIFY)%N")
			io.put_string (" 16) constraints        - Solver constraint behavior comparison (CONSTRAINT)%N")
			io.put_string (" 17) constraint-explorer- Live interactive layout playground with multi-flex simulation%N")
			io.put_string (" 18) canvas             - 2D vector canvas: world map, animated Pong, shapes & Lissajous%N")
			io.put_string (" 19) chart              - Real-time animated multi-series oscilloscope & scatter chart%N")
			io.put_string (" 20) weather            - 24-hour hourly weather forecast with thermal gradient (BARCHART)%N")
			io.put_string (" 21) mouse-drawing      - Freehand vector sketching on Braille canvas with mouse capture%N%N")
			io.put_string ("Tier 4: Flagship Showcase Dashboards:%N")
			io.put_string (" 22) demo               - Classic README Operations Dashboard (Gauges, Chart, Map, Tables)%N")
			io.put_string (" 23) demo2              - Premier Showcase Dashboard (5 Tabs, TrueColor Wallpaper, Destroy)%N%N")
			io.put_string ("Tier 5: Advanced & Ecosystem:%N")
			io.put_string (" 24) panic              - Guaranteed terminal restoration during unhandled exceptions%N")
			io.put_string (" 25) custom-widget      - Custom 3D beveled button widget with mouse click & themes%N")
			io.put_string (" 26) widget-container   - Heterogeneous polymorphic widget collections (STACK_CONTAINER)%N")
			io.put_string (" 27) advanced-widget    - Lifecycle & state separation: timers, shapes, bouncing coordinates%N")
			io.put_string (" 28) hyperlink          - OSC 8 clickable terminal hyperlink escape sequences%N")
			io.put_string (" 29) release-header     - Banner typography, rainbow shadow reflection & package menus%N")
			io.put_string (" 30) volatility-surface - 3D implied volatility wireframe with rotation on Braille canvas%N")
			io.put_string (" 31) logging            - Diagnostic file logging (tui_trace.log) without screen corruption%N")
			io.put_string (" 32) async-github       - Non-blocking background PR monitor with animated Braille spinner%N%N")
			io.put_string ("Batch Suites:%N")
			io.put_string ("  batch                 - Run all 32 Tier 1, 2, 3, 4, and 5 examples in batch mode%N")
			io.put_string ("  tier1                 - Run Tier 1 examples in batch mode%N")
			io.put_string ("  tier2                 - Run Tier 2 examples in batch mode%N")
			io.put_string ("  tier3                 - Run Tier 3 examples in batch mode%N")
			io.put_string ("  tier4                 - Run Tier 4 examples in batch mode%N")
			io.put_string ("  tier5                 - Run Tier 5 examples in batch mode%N")
			io.put_string ("====================================================%N")
		end

end

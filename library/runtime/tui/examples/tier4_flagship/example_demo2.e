note
	description: "[
		Tier 4 Flagship Showcase Dashboard: Demo 2 (Premier Showcase - Ratatui 1-to-1).
		The flagship application demonstrating the complete EiffelTUI ecosystem:
		- 5 Comprehensive feature tabs: About, Recipe, Email, Traceroute, and Weather
		- Full-screen TrueColor 24-bit background wallpaper with OKLab/HSV gradient
		- Mascot art rendering with half-blocks and dynamic eye states
		- Ratatouille recipe with dual cooking pane, ingredients table, and scrollbar
		- Interactive Email client with folder sub-tabs, inbox selection, and reading pane
		- Bad.Horse network traceroute with 29 hops, ping telemetry, and Australia Canvas map
		- Weather dashboard with Monthly calendar, weekly barchart, seasonal metrics, and line gauge
		- Spectacular 'Destroy' melting sand drip physics mode and animated logo reveal
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_DEMO2

inherit
	TUI_APPLICATION
		redefine
			make
		end

create
	make,
	make_batch

feature {NONE} -- Initialization

	make
			-- Initialize and launch Premier Showcase Demo 2.
		local
			l_args: ARGUMENTS_32
			i: INTEGER
		do
			init_state
			Precursor
			set_tick_rate (33) -- ~30 FPS for silky-smooth animations and particle physics
			create l_args
			auto_exit_frames := -1
			from i := 1 until i > l_args.argument_count loop
				if l_args.argument (i).is_equal ("-batch") then
					auto_exit_frames := 5
				end
				i := i + 1
			end
			frame_counter := 0
			run
		end

	make_batch (a_frames: INTEGER)
			-- Initialize and run for `a_frames` frames in batch mode.
		do
			init_state
			make_with_viewport (create {VIEWPORT}.make_fullscreen)
			set_tick_rate (33)
			auto_exit_frames := a_frames
			frame_counter := 0
			run
		end

feature {NONE} -- State Initialization

	init_state
			-- Setup state across all 5 showcase tabs and physics engine.
		do
			active_tab := 1 -- 1: About, 2: Recipe, 3: Email, 4: Traceroute, 5: Weather
			is_destroy_mode := False
			destroy_frame := 0
			seed := 543210987

			-- About tab
			mascot_eye_red := False

			-- Recipe tab
			recipe_row_index := 1
			init_ingredients

			-- Email tab
			email_row_index := 1
			init_emails

			-- Traceroute tab
			traceroute_row_index := 1
			ping_progress := 0
			init_hops
			init_ping_telemetry

			-- Weather tab
			download_progress := 25
			init_weather_data
		end

	init_ingredients
			-- Populate Ratatouille recipe ingredients list.
		do
			create ingredients_qty.make (11)
			create ingredients_name.make (11)

			ingredients_qty.extend ("4 tbsp"); ingredients_name.extend ("olive oil")
			ingredients_qty.extend ("1");      ingredients_name.extend ("onion thinly sliced")
			ingredients_qty.extend ("4");      ingredients_name.extend ("cloves garlic peeled & sliced")
			ingredients_qty.extend ("1");      ingredients_name.extend ("small bay leaf")
			ingredients_qty.extend ("1");      ingredients_name.extend ("eggplant cut in 1/2 in cubes")
			ingredients_qty.extend ("1");      ingredients_name.extend ("zucchini cut in thin slices")
			ingredients_qty.extend ("1");      ingredients_name.extend ("red bell pepper slivers")
			ingredients_qty.extend ("4");      ingredients_name.extend ("plum tomatoes coarsely chopped")
			ingredients_qty.extend ("1 tsp");  ingredients_name.extend ("kosher salt")
			ingredients_qty.extend ("1/4 cup");ingredients_name.extend ("shredded fresh basil")
			ingredients_qty.extend ("to taste");ingredients_name.extend ("freshly ground black pepper")

			create recipe_table_state.make
			recipe_table_state.select_index (1)
		end

	init_emails
			-- Populate interactive inbox email messages.
		do
			create email_from.make (5)
			create email_subject.make (5)
			create email_body.make (5)

			email_from.extend ("Alice <alice@example.com>")
			email_subject.extend ("Design by Contract architecture")
			email_body.extend ("Hi Bertrand,%NHow is the Void Safety verification coming along?%NLooking forward to the EiffelTUI release!%N%NBest,%NAlice")

			email_from.extend ("Bob <bob@example.com>")
			email_subject.extend ("Re: Design by Contract architecture")
			email_body.extend ("Hi Alice,%NContracts and invariants are passing cleanly across all 32 examples.%NThe CQS builders work like a charm.%N%NBob")

			email_from.extend ("Charlie <charlie@example.com>")
			email_subject.extend ("EiffelStudio 24.05 Compilation Benchmarks")
			email_body.extend ("Hi Team,%NWorkbench and finalized C-compilation benchmarks show instant incremental turnarounds.%NZero GC overhead during TUI rendering!%N%NCharlie")

			email_from.extend ("Dave <dave@example.com>")
			email_subject.extend ("Re: Hello (STOP REPLYING TO ALL)")
			email_body.extend ("Hi Everyone,%NPlease stop replying to all on the announcement thread.%N%NThanks,%NDave")

			email_from.extend ("Eve <eve@example.com>")
			email_subject.extend ("Re: Hello (STOP REPLYING TO ALL)")
			email_body.extend ("Hi Dave,%NI am monitoring all incoming packets from Perth to Sydney.%NTraceroute looks pristine!%N%NEve")

			create email_list_state.make
			email_list_state.select_index (1)
		end

	init_hops
			-- Populate 29 bad.horse traceroute network nodes with Australian coordinates.
		do
			create hop_hosts.make (29)
			create hop_addresses.make (29)
			create hop_coords.make (29)

			add_hop ("home", "127.0.0.1", 149.1, -35.3) -- Canberra
			add_hop ("bad.horse", "162.252.205.130", 151.1, -33.9) -- Sydney
			add_hop ("bad.horse", "162.252.205.131", 144.9, -37.8) -- Melbourne
			add_hop ("bad.horse", "162.252.205.132", 153.0, -27.5) -- Brisbane
			add_hop ("bad.horse", "162.252.205.133", 151.1, -33.9) -- Sydney
			add_hop ("he.rides.across.the.nation", "162.252.205.134", 115.9, -31.9) -- Perth
			add_hop ("the.thoroughbred.of.sin", "162.252.205.135", 130.8, -12.4) -- Darwin
			add_hop ("he.got.the.application", "162.252.205.136", 153.0, -27.5) -- Brisbane
			add_hop ("that.you.just.sent.in", "162.252.205.137", 138.6, -34.9) -- Adelaide
			add_hop ("it.needs.evaluation", "162.252.205.138", 130.8, -12.4) -- Darwin
			add_hop ("so.let.the.games.begin", "162.252.205.139", 115.9, -31.9) -- Perth
			add_hop ("a.heinous.crime", "162.252.205.140", 153.0, -27.5) -- Brisbane
			add_hop ("a.show.of.force", "162.252.205.141", 149.1, -35.3) -- Canberra
			add_hop ("a.murder.would.be.nice", "162.252.205.142", 115.9, -31.9) -- Perth
			add_hop ("bad.horse", "162.252.205.143", 144.9, -37.8) -- Melbourne
			add_hop ("bad.horse", "162.252.205.144", 130.8, -12.4) -- Darwin
			add_hop ("bad.horse", "162.252.205.145", 144.9, -37.8) -- Melbourne
			add_hop ("he-s.bad", "162.252.205.146", 115.9, -31.9) -- Perth
			add_hop ("the.evil.league.of.evil", "162.252.205.147", 153.0, -27.5) -- Brisbane
			add_hop ("is.watching.so.beware", "162.252.205.148", 130.8, -12.4) -- Darwin
			add_hop ("the.grade.that.you.receive", "162.252.205.149", 115.9, -31.9) -- Perth
			add_hop ("will.be.your.last.we.swear", "162.252.205.150", 138.6, -34.9) -- Adelaide
			add_hop ("so.make.bad.horse.gleeful", "162.252.205.151", 151.1, -33.9) -- Sydney
			add_hop ("or.he-ll.make.you.his.mare", "162.252.205.152", 144.9, -37.8) -- Melbourne
			add_hop ("o_o", "162.252.205.153", 153.0, -27.5) -- Brisbane
			add_hop ("you-re.saddled.up", "162.252.205.154", 130.8, -12.4) -- Darwin
			add_hop ("there-s.no.recourse", "162.252.205.155", 115.9, -31.9) -- Perth
			add_hop ("it-s.hi-ho.silver", "162.252.205.156", 151.1, -33.9) -- Sydney
			add_hop ("signed.bad.horse", "162.252.205.157", 149.1, -35.3) -- Canberra

			create traceroute_table_state.make
			traceroute_table_state.select_index (1)
		end

	add_hop (a_host, a_ip: STRING_8; a_lon, a_lat: REAL_64)
			-- Add hop configuration entry.
		do
			hop_hosts.extend (a_host)
			hop_addresses.extend (a_ip)
			hop_coords.extend ([a_lon, a_lat])
		end

	init_ping_telemetry
			-- Initialize telemetry wave data for ping sparkline.
		local
			l_vals: ARRAY [NATURAL_64]
			i: INTEGER
		do
			l_vals := <<8, 8, 8, 8, 7, 7, 7, 6, 6, 5, 4, 3, 3, 2, 2, 1, 1, 1, 2, 2, 3, 4, 5, 6, 7, 7, 8, 8, 8, 7, 7, 6, 5, 4, 3, 2, 1, 1, 1, 1, 1, 2, 4, 6, 7, 8, 8, 8, 8, 6, 4, 2, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7>>
			create ping_telemetry.make (l_vals.count)
			from i := 1 until i > l_vals.count loop
				ping_telemetry.extend (l_vals [i])
				i := i + 1
			end
		end

	init_weather_data
			-- Initialize calendar and barcharts for weather tab.
		do
			create calendar_state.make_with_date (2026, 9, 28)
		end

feature {NONE} -- State Fields

	active_tab: INTEGER
			-- Active tab index: 1 = About, 2 = Recipe, 3 = Email, 4 = Traceroute, 5 = Weather

	is_destroy_mode: BOOLEAN
			-- Has the user triggered the 'Destroy' particle physics mode?

	destroy_frame: INTEGER
			-- Frame counter for destroy dripping physics and logo fade-in

	seed: INTEGER_64
			-- LCG PRNG state

	auto_exit_frames: INTEGER
			-- Batch auto-exit counter (-1 for infinite interactive loop)

	frame_counter: INTEGER
			-- Rendered frame count

	mascot_eye_red: BOOLEAN
			-- Mascot eye color toggle (False = Bright Yellow, True = Red)

	recipe_row_index: INTEGER
			-- Selected ingredient index

	recipe_table_state: TABLE_STATE
			-- Table state for ingredients

	ingredients_qty: ARRAYED_LIST [STRING_8]
			-- Ingredient quantity labels

	ingredients_name: ARRAYED_LIST [STRING_8]
			-- Ingredient name descriptions

	email_row_index: INTEGER
			-- Selected email index

	email_list_state: LIST_STATE
			-- State tracking inbox list cursor

	email_from: ARRAYED_LIST [STRING_8]
			-- Sender addresses

	email_subject: ARRAYED_LIST [STRING_8]
			-- Email subjects

	email_body: ARRAYED_LIST [STRING_8]
			-- Full email message bodies

	traceroute_row_index: INTEGER
			-- Selected network hop index

	traceroute_table_state: TABLE_STATE
			-- Table state for traceroute hops

	hop_hosts: ARRAYED_LIST [STRING_8]
			-- Hostname descriptions

	hop_addresses: ARRAYED_LIST [STRING_8]
			-- IP address strings

	hop_coords: ARRAYED_LIST [TUPLE [lon, lat: REAL_64]]
			-- Geographical coordinates (Longitude, Latitude)

	ping_telemetry: ARRAYED_LIST [NATURAL_64]
			-- Ping sparkline wave points

	ping_progress: INTEGER
			-- Sparkline rotating phase index

	download_progress: INTEGER
			-- Weather tab download percentage (0..100)

	calendar_state: CALENDAR_STATE
			-- Monthly calendar state

feature {NONE} -- Event Handling

	process (a_event: EVENT)
			-- Process input keystrokes and periodic timer ticks.
		local
			ch: CHARACTER_32
		do
			if attached {TICK_EVENT} a_event then
				on_tick
			elseif attached {KEY_EVENT} a_event as k and then k.is_press then
				if k.code.is_escape then
					stop
				elseif k.code.is_left then
					prev_tab
				elseif k.code.is_right or k.code.is_tab then
					next_tab
				elseif k.code.is_up then
					prev_item
				elseif k.code.is_down then
					next_item
				elseif k.code.is_delete then
					toggle_destroy
				elseif k.code.is_char then
					ch := k.code.character
					if ch = 'q' or ch = 'Q' then
						stop
					elseif ch = 'h' or ch = 'H' then
						prev_tab
					elseif ch = 'l' or ch = 'L' then
						next_tab
					elseif ch = 'k' or ch = 'K' then
						prev_item
					elseif ch = 'j' or ch = 'J' then
						next_item
					elseif ch = 'd' or ch = 'D' then
						toggle_destroy
					elseif ch = '1' then
						set_tab (1)
					elseif ch = '2' then
						set_tab (2)
					elseif ch = '3' then
						set_tab (3)
					elseif ch = '4' then
						set_tab (4)
					elseif ch = '5' then
						set_tab (5)
					end
				end
			end
		end

	prev_tab
			-- Navigate to previous tab.
		do
			if is_destroy_mode then
				is_destroy_mode := False
			end
			active_tab := (active_tab - 2 + 5) \\ 5 + 1
		end

	next_tab
			-- Navigate to next tab.
		do
			if is_destroy_mode then
				is_destroy_mode := False
			end
			active_tab := (active_tab \\ 5) + 1
		end

	set_tab (a_index: INTEGER)
			-- Jump directly to tab `a_index`.
		do
			if is_destroy_mode then
				is_destroy_mode := False
			end
			active_tab := a_index
		end

	toggle_destroy
			-- Toggle Destroy mode animation.
		do
			is_destroy_mode := not is_destroy_mode
			if is_destroy_mode then
				destroy_frame := 0
			end
		end

	prev_item
			-- Up navigation within current active tab.
		do
			inspect active_tab
			when 1 then
				mascot_eye_red := not mascot_eye_red
			when 2 then
				recipe_row_index := (recipe_row_index - 2 + ingredients_qty.count) \\ ingredients_qty.count + 1
				recipe_table_state.select_index (recipe_row_index)
			when 3 then
				email_row_index := (email_row_index - 2 + email_from.count) \\ email_from.count + 1
				email_list_state.select_index (email_row_index)
			when 4 then
				traceroute_row_index := (traceroute_row_index - 2 + hop_hosts.count) \\ hop_hosts.count + 1
				traceroute_table_state.select_index (traceroute_row_index)
			when 5 then
				download_progress := (download_progress - 5).max (0)
			else
			end
		end

	next_item
			-- Down navigation within current active tab.
		do
			inspect active_tab
			when 1 then
				mascot_eye_red := not mascot_eye_red
			when 2 then
				recipe_row_index := (recipe_row_index \\ ingredients_qty.count) + 1
				recipe_table_state.select_index (recipe_row_index)
			when 3 then
				email_row_index := (email_row_index \\ email_from.count) + 1
				email_list_state.select_index (email_row_index)
			when 4 then
				traceroute_row_index := (traceroute_row_index \\ hop_hosts.count) + 1
				traceroute_table_state.select_index (traceroute_row_index)
			when 5 then
				download_progress := (download_progress + 5).min (100)
			else
			end
		end

	on_tick
			-- Periodic heartbeat tick: advance animations and ping waveforms.
		local
			l_val: NATURAL_64
		do
			if is_destroy_mode then
				destroy_frame := destroy_frame + 1
			end

			-- Rotate ping telemetry wave
			if ping_telemetry.count > 1 then
				l_val := ping_telemetry.first
				ping_telemetry.start
				ping_telemetry.remove
				ping_telemetry.extend (l_val)
				ping_progress := ping_progress + 1
			end
		end

feature {NONE} -- Rendering Pipeline

	render (a_frame: FRAME)
			-- Main rendering pipeline: Root Dark Blue + Gradient Swatch + Content + Bars.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_title_area, l_body_area, l_footer_area: RECT
		do
			if auto_exit_frames > 0 then
				frame_counter := frame_counter + 1
				if frame_counter >= auto_exit_frames then
					stop
				end
			end

			-- 1. Full-screen HSV TrueColor Gradient Wallpaper
			render_rgb_swatch (a_frame, a_frame.area)

			-- 2. Structure: Title Bar (1), Body (Flex 1), Bottom Key Bar (1)
			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (1)
			>>)
			l_chunks := l_layout.split (a_frame.area)
			l_title_area := l_chunks [1]
			l_body_area := l_chunks [2]
			l_footer_area := l_chunks [3]

			render_title_bar (a_frame, l_title_area)

			-- 3. Render active tab
			inspect active_tab
			when 1 then
				render_about_tab (a_frame, l_body_area)
			when 2 then
				render_recipe_tab (a_frame, l_body_area)
			when 3 then
				render_email_tab (a_frame, l_body_area)
			when 4 then
				render_traceroute_tab (a_frame, l_body_area)
			when 5 then
				render_weather_tab (a_frame, l_body_area)
			else
				render_about_tab (a_frame, l_body_area)
			end

			-- 4. Bottom key bindings bar
			render_bottom_bar (a_frame, l_footer_area)

			-- 5. If Destroy Mode active, apply melting drip physics & logo reveal overlay
			if is_destroy_mode then
				apply_destroy_physics (a_frame)
			end
		end

feature {NONE} -- TrueColor Gradient Wallpaper

	render_rgb_swatch (a_frame: FRAME; a_area: RECT)
			-- Render smooth 24-bit TrueColor upper half-block ('▀') wallpaper across `a_area`.
		local
			x, y: INTEGER
			hue, val_fg, val_bg: REAL_64
			fg_col, bg_col: COLOR
			l_style: STYLE
			l_half_block: CHARACTER_32
			w, h: INTEGER
		do
			l_half_block := (9600).to_character_32 -- Upper half block '▀'
			w := a_area.width.to_integer_32
			h := a_area.height.to_integer_32

			if w > 0 and h > 0 then
				from y := a_area.y.to_integer_32 until y >= a_area.bottom.to_integer_32 loop
					val_fg := (h - (y - a_area.y.to_integer_32)).to_double / h.to_double
					val_bg := (val_fg - (0.5 / h.to_double)).max (0.0)

					from x := a_area.x.to_integer_32 until x >= a_area.right.to_integer_32 loop
						hue := (x - a_area.x.to_integer_32).to_double * 360.0 / w.to_double

						fg_col := hsv_to_color (hue, 0.75, val_fg * 0.7)
						bg_col := hsv_to_color (hue, 0.75, val_bg * 0.7)

						create l_style.make_with_colors (fg_col, bg_col)
						a_frame.buffer.put_char (y, x, l_half_block, l_style)
						x := x + 1
					end
					y := y + 1
				end
			end
		end

	hsv_to_color (h, s, v: REAL_64): COLOR
			-- Convert Hue (0..360), Saturation (0..1), and Value (0..1) to RGB COLOR.
		local
			c, x, m: REAL_64
			r, g, b: REAL_64
			h_sector: INTEGER
			r8, g8, b8: NATURAL_8
		do
			c := v * s
			x := c * (1.0 - (((h / 60.0).floor \\ 2).to_double - 1.0).abs)
			m := v - c

			h_sector := ((h / 60.0).floor.to_integer_32) \\ 6
			inspect h_sector
			when 0 then r := c; g := x; b := 0.0
			when 1 then r := x; g := c; b := 0.0
			when 2 then r := 0.0; g := c; b := x
			when 3 then r := 0.0; g := x; b := c
			when 4 then r := x; g := 0.0; b := c
			else       r := c; g := 0.0; b := x
			end

			r8 := ((r + m) * 255.0).rounded.min (255).max (0).to_natural_8
			g8 := ((g + m) * 255.0).rounded.min (255).max (0).to_natural_8
			b8 := ((b + m) * 255.0).rounded.min (255).max (0).to_natural_8

			create Result.make_rgb (r8, g8, b8)
		end

feature {NONE} -- Title Bar & Bottom Navigation Bar

	render_title_bar (a_frame: FRAME; a_area: RECT)
			-- Render top header with app title and tab buttons.
		local
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_title_area, l_tabs_area: RECT
			l_title_para: TUI_PARAGRAPH
			l_title_text: TEXT
			l_tabs: TUI_TABS
			l_titles: ARRAYED_LIST [READABLE_STRING_GENERAL]
			l_dark_blue: COLOR
			l_tab_style, l_hi_style: STYLE
		do
			l_dark_blue := create {COLOR}.make_rgb (16, 24, 48)

			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (20),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_layout.split (a_area)
			l_title_area := l_chunks [1]
			l_tabs_area := l_chunks [2]

			-- Title: "Ratatui [EiffelTUI]"
			create l_title_text.make_empty
			l_title_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make (
					" Ratatui [EiffelTUI] ",
					(create {STYLE}.make_with_colors ({COLOR}.Bright_white, l_dark_blue)).with_bold
				)
			>>))
			create l_title_para.make (l_title_text)
			a_frame.render_widget (l_title_para, l_title_area)

			-- Tabs
			create l_titles.make (5)
			l_titles.extend (" About ")
			l_titles.extend (" Recipe ")
			l_titles.extend (" Email ")
			l_titles.extend (" Traceroute ")
			l_titles.extend (" Weather ")

			create l_tab_style.make_with_colors ({COLOR}.Dark_gray, l_dark_blue)
			create l_hi_style.make_with_colors ({COLOR}.Bright_yellow, l_dark_blue)
			l_hi_style := l_hi_style.with_bold.with_reversed

			create l_tabs.make_from_strings (l_titles)
			l_tabs := l_tabs.with_style (l_tab_style).
				with_highlight_style (l_hi_style).
				with_divider ("").
				with_selected (active_tab)

			a_frame.render_widget (l_tabs, l_tabs_area)
		end

	render_bottom_bar (a_frame: FRAME; a_area: RECT)
			-- Render bottom command keybindings reference bar.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
			l_key_style, l_desc_style: STYLE
		do
			create l_key_style.make_with_colors ({COLOR}.Bright_white, create {COLOR}.make_rgb (40, 40, 50))
			l_key_style := l_key_style.with_bold
			create l_desc_style.make_with_colors ({COLOR}.Gray, create {COLOR}.make_rgb (20, 20, 30))

			create l_line.make_empty

			l_line.append_span (create {TEXT_SPAN}.make (" H/<- ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Left  ", l_desc_style))

			l_line.append_span (create {TEXT_SPAN}.make (" L/->/Tab ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Right  ", l_desc_style))

			l_line.append_span (create {TEXT_SPAN}.make (" K/^ ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Up  ", l_desc_style))

			l_line.append_span (create {TEXT_SPAN}.make (" J/v ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Down  ", l_desc_style))

			l_line.append_span (create {TEXT_SPAN}.make (" D/Del ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Destroy  ", l_desc_style))

			l_line.append_span (create {TEXT_SPAN}.make (" Q/Esc ", l_key_style))
			l_line.append_span (create {TEXT_SPAN}.make (" Quit ", l_desc_style))

			create l_text.make_empty
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_alignment ({TEXT_ALIGNMENT}.center)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Tab 1: About Tab

	render_about_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 1: Mascot silhouette on left, Description card on right.
		local
			l_card_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_mascot_area, l_desc_area: RECT
		do
			l_card_area := a_area.inner (2, 1)
			a_frame.render_widget (create {TUI_CLEAR}, l_card_area)

			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (34),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_layout.split (l_card_area)
			l_mascot_area := l_chunks [1]
			l_desc_area := l_chunks [2]

			render_mascot (a_frame, l_mascot_area)
			render_about_description (a_frame, l_desc_area)
		end

	render_mascot (a_frame: FRAME; a_area: RECT)
			-- Render ASCII/Half-Block Mascot with Chef Hat and toggling eye color.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_eye_color: COLOR
			l_hat_style, l_rat_style, l_eye_style, l_term_style: STYLE
		do
			if mascot_eye_red then
				l_eye_color := {COLOR}.Bright_red
			else
				l_eye_color := {COLOR}.Bright_yellow
			end

			create l_hat_style.make_fg ({COLOR}.Bright_white)
			l_hat_style := l_hat_style.with_bold
			create l_rat_style.make_fg ({COLOR}.Dark_gray)
			create l_eye_style.make_fg (l_eye_color)
			l_eye_style := l_eye_style.with_bold
			create l_term_style.make_fg ({COLOR}.Bright_cyan)

			create l_text.make_empty

			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("             __  __             ", l_hat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("            /  \/  \            ", l_hat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("           |        |           ", l_hat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("          (  Chef   )           ", l_hat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("           \________/  /\_/\    ", l_hat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("              ||      ( ", l_rat_style),
				create {TEXT_SPAN}.make ("o", l_eye_style),
				create {TEXT_SPAN}.make (".", l_rat_style),
				create {TEXT_SPAN}.make ("o", l_eye_style),
				create {TEXT_SPAN}.make (" )   ", l_rat_style)
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("             /  \     > ^ <     ", l_rat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("            /|  |\     / \      ", l_rat_style)>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("          +-------+   (   )     ", l_term_style)
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("          | >_TUI |   /   \     ", l_term_style)
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("          +-------+  (__|__)    ", l_term_style)
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<create {TEXT_SPAN}.make ("          [Press Up/Down for Eye] ", create {STYLE}.make_fg ({COLOR}.Gray))>>))

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_about_description (a_frame: FRAME; a_area: RECT)
			-- Render description panel.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_dark_blue: COLOR
		do
			l_dark_blue := create {COLOR}.make_rgb (16, 24, 48)

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" About EiffelTUI ")

			create l_text.make_empty
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("- cooking up terminal user interfaces -%N%N", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("EiffelTUI is a premier native Eiffel library for building rich terminal applications.%NIt provides a 1-to-1 ergonomic translation of Ratatui into Design by Contract,%Nfeaturing immutable CQS builder patterns, Void Safety, and cross-platform drivers.%N%N", create {STYLE}.make_fg ({COLOR}.White))
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("Key Architecture Highlights:%N", (create {STYLE}.make_fg ({COLOR}.Bright_green)).with_bold),
				create {TEXT_SPAN}.make ("  * Terminal Pipeline: FRAME -> BUFFER -> DIFF_ENGINE -> ANSI_SERIALIZER%N  * Strict CQS: Immutable widgets with fluent with_* queries%N  * Void-safe across loops and attached agents%N  * Unified Windows Console & POSIX PTY drivers%N", create {STYLE}.make_fg ({COLOR}.Gray))
			>>))

			create l_para.make (l_text)
			l_para := l_para.with_block (l_block)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Tab 2: Recipe Tab

	render_recipe_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 2: Ratatouille Cooking instructions on left, Ingredients on right.
		local
			l_card_area: RECT
			l_block: TUI_BLOCK
			l_inner_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_recipe_area, l_ingr_area: RECT
		do
			l_card_area := a_area.inner (2, 1)
			a_frame.render_widget (create {TUI_CLEAR}, l_card_area)

			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" Ratatouille Recipe ")
			a_frame.render_widget (l_block, l_card_area)

			l_inner_area := l_card_area.inner (2, 1)

			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (44),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_layout.split (l_inner_area)
			l_recipe_area := l_chunks [1]
			l_ingr_area := l_chunks [2]

			render_recipe_steps (a_frame, l_recipe_area)
			render_ingredients_table (a_frame, l_ingr_area)
		end

	render_recipe_steps (a_frame: FRAME; a_area: RECT)
			-- Cooking instruction steps.
		local
			l_para: TUI_PARAGRAPH
			l_text: TEXT
		do
			create l_text.make_empty
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("Step 1: ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold),
				create {TEXT_SPAN}.make ("Over medium-low heat, add the oil to a large skillet with the onion, garlic, and bay leaf, stirring occasionally, until softened.%N%N", create {STYLE}.make_fg ({COLOR}.White))
			>>))
			l_text.append_line (create {TEXT_LINE}.make (<<
				create {TEXT_SPAN}.make ("Step 2: ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold),
				create {TEXT_SPAN}.make ("Add the eggplant and cook, stirring occasionally, for 8 minutes. Stir in zucchini, bell pepper, tomatoes, and salt; cook for 5-7 minutes. Stir in fresh basil to taste.%N", create {STYLE}.make_fg ({COLOR}.White))
			>>))

			create l_para.make (l_text)
			a_frame.render_widget (l_para, a_area)
		end

	render_ingredients_table (a_frame: FRAME; a_area: RECT)
			-- Ingredients table with vertical scrollbar.
		local
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_row: TABLE_ROW
			l_sb: TUI_SCROLLBAR
			l_sb_state: SCROLLBAR_STATE
			i: INTEGER
			l_sel_style: STYLE
		do
			create l_header.make_raw (<<"Qty", "Ingredient">>)
			l_header := l_header.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold.with_underline)

			create l_rows.make (ingredients_qty.count)
			from i := 1 until i > ingredients_qty.count loop
				create l_row.make_raw (<<ingredients_qty [i], ingredients_name [i]>>)
				if i = recipe_row_index then
					l_row := l_row.with_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold)
				else
					l_row := l_row.with_style (create {STYLE}.make_fg ({COLOR}.Gray))
				end
				l_rows.extend (l_row)
				i := i + 1
			end

			create l_sel_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)

			create l_table.make (
				l_rows,
				<<
					{CONSTRAINTS}.fixed (10),
					{CONSTRAINTS}.flex (1)
				>>
			)
			l_table := l_table.with_header (l_header).with_row_highlight_style (l_sel_style)

			a_frame.render_stateful_widget (l_table, a_area, recipe_table_state)

			-- Vertical Scrollbar
			create l_sb_state.make (ingredients_qty.count)
			l_sb_state.set_position (recipe_row_index)
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb := l_sb.with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			a_frame.render_stateful_widget (l_sb, a_area, l_sb_state)
		end

feature {NONE} -- Tab 3: Email Tab

	render_email_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 3: Folder sub-tabs, Inbox message list, and reading pane.
		local
			l_card_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_inbox_area, l_reading_area: RECT
		do
			l_card_area := a_area.inner (2, 1)
			a_frame.render_widget (create {TUI_CLEAR}, l_card_area)

			create l_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (8),
				{CONSTRAINTS}.flex (1)
			>>)
			l_chunks := l_layout.split (l_card_area)
			l_inbox_area := l_chunks [1]
			l_reading_area := l_chunks [2]

			render_email_inbox (a_frame, l_inbox_area)
			render_email_reader (a_frame, l_reading_area)
		end

	render_email_inbox (a_frame: FRAME; a_area: RECT)
			-- Email folders and message list.
		local
			l_v_layout: LAYOUT
			l_v_chunks: ARRAY [RECT]
			l_folder_area, l_list_area: RECT
			l_tabs: TUI_TABS
			l_items: ARRAYED_LIST [LIST_ITEM]
			l_item: LIST_ITEM
			l_list: TUI_LIST
			i: INTEGER
			l_sb: TUI_SCROLLBAR
			l_sb_state: SCROLLBAR_STATE
		do
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.fixed (1),
				{CONSTRAINTS}.flex (1)
			>>)
			l_v_chunks := l_v_layout.split (a_area)
			l_folder_area := l_v_chunks [1]
			l_list_area := l_v_chunks [2]

			-- Sub-tabs: Inbox, Sent, Drafts
			create l_tabs.make_from_strings (<<" [ Inbox (5) ] ", " [ Sent (2) ] ", " [ Drafts (0) ] ">>)
			l_tabs := l_tabs.with_style (create {STYLE}.make_fg ({COLOR}.Dark_gray)).
				with_highlight_style ((create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold).
				with_selected (1)
			a_frame.render_widget (l_tabs, l_folder_area)

			-- Message list
			create l_items.make (email_from.count)
			from i := 1 until i > email_from.count loop
				create l_item.make_raw (email_from [i] + "  -  " + email_subject [i])
				l_items.extend (l_item)
				i := i + 1
			end

			create l_list.make (l_items)
			l_list := l_list.with_highlight_symbol (">> ").
				with_highlight_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			a_frame.render_stateful_widget (l_list, l_list_area, email_list_state)

			-- Scrollbar
			create l_sb_state.make (email_from.count)
			l_sb_state.set_position (email_row_index)
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_right)
			l_sb := l_sb.with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan))
			a_frame.render_stateful_widget (l_sb, l_list_area, l_sb_state)
		end

	render_email_reader (a_frame: FRAME; a_area: RECT)
			-- Email reading pane.
		local
			l_block: TUI_BLOCK
			l_para: TUI_PARAGRAPH
			l_text: TEXT
			l_line: TEXT_LINE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Reading Pane ")

			create l_text.make_empty

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("From: ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make (email_from [email_row_index] + "%N", create {STYLE}.make_fg ({COLOR}.White)))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make ("Subject: ", (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold))
			l_line.append_span (create {TEXT_SPAN}.make (email_subject [email_row_index] + "%N%N", (create {STYLE}.make_fg ({COLOR}.Bright_white)).with_bold))
			l_text.append_line (l_line)

			create l_line.make_empty
			l_line.append_span (create {TEXT_SPAN}.make (email_body [email_row_index], create {STYLE}.make_fg ({COLOR}.Gray)))
			l_text.append_line (l_line)

			create l_para.make (l_text)
			l_para := l_para.with_block (l_block)
			a_frame.render_widget (l_para, a_area)
		end

feature {NONE} -- Tab 4: Traceroute Tab

	render_traceroute_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 4: 29 Hops table & Ping sparkline on left, Australia Map on right.
		local
			l_card_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_left_area, l_map_area: RECT
			l_left_layout: LAYOUT
			l_left_chunks: ARRAY [RECT]
			l_hops_area, l_ping_area: RECT
		do
			l_card_area := a_area.inner (2, 1)
			a_frame.render_widget (create {TUI_CLEAR}, l_card_area)

			create l_layout.make_horizontal (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_chunks := l_layout.split (l_card_area)
			l_left_area := l_chunks [1]
			l_map_area := l_chunks [2]

			create l_left_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (3)
			>>)
			l_left_chunks := l_left_layout.split (l_left_area)
			l_hops_area := l_left_chunks [1]
			l_ping_area := l_left_chunks [2]

			render_traceroute_hops (a_frame, l_hops_area)
			render_traceroute_ping (a_frame, l_ping_area)
			render_australia_map (a_frame, l_map_area)
		end

	render_traceroute_hops (a_frame: FRAME; a_area: RECT)
			-- Render hops table with selection and scrollbar.
		local
			l_block: TUI_BLOCK
			l_table: TUI_TABLE
			l_header: TABLE_ROW
			l_rows: ARRAYED_LIST [TABLE_ROW]
			l_row: TABLE_ROW
			l_sb: TUI_SCROLLBAR
			l_sb_state: SCROLLBAR_STATE
			i: INTEGER
			l_sel_style: STYLE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_blue)).
				with_title (" Traceroute bad.horse ")

			create l_header.make_raw (<<"Host", "Address">>)
			l_header := l_header.with_style ((create {STYLE}.make_fg ({COLOR}.Bright_cyan)).with_bold.with_underline)

			create l_rows.make (hop_hosts.count)
			from i := 1 until i > hop_hosts.count loop
				create l_row.make_raw (<<hop_hosts [i], hop_addresses [i]>>)
				if i = traceroute_row_index then
					l_row := l_row.with_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)).with_bold)
				else
					l_row := l_row.with_style (create {STYLE}.make_fg ({COLOR}.Gray))
				end
				l_rows.extend (l_row)
				i := i + 1
			end

			create l_sel_style.make_with_colors ({COLOR}.Black, {COLOR}.Bright_yellow)

			create l_table.make (
				l_rows,
				<<
					{CONSTRAINTS}.flex (1),
					{CONSTRAINTS}.fixed (16)
				>>
			)
			l_table := l_table.with_block (l_block).with_header (l_header).with_row_highlight_style (l_sel_style)
			a_frame.render_stateful_widget (l_table, a_area, traceroute_table_state)

			-- Vertical Scrollbar
			create l_sb_state.make (hop_hosts.count)
			l_sb_state.set_position (traceroute_row_index)
			create l_sb.make ({SCROLLBAR_ORIENTATION}.vertical_left)
			l_sb := l_sb.with_thumb_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			a_frame.render_stateful_widget (l_sb, a_area, l_sb_state)
		end

	render_traceroute_ping (a_frame: FRAME; a_area: RECT)
			-- Latency sparkline.
		local
			l_block: TUI_BLOCK
			l_sparkline: TUI_SPARKLINE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Ping Latency Telemetry ")

			create l_sparkline.make_with_data (ping_telemetry)
			l_sparkline := l_sparkline.with_block (l_block).
				with_bar_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			a_frame.render_widget (l_sparkline, a_area)
		end

	render_australia_map (a_frame: FRAME; a_area: RECT)
			-- Australia Canvas map plotting nodes and routing path.
		local
			l_block: TUI_BLOCK
			l_canvas: TUI_CANVAS
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Australia Network Topology ")

			create l_canvas.make
			l_canvas := l_canvas.with_block (l_block).
				with_bounds (112.0, 155.0, -46.0, -11.0).
				with_marker ({CANVAS_MARKER}.braille).
				with_painter (agent paint_australia_hops)
			a_frame.render_widget (l_canvas, a_area)
		end

	paint_australia_hops (p: CANVAS_PAINTER)
			-- Draw Australian continent silhouette and active traceroute route.
		local
			curr_coords, next_coords: TUPLE [lon, lat: REAL_64]
			i: INTEGER
		do
			-- Stylized Australian Coastline
			p.set_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))
			-- West coast
			p.draw_line (114.0, -22.0, 115.0, -34.0)
			p.draw_line (115.0, -34.0, 120.0, -35.0)
			-- South coast
			p.draw_line (120.0, -35.0, 138.0, -35.0)
			p.draw_line (138.0, -35.0, 147.0, -38.0)
			-- East coast
			p.draw_line (147.0, -38.0, 153.0, -28.0)
			p.draw_line (153.0, -28.0, 145.0, -15.0)
			-- North coast / Gulf of Carpentaria
			p.draw_line (145.0, -15.0, 136.0, -12.0)
			p.draw_line (136.0, -12.0, 130.0, -12.0)
			p.draw_line (130.0, -12.0, 122.0, -17.0)
			p.draw_line (122.0, -17.0, 114.0, -22.0)

			-- Tasmania
			p.draw_circle (146.5, -42.0, 2.0)

			-- All Hop nodes (dim cyan)
			p.set_style (create {STYLE}.make_fg ({COLOR}.Cyan))
			from i := 1 until i > hop_coords.count loop
				p.draw_circle (hop_coords [i].lon, hop_coords [i].lat, 1.2)
				i := i + 1
			end

			-- Active Hop line connecting to next hop
			curr_coords := hop_coords [traceroute_row_index]
			if traceroute_row_index < hop_coords.count then
				next_coords := hop_coords [traceroute_row_index + 1]
			else
				next_coords := hop_coords [1]
			end

			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow))
			p.draw_line (curr_coords.lon, curr_coords.lat, next_coords.lon, next_coords.lat)

			-- Source node (Green)
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_green))
			p.draw_circle (curr_coords.lon, curr_coords.lat, 2.5)
			p.draw_text (curr_coords.lon + 1.5, curr_coords.lat, hop_hosts [traceroute_row_index], create {STYLE}.make_fg ({COLOR}.Bright_green))

			-- Destination node (Red)
			p.set_style (create {STYLE}.make_fg ({COLOR}.Bright_red))
			p.draw_circle (next_coords.lon, next_coords.lat, 2.5)
		end

feature {NONE} -- Tab 5: Weather Tab

	render_weather_tab (a_frame: FRAME; a_area: RECT)
			-- Render Tab 5: Calendar, Weekly BarChart, Seasonal BarChart, and LineGauge.
		local
			l_card_area: RECT
			l_layout: LAYOUT
			l_chunks: ARRAY [RECT]
			l_main_area, l_gauge_area: RECT
			l_main_layout: LAYOUT
			l_main_chunks: ARRAY [RECT]
			l_cal_area, l_charts_area: RECT
		do
			l_card_area := a_area.inner (2, 1)
			a_frame.render_widget (create {TUI_CLEAR}, l_card_area)

			create l_layout.make_vertical (<<
				{CONSTRAINTS}.flex (1),
				{CONSTRAINTS}.fixed (3)
			>>)
			l_chunks := l_layout.split (l_card_area)
			l_main_area := l_chunks [1]
			l_gauge_area := l_chunks [2]

			-- Main: Calendar on left (28 cols), Charts on right
			create l_main_layout.make_horizontal (<<
				{CONSTRAINTS}.fixed (28),
				{CONSTRAINTS}.flex (1)
			>>)
			l_main_chunks := l_main_layout.split (l_main_area)
			l_cal_area := l_main_chunks [1]
			l_charts_area := l_main_chunks [2]

			render_weather_calendar (a_frame, l_cal_area)
			render_weather_charts (a_frame, l_charts_area)
			render_weather_gauge (a_frame, l_gauge_area)
		end

	render_weather_calendar (a_frame: FRAME; a_area: RECT)
			-- Monthly calendar.
		local
			l_block: TUI_BLOCK
			l_cal: TUI_CALENDAR
			l_hdr_style, l_sel_style: STYLE
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_cyan)).
				with_title (" Calendar ")

			create l_hdr_style.make_with_colors ({COLOR}.Bright_yellow, create {COLOR}.make_rgb (16, 24, 48))
			l_hdr_style := l_hdr_style.with_bold

			create l_sel_style.make_with_colors ({COLOR}.Bright_white, {COLOR}.Red)
			l_sel_style := l_sel_style.with_bold

			create l_cal.make
			l_cal := l_cal.with_block (l_block).
				with_header_style (l_hdr_style).
				with_selected_style (l_sel_style).
				with_show_month_header (True).
				with_show_weekday_header (True)

			a_frame.render_stateful_widget (l_cal, a_area, calendar_state)
		end

	render_weather_charts (a_frame: FRAME; a_area: RECT)
			-- Weekly vertical bar chart + Seasonal horizontal bar chart.
		local
			l_v_layout: LAYOUT
			l_v_chunks: ARRAY [RECT]
			l_weekly_area, l_seasonal_area: RECT
			l_weekly_items, l_seasonal_items: ARRAYED_LIST [BAR_ITEM]
			l_block1, l_block2: TUI_BLOCK
			l_chart1, l_chart2: TUI_BARCHART
		do
			create l_v_layout.make_vertical (<<
				{CONSTRAINTS}.ratio (1, 2),
				{CONSTRAINTS}.ratio (1, 2)
			>>)
			l_v_chunks := l_v_layout.split (a_area)
			l_weekly_area := l_v_chunks [1]
			l_seasonal_area := l_v_chunks [2]

			-- 1. Weekly BarChart: Sat 76, Sun 69, Mon 65, Tue 67, Wed 65, Thu 69, Fri 73
			create l_weekly_items.make (7)
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Sat", 76, "76" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Sun", 69, "69" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Mon", 65, "65" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Tue", 67, "67" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Wed", 65, "65" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Thu", 69, "69" + (176).to_character_32.out))
			l_weekly_items.extend (create {BAR_ITEM}.make_with_text ("Fri", 73, "73" + (176).to_character_32.out))

			create l_block1.make
			l_block1 := l_block1.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_title (" Weekly Forecast [Fahrenheit] ")

			create l_chart1.make_with_data (l_weekly_items)
			l_chart1 := l_chart1.with_block (l_block1).
				with_bar_width (4).
				with_bar_gap (2).
				with_bar_style (create {STYLE}.make_fg ({COLOR}.Bright_green)).
				with_value_style ((create {STYLE}.make_with_colors ({COLOR}.Black, {COLOR}.Bright_green)).with_bold)
			a_frame.render_widget (l_chart1, l_weekly_area)

			-- 2. Seasonal Horizontal BarChart: Winter 51, Spring 65, Summer 77, Fall 71
			create l_seasonal_items.make (4)
			l_seasonal_items.extend (create {BAR_ITEM}.make_with_text ("Winter", 51, "Winter 37-51"))
			l_seasonal_items.extend (create {BAR_ITEM}.make_with_text ("Spring", 65, "Spring 40-65"))
			l_seasonal_items.extend (create {BAR_ITEM}.make_with_text ("Summer", 77, "Summer 54-77"))
			l_seasonal_items.extend (create {BAR_ITEM}.make_with_text ("Fall", 71, "Fall 41-71"))

			create l_block2.make
			l_block2 := l_block2.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_yellow)).
				with_title (" Seasonal Climate Range ")

			create l_chart2.make_with_data (l_seasonal_items)
			l_chart2 := l_chart2.with_block (l_block2).
				with_direction ({BAR_CHART_DIRECTION}.horizontal).
				with_bar_gap (1).
				with_bar_style (create {STYLE}.make_fg (create {COLOR}.make_rgb (32, 48, 96))).
				with_value_style ((create {STYLE}.make_fg ({COLOR}.Bright_yellow)).with_bold)
			a_frame.render_widget (l_chart2, l_seasonal_area)
		end

	render_weather_gauge (a_frame: FRAME; a_area: RECT)
			-- Download progress line gauge with dynamic hue shifting.
		local
			l_block: TUI_BLOCK
			l_line_gauge: TUI_LINE_GAUGE
			l_hue: REAL_64
			l_fill_col: COLOR
			l_label: STRING_32
		do
			create l_block.make
			l_block := l_block.with_borders ({BORDERS}.all_borders).
				with_border_type ({BORDER_TYPE}.rounded).
				with_border_style (create {STYLE}.make_fg ({COLOR}.Bright_magenta)).
				with_title (" Telemetry Satellite Sync ")

			l_hue := (90.0 - (download_progress.to_double * 0.7)).max (0.0)
			l_fill_col := hsv_to_color (l_hue, 1.0, 1.0)

			create l_label.make (32)
			if download_progress < 100 then
				l_label.append_string_general ("Syncing: ")
				l_label.append_integer (download_progress)
				l_label.append_character ('%%')
			else
				l_label.append_string_general ("Telemetry Sync Complete!")
			end

			create l_line_gauge.make
			l_line_gauge := l_line_gauge.with_block (l_block).
				with_ratio (download_progress.to_double / 100.0).
				with_label (l_label).
				with_filled_style (create {STYLE}.make_fg (l_fill_col)).
				with_unfilled_style (create {STYLE}.make_fg ({COLOR}.Dark_gray))

			a_frame.render_widget (l_line_gauge, a_area)
		end

feature {NONE} -- Destroy Mode Particle Physics & Logo Reveal

	apply_destroy_physics (a_frame: FRAME)
			-- Melting sand drip pixel physics across screen and fading logo.
		local
			buf: BUFFER
			area: RECT
			x, y, dest_y, dest_x: INTEGER
			src_cell: TERMINAL_CELL
			i, pixel_count: INTEGER
		do
			buf := a_frame.buffer
			area := a_frame.area

			-- Move random pixels down one row
			pixel_count := (area.width.to_integer_32 * area.height.to_integer_32 // 4).min (2000)

			from i := 1 until i > pixel_count loop
				x := area.x.to_integer_32 + next_random_val (area.width.to_integer_32 - 1)
				y := area.y.to_integer_32 + 1 + next_random_val (area.height.to_integer_32 - 3)

				if buf.is_valid_position (y, x) then
					src_cell := buf.cell (y, x)
					if next_random_val (100) < 5 then
						-- Clear cell 5% of the time to dissolve
						dest_x := (x + next_random_val (4) - 2).max (area.x.to_integer_32).min (area.right.to_integer_32 - 1)
						dest_y := area.y.to_integer_32 + 1
						buf.put_char (dest_y, dest_x, ' ', create {STYLE}.default_create)
					else
						-- Move down
						dest_y := (y + 1).min (area.bottom.to_integer_32 - 2)
						buf.put_string (dest_y, x, src_cell.symbol, src_cell.style)
					end
				end
				i := i + 1
			end

			-- Fading overlay banner
			render_destroy_logo (a_frame, area)
		end

	render_destroy_logo (a_frame: FRAME; a_area: RECT)
			-- Draw large centered logo fading into bright red.
		local
			l_box_w, l_box_h: INTEGER
			l_start_x, l_start_y: INTEGER
			l_logo_lines: ARRAY [STRING_32]
			l_intensity: NATURAL_8
			l_style: STYLE
			i: INTEGER
		do
			l_box_w := 48
			l_box_h := 7
			l_start_x := (a_area.x.to_integer_32 + (a_area.width.to_integer_32 - l_box_w) // 2).max (0)
			l_start_y := (a_area.y.to_integer_32 + (a_area.height.to_integer_32 - l_box_h) // 2).max (0)

			l_intensity := ((destroy_frame * 6).min (255)).to_natural_8
			create l_style.make_with_colors (
				create {COLOR}.make_rgb (255, (l_intensity // 3), (l_intensity // 4)),
				create {COLOR}.make_rgb (10, 0, 0)
			)
			l_style := l_style.with_bold

			l_logo_lines := <<
				"################################################",
				"#  EEEEE  I  FFFFF  FFFFF  EEEEE  L      TUI   #",
				"#  E      I  F      F      E      L       |    #",
				"#  EEEE   I  FFFF   FFFF   EEEE   L      Rat   #",
				"#  E      I  F      F      E      L            #",
				"#  EEEEE  I  F      F      EEEEE  LLLLL        #",
				"################################################"
			>>

			from i := 1 until i > l_logo_lines.count loop
				if a_frame.buffer.is_valid_position (l_start_y + i - 1, l_start_x) then
					a_frame.buffer.put_string (l_start_y + i - 1, l_start_x, l_logo_lines [i], l_style)
				end
				i := i + 1
			end
		end

feature {NONE} -- Helpers

	next_random_val (a_max: INTEGER): INTEGER
			-- Next pseudo-random integer in 0..a_max.
		do
			seed := ((seed * 1103515245 + 12345) & 0x7FFFFFFF)
			Result := ((seed \\ (a_max + 1).to_integer_64)).to_integer_32.abs
		end

end

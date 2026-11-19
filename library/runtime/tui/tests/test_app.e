note
	description: "[
		Robust test suite runner executing all EiffelTUI test sets.
		Catches failures per test, prints clear [PASS] / [FAIL] status with exception reasons,
		continues running all remaining tests on failure, and exits non-zero if any test fails.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

inherit
	ANY

create
	make

feature {NONE} -- Initialization

	make
			-- Run all test suites with per-test failure isolation and summary reporting.
		local
			l_t1: TEST_TERMINAL_BACKEND
			l_t2: TEST_BUFFER_AND_DIFF
			l_t3: TEST_LAYOUT_SOLVER
			l_t4: TEST_EVENTS_AND_PARSER
			l_t5: TEST_TEXT_AND_WIDGETS
			l_t6: TEST_STATEFUL_WIDGETS
			l_t7: TEST_TABLE_WIDGET
			l_t8: TEST_SCROLLBAR
			l_t9: TEST_METRIC_WIDGETS
			l_t10: TEST_CANVAS
			l_t11: TEST_LAYOUT_AND_BORDERS
			l_t12: TEST_VIEWPORT_AND_POSIX
			l_t13: TEST_EDGE_CASES
			l_t14: TEST_MILESTONE_C
			l_t15: TEST_MILESTONE_D
			l_t16: TEST_MILESTONE_D_REVIEW
			l_t17: TEST_MILESTONE_E
			l_t18: TEST_MILESTONE_E_REVIEW
			l_t19: TEST_MILESTONE_E_FOLLOWUPS
			l_t20: TEST_MILESTONE_F
			l_t21: TEST_WIDGET_SMOKE
			l_t22: TEST_MILESTONE_F_REVIEW
			l_t23: TEST_MILESTONE_F_GAPS
			l_t24: TEST_MILESTONE_G
			l_t25: TEST_MILESTONE_G_REVIEW
			l_t26: TEST_MILESTONE_G_FOLLOWUPS
			l_t27: TEST_KEYBOARD_ENHANCEMENT
			l_t28: TEST_TIER1_EXAMPLES
			l_t29: TEST_TIER2_EXAMPLES
			l_t30: TEST_PASTE_ROBUSTNESS
			l_t31: TEST_UNICODE_WRAP
			l_t32: TEST_CONSOLE_INPUT_CLAIM
			l_t33: TEST_UNICODE_SCALAR
			l_t34: TEST_UTF_8_INPUT
			l_t35: TEST_SERIALIZER_REANCHOR
			l_t36: TEST_TEXT_INPUT_EDGES
			l_t37: TEST_FRAME_OUTPUT
			l_t38: TEST_FAILURE_RECOVERY
			l_t39: TEST_UTF_8_OUT
			l_t40: TEST_UNICODE_GAPS
			l_t41: TEST_DIFF_POOL
			l_t42: TEST_SHARED_OBJECTS
			l_t43: TEST_EVENT_FLOOD
			l_t44: TEST_MILESTONE_H
			l_t45: TEST_TEXT_AREA
			l_t46: TEST_SUSPEND_RESUME
			l_t47: TEST_INTERACTION
			l_t48: TEST_BLOCK_SHADOW
			l_t49: TEST_FILL
			l_t50: TEST_SPARKLINE
			l_t51: TEST_TABLE_SCROLLING
			l_t52: TEST_TEXT_ALIGNMENT_BUILDERS
			l_t53: TEST_GAUGE_RATATUI
			l_t54: TEST_DIFF_CHECKS
			l_t55: TEST_CHART_CHECKS
			l_t56: TEST_WIDGET_EDGE_CHECKS
			l_t57: TEST_THEME
			l_t58: TEST_COLOR_FROM_STRING
			l_t59: TEST_CURSOR_SHAPE
			l_t60: TEST_WINDOW_TITLE
			l_t61: TEST_CLIPBOARD
			l_t62: TEST_KEYBOARD_QUERY
			l_t63: TEST_DIVIDER
			l_t64: TEST_CHECKBOX
			l_t65: TEST_SLIDER
			l_t66: TEST_FORM_CONTROLS_EXAMPLE
			l_t67: TEST_MENU
			l_t68: TEST_TOAST
			l_t69: TEST_MOUSE_MOTION
			l_t70: TEST_TOOLTIP
			l_t71: TEST_TOML_SUBSET
			l_t72: TEST_STYLE_TEXT
			l_t73: TEST_THEME_FILE
			l_t74: TEST_ASYNC_WORKER
			l_t75: TEST_ASYNC_SCAN
			l_t76: TEST_BUTTON
			l_t77: TEST_DIALOG
			l_t78: TEST_BREADCRUMB
			l_t79: TEST_FILE_TREE_EXAMPLE
			l_t80: TEST_CLIPBOARD_READ
			l_t81: TEST_CLIPBOARD_EXAMPLES
			l_platform: TEST_PLATFORM_DRIVER
		do
			total_count := 0
			pass_count := 0
			fail_count := 0

			if not library_preconditions_checked then
				print ("============================================================%N")
				print ("  SUITE NOT RUN: assertions are off in this build.%N")
				print ("  Many tests expect a contract to refuse bad input, so they%N")
				print ("  would fail here without any defect in the code.%N")
				print ("  Build with one of these, then run the executable again:%N")
				print ("    ec -batch -config eiffeltui.ecf -target eiffeltui_tests -c_compile%N")
				print ("    ec -batch -config eiffeltui.ecf -target eiffeltui_tests -finalize -keep -c_compile%N")
				print ("============================================================%N")
				(create {EXCEPTIONS}).die (2)
			end

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 1 Test Suite (Terminal Backend)...%N")
			print ("============================================================%N")
			create l_t1
			run_test ("test_virtual_terminal_initialization", agent l_t1.test_virtual_terminal_initialization)
			run_test ("test_cursor_movement", agent l_t1.test_cursor_movement)
			run_test ("test_put_string_and_cell_inspection", agent l_t1.test_put_string_and_cell_inspection)
			run_test ("test_clear_screen", agent l_t1.test_clear_screen)
			run_test ("test_screen_modes", agent l_t1.test_screen_modes)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 2 Test Suite (Buffer & Diff)...%N")
			print ("============================================================%N")
			create l_t2
			run_test ("test_color_and_styles", agent l_t2.test_color_and_styles)
			run_test ("test_unicode_and_wide_glyphs", agent l_t2.test_unicode_and_wide_glyphs)
			run_test ("test_buffer_wide_character_placement", agent l_t2.test_buffer_wide_character_placement)
			run_test ("test_diff_engine_dirty_detection", agent l_t2.test_diff_engine_dirty_detection)
			run_test ("test_diff_engine_gap_merging", agent l_t2.test_diff_engine_gap_merging)
			run_test ("test_ansi_serializer_with_virtual_terminal", agent l_t2.test_ansi_serializer_with_virtual_terminal)
			run_test ("test_ratatui_skip_cells_are_skipped", agent l_t2.test_ratatui_skip_cells_are_skipped)
			run_test ("test_ratatui_always_update_cells_are_emitted_even_when_identical", agent l_t2.test_ratatui_always_update_cells_are_emitted_even_when_identical)
			run_test ("test_ratatui_forced_width_skips_trailing", agent l_t2.test_ratatui_forced_width_skips_trailing)
			run_test ("test_ratatui_forced_width_replaces_skip", agent l_t2.test_ratatui_forced_width_replaces_skip)
			run_test ("test_ratatui_diff_skip", agent l_t2.test_ratatui_diff_skip)
			run_test ("test_ratatui_merge_diff_forcedwidth", agent l_t2.test_ratatui_merge_diff_forcedwidth)
			run_test ("test_ratatui_merge_diff_link", agent l_t2.test_ratatui_merge_diff_link)
			run_test ("test_ratatui_merge_diff_split_link", agent l_t2.test_ratatui_merge_diff_split_link)
			run_test ("test_ratatui_merge_diff_image_sequences", agent l_t2.test_ratatui_merge_diff_image_sequences)
			run_test ("test_ratatui_merge_skip", agent l_t2.test_ratatui_merge_skip)
			run_test ("test_skip_splits_merged_span", agent l_t2.test_skip_splits_merged_span)
			run_test ("test_forced_width_cover_splits_span", agent l_t2.test_forced_width_cover_splits_span)
			run_test ("test_forced_width_stops_at_row_end", agent l_t2.test_forced_width_stops_at_row_end)
			run_test ("test_option_change_is_dirty", agent l_t2.test_option_change_is_dirty)
			run_test ("test_previous_cover_is_redrawn", agent l_t2.test_previous_cover_is_redrawn)
			run_test ("test_options_in_grown_area", agent l_t2.test_options_in_grown_area)
			run_test ("test_writes_clear_diff_option", agent l_t2.test_writes_clear_diff_option)
			run_test ("test_style_changes_keep_diff_option", agent l_t2.test_style_changes_keep_diff_option)
			run_test ("test_cell_equality_with_diff_option", agent l_t2.test_cell_equality_with_diff_option)
			run_test ("test_set_diff_option_preconditions", agent l_t2.test_set_diff_option_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 3 Test Suite (Layout Solver)...%N")
			print ("============================================================%N")
			create l_t3
			run_test ("test_rect_geometry", agent l_t3.test_rect_geometry)
			run_test ("test_split_vertical_fixed_and_flex", agent l_t3.test_split_vertical_fixed_and_flex)
			run_test ("test_split_horizontal_ratios", agent l_t3.test_split_horizontal_ratios)
			run_test ("test_split_horizontal_percentage", agent l_t3.test_split_horizontal_percentage)
			run_test ("test_flex_remainder_distribution", agent l_t3.test_flex_remainder_distribution)
			run_test ("test_split_with_margin", agent l_t3.test_split_with_margin)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 4 Test Suite (Events & Parser)...%N")
			print ("============================================================%N")
			create l_t4
			run_test ("test_modifiers", agent l_t4.test_modifiers)
			run_test ("test_key_code_definitions", agent l_t4.test_key_code_definitions)
			run_test ("test_parser_ground_characters", agent l_t4.test_parser_ground_characters)
			run_test ("test_parser_csi_arrow_keys", agent l_t4.test_parser_csi_arrow_keys)
			run_test ("test_parser_csi_modifiers", agent l_t4.test_parser_csi_modifiers)
			run_test ("test_parser_sgr_mouse", agent l_t4.test_parser_sgr_mouse)
			run_test ("test_synchronized_queue", agent l_t4.test_synchronized_queue)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 5 Test Suite (Text & Widgets)...%N")
			print ("============================================================%N")
			create l_t5
			run_test ("test_text_span_and_unicode_width", agent l_t5.test_text_span_and_unicode_width)
			run_test ("test_text_line_and_composition", agent l_t5.test_text_line_and_composition)
			run_test ("test_text_wrapping", agent l_t5.test_text_wrapping)
			run_test ("test_text_alignment", agent l_t5.test_text_alignment)
			run_test ("test_tui_block_geometry_and_rendering", agent l_t5.test_tui_block_geometry_and_rendering)
			run_test ("test_tui_paragraph_rendering", agent l_t5.test_tui_paragraph_rendering)
			run_test ("test_tui_clear", agent l_t5.test_tui_clear)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 6 Test Suite (Stateful & Terminal)...%N")
			print ("============================================================%N")
			create l_t6
			run_test ("test_terminal_and_frame_agent_draw", agent l_t6.test_terminal_and_frame_agent_draw)
			run_test ("test_list_state_navigation", agent l_t6.test_list_state_navigation)
			run_test ("test_list_viewport_scrolling", agent l_t6.test_list_viewport_scrolling)
			run_test ("test_tui_list_stateful_rendering", agent l_t6.test_tui_list_stateful_rendering)
			run_test ("test_tabs_state_and_rendering", agent l_t6.test_tabs_state_and_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 7 Test Suite (Table Widget)...%N")
			print ("============================================================%N")
			create l_t7
			run_test ("test_table_cell_and_row_construction", agent l_t7.test_table_cell_and_row_construction)
			run_test ("test_table_state_navigation", agent l_t7.test_table_state_navigation)
			run_test ("test_tui_table_rendering_stateless", agent l_t7.test_tui_table_rendering_stateless)
			run_test ("test_tui_table_stateful_selection_and_highlight", agent l_t7.test_tui_table_stateful_selection_and_highlight)
			run_test ("test_tui_table_column_spanning", agent l_t7.test_tui_table_column_spanning)
			run_test ("test_tui_table_with_block_and_footer", agent l_t7.test_tui_table_with_block_and_footer)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 8 Test Suite (Scrollbar Widget)...%N")
			print ("============================================================%N")
			create l_t8
			run_test ("test_scrollbar_orientation_constants", agent l_t8.test_scrollbar_orientation_constants)
			run_test ("test_scrollbar_state_navigation", agent l_t8.test_scrollbar_state_navigation)
			run_test ("test_tui_scrollbar_vertical_rendering", agent l_t8.test_tui_scrollbar_vertical_rendering)
			run_test ("test_tui_scrollbar_horizontal_rendering", agent l_t8.test_tui_scrollbar_horizontal_rendering)
			run_test ("test_tui_scrollbar_pairing_with_list", agent l_t8.test_tui_scrollbar_pairing_with_list)
			run_test ("test_scrollbar_valid_symbols", agent l_t8.test_scrollbar_valid_symbols)
			run_test ("test_scrollbar_setters_refuse_wide_symbols", agent l_t8.test_scrollbar_setters_refuse_wide_symbols)
			run_test ("test_scrollbar_invariant_catches_edited_symbol", agent l_t8.test_scrollbar_invariant_catches_edited_symbol)
			run_test ("test_scrollbar_stays_in_its_column", agent l_t8.test_scrollbar_stays_in_its_column)
			run_test ("test_horizontal_scrollbar_symbols_do_not_blank_each_other", agent l_t8.test_horizontal_scrollbar_symbols_do_not_blank_each_other)
			run_test ("test_large_thumb_stays_in_track_at_end", agent l_t8.test_large_thumb_stays_in_track_at_end)
			run_test ("test_render_scrollbar_keeps_end_symbol_for_large_thumb", agent l_t8.test_render_scrollbar_keeps_end_symbol_for_large_thumb)
			run_test ("test_thumb_stays_within_track_for_large_thumb_at_end", agent l_t8.test_thumb_stays_within_track_for_large_thumb_at_end)
			run_test ("test_render_scrollbar_simple", agent l_t8.test_render_scrollbar_simple)
			run_test ("test_render_scrollbar_with_symbols", agent l_t8.test_render_scrollbar_with_symbols)
			run_test ("test_custom_viewport_length", agent l_t8.test_custom_viewport_length)
			run_test ("test_thumb_visible_on_very_small_track", agent l_t8.test_thumb_visible_on_very_small_track)
			run_test ("test_thumb_length_constant_while_scrolling", agent l_t8.test_thumb_length_constant_while_scrolling)
			run_test ("test_thumb_math_does_not_overflow_for_long_content", agent l_t8.test_thumb_math_does_not_overflow_for_long_content)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 9 Test Suite (Metric Widgets)...%N")
			print ("============================================================%N")
			create l_t9
			run_test ("test_gauge_rendering_and_label", agent l_t9.test_gauge_rendering_and_label)
			run_test ("test_gauge_label_wide_char_across_fill_edge", agent l_t9.test_gauge_label_wide_char_across_fill_edge)
			run_test ("test_gauge_label_wide_char_after_fill_edge", agent l_t9.test_gauge_label_wide_char_after_fill_edge)
			run_test ("test_one_column_symbols", agent l_t9.test_one_column_symbols)
			run_test ("test_line_gauge_refuses_wide_symbols", agent l_t9.test_line_gauge_refuses_wide_symbols)
			run_test ("test_line_gauge_invariant_catches_edited_symbol", agent l_t9.test_line_gauge_invariant_catches_edited_symbol)
			run_test ("test_line_gauge_multi_code_point_symbol_in_every_cell", agent l_t9.test_line_gauge_multi_code_point_symbol_in_every_cell)
			run_test ("test_gauge_unicode_sub_cell", agent l_t9.test_gauge_unicode_sub_cell)
			run_test ("test_line_gauge_rendering", agent l_t9.test_line_gauge_rendering)
			run_test ("test_sparkline_rendering", agent l_t9.test_sparkline_rendering)
			run_test ("test_barchart_rendering", agent l_t9.test_barchart_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 10 Test Suite (Canvas & Chart)...%N")
			print ("============================================================%N")
			create l_t10
			run_test ("test_braille_canvas_subpixels", agent l_t10.test_braille_canvas_subpixels)
			run_test ("test_canvas_painter_bresenham_line", agent l_t10.test_canvas_painter_bresenham_line)
			run_test ("test_canvas_painter_circle_and_rect", agent l_t10.test_canvas_painter_circle_and_rect)
			run_test ("test_tui_canvas_rendering_with_agent", agent l_t10.test_tui_canvas_rendering_with_agent)
			run_test ("test_tui_chart_rendering", agent l_t10.test_tui_chart_rendering)
			run_test ("test_text_cell_dot_marker", agent l_t10.test_text_cell_dot_marker)
			run_test ("test_text_cell_half_block_marker", agent l_t10.test_text_cell_half_block_marker)
			run_test ("test_text_cell_braille_marker", agent l_t10.test_text_cell_braille_marker)
			run_test ("test_point_non_finite_or_outside_draws_nothing", agent l_t10.test_point_non_finite_or_outside_draws_nothing)
			run_test ("test_line_non_finite_draws_nothing", agent l_t10.test_line_non_finite_draws_nothing)
			run_test ("test_line_partly_outside_matches_unclipped_walk", agent l_t10.test_line_partly_outside_matches_unclipped_walk)
			run_test ("test_shapes_non_finite_draw_nothing", agent l_t10.test_shapes_non_finite_draw_nothing)
			run_test ("test_line_far_end_is_clipped", agent l_t10.test_line_far_end_is_clipped)
			run_test ("test_ratatui_horizontal_with_vertical_pattern_markers", agent l_t10.test_ratatui_horizontal_with_vertical_pattern_markers)
			run_test ("test_ratatui_diagonal_lines_pattern_markers", agent l_t10.test_ratatui_diagonal_lines_pattern_markers)
			run_test ("test_pattern_grid_one_cell_per_bit", agent l_t10.test_pattern_grid_one_cell_per_bit)
			run_test ("test_pixel_tables_are_one_column_wide", agent l_t10.test_pixel_tables_are_one_column_wide)
			run_test ("test_marker_resolution", agent l_t10.test_marker_resolution)
			run_test ("test_braille_layer_over_octant_base", agent l_t10.test_braille_layer_over_octant_base)
			run_test ("test_chart_dataset_pattern_markers", agent l_t10.test_chart_dataset_pattern_markers)
			run_test ("test_ratatui_horizontal_with_vertical_custom_markers", agent l_t10.test_ratatui_horizontal_with_vertical_custom_markers)
			run_test ("test_ratatui_diagonal_lines_custom_markers", agent l_t10.test_ratatui_diagonal_lines_custom_markers)
			run_test ("test_ratatui_horizontal_with_vertical_cell_markers", agent l_t10.test_ratatui_horizontal_with_vertical_cell_markers)
			run_test ("test_ratatui_diagonal_lines_cell_markers", agent l_t10.test_ratatui_diagonal_lines_cell_markers)
			run_test ("test_marker_symbols_match_ratatui", agent l_t10.test_marker_symbols_match_ratatui)
			run_test ("test_ratatui_rectangle_block_lines", agent l_t10.test_ratatui_rectangle_block_lines)
			run_test ("test_ratatui_rectangle_half_block_lines", agent l_t10.test_ratatui_rectangle_half_block_lines)
			run_test ("test_ratatui_rectangle_braille_lines", agent l_t10.test_ratatui_rectangle_braille_lines)
			run_test ("test_ratatui_rectangle_custom_lines", agent l_t10.test_ratatui_rectangle_custom_lines)
			run_test ("test_ratatui_chart_overlapping_lines", agent l_t10.test_ratatui_chart_overlapping_lines)
			run_test ("test_half_block_cell_colours", agent l_t10.test_half_block_cell_colours)
			run_test ("test_layer_cell_sets_only_its_fields", agent l_t10.test_layer_cell_sets_only_its_fields)
			run_test ("test_custom_marker_layers_use_their_own_char", agent l_t10.test_custom_marker_layers_use_their_own_char)
			run_test ("test_chart_dataset_custom_marker", agent l_t10.test_chart_dataset_custom_marker)
			run_test ("test_custom_marker_builders_and_defaults", agent l_t10.test_custom_marker_builders_and_defaults)
			run_test ("test_custom_marker_refuses_wide_char", agent l_t10.test_custom_marker_refuses_wide_char)
			run_test ("test_dataset_custom_marker_after_blank_symbol_marker", agent l_t10.test_dataset_custom_marker_after_blank_symbol_marker)
			run_test ("test_ratatui_line_cases_dot_marker", agent l_t10.test_ratatui_line_cases_dot_marker)
			run_test ("test_line_dots_do_not_depend_on_end_order", agent l_t10.test_line_dots_do_not_depend_on_end_order)
			run_test ("test_point_on_bound_with_rounding_error_is_drawn", agent l_t10.test_point_on_bound_with_rounding_error_is_drawn)
			run_test ("test_line_through_corner_is_clipped", agent l_t10.test_line_through_corner_is_clipped)
			run_test ("test_snapshot_failure_message_is_readable", agent l_t10.test_snapshot_failure_message_is_readable)
			run_test ("test_ratatui_filled_line_cases_dot_marker", agent l_t10.test_ratatui_filled_line_cases_dot_marker)
			run_test ("test_ratatui_chart_filled_line", agent l_t10.test_ratatui_chart_filled_line)
			run_test ("test_chart_area_fill_to_y", agent l_t10.test_chart_area_fill_to_y)
			run_test ("test_chart_single_point_dataset_is_drawn", agent l_t10.test_chart_single_point_dataset_is_drawn)
			run_test ("test_chart_dataset_fill_to_y_builders", agent l_t10.test_chart_dataset_fill_to_y_builders)
			run_test ("test_shape_filled_line", agent l_t10.test_shape_filled_line)
			run_test ("test_filled_line_non_finite_and_far_end", agent l_t10.test_filled_line_non_finite_and_far_end)
			run_test ("test_ratatui_area_cases_dot_marker", agent l_t10.test_ratatui_area_cases_dot_marker)
			run_test ("test_clipped_polygon", agent l_t10.test_clipped_polygon)
			run_test ("test_polygon_non_finite_and_degenerate", agent l_t10.test_polygon_non_finite_and_degenerate)
			run_test ("test_shape_area", agent l_t10.test_shape_area)
			run_test ("test_world_map_data_counts_and_ranges", agent l_t10.test_world_map_data_counts_and_ranges)
			run_test ("test_map_resolution_names_and_default", agent l_t10.test_map_resolution_names_and_default)
			run_test ("test_ratatui_map_draw_low", agent l_t10.test_ratatui_map_draw_low)
			run_test ("test_ratatui_map_draw_high", agent l_t10.test_ratatui_map_draw_high)
			run_test ("test_shape_map", agent l_t10.test_shape_map)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 11 Test Suite (Layout & Borders)...%N")
			print ("============================================================%N")
			create l_t11
			run_test ("test_layout_split_with_spacing", agent l_t11.test_layout_split_with_spacing)
			run_test ("test_layout_justification_end_and_center", agent l_t11.test_layout_justification_end_and_center)
			run_test ("test_layout_justification_space_between", agent l_t11.test_layout_justification_space_between)
			run_test ("test_border_collision_symbol_merging", agent l_t11.test_border_collision_symbol_merging)
			run_test ("test_buffer_border_fusion", agent l_t11.test_buffer_border_fusion)

			print ("============================================================%N")
			print ("  Running EiffelTUI Phase 12 Test Suite (Viewport & POSIX)...%N")
			print ("============================================================%N")
			create l_t12
			run_test ("test_viewport_modes", agent l_t12.test_viewport_modes)
			run_test ("test_fixed_viewport_resize", agent l_t12.test_fixed_viewport_resize)
			run_test ("test_frame_cursor_positioning", agent l_t12.test_frame_cursor_positioning)
			run_test ("test_terminal_with_inline_viewport_and_cursor", agent l_t12.test_terminal_with_inline_viewport_and_cursor)
			run_test ("test_platform_terminal_driver", agent l_t12.test_platform_terminal_driver)

			print ("============================================================%N")
			print ("  Running EiffelTUI Edge Cases Test Suite (Milestone B)...%N")
			print ("============================================================%N")
			create l_t13
			run_test ("test_zero_and_oversized_areas", agent l_t13.test_zero_and_oversized_areas)
			run_test ("test_wide_characters_in_widgets", agent l_t13.test_wide_characters_in_widgets)
			run_test ("test_wide_over_wide_overwrite", agent l_t13.test_wide_over_wide_overwrite)
			run_test ("test_combining_marks_and_emoji", agent l_t13.test_combining_marks_and_emoji)
			run_test ("test_rect_bounds_and_overflow", agent l_t13.test_rect_bounds_and_overflow)
			run_test ("test_overconstrained_and_min_max_layouts", agent l_t13.test_overconstrained_and_min_max_layouts)
			run_test ("test_malformed_and_partial_input", agent l_t13.test_malformed_and_partial_input)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone C Test Suite...%N")
			print ("============================================================%N")
			create l_t14
			run_test ("test_platform_console_driver", agent l_t14.test_platform_console_driver)
			run_test ("test_utf8_streaming_input", agent l_t14.test_utf8_streaming_input)
			run_test ("test_lone_escape_flush", agent l_t14.test_lone_escape_flush)
			run_test ("test_mouse_modifiers_and_horizontal_scroll", agent l_t14.test_mouse_modifiers_and_horizontal_scroll)
			run_test ("test_focus_events", agent l_t14.test_focus_events)
			run_test ("test_bracketed_paste_event", agent l_t14.test_bracketed_paste_event)
			run_test ("test_modified_function_keys", agent l_t14.test_modified_function_keys)
			run_test ("test_cursor_position_report", agent l_t14.test_cursor_position_report)
			run_test ("test_synchronized_queue_timeout", agent l_t14.test_synchronized_queue_timeout)
			run_test ("test_synchronized_queue_wake", agent l_t14.test_synchronized_queue_wake)
			run_test ("test_event_thread_with_fake_driver", agent l_t14.test_event_thread_with_fake_driver)
			run_test ("test_event_thread_failure_reported", agent l_t14.test_event_thread_failure_reported)
			run_test ("test_backend_restores_before_driver", agent l_t14.test_backend_restores_before_driver)
			run_test ("test_backend_reenables_vt_mode", agent l_t14.test_backend_reenables_vt_mode)
			run_test ("test_backend_cursor_position_query", agent l_t14.test_backend_cursor_position_query)
			run_test ("test_terminal_resize_on_draw", agent l_t14.test_terminal_resize_on_draw)
			run_test ("test_inline_viewport_setup_and_insert_before", agent l_t14.test_inline_viewport_setup_and_insert_before)
			run_test ("test_inline_viewport_moves_down_while_room", agent l_t14.test_inline_viewport_moves_down_while_room)
			run_test ("test_tui_application_run_and_restore", agent l_t14.test_tui_application_run_and_restore)
			run_test ("test_tui_application_exception_restores_terminal", agent l_t14.test_tui_application_exception_restores_terminal)
			run_test ("test_tui_application_ticks_under_steady_input", agent l_t14.test_tui_application_ticks_under_steady_input)
			run_test ("test_tui_application_runs_twice", agent l_t14.test_tui_application_runs_twice)
			run_test ("test_event_thread_renewed", agent l_t14.test_event_thread_renewed)
			run_test ("test_tui_application_input_thread_timeout", agent l_t14.test_tui_application_input_thread_timeout)
			run_test ("test_termination_request_ends_run_after_restore", agent l_t14.test_termination_request_ends_run_after_restore)
			run_test ("test_termination_request_wakes_slow_loop", agent l_t14.test_termination_request_wakes_slow_loop)
			run_test ("test_event_budget_redraws_during_flood", agent l_t14.test_event_budget_redraws_during_flood)
			run_test ("test_termination_request_outside_run_is_immediate", agent l_t14.test_termination_request_outside_run_is_immediate)
			run_test ("test_second_termination_request_is_immediate", agent l_t14.test_second_termination_request_is_immediate)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone D Test Suite...%N")
			print ("============================================================%N")
			create l_t15
			run_test ("test_style_modifiers_and_fluent_builders", agent l_t15.test_style_modifiers_and_fluent_builders)
			run_test ("test_unicode_width_uax11_and_graphemes", agent l_t15.test_unicode_width_uax11_and_graphemes)
			run_test ("test_buffer_wide_over_wide_repair", agent l_t15.test_buffer_wide_over_wide_repair)
			run_test ("test_buffer_api_extensions", agent l_t15.test_buffer_api_extensions)
			run_test ("test_rect_saturating_bounds_and_helpers", agent l_t15.test_rect_saturating_bounds_and_helpers)
			run_test ("test_synchronized_output_and_minimal_sgr", agent l_t15.test_synchronized_output_and_minimal_sgr)
			run_test ("test_backend_cursor_tracking_and_escapes", agent l_t15.test_backend_cursor_tracking_and_escapes)
			run_test ("test_allocation_reuse", agent l_t15.test_allocation_reuse)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone D Review Test Suite...%N")
			print ("============================================================%N")
			create l_t16
			run_test ("test_paragraph_horizontal_scroll_clips_per_grapheme", agent l_t16.test_paragraph_horizontal_scroll_clips_per_grapheme)
			run_test ("test_set_line_clipped_negative_start", agent l_t16.test_set_line_clipped_negative_start)
			run_test ("test_put_char_zero_width_keeps_consistency", agent l_t16.test_put_char_zero_width_keeps_consistency)
			run_test ("test_resize_cuts_wide_char", agent l_t16.test_resize_cuts_wide_char)
			run_test ("test_merge_repairs_cut_wide_char", agent l_t16.test_merge_repairs_cut_wide_char)
			run_test ("test_grapheme_clusters_in_buffer", agent l_t16.test_grapheme_clusters_in_buffer)
			run_test ("test_combining_mark_across_spans", agent l_t16.test_combining_mark_across_spans)
			run_test ("test_unicode_tables_from_ucd", agent l_t16.test_unicode_tables_from_ucd)
			run_test ("test_backend_cursor_tracking_utf8_bytes", agent l_t16.test_backend_cursor_tracking_utf8_bytes)
			run_test ("test_cells_updated_in_place_and_styles_shared", agent l_t16.test_cells_updated_in_place_and_styles_shared)
			run_test ("test_terminal_swaps_buffers", agent l_t16.test_terminal_swaps_buffers)
			run_test ("test_diff_span_pool_reused", agent l_t16.test_diff_span_pool_reused)
			run_test ("test_style_same_rendering_and_reset", agent l_t16.test_style_same_rendering_and_reset)
			run_test ("test_serializer_exact_sgr_deltas", agent l_t16.test_serializer_exact_sgr_deltas)
			run_test ("test_rect_clamp_moves_and_inner_does_not_wrap", agent l_t16.test_rect_clamp_moves_and_inner_does_not_wrap)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Test Suite (Layout Parity)...%N")
			print ("============================================================%N")
			create l_t17
			run_test ("test_layout_value_object_and_builders", agent l_t17.test_layout_value_object_and_builders)
			run_test ("test_layout_split_array", agent l_t17.test_layout_split_array)
			run_test ("test_deterministic_min_can_grow", agent l_t17.test_deterministic_min_can_grow)
			run_test ("test_deterministic_max_can_shrink", agent l_t17.test_deterministic_max_can_shrink)
			run_test ("test_deterministic_pct_and_ratio_remainders", agent l_t17.test_deterministic_pct_and_ratio_remainders)
			run_test ("test_deterministic_overconstrained_proportional_shrink", agent l_t17.test_deterministic_overconstrained_proportional_shrink)
			run_test ("test_deterministic_flex_split_by_weight", agent l_t17.test_deterministic_flex_split_by_weight)
			run_test ("test_flex_justify_proper_type_and_constants", agent l_t17.test_flex_justify_proper_type_and_constants)
			run_test ("test_flex_justify_space_evenly", agent l_t17.test_flex_justify_space_evenly)
			run_test ("test_flex_justify_remainder_distribution", agent l_t17.test_flex_justify_remainder_distribution)
			run_test ("test_flex_justify_legacy", agent l_t17.test_flex_justify_legacy)
			run_test ("test_layout_cache", agent l_t17.test_layout_cache)
			run_test ("test_layout_postconditions", agent l_t17.test_layout_postconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Review Test Suite...%N")
			print ("============================================================%N")
			create l_t18
			run_test ("test_percentage_rounding_bounded_by_exact_total", agent l_t18.test_percentage_rounding_bounded_by_exact_total)
			run_test ("test_ratio_does_not_overflow", agent l_t18.test_ratio_does_not_overflow)
			run_test ("test_overconstrained_shrink_order", agent l_t18.test_overconstrained_shrink_order)
			run_test ("test_space_around_is_symmetric", agent l_t18.test_space_around_is_symmetric)
			run_test ("test_large_spacing_does_not_overflow", agent l_t18.test_large_spacing_does_not_overflow)
			run_test ("test_layout_split_returns_copies", agent l_t18.test_layout_split_returns_copies)
			run_test ("test_layout_is_immutable", agent l_t18.test_layout_is_immutable)
			run_test ("test_postcondition_queries_reject_bad_chunks", agent l_t18.test_postcondition_queries_reject_bad_chunks)
			run_test ("test_overlap_with_zero_width_chunk", agent l_t18.test_overlap_with_zero_width_chunk)
			run_test ("test_overlap_bound_query", agent l_t18.test_overlap_bound_query)
			run_test ("test_merged_borders_keep_line_family", agent l_t18.test_merged_borders_keep_line_family)
			run_test ("test_merged_border_ignores_text", agent l_t18.test_merged_border_ignores_text)
			run_test ("test_render_merged_restores_setting", agent l_t18.test_render_merged_restores_setting)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone E Follow-ups Test Suite...%N")
			print ("============================================================%N")
			create l_t19
			run_test ("test_spacing_value_object", agent l_t19.test_spacing_value_object)
			run_test ("test_layout_overlap_spacing_ratatui_cases", agent l_t19.test_layout_overlap_spacing_ratatui_cases)
			run_test ("test_adjacent_blocks_overlap_border_merging", agent l_t19.test_adjacent_blocks_overlap_border_merging)
			run_test ("test_layout_split_with_spacers", agent l_t19.test_layout_split_with_spacers)
			run_test ("test_layout_cache_lru_eviction", agent l_t19.test_layout_cache_lru_eviction)
			run_test ("test_tui_table_layout_integration", agent l_t19.test_tui_table_layout_integration)
			run_test ("test_split_list_is_independent_of_cache", agent l_t19.test_split_list_is_independent_of_cache)
			run_test ("test_cache_hit_reuses_stored_solution", agent l_t19.test_cache_hit_reuses_stored_solution)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Test Suite (Widget Completion)...%N")
			print ("============================================================%N")
			create l_t20
			run_test ("test_table_horizontal_column_scroll_and_highlight", agent l_t20.test_table_horizontal_column_scroll_and_highlight)
			run_test ("test_barchart_bar_group_and_horizontal", agent l_t20.test_barchart_bar_group_and_horizontal)
			run_test ("test_chart_legend_position_axis_titles_markers", agent l_t20.test_chart_legend_position_axis_titles_markers)
			run_test ("test_canvas_shapes_layers_color_policy", agent l_t20.test_canvas_shapes_layers_color_policy)
			run_test ("test_block_multiple_titles_background_padding_borders", agent l_t20.test_block_multiple_titles_background_padding_borders)
			run_test ("test_list_multiline_highlight_spacing_direction", agent l_t20.test_list_multiline_highlight_spacing_direction)
			run_test ("test_tabs_padding_and_divider_clipping", agent l_t20.test_tabs_padding_and_divider_clipping)
			run_test ("test_gauge_color_inversion_and_line_gauge_truncation", agent l_t20.test_gauge_color_inversion_and_line_gauge_truncation)
			run_test ("test_sparkline_direction_and_ordering", agent l_t20.test_sparkline_direction_and_ordering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Widget Smoke Test Suite...%N")
			print ("============================================================%N")
			create l_t21
			run_test ("test_text_widgets_survive_awkward_areas", agent l_t21.test_text_widgets_survive_awkward_areas)
			run_test ("test_stateful_widgets_survive_awkward_areas", agent l_t21.test_stateful_widgets_survive_awkward_areas)
			run_test ("test_metric_widgets_survive_awkward_areas", agent l_t21.test_metric_widgets_survive_awkward_areas)
			run_test ("test_canvas_widgets_survive_awkward_areas", agent l_t21.test_canvas_widgets_survive_awkward_areas)
			run_test ("test_ecosystem_widgets_survive_awkward_areas", agent l_t21.test_ecosystem_widgets_survive_awkward_areas)
			run_test ("test_divider_survives_awkward_areas", agent l_t21.test_divider_survives_awkward_areas)
			run_test ("test_checkbox_survives_awkward_areas", agent l_t21.test_checkbox_survives_awkward_areas)
			run_test ("test_slider_survives_awkward_areas", agent l_t21.test_slider_survives_awkward_areas)
			run_test ("test_menu_survives_awkward_areas", agent l_t21.test_menu_survives_awkward_areas)
			run_test ("test_toast_survives_awkward_areas", agent l_t21.test_toast_survives_awkward_areas)
			run_test ("test_tooltip_survives_awkward_areas", agent l_t21.test_tooltip_survives_awkward_areas)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Review Test Suite...%N")
			print ("============================================================%N")
			create l_t22
			run_test ("test_list_highlight_spacing", agent l_t22.test_list_highlight_spacing)
			run_test ("test_list_scrolls_by_rows", agent l_t22.test_list_scrolls_by_rows)
			run_test ("test_list_scroll_padding_leaves_no_blank_rows", agent l_t22.test_list_scroll_padding_leaves_no_blank_rows)
			run_test ("test_horizontal_bar_value_at_maximum", agent l_t22.test_horizontal_bar_value_at_maximum)
			run_test ("test_block_title_kept_with_other_titles", agent l_t22.test_block_title_kept_with_other_titles)
			run_test ("test_chart_dot_marker_is_drawn", agent l_t22.test_chart_dot_marker_is_drawn)
			run_test ("test_chart_y_title_and_label_order", agent l_t22.test_chart_y_title_and_label_order)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone F Gaps Test Suite...%N")
			print ("============================================================%N")
			create l_t23
			run_test ("test_table_clips_columns_and_scrolls_right", agent l_t23.test_table_clips_columns_and_scrolls_right)
			run_test ("test_table_highlights_win_over_cell_styles", agent l_t23.test_table_highlights_win_over_cell_styles)
			run_test ("test_barchart_vertical_groups_and_group_labels", agent l_t23.test_barchart_vertical_groups_and_group_labels)
			run_test ("test_barchart_max_follows_group_changes", agent l_t23.test_barchart_max_follows_group_changes)
			run_test ("test_barchart_hides_values_wider_than_the_bar", agent l_t23.test_barchart_hides_values_wider_than_the_bar)
			run_test ("test_canvas_layers_stack", agent l_t23.test_canvas_layers_stack)
			run_test ("test_canvas_half_block_resolution", agent l_t23.test_canvas_half_block_resolution)
			run_test ("test_canvas_text_clipped_to_area", agent l_t23.test_canvas_text_clipped_to_area)
			run_test ("test_chart_line_uses_marker", agent l_t23.test_chart_line_uses_marker)
			run_test ("test_chart_bars_rise_from_zero", agent l_t23.test_chart_bars_rise_from_zero)
			run_test ("test_chart_legend_border_and_hiding", agent l_t23.test_chart_legend_border_and_hiding)
			run_test ("test_block_titles_laid_out_per_side", agent l_t23.test_block_titles_laid_out_per_side)
			run_test ("test_gauge_label_keeps_explicit_colour", agent l_t23.test_gauge_label_keeps_explicit_colour)
			run_test ("test_gauge_label_wide_char_clipped", agent l_t23.test_gauge_label_wide_char_clipped)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Test Suite (Ergonomics & Ecosystem)...%N")
			print ("============================================================%N")
			create l_t24
			run_test ("test_style_immutability_and_cqs", agent l_t24.test_style_immutability_and_cqs)
			run_test ("test_block_container_and_inner_area", agent l_t24.test_block_container_and_inner_area)
			run_test ("test_text_hierarchy_direct_rendering", agent l_t24.test_text_hierarchy_direct_rendering)
			run_test ("test_symbols_and_themes", agent l_t24.test_symbols_and_themes)
			run_test ("test_text_input_editing_and_rendering", agent l_t24.test_text_input_editing_and_rendering)
			run_test ("test_popup_helpers_and_rendering", agent l_t24.test_popup_helpers_and_rendering)
			run_test ("test_tree_navigation_and_rendering", agent l_t24.test_tree_navigation_and_rendering)
			run_test ("test_calendar_state_and_rendering", agent l_t24.test_calendar_state_and_rendering)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Review Test Suite...%N")
			print ("============================================================%N")
			create l_t25
			run_test ("test_builders_do_not_share_lists", agent l_t25.test_builders_do_not_share_lists)
			run_test ("test_frame_rejects_mismatched_state", agent l_t25.test_frame_rejects_mismatched_state)
			run_test ("test_text_input_edits_grapheme_clusters", agent l_t25.test_text_input_edits_grapheme_clusters)
			run_test ("test_text_input_renders_by_display_width", agent l_t25.test_text_input_renders_by_display_width)
			run_test ("test_text_input_scrolls_by_column_and_keeps_invariant", agent l_t25.test_text_input_scrolls_by_column_and_keeps_invariant)
			run_test ("test_tree_stays_in_area_and_follows_selection", agent l_t25.test_tree_stays_in_area_and_follows_selection)
			run_test ("test_calendar_stays_in_narrow_area", agent l_t25.test_calendar_stays_in_narrow_area)
			run_test ("test_calendar_weekday_before_year_one", agent l_t25.test_calendar_weekday_before_year_one)
			run_test ("test_gray_is_ansi_7", agent l_t25.test_gray_is_ansi_7)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone G Follow-ups Test Suite...%N")
			print ("============================================================%N")
			create l_t26
			run_test ("test_is_equal_differentiates_titles_and_borders", agent l_t26.test_is_equal_differentiates_titles_and_borders)
			run_test ("test_is_equal_table_and_canvas_and_chart", agent l_t26.test_is_equal_table_and_canvas_and_chart)
			run_test ("test_copied_list_and_table_elements_isolated", agent l_t26.test_copied_list_and_table_elements_isolated)
			run_test ("test_tree_collapse_reselects_visible_ancestor", agent l_t26.test_tree_collapse_reselects_visible_ancestor)
			run_test ("test_calendar_custom_first_day_and_date_styles", agent l_t26.test_calendar_custom_first_day_and_date_styles)
			run_test ("test_copied_tabs_bars_and_tree_roots_isolated", agent l_t26.test_copied_tabs_bars_and_tree_roots_isolated)
			run_test ("test_block_title_copies_keep_mirroring", agent l_t26.test_block_title_copies_keep_mirroring)
			run_test ("test_calendar_is_equal_compares_date_styles", agent l_t26.test_calendar_is_equal_compares_date_styles)
			run_test ("test_copy_on_write_keeps_copies_independent", agent l_t26.test_copy_on_write_keeps_copies_independent)
			run_test ("test_tree_state_collapse_uses_recorded_path", agent l_t26.test_tree_state_collapse_uses_recorded_path)
			run_test ("test_calendar_shows_surrounding_days", agent l_t26.test_calendar_shows_surrounding_days)
			run_test ("test_calendar_rejects_impossible_date_style", agent l_t26.test_calendar_rejects_impossible_date_style)

			print ("============================================================%N")
			print ("  Running EiffelTUI Keyboard Enhancement Test Suite...%N")
			print ("============================================================%N")
			create l_t27
			run_test ("test_insert_key_code", agent l_t27.test_insert_key_code)
			run_test ("test_key_event_kinds", agent l_t27.test_key_event_kinds)
			run_test ("test_parser_insert_key", agent l_t27.test_parser_insert_key)
			run_test ("test_kitty_csi_u_characters", agent l_t27.test_kitty_csi_u_characters)
			run_test ("test_kitty_csi_u_functional_keys", agent l_t27.test_kitty_csi_u_functional_keys)
			run_test ("test_csi_event_types_legacy_keys", agent l_t27.test_csi_event_types_legacy_keys)
			run_test ("test_modified_f3_disambiguation", agent l_t27.test_modified_f3_disambiguation)
			run_test ("test_backend_keyboard_enhancement", agent l_t27.test_backend_keyboard_enhancement)
			run_test ("test_tilde_function_keys", agent l_t27.test_tilde_function_keys)
			run_test ("test_application_pushes_and_pops_keyboard_flags", agent l_t27.test_application_pushes_and_pops_keyboard_flags)

			print ("============================================================%N")
			print ("  Running EiffelTUI Platform Driver Test Suite...%N")
			print ("============================================================%N")
			create l_platform
			across l_platform.tests as t loop
				run_test (t.name, t.routine)
			end

			print ("============================================================%N")
			print ("  Running EiffelTUI Tier 1 Foundation Examples Test Suite...%N")
			print ("============================================================%N")
			create l_t28
			run_test ("test_example_hello_world", agent l_t28.test_example_hello_world)
			run_test ("test_example_minimal", agent l_t28.test_example_minimal)
			run_test ("test_example_colors_rgb", agent l_t28.test_example_colors_rgb)
			run_test ("test_example_color_explorer", agent l_t28.test_example_color_explorer)
			run_test ("test_example_modifiers", agent l_t28.test_example_modifiers)
			run_test ("test_example_popup", agent l_t28.test_example_popup)
			run_test ("test_example_inline", agent l_t28.test_example_inline)

			print ("============================================================%N")
			print ("  Running EiffelTUI Tier 2 Widget Specialist Examples Test Suite...%N")
			print ("============================================================%N")
			create l_t29
			run_test ("test_example_todo_list", agent l_t29.test_example_todo_list)
			run_test ("test_example_user_input", agent l_t29.test_example_user_input)
			run_test ("test_example_input_form", agent l_t29.test_example_input_form)
			run_test ("test_example_text_area", agent l_t29.test_example_text_area)
			run_test ("test_example_modal_dialog", agent l_t29.test_example_modal_dialog)
			run_test ("test_example_modal_dialog_clicks", agent l_t29.test_example_modal_dialog_clicks)
			run_test ("test_example_table", agent l_t29.test_example_table)
			run_test ("test_example_scrollbar", agent l_t29.test_example_scrollbar)
			run_test ("test_example_gauge", agent l_t29.test_example_gauge)
			run_test ("test_example_calendar_explorer", agent l_t29.test_example_calendar_explorer)

			print ("============================================================%N")
			print ("  Running EiffelTUI Bracketed Paste Robustness Test Suite...%N")
			print ("============================================================%N")
			create l_t30
			run_test ("test_end_marker_split_by_timeout", agent l_t30.test_end_marker_split_by_timeout)
			run_test ("test_escape_before_end_marker", agent l_t30.test_escape_before_end_marker)
			run_test ("test_long_parameters_in_paste_kept", agent l_t30.test_long_parameters_in_paste_kept)
			run_test ("test_paste_watchdog", agent l_t30.test_paste_watchdog)
			run_test ("test_flush_outside_paste_unchanged", agent l_t30.test_flush_outside_paste_unchanged)
			run_test ("test_event_thread_pause_inside_end_marker", agent l_t30.test_event_thread_pause_inside_end_marker)
			run_test ("test_event_thread_lost_end_marker", agent l_t30.test_event_thread_lost_end_marker)
			run_test ("test_paste_split_into_parts", agent l_t30.test_paste_split_into_parts)
			run_test ("test_paste_exact_multiple_ends_with_empty_part", agent l_t30.test_paste_exact_multiple_ends_with_empty_part)
			run_test ("test_paste_parts_keep_sequences", agent l_t30.test_paste_parts_keep_sequences)
			run_test ("test_paste_watchdog_delivers_parts", agent l_t30.test_paste_watchdog_delivers_parts)
			run_test ("test_paste_event_owns_its_text", agent l_t30.test_paste_event_owns_its_text)
			run_test ("test_event_thread_resize_poll_not_per_byte", agent l_t30.test_event_thread_resize_poll_not_per_byte)

			print ("============================================================%N")
			print ("  Running EiffelTUI Failure Recovery Test Suite...%N")
			print ("============================================================%N")
			create l_t38
			run_test ("test_sgr_mouse_large_coordinates_clamped", agent l_t38.test_sgr_mouse_large_coordinates_clamped)
			run_test ("test_discard_pending", agent l_t38.test_discard_pending)
			run_test ("test_event_thread_retry_starts_clean", agent l_t38.test_event_thread_retry_starts_clean)
			run_test ("test_event_thread_large_mouse_coordinate", agent l_t38.test_event_thread_large_mouse_coordinate)
			run_test ("test_failed_push_releases_lock", agent l_t38.test_failed_push_releases_lock)

			print ("============================================================%N")
			print ("  Running EiffelTUI UTF-8 out Test Suite...%N")
			print ("============================================================%N")
			create l_t39
			run_test ("test_text_out_is_utf_8", agent l_t39.test_text_out_is_utf_8)
			run_test ("test_widget_items_out_is_utf_8", agent l_t39.test_widget_items_out_is_utf_8)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Gaps Test Suite...%N")
			print ("============================================================%N")
			create l_t40
			run_test ("test_vs16_widens_only_emoji", agent l_t40.test_vs16_widens_only_emoji)
			run_test ("test_bidi_controls_are_own_clusters", agent l_t40.test_bidi_controls_are_own_clusters)
			run_test ("test_buffer_drops_bidi_controls", agent l_t40.test_buffer_drops_bidi_controls)
			run_test ("test_calendar_header_centred_by_width", agent l_t40.test_calendar_header_centred_by_width)
			run_test ("test_sub_span_on_cluster_boundaries", agent l_t40.test_sub_span_on_cluster_boundaries)

			print ("============================================================%N")
			print ("  Running EiffelTUI Diff Pool Test Suite...%N")
			print ("============================================================%N")
			create l_t41
			run_test ("test_sparse_frame_pool_is_small", agent l_t41.test_sparse_frame_pool_is_small)
			run_test ("test_unused_spans_emptied", agent l_t41.test_unused_spans_emptied)
			run_test ("test_span_grows_to_a_row", agent l_t41.test_span_grows_to_a_row)
			run_test ("test_discard_pool", agent l_t41.test_discard_pool)
			run_test ("test_terminal_resize_discards_pool", agent l_t41.test_terminal_resize_discards_pool)
			run_test ("test_diff_options_reuse_pool", agent l_t41.test_diff_options_reuse_pool)

			print ("============================================================%N")
			print ("  Running EiffelTUI Diff Checks (P1 X2) Test Suite...%N")
			print ("============================================================%N")
			create l_t54
			run_test ("test_uncovered_trailing_cells_written", agent l_t54.test_uncovered_trailing_cells_written)
			run_test ("test_partially_replaced_wide_chars_write_uncovered_cell", agent l_t54.test_partially_replaced_wide_chars_write_uncovered_cell)
			run_test ("test_shrinking_wide_glyph_clears_trailing_cell", agent l_t54.test_shrinking_wide_glyph_clears_trailing_cell)
			run_test ("test_wide_char_trailing_not_corrupted", agent l_t54.test_wide_char_trailing_not_corrupted)
			run_test ("test_long_symbol_does_not_hide_later_cells", agent l_t54.test_long_symbol_does_not_hide_later_cells)
			run_test ("test_wide_glyph_background_change_rewrites_glyph", agent l_t54.test_wide_glyph_background_change_rewrites_glyph)
			run_test ("test_wide_glyph_style_change_resumes_after_repaint", agent l_t54.test_wide_glyph_style_change_resumes_after_repaint)
			run_test ("test_wide_glyph_foreground_change_writes_glyph_only", agent l_t54.test_wide_glyph_foreground_change_writes_glyph_only)
			run_test ("test_vs16_cluster_is_two_columns_and_disputed", agent l_t54.test_vs16_cluster_is_two_columns_and_disputed)
			run_test ("test_vs16_replacing_narrower_content_leaves_no_stale_column", agent l_t54.test_vs16_replacing_narrower_content_leaves_no_stale_column)
			run_test ("test_vs16_row_replacing_ascii_does_not_drift", agent l_t54.test_vs16_row_replacing_ascii_does_not_drift)
			run_test ("test_mixed_width_rows_do_not_drift", agent l_t54.test_mixed_width_rows_do_not_drift)
			run_test ("test_vs16_trailing_column_cleared_before_glyph", agent l_t54.test_vs16_trailing_column_cleared_before_glyph)

			print ("============================================================%N")
			print ("  Running EiffelTUI Chart Checks (P1 X3) Test Suite...%N")
			print ("============================================================%N")
			create l_t55
			run_test ("test_chart_one_y_label_renders_it", agent l_t55.test_chart_one_y_label_renders_it)
			run_test ("test_chart_one_x_label_renders_it", agent l_t55.test_chart_one_x_label_renders_it)
			run_test ("test_chart_labels_on_one_cell_plot", agent l_t55.test_chart_labels_on_one_cell_plot)
			run_test ("test_chart_huge_bounds_render", agent l_t55.test_chart_huge_bounds_render)
			run_test ("test_chart_huge_bounds_place_points", agent l_t55.test_chart_huge_bounds_place_points)
			run_test ("test_clipping_ends_beyond_half_the_range", agent l_t55.test_clipping_ends_beyond_half_the_range)
			run_test ("test_barchart_render_handles_u64_max_value", agent l_t55.test_barchart_render_handles_u64_max_value)
			run_test ("test_barchart_render_keeps_integer_precision_for_large_values", agent l_t55.test_barchart_render_keeps_integer_precision_for_large_values)
			run_test ("test_barchart_values_on_the_bars", agent l_t55.test_barchart_values_on_the_bars)
			run_test ("test_horizontal_empty_barchart_renders_block_only", agent l_t55.test_horizontal_empty_barchart_renders_block_only)
			run_test ("test_constructors_ignore_empty_groups", agent l_t55.test_constructors_ignore_empty_groups)
			run_test ("test_empty_groups_are_not_part_of_the_chart", agent l_t55.test_empty_groups_are_not_part_of_the_chart)

			print ("============================================================%N")
			print ("  Running EiffelTUI Widget Edge Checks (P1 X4) Test Suite...%N")
			print ("============================================================%N")
			create l_t56
			run_test ("test_halfwidth_sound_marks_are_one_column", agent l_t56.test_halfwidth_sound_marks_are_one_column)
			run_test ("test_other_grapheme_extend_characters", agent l_t56.test_other_grapheme_extend_characters)
			run_test ("test_set_string_halfwidth_katakana_with_dakuten", agent l_t56.test_set_string_halfwidth_katakana_with_dakuten)
			run_test ("test_set_string_combining_vs_halfwidth_dakuten", agent l_t56.test_set_string_combining_vs_halfwidth_dakuten)
			run_test ("test_render_paragraph_with_halfwidth_katakana_dakuten_and_background", agent l_t56.test_render_paragraph_with_halfwidth_katakana_dakuten_and_background)
			run_test ("test_clipping_keeps_dakuten_with_its_katakana", agent l_t56.test_clipping_keeps_dakuten_with_its_katakana)
			run_test ("test_text_input_and_area_edit_dakuten_as_one_character", agent l_t56.test_text_input_and_area_edit_dakuten_as_one_character)
			run_test ("test_clear_render", agent l_t56.test_clear_render)
			run_test ("test_clear_render_partially_out_of_bounds", agent l_t56.test_clear_render_partially_out_of_bounds)
			run_test ("test_clear_render_fully_out_of_bounds", agent l_t56.test_clear_render_fully_out_of_bounds)
			run_test ("test_clear_resets_cells_and_splits_cut_wide_characters", agent l_t56.test_clear_resets_cells_and_splits_cut_wide_characters)
			run_test ("test_clear_on_buffer_at_the_coordinate_limit", agent l_t56.test_clear_on_buffer_at_the_coordinate_limit)
			run_test ("test_inner_takes_into_account_the_borders", agent l_t56.test_inner_takes_into_account_the_borders)
			run_test ("test_inner_saturates_when_padding_sum_overflows", agent l_t56.test_inner_saturates_when_padding_sum_overflows)
			run_test ("test_inner_padding_sums_do_not_wrap", agent l_t56.test_inner_padding_sums_do_not_wrap)
			run_test ("test_inner_with_padding_larger_than_the_area", agent l_t56.test_inner_with_padding_larger_than_the_area)
			run_test ("test_render_empty_areas_draws_nothing", agent l_t56.test_render_empty_areas_draws_nothing)
			run_test ("test_render_merged_borders_in_minimal_buffer", agent l_t56.test_render_merged_borders_in_minimal_buffer)
			run_test ("test_block_at_the_last_column_and_row", agent l_t56.test_block_at_the_last_column_and_row)
			run_test ("test_block_partly_outside_the_buffer_is_closed_at_its_edge", agent l_t56.test_block_partly_outside_the_buffer_is_closed_at_its_edge)
			run_test ("test_content_stays_inside_a_block_cut_by_the_buffer", agent l_t56.test_content_stays_inside_a_block_cut_by_the_buffer)
			run_test ("test_huge_titles_are_clipped", agent l_t56.test_huge_titles_are_clipped)
			run_test ("test_block_on_buffer_at_the_coordinate_limit", agent l_t56.test_block_on_buffer_at_the_coordinate_limit)
			run_test ("test_buffer_size_is_within_rect_range", agent l_t56.test_buffer_size_is_within_rect_range)
			run_test ("test_insert_before_more_rows_than_a_buffer_holds", agent l_t56.test_insert_before_more_rows_than_a_buffer_holds)
			run_test ("test_insert_before_rows_gives_each_block_its_first_row", agent l_t56.test_insert_before_rows_gives_each_block_its_first_row)
			run_test ("test_insert_before_at_the_buffer_limit", agent l_t56.test_insert_before_at_the_buffer_limit)
			run_test ("test_terminal_larger_than_a_buffer", agent l_t56.test_terminal_larger_than_a_buffer)

			print ("============================================================%N")
			print ("  Running EiffelTUI Shared Objects Test Suite...%N")
			print ("============================================================%N")
			create l_t42
			run_test ("test_symbols_are_immutable", agent l_t42.test_symbols_are_immutable)
			run_test ("test_set_style_stores_private_copy", agent l_t42.test_set_style_stores_private_copy)

			print ("============================================================%N")
			print ("  Running EiffelTUI Event Flood Test Suite...%N")
			print ("============================================================%N")
			create l_t43
			run_test ("test_drag_and_resize_coalesced", agent l_t43.test_drag_and_resize_coalesced)
			run_test ("test_clicks_and_moves_not_merged", agent l_t43.test_clicks_and_moves_not_merged)
			run_test ("test_coalescing_off", agent l_t43.test_coalescing_off)
			run_test ("test_queue_full", agent l_t43.test_queue_full)
			run_test ("test_input_thread_waits_while_full", agent l_t43.test_input_thread_waits_while_full)

			print ("============================================================%N")
			print ("  Running EiffelTUI Milestone H (Custom Events / Focus)...%N")
			print ("============================================================%N")
			create l_t44
			run_test ("test_custom_event_flags", agent l_t44.test_custom_event_flags)
			run_test ("test_post_event_from_worker_thread", agent l_t44.test_post_event_from_worker_thread)
			run_test ("test_post_event_wakes_poll", agent l_t44.test_post_event_wakes_poll)
			run_test ("test_focus_tab_cycle", agent l_t44.test_focus_tab_cycle)
			run_test ("test_hit_map_topmost", agent l_t44.test_hit_map_topmost)
			run_test ("test_modal_scope_traps_focus", agent l_t44.test_modal_scope_traps_focus)
			run_test ("test_form_snapshot_diagram", agent l_t44.test_form_snapshot_diagram)

			print ("============================================================%N")
			print ("  Running EiffelTUI Text Area Test Suite...%N")
			print ("============================================================%N")
			create l_t45
			run_test ("test_newline_and_navigation", agent l_t45.test_newline_and_navigation)
			run_test ("test_grapheme_delete", agent l_t45.test_grapheme_delete)
			run_test ("test_selection_and_undo", agent l_t45.test_selection_and_undo)
			run_test ("test_render_snapshot", agent l_t45.test_render_snapshot)
			run_test ("test_backspace_after_extend_leaves_no_selection", agent l_t45.test_backspace_after_extend_leaves_no_selection)
			run_test ("test_delete_with_stale_anchor_keeps_invariant", agent l_t45.test_delete_with_stale_anchor_keeps_invariant)
			run_test ("test_scroll_follows_wrapped_rows", agent l_t45.test_scroll_follows_wrapped_rows)
			run_test ("test_trailing_line_break_gives_one_empty_row", agent l_t45.test_trailing_line_break_gives_one_empty_row)
			run_test ("test_scroll_row_inside_bordered_block", agent l_t45.test_scroll_row_inside_bordered_block)
			run_test ("test_cursor_keeps_character_under_it", agent l_t45.test_cursor_keeps_character_under_it)
			run_test ("test_selection_highlights_only_the_range", agent l_t45.test_selection_highlights_only_the_range)
			run_test ("test_word_wrap_breaks_at_spaces", agent l_t45.test_word_wrap_breaks_at_spaces)
			run_test ("test_cursor_after_full_row_is_inside_area", agent l_t45.test_cursor_after_full_row_is_inside_area)
			run_test ("test_up_down_move_by_visual_rows", agent l_t45.test_up_down_move_by_visual_rows)
			run_test ("test_loaded_text_keeps_cursor_column", agent l_t45.test_loaded_text_keeps_cursor_column)
			run_test ("test_scroll_moves_by_the_fewest_rows", agent l_t45.test_scroll_moves_by_the_fewest_rows)
			run_test ("test_word_wrap_scroll_and_cursor", agent l_t45.test_word_wrap_scroll_and_cursor)
			run_test ("test_cursor_position_in_offset_scrolled_block", agent l_t45.test_cursor_position_in_offset_scrolled_block)
			run_test ("test_selection_and_cursor_cell_styles", agent l_t45.test_selection_and_cursor_cell_styles)
			run_test ("test_editing_large_text_is_line_local", agent l_t45.test_editing_large_text_is_line_local)
			run_test ("test_typing_groups_into_undo_steps", agent l_t45.test_typing_groups_into_undo_steps)
			run_test ("test_no_op_edits_record_no_undo", agent l_t45.test_no_op_edits_record_no_undo)
			run_test ("test_redo_reverses_undo", agent l_t45.test_redo_reverses_undo)
			run_test ("test_edit_forgets_redo", agent l_t45.test_edit_forgets_redo)
			run_test ("test_undo_and_redo_share_the_bound", agent l_t45.test_undo_and_redo_share_the_bound)
			run_test ("test_backspace_run_is_one_undo_step", agent l_t45.test_backspace_run_is_one_undo_step)
			run_test ("test_newline_ends_typing_step", agent l_t45.test_newline_ends_typing_step)
			run_test ("test_undo_restores_cursor_and_anchor", agent l_t45.test_undo_restores_cursor_and_anchor)
			run_test ("test_undo_depth_is_bounded", agent l_t45.test_undo_depth_is_bounded)
			run_test ("test_focus_tab_into_area", agent l_t45.test_focus_tab_into_area)

			create l_t46
			run_test ("test_ctrl_z_suspend_sequence", agent l_t46.test_ctrl_z_suspend_sequence)
			run_test ("test_late_continue_resumes_once", agent l_t46.test_late_continue_resumes_once)
			run_test ("test_external_stop_resumes_once", agent l_t46.test_external_stop_resumes_once)
			run_test ("test_external_stop_sets_title_again", agent l_t46.test_external_stop_sets_title_again)
			run_test ("test_title_set_on_terminal_survives_ctrl_z", agent l_t46.test_title_set_on_terminal_survives_ctrl_z)
			run_test ("test_title_set_while_stopped_waits_for_fg", agent l_t46.test_title_set_while_stopped_waits_for_fg)
			run_test ("test_external_stop_background_continue_waits_for_fg", agent l_t46.test_external_stop_background_continue_waits_for_fg)
			run_test ("test_ctrl_z_background_continue_waits_for_fg", agent l_t46.test_ctrl_z_background_continue_waits_for_fg)
			run_test ("test_external_stop_quit_before_noticed_writes_nothing", agent l_t46.test_external_stop_quit_before_noticed_writes_nothing)
			run_test ("test_external_stop_waiting_in_background_writes_nothing", agent l_t46.test_external_stop_waiting_in_background_writes_nothing)
			run_test ("test_background_start_waits_for_fg", agent l_t46.test_background_start_waits_for_fg)
			run_test ("test_quit_while_waiting_to_start_writes_nothing", agent l_t46.test_quit_while_waiting_to_start_writes_nothing)
			run_test ("test_termination_while_waiting_to_start_writes_nothing", agent l_t46.test_termination_while_waiting_to_start_writes_nothing)
			run_test ("test_inline_background_start_queries_cursor_after_fg", agent l_t46.test_inline_background_start_queries_cursor_after_fg)
			run_test ("test_output_handed_to_driver_at_flush", agent l_t46.test_output_handed_to_driver_at_flush)
			run_test ("test_inline_viewport_resume", agent l_t46.test_inline_viewport_resume)
			run_test ("test_suspend_sequence_order_fullscreen", agent l_t46.test_suspend_sequence_order_fullscreen)
			run_test ("test_suspend_sequence_order_inline", agent l_t46.test_suspend_sequence_order_inline)
			run_test ("test_ctrl_z_passed_through_when_disabled", agent l_t46.test_ctrl_z_passed_through_when_disabled)
			run_test ("test_no_suspend_without_platform_support", agent l_t46.test_no_suspend_without_platform_support)

			create l_t47
			run_test ("test_blocker_hides_what_is_below", agent l_t47.test_blocker_hides_what_is_below)
			run_test ("test_focus_at_stays_in_scope", agent l_t47.test_focus_at_stays_in_scope)
			run_test ("test_focus_at_nested_scopes", agent l_t47.test_focus_at_nested_scopes)
			run_test ("test_popup_blocks_background_hits", agent l_t47.test_popup_blocks_background_hits)
			run_test ("test_non_modal_popup_does_not_block", agent l_t47.test_non_modal_popup_does_not_block)
			run_test ("test_popup_blocking_follows_focus_scope", agent l_t47.test_popup_blocking_follows_focus_scope)
			run_test ("test_popup_registers_inner_widget_hits", agent l_t47.test_popup_registers_inner_widget_hits)
			run_test ("test_modal_clips_later_regions", agent l_t47.test_modal_clips_later_regions)
			run_test ("test_modal_popup_blocks_controls_drawn_after_it", agent l_t47.test_modal_popup_blocks_controls_drawn_after_it)
			run_test ("test_shown_area_follows_the_screen", agent l_t47.test_shown_area_follows_the_screen)
			run_test ("test_hit_test_after_insert_before", agent l_t47.test_hit_test_after_insert_before)
			run_test ("test_hit_test_after_resize_event", agent l_t47.test_hit_test_after_resize_event)
			run_test ("test_modal_clicks_in_fixed_viewport", agent l_t47.test_modal_clicks_in_fixed_viewport)
			run_test ("test_widgets_register_their_hit_region", agent l_t47.test_widgets_register_their_hit_region)
			run_test ("test_hit_test_uses_screen_coordinates", agent l_t47.test_hit_test_uses_screen_coordinates)
			run_test ("test_hit_test_fullscreen", agent l_t47.test_hit_test_fullscreen)
			run_test ("test_hit_test_fixed_viewport", agent l_t47.test_hit_test_fixed_viewport)
			run_test ("test_hit_test_outside_viewport_is_void", agent l_t47.test_hit_test_outside_viewport_is_void)
			run_test ("test_hit_map_replaced_after_each_frame", agent l_t47.test_hit_map_replaced_after_each_frame)
			run_test ("test_form_snapshot_with_clicks_and_modal", agent l_t47.test_form_snapshot_with_clicks_and_modal)
			run_test ("test_modal_dialog_example_snapshot", agent l_t47.test_modal_dialog_example_snapshot)
			run_test ("test_input_form_example_snapshot", agent l_t47.test_input_form_example_snapshot)
			run_test ("test_demo2_ping_sparkline_absent_and_bar_styles", agent l_t47.test_demo2_ping_sparkline_absent_and_bar_styles)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Wrap Test Suite...%N")
			print ("============================================================%N")
			create l_t31
			run_test ("test_character_wrap_keeps_combining_marks", agent l_t31.test_character_wrap_keeps_combining_marks)
			run_test ("test_character_wrap_keeps_vs16", agent l_t31.test_character_wrap_keeps_vs16)
			run_test ("test_character_wrap_keeps_zwj_sequence", agent l_t31.test_character_wrap_keeps_zwj_sequence)
			run_test ("test_character_wrap_keeps_flags_whole", agent l_t31.test_character_wrap_keeps_flags_whole)
			run_test ("test_character_wrap_round_trip", agent l_t31.test_character_wrap_round_trip)
			run_test ("test_character_wrap_trims_leading_space", agent l_t31.test_character_wrap_trims_leading_space)
			run_test ("test_character_wrap_across_spans", agent l_t31.test_character_wrap_across_spans)
			run_test ("test_word_wrap_vs16_not_under_counted", agent l_t31.test_word_wrap_vs16_not_under_counted)
			run_test ("test_word_wrap_emoji_not_over_counted", agent l_t31.test_word_wrap_emoji_not_over_counted)
			run_test ("test_word_wrap_oversized_keeps_zwj", agent l_t31.test_word_wrap_oversized_keeps_zwj)
			run_test ("test_word_wrap_keeps_combining_marks", agent l_t31.test_word_wrap_keeps_combining_marks)
			run_test ("test_word_wrap_keeps_flags_whole", agent l_t31.test_word_wrap_keeps_flags_whole)
			run_test ("test_word_wrap_round_trip", agent l_t31.test_word_wrap_round_trip)
			run_test ("test_wrap_same_style_spans_split_vs16", agent l_t31.test_wrap_same_style_spans_split_vs16)
			run_test ("test_wrap_same_style_spans_split_zwj", agent l_t31.test_wrap_same_style_spans_split_zwj)
			run_test ("test_append_span_moves_continuation", agent l_t31.test_append_span_moves_continuation)
			run_test ("test_append_span_keeps_independent_span", agent l_t31.test_append_span_keeps_independent_span)
			run_test ("test_append_span_skips_empty_spans", agent l_t31.test_append_span_skips_empty_spans)
			run_test ("test_append_text", agent l_t31.test_append_text)
			run_test ("test_right_adjust", agent l_t31.test_right_adjust)
			run_test ("test_wrap_split_around_empty_span", agent l_t31.test_wrap_split_around_empty_span)
			run_test ("test_buffer_draws_vs16_split_around_empty_span", agent l_t31.test_buffer_draws_vs16_split_around_empty_span)
			run_test ("test_wrap_different_style_spans_split_zwj", agent l_t31.test_wrap_different_style_spans_split_zwj)
			run_test ("test_buffer_draws_vs16_split_across_styles", agent l_t31.test_buffer_draws_vs16_split_across_styles)

			print ("============================================================%N")
			print ("  Running EiffelTUI Console Input Claim Test Suite...%N")
			print ("============================================================%N")
			create l_t32
			run_test ("test_claim_is_exclusive", agent l_t32.test_claim_is_exclusive)
			run_test ("test_platform_drivers_share_one_claim", agent l_t32.test_platform_drivers_share_one_claim)
			run_test ("test_event_thread_holds_claim_while_running", agent l_t32.test_event_thread_holds_claim_while_running)
			run_test ("test_second_reader_refused", agent l_t32.test_second_reader_refused)
			run_test ("test_query_releases_claim", agent l_t32.test_query_releases_claim)
			run_test ("test_query_refused_while_reader_runs", agent l_t32.test_query_refused_while_reader_runs)
			run_test ("test_inline_setup_refused_while_reader_runs", agent l_t32.test_inline_setup_refused_while_reader_runs)
			run_test ("test_application_holds_claim_while_running", agent l_t32.test_application_holds_claim_while_running)
			run_test ("test_run_refused_while_input_in_use", agent l_t32.test_run_refused_while_input_in_use)

			print ("============================================================%N")
			print ("  Running EiffelTUI Unicode Scalar Test Suite...%N")
			print ("============================================================%N")
			create l_t33
			run_test ("test_scalar_value_boundaries", agent l_t33.test_scalar_value_boundaries)
			run_test ("test_scalar_string", agent l_t33.test_scalar_string)
			run_test ("test_replacement_is_measurement_neutral", agent l_t33.test_replacement_is_measurement_neutral)
			run_test ("test_buffer_draws_surrogates_as_replacement", agent l_t33.test_buffer_draws_surrogates_as_replacement)
			run_test ("test_buffer_replaces_values_above_u10ffff", agent l_t33.test_buffer_replaces_values_above_u10ffff)
			run_test ("test_put_char_replaces_surrogate", agent l_t33.test_put_char_replaces_surrogate)
			run_test ("test_surrogate_keeps_its_combining_mark", agent l_t33.test_surrogate_keeps_its_combining_mark)
			run_test ("test_line_spans_stay_in_place", agent l_t33.test_line_spans_stay_in_place)
			run_test ("test_cell_setters_replace_non_scalar_values", agent l_t33.test_cell_setters_replace_non_scalar_values)
			run_test ("test_frame_is_valid_utf_8", agent l_t33.test_frame_is_valid_utf_8)
			run_test ("test_frames_with_mixed_text_are_valid_utf_8", agent l_t33.test_frames_with_mixed_text_are_valid_utf_8)

			print ("============================================================%N")
			print ("  Running EiffelTUI UTF-8 Input Test Suite...%N")
			print ("============================================================%N")
			create l_t34
			run_test ("test_well_formed_boundaries", agent l_t34.test_well_formed_boundaries)
			run_test ("test_unicode_table_3_8_example", agent l_t34.test_unicode_table_3_8_example)
			run_test ("test_overlongs_rejected", agent l_t34.test_overlongs_rejected)
			run_test ("test_surrogates_rejected", agent l_t34.test_surrogates_rejected)
			run_test ("test_above_u10ffff_rejected", agent l_t34.test_above_u10ffff_rejected)
			run_test ("test_stray_continuation_bytes", agent l_t34.test_stray_continuation_bytes)
			run_test ("test_truncated_sequences", agent l_t34.test_truncated_sequences)
			run_test ("test_decoded_code_points", agent l_t34.test_decoded_code_points)
			run_test ("test_overlong_esc_does_not_end_paste", agent l_t34.test_overlong_esc_does_not_end_paste)
			run_test ("test_paste_keeps_character_split_by_pause", agent l_t34.test_paste_keeps_character_split_by_pause)
			run_test ("test_paste_watchdog_replaces_unfinished_character", agent l_t34.test_paste_watchdog_replaces_unfinished_character)

			print ("============================================================%N")
			print ("  Running EiffelTUI Serializer Re-anchoring Test Suite...%N")
			print ("============================================================%N")
			create l_t35
			run_test ("test_narrow_text_has_one_move", agent l_t35.test_narrow_text_has_one_move)
			run_test ("test_move_after_wide_cell", agent l_t35.test_move_after_wide_cell)
			run_test ("test_move_after_multi_code_point_cluster", agent l_t35.test_move_after_multi_code_point_cluster)
			run_test ("test_no_move_after_last_cell", agent l_t35.test_no_move_after_last_cell)
			run_test ("test_moves_use_the_offset", agent l_t35.test_moves_use_the_offset)
			run_test ("test_text_after_zwj_sequence_lands_in_place", agent l_t35.test_text_after_zwj_sequence_lands_in_place)
			run_test ("test_diff_keeps_the_row_in_place", agent l_t35.test_diff_keeps_the_row_in_place)
			run_test ("test_move_after_forced_width_cell", agent l_t35.test_move_after_forced_width_cell)
			run_test ("test_cursor_after_forced_width_on_virtual_terminal", agent l_t35.test_cursor_after_forced_width_on_virtual_terminal)
			run_test ("test_hyperlink_cells_keep_their_columns", agent l_t35.test_hyperlink_cells_keep_their_columns)
			run_test ("test_continuation_at_span_start", agent l_t35.test_continuation_at_span_start)

			print ("============================================================%N")
			print ("  Running EiffelTUI Text Input Edge Case Test Suite...%N")
			print ("============================================================%N")
			create l_t36
			run_test ("test_single_line_text", agent l_t36.test_single_line_text)
			run_test ("test_paste_is_single_line", agent l_t36.test_paste_is_single_line)
			run_test ("test_typed_controls", agent l_t36.test_typed_controls)
			run_test ("test_set_value_is_single_line", agent l_t36.test_set_value_is_single_line)
			run_test ("test_insert_regional_indicator_before_flag", agent l_t36.test_insert_regional_indicator_before_flag)
			run_test ("test_insert_before_combining_mark", agent l_t36.test_insert_before_combining_mark)
			run_test ("test_insert_zwj_between_emoji", agent l_t36.test_insert_zwj_between_emoji)
			run_test ("test_backspace_regroups_flags", agent l_t36.test_backspace_regroups_flags)
			run_test ("test_delete_regroups_flags", agent l_t36.test_delete_regroups_flags)
			run_test ("test_typing_keeps_cursor_on_boundaries", agent l_t36.test_typing_keeps_cursor_on_boundaries)
			run_test ("test_cursor_on_zero_width_cluster_keeps_next_character", agent l_t36.test_cursor_on_zero_width_cluster_keeps_next_character)
			run_test ("test_cursor_at_end_is_blank_cell", agent l_t36.test_cursor_at_end_is_blank_cell)

			print ("============================================================%N")
			print ("  Running EiffelTUI Frame Output Test Suite...%N")
			print ("============================================================%N")
			create l_t37
			run_test ("test_frame_buffer_reused", agent l_t37.test_frame_buffer_reused)
			run_test ("test_cursor_after_frame", agent l_t37.test_cursor_after_frame)
			run_test ("test_cursor_after_zwj_sequence", agent l_t37.test_cursor_after_zwj_sequence)
			run_test ("test_cursor_at_right_edge", agent l_t37.test_cursor_at_right_edge)
			run_test ("test_empty_frame_keeps_cursor", agent l_t37.test_empty_frame_keeps_cursor)
			run_test ("test_put_frame_does_not_scan", agent l_t37.test_put_frame_does_not_scan)
			run_test ("test_put_string_still_tracks", agent l_t37.test_put_string_still_tracks)

			print ("============================================================%N")
			print ("  Running EiffelTUI Block Shadow Test Suite (P1 V6)...%N")
			print ("============================================================%N")
			create l_t48
			run_test ("test_ratatui_overlay_renders_style_without_changing_symbols", agent l_t48.test_ratatui_overlay_renders_style_without_changing_symbols)
			run_test ("test_ratatui_symbol_filters_fill_only_visible_shadow_cells", agent l_t48.test_ratatui_symbol_filters_fill_only_visible_shadow_cells)
			run_test ("test_ratatui_render_is_clipped_to_buffer", agent l_t48.test_ratatui_render_is_clipped_to_buffer)
			run_test ("test_ratatui_custom_filter_is_applied", agent l_t48.test_ratatui_custom_filter_is_applied)
			run_test ("test_ratatui_dimmed_filter_dims_background", agent l_t48.test_ratatui_dimmed_filter_dims_background)
			run_test ("test_shadow_negative_offset", agent l_t48.test_shadow_negative_offset)
			run_test ("test_block_with_shadow", agent l_t48.test_block_with_shadow)
			run_test ("test_block_shadow_equality_and_copy", agent l_t48.test_block_shadow_equality_and_copy)
			run_test ("test_shadow_refuses_wide_symbol", agent l_t48.test_shadow_refuses_wide_symbol)
			run_test ("test_shadow_over_wide_characters", agent l_t48.test_shadow_over_wide_characters)
			run_test ("test_popup_with_shadow_over_list", agent l_t48.test_popup_with_shadow_over_list)
			run_test ("test_popup_shadow_hit_testing", agent l_t48.test_popup_shadow_hit_testing)

			print ("============================================================%N")
			print ("  Running EiffelTUI Fill Widget Test Suite (P1 V7)...%N")
			print ("============================================================%N")
			create l_t49
			run_test ("test_ratatui_fills_area_with_symbol_and_style", agent l_t49.test_ratatui_fills_area_with_symbol_and_style)
			run_test ("test_ratatui_clips_area_to_buffer", agent l_t49.test_ratatui_clips_area_to_buffer)
			run_test ("test_ratatui_render_fully_out_of_bounds_is_noop", agent l_t49.test_ratatui_render_fully_out_of_bounds_is_noop)
			run_test ("test_ratatui_renders_with_offset_buffer_area", agent l_t49.test_ratatui_renders_with_offset_buffer_area)
			run_test ("test_ratatui_stylize_shorthand_works", agent l_t49.test_ratatui_stylize_shorthand_works)
			run_test ("test_ratatui_accepts_owned_string_symbol", agent l_t49.test_ratatui_accepts_owned_string_symbol)
			run_test ("test_ratatui_symbol_setter_replaces_symbol", agent l_t49.test_ratatui_symbol_setter_replaces_symbol)
			run_test ("test_ratatui_new_panics_on_empty_symbol", agent l_t49.test_ratatui_new_panics_on_empty_symbol)
			run_test ("test_ratatui_default_is_noop", agent l_t49.test_ratatui_default_is_noop)
			run_test ("test_fill_symbol_validity", agent l_t49.test_fill_symbol_validity)
			run_test ("test_fill_cluster_symbol", agent l_t49.test_fill_cluster_symbol)
			run_test ("test_fill_wide_symbol", agent l_t49.test_fill_wide_symbol)
			run_test ("test_fill_patches_cell_style", agent l_t49.test_fill_patches_cell_style)
			run_test ("test_fill_over_wide_characters", agent l_t49.test_fill_over_wide_characters)
			run_test ("test_fill_equality_and_copy", agent l_t49.test_fill_equality_and_copy)

			print ("============================================================%N")
			print ("  Running EiffelTUI Sparkline Test Suite (P1 V9)...%N")
			print ("============================================================%N")
			create l_t50
			run_test ("test_ratatui_it_can_be_created_from_values", agent l_t50.test_ratatui_it_can_be_created_from_values)
			run_test ("test_ratatui_it_does_not_panic_if_max_is_zero", agent l_t50.test_ratatui_it_does_not_panic_if_max_is_zero)
			run_test ("test_ratatui_it_does_not_panic_if_max_is_set_to_zero", agent l_t50.test_ratatui_it_does_not_panic_if_max_is_set_to_zero)
			run_test ("test_ratatui_it_draws", agent l_t50.test_ratatui_it_draws)
			run_test ("test_ratatui_it_draws_double_height", agent l_t50.test_ratatui_it_draws_double_height)
			run_test ("test_ratatui_render_handles_u64_max_value", agent l_t50.test_ratatui_render_handles_u64_max_value)
			run_test ("test_ratatui_render_keeps_integer_precision_for_large_values", agent l_t50.test_ratatui_render_keeps_integer_precision_for_large_values)
			run_test ("test_ratatui_it_renders_right_to_left", agent l_t50.test_ratatui_it_renders_right_to_left)
			run_test ("test_ratatui_it_renders_with_absent_value_style", agent l_t50.test_ratatui_it_renders_with_absent_value_style)
			run_test ("test_ratatui_it_renders_with_absent_value_style_double_height", agent l_t50.test_ratatui_it_renders_with_absent_value_style_double_height)
			run_test ("test_ratatui_it_renders_with_custom_absent_value_style", agent l_t50.test_ratatui_it_renders_with_custom_absent_value_style)
			run_test ("test_ratatui_it_renders_with_custom_bar_styles", agent l_t50.test_ratatui_it_renders_with_custom_bar_styles)
			run_test ("test_ratatui_render_in_minimal_buffer", agent l_t50.test_ratatui_render_in_minimal_buffer)
			run_test ("test_ratatui_marker_setter", agent l_t50.test_ratatui_marker_setter)
			run_test ("test_ratatui_it_renders_braille", agent l_t50.test_ratatui_it_renders_braille)
			run_test ("test_ratatui_it_renders_braille_double_height", agent l_t50.test_ratatui_it_renders_braille_double_height)
			run_test ("test_ratatui_it_renders_braille_right_to_left", agent l_t50.test_ratatui_it_renders_braille_right_to_left)
			run_test ("test_ratatui_it_renders_braille_with_absent_values", agent l_t50.test_ratatui_it_renders_braille_with_absent_values)
			run_test ("test_ratatui_braille_uses_right_sample_style_when_styles_differ", agent l_t50.test_ratatui_braille_uses_right_sample_style_when_styles_differ)
			run_test ("test_ratatui_braille_uses_base_style_when_right_sample_has_no_custom_style", agent l_t50.test_ratatui_braille_uses_base_style_when_right_sample_has_no_custom_style)
			run_test ("test_ratatui_braille_renders_lone_absent_value", agent l_t50.test_ratatui_braille_renders_lone_absent_value)
			run_test ("test_ratatui_braille_renders_absent_pair_right_to_left", agent l_t50.test_ratatui_braille_renders_absent_pair_right_to_left)
			run_test ("test_ratatui_braille_applies_absent_style_with_default_blank_symbol", agent l_t50.test_ratatui_braille_applies_absent_style_with_default_blank_symbol)
			run_test ("test_ratatui_braille_absent_sample_does_not_override_visible_sample", agent l_t50.test_ratatui_braille_absent_sample_does_not_override_visible_sample)
			run_test ("test_ratatui_braille_renders_mixed_pair_right_to_left", agent l_t50.test_ratatui_braille_renders_mixed_pair_right_to_left)
			run_test ("test_ratatui_braille_render_direction_is_symmetric", agent l_t50.test_ratatui_braille_render_direction_is_symmetric)
			run_test ("test_ratatui_double_width_marker_renders_multiple_rows", agent l_t50.test_ratatui_double_width_marker_renders_multiple_rows)
			run_test ("test_ratatui_braille_handles_max_extremes", agent l_t50.test_ratatui_braille_handles_max_extremes)
			run_test ("test_ratatui_it_renders_quadrant", agent l_t50.test_ratatui_it_renders_quadrant)
			run_test ("test_ratatui_it_renders_sextant", agent l_t50.test_ratatui_it_renders_sextant)
			run_test ("test_ratatui_it_renders_octant", agent l_t50.test_ratatui_it_renders_octant)
			run_test ("test_ratatui_it_renders_half_block", agent l_t50.test_ratatui_it_renders_half_block)
			run_test ("test_ratatui_it_renders_block_dot_and_custom", agent l_t50.test_ratatui_it_renders_block_dot_and_custom)
			run_test ("test_sparkline_bar_value_and_style", agent l_t50.test_sparkline_bar_value_and_style)
			run_test ("test_sparkline_absent_bars_ignored_by_max", agent l_t50.test_sparkline_absent_bars_ignored_by_max)
			run_test ("test_sparkline_values_is_a_copy", agent l_t50.test_sparkline_values_is_a_copy)
			run_test ("test_sparkline_style_layers", agent l_t50.test_sparkline_style_layers)
			run_test ("test_sparkline_markers_with_blocks_and_clipping", agent l_t50.test_sparkline_markers_with_blocks_and_clipping)
			run_test ("test_sparkline_scaled_ticks", agent l_t50.test_sparkline_scaled_ticks)
			run_test ("test_sparkline_equality_and_copy", agent l_t50.test_sparkline_equality_and_copy)
			run_test ("test_sparkline_preconditions", agent l_t50.test_sparkline_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Table Scrolling Test Suite (P1 V10)...%N")
			print ("============================================================%N")
			create l_t51
			run_test ("test_ratatui_highlight_spacing_excess_area", agent l_t51.test_ratatui_highlight_spacing_excess_area)
			run_test ("test_ratatui_highlight_spacing_insufficient_area", agent l_t51.test_ratatui_highlight_spacing_insufficient_area)
			run_test ("test_ratatui_render_with_selection_and_offset", agent l_t51.test_ratatui_render_with_selection_and_offset)
			run_test ("test_ratatui_scroll_padding_with_padding", agent l_t51.test_ratatui_scroll_padding_with_padding)
			run_test ("test_ratatui_scroll_padding_render", agent l_t51.test_ratatui_scroll_padding_render)
			run_test ("test_ratatui_scroll_padding_flicker", agent l_t51.test_ratatui_scroll_padding_flicker)
			run_test ("test_ratatui_scroll_padding_row_heights_and_margins", agent l_t51.test_ratatui_scroll_padding_row_heights_and_margins)
			run_test ("test_ratatui_table_state_scroll_by", agent l_t51.test_ratatui_table_state_scroll_by)
			run_test ("test_ratatui_list_state_scroll_by", agent l_t51.test_ratatui_list_state_scroll_by)
			run_test ("test_table_scrolls_by_lines", agent l_t51.test_table_scrolls_by_lines)
			run_test ("test_table_padding_with_header_symbol_and_column_selection", agent l_t51.test_table_padding_with_header_symbol_and_column_selection)
			run_test ("test_table_offset_kept_near_end", agent l_t51.test_table_offset_kept_near_end)
			run_test ("test_row_viewport_arithmetic", agent l_t51.test_row_viewport_arithmetic)
			run_test ("test_row_viewport_matches_reference", agent l_t51.test_row_viewport_matches_reference)
			run_test ("test_row_viewport_cost_does_not_grow_with_rows", agent l_t51.test_row_viewport_cost_does_not_grow_with_rows)
			run_test ("test_table_spacing_and_padding_equality_and_copy", agent l_t51.test_table_spacing_and_padding_equality_and_copy)
			run_test ("test_table_preconditions", agent l_t51.test_table_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Text Alignment Test Suite (P1 V11)...%N")
			print ("============================================================%N")
			create l_t52
			run_test ("test_ratatui_line_alignment", agent l_t52.test_ratatui_line_alignment)
			run_test ("test_ratatui_line_left_aligned_centered_right_aligned", agent l_t52.test_ratatui_line_left_aligned_centered_right_aligned)
			run_test ("test_ratatui_line_render_aligned", agent l_t52.test_ratatui_line_render_aligned)
			run_test ("test_ratatui_text_left_aligned_centered_right_aligned", agent l_t52.test_ratatui_text_left_aligned_centered_right_aligned)
			run_test ("test_ratatui_text_render_aligned", agent l_t52.test_ratatui_text_render_aligned)
			run_test ("test_ratatui_text_render_one_line_right", agent l_t52.test_ratatui_text_render_one_line_right)
			run_test ("test_ratatui_paragraph_left_aligned_centered_right_aligned", agent l_t52.test_ratatui_paragraph_left_aligned_centered_right_aligned)
			run_test ("test_ratatui_paragraph_inherit_text_alignment", agent l_t52.test_ratatui_paragraph_inherit_text_alignment)
			run_test ("test_ratatui_paragraph_inherit_text_alignment_renders", agent l_t52.test_ratatui_paragraph_inherit_text_alignment_renders)
			run_test ("test_ratatui_paragraph_with_alignment", agent l_t52.test_ratatui_paragraph_with_alignment)
			run_test ("test_ratatui_widgets_paragraph_can_align_spans", agent l_t52.test_ratatui_widgets_paragraph_can_align_spans)
			run_test ("test_ratatui_widgets_paragraph_works_with_padding_centred_line", agent l_t52.test_ratatui_widgets_paragraph_works_with_padding_centred_line)
			run_test ("test_paragraph_alignment_precedence", agent l_t52.test_paragraph_alignment_precedence)
			run_test ("test_paragraph_alignment_follows_text", agent l_t52.test_paragraph_alignment_follows_text)
			run_test ("test_wrapped_lines_keep_alignment_state", agent l_t52.test_wrapped_lines_keep_alignment_state)
			run_test ("test_alignment_equality_and_copy", agent l_t52.test_alignment_equality_and_copy)
			run_test ("test_alignment_preconditions", agent l_t52.test_alignment_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Gauge vs Ratatui Test Suite (gauge background fix)...%N")
			print ("============================================================%N")
			create l_t53
			run_test ("test_ratatui_gauge_renders", agent l_t53.test_ratatui_gauge_renders)
			run_test ("test_ratatui_gauge_renders_no_unicode", agent l_t53.test_ratatui_gauge_renders_no_unicode)
			run_test ("test_ratatui_gauge_applies_styles", agent l_t53.test_ratatui_gauge_applies_styles)
			run_test ("test_ratatui_gauge_fills_cell_immediately_after_label", agent l_t53.test_ratatui_gauge_fills_cell_immediately_after_label)
			run_test ("test_ratatui_gauge_supports_large_labels", agent l_t53.test_ratatui_gauge_supports_large_labels)
			run_test ("test_gauge_unfilled_part_takes_gauge_background", agent l_t53.test_gauge_unfilled_part_takes_gauge_background)
			run_test ("test_gauge_default_label_is_bold", agent l_t53.test_gauge_default_label_is_bold)
			run_test ("test_gauge_without_background_keeps_cell_background", agent l_t53.test_gauge_without_background_keeps_cell_background)

			print ("============================================================%N")
			print ("  Running EiffelTUI Theme Test Suite (P2 B1, C3)...%N")
			print ("============================================================%N")
			create l_t57
			run_test ("test_presets_are_not_shared", agent l_t57.test_presets_are_not_shared)
			run_test ("test_presets_differ", agent l_t57.test_presets_differ)
			run_test ("test_preset_foregrounds_show_on_the_background", agent l_t57.test_preset_foregrounds_show_on_the_background)

			print ("============================================================%N")
			print ("  Running EiffelTUI Color From String Test Suite (P2 C1)...%N")
			print ("============================================================%N")
			create l_t58
			run_test ("test_ratatui_from_rgb_color", agent l_t58.test_ratatui_from_rgb_color)
			run_test ("test_ratatui_from_indexed_color", agent l_t58.test_ratatui_from_indexed_color)
			run_test ("test_ratatui_from_ansi_color", agent l_t58.test_ratatui_from_ansi_color)
			run_test ("test_ratatui_from_invalid_colors", agent l_t58.test_ratatui_from_invalid_colors)
			run_test ("test_ratatui_display", agent l_t58.test_ratatui_display)
			run_test ("test_ratatui_deserialize", agent l_t58.test_ratatui_deserialize)
			run_test ("test_ratatui_serialize_then_deserialize", agent l_t58.test_ratatui_serialize_then_deserialize)
			run_test ("test_color_name_trap", agent l_t58.test_color_name_trap)
			run_test ("test_color_string_edges", agent l_t58.test_color_string_edges)
			run_test ("test_color_string_round_trip", agent l_t58.test_color_string_round_trip)
			run_test ("test_make_from_string_precondition", agent l_t58.test_make_from_string_precondition)

			print ("============================================================%N")
			print ("  Running EiffelTUI TOML Subset Test Suite (P2 Q1)...%N")
			print ("============================================================%N")
			create l_t71
			run_test ("test_reads_theme_sections", agent l_t71.test_reads_theme_sections)
			run_test ("test_comments_blank_lines_and_whitespace", agent l_t71.test_comments_blank_lines_and_whitespace)
			run_test ("test_reads_strings_and_escapes", agent l_t71.test_reads_strings_and_escapes)
			run_test ("test_keys_are_bare_and_exact", agent l_t71.test_keys_are_bare_and_exact)
			run_test ("test_structure_errors", agent l_t71.test_structure_errors)
			run_test ("test_value_errors", agent l_t71.test_value_errors)
			run_test ("test_string_errors", agent l_t71.test_string_errors)
			run_test ("test_duplicate_errors", agent l_t71.test_duplicate_errors)
			run_test ("test_error_line_numbers", agent l_t71.test_error_line_numbers)
			run_test ("test_failed_read_has_no_document", agent l_t71.test_failed_read_has_no_document)
			run_test ("test_writer_output", agent l_t71.test_writer_output)
			run_test ("test_writer_escapes", agent l_t71.test_writer_escapes)
			run_test ("test_escaping_round_trip", agent l_t71.test_escaping_round_trip)
			run_test ("test_read_write_read", agent l_t71.test_read_write_read)
			run_test ("test_document_equality_is_ordered", agent l_t71.test_document_equality_is_ordered)
			run_test ("test_values_are_immutable", agent l_t71.test_values_are_immutable)
			run_test ("test_preconditions", agent l_t71.test_preconditions)
			run_test ("test_lines_are_recorded", agent l_t71.test_lines_are_recorded)

			print ("============================================================%N")
			print ("  Running EiffelTUI Style Text Test Suite (P2 C2)...%N")
			print ("============================================================%N")
			create l_t72
			run_test ("test_reads_theme_style", agent l_t72.test_reads_theme_style)
			run_test ("test_reads_section_from_document", agent l_t72.test_reads_section_from_document)
			run_test ("test_modifier_names", agent l_t72.test_modifier_names)
			run_test ("test_remove_modifiers_patch", agent l_t72.test_remove_modifiers_patch)
			run_test ("test_printed_text", agent l_t72.test_printed_text)
			run_test ("test_round_trip_every_flag", agent l_t72.test_round_trip_every_flag)
			run_test ("test_round_trip_every_color_kind", agent l_t72.test_round_trip_every_color_kind)
			run_test ("test_empty_style", agent l_t72.test_empty_style)
			run_test ("test_section_round_trip_through_file_format", agent l_t72.test_section_round_trip_through_file_format)
			run_test ("test_unknown_field_error", agent l_t72.test_unknown_field_error)
			run_test ("test_unknown_modifier_error", agent l_t72.test_unknown_modifier_error)
			run_test ("test_bad_color_error", agent l_t72.test_bad_color_error)
			run_test ("test_wrong_value_type_error", agent l_t72.test_wrong_value_type_error)
			run_test ("test_modifier_in_both_lists_error", agent l_t72.test_modifier_in_both_lists_error)
			run_test ("test_ratatui_serde_keys", agent l_t72.test_ratatui_serde_keys)
			run_test ("test_rapid_blink_sgr", agent l_t72.test_rapid_blink_sgr)
			run_test ("test_format_error_position", agent l_t72.test_format_error_position)
			run_test ("test_section_error_without_lines", agent l_t72.test_section_error_without_lines)
			run_test ("test_failed_read_has_no_style", agent l_t72.test_failed_read_has_no_style)
			run_test ("test_preconditions", agent l_t72.test_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Theme File Test Suite (P2 C3)...%N")
			print ("============================================================%N")
			create l_t73
			run_test ("test_dark_text", agent l_t73.test_dark_text)
			run_test ("test_round_trip_presets", agent l_t73.test_round_trip_presets)
			run_test ("test_round_trip_presets_through_files", agent l_t73.test_round_trip_presets_through_files)
			run_test ("test_round_trip_custom_theme", agent l_t73.test_round_trip_custom_theme)
			run_test ("test_shipped_preset_files_match", agent l_t73.test_shipped_preset_files_match)
			run_test ("test_partial_file_keeps_other_sections", agent l_t73.test_partial_file_keeps_other_sections)
			run_test ("test_present_section_replaces_default", agent l_t73.test_present_section_replaces_default)
			run_test ("test_comments_and_blank_lines_skipped", agent l_t73.test_comments_and_blank_lines_skipped)
			run_test ("test_unknown_section_error", agent l_t73.test_unknown_section_error)
			run_test ("test_format_error_line", agent l_t73.test_format_error_line)
			run_test ("test_style_error_lines", agent l_t73.test_style_error_lines)
			run_test ("test_failed_load_leaves_no_theme", agent l_t73.test_failed_load_leaves_no_theme)
			run_test ("test_missing_file", agent l_t73.test_missing_file)
			run_test ("test_save_errors", agent l_t73.test_save_errors)
			run_test ("test_save_keeps_old_file_on_failure", agent l_t73.test_save_keeps_old_file_on_failure)
			run_test ("test_utf_8_files", agent l_t73.test_utf_8_files)
			run_test ("test_bom_in_text_is_an_error", agent l_t73.test_bom_in_text_is_an_error)
			run_test ("test_section_names", agent l_t73.test_section_names)
			run_test ("test_settings_example", agent l_t73.test_settings_example)

			print ("============================================================%N")
			print ("  Running EiffelTUI Async Worker Test Suite (P2 B2)...%N")
			print ("============================================================%N")
			create l_t74
			run_test ("test_quit_during_fetch_joins_worker", agent l_t74.test_quit_during_fetch_joins_worker)
			run_test ("test_stale_fetch_result_dropped", agent l_t74.test_stale_fetch_result_dropped)
			run_test ("test_refresh_stops_older_worker", agent l_t74.test_refresh_stops_older_worker)
			run_test ("test_quit_gives_up_after_join_timeout", agent l_t74.test_quit_gives_up_after_join_timeout)
			run_test ("test_termination_request_during_fetch", agent l_t74.test_termination_request_during_fetch)
			run_test ("test_background_work_stopped_on_every_exit", agent l_t74.test_background_work_stopped_on_every_exit)
			run_test ("test_background_work_stopped_on_exception", agent l_t74.test_background_work_stopped_on_exception)
			run_test ("test_background_work_stopped_on_termination_request", agent l_t74.test_background_work_stopped_on_termination_request)
			run_test ("test_background_work_failure_dropped", agent l_t74.test_background_work_failure_dropped)

			print ("============================================================%N")
			print ("  Running EiffelTUI Async Scan Test Suite (P2 A1)...%N")
			print ("============================================================%N")
			create l_t75
			run_test ("test_scanner_finds_largest", agent l_t75.test_scanner_finds_largest)
			run_test ("test_scanner_cancel_and_errors", agent l_t75.test_scanner_cancel_and_errors)
			run_test ("test_unreadable_directory_posix", agent l_t75.test_unreadable_directory_posix)
			run_test ("test_unreadable_directory_windows", agent l_t75.test_unreadable_directory_windows)
			run_test ("test_size_above_4_gib", agent l_t75.test_size_above_4_gib)
			run_test ("test_links_not_followed", agent l_t75.test_links_not_followed)
			run_test ("test_size_text", agent l_t75.test_size_text)
			run_test ("test_batch_scan_snapshot", agent l_t75.test_batch_scan_snapshot)
			run_test ("test_missing_path_is_error", agent l_t75.test_missing_path_is_error)
			run_test ("test_progress_at_most_every_50_ms", agent l_t75.test_progress_at_most_every_50_ms)
			run_test ("test_cancel_during_scan", agent l_t75.test_cancel_during_scan)
			run_test ("test_refresh_drops_old_result", agent l_t75.test_refresh_drops_old_result)
			run_test ("test_batch_gives_up_after_limit", agent l_t75.test_batch_gives_up_after_limit)
			run_test ("test_quit_during_scan_joins_worker", agent l_t75.test_quit_during_scan_joins_worker)
			run_test ("test_quit_gives_up_after_join_timeout", agent l_t75.test_quit_gives_up_after_join_timeout)

			print ("============================================================%N")
			print ("  Running EiffelTUI Cursor Shape Test Suite (P2 T1)...%N")
			print ("============================================================%N")
			create l_t59
			run_test ("test_cursor_shape_values", agent l_t59.test_cursor_shape_values)
			run_test ("test_ansi_backend_writes_decscusr", agent l_t59.test_ansi_backend_writes_decscusr)
			run_test ("test_virtual_terminal_records_shape", agent l_t59.test_virtual_terminal_records_shape)
			run_test ("test_draw_writes_shape_when_it_changes", agent l_t59.test_draw_writes_shape_when_it_changes)
			run_test ("test_forget_writes_shape_again", agent l_t59.test_forget_writes_shape_again)
			run_test ("test_reset_cursor_shape", agent l_t59.test_reset_cursor_shape)
			run_test ("test_restore_after_bar_writes_default", agent l_t59.test_restore_after_bar_writes_default)
			run_test ("test_restore_after_default_writes_nothing", agent l_t59.test_restore_after_default_writes_nothing)
			run_test ("test_text_widgets_ask_for_a_bar", agent l_t59.test_text_widgets_ask_for_a_bar)
			run_test ("test_frame_shape_defaults_per_frame", agent l_t59.test_frame_shape_defaults_per_frame)

			print ("============================================================%N")
			print ("  Running EiffelTUI Window Title Test Suite (P2 T2)...%N")
			print ("============================================================%N")
			create l_t60
			run_test ("test_sanitized_drops_controls", agent l_t60.test_sanitized_drops_controls)
			run_test ("test_ansi_backend_writes_plain_title", agent l_t60.test_ansi_backend_writes_plain_title)
			run_test ("test_ansi_backend_writes_utf8_title", agent l_t60.test_ansi_backend_writes_utf8_title)
			run_test ("test_backend_refuses_unsanitized_title", agent l_t60.test_backend_refuses_unsanitized_title)
			run_test ("test_virtual_terminal_records_title", agent l_t60.test_virtual_terminal_records_title)
			run_test ("test_terminal_title_is_sanitized", agent l_t60.test_terminal_title_is_sanitized)
			run_test ("test_terminal_pushes_once", agent l_t60.test_terminal_pushes_once)
			run_test ("test_app_title_before_run_writes_nothing", agent l_t60.test_app_title_before_run_writes_nothing)
			run_test ("test_app_pushes_once_per_run_and_pops", agent l_t60.test_app_pushes_once_per_run_and_pops)
			run_test ("test_app_without_title_writes_none", agent l_t60.test_app_without_title_writes_none)

			print ("============================================================%N")
			print ("  Running EiffelTUI Clipboard Test Suite (P2 T3)...%N")
			print ("============================================================%N")
			create l_t61
			run_test ("test_base64_rfc4648_vectors", agent l_t61.test_base64_rfc4648_vectors)
			run_test ("test_base64_high_bytes_and_utf_8", agent l_t61.test_base64_high_bytes_and_utf_8)
			run_test ("test_base64_decodes_rfc4648_vectors", agent l_t61.test_base64_decodes_rfc4648_vectors)
			run_test ("test_base64_round_trips", agent l_t61.test_base64_round_trips)
			run_test ("test_base64_rejects_invalid", agent l_t61.test_base64_rejects_invalid)
			run_test ("test_base64_utf_8_replacement", agent l_t61.test_base64_utf_8_replacement)
			run_test ("test_ansi_backend_writes_osc52", agent l_t61.test_ansi_backend_writes_osc52)
			run_test ("test_virtual_terminal_records_clipboard", agent l_t61.test_virtual_terminal_records_clipboard)
			run_test ("test_terminal_copies_both_targets", agent l_t61.test_terminal_copies_both_targets)
			run_test ("test_fits_in_clipboard_at_the_boundary", agent l_t61.test_fits_in_clipboard_at_the_boundary)
			run_test ("test_copy_over_the_limit_raises", agent l_t61.test_copy_over_the_limit_raises)
			run_test ("test_clipboard_prefix_keeps_graphemes", agent l_t61.test_clipboard_prefix_keeps_graphemes)
			run_test ("test_selected_text", agent l_t61.test_selected_text)
			run_test ("test_example_text_area_copies_selection", agent l_t61.test_example_text_area_copies_selection)
			run_test ("test_example_text_area_copy_without_selection", agent l_t61.test_example_text_area_copy_without_selection)
			run_test ("test_example_text_area_truncates_long_selection", agent l_t61.test_example_text_area_truncates_long_selection)
			run_test ("test_empty_copy_refused", agent l_t61.test_empty_copy_refused)
			run_test ("test_example_text_area_copies_nothing_when_nothing_fits", agent l_t61.test_example_text_area_copies_nothing_when_nothing_fits)

			print ("============================================================%N")
			print ("  Running EiffelTUI Keyboard Support Query Test Suite (P2 T4)...%N")
			print ("============================================================%N")
			create l_t62
			run_test ("test_parser_flags_reply", agent l_t62.test_parser_flags_reply)
			run_test ("test_parser_device_attributes", agent l_t62.test_parser_device_attributes)
			run_test ("test_parser_replies_split_and_among_keys", agent l_t62.test_parser_replies_split_and_among_keys)
			run_test ("test_query_writes_both_queries", agent l_t62.test_query_writes_both_queries)
			run_test ("test_query_flags_then_da1_is_supported", agent l_t62.test_query_flags_then_da1_is_supported)
			run_test ("test_query_da1_alone_is_unsupported", agent l_t62.test_query_da1_alone_is_unsupported)
			run_test ("test_query_no_reply_is_unknown", agent l_t62.test_query_no_reply_is_unknown)
			run_test ("test_query_flags_without_da1", agent l_t62.test_query_flags_without_da1)
			run_test ("test_query_keeps_keys_before_replies", agent l_t62.test_query_keeps_keys_before_replies)
			run_test ("test_query_keeps_lone_escape", agent l_t62.test_query_keeps_lone_escape)
			run_test ("test_query_refused_while_input_in_use", agent l_t62.test_query_refused_while_input_in_use)
			run_test ("test_app_asks_once_and_pushes_when_supported", agent l_t62.test_app_asks_once_and_pushes_when_supported)
			run_test ("test_app_unsupported_does_not_push", agent l_t62.test_app_unsupported_does_not_push)
			run_test ("test_app_no_reply_is_unknown", agent l_t62.test_app_no_reply_is_unknown)
			run_test ("test_app_not_requested_asks_nothing", agent l_t62.test_app_not_requested_asks_nothing)
			run_test ("test_app_not_asked_on_resume", agent l_t62.test_app_not_asked_on_resume)
			run_test ("test_app_background_start_asks_after_fg", agent l_t62.test_app_background_start_asks_after_fg)
			run_test ("test_app_driver_provided_enhancement_asks_nothing", agent l_t62.test_app_driver_provided_enhancement_asks_nothing)
			run_test ("test_app_late_replies_dropped", agent l_t62.test_app_late_replies_dropped)

			print ("============================================================%N")
			print ("  Running EiffelTUI Divider Test Suite (P2 W1)...%N")
			print ("============================================================%N")
			create l_t63
			run_test ("test_divider_line_sets", agent l_t63.test_divider_line_sets)
			run_test ("test_divider_label_alignments", agent l_t63.test_divider_label_alignments)
			run_test ("test_divider_label_clipped_and_dropped", agent l_t63.test_divider_label_clipped_and_dropped)
			run_test ("test_divider_wide_label_at_clipping_edge", agent l_t63.test_divider_wide_label_at_clipping_edge)
			run_test ("test_divider_zero_and_one_cell_areas", agent l_t63.test_divider_zero_and_one_cell_areas)
			run_test ("test_divider_over_wide_characters", agent l_t63.test_divider_over_wide_characters)
			run_test ("test_divider_patches_cell_style", agent l_t63.test_divider_patches_cell_style)
			run_test ("test_divider_builders_equality_and_copy", agent l_t63.test_divider_builders_equality_and_copy)
			run_test ("test_divider_preconditions", agent l_t63.test_divider_preconditions)

			print ("============================================================%N")
			print ("  Running EiffelTUI Checkbox Test Suite (P2 W2)...%N")
			print ("============================================================%N")
			create l_t64
			run_test ("test_checkbox_unchecked_and_checked", agent l_t64.test_checkbox_unchecked_and_checked)
			run_test ("test_checkbox_focused", agent l_t64.test_checkbox_focused)
			run_test ("test_checkbox_wide_label_at_clipping_edge", agent l_t64.test_checkbox_wide_label_at_clipping_edge)
			run_test ("test_checkbox_symbol_presets", agent l_t64.test_checkbox_symbol_presets)
			run_test ("test_checkbox_patches_cell_style", agent l_t64.test_checkbox_patches_cell_style)
			run_test ("test_checkbox_symbols_checked_and_aligned", agent l_t64.test_checkbox_symbols_checked_and_aligned)
			run_test ("test_checkbox_zero_size_areas", agent l_t64.test_checkbox_zero_size_areas)
			run_test ("test_checkbox_builders_equality_and_copy", agent l_t64.test_checkbox_builders_equality_and_copy)
			run_test ("test_checkbox_registers_its_hit_region", agent l_t64.test_checkbox_registers_its_hit_region)
			run_test ("test_checkbox_hit_test_fixed_viewport", agent l_t64.test_checkbox_hit_test_fixed_viewport)
			run_test ("test_checkbox_toggled_by_space_and_click", agent l_t64.test_checkbox_toggled_by_space_and_click)

			print ("============================================================%N")
			print ("  Running EiffelTUI Slider Test Suite (P2 W3)...%N")
			print ("============================================================%N")
			create l_t65
			run_test ("test_slider_state_clamp_and_snap", agent l_t65.test_slider_state_clamp_and_snap)
			run_test ("test_slider_state_large_ranges", agent l_t65.test_slider_state_large_ranges)
			run_test ("test_slider_state_empty_range", agent l_t65.test_slider_state_empty_range)
			run_test ("test_slider_set_from_position", agent l_t65.test_slider_set_from_position)
			run_test ("test_slider_track_cell_both_directions", agent l_t65.test_slider_track_cell_both_directions)
			run_test ("test_slider_horizontal_snapshots", agent l_t65.test_slider_horizontal_snapshots)
			run_test ("test_slider_vertical_snapshots", agent l_t65.test_slider_vertical_snapshots)
			run_test ("test_slider_focused_and_styles", agent l_t65.test_slider_focused_and_styles)
			run_test ("test_slider_zero_and_clipped_areas", agent l_t65.test_slider_zero_and_clipped_areas)
			run_test ("test_slider_track_does_not_move_with_the_value", agent l_t65.test_slider_track_does_not_move_with_the_value)
			run_test ("test_slider_builders_equality", agent l_t65.test_slider_builders_equality)
			run_test ("test_slider_registers_its_hit_region", agent l_t65.test_slider_registers_its_hit_region)
			run_test ("test_slider_click_and_drag", agent l_t65.test_slider_click_and_drag)

			print ("============================================================%N")
			print ("  Running EiffelTUI Form Controls Example Test Suite (P2 W1-W3)...%N")
			print ("============================================================%N")
			create l_t66
			run_test ("test_form_controls_example_snapshot", agent l_t66.test_form_controls_example_snapshot)
			run_test ("test_form_controls_example_mouse", agent l_t66.test_form_controls_example_mouse)

			print ("============================================================%N")
			print ("  Running EiffelTUI Menu Test Suite (P2 W4)...%N")
			print ("============================================================%N")
			create l_t67
			run_test ("test_menu_state_skips_separators_and_disabled", agent l_t67.test_menu_state_skips_separators_and_disabled)
			run_test ("test_menu_state_submenus", agent l_t67.test_menu_state_submenus)
			run_test ("test_menu_state_activate_and_chosen", agent l_t67.test_menu_state_activate_and_chosen)
			run_test ("test_menu_state_set_items_while_open", agent l_t67.test_menu_state_set_items_while_open)
			run_test ("test_menu_state_clicks", agent l_t67.test_menu_state_clicks)
			run_test ("test_menu_item_builders_and_equality", agent l_t67.test_menu_item_builders_and_equality)
			run_test ("test_overlay_placement", agent l_t67.test_overlay_placement)
			run_test ("test_menu_closed_bar", agent l_t67.test_menu_closed_bar)
			run_test ("test_menu_open_drop_down", agent l_t67.test_menu_open_drop_down)
			run_test ("test_menu_submenu_flips_at_right_edge", agent l_t67.test_menu_submenu_flips_at_right_edge)
			run_test ("test_menu_drop_down_at_bottom_edge", agent l_t67.test_menu_drop_down_at_bottom_edge)
			run_test ("test_menu_shortcuts_and_wide_labels", agent l_t67.test_menu_shortcuts_and_wide_labels)
			run_test ("test_menu_registers_hit_regions", agent l_t67.test_menu_registers_hit_regions)
			run_test ("test_menu_clicks_fixed_viewport", agent l_t67.test_menu_clicks_fixed_viewport)
			run_test ("test_menu_focus_scope_traps_tab", agent l_t67.test_menu_focus_scope_traps_tab)
			run_test ("test_menu_copy_does_not_take_the_scope", agent l_t67.test_menu_copy_does_not_take_the_scope)
			run_test ("test_menu_cut_drop_down_scrolls", agent l_t67.test_menu_cut_drop_down_scrolls)
			run_test ("test_menu_hits_safe_in_any_order", agent l_t67.test_menu_hits_safe_in_any_order)
			run_test ("test_menu_bar_scrolls_sideways", agent l_t67.test_menu_bar_scrolls_sideways)
			run_test ("test_menu_shadow_has_room", agent l_t67.test_menu_shadow_has_room)
			run_test ("test_menu_item_label_is_a_copy", agent l_t67.test_menu_item_label_is_a_copy)
			run_test ("test_menu_bar_example", agent l_t67.test_menu_bar_example)
			run_test ("test_menu_bar_quit_asks_first", agent l_t67.test_menu_bar_quit_asks_first)
			run_test ("test_menu_bar_q_asks_too", agent l_t67.test_menu_bar_q_asks_too)

			print ("============================================================%N")
			print ("  Running EiffelTUI Toast Test Suite (P2 W5)...%N")
			print ("============================================================%N")
			create l_t68
			run_test ("test_toast_queue_expiry_at_exact_duration", agent l_t68.test_toast_queue_expiry_at_exact_duration)
			run_test ("test_toast_queue_order", agent l_t68.test_toast_queue_order)
			run_test ("test_toast_queue_max_visible", agent l_t68.test_toast_queue_max_visible)
			run_test ("test_toast_queue_push_during_expire", agent l_t68.test_toast_queue_push_during_expire)
			run_test ("test_toast_queue_copy_and_preconditions", agent l_t68.test_toast_queue_copy_and_preconditions)
			run_test ("test_toast_queue_ids", agent l_t68.test_toast_queue_ids)
			run_test ("test_toast_hit_regions", agent l_t68.test_toast_hit_regions)
			run_test ("test_toast_line_alignment", agent l_t68.test_toast_line_alignment)
			run_test ("test_toast_each_position", agent l_t68.test_toast_each_position)
			run_test ("test_toast_long_text_wrapped", agent l_t68.test_toast_long_text_wrapped)
			run_test ("test_toast_wider_than_area", agent l_t68.test_toast_wider_than_area)
			run_test ("test_toast_styles_and_theme", agent l_t68.test_toast_styles_and_theme)
			run_test ("test_toast_render_without_queue_and_over_wide_characters", agent l_t68.test_toast_render_without_queue_and_over_wide_characters)
			run_test ("test_toast_builders_and_equality", agent l_t68.test_toast_builders_and_equality)
			run_test ("test_toasts_example", agent l_t68.test_toasts_example)

			print ("============================================================%N")
			print ("  Running EiffelTUI Mouse Motion Test Suite (P2 W6)...%N")
			print ("============================================================%N")
			create l_t69
			run_test ("test_motion_report_is_a_move", agent l_t69.test_motion_report_is_a_move)
			run_test ("test_motion_report_with_modifiers", agent l_t69.test_motion_report_with_modifiers)
			run_test ("test_drag_reports_unchanged", agent l_t69.test_drag_reports_unchanged)
			run_test ("test_motion_burst_coalesced", agent l_t69.test_motion_burst_coalesced)
			run_test ("test_ansi_backend_motion_sequences", agent l_t69.test_ansi_backend_motion_sequences)
			run_test ("test_leave_raw_mode_turns_motion_off_first", agent l_t69.test_leave_raw_mode_turns_motion_off_first)
			run_test ("test_virtual_terminal_records_motion", agent l_t69.test_virtual_terminal_records_motion)
			run_test ("test_app_motion_enable_and_disable", agent l_t69.test_app_motion_enable_and_disable)
			run_test ("test_app_motion_toggled_while_running", agent l_t69.test_app_motion_toggled_while_running)

			print ("============================================================%N")
			print ("  Running EiffelTUI Tooltip Test Suite (P2 W6)...%N")
			print ("============================================================%N")
			create l_t70
			run_test ("test_tooltip_placement_four_sides", agent l_t70.test_tooltip_placement_four_sides)
			run_test ("test_tooltip_flips_at_each_edge", agent l_t70.test_tooltip_flips_at_each_edge)
			run_test ("test_tooltip_corners_and_neither_side", agent l_t70.test_tooltip_corners_and_neither_side)
			run_test ("test_tooltip_cut_beside_anchor_wraps_again", agent l_t70.test_tooltip_cut_beside_anchor_wraps_again)
			run_test ("test_tooltip_short_text_snapshot", agent l_t70.test_tooltip_short_text_snapshot)
			run_test ("test_tooltip_wrapped_text_snapshot", agent l_t70.test_tooltip_wrapped_text_snapshot)
			run_test ("test_tooltip_bounds_and_buffer", agent l_t70.test_tooltip_bounds_and_buffer)
			run_test ("test_tooltip_builders_and_equality", agent l_t70.test_tooltip_builders_and_equality)
			run_test ("test_hover_state", agent l_t70.test_hover_state)
			run_test ("test_tooltip_hit_region", agent l_t70.test_tooltip_hit_region)
			run_test ("test_hover_state_tooltip_id", agent l_t70.test_hover_state_tooltip_id)
			run_test ("test_tooltips_example_focus", agent l_t70.test_tooltips_example_focus)
			run_test ("test_tooltips_example_hover", agent l_t70.test_tooltips_example_hover)

			print ("============================================================%N")
			print ("  Running EiffelTUI Button Test Suite (P2b U1)...%N")
			print ("============================================================%N")
			create l_t76
			run_test ("test_button_plain_focused_pressed", agent l_t76.test_button_plain_focused_pressed)
			run_test ("test_button_alignments", agent l_t76.test_button_alignments)
			run_test ("test_button_clipped_at_cluster_boundary", agent l_t76.test_button_clipped_at_cluster_boundary)
			run_test ("test_button_middle_row", agent l_t76.test_button_middle_row)
			run_test ("test_button_width", agent l_t76.test_button_width)
			run_test ("test_button_registers_its_hit_region", agent l_t76.test_button_registers_its_hit_region)
			run_test ("test_button_builders_equality_and_copy", agent l_t76.test_button_builders_equality_and_copy)
			run_test ("test_button_without_fill", agent l_t76.test_button_without_fill)
			print ("============================================================%N")
			print ("  Running EiffelTUI Dialog Test Suite (P2b U2)...%N")
			print ("============================================================%N")
			create l_t77
			run_test ("test_dialog_alert_snapshot", agent l_t77.test_dialog_alert_snapshot)
			run_test ("test_dialog_confirm_snapshot", agent l_t77.test_dialog_confirm_snapshot)
			run_test ("test_dialog_three_buttons_snapshot", agent l_t77.test_dialog_three_buttons_snapshot)
			run_test ("test_dialog_long_message_wrapped", agent l_t77.test_dialog_long_message_wrapped)
			run_test ("test_dialog_small_frames", agent l_t77.test_dialog_small_frames)
			run_test ("test_dialog_wide_characters", agent l_t77.test_dialog_wide_characters)
			run_test ("test_dialog_kinds_from_dark_theme", agent l_t77.test_dialog_kinds_from_dark_theme)
			run_test ("test_dialog_keys_move_and_wrap", agent l_t77.test_dialog_keys_move_and_wrap)
			run_test ("test_dialog_keys_answer", agent l_t77.test_dialog_keys_answer)
			run_test ("test_dialog_keys_first_letters", agent l_t77.test_dialog_keys_first_letters)
			run_test ("test_dialog_clicks_in_frame", agent l_t77.test_dialog_clicks_in_frame)
			run_test ("test_dialog_clicks_through_hit_test", agent l_t77.test_dialog_clicks_through_hit_test)
			run_test ("test_dialog_focus_scope", agent l_t77.test_dialog_focus_scope)
			run_test ("test_dialog_answered_action", agent l_t77.test_dialog_answered_action)
			run_test ("test_dialog_focus_follows_focus_manager", agent l_t77.test_dialog_focus_follows_focus_manager)
			run_test ("test_dialog_answer_count_and_ids", agent l_t77.test_dialog_answer_count_and_ids)
			run_test ("test_dialog_state_and_widget_values", agent l_t77.test_dialog_state_and_widget_values)
			print ("============================================================%N")
			print ("  Running EiffelTUI Breadcrumb Test Suite (P2b R1)...%N")
			print ("============================================================%N")
			create l_t78
			run_test ("test_breadcrumb_path_that_fits", agent l_t78.test_breadcrumb_path_that_fits)
			run_test ("test_breadcrumb_collapses_middle", agent l_t78.test_breadcrumb_collapses_middle)
			run_test ("test_breadcrumb_every_width", agent l_t78.test_breadcrumb_every_width)
			run_test ("test_breadcrumb_wide_and_combining", agent l_t78.test_breadcrumb_wide_and_combining)
			run_test ("test_breadcrumb_separator_presets", agent l_t78.test_breadcrumb_separator_presets)
			run_test ("test_breadcrumb_styles", agent l_t78.test_breadcrumb_styles)
			run_test ("test_breadcrumb_registers_visible_crumbs", agent l_t78.test_breadcrumb_registers_visible_crumbs)
			run_test ("test_breadcrumb_one_and_no_crumbs", agent l_t78.test_breadcrumb_one_and_no_crumbs)
			run_test ("test_breadcrumb_builders_equality_and_copy", agent l_t78.test_breadcrumb_builders_equality_and_copy)
			run_test ("test_breadcrumb_review_fixes", agent l_t78.test_breadcrumb_review_fixes)
			create l_t79
			run_test ("test_file_tree_example_snapshot", agent l_t79.test_file_tree_example_snapshot)
			run_test ("test_file_tree_breadcrumb_follows_tree", agent l_t79.test_file_tree_breadcrumb_follows_tree)
			run_test ("test_file_tree_crumb_click_and_backspace", agent l_t79.test_file_tree_crumb_click_and_backspace)
			run_test ("test_file_tree_alt_arrows_and_enter", agent l_t79.test_file_tree_alt_arrows_and_enter)
			run_test ("test_file_tree_narrow_frame", agent l_t79.test_file_tree_narrow_frame)
			run_test ("test_file_tree_example_scripted", agent l_t79.test_file_tree_example_scripted)
			print ("============================================================%N")
			print ("  Running EiffelTUI Clipboard Read Test Suite (P2b K2)...%N")
			print ("============================================================%N")
			create l_t80
			run_test ("test_reply_ended_by_bel", agent l_t80.test_reply_ended_by_bel)
			run_test ("test_reply_ended_by_st", agent l_t80.test_reply_ended_by_st)
			run_test ("test_reply_selections", agent l_t80.test_reply_selections)
			run_test ("test_reply_empty_and_query", agent l_t80.test_reply_empty_and_query)
			run_test ("test_reply_invalid_base64", agent l_t80.test_reply_invalid_base64)
			run_test ("test_reply_text_not_sanitised", agent l_t80.test_reply_text_not_sanitised)
			run_test ("test_reply_split_byte_by_byte", agent l_t80.test_reply_split_byte_by_byte)
			run_test ("test_reply_split_with_pauses", agent l_t80.test_reply_split_with_pauses)
			run_test ("test_reply_between_two_keys", agent l_t80.test_reply_between_two_keys)
			run_test ("test_alt_bracket_then_letter", agent l_t80.test_alt_bracket_then_letter)
			run_test ("test_alt_bracket_timeout", agent l_t80.test_alt_bracket_timeout)
			run_test ("test_alt_bracket_digit_then_letter", agent l_t80.test_alt_bracket_digit_then_letter)
			run_test ("test_other_osc_dropped", agent l_t80.test_other_osc_dropped)
			run_test ("test_reply_over_cap", agent l_t80.test_reply_over_cap)
			run_test ("test_reply_inside_paste", agent l_t80.test_reply_inside_paste)
			run_test ("test_committed_osc_timeout", agent l_t80.test_committed_osc_timeout)
			run_test ("test_escape_inside_osc", agent l_t80.test_escape_inside_osc)
			run_test ("test_can_sub_cancel_osc", agent l_t80.test_can_sub_cancel_osc)
			run_test ("test_discard_pending_in_osc", agent l_t80.test_discard_pending_in_osc)
			run_test ("test_clipboard_event_kind", agent l_t80.test_clipboard_event_kind)
			run_test ("test_event_thread_reply", agent l_t80.test_event_thread_reply)
			run_test ("test_request_bytes", agent l_t80.test_request_bytes)
			run_test ("test_app_reply_reaches_process_once", agent l_t80.test_app_reply_reaches_process_once)
			run_test ("test_app_unrequested_reply_dropped", agent l_t80.test_app_unrequested_reply_dropped)
			run_test ("test_app_timeout_unavailable", agent l_t80.test_app_timeout_unavailable)
			run_test ("test_app_second_read_ignored", agent l_t80.test_app_second_read_ignored)
			run_test ("test_app_stop_sends_nothing_more", agent l_t80.test_app_stop_sends_nothing_more)
			run_test ("test_app_suspend_ends_read", agent l_t80.test_app_suspend_ends_read)
			run_test ("test_app_read_while_waiting_for_terminal", agent l_t80.test_app_read_while_waiting_for_terminal)
			run_test ("test_app_reply_before_request_written_dropped", agent l_t80.test_app_reply_before_request_written_dropped)
			run_test ("test_app_reread_while_waiting_does_not_spin", agent l_t80.test_app_reread_while_waiting_does_not_spin)
			run_test ("test_app_without_reads_unchanged", agent l_t80.test_app_without_reads_unchanged)
			run_test ("test_app_driver_reads_no_clipboard_by_default", agent l_t80.test_app_driver_reads_no_clipboard_by_default)
			run_test ("test_app_driver_read_answers_once", agent l_t80.test_app_driver_read_answers_once)
			run_test ("test_app_driver_read_statuses", agent l_t80.test_app_driver_read_statuses)
			run_test ("test_app_driver_read_terminal_reply_late", agent l_t80.test_app_driver_read_terminal_reply_late)
			run_test ("test_app_driver_read_deadline_after_read", agent l_t80.test_app_driver_read_deadline_after_read)
			run_test ("test_app_driver_read_lifecycle", agent l_t80.test_app_driver_read_lifecycle)

			print ("============================================================%N")
			print ("  Running EiffelTUI Clipboard Examples Test Suite (P2b K6)...%N")
			print ("============================================================%N")
			create l_t81
			run_test ("test_text_area_ctrl_v_inserts_reply", agent l_t81.test_text_area_ctrl_v_inserts_reply)
			run_test ("test_text_area_ctrl_v_no_reply", agent l_t81.test_text_area_ctrl_v_no_reply)
			run_test ("test_text_area_ctrl_v_reply_not_text", agent l_t81.test_text_area_ctrl_v_reply_not_text)
			run_test ("test_text_area_ctrl_v_driver_provider", agent l_t81.test_text_area_ctrl_v_driver_provider)
			run_test ("test_text_area_typed_keys_unchanged", agent l_t81.test_text_area_typed_keys_unchanged)
			run_test ("test_text_area_bracketed_paste", agent l_t81.test_text_area_bracketed_paste)
			run_test ("test_menu_bar_paste_reply_toast", agent l_t81.test_menu_bar_paste_reply_toast)
			run_test ("test_menu_bar_paste_no_reply_toast", agent l_t81.test_menu_bar_paste_no_reply_toast)
			run_test ("test_menu_bar_paste_driver_provider", agent l_t81.test_menu_bar_paste_driver_provider)
			run_test ("test_menu_bar_paste_answer_while_dialog_open", agent l_t81.test_menu_bar_paste_answer_while_dialog_open)
			print ("============================================================%N")
			print ("  TEST SUITE SUMMARY%N")
			print ("============================================================%N")
			print ("  Total tests executed: " + total_count.out + "%N")
			print ("  Passed:               " + pass_count.out + "%N")
			print ("  Failed:               " + fail_count.out + "%N")
			print ("============================================================%N")

			if fail_count > 0 then
				print ("  SUITE RESULT: FAILED (" + fail_count.out + " failure(s))%N%N")
				(create {EXCEPTIONS}).die (1)
			else
				print ("  SUITE RESULT: ALL TESTS PASSED!%N%N")
			end
		end

feature {NONE} -- Execution Engine

	library_preconditions_checked: BOOLEAN
			-- Does this build check the library's preconditions?
			-- False in a build finalized without `-keep`, which removes assertions.
		local
			l_probed: BOOLEAN
			l_line: TEXT_LINE
		do
			if not l_probed then
				l_line := (create {TEXT_LINE}.make_raw ("a")).with_alignment (3)
			end
		rescue
			l_probed := True
			Result := attached {PRECONDITION_VIOLATION} (create {EXCEPTION_MANAGER}).last_exception
			retry
		end

	total_count: INTEGER
			-- Number of tests executed

	pass_count: INTEGER
			-- Number of tests that completed successfully

	fail_count: INTEGER
			-- Number of tests that raised an exception

	run_test (a_name: STRING; a_routine: PROCEDURE)
			-- Execute `a_routine` within an isolated rescue context.
			-- If an exception occurs, record failure, log reason, and continue.
		local
			l_failed: BOOLEAN
			l_exc_mgr: EXCEPTION_MANAGER
		do
			if not l_failed then
				total_count := total_count + 1
				a_routine.call
				pass_count := pass_count + 1
				print ("  [PASS] " + a_name + "%N")
			end
		rescue
			if not l_failed then
				l_failed := True
				fail_count := fail_count + 1
				print ("  [FAIL] " + a_name + "%N")
				create l_exc_mgr
				if attached l_exc_mgr.last_exception as l_exc then
					if attached l_exc.description as l_desc and then not l_desc.is_empty then
						print ("         Reason: ")
						print (l_desc)
						print ("%N")
					elseif attached l_exc.tag as l_tag and then not l_tag.is_empty then
						print ("         Tag: ")
						print (l_tag)
						print ("%N")
					end
					if attached l_exc.recipient_name as l_rec then
						print ("         Location: " + l_rec + "%N")
					end
				end
				retry
			end
		end

end

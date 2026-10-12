note
	description: "[
		Unit tests for Phase 11: Advanced Layout & Border Junction Engine
		(FLEX_JUSTIFY, split_with_spacing, split_with_justification, BORDER_COLLISION_SOLVER).
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_LAYOUT_AND_BORDERS

inherit
	EQA_TEST_SET

feature -- Test Routines

	test_layout_split_with_spacing
			-- Test LAYOUT_SOLVER.split_with_spacing leaving fixed gap cells between chunks.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_rects: ARRAYED_LIST [RECT]
			l_c1, l_c2: CONSTRAINT
		do
			create l_solver
			create l_area.make (0, 0, 20, 10)
			l_c1 := {CONSTRAINTS}.fixed (5)
			l_c2 := {CONSTRAINTS}.fixed (5)

			-- Split with 2-cell spacing horizontally
			l_rects := l_solver.split_with_spacing (l_area, <<l_c1, l_c2>>, {SPLIT_DIRECTION}.horizontal, 2)
			assert ("two chunks", l_rects.count = 2)

			-- Chunk 1: x = 0, width = 5
			assert ("chunk 1 x is 0", l_rects.i_th (1).x = 0)
			assert ("chunk 1 width is 5", l_rects.i_th (1).width = 5)

			-- Chunk 2: x = 0 + 5 + 2 = 7, width = 5
			assert ("chunk 2 x is 7", l_rects.i_th (2).x = 7)
			assert ("chunk 2 width is 5", l_rects.i_th (2).width = 5)
		end

	test_layout_justification_end_and_center
			-- Test flex justification end_align and center_align.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_rects_end, l_rects_center: ARRAYED_LIST [RECT]
			l_c1, l_c2: CONSTRAINT
		do
			create l_solver
			-- Width 20, two fixed 5 chunks => 10 extra space
			create l_area.make (0, 0, 20, 5)
			l_c1 := {CONSTRAINTS}.fixed (5)
			l_c2 := {CONSTRAINTS}.fixed (5)

			-- 1. End Align: all 10 extra cells precede chunk 1
			l_rects_end := l_solver.split_with_justification (l_area, <<l_c1, l_c2>>, {SPLIT_DIRECTION}.horizontal, 0, {FLEX_JUSTIFY}.end_align)
			assert ("end align chunk 1 x is 10", l_rects_end.i_th (1).x = 10)
			assert ("end align chunk 2 x is 15", l_rects_end.i_th (2).x = 15)

			-- 2. Center Align: 10 extra cells => 5 before chunk 1, 5 after chunk 2
			l_rects_center := l_solver.split_with_justification (l_area, <<l_c1, l_c2>>, {SPLIT_DIRECTION}.horizontal, 0, {FLEX_JUSTIFY}.center_align)
			assert ("center align chunk 1 x is 5", l_rects_center.i_th (1).x = 5)
			assert ("center align chunk 2 x is 10", l_rects_center.i_th (2).x = 10)
		end

	test_layout_justification_space_between
			-- Test space_between flex justification.
		local
			l_solver: LAYOUT_SOLVER
			l_area: RECT
			l_rects: ARRAYED_LIST [RECT]
			l_c1, l_c2, l_c3: CONSTRAINT
		do
			create l_solver
			-- Width 20, three fixed 4 chunks => 12 allocated => 8 extra cells
			-- With 3 chunks, there are 2 gaps => 8 // 2 = 4 extra space per gap
			create l_area.make (0, 0, 20, 5)
			l_c1 := {CONSTRAINTS}.fixed (4)
			l_c2 := {CONSTRAINTS}.fixed (4)
			l_c3 := {CONSTRAINTS}.fixed (4)

			l_rects := l_solver.split_with_justification (l_area, <<l_c1, l_c2, l_c3>>, {SPLIT_DIRECTION}.horizontal, 0, {FLEX_JUSTIFY}.space_between)
			assert ("chunk 1 x is 0", l_rects.i_th (1).x = 0)
			-- Chunk 2: x = 0 + 4 + 4 = 8
			assert ("chunk 2 x is 8", l_rects.i_th (2).x = 8)
			-- Chunk 3: x = 8 + 4 + 4 = 16
			assert ("chunk 3 x is 16", l_rects.i_th (3).x = 16)
		end

	test_border_collision_symbol_merging
			-- Test 4-bit connection merging of box-drawing characters.
		local
			l_solver: BORDER_COLLISION_SOLVER
			c_horiz, c_vert: CHARACTER_32
			c_tl, c_tr, c_bl, c_br: CHARACTER_32
		do
			create l_solver
			c_horiz := (9472).to_character_32 -- '─'
			c_vert := (9474).to_character_32  -- '│'
			c_tl := (9484).to_character_32    -- '┌'
			c_tr := (9488).to_character_32    -- '┐'
			c_bl := (9492).to_character_32    -- '└'
			c_br := (9496).to_character_32    -- '┘'

			-- '─' + '│' = '┼' (code 9532)
			assert ("cross junction", l_solver.merge_symbols (c_horiz, c_vert).code = 9532)

			-- '┌' + '─' = '┬' (code 9516)
			assert ("t-junction top from tl", l_solver.merge_symbols (c_tl, c_horiz).code = 9516)

			-- '┐' + '─' = '┬' (code 9516)
			assert ("t-junction top from tr", l_solver.merge_symbols (c_tr, c_horiz).code = 9516)

			-- '└' + '─' = '┴' (code 9524)
			assert ("t-junction bottom from bl", l_solver.merge_symbols (c_bl, c_horiz).code = 9524)

			-- '┘' + '─' = '┴' (code 9524)
			assert ("t-junction bottom from br", l_solver.merge_symbols (c_br, c_horiz).code = 9524)

			-- '┌' + '│' = '├' (code 9500)
			assert ("t-junction left from tl", l_solver.merge_symbols (c_tl, c_vert).code = 9500)

			-- '┐' + '│' = '┤' (code 9508)
			assert ("t-junction right from tr", l_solver.merge_symbols (c_tr, c_vert).code = 9508)

			-- Rounded corner merging: '╭' (code 9581) + '│' = '├' (code 9500)
			assert ("rounded top-left merged with vert", l_solver.merge_symbols ((9581).to_character_32, c_vert).code = 9500)
		end

	test_buffer_border_fusion
			-- Test merging border collisions into BUFFER cells.
		local
			l_solver: BORDER_COLLISION_SOLVER
			l_buf: BUFFER
			l_style: STYLE
		do
			create l_solver
			create l_buf.make (10, 5)
			create l_style.default_create

			-- Put horizontal border '─' across row 2
			l_buf.put_char (2, 4, (9472).to_character_32, l_style)

			-- Now write intersecting vertical border '│' through (2, 4) using merge_into_buffer
			l_solver.merge_into_buffer (l_buf, 2, 4, (9474).to_character_32, l_style)

			-- Result at (2, 4) should automatically be cross junction '┼' (code 9532)
			assert ("cell became cross junction", l_buf.cell (2, 4).symbol.code (1) = 9532)
		end

end

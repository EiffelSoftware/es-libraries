note
	description: "[
		AutoTest suite for Layer 4: RECT geometry, Constraints, and LAYOUT_SOLVER.
	]"
	author: "EiffelTUI Team"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_LAYOUT_SOLVER

inherit
	EQA_TEST_SET

feature -- Test routines

	test_rect_geometry
			-- Test RECT points, boundaries, intersection, and union.
		local
			l_r1, l_r2, l_inter, l_union, l_inner: RECT
		do
			create l_r1.make (10, 5, 20, 15)
			assert ("x is 10", l_r1.x = 10)
			assert ("y is 5", l_r1.y = 5)
			assert ("width is 20", l_r1.width = 20)
			assert ("height is 15", l_r1.height = 15)
			assert ("right is 30", l_r1.right = 30)
			assert ("bottom is 20", l_r1.bottom = 20)
			assert ("area is 300", l_r1.area = 300)

			assert ("contains inside point", l_r1.contains_point (15, 10))
			assert ("does not contain outside point", not l_r1.contains_point (5, 5))
			assert ("does not contain right edge", not l_r1.contains_point (30, 10))

			create l_r2.make (20, 10, 20, 15)
			assert ("intersects", l_r1.intersects (l_r2))

			l_inter := l_r1.intersection (l_r2)
			assert ("inter x is 20", l_inter.x = 20)
			assert ("inter y is 10", l_inter.y = 10)
			assert ("inter width is 10", l_inter.width = 10)
			assert ("inter height is 10", l_inter.height = 10)

			l_union := l_r1.union (l_r2)
			assert ("union x is 10", l_union.x = 10)
			assert ("union y is 5", l_union.y = 5)
			assert ("union width is 30", l_union.width = 30)
			assert ("union height is 20", l_union.height = 20)

			l_inner := l_r1.inner (2, 3)
			assert ("inner x is 12", l_inner.x = 12)
			assert ("inner y is 8", l_inner.y = 8)
			assert ("inner width is 16", l_inner.width = 16)
			assert ("inner height is 9", l_inner.height = 9)
		end

	test_split_vertical_fixed_and_flex
			-- Test splitting 80x24 vertically into [ Fixed(3), Flex(1) ].
		local
			l_parent: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_solver: LAYOUT_SOLVER
			l_results: ARRAYED_LIST [RECT]
		do
			create l_parent.make (0, 0, 80, 24)
			create l_constraints.make (2)
			l_constraints.extend ({CONSTRAINTS}.fixed (3))
			l_constraints.extend ({CONSTRAINTS}.flex (1))

			create l_solver
			l_results := l_solver.split (l_parent, l_constraints, {SPLIT_DIRECTION}.vertical)

			assert ("2 rects produced", l_results.count = 2)

			-- Top: 80x3 at (0, 0)
			assert ("top x is 0", l_results.i_th (1).x = 0)
			assert ("top y is 0", l_results.i_th (1).y = 0)
			assert ("top width is 80", l_results.i_th (1).width = 80)
			assert ("top height is 3", l_results.i_th (1).height = 3)

			-- Bottom: 80x21 at (0, 3)
			assert ("bottom x is 0", l_results.i_th (2).x = 0)
			assert ("bottom y is 3", l_results.i_th (2).y = 3)
			assert ("bottom width is 80", l_results.i_th (2).width = 80)
			assert ("bottom height is 21", l_results.i_th (2).height = 21)

			assert ("total height is 24", l_results.i_th (1).height + l_results.i_th (2).height = 24)
		end

	test_split_horizontal_ratios
			-- Test splitting 80x24 horizontally into [ Ratio(1, 4), Ratio(3, 4) ].
		local
			l_parent: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_solver: LAYOUT_SOLVER
			l_results: ARRAYED_LIST [RECT]
		do
			create l_parent.make (0, 0, 80, 24)
			create l_constraints.make (2)
			l_constraints.extend ({CONSTRAINTS}.ratio (1, 4))
			l_constraints.extend ({CONSTRAINTS}.ratio (3, 4))

			create l_solver
			l_results := l_solver.split (l_parent, l_constraints, {SPLIT_DIRECTION}.horizontal)

			assert ("2 rects produced", l_results.count = 2)

			-- Left: 20x24 at (0, 0)
			assert ("left x is 0", l_results.i_th (1).x = 0)
			assert ("left y is 0", l_results.i_th (1).y = 0)
			assert ("left width is 20", l_results.i_th (1).width = 20)
			assert ("left height is 24", l_results.i_th (1).height = 24)

			-- Right: 60x24 at (20, 0)
			assert ("right x is 20", l_results.i_th (2).x = 20)
			assert ("right y is 0", l_results.i_th (2).y = 0)
			assert ("right width is 60", l_results.i_th (2).width = 60)
			assert ("right height is 24", l_results.i_th (2).height = 24)

			assert ("total width is 80", l_results.i_th (1).width + l_results.i_th (2).width = 80)
		end

	test_split_horizontal_percentage
			-- Test splitting 80x24 horizontally into [ Percentage(50), Percentage(50) ].
		local
			l_parent: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_solver: LAYOUT_SOLVER
			l_results: ARRAYED_LIST [RECT]
		do
			create l_parent.make (0, 0, 80, 24)
			create l_constraints.make (2)
			l_constraints.extend ({CONSTRAINTS}.percentage (50))
			l_constraints.extend ({CONSTRAINTS}.percentage (50))

			create l_solver
			l_results := l_solver.split (l_parent, l_constraints, {SPLIT_DIRECTION}.horizontal)

			assert ("2 rects produced", l_results.count = 2)
			assert ("rect 1 width is 40", l_results.i_th (1).width = 40)
			assert ("rect 2 width is 40", l_results.i_th (2).width = 40)
			assert ("rect 2 x is 40", l_results.i_th (2).x = 40)
		end

	test_flex_remainder_distribution
			-- Test dividing 100 cells among 3 equal flex children redistributes remainder.
		local
			l_parent: RECT
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_solver: LAYOUT_SOLVER
			l_results: ARRAYED_LIST [RECT]
			l_sum: NATURAL_16
		do
			create l_parent.make (0, 0, 100, 10)
			create l_constraints.make (3)
			l_constraints.extend ({CONSTRAINTS}.flex (1))
			l_constraints.extend ({CONSTRAINTS}.flex (1))
			l_constraints.extend ({CONSTRAINTS}.flex (1))

			create l_solver
			l_results := l_solver.split (l_parent, l_constraints, {SPLIT_DIRECTION}.horizontal)

			assert ("3 rects produced", l_results.count = 3)
			l_sum := l_results.i_th (1).width + l_results.i_th (2).width + l_results.i_th (3).width
			assert ("total width equals parent 100", l_sum = 100)
			assert ("first got remainder (34)", l_results.i_th (1).width = 34)
			assert ("second is 33", l_results.i_th (2).width = 33)
			assert ("third is 33", l_results.i_th (3).width = 33)
		end

	test_split_with_margin
			-- Test layout solver with margin deflation.
		local
			l_parent: RECT
			l_margin: MARGIN
			l_constraints: ARRAYED_LIST [CONSTRAINT]
			l_solver: LAYOUT_SOLVER
			l_results: ARRAYED_LIST [RECT]
		do
			create l_parent.make (0, 0, 80, 24)
			create l_margin.make (2, 1) -- Horiz 2, Vert 1 -> Inner: (2, 1, 76, 22)
			create l_constraints.make (2)
			l_constraints.extend ({CONSTRAINTS}.fixed (2))
			l_constraints.extend ({CONSTRAINTS}.flex (1))

			create l_solver
			l_results := l_solver.split_with_margin (l_parent, l_constraints, {SPLIT_DIRECTION}.vertical, l_margin)

			assert ("2 rects produced", l_results.count = 2)
			assert ("top x is 2", l_results.i_th (1).x = 2)
			assert ("top y is 1", l_results.i_th (1).y = 1)
			assert ("top width is 76", l_results.i_th (1).width = 76)
			assert ("top height is 2", l_results.i_th (1).height = 2)

			assert ("bottom x is 2", l_results.i_th (2).x = 2)
			assert ("bottom y is 3", l_results.i_th (2).y = 3)
			assert ("bottom width is 76", l_results.i_th (2).width = 76)
			assert ("bottom height is 20", l_results.i_th (2).height = 20)
		end

end

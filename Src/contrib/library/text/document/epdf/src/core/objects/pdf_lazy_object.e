note
	description: "[
		Lazy proxy for PDF objects that defers parsing until first access.
		Ensures objects are only parsed when needed, implementing lazy loading strategy.
		See plan.md Section 4.3: Lazy Object Proxy.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_LAZY_OBJECT

inherit
	PDF_OBJECT

create
	make

feature -- Initialization

	make (a_loader: like loader)
			-- Create lazy object with loader function.
		do
			loader := a_loader
			cached := Void
		ensure
			loader_set: loader = a_loader
			not_loaded: not is_loaded
		end

feature -- Access

	resolved: PDF_OBJECT
			-- Get the resolved (loaded) object.
			-- Loads object on first access.
		do
			if attached cached as c then
				Result := c
			else
				Result := loader.item (Void)
				cached := Result
			end
		ensure
			cached_after_first_call: is_loaded
		end

feature -- Status Report

	is_loaded: BOOLEAN
			-- Has the object been loaded yet?
		do
			Result := cached /= Void
		ensure
			definition: Result = (cached /= Void)
		end

feature -- Visitor Pattern

	accept (a_visitor: PDF_VISITOR)
			-- Accept visitor by delegating to resolved object.
		do
			resolved.accept (a_visitor)
		end

feature {NONE} -- Implementation

	loader: FUNCTION [PDF_OBJECT]
			-- Function that loads the actual object.

	cached: detachable PDF_OBJECT
			-- Cached resolved object (Void until first access).

invariant
	loaded_implies_cached: is_loaded implies cached /= Void

end

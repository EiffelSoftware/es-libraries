note
	description: "[
		Represents a PDF Graphics State Parameter Dictionary (ExtGState).
		ExtGState dictionaries define graphics state parameters that can be
		set using the gs operator in content streams.
		
		Per ISO 32000-1:2008 §8.4.5:
		- Specifies graphics state parameters beyond basic operators
		- Critical for transparency (CA, ca, BM, SMask)
		- Line style parameters (LW, LC, LJ, ML, D)
	]"
	spec_reference: "ISO 32000-1:2008 Section 8.4.5 Graphics State Parameter Dictionaries"
	date: "$Date$"
	revision: "$Revision$"

class
	PDF_GRAPHICS_STATE

create
	make_from_dictionary,
	make_empty

feature -- Initialization

	make_from_dictionary (a_dictionary: PDF_DICTIONARY)
			-- Create graphics state from dictionary.
			-- Extracts all relevant parameters.
		require
			dictionary_valid: a_dictionary /= Void
		do
			source_dictionary := a_dictionary
			extract_properties
		ensure
			dictionary_set: source_dictionary = a_dictionary
		end

	make_empty
			-- Create empty graphics state.
		do
			create source_dictionary.make_empty
		end

feature -- Access

	source_dictionary: PDF_DICTIONARY
			-- The underlying dictionary object.

feature -- Line Style Parameters

	line_width: REAL_64
			-- Line width (/LW).
			-- Per ISO 32000-1:2008 §8.4.3.2.

	has_line_width: BOOLEAN
			-- Was line width specified?

	line_cap: INTEGER
			-- Line cap style (/LC): 0=butt, 1=round, 2=square.
			-- Per ISO 32000-1:2008 §8.4.3.3.

	has_line_cap: BOOLEAN
			-- Was line cap specified?

	line_join: INTEGER
			-- Line join style (/LJ): 0=miter, 1=round, 2=bevel.
			-- Per ISO 32000-1:2008 §8.4.3.4.

	has_line_join: BOOLEAN
			-- Was line join specified?

	miter_limit: REAL_64
			-- Miter limit (/ML).
			-- Per ISO 32000-1:2008 §8.4.3.5.

	has_miter_limit: BOOLEAN
			-- Was miter limit specified?

	dash_array: detachable PDF_ARRAY
			-- Dash pattern (/D).
			-- Per ISO 32000-1:2008 §8.4.3.6.

feature -- Transparency Parameters (Critical)

	stroke_alpha: REAL_64
			-- Stroking alpha constant (/CA).
			-- Per ISO 32000-1:2008 §11.6.4.4.
			-- Range: 0.0 (transparent) to 1.0 (opaque).

	has_stroke_alpha: BOOLEAN
			-- Was stroke alpha specified?

	fill_alpha: REAL_64
			-- Non-stroking (fill) alpha constant (/ca).
			-- Per ISO 32000-1:2008 §11.6.4.4.
			-- Range: 0.0 (transparent) to 1.0 (opaque).

	has_fill_alpha: BOOLEAN
			-- Was fill alpha specified?

	blend_mode: detachable STRING_8
			-- Blend mode (/BM).
			-- Per ISO 32000-1:2008 §11.3.5.
			-- Common values: Normal, Multiply, Screen, Overlay, etc.

	alpha_is_shape: BOOLEAN
			-- Alpha source flag (/AIS).
			-- Per ISO 32000-1:2008 §11.6.4.4.

feature -- Soft Mask (Advanced Transparency)

	soft_mask_name: detachable STRING_8
			-- Soft mask name or "None" (/SMask).
			-- Per ISO 32000-1:2008 §11.6.5.

	has_soft_mask: BOOLEAN
			-- Does this state define a soft mask?
		do
			Result := attached soft_mask_name as sm and then
				not sm.same_string ("None")
		end

feature -- Other Parameters

	overprint_mode: INTEGER
			-- Overprint mode (/OPM).

	has_overprint_mode: BOOLEAN
			-- Was overprint mode specified?

	font_info: detachable PDF_ARRAY
			-- Font and size (/Font): [font size].

feature -- Query

	has_transparency: BOOLEAN
			-- Does this graphics state define transparency settings?
		do
			Result := has_stroke_alpha or has_fill_alpha or
				blend_mode /= Void or has_soft_mask
		end

	has_line_style: BOOLEAN
			-- Does this graphics state define line style settings?
		do
			Result := has_line_width or has_line_cap or
				has_line_join or dash_array /= Void
		end

feature {NONE} -- Implementation

	extract_properties
			-- Extract graphics state properties from dictionary.
		local
			dict: PDF_DICTIONARY
		do
			dict := source_dictionary

				-- Line width
			if attached {PDF_NUMBER} dict.item ("LW") as lw then
				line_width := lw.real_value
				has_line_width := True
			end

				-- Line cap
			if attached {PDF_NUMBER} dict.item ("LC") as lc then
				line_cap := lc.int_value
				has_line_cap := True
			end

				-- Line join
			if attached {PDF_NUMBER} dict.item ("LJ") as lj then
				line_join := lj.int_value
				has_line_join := True
			end

				-- Miter limit
			if attached {PDF_NUMBER} dict.item ("ML") as ml then
				miter_limit := ml.real_value
				has_miter_limit := True
			end

				-- Dash array
			if attached {PDF_ARRAY} dict.item ("D") as d then
				dash_array := d
			end

				-- Stroke alpha (CA) - uppercase for stroking
			if attached {PDF_NUMBER} dict.item ("CA") as ca then
				stroke_alpha := ca.real_value
				has_stroke_alpha := True
			end

				-- Fill alpha (ca) - lowercase for non-stroking
			if attached {PDF_NUMBER} dict.item ("ca") as ca_lower then
				fill_alpha := ca_lower.real_value
				has_fill_alpha := True
			end

				-- Blend mode
			if attached {PDF_NAME} dict.item ("BM") as bm then
				blend_mode := bm.value
			end

				-- Alpha is shape
			if attached {PDF_BOOLEAN} dict.item ("AIS") as ais then
				alpha_is_shape := ais.value
			end

				-- Soft mask (can be name "None" or dictionary)
			if attached {PDF_NAME} dict.item ("SMask") as sm then
				soft_mask_name := sm.value
			end

				-- Overprint mode
			if attached {PDF_NUMBER} dict.item ("OPM") as opm then
				overprint_mode := opm.int_value
				has_overprint_mode := True
			end

				-- Font
			if attached {PDF_ARRAY} dict.item ("Font") as f then
				font_info := f
			end
		end

invariant
	dictionary_attached: source_dictionary /= Void

end

note
	description: "Tests for Markdown inline: Images, titles, formatted alt (FEATURES.md Inline)."

class
	TEST_MD_IMAGES

inherit
	TEST_MD_PARSER_BASE

feature -- Tests (Images)

	test_inline_image
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt text](image.png)%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt text%"/></p>%N"))
		end

	test_image_with_title
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt](image.png %"title%")%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt%" title=%"title%"/></p>%N"))
		end

	test_image_with_title_single_quotes
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt](image.png 'title')%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt%" title=%"title%"/></p>%N"))
		end

	test_image_with_inline_formatting
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![*bold* alt](image.png)%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"bold alt%"/></p>%N"))
		end

	test_reference_style_image_explicit
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt text][img-ref]%N%N[img-ref]: image.png%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt text%"/></p>%N"))
		end

	test_reference_style_image_with_title
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt][img-ref]%N%N[img-ref]: image.png %"Image Title%"%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt%" title=%"Image Title%"/></p>%N"))
		end

	test_reference_style_image_collapsed
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt text][]%N%N[alt text]: image.png%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt text%"/></p>%N"))
		end

	test_reference_style_image_shortcut
		local
			t: MD_CONTENT_TEXT
			o: STRING
		do
			create t.make_from_string ("![alt text]%N%N[alt text]: image.png%N")
			create o.make_empty
			t.document.process (create {MD_XHTML_GENERATOR}.make (o))
			assert ("xhtml", o.same_string ("<p><img src=%"image.png%" alt=%"alt text%"/></p>%N"))
		end

end

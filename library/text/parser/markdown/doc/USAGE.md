# Usage Guide

This guide provides examples and instructions for using the Markdown parser library.

## Basic Usage

### Parse Markdown into an AST

Use `MD_PARSER` directly:

```eiffel
local
	p: MD_PARSER
	doc: MD_DOCUMENT
do
	create p.make
	doc := p.parse ("# Title%N%NParagraph with *emphasis*.%N")
	-- Use doc to access the parsed AST
end
```

Or use `MD_CONTENT_TEXT` (cached parse):

```eiffel
local
	t: MD_CONTENT_TEXT
	doc: MD_DOCUMENT
do
	create t.make_from_string ("# Title%N%NParagraph.%N")
	doc := t.document  -- Cached, won't re-parse
end
```

### Render to XHTML

```eiffel
local
	t: MD_CONTENT_TEXT
	out: STRING
do
	create t.make_from_string ("# Hello *world*%N%NThis is `code`.%N")
	create out.make_empty
	t.document.process (create {MD_XHTML_GENERATOR}.make (out))
	print (out)
	-- Output: <h1>Hello <em>world</em></h1>%N<p>This is <code class="inline">code</code>.</p>%N
end
```

### Render to CommonMark XML AST

To export the document as CommonMark XML (AST format, see http://commonmark.org/xml/1.0):

```eiffel
local
	t: MD_CONTENT_TEXT
	xml: STRING
do
	create t.make_from_string ("# Hello *world*%N%NThis is `code`.%N")
	create xml.make_empty
	t.document.process (create {MD_AST_GENERATOR}.make (xml))
	print (xml)
	-- Output: <?xml version="1.0" encoding="UTF-8"?>
	-- <document xmlns="http://commonmark.org/xml/1.0">
	-- <heading level="1"><text>Hello </text><strong><text>world</text></strong></heading>
	-- <paragraph><text>This is </text><code>code</code><text>.</text></paragraph>
	-- </document>
end
```

### Walk the Tree

If you want to extract information without rendering, implement a custom visitor:

```eiffel
class
	MY_CUSTOM_VISITOR

inherit
	MD_VISITOR

feature -- Processing
	visit_heading (a_heading: MD_HEADING)
		do
			print ("Found heading level " + a_heading.level.out + "%N")
			-- Process heading content
			visit_composite (a_heading)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			print ("Found paragraph%N")
			visit_composite (a_paragraph)
		end

	-- Implement other visit_* routines as needed
end
```

Or reuse `MD_ITERATOR` and redefine only what you need:

```eiffel
class
	MY_ITERATOR

inherit
	MD_ITERATOR
		redefine
			visit_heading
		end

feature
	visit_heading (a_heading: MD_HEADING)
		do
			-- Custom handling
			print ("Heading: " + a_heading.level.out + "%N")
			Precursor (a_heading)  -- Continue normal traversal
		end
end
```

## Advanced Examples

### Extract All Links

```eiffel
class
	LINK_EXTRACTOR

inherit
	MD_VISITOR

create
	make

feature {NONE} -- Initialization
	make
		do
			create links.make (10)
		end

feature -- Access
	links: ARRAYED_LIST [TUPLE [text: STRING; url: STRING]]

feature -- Processing
	visit_link (a_link: MD_LINK)
		local
			text: STRING
		do
			create text.make_empty
			-- Collect link text
			across a_link as inline_item loop
				if attached {MD_TEXT} inline_item as txt then
					text.append (txt.text)
				end
			end
			links.extend ([text, a_link.url])
		end

	-- Implement other visit_* routines to do nothing or call visit_composite
	visit_document (a_document: MD_DOCUMENT)
		do
			visit_composite (a_document)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			visit_composite (a_paragraph)
		end

	-- ... implement other visit_* routines similarly
end
```

### Count Headings by Level

```eiffel
class
	HEADING_COUNTER

inherit
	MD_VISITOR

create
	make

feature {NONE} -- Initialization
	make
		do
			create counts.make_filled (0, 1, 6)
		end

feature -- Access
	counts: ARRAYED_LIST [INTEGER]
			-- Counts for heading levels 1-6

feature -- Processing
	visit_heading (a_heading: MD_HEADING)
		do
			if a_heading.level >= 1 and a_heading.level <= 6 then
				counts [a_heading.level] := counts [a_heading.level] + 1
			end
		end

	-- Implement other visit_* routines to traverse the tree
	visit_document (a_document: MD_DOCUMENT)
		do
			visit_composite (a_document)
		end

	-- ... implement other visit_* routines
end
```

### Process Images

```eiffel
local
	t: MD_CONTENT_TEXT
	visitor: IMAGE_EXTRACTOR
do
	create t.make_from_string ("Text with ![alt](image.png \"title\") image.%NOr ![alt][ref] reference-style.%N[ref]: image.png \"Title\"%N")
	create visitor.make
	t.document.process (visitor)
	-- visitor has extracted all images
end

class
	IMAGE_EXTRACTOR

inherit
	MD_VISITOR

create
	make

feature {NONE} -- Initialization
	make
		do
			create images.make (10)
		end

feature -- Access
	images: ARRAYED_LIST [TUPLE [url: STRING; alt: STRING; title: detachable STRING]]

feature -- Processing
	visit_image (a_image: MD_IMAGE)
		local
			alt_text: STRING
		do
			create alt_text.make_empty
			across a_image as inline_item loop
				if attached {MD_TEXT} inline_item as txt then
					alt_text.append (txt.text)
				end
			end
			images.extend ([a_image.url, alt_text, a_image.title])
			-- Note: a_image.title may be Void for images without titles
		end

	-- Implement other visit_* routines to traverse the tree
	visit_document (a_document: MD_DOCUMENT)
		do
			visit_composite (a_document)
		end

	visit_paragraph (a_paragraph: MD_PARAGRAPH)
		do
			visit_composite (a_paragraph)
		end

	-- ... implement other visit_* routines similarly
end
```

### Process Tables

```eiffel
local
	t: MD_CONTENT_TEXT
	visitor: TABLE_PROCESSOR
do
	create t.make_from_string ("| Header 1 | Header 2 |%N|----------|----------|%N| Cell 1   | Cell 2   |%N")
	create visitor.make
	t.document.process (visitor)
	-- visitor has processed all tables
end

class
	TABLE_PROCESSOR

inherit
	MD_VISITOR

feature
	visit_table (a_table: MD_TABLE)
		do
			print ("Found table with " + a_table.count.out + " rows%N")
			visit_composite (a_table)
		end

	visit_table_row (a_row: MD_TABLE_ROW)
		do
			print ("  Row with " + a_row.count.out + " cells%N")
			visit_composite (a_row)
		end

	visit_table_cell (a_cell: MD_TABLE_CELL)
		do
			print ("    Cell: ")
			visit_composite (a_cell)
			print ("%N")
		end

	-- ... implement other visit_* routines
end
```

## File I/O Example

```eiffel
local
	file: PLAIN_TEXT_FILE
	content: STRING
	t: MD_CONTENT_TEXT
	out: STRING
	output_file: PLAIN_TEXT_FILE
do
	-- Read input file
	create file.make_with_name ("input.md")
	if file.exists and then file.is_readable then
		file.open_read
		file.read_stream (file.count)
		content := file.last_string
		file.close

		-- Parse and render
		create t.make_from_string (content)
		create out.make_empty
		t.document.process (create {MD_XHTML_GENERATOR}.make (out))

		-- Write output file
		create output_file.make_with_name ("output.html")
		output_file.open_write
		output_file.put_string ("<!DOCTYPE html>%N<html><head><meta charset=%"UTF-8%"></head><body>%N")
		output_file.put_string (out)
		output_file.put_string ("</body></html>%N")
		output_file.close
	end
end
```

## Best Practices

1. **Use `MD_CONTENT_TEXT`** if you need to access the document multiple times (it caches the parse result)

2. **Use `MD_PARSER` directly** if you only need to parse once

3. **Implement custom visitors** for specific extraction or transformation tasks

4. **Reuse `MD_ITERATOR`** as a base when you only need to customize a few visit routines

5. **Handle errors gracefully** - The parser may produce partial results for malformed input

6. **Test with real Markdown** - The parser handles typical documents well, but edge cases may vary

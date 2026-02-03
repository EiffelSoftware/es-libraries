## Overview

This folder provides an Eiffel **Markdown parser** that produces a small AST and a **visitor-based API** (inspired by the existing `wikitext` library in the same repository).

## Status / Scope

This library intentionally implements a pragmatic subset of Markdown (close to CommonMark for typical documents):

- **Block**
  - ATX headings: `#` .. `######`
  - Setext headings: `H1\n====` or `H2\n----`
  - Paragraphs (blank-line separated)
  - Hard line breaks: two trailing spaces or backslash at end of line
  - Unordered lists: `- item`, `* item`, `+ item` (with nested lists via indentation)
  - Ordered lists: `1. item`, `2) item` (with nested lists via indentation)
  - Lists with multiple paragraphs, code blocks, and blockquotes
  - Blockquotes: `> ...` (with nested blockquotes: `> > nested`)
  - Fenced code blocks: triple backticks ````` ``` ````` or tildes `~~~` with optional info string (language)
  - Indented code blocks: 4 spaces or 1 tab
  - Thematic breaks: `---`, `***`, `___` (with optional spaces)
  - Tables: `| Header | Header |` with separator row `|------|------|`

- **Inline**
  - Text
  - Emphasis: `*text*` or `_text_` (with GitHub extension)
  - Strong: `**text**` or `__text__` (with GitHub extension)
  - Code span: `` `code` ``
  - Links: `[label](url)` or reference-style `[label][ref]` with `[ref]: url "title"`
  - Autolinks: `<https://example.com>` and `<user@example.com>`
  - Images: `![alt](url)` with optional title `![alt](url "title")` or reference-style `![alt][ref]`
  - Strikethrough: `~~text~~` (with GitHub extension)
  - Task lists: `- [ ]` or `- [x]` (with GitHub extension)
  - Full backslash escapes: `\!`, `\"`, `\#`, etc.
  - Soft breaks: single newline within paragraph

- **HTML Blocks**
  - Raw HTML blocks (types 2-7): `<div>...</div>` until blank line

## Public API (entry points)

- `MD_CONTENT_TEXT`
	- Create with `make_from_string`
	- Call `document: MD_DOCUMENT` to get the parsed AST (cached)

- `MD_PARSER`
	- Call `parse (a_text: READABLE_STRING_8): MD_DOCUMENT`

- Visitors
	- `MD_XHTML_GENERATOR` renders to XHTML into a caller-provided `STRING`.
	- `MD_AST_GENERATOR` exports to CommonMark XML AST (http://commonmark.org/xml/1.0).
	- `MD_DEBUG_VISITOR` prints the tree to stdout.
	- `MD_ITERATOR` walks the tree (base for custom visitors).

## Example

```eiffel
local
	t: MD_CONTENT_TEXT
	out: STRING
do
	create t.make_from_string ("# Hello *world*%N")
	create out.make_empty
	t.document.process (create {MD_XHTML_GENERATOR}.make (out))
	print (out)
end
```

Expected output:

```text
<h1>Hello <em>world</em></h1>
```

## Documentation

Comprehensive documentation is available in the `doc/` directory:

- **[doc/USAGE.md](doc/USAGE.md)** - Usage guide with examples
- **[doc/ARCHITECTURE.md](doc/ARCHITECTURE.md)** - Architecture and design details
- **[doc/FEATURES.md](doc/FEATURES.md)** - Complete feature list with status

## Folder layout

- `markdown.ecf`: library target
- `src/core/structure`: AST node classes
- `src/core/visitor`: visitors (iterator, XHTML generator, debug visitor)
- `src/core/md_parser.e`: parser
- `doc/`: Documentation files
- `examples/md2html`: small console app converting `input.md` to `output.html`
- `examples/md2ast`: small console app converting `input.md` to CommonMark XML AST
- `tests/`: AutoTest suite (`tests.ecf`, `TEST_MD_PARSER`)


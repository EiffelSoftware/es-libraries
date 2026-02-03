# Architecture

This library follows the same broad architecture as `wikitext`:

- **AST / structure classes** in `src/core/structure/`
- **Visitors** in `src/core/visitor/`
- **Parser** producing the AST in `src/core/md_parser.e`

## AST Design

The root node is `MD_DOCUMENT` (a composite of `MD_BLOCK`).

### Block-Level Nodes

- `MD_HEADING` - ATX headings (`# H1` to `###### H6`) and Setext headings (`H1\n====` or `H2\n----`)
- `MD_PARAGRAPH` - Paragraphs (blank-line separated, with hard line breaks)
- `MD_LIST` / `MD_LIST_ITEM` - Ordered and unordered lists (with nested lists, multiple paragraphs, code blocks, and blockquotes)
- `MD_BLOCKQUOTE` - Blockquotes (`> ...` with nested support: `> > nested`)
- `MD_CODE_BLOCK` - Fenced code blocks (``` or ~~~ with optional info string) and indented code blocks (4 spaces or 1 tab)
- `MD_THEMATIC_BREAK` - Thematic breaks (`---`, `***`, `___`)
- `MD_TABLE` / `MD_TABLE_ROW` / `MD_TABLE_CELL` / `MD_TABLE_HEADER_CELL` - Tables
- `MD_RAW_HTML` - Raw HTML blocks (types 2-7, until blank line)
- `MD_FOOTNOTE_DEFINITION` / `MD_FOOTNOTE_REFERENCE` - Footnotes (extension)

### Inline Nodes

- `MD_TEXT` - Plain text
- `MD_EMPHASIS` - Emphasis (`*text*` or `_text_` with GitHub extension)
- `MD_STRONG` - Strong emphasis (`**text**` or `__text__` with GitHub extension)
- `MD_CODE_SPAN` - Inline code (`` `code` ``)
- `MD_LINK` - Links (`[label](url)`, reference-style `[label][ref]`, or autolinks `<url>`)
- `MD_IMAGE` - Images (`![alt](url)` or reference-style `![alt][ref]`, with optional title)
- `MD_LINE_BREAK` - Hard line breaks (two trailing spaces or backslash)
- `MD_SOFT_BREAK` - Soft line breaks (single newline within paragraph)
- `MD_STRIKETHROUGH` - Strikethrough (`~~text~~` with GitHub extension)

## Visitor Protocol

Each `MD_ITEM` implements `process (a_visitor: MD_VISITOR)`.
Visitors implement `visit_*` routines to handle each node type.

### Provided Visitors

- `MD_ITERATOR`: Generic tree traversal (base for custom visitors)
- `MD_XHTML_GENERATOR`: XHTML rendering into a caller-provided `STRING`
- `MD_AST_GENERATOR`: CommonMark XML AST export (http://commonmark.org/xml/1.0)
- `MD_DEBUG_VISITOR`: Debugging output to stdout

### Custom Visitors

To create a custom visitor, inherit from `MD_VISITOR` and implement the `visit_*` routines for the node types you need to handle. You can also inherit from `MD_ITERATOR` and redefine only the routines you need.

## Parser Strategy

`MD_PARSER` uses a two-phase parsing approach:

1. **Block parsing**: Identifies block-level structures (headings, paragraphs, lists, blockquotes, fenced code blocks, thematic breaks, tables, HTML blocks)
2. **Inline parsing**: Processes inline formatting within blocks (emphasis, strong, code spans, links, images, escapes, soft breaks)

### Block Parsing

The parser processes the input line-by-line, identifying block structures:
- Headings (ATX style with `#` or Setext style with underlines `====` or `----`)
- Paragraphs (consecutive non-blank lines, with hard line breaks via two spaces or backslash)
- Lists (with indentation-based nesting, multiple paragraphs, code blocks, blockquotes, and task lists with GitHub extension)
- Blockquotes (lines starting with `>`, with nested support)
- Fenced code blocks (triple backticks ``` or tildes ~~~)
- Indented code blocks (4 spaces or 1 tab)
- Thematic breaks (horizontal rules)
- Tables (pipe-separated rows with alignment)
- HTML blocks (types 2-7, until blank line)

### Inline Parsing

After block identification, inline parsing processes the text content within blocks:
- Emphasis and strong emphasis (asterisks, or underscores with GitHub extension)
- Code spans (backticks with variable-length delimiters)
- Links (inline style `[text](url)`, reference-style `[text][ref]`, and autolinks `<url>` or `<email>`)
- Images (inline style `![alt](url)` and reference-style `![alt][ref]`, with optional titles)
- Hard line breaks (detected during paragraph building)
- Soft line breaks (single newline within paragraph)
- Strikethrough (`~~text~~` with GitHub extension)
- Full backslash escapes (all punctuation characters)

## Convenience Wrapper

`MD_CONTENT_TEXT` is a convenience wrapper that:
- Takes a Markdown string in its constructor
- Caches the parsed `MD_DOCUMENT`
- Provides easy access via `document: MD_DOCUMENT`

This avoids re-parsing if you need to access the document multiple times.

## Design Patterns

- **Composite Pattern**: `MD_COMPOSITE` and `MD_BOX` for tree structures
- **Visitor Pattern**: `MD_VISITOR` for traversing and processing the AST
- **Strategy Pattern**: Different visitors for different output formats (XHTML, debug, custom)

# Markdown Features

This document provides a comprehensive overview of all Markdown features and their implementation status.

## Status Legend

- ✅ **Implemented** - Feature is fully implemented and tested
- 📝 **Todo** - Feature is planned for implementation
- 🔄 **Partial** - Feature is partially implemented

## Block-Level Features

| Feature | Status | Syntax Example |
|---------|--------|----------------|
| ATX Headings (`# H1` to `###### H6`) | ✅ Implemented | `# Heading 1` |
| Setext Headings (`H1\n====` or `H2\n----`) | ✅ Implemented | `Heading\n====` |
| Paragraphs | ✅ Implemented | Blank-line separated |
| Fenced Code Blocks (backticks ```) | ✅ Implemented | ` ```eiffel\ncode\n``` ` |
| Fenced Code Blocks (tildes `~~~`) | ✅ Implemented | ` ~~~eiffel\ncode\n~~~ ` |
| Indented Code Blocks (4 spaces) | ✅ Implemented | `    code` |
| Thematic Breaks (`---`, `***`, `___`) | ✅ Implemented | `---` |
| Blockquotes (`> ...`) | ✅ Implemented | `> quoted text` |
| Nested Blockquotes (`> > nested`) | ✅ Implemented | `> > nested quote` |
| Unordered Lists (`-`, `*`, `+`) | ✅ Implemented | `- item` (with nesting) |
| Ordered Lists (`1.`, `2)`) | ✅ Implemented | `1. item` (with nesting) |
| Lists with Multiple Paragraphs | ✅ Implemented | Blank line continuation |
| Lists Containing Code Blocks | ✅ Implemented | Code blocks in list items |
| Lists Containing Blockquotes | ✅ Implemented | Blockquotes in list items |
| Lazy List Continuation | ✅ Implemented | Indented continuation |
| Tables (basic) | ✅ Implemented | `\| Header \|` with separator |
| Table Column Alignment | ✅ Implemented | `\|:---\|:---:\|---:\|` (left, center, right) |
| Tables without Header Rows | ✅ Implemented | Separator line first, then body rows only |
| Tables with Empty Cells | ✅ Implemented | `\| A \| \| C \|` (empty middle cell) |
| Raw HTML Blocks | ✅ Implemented | `<div>...</div>` (until blank line) |
| Hard Line Breaks (2 spaces) | ✅ Implemented | Two trailing spaces + newline |
| Hard Line Breaks (backslash) | ✅ Implemented | Backslash at end of line |

## Inline Features

| Feature | Status | Syntax Example |
|---------|--------|----------------|
| Plain Text | ✅ Implemented | Regular text content |
| Emphasis with Asterisks (`*text*`) | ✅ Implemented | `*emphasized*` |
| Emphasis with Underscores (`_text_`) | ✅ Implemented | `_emphasized_` (word boundaries) |
| Strong with Asterisks (`**text**`) | ✅ Implemented | `**strong**` |
| Strong with Underscores (`__text__`) | ✅ Implemented | `__strong__` (word boundaries) |
| Code Spans (backticks) | ✅ Implemented | `` `code` `` (variable-length) |
| Inline Links (`[text](url)`) | ✅ Implemented | `[label](url)` |
| Reference-Style Links (`[text][ref]`) | ✅ Implemented | `[text][ref]`, `[text][]`, `[text]` with `[ref]: url` |
| Implicit Reference Links | ✅ Implemented | `[text][]` |
| Collapsed Reference Links | ✅ Implemented | `[text][]` |
| Link Titles | ✅ Implemented | `[text](url "title")` or `[text](url 'title')` |
| Images (`![alt](url)`) | ✅ Implemented | `![alt text](url)` |
| Reference-Style Images | ✅ Implemented | `![alt][ref]`, `![alt][]`, `![alt]` with `[ref]: url "title"` |
| Image Titles | ✅ Implemented | `![alt](url "title")` |
| Autolinks (`<url>`) | ✅ Implemented | `<https://example.com>` |
| Email Autolinks | ✅ Implemented | `<user@example.com>` |
| Strikethrough (`~~text~~`) | ✅ Implemented | `~~strikethrough~~` (GFM) |
| Task Lists | 📝 Todo | `- [ ]` or `- [x]` (GFM) |
| Entity References | ✅ Implemented | `&amp;`, `&lt;`, `&#169;`, `&#x26;` (named + numeric) |
| Basic Escaping | ✅ Implemented | `\*`, ``\````, `\[` |
| Full Backslash Escapes | ✅ Implemented | All punctuation characters (`\!`, `\"`, `\#`, ..., `\~`) |

## Output Formats

| Format | Status | Visitor / Usage |
|--------|--------|-----------------|
| XHTML (fragment) | ✅ Implemented | `MD_XHTML_GENERATOR` – renders AST to XHTML |
| CommonMark XML AST (1.0) | ✅ Implemented | `MD_AST_GENERATOR` – exports AST as XML (http://commonmark.org/xml/1.0) |

Use `document.process (create {MD_XHTML_GENERATOR}.make (buffer))` or `document.process (create {MD_AST_GENERATOR}.make (buffer))` after parsing.

## Advanced Features

| Feature | Status | Notes |
|---------|--------|-------|
| Link Reference Definitions | 📝 Todo | `[ref]: url` anywhere in document |
| Definition Lists | 📝 Todo | Not in CommonMark spec |
| Footnotes | ✅ Implemented | `[^1]` with `[^1]: definition` (extension) |
| Precedence Rules (full CommonMark) | 🔄 Partial | Basic precedence, missing edge cases |
| Whitespace Normalization | 🔄 Partial | Basic handling, missing full rules |
| Unicode Support | 🔄 Partial | Basic support, may need enhancement |
| Character Encoding | 🔄 Partial | Basic handling |

## Summary Statistics

| Category | Implemented | Partial | Todo | Total |
|----------|-------------|---------|------|-------|
| Block-Level | 21 | 0 | 0 | 21 |
| Inline | 13 | 0 | 7 | 20 |
| Advanced | 1 | 3 | 3 | 7 |
| **Total** | **35** | **3** | **8** | **46** |

**Current Coverage**: ~61% of CommonMark features implemented

## Implementation Priority

### High Priority (CommonMark Core)
- Reference-style links - Common in Markdown documents
- Hard line breaks - Frequently used
- Indented code blocks - Alternative to fenced blocks
- Emphasis with underscores - Common alternative syntax

### Medium Priority (CommonMark Standard)
- Link titles - Enhanced link functionality
- Autolinks - Convenience feature
- Nested blockquotes - Advanced formatting
- Table alignment - Enhanced table support
- Fenced code blocks with tildes - Alternative syntax

### Low Priority (Extensions/Edge Cases)
- Strikethrough - GitHub Flavored Markdown extension
- Task lists - GitHub Flavored Markdown extension
- Entity references - HTML compatibility
- Full backslash escape rules - Edge cases
- Advanced list features - Edge cases

## Notes

- **Focus**: The parser currently implements a pragmatic subset suitable for typical documents
- **Testing**: All implemented features have corresponding unit tests
- **Architecture**: Visitor-based AST design allows easy extension for new features
- **See Also**: [MISSING_FEATURES.md](MISSING_FEATURES.md) for detailed implementation notes on missing features

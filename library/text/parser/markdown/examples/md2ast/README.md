# md2ast

Console tool that converts a Markdown file to **CommonMark XML AST** (namespace http://commonmark.org/xml/1.0).

## Usage

```text
md2ast <input.md> <output.xml>
```

- **input.md**: path to the Markdown source file
- **output.xml**: path where the XML AST will be written

## Example

```text
md2ast ..\all_markdown_syntax.md all_markdown_syntax.xml
```

The generated XML is a full document with `<?xml version="1.0" encoding="UTF-8"?>` and root element `<document xmlns="http://commonmark.org/xml/1.0">`, containing block and inline elements such as `paragraph`, `heading`, `block_quote`, `list`, `list_item`, `text`, `strong`, `emph`, `link`, `image`, etc.

## Build

Open `md2ast.ecf` in EiffelStudio (or compile with ec) and build the `md2ast` target. The project depends on the parent `markdown` library (`..\..\markdown.ecf`).

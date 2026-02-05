## Examples

- `md2html/`: console tool converting a Markdown file to an HTML file.
  - `md.css`: modern stylesheet for rendering Markdown content in HTML (included automatically in generated HTML)
- `md2ast/`: console tool converting a Markdown file to CommonMark XML AST (http://commonmark.org/xml/1.0).
  - Usage: `md2ast <input.md> <output.xml>`
- `all_markdown_syntax.md`: comprehensive example demonstrating all Markdown syntax features (including unsupported ones).
- `supported_markdown_syntax.md`: example demonstrating only the Markdown syntax currently supported by this parser.
- `image.png`: minimal test image (1x1 pixel) used in the example markdown files for testing image syntax.

**Note**: The example markdown files reference `image.png` for testing image syntax. A minimal test image is provided, but you can replace it with any PNG image file for better visual testing.

**Note**: When using `md2html`, make sure `md.css` is in the same directory as the generated HTML file, or update the CSS link path in the generated HTML.


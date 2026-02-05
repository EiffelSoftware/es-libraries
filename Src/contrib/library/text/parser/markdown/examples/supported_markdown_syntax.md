# Supported Markdown Syntax Examples

This document demonstrates all Markdown syntax features currently supported by this parser.

**Note**: Some features (strikethrough, underscore emphasis, task lists) are GitHub Flavored Markdown extensions that require `using_github_extension` to be enabled on the parser. These are clearly marked in the document.

## Headings

### ATX Headings

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

### Setext Headings

Heading 1
========

Heading 2
--------

## Paragraphs

This is a paragraph. Paragraphs are separated by blank lines.

This is another paragraph with some **strong text** and *emphasized text*.

### Soft Line Breaks

This is a single paragraph
that spans multiple lines
but renders as one paragraph.

### Hard Line Breaks

This line ends with two spaces  
and continues on the next line.

This line ends with a backslash\
and also continues on the next line.

## Emphasis and Strong

*This is emphasized text*

**This is strong text**

***This is both emphasized and strong***

You can use emphasis and strong together: ***bold and italic*** or **bold with *italic* inside**.

### Underscore Emphasis and Strong (GitHub Flavored Markdown)

_This is emphasized text using underscores_

__This is strong text using underscores__

___This is both emphasized and strong using underscores___

**Note**: Underscore emphasis requires `using_github_extension` to be enabled on the parser.

## Code

### Inline Code

Use `code` in your text. You can also use ``double backticks`` for code with backticks inside: `` `code` ``.

You can use variable-length backtick delimiters: `` `code with `backticks` inside` `` or ``` ```code with ``backticks`` inside``` ```.

### Fenced Code Blocks (Backticks)

```eiffel
class
    EXAMPLE
feature
    make
        do
            print ("Hello, World!%N")
        end
end
```

```python
def hello():
    print("Hello, World!")
```

```
Plain code block without language identifier
```

### Fenced Code Blocks (Tildes)

~~~eiffel
class
    EXAMPLE
end
~~~

~~~
Plain code block with tildes
~~~

### Indented Code Blocks

    This is an indented code block
    with 4 spaces of indentation.
    It continues until a non-indented line.

## Lists

### Unordered Lists

- First item
- Second item
- Third item

### Unordered Lists with Different Markers

* Asterisk item
* Another asterisk item

+ Plus item
+ Another plus item

### Nested Unordered Lists

- First level
  - Second level
    - Third level
  - Back to second level
- Back to first level

### Ordered Lists

1. First item
2. Second item
3. Third item

### Ordered Lists with Parentheses

1) First item
2) Second item
3) Third item

### Nested Ordered Lists

1. First level
   1. Second level
      1. Third level
   2. Back to second level
2. Back to first level

### Mixed Lists

1. First ordered item
   - Nested unordered item
   - Another nested item
2. Second ordered item
   * Another nested unordered item

### Lists with Multiple Paragraphs

- First paragraph in list item

  Second paragraph in the same list item (indented)

- Another list item

### Lists with Code Blocks

- Item with fenced code block:

  ```eiffel
  class FOO
  end
  ```

- Item with indented code block:

      code here
      more code

### Lists with Blockquotes

- Item with blockquote:

  > quoted text
  > more quoted text

- Another item

### Task Lists (GitHub Flavored Markdown)

- [ ] Unchecked task
- [x] Checked task
- [X] Checked task (uppercase X also works)
- [ ] Another unchecked task

Task lists also work with ordered lists:

1. [ ] First unchecked task
2. [x] Second checked task
3. [ ] Third unchecked task

**Note**: Task lists require `using_github_extension` to be enabled on the parser.

## Blockquotes

> This is a blockquote.
> It can span multiple lines.
> All lines are part of the same quote.

> This is another blockquote.

> Blockquotes can contain **formatting** and `code`.

> They can also contain lists:
> - Item 1
> - Item 2

### Nested Blockquotes

> First level blockquote
> > Second level blockquote
> > > Third level blockquote
> > Back to second level
> Back to first level

## Links

### Inline Links

This is an [inline link](https://example.com) to example.com.

Links can contain [**formatted text**](https://example.com) or [*emphasized text*](https://example.org).

### Autolinks

Visit <https://example.com> for more information.

Email <user@example.com> for inquiries.

Autolinks work for both URLs and email addresses.

## Images

### Inline Images

![Alt text](image.png)

![Alt text with title](image.png "Image Title")

![Alt text with single-quoted title](image.png 'Image Title')

### Images with Formatted Alt Text

![Alt with *emphasis*](image.png)

![Alt with **strong**](image.png "Title")

![Alt with `code`](image.png)

### Reference-Style Images

![Alt text][img-ref]

![Alt text][]

![Alt text]

[img-ref]: image.png "Image Title"

## Tables

### Basic Tables

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

### Tables with Inline Formatting

| Header 1 | Header 2 |
|----------|----------|
| *Emphasized* | **Strong** |
| `Code` | [Link](url) |
| ![Image](img.png) | Plain text |

### Tables with Optional Leading/Trailing Pipes

Header 1 | Header 2 | Header 3
---------|---------|---------
Cell 1   | Cell 2   | Cell 3
Cell 4   | Cell 5   | Cell 6

## Thematic Breaks

---

***

___

## Raw HTML Blocks

Raw HTML is passed through unchanged. A block starts when a line begins with `<` followed by a letter (e.g. `<div>`, `<p>`), `</` and a letter, `<!--`, `<?`, or `<!`. The block continues until a blank line.

### Single-line HTML block

<div>Hello, world!</div>

<p>This is a paragraph tag.</p>

### Multi-line HTML block

<div>
  <p>Nested content</p>
  <span>More HTML</span>
</div>

### HTML comments

<!-- This is a comment and is output as raw HTML -->

## Strikethrough (GitHub Flavored Markdown)

~~This text is struck through~~

You can combine strikethrough with other formatting: ~~*emphasized and struck*~~ or ~~**strong and struck**~~.

**Note**: Strikethrough requires `using_github_extension` to be enabled on the parser.

## Escaping

\*Not emphasized\*

\`Not code\`

\[Not a link\]

\**Not strong\**

\~~Not strikethrough\~~

### Full Backslash Escapes

All punctuation characters can be escaped and rendered literally:

\! \" \# \$ \% \& \' \( \) \* \+ \, \- \. \/ \: \; \< \= \> \? \@ \[ \\ \] \^ \_ \` \{ \| \} \~

## Complex Examples

### Mixed Content

# Main Heading

This paragraph contains **strong text**, *emphasized text*, `code`, and a [link](https://example.com).

- List item with **formatting**
- List item with `code`
- List item with [link](url)
- List item with ![image](img.png "Title")

> Blockquote with **formatting** and `code`

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| *Italic* | **Bold** | `Code` |

---

### Nested Structures

1. First ordered item
   - Nested unordered item
     - Deeper nested item
   - Another nested item
2. Second ordered item

   > Blockquote inside list item
   > with multiple lines

3. Third ordered item with `code` and **formatting**

### Code Spans with Escaped Backticks

Here's code with a backtick: `` `code` ``

Here's code with multiple backticks: ``` ```code``` ```

### Images in Various Contexts

Paragraph with image: ![Alt text](image.png "Title")

- List item with image: ![Alt](img.png)
- Another item

| Image Column | Text Column |
|--------------|-------------|
| ![Image](img.png) | Some text |

> Blockquote with ![image](img.png "Title")

## Real-World Example

# Project Documentation

This is a **sample document** demonstrating the *supported* Markdown features.

## Features

The parser supports:

1. **Headings** - Both ATX and Setext styles
2. **Lists** - Ordered and unordered with nesting, multiple paragraphs, code blocks, blockquotes, and task lists (with GitHub extension)
3. **Code** - Inline code spans, fenced blocks (backticks and tildes), and indented code blocks
4. **Links and Images** - Inline style with titles, and autolinks (URLs and emails)
5. **Tables** - Basic table support
6. **Blockquotes** - Single and nested blockquotes
7. **Raw HTML Blocks** - Block-level HTML passed through until a blank line
8. **Line Breaks** - Soft and hard line breaks (two spaces or backslash)
9. **Formatting** - Emphasis and strong text (asterisks and underscores with GitHub extension)
10. **Strikethrough** - GitHub Flavored Markdown extension

### Code Example

```eiffel
class
    MARKDOWN_PARSER
feature
    parse (text: STRING): DOCUMENT
        do
            -- Parse markdown text
        end
end
```

### Reference Links

For more information, see the [documentation](README.md) or visit [the website](https://example.com).

---

## GitHub Flavored Markdown Extensions

The following features are available when `using_github_extension` is enabled on the parser:

- **Strikethrough**: `~~text~~`
- **Underscore Emphasis**: `_text_` and `__text__`
- **Task Lists**: `- [ ]` and `- [x]`

To enable these features:

```eiffel
local
    p: MD_PARSER
    doc: MD_DOCUMENT
do
    create p.make
    p.set_using_github_extension (True)
    doc := p.parse (markdown_text)
    -- Process document...
end
```

---

*This document demonstrates all currently supported Markdown syntax features.*

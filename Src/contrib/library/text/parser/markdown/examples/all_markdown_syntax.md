# Comprehensive Markdown Syntax Examples

This document demonstrates all Markdown syntax features, including those not yet supported by this parser. Features marked with ✅ are currently supported, while those marked with ❌ are not yet implemented.

## Headings

### ATX Headings ✅

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

### Setext Headings ✅

Heading 1
========

Heading 2
--------

## Paragraphs ✅

This is a paragraph. Paragraphs are separated by blank lines.

This is another paragraph with some **strong text** and *emphasized text*.

## Line Breaks

### Hard Line Breaks ✅

This line ends with two spaces  
and continues on the next line.

This line ends with a backslash\
and continues on the next line.

### Soft Line Breaks ✅

This is a single paragraph
that spans multiple lines
but renders as one paragraph.

## Emphasis and Strong ✅

*This is emphasized text*
_This is also emphasized (underscore) ✅_

**This is strong text**
__This is also strong (underscore) ✅__

***This is both emphasized and strong***
___This is also both (underscore) ✅___

## Code

### Inline Code ✅

Use `code` in your text. You can also use ``double backticks`` for code with backticks inside: `` `code` ``.

### Fenced Code Blocks ✅

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

### Fenced Code Blocks with Tildes ✅

~~~eiffel
class
    EXAMPLE
end
~~~

### Indented Code Blocks ✅

    This is an indented code block
    with 4 spaces of indentation.

## Lists

### Unordered Lists ✅

- First item
- Second item
- Third item

### Unordered Lists with Different Markers ✅

* Asterisk item
* Another asterisk item

+ Plus item
+ Another plus item

### Nested Unordered Lists ✅

- First level
  - Second level
    - Third level
  - Back to second level
- Back to first level

### Ordered Lists ✅

1. First item
2. Second item
3. Third item

### Ordered Lists with Parentheses ✅

1) First item
2) Second item
3) Third item

### Nested Ordered Lists ✅

1. First level
   1. Second level
      1. Third level
   2. Back to second level
2. Back to first level

### Mixed Lists ✅

1. First ordered item
   - Nested unordered item
   - Another nested item
2. Second ordered item
   * Another nested unordered item

### Lists with Multiple Paragraphs ✅

- First item

  This is a second paragraph in the same list item.

- Second item

### Lists with Code Blocks ✅

- Item with code block:

  ```eiffel
  code here
  ```

- Another item

### Lists with Blockquotes ✅

- Item with blockquote:

  > quoted text

- Another item

### Task Lists (GitHub Flavored Markdown) ✅

- [ ] Unchecked task
- [x] Checked task
- [ ] Another unchecked task

## Blockquotes ✅

> This is a blockquote.
> It can span multiple lines.
> All lines are part of the same quote.

> This is another blockquote.

### Nested Blockquotes ✅

> First level
> > Second level
> > > Third level

## Links ✅

### Inline Links ✅

This is an [inline link](https://example.com) to example.com.

This is a [link with title](https://example.com "Example Title").

### Reference-Style Links ✅

This is a [reference-style link][ref1].

This is an [implicit reference link][].

This is a [collapsed reference link][].

[ref1]: https://example.com
[implicit reference link]: https://example.org
[collapsed reference link]: https://example.net "Optional Title"

### Autolinks ✅

<https://example.com>

<user@example.com>

### Raw HTML Links ✅

<a href="https://example.com" target="_blank">Open in new tab</a>

## Images ✅

### Inline Images ✅

![Alt text](image.png)

![Alt text with title](image.png "Image Title")

![Alt text with single-quoted title](image.png 'Image Title')

### Images with Formatted Alt Text ✅

![Alt with *emphasis*](image.png)

![Alt with **strong**](image.png "Title")

### Reference-Style Images ✅

![Alt text][img-ref]

![Alt text][]

![Alt text]

[img-ref]: image.png "Image Title"
[Alt text]: image.png "Image Title"

## Tables ✅

### Basic Tables ✅

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

### Tables with Alignment ✅

| Left | Center | Right |
|:-----|:------:|------:|
| Left aligned | Center aligned | Right aligned |
| More left | More center | More right |

### Tables with Inline Formatting ✅

| Header 1 | Header 2 |
|----------|----------|
| *Emphasized* | **Strong** |
| `Code` | [Link](url) |

## Thematic Breaks ✅

---

***

___

## HTML Blocks ✅

Raw HTML blocks are supported. A block starts when a line begins with `<` followed by a letter, `</`+letter, `<!--`, `<?`, or `<!`, and continues until a blank line.

<div>
This is an HTML block.
</div>

<p>This is a paragraph HTML block.</p>

## Entity References ✅

&amp; &lt; &gt; &quot; &apos; &#169; &#x26;

## Escaping ✅

\*Not emphasized\*

\`Not code\`

\[Not a link\]

### Full Backslash Escapes ✅

All punctuation characters can be escaped and rendered literally:

\! \" \# \$ \% \& \' \( \) \* \+ \, \- \. \/ \: \; \< \= \> \? \@ \[ \\ \] \^ \_ \` \{ \| \} \~

## Strikethrough (GitHub Flavored Markdown) ✅

~~This text is struck through~~

## Footnotes ✅

This is a footnote reference[^1].

[^1]: This is the footnote definition.

## Definition Lists (not in CommonMark) ✅

Term 1
: Definition 1

Term 2
: Definition 2a
: Definition 2b

## Complex Examples

### Mixed Content ✅

# Main Heading

This paragraph contains **strong text**, *emphasized text*, `code`, and a [link](https://example.com).

- List item with **formatting**
- List item with `code`
- List item with [link](url)

> Blockquote with **formatting** and `code`

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |

---

### Code in Lists ✅

1. First item

   ```eiffel
   code block
   ```

2. Second item

### Blockquote in Lists ✅

1. First item

   > Blockquote here

2. Second item

## Notes

- Features marked with ✅ are fully supported by this parser
- Features marked with ❌ are not yet implemented
- Some features may have partial support or edge case limitations
- This document is based on CommonMark specification with GitHub Flavored Markdown extensions

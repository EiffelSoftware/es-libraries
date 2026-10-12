# ePDF

Eiffel library to read, create, modify and encrypt PDF documents, following
the ISO 32000-1:2008 (PDF 1.7) specification.

## Features

- **Parsing**: classic xref tables and xref streams, object streams,
  linearized files, lazy object loading with caching.
- **Writing**: full rewrite or incremental updates (`PDF_INCREMENTAL_WRITER`).
- **Modification**: add footers (single or multi-line, left/center/right) to
  every page, manage page resources and fonts, add new objects to an existing
  document.
- **Fonts**: standard 14 Type 1 fonts, TrueType fonts and font descriptors,
  ToUnicode CMaps.
- **Images**: image and form XObjects.
- **Filters**: FlateDecode (zlib), LZWDecode, ASCII85Decode, ASCIIHexDecode,
  DCTDecode (JPEG, via the bundled public-domain `stb_image.h`).
- **Security**: Standard security handler with RC4, AES-128 and AES-256,
  user/owner passwords and permission flags.

## Usage

Add the library to your project configuration:

```xml
<library name="epdf" location="$ISE_LIBRARY\contrib\library\text\document\epdf\epdf.ecf"/>
```

Dependencies: `base`, `time`, `C_library/zlib` and the unstable `crypto`
library (used as a cryptographically secure random generator). On Windows,
`bcrypt.lib` is linked automatically.

### Load a PDF and add a footer

```eiffel
	add_footer (a_input, a_output: READABLE_STRING_GENERAL)
		local
			src: PDF_FILE_BYTE_SOURCE
			doc: PDF_DOCUMENT
			footer: PDF_FOOTER_SERVICE
		do
			create src.make_from_file (a_input)
			create doc.make_from_source (src)
			if doc.is_loaded then
				create footer.make
				footer.set_font_size (8.0)
				footer.set_margin (20.0)
				footer.add_footer_to_document (doc, "Personal copy - do not distribute")
				doc.write_to_file (a_output)
			end
		end
```

### Inspect a document

```eiffel
	create src.make_from_file ("document.pdf")
	create doc.make_from_source (src)
	print (doc.version)
	if attached doc.catalog as l_catalog then
		-- Navigate the object tree, using `doc.get_object (ref.object_id)` to resolve references.
	end
```

### Encrypt a document

See [example/pdf_processor_app.e](example/pdf_processor_app.e) for a complete
program that adds a footer and AES encryption with restricted permissions
(`PDF_PERMISSIONS`, `PDF_STANDARD_SECURITY_HANDLER`), driven by
[example/config.ini](example/config.ini).

## Example

`example/example.ecf` builds `pdf_processor`, a console tool that reads
`config.ini` from the current directory, then inserts a message page, adds a
footer and encrypts the input PDF. The default configuration uses a sample
from `testing/pdf`.

## Tests

`testing/testing.ecf` contains an AutoTest test suite and a `TEST_RUNNER`
root class running a quick subset (SHA, AES, encryption, resource management).
Tests locate their input files in `testing/pdf` relative to the **current
directory**, so run them from this library folder. Output goes to
`testing/test_output` (see `testing/cleanup_test_output.*`).

Only small sample PDFs are distributed. Several integration tests use larger
real-world documents that are not included (for instance `ITIL.pdf`,
`OOSC2.pdf`, `PDF32000_2008.pdf`, `v112-367_3_STANDARD.pdf`,
`probable-provable.pdf`, `sample-pdf-with-images.pdf`,
`Bodea Brochure - Linearized.pdf`). Those tests fail with a file-not-found
error unless you copy suitable PDFs with these names into `testing/pdf`.

## License

Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt).

`spec/include/stb_image.h` is by Sean Barrett and others, released into the
public domain (or MIT license, at your choice).

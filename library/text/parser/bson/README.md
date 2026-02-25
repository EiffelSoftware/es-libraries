# BSON Library for Eiffel

A pure Eiffel library for parsing and generating BSON (Binary JSON) data.

## Overview

BSON is a binary-encoded serialization of JSON-like documents. This library provides:

- **Parsing**: Read binary BSON data into Eiffel objects
- **Generation**: Write Eiffel objects as binary BSON data
- **Full type support**: All BSON types from the 1.1 specification

## Features

- Complete BSON 1.1 specification support
- Design by Contract (DbC) throughout
- Similar API to the Eiffel JSON library
- Visitor pattern for traversing BSON structures
- Little-endian byte order handling (per BSON spec)

## Supported Types

| BSON Type | Eiffel Class | Description |
|-----------|--------------|-------------|
| Double | `BSON_DOUBLE` | 64-bit IEEE 754 floating point |
| String | `BSON_STRING` | UTF-8 string |
| Document | `BSON_DOCUMENT` | Embedded document |
| Array | `BSON_ARRAY` | Array (document with numeric keys) |
| Binary | `BSON_BINARY` | Binary data with subtype |
| ObjectId | `BSON_OBJECT_ID` | 12-byte unique identifier |
| Boolean | `BSON_BOOLEAN` | True or false |
| DateTime | `BSON_DATETIME` | UTC datetime (milliseconds) |
| Null | `BSON_NULL` | Null value |
| Regex | `BSON_REGEX` | Regular expression |
| JavaScript | `BSON_JAVASCRIPT` | JavaScript code |
| Int32 | `BSON_INT32` | 32-bit signed integer |
| Timestamp | `BSON_TIMESTAMP` | MongoDB internal timestamp |
| Int64 | `BSON_INT64` | 64-bit signed integer |
| MinKey | `BSON_MIN_KEY` | Minimum key value |
| MaxKey | `BSON_MAX_KEY` | Maximum key value |

## Usage

### Creating a Document

```eiffel
local
    doc: BSON_DOCUMENT
    arr: BSON_ARRAY
do
    create doc.make_empty
    doc.put_string ("John Doe", "name")
    doc.put_int32 (30, "age")
    doc.put_boolean (True, "active")
    
    create arr.make_empty
    arr.extend_string ("reading")
    arr.extend_string ("coding")
    doc.put (arr, "hobbies")
end
```

### Writing BSON Binary Data

```eiffel
local
    doc: BSON_DOCUMENT
    writer: BSON_WRITER
    bytes: ARRAY [NATURAL_8]
do
    create doc.make_empty
    doc.put_string ("Hello", "message")
    
    create writer.make
    bytes := writer.to_bytes (doc)
    -- bytes now contains the binary BSON representation
end
```

### Parsing BSON Binary Data

```eiffel
local
    parser: BSON_PARSER
    doc: detachable BSON_DOCUMENT
    bytes: ARRAY [NATURAL_8]
do
    -- bytes contains BSON binary data
    create parser.make
    doc := parser.parse (bytes)
    
    if attached doc as d then
        if attached d.string_value ("message") as msg then
            print (msg)
        end
    else
        print ("Parse error: " + parser.last_error)
    end
end
```

### Accessing Values

```eiffel
local
    doc: BSON_DOCUMENT
do
    -- Type-safe access with typed items
    if attached doc.string_item ("name") as s then
        print (s.value)
    end
    
    -- Direct value access (requires value exists)
    print (doc.int32_value ("age"))
    print (doc.boolean_value ("active"))
    
    -- Nested document access
    if attached doc.document_item ("address") as addr then
        print (addr.string_value ("city"))
    end
    
    -- Array access
    if attached doc.array_item ("items") as items then
        across items as item loop
            item.accept (my_visitor)
        end
    end
end
```

### Visitor Pattern

```eiffel
class
    MY_BSON_PROCESSOR

inherit
    BSON_ITERATOR
        redefine
            visit_bson_string,
            visit_bson_int32
        end

feature -- Visitor

    visit_bson_string (a_string: BSON_STRING)
        do
            print ("String: " + a_string.value)
        end

    visit_bson_int32 (an_int: BSON_INT32)
        do
            print ("Int32: " + an_int.value.out)
        end

end
```

## Library Structure

```
library/
├── kernel/           -- Core BSON value types
│   ├── bson_value.e
│   ├── bson_document.e
│   ├── bson_array.e
│   ├── bson_string.e
│   ├── bson_double.e
│   ├── bson_int32.e
│   ├── bson_int64.e
│   ├── bson_boolean.e
│   ├── bson_null.e
│   ├── bson_binary.e
│   ├── bson_object_id.e
│   ├── bson_datetime.e
│   ├── bson_timestamp.e
│   ├── bson_regex.e
│   ├── bson_javascript.e
│   ├── bson_min_key.e
│   ├── bson_max_key.e
│   └── bson_constants.e
├── parser/           -- BSON parser
│   └── bson_parser.e
└── utility/
    ├── visitor/      -- Visitor pattern
    │   ├── bson_visitor.e
    │   └── bson_iterator.e
    └── writer/       -- BSON writer
        └── bson_writer.e
```

## Requirements

- EiffelStudio 21.11 or later
- Base library
- Time library

## References

- [BSON Specification](https://bsonspec.org/)
- [BSON Spec 1.1](https://bsonspec.org/spec.html)

## License

MIT License

## Author

Jocelyn Fiat and Eiffel Software, 2026

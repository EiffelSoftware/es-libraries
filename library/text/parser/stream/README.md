# Stream Library for Eiffel

A lightweight Eiffel library providing input stream abstractions for sequential reading of character and byte data from various sources.

## Overview

The Stream library defines a hierarchy of deferred input stream classes that abstract over different data sources. It supports both **character-based** (`CHARACTER_8`) and **byte-based** (`NATURAL_8`) input streams, with implementations for strings, files, byte arrays, and raw memory pointers.

## Features

- **Unified interface**: Common `INPUT_STREAM` abstraction with position tracking (index, line, column)
- **Character streams**: Read text character-by-character from strings or files
- **Byte streams**: Read raw bytes from strings, arrays, files, or memory pointers
- **Chunked file reading**: Efficient buffered reading for large files
- **Design by Contract**: Full DbC support throughout

## Class Hierarchy

```
INPUT_STREAM (deferred)
├── NULL_INPUT_STREAM
├── CHARACTER_8_INPUT_STREAM (deferred)
│   ├── FILE_CHARACTER_8_INPUT_STREAM
│   └── STRING_8_CHARACTER_8_INPUT_STREAM
└── NATURAL_8_INPUT_STREAM (deferred)
    ├── NULL_NATURAL_8_INPUT_STREAM
    ├── BYTE_ARRAY_INPUT_STREAM
    ├── STRING_8_NATURAL_8_INPUT_STREAM
    ├── FILE_NATURAL_8_INPUT_STREAM
    └── POINTER_NATURAL_8_INPUT_STREAM
```

## Installation

Add the library to your ECF file:

```xml
<library name="stream" location="$ISE_LIBRARY\contrib\library\text\parser\stream\stream.ecf"/>
```

Or use Iron package manager:

```
iron install text/parser/stream
```

## Usage

### Reading from a String (Characters)

```eiffel
local
    stream: STRING_8_CHARACTER_8_INPUT_STREAM
do
    create stream.make ("Hello World")
    from stream.start until stream.end_of_input loop
        stream.next
        if not stream.end_of_input then
            print (stream.last_character)
        end
    end
end
```

### Reading from a File (Characters)

```eiffel
local
    stream: FILE_CHARACTER_8_INPUT_STREAM
do
    create stream.make_with_path (create {PATH}.make_from_string ("data.txt"))
    from stream.start until stream.end_of_input loop
        stream.next
        if not stream.end_of_input then
            -- stream.last_character, stream.line, stream.column available
            print (stream.last_character)
        end
    end
    stream.close
end
```

### Reading Bytes from a String

```eiffel
local
    stream: STRING_8_NATURAL_8_INPUT_STREAM
do
    create stream.make ("binary data")
    from stream.start until stream.end_of_input loop
        stream.next
        if not stream.end_of_input then
            print (stream.last_byte.out + " ")
        end
    end
end
```

### Reading Bytes from a Byte Array

```eiffel
local
    stream: BYTE_ARRAY_INPUT_STREAM
    bytes: ARRAY [NATURAL_8]
do
    bytes := <<0x48, 0x65, 0x6C, 0x6C, 0x6F>>  -- "Hello"
    create stream.make (bytes)
    from stream.start until stream.end_of_input loop
        stream.next
        if not stream.end_of_input then
            print (stream.last_byte.to_character_8)
        end
    end
end
```

### Position Tracking

All streams provide position information useful for parsers and error reporting:

```eiffel
-- After each next/read_character call:
stream.index   -- 0-based position in stream
stream.line    -- Current line number (1-based)
stream.column  -- Current column number
```

## Library Structure

```
stream/
├── stream.ecf              -- Main library configuration
├── input/
│   ├── input_stream.e      -- Base deferred class
│   ├── null_input_stream.e -- Null object pattern
│   ├── character_8/        -- Character-based streams
│   │   ├── character_8_input_stream.e
│   │   ├── file_character_8_input_stream.e
│   │   └── string_8_character_8_input_stream.e
│   └── natural_8/          -- Byte-based streams
│       ├── natural_8_input_stream.e
│       ├── null_natural_8_input_stream.e
│       ├── byte_array_input_stream.e
│       ├── string_8_natural_8_input_stream.e
│       ├── file_natural_8_input_stream.e
│       └── pointer_natural_8_input_stream.e
└── tests/
    ├── tests.ecf
    └── application.e
```

## Requirements

- EiffelStudio 21.11 or later
- Base library

## License

Eiffel Forum License v2

## Copyright

Copyright (c) 1984-2014, Eiffel Software and others

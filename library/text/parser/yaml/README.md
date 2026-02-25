# YAML Library for Eiffel

A YAML parser and generator library for Eiffel, implementing YAML 1.2.2 specification.

## Features

- **Parse YAML content** from strings
- **Generate YAML output** from Eiffel objects
- **Support for all YAML data types**:
  - Scalars (strings, integers, floats, booleans, null)
  - Sequences (arrays/lists)
  - Mappings (objects/dictionaries)
- **Flow and block styles** for collections
- **Document support** with directives
- **Anchors and aliases** for node reuse
- **Visitor pattern** for traversing YAML trees

## Installation

Add the library to your ECF file:

```xml
<library name="yaml" location="$ISE_LIBRARY\contrib\library\text\parser\yaml\library\yaml.ecf"/>
```

## Usage

### Parsing YAML

```eiffel
local
    parser: YAML_PARSER
    value: detachable YAML_VALUE
do
    create parser.make
    value := parser.parse_string ("name: John%Nage: 30")
    if attached {YAML_MAPPING} value as mapping then
        if attached mapping.value_at ("name") as name_value then
            print (name_value.as_scalar.value)
        end
    end
end
```

### Building YAML Programmatically

```eiffel
local
    mapping: YAML_MAPPING
    sequence: YAML_SEQUENCE
do
    create mapping.make
    mapping.put_string ("name", create {YAML_SCALAR}.make ("John"))
    mapping.put_string ("age", create {YAML_SCALAR}.make_integer (30))
    
    create sequence.make
    sequence.extend (create {YAML_SCALAR}.make ("item1"))
    sequence.extend (create {YAML_SCALAR}.make ("item2"))
    mapping.put_string ("items", sequence)
end
```

### Writing YAML

```eiffel
local
    writer: YAML_WRITER
    mapping: YAML_MAPPING
do
    create mapping.make
    mapping.put_string ("key", create {YAML_SCALAR}.make ("value"))
    
    create writer.make
    writer.write_value (mapping)
    print (writer.output)
end
```

## Classes

### Core Classes

- `YAML_VALUE` - Abstract base class for all YAML values
- `YAML_SCALAR` - Scalar values (strings, numbers, booleans, null)
- `YAML_SEQUENCE` - Ordered collection of values
- `YAML_MAPPING` - Key-value pair collection
- `YAML_DOCUMENT` - YAML document with optional directives

### Parser and Writer

- `YAML_PARSER` - Parse YAML strings into value trees
- `YAML_WRITER` - Generate YAML output from value trees

### Visitors

- `YAML_VISITOR` - Abstract visitor for traversing YAML trees
- `YAML_ITERATOR` - Iterate through all nodes
- `YAML_PRETTY_STRING_VISITOR` - Generate pretty-printed output

## Running Tests

```
ec -config test\autotest\test_suite\test_suite.ecf -target tests -tests
```

## License

This library is part of the Eiffel Studio contrib libraries.

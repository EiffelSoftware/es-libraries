# YAML/JSON Converter Tool

A command-line tool to convert between YAML and JSON formats.

## Building

```bash
ec -config yaml_json.ecf -target yaml_json -c_compile -finalize
```

The executable will be created at `EIFGENs/yaml_json/F_code/yaml_json.exe`.

## Usage

```
yaml_json <command> <input_file> [output_file] [options]
```

### Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `yaml2json` | `y2j` | Convert YAML to JSON |
| `json2yaml` | `j2y` | Convert JSON to YAML |
| `--help` | `-h` | Show help message |

### Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--pretty` | `-p` | Pretty print output with indentation |

### Examples

**Convert YAML to JSON (output to stdout):**
```bash
yaml_json yaml2json config.yaml
```

**Convert YAML to JSON (save to file, pretty printed):**
```bash
yaml_json yaml2json config.yaml config.json --pretty
```

**Convert JSON to YAML:**
```bash
yaml_json json2yaml data.json data.yaml
```

**Using short commands:**
```bash
yaml_json y2j input.yaml output.json -p
yaml_json j2y input.json output.yaml
```

## Supported Features

### YAML to JSON
- Scalars (strings, integers, floats, booleans, null)
- Sequences (arrays)
- Mappings (objects)
- Flow style `[a, b, c]` and `{key: value}`
- Block style with indentation
- Comments are ignored in output

### JSON to YAML
- All JSON types convert to YAML equivalents
- Nested structures are properly indented
- Strings are quoted when necessary

## Dependencies

- YAML library (`library/yaml.ecf`)
- JSON library (`$ISE_LIBRARY/contrib/library/text/parser/json/library/json.ecf`)

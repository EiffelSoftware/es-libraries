"""Find (and optionally escape) non-ASCII characters inside Eiffel string and character literals.

EiffelStudio reads source files without a byte order mark as ISO-8859-1, so a UTF-8 literal such
as "日" compiles to three Latin-1 characters (review finding U12). Writing the character as a
%/0x65E5/ escape keeps the source ASCII and the literal correct.

Usage:
    python tools/escape_non_ascii_literals.py [--fix] PATH...

PATH is a file or a directory (searched for *.e). Without --fix, every non-ASCII character found
in a literal is listed and the exit status is 1 if there is any. With --fix, the files are
rewritten in place. Comments and verbatim strings ("[ ... ]" / "{ ... }") are left alone: '%'
escapes are not interpreted in verbatim strings, so a non-ASCII character there is only reported.
"""

import os
import sys


def escape(ch):
    return '%/0x{:X}/'.format(ord(ch))


def scan_line(line, state):
    """Return (new_line, findings, state) for one line.

    `state` is None, or the closing marker of a verbatim string that is still open.
    `findings` holds (column, character, kind) for each non-ASCII character in a literal.
    """
    out = []
    findings = []
    i = 0
    n = len(line)
    if state is not None:
        # Inside a verbatim string: it ends on a line whose first non-blank text is the marker
        if line.strip().startswith(state):
            state = None
        else:
            for col, ch in enumerate(line):
                if ord(ch) > 127:
                    findings.append((col + 1, ch, 'verbatim'))
            return line, findings, state
    while i < n:
        ch = line[i]
        if ch == '-' and i + 1 < n and line[i + 1] == '-':
            out.append(line[i:])
            break
        if ch == '"':
            # Verbatim string opener: " followed by optional text and [ or { at end of line
            rest = line[i + 1:].rstrip('\r\n')
            if rest and rest[-1] in '[{' and '"' not in rest:
                state = ']"' if rest[-1] == '[' else '}"'
                out.append(line[i:])
                break
            j = i + 1
            buf = ['"']
            while j < n and line[j] != '"':
                c = line[j]
                if c == '%' and j + 1 < n:
                    if line[j + 1] == '/':
                        k = line.find('/', j + 2)
                        if k == -1:
                            k = n - 1
                        buf.append(line[j:k + 1])
                        j = k + 1
                    else:
                        buf.append(line[j:j + 2])
                        j += 2
                    continue
                if ord(c) > 127:
                    findings.append((j + 1, c, 'string'))
                    buf.append(escape(c))
                else:
                    buf.append(c)
                j += 1
            if j < n:
                buf.append('"')
            out.append(''.join(buf))
            i = j + 1
            continue
        if ch == "'":
            j = i + 1
            if j < n and line[j] == '%':
                # An escaped character: '%X' or '%/code/'
                if j + 1 < n and line[j + 1] == '/':
                    end = line.find('/', j + 2)
                    if end == -1:
                        end = n - 1
                else:
                    end = j + 1
                k = min(end + 1, n - 1)  # the closing quote
                out.append(line[i:k + 1])
                i = k + 1
                continue
            if j + 1 < n and line[j + 1] == "'" and ord(line[j]) > 127:
                findings.append((j + 1, line[j], 'character'))
                out.append("'" + escape(line[j]) + "'")
                i = j + 2
                continue
            out.append(ch)
            i += 1
            continue
        out.append(ch)
        i += 1
    return ''.join(out), findings, state


def eiffel_files(paths):
    for p in paths:
        if os.path.isdir(p):
            for root, _dirs, files in os.walk(p):
                if 'EIFGENs' in root:
                    continue
                for f in sorted(files):
                    if f.endswith('.e'):
                        yield os.path.join(root, f)
        else:
            yield p


def main(argv):
    fix = '--fix' in argv
    paths = [a for a in argv if a != '--fix']
    if not paths:
        print(__doc__)
        return 2
    total = 0
    for path in eiffel_files(paths):
        with open(path, encoding='utf-8', newline='') as f:
            lines = f.readlines()
        state = None
        new_lines = []
        changed = False
        for number, line in enumerate(lines, 1):
            new_line, findings, state = scan_line(line, state)
            for col, ch, kind in findings:
                total += 1
                print('{}:{}:{}: U+{:04X} in a {} literal'.format(path, number, col, ord(ch), kind))
            if new_line != line:
                changed = True
            new_lines.append(new_line)
        if fix and changed:
            with open(path, 'w', encoding='utf-8', newline='') as f:
                f.writelines(new_lines)
    print('{} non-ASCII character(s) in literals'.format(total))
    return 1 if total and not fix else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

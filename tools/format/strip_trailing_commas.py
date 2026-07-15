"""Strip trailing commas before ) ] } in Dart files, skipping strings/comments.

Run: python tools/format/strip_trailing_commas.py <file1> [file2 ...]
Or:   python tools/format/strip_trailing_commas.py --glob 'lib/**/*.dart'
"""

import sys
import os
import glob as globlib
import argparse


def strip_trailing_commas(content: str) -> str:
    result = []
    i = 0
    n = len(content)

    while i < n:
        c = content[i]

        # Line comment //
        if c == '/' and i + 1 < n and content[i + 1] == '/':
            j = content.find('\n', i)
            if j == -1:
                result.append(content[i:])
                break
            result.append(content[i:j])
            i = j
            continue

        # Block comment /* ... */
        if c == '/' and i + 1 < n and content[i + 1] == '*':
            j = content.find('*/', i + 2)
            if j == -1:
                result.append(content[i:])
                break
            result.append(content[i:j + 2])
            i = j + 2
            continue

        # Raw string r'...' or r"..."
        if c == 'r' and i + 1 < n and content[i + 1] in ('"', "'"):
            quote = content[i + 1]
            if i + 3 < n and content[i + 2] == quote and content[i + 3] == quote:
                end = content.find(quote * 3, i + 4)
                if end == -1:
                    result.append(content[i:])
                    break
                result.append(content[i:end + 3])
                i = end + 3
            else:
                j = i + 2
                while j < n and content[j] != quote and content[j] != '\n':
                    if content[j] == '\\' and j + 1 < n:
                        j += 2
                    else:
                        j += 1
                if j < n and content[j] == quote:
                    result.append(content[i:j + 1])
                    i = j + 1
                else:
                    result.append(content[i:j])
                    i = j
            continue

        # String '...' or "..." (single or triple)
        if c in ('"', "'"):
            quote = c
            if i + 2 < n and content[i + 1] == quote and content[i + 2] == quote:
                end = content.find(quote * 3, i + 3)
                if end == -1:
                    result.append(content[i:])
                    break
                result.append(content[i:end + 3])
                i = end + 3
            else:
                j = i + 1
                while j < n and content[j] != quote and content[j] != '\n':
                    if content[j] == '\\' and j + 1 < n:
                        j += 2
                    else:
                        j += 1
                if j < n and content[j] == quote:
                    result.append(content[i:j + 1])
                    i = j + 1
                else:
                    result.append(content[i:j])
                    i = j
            continue

        # Trailing comma before ) ] }
        if c == ',':
            j = i + 1
            while j < n and content[j] in ' \t\r\n':
                j += 1
            if j < n and content[j] in ')]}':
                # Remove the comma; preserve whitespace and closing bracket.
                result.append(content[i + 1:j])
                result.append(content[j])
                i = j + 1
                continue

        result.append(c)
        i += 1

    return ''.join(result)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('files', nargs='*')
    parser.add_argument('--glob', action='append', default=[],
                        help='Glob pattern, e.g. "lib/**/*.dart". May repeat.')
    args = parser.parse_args()

    paths = list(args.files)
    for pattern in args.glob:
        paths.extend(globlib.glob(pattern, recursive=True))

    if not paths:
        parser.error('no input files')

    modified = 0
    for path in paths:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = strip_trailing_commas(content)
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            modified += 1
            print(f'M: {path}')

    print(f'\n{modified} file(s) modified')


if __name__ == '__main__':
    main()

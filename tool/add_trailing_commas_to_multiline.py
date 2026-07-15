"""Add trailing commas to multi-line function call/declaration argument
lists that lack them. Conservative: only processes () pairs where the (
is immediately preceded by an identifier char, >, ], or ) — this skips
control-flow headers (if/for/while/switch/catch) because dart format
normalizes them to `keyword (expr)` with a space before (. Does NOT
touch [] or {} pairs to avoid corrupting list/index, blocks, class
bodies, switch bodies, and map/set literals.

Run after strip_trailing_commas.py + dart format. Then re-run dart format
to get 2-space block indent on the newly-comma'd multi-line calls.
"""

import sys
import os
import glob as globlib
import argparse


def _skip_string_or_comment(content, i, n):
    c = content[i]
    if c == '/' and i + 1 < n and content[i + 1] == '/':
        j = content.find('\n', i)
        return n if j == -1 else j
    if c == '/' and i + 1 < n and content[i + 1] == '*':
        j = content.find('*/', i + 2)
        return n if j == -1 else j + 2
    if c == 'r' and i + 1 < n and content[i + 1] in ('"', "'"):
        quote = content[i + 1]
        if i + 3 < n and content[i + 2] == quote and content[i + 3] == quote:
            end = content.find(quote * 3, i + 4)
            return n if end == -1 else end + 3
        j = i + 2
        while j < n and content[j] != quote and content[j] != '\n':
            if content[j] == '\\' and j + 1 < n:
                j += 2
            else:
                j += 1
        return j + 1 if j < n and content[j] == quote else j
    if c in ('"', "'"):
        quote = c
        if i + 2 < n and content[i + 1] == quote and content[i + 2] == quote:
            end = content.find(quote * 3, i + 3)
            return n if end == -1 else end + 3
        j = i + 1
        while j < n and content[j] != quote and content[j] != '\n':
            if content[j] == '\\' and j + 1 < n:
                j += 2
            else:
                j += 1
        return j + 1 if j < n and content[j] == quote else j
    return None


def _is_call_open(content, open_pos):
    """True if the ( at open_pos looks like a function call/declaration
    opener (not control flow)."""
    if open_pos == 0:
        return False
    prev = content[open_pos - 1]
    return prev.isalnum() or prev == '_' or prev in '>]})'


def _last_significant_char_before(content, close_pos):
    """Return the index of the last non-whitespace char before close_pos,
    skipping back over a trailing // line comment if present. Returns -1
    if nothing meaningful is found."""
    j = close_pos - 1
    while j >= 0 and content[j] in ' \t\r\n':
        j -= 1
    if j < 0:
        return -1
    # If we hit a // comment, walk back to before it.
    if j > 0 and content[j] == '/' and content[j - 1] == '/':
        k = j - 2
        while k >= 0 and content[k] in ' \t':
            k -= 1
        if k < 0:
            return -1
        # The char at k might itself be inside a comment or string; we
        # trust dart format has kept args on their own lines.
        return k
    return j


def add_trailing_commas(content):
    n = len(content)
    pairs = []
    stack = []
    i = 0
    while i < n:
        skip = _skip_string_or_comment(content, i, n)
        if skip is not None:
            i = skip
            continue
        c = content[i]
        if c in '([{':
            stack.append((i, c))
        elif c in ')]}':
            if stack:
                open_pos, open_char = stack.pop()
                expected = {'(': ')', '[': ']', '{': '}'}[open_char]
                if c == expected and open_char == '(':
                    pairs.append((open_pos, i))
        i += 1

    insertions = []
    for open_pos, close_pos in pairs:
        if not _is_call_open(content, open_pos):
            continue
        segment = content[open_pos + 1:close_pos]
        if '\n' not in segment:
            continue
        # Skip for-loop headers: they contain ;
        if ';' in segment:
            continue
        j = _last_significant_char_before(content, close_pos)
        if j < 0:
            continue
        ch = content[j]
        if ch == ',':
            continue
        if ch in '({[}':
            continue
        # Don't add if the last token is a binary operator (unlikely
        # after dart format, but guard anyway).
        if ch in '+-*/%<>=&|^~?!:':
            continue
        insertions.append(close_pos)

    result = content
    for pos in sorted(insertions, reverse=True):
        result = result[:pos] + ',' + result[pos:]
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('files', nargs='*')
    parser.add_argument('--glob', action='append', default=[])
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
        new_content = add_trailing_commas(content)
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            modified += 1
            print(f'M: {path}')

    print(f'\n{modified} file(s) modified')


if __name__ == '__main__':
    main()

"""Physically expand single-line calls/declarations that should be
multi-line per STYLE.md §2b argument-count rule. Inserts real newlines
and a trailing comma so dart format keeps the multi-line form.

Rules:
- 4+ args: always expand.
- 3 args: expand if full line (with indent) > 160 chars.
- 1-2 args: leave (page_width 200 handles them).

Only touches single-line `()` constructs whose `(` is preceded by an
identifier char, `>`, `]`, or `)` — i.e. calls/declarations, not
control-flow headers. Skips strings and comments. A pure named-parameter
block `({a, b, c, d})` is expanded inside the braces.

Run: python tools/format/expand_multiline_args.py --glob 'lib/**/*.dart'
"""

import sys
import os
import glob as globlib
import argparse


def skip_string(s, i, n):
    quote = s[i]
    if s[i:i + 3] == quote * 3:
        j = s.find(quote * 3, i + 3)
        return n if j == -1 else j + 3
    j = i + 1
    while j < n:
        c = s[j]
        if c == '\\':
            j += 2
            continue
        if c == quote:
            return j + 1
        if c == '\n':
            return j
        j += 1
    return n


def skip_block_comment(s, i, n):
    j = s.find('*/', i + 2)
    return n if j == -1 else j + 2


def skip_line_comment(s, i, n):
    j = s.find('\n', i)
    return n if j == -1 else j


def is_ident_char(c):
    return c.isalnum() or c == '_'


def find_call_close(s, open_idx, n):
    depth = 1
    i = open_idx + 1
    while i < n:
        c = s[i]
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            i = skip_line_comment(s, i, n)
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            i = skip_block_comment(s, i, n)
            continue
        if c in '"\'':
            i = skip_string(s, i, n)
            continue
        if c in '([{':
            depth += 1
            i += 1
            continue
        if c in ')]}':
            depth -= 1
            if depth == 0:
                return i
            i += 1
            continue
        i += 1
    return -1


def split_args(seg):
    """Split segment by top-level commas. Returns (args, is_named_block).
    A pure named block {a, b} is unwrapped to its inner args with flag."""
    seg = seg.strip()
    named = False
    if seg.startswith('{') and seg.endswith('}'):
        seg = seg[1:-1].strip()
        named = True
    args = []
    depth = 0
    cur = []
    i = 0
    n = len(seg)
    while i < n:
        c = seg[i]
        if c == '/' and i + 1 < n and seg[i + 1] == '/':
            j = seg.find('\n', i)
            j = n if j == -1 else j + 1
            cur.append(seg[i:j])
            i = j
            continue
        if c == '/' and i + 1 < n and seg[i + 1] == '*':
            j = seg.find('*/', i + 2)
            j = n if j == -1 else j + 2
            cur.append(seg[i:j])
            i = j
            continue
        if c in '"\'':
            j = skip_string(seg, i, n)
            cur.append(seg[i:j])
            i = j
            continue
        if c in '([{':
            depth += 1
            cur.append(c)
            i += 1
            continue
        if c in ')]}':
            depth -= 1
            cur.append(c)
            i += 1
            continue
        if c == ',' and depth == 0:
            args.append(''.join(cur).strip())
            cur = []
            i += 1
            continue
        cur.append(c)
        i += 1
    last = ''.join(cur).strip()
    if last or args:
        args.append(last)
    return args, named


def expand(content, open_idx, close_idx, base_indent):
    seg = content[open_idx + 1:close_idx]
    args, named = split_args(seg)
    if not args:
        return content[open_idx:close_idx + 1]
    arg_pad = ' ' * (base_indent + 2)
    close_pad = ' ' * base_indent
    if named:
        parts = ['({\n']
        for a in args:
            parts.append(arg_pad + a + ',\n')
        parts.append(close_pad + '})')
    else:
        parts = ['(\n']
        for a in args:
            parts.append(arg_pad + a + ',\n')
        parts.append(close_pad + ')')
    return ''.join(parts)


def process(content):
    n = len(content)
    edits = []
    i = 0
    while i < n:
        c = content[i]
        if c == '/' and i + 1 < n and content[i + 1] == '/':
            i = skip_line_comment(content, i, n)
            continue
        if c == '/' and i + 1 < n and content[i + 1] == '*':
            i = skip_block_comment(content, i, n)
            continue
        if c == 'r' and i + 1 < n and content[i + 1] in '"\'':
            i = skip_string(content, i + 1, n)
            continue
        if c in '"\'':
            i = skip_string(content, i, n)
            continue
        if c == '(':
            k = i - 1
            while k >= 0 and content[k] in ' \t':
                k -= 1
            prev = content[k] if k >= 0 else ''
            is_call = bool(prev) and (is_ident_char(prev) or prev in '>]})')
            if is_call:
                close = find_call_close(content, i, n)
                if close != -1:
                    open_nl = content.rfind('\n', 0, i)
                    close_nl = content.rfind('\n', 0, close)
                    if open_nl == close_nl:
                        seg = content[i + 1:close]
                        if '<' in seg:
                            i += 1
                            continue
                        args_tmp, _ = split_args(seg)
                        argc = len(args_tmp)
                        line_start = open_nl + 1 if open_nl != -1 else 0
                        line_end = content.find('\n', close)
                        if line_end == -1:
                            line_end = n
                        line_width = len(content[line_start:line_end])
                        need = (argc >= 4) or (argc == 3 and line_width > 160)
                        if need:
                            line_head = content[line_start:i]
                            base_indent = len(line_head) - len(line_head.lstrip())
                            edits.append((i, close, base_indent))
            i += 1
            continue
        i += 1
    if not edits:
        return content, 0
    edits.sort()
    filtered = []
    last_end = -1
    for open_idx, close_idx, base_indent in edits:
        if open_idx > last_end:
            filtered.append((open_idx, close_idx, base_indent))
            last_end = close_idx
    out = []
    last = 0
    for open_idx, close_idx, base_indent in filtered:
        out.append(content[last:open_idx])
        out.append(expand(content, open_idx, close_idx, base_indent))
        last = close_idx + 1
    out.append(content[last:])
    return ''.join(out), len(filtered)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--glob', action='append', required=True)
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()
    total = 0
    files = 0
    for pattern in args.glob:
        for path in globlib.glob(pattern, recursive=True):
            if not os.path.isfile(path):
                continue
            with open(path, 'r', encoding='utf-8') as f:
                original = f.read()
            new, edits = process(original)
            if edits > 0 and new != original:
                total += edits
                files += 1
                if not args.dry_run:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new)
                print(f'{path}: {edits}')
    print(f'---\n{files} files, {total} expansions'
          f'{" (dry-run)" if args.dry_run else ""}')


if __name__ == '__main__':
    main()

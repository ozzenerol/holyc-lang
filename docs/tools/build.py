#!/usr/bin/env python3
"""Build docs/*.html from the page sources in docs/pages/.

Each page source starts with `<!-- title: Page title -->` followed by the
page body; this wraps it in the shared layout (tools/page.py) and also
regenerates the library reference (tools/gen-stdlib.py).

Usage: python3 docs/tools/build.py
"""
import html
import os
import re
import runpy
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from page import page  # noqa: E402


# Code blocks are written raw in the page sources (so examples read and
# copy exactly as typed); escape them for HTML here.
CODE = re.compile(r'(<pre[^>]*>(?:<code[^>]*>)?)(.*?)((?:</code>)?</pre>)', re.S)


def escape_code(body):
    def one(m):
        inner = m.group(2)
        if inner.startswith("\n"):  # allow the code to start on its own line
            inner = inner[1:]
        return m.group(1) + html.escape(inner, quote=False) + m.group(3)
    return CODE.sub(one, body)


# `<!-- include: examples/x/main.HC -->` pulls a file's text in raw, so
# the example pages always show the code and output that run.sh checks.
INCLUDE = re.compile(r"<!--\s*include:\s*(\S+)\s*-->")


def include_files(body):
    return INCLUDE.sub(lambda m: open(os.path.join(DOCS, m.group(1))).read(), body)


def main():
    pages = os.path.join(DOCS, "pages")
    for name in sorted(os.listdir(pages)):
        if not name.endswith(".html"):
            continue
        src = open(os.path.join(pages, name)).read()
        m = re.match(r"\s*<!--\s*title:\s*(.*?)\s*-->\s*", src)
        if not m:
            sys.exit(f"{name}: missing <!-- title: ... --> header")
        body = include_files(src[m.end():])
        out = os.path.join(DOCS, name)
        open(out, "w").write(page(m.group(1), name, escape_code(body)))
        print(f"wrote docs/{name}")
    runpy.run_path(os.path.join(TOOLS, "gen-stdlib.py"), run_name="__main__")


if __name__ == "__main__":
    main()

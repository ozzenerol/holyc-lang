"""Shared page layout for the generated docs."""
import html

NAV = [
    ("index.html", "Home"),
    ("getting-started.html", "Getting started"),
    ("language.html", "Language"),
    ("library.html", "Library guide"),
    ("stdlib.html", "Library reference"),
    ("tools.html", "Tools"),
    ("examples.html", "Examples"),
    ("known-issues.html", "Known issues"),
]


def page(title, filename, content):
    current = ' aria-current="page"'
    links = "".join(
        f'<a href="{href}"{current if href == filename else ""}>{html.escape(label)}</a>'
        for href, label in NAV)
    full_title = "HolyC" if filename == "index.html" else f"{title} · HolyC"
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(full_title)}</title>
<link rel="icon" type="image/png" href="assets/favicon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600;700&family=VT323&display=swap">
<link rel="stylesheet" href="assets/style.css">
<script src="assets/docs.js" defer></script>
</head>
<body>
<header class="topbar">
  <a class="brand" href="index.html"><img src="assets/favicon.png" alt="" width="25" height="28">HolyC</a>
  <button class="menu" aria-label="Menu" aria-expanded="false">☰</button>
  <nav class="pages">{links}</nav>
  <button class="theme" aria-label="Toggle dark mode">◐</button>
</header>
<div class="layout">
  <aside class="toc" aria-label="On this page"></aside>
  <main>
{content}
  </main>
</div>
<footer>Docs for <a href="https://github.com/Jamesbarford/holyc-lang">hcc</a>, a HolyC compiler.
Every example on these pages is compiled and run by <code>docs/tools/check-examples.py</code>.</footer>
</body>
</html>
'''

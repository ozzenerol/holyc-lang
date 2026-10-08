(function () {
  var root = document.documentElement;

  // The theme is set in <head> (see tools/page.py). Choosing one saves it
  // and adds ?theme= to the links between pages, so it sticks even where
  // file:// pages can't share storage (Firefox).
  function carryTheme() {
    var t = root.getAttribute("data-theme");
    document.querySelectorAll('a[href$=".html"], a[href*=".html#"], a[href*=".html?"]').forEach(function (a) {
      var href = a.getAttribute("href");
      if (/^[a-z]+:/i.test(href)) return;            // external link
      var hash = "", i = href.indexOf("#");
      if (i >= 0) { hash = href.slice(i); href = href.slice(0, i); }
      href = href.replace(/\?.*$/, "");
      a.setAttribute("href", href + (t ? "?theme=" + t : "") + hash);
    });
  }

  function toggleTheme() {
    var dark = root.getAttribute("data-theme") === "dark" ||
      (!root.getAttribute("data-theme") && matchMedia("(prefers-color-scheme: dark)").matches);
    var next = dark ? "light" : "dark";
    root.setAttribute("data-theme", next);
    try { localStorage.setItem("holyc-theme", next); } catch (e) {}
    carryTheme();
  }

  var KEYWORDS = /^(if|else|for|while|do|switch|case|default|break|continue|return|goto|try|catch|throw|class|union|public|private|extern|_extern|asm|static|inline|auto|sizeof|alignof|typeof|reg|noreg|volatile|atomic)$/;
  var TYPES = /^(U0|I8|U8|I16|U16|I32|U32|I64|U64|F32|F64|Bool)$/;

  function esc(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  // A small HolyC tokenizer: comments, strings, chars, preprocessor
  // lines, numbers, keywords and types.
  function highlight(src) {
    var out = "", i = 0, n = src.length;
    function span(cls, text) { out += '<span class="tok-' + cls + '">' + esc(text) + "</span>"; }
    while (i < n) {
      var c = src[i], rest = src.slice(i), m;
      if (rest.startsWith("//")) {
        var e = src.indexOf("\n", i); if (e < 0) e = n;
        span("com", src.slice(i, e)); i = e;
      } else if (rest.startsWith("/*")) {
        var e2 = src.indexOf("*/", i + 2); e2 = e2 < 0 ? n : e2 + 2;
        span("com", src.slice(i, e2)); i = e2;
      } else if (c === '"' || c === "'") {
        var j = i + 1;
        while (j < n && src[j] !== c) j += src[j] === "\\" ? 2 : 1;
        span("str", src.slice(i, j + 1)); i = j + 1;
      } else if (c === "#" && (i === 0 || src[i - 1] === "\n" || /^\s*$/.test(src.slice(src.lastIndexOf("\n", i - 1) + 1, i)))) {
        m = /^#\s*[a-z]+/.exec(rest);
        span("pp", m[0]); i += m[0].length;
      } else if ((m = /^(0x[0-9a-fA-F]+|\d+\.\d*(e[+-]?\d+)?|\d+)/.exec(rest)) && !/[A-Za-z_0-9]/.test(src[i - 1] || "")) {
        span("num", m[0]); i += m[0].length;
      } else if ((m = /^[A-Za-z_]\w*/.exec(rest))) {
        var w = m[0];
        if (KEYWORDS.test(w)) span("kw", w);
        else if (TYPES.test(w)) span("type", w);
        else out += esc(w);
        i += w.length;
      } else {
        out += esc(c); i++;
      }
    }
    return out;
  }

  function slug(text) {
    return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  }

  document.addEventListener("DOMContentLoaded", function () {
    var themeBtn = document.querySelector(".theme");
    if (themeBtn) themeBtn.addEventListener("click", toggleTheme);
    carryTheme();

    var menu = document.querySelector(".menu"), pages = document.querySelector(".pages");
    if (menu) menu.addEventListener("click", function () {
      var open = pages.classList.toggle("open");
      menu.setAttribute("aria-expanded", open ? "true" : "false");
    });

    // Highlight HolyC code; add copy buttons to every code block.
    document.querySelectorAll("pre").forEach(function (pre) {
      var code = pre.querySelector("code");
      if (code && (code.classList.contains("language-holyc") || pre.hasAttribute("data-run"))) {
        code.innerHTML = highlight(code.textContent);
      }
      if (pre.classList.contains("output")) return;
      var btn = document.createElement("button");
      btn.className = "copy";
      btn.type = "button";
      btn.textContent = "Copy";
      btn.addEventListener("click", function () {
        var text = (code || pre).textContent;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = "Copied";
          setTimeout(function () { btn.textContent = "Copy"; }, 1200);
        });
      });
      pre.appendChild(btn);
    });

    // "On this page" from the h2/h3 headings.
    var toc = document.querySelector(".toc");
    var heads = document.querySelectorAll("main h2, main h3");
    if (!toc || heads.length < 3 || document.querySelector("main .modules")) return;
    var html = '<div class="toc-title">On this page</div><ol>', open = false;
    heads.forEach(function (h) {
      if (!h.id) h.id = slug(h.textContent);
      var a = document.createElement("a");
      a.className = "anchor"; a.href = "#" + h.id; a.textContent = "#";
      a.setAttribute("aria-label", "Link to this section");
      h.appendChild(a);
      var label = esc(h.textContent.replace(/#$/, ""));
      if (h.tagName === "H2") {
        if (open) html += "</ol></li>";
        html += '<li><a href="#' + h.id + '">' + label + "</a><ol>";
        open = true;
      } else {
        html += '<li><a href="#' + h.id + '">' + label + "</a></li>";
      }
    });
    if (open) html += "</ol></li>";
    toc.innerHTML = html + "</ol>";

    var links = toc.querySelectorAll("a");
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        links.forEach(function (l) { l.classList.toggle("active", l.getAttribute("href") === "#" + e.target.id); });
      });
    }, { rootMargin: "-70px 0px -70% 0px" });
    heads.forEach(function (h) { observer.observe(h); });
  });
})();

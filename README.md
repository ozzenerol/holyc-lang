# hcc — a HolyC compiler (ozzenerol fork)

<p align="center">
  <img src="/assets/holyc-logo.png?raw=true" alt="HolyC logo" width="300"/>
</p>

A compiler for [Terry A. Davis](https://en.wikipedia.org/wiki/Terry_A._Davis)'s
HolyC, written in C. It compiles ahead of time to native x86_64 and AArch64
binaries, runs programs directly with a built-in JIT, and comes with a REPL, a
language server and a standard library (strings, containers, JSON, files,
networking, threads, dates, optional SQLite).

```hc
U0 Main()
{
  "Hello world\n";
}
```

**Documentation: [ozzenerol.github.io/holyc-lang](https://ozzenerol.github.io/holyc-lang/)**

> [!NOTE]
> This is an independent fork of
> [Jamesbarford/holyc-lang](https://github.com/Jamesbarford/holyc-lang). It has
> diverged a long way — well over a hundred bug fixes, a new build and test
> setup, and its own documentation — and is **not** kept in sync with
> upstream. Report bugs for this fork
> [here](https://github.com/ozzenerol/holyc-lang/issues), not upstream.

## What's different in this fork

- **Correctness.** 100+ compiler, JIT and standard-library bugs fixed, each with
  a regression test that fails without the fix and passes with it — wrong-code
  bugs (pointer loads, global initialiser layout, int/float conversions, dropped
  `return` expressions, `&&`/`||` on floats, arm64 register clobbering, ...),
  compiler crashes and hangs on bad or truncated input, and stdlib bugs (JSON,
  `IntSet`, `CatPrint`, `FileRead`, `printf` edge cases, ...).
- **Diagnostics** that point at the right place: errors on macro uses, on
  directives, after tabs and non-ASCII text; errors inside `#define`/`#if`,
  class bodies and initialisers recover instead of cascading.
- **Language fixes** that bring it closer to C where HolyC doesn't say
  otherwise: nested `#if`, `#undef` order, `#define` line continuation and
  typing, unary operator precedence, function-pointer arrays, nested and
  zero-filled initialisers, anonymous unions, string-literal escapes.
- **One-command build** (`./build.sh`) into a local prefix — nothing in
  `/usr/local` is needed or touched unless you ask for it.
- **Tests everywhere**: ~180 numbered tests run both compiled and in the JIT,
  LSP tests, checked documentation examples, and a cross-architecture matrix in
  Docker.
- **Documentation** at **[ozzenerol.github.io/holyc-lang](https://ozzenerol.github.io/holyc-lang/)** (built from `docs/`): getting started, the language,
  the library, tools, examples and a [known-issues](https://ozzenerol.github.io/holyc-lang/known-issues.html) page
  where every open bug has a reproduction and a workaround. Every example in the
  docs is compiled and run by the test suite.

## Building

Requirements: a C compiler (gcc or clang), `make`, `cmake`, and Python 3 for
the docs checks. Linux (x86_64, arm64) and macOS (arm64) are tested; on Windows
use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install).

```sh
./build.sh                 # hcc + libtos into ./build/prefix, ./hcc in the repo root
./build.sh --test          # ... and run the unit, JIT and LSP test suites
./build.sh --install       # ... and install into /usr/local (sudo only for the copy)
```

Other flags: `--debug` (AddressSanitizer build), `--sqlite` (link libtos with
SQLite), `--clean`. Environment overrides: `CC`, `JOBS`, `INSTALL_PREFIX`.
Run it as your normal user, not with sudo.

Prebuilt binaries for Linux x86_64/aarch64 and macOS are attached to
[releases](https://github.com/ozzenerol/holyc-lang/releases); install one with
`packaging/install.sh`. What changed in each version is on the
[Releases page](https://ozzenerol.github.io/holyc-lang/releases.html).

## Using the compiler

```sh
hcc main.HC -o main && ./main      # compile ahead of time
hcc -jit main.HC                   # compile in memory and run
hcc -repl                          # interactive session
hcc -lsp                           # language server (see below)
hcc --help                         # everything else
```

When working from a source build without installing, point hcc at the local
prefix: `./hcc --install-dir=build/prefix main.HC`.

### REPL
`hcc -repl` keeps functions, classes, globals and `#define`s as you type,
executes statements immediately and echoes the value of a trailing expression.
It has line editing, persistent history (`~/.hcc_repl_history`) and tab
completion. `Uf("Name");` disassembles a JIT-compiled function and
`ReplDel("name");` removes a definition so it can be redefined.
`~/.hcc_rc.HC` is included at start-up (`#define HCC_NO_REPL_HELLO` there
silences the greeting). `@ <command>` runs a shell command.

### Shared libraries: `#link`
```hc
#link "./mylib.so"   /* a path, relative to the working directory */
#link <sdl2>         /* a library name, like -lsdl2 */

extern "c" I64 MyLibAdd(I64 a, I64 b);
```
AOT builds pass these to the linker; the JIT and the REPL `dlopen` them.

### JIT or AOT: `#ifjit` / `#ifaot`
Shorthand for `#ifdef __HCC_JIT__` / `#ifdef __HCC_AOT__` — exactly one is
always defined.

### Language server
`hcc -lsp` gives diagnostics, go-to-definition, hover, completion and rename.
Neovim setup:

```lua
vim.filetype.add({ extension = { HH = "holyc", HC = "holyc", hc = "holyc" } })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "holyc",
  callback = function(ev)
    vim.lsp.start({
      name = "hcc",
      cmd = { "hcc", "-lsp" },
      root_dir = vim.fs.root(ev.buf, { ".git" })
                 or vim.fs.dirname(vim.api.nvim_buf_get_name(ev.buf)),
    })
  end,
})
```

### Other tools
`-cfg` / `-cfg-png` / `-cfg-svg` draw a function's control-flow graph
(needs [graphviz](https://graphviz.org/)); `-transpile` turns HolyC into C
(experimental). See [Tools](https://ozzenerol.github.io/holyc-lang/tools.html).

## Testing

```sh
./build.sh --test                      # x86_64/arm64 native: unit (AOT + JIT), LSP
python3 docs/tools/check-examples.py   # every runnable example in the docs
docs/examples/run.sh                   # the example projects, compiled and JIT
docker/test.sh                         # x86_64 + arm64 Linux in containers
docker/test.sh --full                  # every build configuration (gcc, clang, ASan, sqlite, install)
```

Tests are `src/tests/NN_name.HC`; the runners pick up every numbered file and run
it both ahead of time and in the JIT. A bug fix comes with a test that fails
before the fix and passes after it.

## Differences from TempleOS HolyC
- `F32`, for C libraries that use `float`.
- `auto` type inference and `typeof(expr)` (a compile-time string).
- Range-based `for` over arrays and over any class with `entries` and `size`.
- `extern "c"` to call any C function, and `#link` for shared libraries.
- See the [language page](https://ozzenerol.github.io/holyc-lang/language.html) for the full list.

## Known issues
Open bugs, each with a reproduction and a workaround, are on the
[known-issues page](https://ozzenerol.github.io/holyc-lang/known-issues.html).

## Credits
hcc was created by [James Barford-Evans](https://github.com/Jamesbarford); this
fork builds on his work and keeps its license (see [COPYING](COPYING)). His
inspirations and resources: [TempleOS](https://templeos.org/),
[8cc](https://github.com/rui314/8cc), [tcc](http://bellard.org/tcc/),
[cc65](https://cc65.github.io/), [shecc](https://github.com/sysprog21/shecc),
[CaptCC](https://github.com/Captainarash/CaptCC),
[linenoise](https://github.com/antirez/linenoise).

#include "testhelper.HC"

/* The legacy x86 backend (--use-legacy-x86) wrote a global class
 * initialiser as its values back to back, ignoring field offsets,
 * padding and alignment, so `class P { I32 a; I64 b; }; P g = {1, 2};`
 * gave a wrong g.b. It now uses the default backend's layout code.
 * (The legacy backend can't name a global class's fields directly, so the
 * program reads them through pointers; x86_64 only.) */

#define LEGACY_SRC "__184_legacy_init.HC"
#define LEGACY_BIN "./__184_legacy_init"
#define LEGACY_OUT "__184_legacy_init.out"

U0 Cleanup()
{
  Rm(LEGACY_SRC);
  Rm(LEGACY_BIN);
  Rm(LEGACY_OUT);
}

U8 *g_program = "
class P { I32 a; I64 b; };
class Q { U8 c; U8 *s; F64 f; I64 n; };
class R { I64 x; P inner; I64 y; };
P g = {1, 2};
Q q = {7, \"hi\", 2.5, -5};
R r = {10, {3, 4}, 11};
P parr[2] = {{5, 6}, {7, 8}};
U8 *strs[2] = {\"ab\", \"cd\"};

U0 Main()
{
  P *p = &g;
  Q *qp = &q;
  R *rp = &r;
  P *pa = parr;
  U8 **sp = strs;
  \"%d %d\\n\", p->a, p->b;
  \"%d %s %.1f %d\\n\", qp->c, qp->s, qp->f, qp->n;
  \"%d %d %d %d\\n\", rp->x, rp->inner.a, rp->inner.b, rp->y;
  \"%d %d %d %d\\n\", pa->a, pa->b, (pa + 1)->a, (pa + 1)->b;
  \"%s %s\\n\", sp[0], sp[1];
  \"%d %d %d\\n\", sizeof(g), sizeof(q), sizeof(r);
}
";

U8 *g_want = "1 2\n7 hi 2.5 -5\n10 3 4 11\n5 6 7 8\nab cd\n16 32 32\n";

I32 Main()
{
  I64 correct = 0, tests = 1;
  "Test - legacy x86 global class initialisers: ";
#ifdef IS_X86_64
  U8 *out = NULL;
  Cleanup;
  if (FileWrite(LEGACY_SRC, g_program, StrLen(g_program), O_CREAT | O_RDWR | O_TRUNC) &&
      System("../../hcc ${HCC_INSTALL_DIR:+--install-dir=$HCC_INSTALL_DIR} --use-legacy-x86 "
             LEGACY_SRC " -o " LEGACY_BIN) == 0) {
    /* the exit status of a legacy-compiled U0 Main is not meaningful */
    System(LEGACY_BIN " > " LEGACY_OUT " 2>&1");
    out = FileRead(LEGACY_OUT);
  }
  if (out) {
    if (!StrCmp(out, g_want)) correct++;
    else "\n%s", out;
    Free(out);
  }
  Cleanup;
#else
  correct++; /* the legacy backend is x86_64 only */
#endif
  PrintResult(correct, tests);
  "====\n";
  return 0;
}

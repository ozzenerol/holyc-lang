#include "testhelper.HC"

/* StrNCpy(buf, len) copied exactly len bytes, past the end of a shorter
 * string, returned an uninitialised byte for len 0 (it returned before
 * writing the NUL) and crashed on a negative len. It is now strndup: at
 * most len bytes, stopping at the NUL, always terminated, len < 0 is 0.
 * fzf's internal str_replace called it as if it were C's strncpy (leaking
 * the copy and leaving the result unwritten); that use is fixed too. */

U8 *str_replace(U8 *orig, U8 *rep, U8 *with);

I32 Main()
{
  I64 correct = 0, tests = 0;
  "Test - StrNCpy strndup semantics: ";

  U8 *a = StrNCpy("hello", 3);
  U8 *b = StrNCpy("hi", 10);
  U8 *c = StrNCpy("hello", 0);
  U8 *d = StrNCpy("hello", -1);
  U8 *e = StrNCpy("hello", 5);
  U8 *f = StrNCpy(NULL, 4);
  tests++;
  if (!StrCmp(a, "hel") && !StrCmp(b, "hi") && c[0] == '\0' && d[0] == '\0' &&
      !StrCmp(e, "hello") && f[0] == '\0') correct++;
  /* only what is needed is allocated, so a short source can't be read past */
  tests++; if (MSize(b) == 3 && MSize(a) == 4) correct++;
  Free(a); Free(b); Free(c); Free(d); Free(e); Free(f);

  U8 *r = str_replace("a b\\ c\\ d", "\\ ", "\t");
  tests++; if (r && !StrCmp(r, "a b\tc\td")) correct++;
  else "str_replace -> \"%s\"\n", r;
  Free(r);

  PrintResult(correct, tests);
  "====\n";
  return 0;
}

#include "testhelper.HC"

/* CatLenPrint never freed the string it formats into, so every call
 * leaked a block (JsonToString, built on it, leaked one per piece), and
 * CatLenPrint(NULL, ...) allocated no room for the '\0' it then wrote. */

extern "c" U0 *mallinfo2(U0 *out);
class MI
{
  U64 arena, ordblks, smblks, hblks, hblkhd, usmblks, fsmblks, uordblks,
      fordblks, keepcost;
};

/* Bytes in use on the heap */
I64 InUse()
{
  MI m;
  mallinfo2(&m);
  return m.uordblks;
}

I32 Main()
{
  "Test - CatLenPrint leak and overflow: ";
  I64 correct = 0, tests = 0, len, i, before;
  U8 *s;

  /* No leak: 20000 appends only grow the one string */
  tests++;
  len = 0;
  s = MAlloc(16);
  s[0] = '\0';
  s = CatLenPrint(s, &len, "x");
  before = InUse() - MSize(s);
  for (i = 0; i < 20000; i++) {
    s = CatLenPrint(s, &len, "%d,", i % 10);
  }
  if (InUse() - MSize(s) - before < 4096 && len == 40001) correct++;
  else "heap grew %d\n", InUse() - MSize(s) - before;
  Free(s);

  /* The text is right */
  tests++;
  len = 0;
  s = CatLenPrint(NULL, &len, "hello");
  if (len == 5 && !StrCmp(s, "hello") && MSize(s) >= len + 1) correct++;
  else "len %d MSize %d\n", len, MSize(s);
  s = CatLenPrint(s, &len, " %s %d", "world", 42);
  tests++;
  if (len == 14 && !StrCmp(s, "hello world 42") && MSize(s) >= len + 1) correct++;
  Free(s);

  /* From NULL, every length lands with room for the '\0' */
  tests++;
  Bool ok = TRUE;
  for (i = 0; i < 300; i++) {
    len = 0;
    s = CatLenPrint(NULL, &len, "%*s", i, "");
    if (len != i || MSize(s) < i + 1 || s[i] != '\0') ok = FALSE;
    Free(s);
  }
  if (ok) correct++;

  /* JsonToString no longer leaks */
  tests++;
  Json *j = JsonParse("{\"a\":[1,2,3,true,null],\"b\":\"x\",\"c\":{\"d\":1.5}}");
  s = JsonToString(j);
  Free(s);
  before = InUse();
  for (i = 0; i < 2000; i++) {
    s = JsonToString(j);
    Free(s);
  }
  if (InUse() - before < 4096) correct++;
  else "JsonToString heap grew %d\n", InUse() - before;
  JsonRelease(j);

  PrintResult(correct, tests);
  "====\n";
  return 0;
}

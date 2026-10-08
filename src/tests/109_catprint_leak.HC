#include "testhelper.HC"

/* CatPrint returned a brand new string and never freed the one passed
 * in, so the idiomatic `s = CatPrint(s, ...)` loop leaked every old s.
 * It now appends into the heap string it is given, growing it with
 * ReAlloc (which frees the old block) when it is full. The leak is
 * measured with libc's own count of bytes in use. */

#ifdef IS_MACOS
class MallocStats
{
  U32 blocks_in_use;
  U32 pad;
  U64 size_in_use;
  U64 max_size_in_use;
  U64 size_allocated;
};
extern "c" U0 malloc_zone_statistics(U0 *zone, MallocStats *stats);
I64 HeapInUse()
{
  MallocStats st;
  malloc_zone_statistics(NULL, &st);
  return st.size_in_use;
}
#else
class MallInfo2
{
  U64 arena, ordblks, smblks, hblks, hblkhd;
  U64 usmblks, fsmblks, uordblks, fordblks, keepcost;
};
extern "c" MallInfo2 mallinfo2();
I64 HeapInUse()
{
  MallInfo2 m = mallinfo2();
  return m.uordblks + m.hblkhd;
}
#endif

U8 *ValueStr(U0 *v)
{
  return StrPrint(NULL, "v%d", v(I64));
}

I32 Main()
{
  "Test - CatPrint frees what it replaces: ";
  I64 tests = 9;
  I64 correct = 0;
  I64 i, before, delta;
  U8 *s, *t, want[1024];

  /* 1: the leaking loop; ~11MB used to stay allocated */
  before = HeapInUse();
  s = StrNew("");
  for (i = 0; i < 2000; i++) s = CatPrint(s, "%d", i);
  Free(s);
  delta = HeapInUse() - before;
  if (delta < 65536) correct++;
  else "\n  CatPrint loop leaked %d bytes\n", delta;

  /* 2: the result is still every piece in order */
  s = StrNew("id");
  I64 pos = 2;
  StrCpy(want, "id");
  for (i = 0; i < 100; i++) {
    s = CatPrint(s, ",%d", i);
    pos += snprintf(want + pos, 1024 - pos, ",%d", i);
  }
  if (!StrCmp(s, want) && StrLen(s) == pos) correct++;
  Free(s);

  /* 3: a NULL dst starts a new string, as it did before */
  s = CatPrint(NULL, "x%d", 5);
  if (!StrCmp(s, "x5")) correct++;
  Free(s);

  /* 4: with room left, the text goes into the same block */
  s = MAlloc(64);
  s[0] = '\0';
  t = CatPrint(s, "ab%d", 1);
  if (t == s && !StrCmp(t, "ab1")) correct++;
  Free(t);

  /* 5: a full MAlloc'd block grows */
  s = MAlloc(4);
  StrCpy(s, "abc");
  s = CatPrint(s, "%s", "defghij");
  if (!StrCmp(s, "abcdefghij") && MSize(s) > 10) correct++;
  Free(s);

  /* 6: appending nothing leaves it alone */
  s = StrNew("same");
  s = CatPrint(s, "%s", "");
  if (!StrCmp(s, "same")) correct++;
  Free(s);

  /* 7: one append longer than STR_LEN, with padding */
  s = StrNew("[");
  s = CatPrint(s, "%300s]", "r");
  if (StrLen(s) == 302 && s[0] == '[' && s[299] == ' ' &&
      s[300] == 'r' && s[301] == ']') correct++;
  Free(s);

  /* 8, 9: the map printers use CatPrint; no double free, no leak */
  IntMap *im = IntMapNew;
  for (i = 0; i < 50; i++) IntMapSet(im, i, i(U0 *));
  s = IntMapKeysToString(im);
  t = IntMapToString(im, &ValueStr);
  if (s[0] == '{' && s[StrLen(s) - 1] == '}' && StrOcc(s, ',') == 49 &&
      t[0] == '{' && t[StrLen(t) - 1] == '}' && StrOcc(t, ',') == 49) {
    correct++;
  }
  Free(s);
  Free(t);
  before = HeapInUse();
  for (i = 0; i < 200; i++) {
    s = IntMapToString(im, &ValueStr);
    Free(s);
  }
  delta = HeapInUse() - before;
  if (delta < 65536) correct++;
  else "\n  IntMapToString leaked %d bytes\n", delta;
  IntMapRelease(im);

  PrintResult(correct, tests);
  "====\n";
  return 0;
}

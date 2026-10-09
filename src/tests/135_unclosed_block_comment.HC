#include "testhelper.HC"

/* A block comment left open at the end of a file was silently taken
 * as running to the end of the file, so `U0 Main() { ... }` followed
 * by `/` `*` never closed compiled and ran. It must be reported at the
 * opener as "unterminated comment" and hcc must exit 1. */

#define COMMENT_FILE "__135_unclosed_comment.HC"
#define COMMENT_INC  "__135_unclosed_comment.HH"
#define COMMENT_OUT  "__135_unclosed_comment.out"

U0 CleanupCommentTest(U0)
{
  Rm(COMMENT_FILE);
  Rm(COMMENT_INC);
  Rm(COMMENT_OUT);
  Rm("./a.out");
}

I64 CountErrors(U8 *out)
{
  I64 n = 0;
  U8 *p = out;
  while ((p = strstr(p, "error: "))) {
    n++;
    p++;
  }
  return n;
}

/* Compile `source` (and `inc` as COMMENT_INC when not NULL). With
 * `count` 0 it must compile cleanly; otherwise hcc must exit 1 with
 * exactly `count` errors, among them "unterminated comment" at `loc`
 * (" --> file:line:col"). */
Bool Compile(U8 *source, U8 *inc, I64 count, U8 *loc)
{
  U8 *out, *want;
  I64 res;
  Bool ok = TRUE;

  CleanupCommentTest;

  if (!FileWrite(COMMENT_FILE, source, StrLen(source), O_CREAT | O_RDWR | O_TRUNC)) {
    return FALSE;
  }
  if (inc && !FileWrite(COMMENT_INC, inc, StrLen(inc), O_CREAT | O_RDWR | O_TRUNC)) {
    CleanupCommentTest;
    return FALSE;
  }

  res = System("../../hcc ${HCC_INSTALL_DIR:+--install-dir=$HCC_INSTALL_DIR} " COMMENT_FILE " > " COMMENT_OUT " 2>&1");

  out = FileRead(COMMENT_OUT);
  if (!out) {
    CleanupCommentTest;
    return FALSE;
  }

  if (count == 0) {
    if (res != 0) ok = FALSE;
  } else {
    /* system() returns a wait status: the exit code is in bits 8-15 */
    if (((res >> 8) & 0xFF) != 1) ok = FALSE;
    want = MStrPrint("error: unterminated comment\n --> %s\n", loc);
    if (!strstr(out, want)) ok = FALSE;
    Free(want);
  }
  if (CountErrors(out) != count) ok = FALSE;
  if (!ok) "exit status %d\n%s\n", res, out;

  Free(out);
  CleanupCommentTest;
  return ok;
}

Bool TestUnclosedAtEof(U0)
{
  return Compile(
"U0 Main() { \"hi\\n\"; }
/* never closed
", NULL, 1, COMMENT_FILE ":2:1");
}

/* Opened mid-line, no newline at all after it */
Bool TestUnclosedMidLine(U0)
{
  return Compile(
"U0 Main() { \"hi\\n\"; }
I64 x;   /* never closed", NULL, 1, COMMENT_FILE ":2:10");
}

/* `/ * / * * /` is one comment: comments don't nest */
Bool TestNestedLooking(U0)
{
  return Compile(
"U0 Main() { \"hi\\n\"; } /* /* */
", NULL, 0, NULL);
}

Bool TestOpenerInString(U0)
{
  return Compile(
"U0 Main() { \"/* not a comment\\n\"; }
", NULL, 0, NULL);
}

/* A line comment ending the file without a newline is fine */
Bool TestLineCommentAtEof(U0)
{
  return Compile(
"U0 Main() { \"hi\\n\"; }
// no newline after this", NULL, 0, NULL);
}

/* Reported in the included file, then the including file carries on */
Bool TestUnclosedInInclude(U0)
{
  return Compile(
"#include \"" COMMENT_INC "\"
U0 Main() { \"%d\\n\", x; }
",
"I64 x = 1;
  /* never closed
", 1, COMMENT_INC ":2:3");
}

/* Like C, still reported inside a skipped #if 0 block, where it also
 * swallows the #endif */
Bool TestUnclosedInIfZero(U0)
{
  return Compile(
"#if 0
/* never closed
#endif
U0 Main() { \"hi\\n\"; }
", NULL, 2, COMMENT_FILE ":2:1");
}

I32 Main()
{
  "Test - unclosed block comment: ";
  I64 correct = 0, tests = 0;

  tests++; if (TestUnclosedAtEof)     correct++;
  tests++; if (TestUnclosedMidLine)   correct++;
  tests++; if (TestNestedLooking)     correct++;
  tests++; if (TestOpenerInString)    correct++;
  tests++; if (TestLineCommentAtEof)  correct++;
  tests++; if (TestUnclosedInInclude) correct++;
  tests++; if (TestUnclosedInIfZero)  correct++;

  /* The same edge cases in this file itself */
  tests++; /* /* */ correct++;
  tests++; if (StrLen("/*") == 2) correct++;

  CleanupCommentTest;
  PrintResult(correct, tests);
  "====\n";
  return 0;
}

#include "testhelper.HC"

/* `hcc -run file.HC` used to free its command string before handing it
 * to system(), so it ran nothing and exited 0. It must compile the
 * program, run it with any trailing arguments, exit with the program's
 * exit code and leave no binary behind (nor clobber a user's ./a.out).
 * hcc is run from a scratch directory: the test runner itself is
 * ./a.out in src/tests. */

#define RUN_TEST_DIR  "hcc-73-run-dir"
#define RUN_TEST_MAIN "hcc-73-run-main.HC"
#define RUN_TEST_TOP  "hcc-73-run-top.HC"
#define RUN_TEST_OUT  "hcc-73-run.out"
/* A single literal: adjacent strings don't concatenate inside #define */
#define RUN_HCC "H=$PWD/../../hcc && cd hcc-73-run-dir && $H ${HCC_INSTALL_DIR:+--install-dir=$HCC_INSTALL_DIR} -run "

U0 CleanupRunTest(U0)
{
  System("rm -rf " RUN_TEST_DIR " " RUN_TEST_MAIN " " RUN_TEST_TOP " " RUN_TEST_OUT);
}

Bool WriteSource(U8 *path, U8 *source)
{
  return FileWrite(path, source, StrLen(source), O_CREAT | O_RDWR | O_TRUNC);
}

/* The captured output of the last run must be exactly `expected` */
Bool OutputIs(U8 *expected)
{
  U8 *out = FileRead(RUN_TEST_OUT);
  Bool ok;
  if (!out) return FALSE;
  ok = StrCmp(out, expected) == 0;
  if (!ok) "got: '%s'\n", out;
  Free(out);
  return ok;
}

I32 Main()
{
  "Test - hcc -run: ";
  I64 tests = 6;
  I64 correct = 0;

  CleanupRunTest;
  System("mkdir -p " RUN_TEST_DIR);

  WriteSource(RUN_TEST_MAIN,
"U0 Main(I32 argc, U8 **argv)
{
  I64 i;
  \"run works argc=%d\\n\", argc;
  for (i = 1; i < argc; i++) \"[%s]\\n\", argv[i];
  if (argc > 1) Exit(7);
}
");
  WriteSource(RUN_TEST_TOP,
"I64 x = 40;
\"top level %d\\n\", x + 2;
");

  /* Program output reaches stdout and the exit code is the program's */
  if (System("(" RUN_HCC "../" RUN_TEST_MAIN ") > " RUN_TEST_OUT " 2>&1") == 0) correct++;
  else "Failed - -run exit code 0\n";

  if (OutputIs("run works argc=1\n")) correct++;
  else "Failed - -run output\n";

  /* No binary is left in the working directory */
  if (System("test ! -e " RUN_TEST_DIR "/a.out") == 0) correct++;
  else "Failed - -run left ./a.out behind\n";

  /* Trailing arguments are passed through, Exit(7) becomes hcc's exit
   * code and an existing ./a.out is left alone */
  System("echo keep > " RUN_TEST_DIR "/a.out");
  if (System("(" RUN_HCC "../" RUN_TEST_MAIN " foo 'b c') > " RUN_TEST_OUT " 2>&1;"
             " test $? -eq 7 && grep -qx keep " RUN_TEST_DIR "/a.out") == 0) correct++;
  else "Failed - -run exit code 7 / ./a.out kept\n";

  if (OutputIs("run works argc=3\n[foo]\n[b c]\n")) correct++;
  else "Failed - -run arguments\n";

  /* A program with only top-level statements and no Main */
  if (System("(" RUN_HCC "../" RUN_TEST_TOP ") > " RUN_TEST_OUT " 2>&1") == 0 &&
      OutputIs("top level 42\n")) correct++;
  else "Failed - -run top-level program\n";

  CleanupRunTest;
  PrintResult(correct, tests);
  "====\n";
  return 0;
}

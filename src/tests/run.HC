#include "run_shared.HC"

U0 RunTest(U8 *filename, I64 idx)
{
  /* Use the local build (../../hcc relative to src/tests/) so we
   * always test what's actually been compiled, not whatever older
   * hcc happens to be on PATH (e.g. an installed /usr/local/bin/hcc
   * from a prior version - this trap cost us a session of confused
   * cross-test triage). It compiles from src/tests, so its messages
   * name the file as before; the binary runs in the test's own
   * directory (see RunTests). */
  U8 *bin = MStrPrint("%s/b/%d", g_root, idx);
  U8 *cmd = MStrPrint("cd '%s' && '%s' %s '%s' -o '%s'",
                      g_start_dir, g_hcc, g_hcc_flags, filename, bin);
  auto res = System(cmd);

  if (res != 0) {
    "\033[0;31mFailed to compile\033[0;0m: %s\n",filename;
  } else {
    fflush(NULL);
    if ((res = System(bin)) != 0) {
      "\033[0;31mFAILED\033[0;0m to run: %s\n",filename;
    }
    Rm(bin);
  }
  Free(cmd);
  Free(bin);
}

I32 Main(I32 argc, U8 **argv)
{
  /* Argv contract:
   *   ./run                     -> host arch, all tests
   *   ./run --target=<triple>   -> cross to <triple>, all tests
   *   ./run <file.HC>           -> host arch, single file
   *   ./run --target=<triple> <file.HC>
   *                             -> cross to <triple>, single file
   *
   * Disambiguation is by the --target= prefix so the existing
   * single-file workflow keeps working unchanged. */
  g_target = "";
  I64 arg_idx = 1;
  if (argc >= 2 && StrNCmp(argv[1], "--target=", 9) == 0) {
    g_target = argv[1] + 9;
    arg_idx = 2;
  }

  PtrVec *vec;
  if (argc > arg_idx) {
    vec = PtrVecNew;
    PtrVecPush(vec, StrNew(argv[arg_idx]));
  } else {
    vec = CollectTests;
  }

  RunTests(vec);

  PtrVecRelease(vec, &Free);
  return 0;
}

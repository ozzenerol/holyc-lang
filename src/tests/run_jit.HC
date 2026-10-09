#include "run_shared.HC"

U0 RunTest(U8 *filename, I64 idx)
{
  /* Use the local build (../../hcc relative to src/tests/) so we
   * always test what's actually been compiled, not whatever older
   * hcc happens to be on PATH (e.g. an installed /usr/local/bin/hcc
   * from a prior version - this trap cost us a session of confused
   * cross-test triage). The program runs in the test's own directory
   * (see RunTests), so the file is given by its absolute path. */
  U8 *path = filename;
  if (path[0] != '/') path = MStrPrint("%s/%s", g_start_dir, filename);
  U8 *cmd = MStrPrint("'%s' -jit %s '%s'", g_hcc, g_hcc_flags, path);
  auto res = System(cmd);

  if (res != 0) {
    "\033[0;31mFailed to compile\033[0;0m: %s\n",filename;
  }
  Free(cmd);
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

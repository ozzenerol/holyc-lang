I64 CmpFileNames(U8 *str1, U8 *str2)
{
  if ('0'<=*str1<='9' && '0'<=*str2<='9') {
    I64 n1 = 0, n2 = 0;
    while ('0'<=*str1<='9') {
      n1 = (n1 * 10) + (*str1-'0');
      str1++;
    }
    while ('0'<=*str2<='9') {
      n2 = (n2 * 10) + (*str2-'0');
      str2++;
    }
    return n2 > n1;
  }
  return 0;
}

U0 QSortStrings(U8 **arr, I64 high, I64 low=0)
{
  if (low < high) {
    auto pivot = arr[high];
    auto idx = low;

    for (auto i = low; i < high; ++i) {
      if (CmpFileNames(arr[i],pivot)) {
        auto tmp = arr[i];
        arr[i] = arr[idx];
        arr[idx] = tmp;
        idx++;
      }
    }

    arr[high] = arr[idx];
    arr[idx] = pivot;
    QSortStrings(arr,high,idx+1);
    QSortStrings(arr,idx-1,low);
  }
}


Bool ShouldExclude(U8 *filename, I64 namelen)
{
  U8 *exclude[] = {
    "run.HC",
    "run_shared.HC",
    "run_jit.HC",
    "testhelper.HC",
    "tests.sh",
    "Makefile",
    "a.out",
#ifndef __HCC_LINK_SQLITE3__
    "32_sql.HC",
#endif
    "test-runner"};

  for (U8 *name : exclude) {
    if (!StrNCmp(name,filename,namelen)) return TRUE;
  }
  return FALSE;
}

/* Cross-compilation hook.
 *
 * When the runner is invoked with `--target=<triple>` as argv[1] we
 * pass `--target=<triple> --install-dir=../../build/<triple>` to hcc
 * for each test, then invoke the resulting binary via the
 * appropriate emulator (`arch -x86_64 ./a.out` on Apple Silicon for
 * x86_64 targets). Empty target string = host arch, default flow.
 */
/* HolyC doesn't seem to honour `U8 *name = "lit";` initialisers
 * for globals - the pointer comes through NULL and any later
 * dereference segfaults. Declare uninitialised and assign in Main
 * before any reader runs. */
U8 *g_target;

/* Optional libtos prefix for host runs, e.g. build.sh sets
 * HCC_INSTALL_DIR=build/prefix so the tests link the in-tree library
 * rather than whatever is installed in /usr/local. */
extern "c" U8 *getenv(U8 *name);
extern "c" I32 setenv(U8 *name, U8 *value, I32 overwrite);
extern "c" U8 *realpath(U8 *path, U8 *resolved);
extern "c" U8 *mkdtemp(U8 *template);
extern "c" I32 symlink(U8 *target, U8 *path);
extern "c" I32 unlink(U8 *path);
extern "c" I32 dup2(I32 fd, I32 fd2);
extern "c" I32 fflush(U0 *stream);
extern "c" U0 _exit(I32 status);
extern "c" I64 sysconf(I32 name);

PtrVec *CollectTests()
{
  auto dir = opendir(".");
  if (!dir) {
    "Failed to open directory\n";
    Exit;
  }
  auto vec = PtrVecNew();
  Dirent *ent;
  while ((ent = readdir(dir)) != NULL) {
    if (ent->type & DT_REG) {
      auto len = StrLen(ent->name);
      auto res = FzF(ent->name,"HC$");

      if (ShouldExclude(ent->name,len) || res == NULL) {
        continue;
      }
      FzFPositionRelease(res);
      auto str = StrNew(ent->name);
      PtrVecPush(vec,str);
    }
  }

  QSortStrings(vec->entries(U8 **),vec->size-1);
  closedir(dir);
  return vec;
}

/* Tests run in parallel, each in a forked child with its own working
 * directory, TMPDIR and binary, so tests that write fixed file names
 * (./a.out, __NN_*.HC) can't collide. Everything lives under one
 * temporary root R:
 *   R/hcc     symlink to the hcc under test: a test's "../../hcc" works
 *             from its working directory R/w/<n>
 *   R/w/<n>   working directory of test n
 *   R/t/<n>   its TMPDIR
 *   R/b/<n>   its binary (AOT)
 *   R/o/<n>   its stdout and stderr, printed by the parent in test order,
 *             so the output is the same whatever finishes first.
 * JOBS sets how many run at once (default: the number of CPUs). */
U8 *g_start_dir;   /* where the runner was started (src/tests) */
U8 *g_hcc;         /* absolute path of ../../hcc */
U8 *g_hcc_flags;   /* --install-dir / --target flags for the runner's hcc */
U8 *g_root;

#ifdef IS_MACOS
#define SC_NPROCESSORS_ONLN 58
#else
#define SC_NPROCESSORS_ONLN 84
#endif

U8 *AbsPath(U8 *path)
{
  U8 *abs = realpath(path, NULL);
  if (abs) return abs;
  if (path[0] == '/') return StrNew(path);
  return MStrPrint("%s/%s", g_start_dir, path);
}

I64 JobCount()
{
  U8 *env = getenv("JOBS");
  I64 jobs = 0;
  if (env) jobs = Atoi(env);
  if (jobs < 1) jobs = sysconf(SC_NPROCESSORS_ONLN);
  if (jobs < 1) jobs = 1;
  return jobs;
}

U0 RunnerInit()
{
  U8 *tmpdir = getenv("TMPDIR");
  U8 *install_dir = getenv("HCC_INSTALL_DIR");

  g_start_dir = AbsPath(".");
  g_hcc = AbsPath("../../hcc");

  if (g_target[0] != '\0') {
    g_hcc_flags = MStrPrint("--target=%s --install-dir=%s", g_target,
                            AbsPath(MStrPrint("../../build/%s", g_target)));
  } else if (install_dir) {
    /* The tests run hcc themselves from their own directories */
    install_dir = AbsPath(install_dir);
    setenv("HCC_INSTALL_DIR", install_dir, 1);
    g_hcc_flags = MStrPrint("--install-dir=%s", install_dir);
  } else {
    g_hcc_flags = "";
  }

  if (!tmpdir || !tmpdir[0]) tmpdir = "/tmp";
  g_root = mkdtemp(MStrPrint("%s/hcc-tests-XXXXXX", tmpdir));
  if (!g_root) {
    "Failed to create a temporary directory in %s\n", tmpdir;
    Exit(1);
  }
  g_root = AbsPath(g_root);
  symlink(g_hcc, MStrPrint("%s/hcc", g_root));
  MkDir(MStrPrint("%s/w", g_root));
  MkDir(MStrPrint("%s/t", g_root));
  MkDir(MStrPrint("%s/b", g_root));
  MkDir(MStrPrint("%s/o", g_root));
}

U0 RunnerCleanup()
{
  unlink(MStrPrint("%s/hcc", g_root));
  RmDir(g_root, RM_RECURSE);
}

/* Defined by run.HC / run_jit.HC: compile and run `name` (relative to
 * g_start_dir) with the working directory already the test's own. */
U0 RunTest(U8 *name, I64 idx);

/* In the child: set up test idx's directories and output file, run it. */
U0 RunTestChild(U8 *name, I64 idx)
{
  U8 *work = MStrPrint("%s/w/%d", g_root, idx);
  U8 *tmp = MStrPrint("%s/t/%d", g_root, idx);
  MkDir(work);
  MkDir(tmp);
  setenv("TMPDIR", tmp, 1);

  I32 fd = creat(MStrPrint("%s/o/%d", g_root, idx), 0x1A4);
  if (fd == -1 || chdir(work) != 0) {
    "\033[0;31mFAILED\033[0;0m to run: %s (no test directory)\n", name;
    fflush(NULL);
    _exit(1);
  }
  dup2(fd, 1);
  dup2(fd, 2);
  close(fd);

  RunTest(name, idx);
  fflush(NULL);
  _exit(0);
}

U0 PrintTestOutput(I64 idx)
{
  I64 len = 0;
  U8 *path = MStrPrint("%s/o/%d", g_root, idx);
  U8 *out = FileRead(path, &len);
  fflush(NULL);
  if (out) {
    write(1, out, len);
    Free(out);
  }
  Free(path);
}

/* Run every test in `names`, JobCount() at a time, printing each test's
 * output once it and every test before it have finished. */
U0 RunTests(PtrVec *names)
{
  I64 n = names->size, jobs = JobCount(), next = 0, printed = 0;
  I64 running = 0, i;
  I32 pid, status;
  I32 *pids = CAlloc(sizeof(I32) * (n + 1));
  Bool *done = CAlloc(sizeof(Bool) * (n + 1));
  U8 **entries = names->entries(U8 **);

  RunnerInit();

  while (printed < n) {
    while (running < jobs && next < n) {
      fflush(NULL);
      pid = fork();
      if (pid == 0) {
        RunTestChild(entries[next], next);
      } else if (pid == -1) {
        /* Out of processes: wait for one of ours to finish and retry */
        if (running > 0) break;
        U8 *msg = MStrPrint("\033[0;31mFAILED\033[0;0m to run: %s (fork failed)\n",
                            entries[next]);
        FileWrite(MStrPrint("%s/o/%d", g_root, next), msg, StrLen(msg));
        done[next] = TRUE;
      } else {
        pids[next] = pid;
        running++;
      }
      next++;
    }

    if (running > 0) {
      pid = wait(&status);
      for (i = printed; i < next; i++) {
        if (pid == -1 && pids[i] && !done[i]) {
          /* No children left to wait for: should not happen */
          done[i] = TRUE;
          running--;
          continue;
        }
        if (pids[i] == pid) {
          done[i] = TRUE;
          running--;
          break;
        }
      }
    }

    while (printed < n && done[printed]) {
      PrintTestOutput(printed);
      printed++;
    }
  }

  RunnerCleanup();
  Free(pids);
  Free(done);
}

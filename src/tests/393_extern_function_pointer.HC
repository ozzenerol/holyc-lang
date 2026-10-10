#include "testhelper.HC"

/* `extern I64 (*fp)(I64);` didn't parse ("`extern <Type>` must be followed
 * by an identifier, got `(`"), so a program couldn't use a library's
 * public function-pointer global. It now declares one, like
 * `extern I64 x;` does for data. */

#define XF_SRC "__393_xf.HC"
#define XF_OUT "__393_xf.out"
#define XF_BIN "__393_xf.bin"

I64 g_correct = 0, g_tests = 0;
U0 Check(Bool ok, U8 *what)
{
  g_tests++;
  if (ok) g_correct++;
  else "\n  failed: %s\n", what;
}

/* hcc's output (stdout and stderr) for `src` with `flags`; *_res gets the
 * exit status */
U8 *Hcc(U8 *src, U8 *flags, I64 *_res)
{
  U8 *cmd;
  FileWrite(XF_SRC, src, StrLen(src), O_CREAT | O_RDWR | O_TRUNC);
  cmd = MStrPrint("$(command -v timeout >/dev/null 2>&1 && echo timeout 60) "
                  "../../hcc ${HCC_INSTALL_DIR:+--install-dir=$HCC_INSTALL_DIR} "
                  "%s " XF_SRC " > " XF_OUT " 2>&1", flags);
  *_res = System(cmd);
  Free(cmd);
  return FileRead(XF_OUT);
}

I32 Main()
{
  I64 res;
  U8 *out;
  "Test - extern function pointer: ";

  /* declared extern, then defined in the same file */
  out = Hcc(
"I64 Twice(I64 v) { return v * 2; }
extern I64 (*fp)(I64);
I64 (*fp)(I64) = &Twice;
U0 Main() { \"%d\\n\", fp(4); }
", "-jit", &res);
  Check(res == 0 && out && !StrCmp(out, "8\n"), "extern then definition (JIT)");
  Free(out);

  /* a malformed extern still says what is wrong */
  out = Hcc("extern I64 123;\n", "-jit", &res);
  Check(res != 0 && out &&
        strstr(out, "`extern <Type>` must be followed by an identifier, got `123`"),
        "malformed extern");
  Free(out);
  out = Hcc("extern I64 (*)(I64);\n", "-jit", &res);
  Check(res != 0 && out && strstr(out, "Expected function pointer name"),
        "extern function pointer without a name");
  Free(out);
  System("rm -f " XF_SRC " " XF_OUT " " XF_BIN);

  /* a -lib library's public function pointer, called from a program */
  System("rm -rf ./hcc-393-prefix ./hcc-393-work ./hcc-393-use.HC ./hcc-393-use");
  Check(System("D=${HCC_INSTALL_DIR:-/usr/local} && H=$PWD/../../hcc && P=$PWD && "
           "mkdir -p ./hcc-393-prefix/include ./hcc-393-prefix/lib ./hcc-393-work && "
           "cp $D/include/tos.HH ./hcc-393-prefix/include/ && "
           "cp -P $D/lib/libtos.* ./hcc-393-prefix/lib/ && "
           "printf 'I64 LibTriple(I64 x) { return x * 3; }\\n"
           "I64 LibSquare(I64 x) { return x * x; }\\n"
           "public I64 (*triple)(I64) = &LibTriple;\\n"
           "public U0 Hcc393UseSquare() { triple = &LibSquare; }\\n'"
           " > ./hcc-393-work/hcc393.HC && "
           "cd ./hcc-393-work && "
           "$H -lib hcc393 --install-dir=$P/hcc-393-prefix hcc393.HC > /dev/null 2>&1") == 0,
        "build the -lib library");
  /* calls it, then sees the library repoint it */
  System("printf '#link <hcc393>\\n"
         "extern I64 (*triple)(I64);\\nU0 Hcc393UseSquare();\\n"
         "I32 Main() { if (triple(4) != 12) return 1; Hcc393UseSquare();"
         " if (triple(5) != 25) return 2; return 0; }\\n'"
         " > ./hcc-393-use.HC");
  Check(System("../../hcc -jit --install-dir=./hcc-393-prefix ./hcc-393-use.HC") == 0,
        "library function pointer (JIT)");
  Check(System("../../hcc --install-dir=./hcc-393-prefix ./hcc-393-use.HC -o ./hcc-393-use && "
               "./hcc-393-use") == 0,
        "library function pointer (AOT)");
  System("rm -rf ./hcc-393-prefix ./hcc-393-work ./hcc-393-use.HC ./hcc-393-use");

  PrintResult(g_correct, g_tests);
  "====\n";
  return 0;
}

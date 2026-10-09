"Test - -lib library loadable via #link (JIT + AOT): ";
#include "testhelper.HC"

/* `hcc -lib <name>` installs lib<name>.a plus the VERSIONED shared
 * object (lib<name>.so.0.0.1 / lib<name>.0.0.1.dylib) and deliberately
 * no unversioned one, so `-l<name>` keeps linking AOT statically. The
 * JIT used to dlopen only lib<name>.{so,dylib}, so `#link <name>` of a
 * `-lib` library failed under -jit. The library is installed into a
 * scratch prefix holding a copy of libtos from the prefix under test
 * ($HCC_INSTALL_DIR, else the default /usr/local); both the JIT and
 * the AOT program are pointed at that prefix. The AOT program runs
 * with no LD_LIBRARY_PATH, so it must have linked the archive. */

I64 correct = 0;
I64 tests = 3;

System("rm -rf ./hcc-85-prefix ./hcc-85-work ./hcc-85-use.HC ./hcc-85-use");

if (System("D=${HCC_INSTALL_DIR:-/usr/local} && H=$PWD/../../hcc && P=$PWD && "
           "mkdir -p ./hcc-85-prefix/include ./hcc-85-prefix/lib ./hcc-85-work && "
           "cp $D/include/tos.HH ./hcc-85-prefix/include/ && "
           "cp -P $D/lib/libtos.* ./hcc-85-prefix/lib/ && "
           "printf 'public I64 Hcc85Triple(I64 x) { return x * 3; }\n'"
           " > ./hcc-85-work/hcc85.HC && "
           "cd ./hcc-85-work && "
           "$H -lib hcc85 --install-dir=$P/hcc-85-prefix hcc85.HC > /dev/null 2>&1") == 0) {
  correct++;
}

System("printf '#link <hcc85>\n"
       "I64 Hcc85Triple(I64 x);\n"
       "I32 Main() { if (Hcc85Triple(14) == 42) return 0; return 1; }\n'"
       " > ./hcc-85-use.HC");

if (System("../../hcc -jit --install-dir=./hcc-85-prefix ./hcc-85-use.HC") == 0) {
  correct++;
}

if (System("../../hcc --install-dir=./hcc-85-prefix ./hcc-85-use.HC -o ./hcc-85-use && "
           "./hcc-85-use") == 0) {
  correct++;
}

System("rm -rf ./hcc-85-prefix ./hcc-85-work ./hcc-85-use.HC ./hcc-85-use");

PrintResult(correct, tests);
'===\n';
Exit(0);

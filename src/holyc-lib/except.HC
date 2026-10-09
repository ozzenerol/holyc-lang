/* TempleOS-style try/catch/throw runtime.
 *
 * The compiler lowers `try { body } catch <stmt>` into:
 *   - alloca CatchFrame on the stack
 *   - call HCC_TryEnter(&frame)  ; setjmp under the hood
 *   - if return value == 0:  run body, then HCC_TryLeave
 *   - else (got here via longjmp): pop frame, run handler
 *
 * `throw(value)` becomes `HCC_Throw(value)`; the runtime stashes the
 * u64 in Fs->except_ch and longjmps to the most recent catch frame.
 *
 * The compiler reserves 256 bytes for each CatchFrame slot, which is
 * larger than every platform jmp_buf we target plus the chain pointer.
 * The HolyC `class CatchFrame` below pads to exactly 256 bytes so the
 * layout the runtime sees matches what the compiler allocated.
 *
 * Each thread has its own HCFs (catch chain and thrown value), kept
 * under a pthread key: a throw only ever reaches a try of the thread
 * that threw. Fs() returns the calling thread's HCFs. */
#include "./defs.HH"

public extern "c" I32 setjmp(U0 *env);
public extern "c" U0 longjmp(U0 *env, I32 val);
extern "c" I32 pthread_once(U0 *once, U0 (*init)());
extern "c" I32 pthread_key_create(U64 *key, U0 (*destructor)(U0 *));
extern "c" U0 *pthread_getspecific(U64 key);
extern "c" I32 pthread_setspecific(U64 key, U0 *value);

/* Compiler reserves 256 bytes per CatchFrame. We split that into a
 * 248-byte jmp_buf storage region (setjmp owns the format) plus the
 * 8-byte chain pointer the runtime walks. */
#define __JMP_BUF_BYTES__ 248

class CatchFrame;
class CatchFrame
{
  I8 jb[__JMP_BUF_BYTES__];
  CatchFrame *prev;
};

class HCFs
{
  CatchFrame *catch_top;  /* head of the active-try-frames chain */
  U64 except_ch;          /* value of the most recent throw */
};

/* pthread_once_t is an int on Linux and a signed struct on macOS
 * (PTHREAD_ONCE_INIT is {0x30B1BCBA, {0}}); pthread_key_t is 4 bytes on
 * Linux and 8 on macOS, so 8 zeroed bytes hold either. */
#ifdef IS_MACOS
static I64 _fs_once[2] = {0x30B1BCBA, 0};
#else
static I64 _fs_once[2] = {0, 0};
#endif
static U64 _fs_key = 0;

static U0 FsFree(U0 *fs)
{
  free(fs);
}

static U0 FsKeyCreate()
{
  pthread_key_create(&_fs_key, &FsFree);
}

/* The calling thread's HCFs, created on its first use. */
public HCFs *Fs()
{
  pthread_once(_fs_once, &FsKeyCreate);
  HCFs *fs = pthread_getspecific(_fs_key);
  if (!fs) {
    fs = calloc(1, sizeof(HCFs));
    if (!fs) {
      "out of memory for the exception state\n";
      Exit(1);
    }
    pthread_setspecific(_fs_key, fs);
  }
  return fs;
}

/* Push the frame onto the catch-stack. The setjmp call itself MUST
 * stay inline in the user function (it captures the caller's frame,
 * and longjmp to a returned function's frame is UB), so the chain
 * mutation is the only thing we delegate to a helper. */
public U0 HCC_PushFrame(CatchFrame *f)
{
  HCFs *fs = Fs();
  f->prev = fs->catch_top;
  fs->catch_top = f;
}

public U0 HCC_TryLeave(CatchFrame *f)
{
  Fs()->catch_top = f->prev;
}

public U0 HCC_Throw(U64 v)
{
  HCFs *fs = Fs();
  fs->except_ch = v;
  auto t = fs->catch_top;
  if (!t) {
    "uncaught throw: %X\n", v;
    Exit(1);
  }
  longjmp(t->jb, 1);
}

#include "./defs.HH"

public extern "c" U0 exit(I32 status);
public extern "c" I32 system(U8 *command);
public extern "c" I64 write(I32 fd, U0 *buf, U64 nbyte);

#ifdef IS_X86_64
asm {
_EXIT::
    CALL    exit
    RET
}

public _extern _EXIT U0 Exit(I64 exit_code=EXIT_FAIL);
#endif

#ifdef IS_ARM_64
public U0 Exit(I64 exit_code=EXIT_FAIL)
{
  exit(exit_code);
}
#endif

/* Run `command` with the shell (`sh -c`). Returns the command's exit
 * code (0-255), or -1 if it was killed by a signal or the shell could
 * not be run (also for a NULL command). The shell itself gives 127 for
 * a command it can't find. */
public I64 System(U8 *command)
{
  if (!command) return -1;
  I32 status = system(command);
  if (status == -1) return -1;
  /* `system` returns a wait status: the low 7 bits are the signal that
   * killed the child, the exit code is in bits 8-15 */
  if (status & 0x7F) return -1;
  return (status >> 8) & 0xFF;
}

public I64 Write(I64 fd, U8 *buf, I64 len)
{
    return write(fd, buf, len);
}

#ifdef IS_LINUX
extern "c" I32 *__errno_location();
static I32 *ErrnoPtr() { return __errno_location(); }
#else
/* errno is *__error(); the raw name, as hcc doesn't prefix names starting with _ */
_extern ___error I32 *ErrnoPtr();
#endif

/* The calling thread's C errno: the reason the last failing libc call
 * (socket, connect, read, ...) gave. Only meaningful right after a call
 * that returned its error value. */
public I32 Errno()
{
  return *ErrnoPtr();
}

/* Set the calling thread's C errno, e.g. to 0 before a call that only
 * reports errors through errno. */
public U0 SetErrno(I32 err)
{
  *ErrnoPtr() = err;
}

/* Call the shell with `printf`-like formatting. Returns what System
 * returns: the exit code (0-255), or -1 if the command was killed by a
 * signal, could not be run, or fmt is NULL. */
public I32 Sh(U8 *fmt, ...)
{
  if (!fmt) return -1;
  /* Formatted even without arguments, so "%%" is always a single % */
  U8 *cmd = StrPrintJoin(NULL,fmt,argc,argv);
  I32 retval = System(cmd);
  Free(cmd);
  return retval;
}

/* s in single quotes for sh, as a new string to Free: each ' becomes
 * '\'' and NULL gives ''. Nothing in it is expanded by the shell, so
 * Sh("ls %s", q) passes s as one word. */
public U8 *ShQuote(U8 *s)
{
  I64 len = 2, i, j = 0;
  U8 *q;
  if (!s) s = "";
  for (i = 0; s[i]; i++) {
    if (s[i] == '\'') len += 4;
    else len++;
  }
  q = MAlloc(len + 1);
  q[j++] = '\'';
  for (i = 0; s[i]; i++) {
    if (s[i] == '\'') {
      MemCpy(q + j, "'\\''", 4);
      j += 4;
    } else {
      q[j++] = s[i];
    }
  }
  q[j++] = '\'';
  q[j] = '\0';
  return q;
}

extern "c" I32 mkstemp(U8 *template);
extern "c" I32 close(I32 fd);
extern "c" I32 unlink(U8 *path);
extern "c" U8 *getenv(U8 *name);

/* Run a shell command, built with `printf`-like formatting, and return
 * what it printed to stdout in a heap allocated string (Free it). One
 * trailing newline is removed. The exit status is not returned: a
 * failing command gives whatever it printed, often "". stderr is not
 * captured. Returns NULL if fmt is NULL or the output can't be read. */
public U8 *Shlurp(U8 *fmt, ...)
{
  if (!fmt) return NULL;
  U8 *tmp_path, *tmp_quoted, *tmpdir = getenv("TMPDIR");
  U8 *user_cmd, *cmd, *output;
  I64 len = 0;
  I32 fd;

  /* A unique temporary file per call, so concurrent calls don't share,
   * in $TMPDIR like the compiler's own temporary files */
  if (!tmpdir || !tmpdir[0]) tmpdir = "/tmp";
  tmp_path = StrPrint(NULL,"%s/hcc-shlurp-XXXXXX",tmpdir);
  fd = mkstemp(tmp_path);
  if (fd == -1) {
    Free(tmp_path);
    return NULL;
  }
  close(fd);
  tmp_quoted = ShQuote(tmp_path);

  user_cmd = StrPrintJoin(NULL,fmt,argc,argv);
  /* The braces redirect every command in a list (`a; b`), not just the
   * last one. The blank line ends a command that ends in a backslash and
   * `:` keeps the braces from being empty for an empty command. */
  cmd = StrPrint(NULL,"{\n%s\n\n:\n} > %s",user_cmd,tmp_quoted);
  Free(user_cmd);
  System(cmd);
  Free(cmd);

  Free(tmp_quoted);
  output = FileRead(tmp_path,&len);
  unlink(tmp_path);
  Free(tmp_path);
  if (!output) return NULL;
  if (len > 0 && output[len-1] == '\n') {
    output[len-1] = '\0';
  }
  return output;
}

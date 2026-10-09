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

/* Call the shell with `printf`-like formatting. Returns what System
 * returns: the exit code (0-255), or -1 if the command was killed by a
 * signal, could not be run, or fmt is NULL. */
public I32 Sh(U8 *fmt, ...)
{
  if (!fmt) return -1;
  if (argc == 0) return System(fmt);
  U8 *cmd = StrPrintJoin(NULL,fmt,argc,argv);
  I32 retval = System(cmd);
  Free(cmd);
  return retval;
}

extern "c" I32 mkstemp(U8 *template);
extern "c" I32 close(I32 fd);
extern "c" I32 unlink(U8 *path);

/* Run a shell command, built with `printf`-like formatting, and return
 * what it printed to stdout in a heap allocated string (Free it). One
 * trailing newline is removed. The exit status is not returned: a
 * failing command gives whatever it printed, often "". stderr is not
 * captured. Returns NULL if fmt is NULL or the output can't be read. */
public U8 *Shlurp(U8 *fmt, ...)
{
  if (!fmt) return NULL;
  U8 tmp_path[32];
  U8 *user_cmd, *cmd, *output;
  I64 len = 0;
  I32 fd;

  /* A unique temporary file per call, so concurrent calls don't share */
  MemCpy(tmp_path, "/tmp/hcc-shlurp-XXXXXX", 23);
  fd = mkstemp(tmp_path);
  if (fd == -1) return NULL;
  close(fd);

  if (argc == 0) user_cmd = fmt;
  else           user_cmd = StrPrintJoin(NULL,fmt,argc,argv);
  /* The braces redirect every command in a list (`a; b`), not just the
   * last one. The blank line ends a command that ends in a backslash and
   * `:` keeps the braces from being empty for an empty command. */
  cmd = StrPrint(NULL,"{\n%s\n\n:\n} > %s",user_cmd,tmp_path);
  if (user_cmd != fmt) Free(user_cmd);
  System(cmd);
  Free(cmd);

  output = FileRead(tmp_path,&len);
  unlink(tmp_path);
  if (!output) return NULL;
  if (len > 0 && output[len-1] == '\n') {
    output[len-1] = '\0';
  }
  return output;
}

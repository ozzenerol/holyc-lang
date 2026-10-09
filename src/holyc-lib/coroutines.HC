class Coroutine
{
  U0 *rsp;
  U0 *stack_base;
  Bool is_done;
};

/* A multiple of the page size, so the stack top is 16-byte aligned */
#define STACK_CAPACITY (655360)
/* An inaccessible page below each stack: an overflow faults instead of
 * writing over whatever is mapped below */
#define STACK_GUARD    (4096)

#define CORO_PROT_NONE  0x0
#define CORO_PROT_READ  0x1
#define CORO_PROT_WRITE 0x2
#define CORO_MAP_PRIVATE 0x02
#ifdef IS_MACOS
#define CORO_MAP_ANONYMOUS 0x1000
#else
#define CORO_MAP_ANONYMOUS 0x20
#endif

extern "c" U0 *mmap(U0 *addr, U64 len, I32 prot, I32 flags, I32 fd, I64 offset);
extern "c" I32 munmap(U0 *addr, U64 len);
extern "c" I32 mprotect(U0 *addr, U64 len, I32 prot);

static Coroutine *coroutine_stack[1000];
static I64 coroutine_sp = 0;

static U0 CoroutineStackPush(Coroutine *c)
{
  coroutine_stack[coroutine_sp++] = c;
}

static Coroutine *CoroutineStackPop()
{
  if (coroutine_sp - 1 < 0) return NULL;
  return coroutine_stack[--coroutine_sp];
}

static Coroutine *CoroutineStackLast()
{
  if (coroutine_sp == 0) return NULL;
  return coroutine_stack[coroutine_sp-1];
}

static U0 CoroutineInit()
{
  Coroutine *c = MAlloc(sizeof(Coroutine));
  MemSet(c, 0, sizeof(Coroutine));
  CoroutineStackPush(c);
}

U0 *CoroutineNext(Coroutine *c) {
asm {
    MOVL ESI, 16[RDI]
    CMP  ESI, 1
    JE   @@1
    PUSH RDI
    PUSH RBP
    PUSH RBX
    PUSH R12
    PUSH R13
    PUSH R14
    PUSH R15
    MOV RSI, RSP
    JMP CoroutineSwitchContext
@@1:
    XOR RAX, RAX
    RET
}
}

U0 CoroutineRestoreContext(U0 *_rsp)
{
asm {
    MOVQ RSP, RDI
    POP R15
    POP R14
    POP R13
    POP R12
    POP RBX
    POP RBP
    POP RDI
    RET
}
}

U0 CoroutineSwitchContext(Coroutine *c, U0 *_rsp)
{
  auto tail = CoroutineStackLast;
  if (tail) {
    tail->rsp = _rsp;
  }
  CoroutineStackPush(c);
  CoroutineRestoreContext(c->rsp);
}

U0 CoroutineRestoreContextAndReturn(U0 *_rsp, U0 *_arg)
{
asm {
    MOVQ RSP, RDI
    MOVQ RAX, RSI
    POP R15
    POP R14
    POP R13
    POP R12
    POP RBX
    POP RBP
    POP RDI
    RET
}
}

U0 *CoroutineYield(U0 *_arg)
{
asm {
    PUSH RDI
    PUSH RBP
    PUSH RBX
    PUSH R12
    PUSH R13
    PUSH R14
    PUSH R15
    MOVQ RSI, RSP
    JMP CoroutineReturn
}
}

U0 CoroutineReturn(U0 *_arg, U0 *_rsp)
{
  auto tail = CoroutineStackPop;
  if (!tail) {
    return;
  }
  tail->rsp = _rsp;
  auto next_tail = CoroutineStackLast;
  if (next_tail) {
    CoroutineRestoreContextAndReturn(next_tail->rsp, _arg);
  }
}

U0 CoroutineFinish()
{
  auto tail = CoroutineStackPop;
  if (!tail) {
    return;
  }

  tail->is_done = TRUE;
  auto next_tail = CoroutineStackLast;
  if (next_tail) {
    CoroutineRestoreContextAndReturn(next_tail->rsp, NULL);
  }
}

U0 CoroutineRelease(Coroutine *c)
{
  if (c) {
    munmap(c->stack_base, STACK_GUARD + STACK_CAPACITY);
    Free(c);
  }
}

Coroutine *CoroutineNew(U0 (*cb)(U0 *_arg), U0 *arg)
{// NULL if the stack can't be mapped
  Coroutine *c = MAlloc(sizeof(Coroutine));
  c->is_done = 0;
  c->stack_base = mmap(NULL, STACK_GUARD + STACK_CAPACITY,
      CORO_PROT_READ|CORO_PROT_WRITE, CORO_MAP_PRIVATE|CORO_MAP_ANONYMOUS, -1, 0);
  if (c->stack_base(I64) == -1) { /* MAP_FAILED */
    Free(c);
    return NULL;
  }
  if (mprotect(c->stack_base, STACK_GUARD, CORO_PROT_NONE) != 0) {
    munmap(c->stack_base, STACK_GUARD + STACK_CAPACITY);
    Free(c);
    return NULL;
  }
  U0 **_rsp = (c->stack_base + STACK_GUARD + STACK_CAPACITY)(U0 **);

  *(--_rsp) = &CoroutineFinish;
  *(--_rsp) = cb;
  *(--_rsp) = arg;
  *(--_rsp) = 0;
  *(--_rsp) = 0;
  *(--_rsp) = 0;
  *(--_rsp) = 0;
  *(--_rsp) = 0;
  *(--_rsp) = 0;
  c->rsp = _rsp;
  return c;
}

#ifndef COROUTINES_NO_DEMO
U0 Fib(U0 *arg)
{
  I64 max = arg(I64);
  I64 a = 0;
  I64 b = 1;
  while (a < max) {
    CoroutineYield(a(U0 *));
    I64 c = a + b;
    a = b;
    b = c;
  }
}

U0 Main()
{
  CoroutineInit;
  Coroutine *c = CoroutineNew(&Fib, 5(U0 *));
  for (auto it = CoroutineNext(c); !c->is_done; it = CoroutineNext(c)) {
    "%d\n",it;
  }
}
#endif

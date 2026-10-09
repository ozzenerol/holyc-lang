/* A key-value store server speaking a line protocol over TCP:
 *   SET <key> <value>   ->  OK
 *   GET <key>           ->  the value, or (nil)
 *   INCR <key>          ->  the new number (a missing key counts as 0)
 *   DEL <key>           ->  1 if it existed, else 0
 *   COUNT               ->  how many keys there are
 * Every client gets its own thread, and all of them share one StrMap
 * guarded by a mutex. Four clients run at once: each stores its name and
 * bumps a shared counter 250 times. Without the lock the threads would
 * corrupt the map (removing it makes this program crash), and increments
 * would be lost. A last client then reads everything back. */

#define WORKERS 4
#define BUMPS   250

class Store
{
  StrMap *map;
  pthread_mutex_t lock;
};

class Server
{
  I32 fd;
  I64 port;
  Store *store;
};

class Conn
{
  Store *store;
  I32 fd;
  U8 buf[512];   /* bytes read but not yet split into lines */
  I64 len;
};

/* The port the kernel gave a socket bound to port 0. */
I64 BoundPort(I32 fd)
{
  sockaddr_in addr;
  I64 len = sizeof(sockaddr_in);
  if (getsockname(fd, &addr(sockaddr *), &len) != 0) return -1;
  U16 p = addr.sin_port;              /* network byte order */
  return (p >> 8) | ((p & 0xFF) << 8);
}

Bool SendAll(I32 fd, U8 *buf, I64 len)
{
  while (len > 0) {
    I64 n = send(fd, buf, len, 0);
    if (n <= 0) return FALSE;
    buf += n;
    len -= n;
  }
  return TRUE;
}

/* Copy the next '\n'-terminated line into out (without the newline),
 * reading more from the socket as needed. FALSE when the peer is gone. */
Bool ReadLine(I32 fd, U8 *buf, I64 *_len, U8 *out, I64 cap)
{
  while (TRUE) {
    for (I64 i = 0; i < *_len; i++) {
      if (buf[i] == '\n') {
        I64 n = i;
        if (n >= cap) n = cap - 1;
        MemCpy(out, buf, n);
        out[n] = '\0';
        MemCpy(buf, buf + i + 1, *_len - i - 1);
        *_len -= i + 1;
        return TRUE;
      }
    }
    if (*_len >= 512) return FALSE;    /* line too long */
    I64 got = recv(fd, buf + *_len, 512 - *_len, 0);
    if (got <= 0) return FALSE;
    *_len += got;
  }
}

U0 FreeStr(U0 *p)
{
  Free(p);
}

/* Run one command against the store; the reply goes in out. */
U0 Execute(Store *st, U8 *line, U8 *out, I64 cap)
{
  U8 *cmd = line, *key = NULL, *val = NULL;
  key = strchr(cmd, ' ');
  if (key) {
    *key++ = '\0';
    val = strchr(key, ' ');
    if (val) *val++ = '\0';
  }

  pthread_mutex_lock(&st->lock);
  if (!StrCmp(cmd, "SET") && key && val) {
    StrMapDelete(st->map, key);                  /* frees an old key/value */
    StrMapSet(st->map, StrNew(key), StrNew(val));
    snprintf(out, cap, "OK");
  } else if (!StrCmp(cmd, "GET") && key) {
    U8 *v = StrMapGet(st->map, key);
    if (v) snprintf(out, cap, "%s", v);
    else   snprintf(out, cap, "(nil)");
  } else if (!StrCmp(cmd, "INCR") && key) {
    I64 n = 0;
    U8 *v = StrMapGet(st->map, key);
    if (v) n = Atoi(v);
    n++;
    StrMapDelete(st->map, key);
    StrMapSet(st->map, StrNew(key), StrPrint(NULL, "%d", n));
    snprintf(out, cap, "%d", n);
  } else if (!StrCmp(cmd, "DEL") && key) {
    snprintf(out, cap, "%d", StrMapDelete(st->map, key));
  } else if (!StrCmp(cmd, "COUNT")) {
    snprintf(out, cap, "%d", st->map->size);
  } else {
    snprintf(out, cap, "ERR unknown command");
  }
  pthread_mutex_unlock(&st->lock);
}

U0 *ServeConn(Conn *c)
{
  U8 line[256], reply[300];
  while (ReadLine(c->fd, c->buf, &c->len, line, sizeof(line))) {
    Execute(c->store, line, reply, sizeof(reply) - 1);
    I64 n = StrLen(reply);
    reply[n] = '\n';
    if (!SendAll(c->fd, reply, n + 1)) break;
  }
  close(c->fd);
  Free(c);
  return NULL;
}

/* Serve exactly `clients` connections, each on its own thread. */
U0 *AcceptLoop(Server *srv)
{
  pthread_t *handlers[WORKERS + 1];
  for (I64 i = 0; i < WORKERS + 1; i++) {
    Conn *c = CAlloc(sizeof(Conn));
    c->store = srv->store;
    c->fd = accept(srv->fd, NULL, NULL);
    pthread_create(&handlers[i],,&ServeConn,c);
  }
  for (I64 i = 0; i < WORKERS + 1; i++) {
    pthread_join(handlers[i]);
  }
  return NULL;
}

/* ---- client side ---- */

class Session
{
  I32 fd;
  U8 buf[512];
  I64 len;
};

Bool SessionOpen(Session *s, I64 port)
{
  MemSet(s, 0, sizeof(Session));
  s->fd = NetConnect("127.0.0.1", port);
  return s->fd > 0;
}

/* Send one command and wait for its one-line reply. */
U0 Call(Session *s, U8 *cmd, U8 *reply, I64 cap)
{
  SendAll(s->fd, cmd, StrLen(cmd));
  SendAll(s->fd, "\n", 1);
  if (!ReadLine(s->fd, s->buf, &s->len, reply, cap)) StrCpy(reply, "(closed)");
}

class Worker
{
  I64 id;
  I64 port;
};

U0 *RunWorker(Worker *w)
{
  Session s;
  U8 cmd[64], reply[64];
  if (!SessionOpen(&s, w->port)) return NULL;
  snprintf(cmd, sizeof(cmd), "SET worker:%d done-by-thread-%d", w->id, w->id);
  Call(&s, cmd, reply, sizeof(reply));
  for (I64 i = 0; i < BUMPS; i++) {
    Call(&s, "INCR hits", reply, sizeof(reply));
  }
  close(s.fd);
  return NULL;
}

U0 Show(Session *s, U8 *cmd)
{
  U8 reply[128];
  Call(s, cmd, reply, sizeof(reply));
  "%-16s -> %s\n", cmd, reply;
}

U0 Main()
{
  Store store;
  store.map = StrMapNew();
  StrMapSetFreeKey(store.map, &FreeStr);
  StrMapSetFreeValue(store.map, &FreeStr);
  pthread_mutex_init(&store.lock);

  Server srv;
  srv.store = &store;
  srv.fd = NetCreateServer(0, "127.0.0.1", WORKERS + 1);
  if (srv.fd <= 0) {
    "could not start the server\n";
    return;
  }
  srv.port = BoundPort(srv.fd);

  pthread_t *acceptor;
  pthread_create(&acceptor,,&AcceptLoop,&srv);

  Worker workers[WORKERS];
  pthread_t *threads[WORKERS];
  for (I64 i = 0; i < WORKERS; i++) {
    workers[i].id = i + 1;
    workers[i].port = srv.port;
    pthread_create(&threads[i],,&RunWorker,&workers[i]);
  }
  for (I64 i = 0; i < WORKERS; i++) {
    pthread_join(threads[i]);
  }
  "%d clients each sent INCR hits %d times\n", WORKERS, BUMPS;

  Session s;
  if (!SessionOpen(&s, srv.port)) {
    "could not connect\n";
    return;
  }
  Show(&s, "GET hits");
  Show(&s, "GET worker:1");
  Show(&s, "GET worker:4");
  Show(&s, "COUNT");
  Show(&s, "DEL worker:2");
  Show(&s, "DEL worker:2");
  Show(&s, "GET worker:2");
  Show(&s, "COUNT");
  Show(&s, "FLY away");
  close(s.fd);

  pthread_join(acceptor);
  close(srv.fd);
  StrMapRelease(store.map);
}

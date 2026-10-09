// Echo: a TCP echo server with one coroutine per connection, all on one
// thread, and poll() deciding which connection runs next.
//
//   hcc main.HC -o echo && ./echo     # self-test: serves 4 loopback clients, then exits
//   ./echo 7000                       # serve on port 7000 until stopped (try: nc 127.0.0.1 7000)
//   hcc -jit main.HC
//
// Shows: coroutines as lightweight tasks, poll() as the scheduler,
// non-blocking sockets (Errno() EAGAIN), NetSend, and threads for the
// test clients.

#define MAX_CONNS 64
#define CLIENTS   4
#define MESSAGES  3

class Conn
{
  I32 fd;
  I16 events;           // what its coroutine waits for: POLLIN or POLLOUT
  Coroutine *co;
  I64 bytes;            // bytes echoed
};

I64 total_conns, total_bytes;

// Pause the connection's coroutine until poll() says its socket is ready.
U0 WaitFor(Conn *c, I16 events)
{
  c->events = events;
  CoroutineYield;
}

// Write all of buf, waiting whenever the socket's send buffer is full.
Bool SendAll(Conn *c, U8 *buf, I64 len)
{
  I64 n;
  while (len > 0) {
    n = NetSend(c->fd, buf, len);
    if (n > 0) {
      buf += n;
      len -= n;
    } else if (Errno == EAGAIN) {
      WaitFor(c, POLLOUT);
    } else if (Errno != EINTR) {
      return FALSE;     // the peer is gone
    }
  }
  return TRUE;
}

// One connection, from accept to close. It reads like blocking code: the
// waiting happens in WaitFor, where the coroutine pauses.
U0 *Echo(U0 *arg)
{
  Conn *c = arg;
  U8 buf[4096];
  I64 n;
  while (TRUE) {
    n = recv(c->fd, buf, sizeof(buf), 0);
    if (n > 0) {
      c->bytes += n;
      if (!SendAll(c, buf, n)) break;
    } else if (n == 0) {
      break;            // the peer closed the connection
    } else if (Errno == EAGAIN) {
      WaitFor(c, POLLIN);
    } else if (Errno != EINTR) {
      break;
    }
  }
  close(c->fd);
  return NULL;
}

U0 Finish(Conn *c)
{
  total_conns++;
  total_bytes += c->bytes;
  CoroutineRelease(c->co);
  Free(c);
}

// Serve until `stop_after` connections have come and gone (0: forever).
U0 Serve(I32 srv, I64 stop_after)
{
  pollfd fds[MAX_CONNS + 1];
  Conn *conns[MAX_CONNS];
  I64 n = 0, i, accepted = 0;
  I32 fd;

  while (!stop_after || accepted < stop_after || n > 0) {
    fds[0].fd = srv;
    if (n == MAX_CONNS) fds[0].fd = -1;   // full: stop accepting for now
    fds[0].events = POLLIN;
    for (i = 0; i < n; i++) {
      fds[i + 1].fd = conns[i]->fd;
      fds[i + 1].events = conns[i]->events;
    }
    if (poll(fds, n + 1, -1) < 0) {
      if (Errno == EINTR) continue;
      break;
    }

    // Run every connection whose socket is ready. Backwards, so a finished
    // one can be replaced by the last one without skipping anything.
    for (i = n - 1; i >= 0; i--) {
      if (!fds[i + 1].revents) continue;
      CoroutineNext(conns[i]->co);
      if (CoroutineDone(conns[i]->co)) {
        Finish(conns[i]);
        conns[i] = conns[--n];
      }
    }

    // New connections: each gets a coroutine, run until it first waits.
    if (fds[0].revents & POLLIN) {
      while (n < MAX_CONNS && (fd = NetAccept(srv, TRUE)) != -1) {
        Conn *c = CAlloc(sizeof(Conn));
        c->fd = fd;
        c->co = CoroutineNew(&Echo, c);
        accepted++;
        CoroutineNext(c->co);
        if (CoroutineDone(c->co)) Finish(c);
        else conns[n++] = c;
      }
    }
  }
}

// --- the self-test: clients on their own threads -------------------------

class Client
{
  I64 id;
  I32 port;
  I64 ok;               // messages that came back unchanged
};

U0 *ClientMain(U0 *arg)
{
  Client *cl = arg;
  U8 msg[64], got[64];
  I64 i, len, have, n;
  I32 fd = NetConnect("127.0.0.1", cl->port);
  if (fd == -1) return NULL;
  for (i = 0; i < MESSAGES; i++) {
    StrPrint(msg, "client %d message %d\n", cl->id, i);
    len = StrLen(msg);
    if (NetSend(fd, msg, len) != len) break;
    for (have = 0; have < len; have += n) {
      n = recv(fd, got + have, len - have, 0);
      if (n <= 0) break;
    }
    got[have] = 0;
    if (!StrCmp(got, msg)) cl->ok++;
  }
  close(fd);
  return NULL;
}

I32 Main(I32 argc, U8 **argv)
{
  I32 port = 0, srv;
  I64 i;
  if (argc > 1) port = Atoi(argv[1]);
  srv = NetCreateServer(port, "127.0.0.1", 128, AF_INET, TRUE);
  if (srv == -1) {
    "can't listen on port %d\n", port;
    return 1;
  }
  if (argc > 1) {
    "echo server on 127.0.0.1:%d\n", port;
    Serve(srv, 0);
    return 0;
  }

  // Self-test: a free port, CLIENTS clients at once, stop when all are done.
  Client clients[CLIENTS];
  pthread_t *threads[CLIENTS];
  port = NetGetSocketPort(srv);
  for (i = 0; i < CLIENTS; i++) {
    clients[i].id = i;
    clients[i].port = port;
    clients[i].ok = 0;
    pthread_create(&threads[i], NULL, &ClientMain, &clients[i]);
  }
  Serve(srv, CLIENTS);
  for (i = 0; i < CLIENTS; i++) {
    pthread_join(threads[i]);
    "client %d: %d/%d echoes ok\n", i, clients[i].ok, MESSAGES;
  }
  "served %d connections, %d bytes\n", total_conns, total_bytes;
  close(srv);
  return 0;
}

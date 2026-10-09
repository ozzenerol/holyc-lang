/* A multithreaded TCP echo server and the clients that test it, in one
 * program. The server listens on 127.0.0.1 on a port the kernel picks,
 * accepts each client on its own thread and sends back every byte it
 * receives. Four client threads connect at the same time, send their
 * message in small pieces, and check that it comes back unchanged. */

#define CLIENTS 4

class Server
{
  I32 fd;
  I64 port;
  pthread_mutex_t lock;   /* guards bytes and served */
  I64 bytes;
  I64 served;
};

class Conn
{
  Server *srv;
  I32 fd;
};

class Client
{
  I64 id;
  I64 port;
  U8 sent[64];
  U8 got[64];
  Bool ok;
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

/* send() may write less than asked: keep going until all of it is out. */
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

/* Read exactly len bytes, or fail if the peer closes first. */
Bool RecvAll(I32 fd, U8 *buf, I64 len)
{
  while (len > 0) {
    I64 n = recv(fd, buf, len, 0);
    if (n <= 0) return FALSE;
    buf += n;
    len -= n;
  }
  return TRUE;
}

U0 *ServeConn(Conn *c)
{
  U8 buf[256];
  I64 n, total = 0;
  while ((n = recv(c->fd, buf, sizeof(buf), 0)) > 0) {
    if (!SendAll(c->fd, buf, n)) break;
    total += n;
  }
  close(c->fd);

  pthread_mutex_lock(&c->srv->lock);
  c->srv->bytes += total;
  c->srv->served++;
  pthread_mutex_unlock(&c->srv->lock);
  Free(c);
  return NULL;
}

/* Accept CLIENTS connections, one handler thread each, then wait for them. */
U0 *AcceptLoop(Server *srv)
{
  pthread_t *handlers[CLIENTS];
  for (I64 i = 0; i < CLIENTS; i++) {
    Conn *c = MAlloc(sizeof(Conn));
    c->srv = srv;
    c->fd = accept(srv->fd, NULL, NULL);
    pthread_create(&handlers[i],,&ServeConn,c);
  }
  for (I64 i = 0; i < CLIENTS; i++) {
    pthread_join(handlers[i]);
  }
  return NULL;
}

U0 *RunClient(Client *cl)
{
  I32 fd = NetConnect("127.0.0.1", cl->port);
  if (fd <= 0) return NULL;

  snprintf(cl->sent, sizeof(cl->sent), "hello from client %d, over TCP", cl->id);
  I64 len = StrLen(cl->sent);

  /* Send in 5-byte pieces: TCP is a byte stream, the echo must still match. */
  for (I64 off = 0; off < len; off += 5) {
    I64 piece = len - off;
    if (piece > 5) piece = 5;
    SendAll(fd, cl->sent + off, piece);
  }
  cl->ok = RecvAll(fd, cl->got, len);
  cl->got[len] = '\0';
  close(fd);
  return NULL;
}

U0 Main()
{
  Server srv;
  MemSet(&srv, 0, sizeof(Server));
  pthread_mutex_init(&srv.lock);

  srv.fd = NetCreateServer(0, "127.0.0.1", CLIENTS);
  if (srv.fd <= 0) {
    "could not start the server\n";
    return;
  }
  srv.port = BoundPort(srv.fd);
  "server listening on 127.0.0.1 (port chosen by the kernel)\n";

  pthread_t *acceptor;
  pthread_create(&acceptor,,&AcceptLoop,&srv);

  Client clients[CLIENTS];
  pthread_t *threads[CLIENTS];
  for (I64 i = 0; i < CLIENTS; i++) {
    MemSet(&clients[i], 0, sizeof(Client));
    clients[i].id = i + 1;
    clients[i].port = srv.port;
    pthread_create(&threads[i],,&RunClient,&clients[i]);
  }
  for (I64 i = 0; i < CLIENTS; i++) {
    pthread_join(threads[i]);
  }
  pthread_join(acceptor);
  close(srv.fd);

  for (I64 i = 0; i < CLIENTS; i++) {
    Client *cl = &clients[i];
    U8 *verdict = "MISMATCH";
    if (cl->ok && !StrCmp(cl->sent, cl->got)) verdict = "echoed";
    "client %d: %s \"%s\"\n", cl->id, verdict, cl->got;
  }
  "server handled %d connections, echoed %d bytes\n", srv.served, srv.bytes;
}

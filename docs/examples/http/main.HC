/* A tiny HTTP/1.0 server with a thread per connection, and a client that
 * sends it a few requests at the same time. The server has three routes:
 *   GET /             a greeting
 *   GET /add?a=&b=    adds two numbers from the query string
 *   anything else     404, or 405 for a method other than GET
 * Each response says how long its body is and closes the connection. */

#define REQUESTS 5

class Server
{
  I32 fd;
  I64 port;
};

class Request
{
  U8 method[8];
  U8 path[128];
  I64 status;
  U8 body[128];
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

/* Read until the peer closes (or the buffer is full). */
I64 RecvUntilClose(I32 fd, U8 *buf, I64 cap)
{
  I64 got = 0, n;
  while (got < cap - 1 && (n = recv(fd, buf + got, cap - 1 - got, 0)) > 0) {
    got += n;
  }
  buf[got] = '\0';
  return got;
}

/* Value of `name` in a query string like "a=2&b=40", or 0. */
I64 QueryInt(U8 *query, U8 *name)
{
  I64 nlen = StrLen(name);
  U8 *p = query;
  while (p && *p) {
    if (!StrNCmp(p, name, nlen) && p[nlen] == '=') return Atoi(p + nlen + 1);
    p = strchr(p, '&');
    if (p) p++;
  }
  return 0;
}

U8 *StatusText(I64 status)
{
  switch (status) {
    case 200: return "OK";
    case 404: return "Not Found";
    case 405: return "Method Not Allowed";
  }
  return "Error";
}

U0 Respond(I32 fd, I64 status, U8 *body)
{
  U8 *msg = StrPrint(NULL,
      "HTTP/1.0 %d %s\r\nContent-Type: text/plain\r\n"
      "Content-Length: %d\r\nConnection: close\r\n\r\n%s",
      status, StatusText(status), StrLen(body), body);
  SendAll(fd, msg, StrLen(msg));
  Free(msg);
}

U0 *ServeConn(I64 fd)
{
  U8 req[1024];
  I64 got = 0, n;

  /* Read the request head: everything up to the blank line. */
  while (got < sizeof(req) - 1) {
    n = recv(fd, req + got, sizeof(req) - 1 - got, 0);
    if (n <= 0) break;
    got += n;
    req[got] = '\0';
    if (strstr(req, "\r\n\r\n")) break;
  }
  req[got] = '\0';

  /* "GET /add?a=2&b=40 HTTP/1.0": split out the method and the target. */
  U8 *sp1 = strchr(req, ' ');
  U8 *sp2 = NULL;
  if (sp1) sp2 = strchr(sp1 + 1, ' ');
  if (!sp1 || !sp2) {
    Respond(fd, 400, "bad request\n");
  } else {
    *sp1 = '\0';
    *sp2 = '\0';
    U8 *method = req, *target = sp1 + 1;
    U8 *query = strchr(target, '?');
    if (query) *query++ = '\0';

    if (StrCmp(method, "GET")) {
      Respond(fd, 405, "only GET is supported\n");
    } else if (!StrCmp(target, "/")) {
      Respond(fd, 200, "Hello from HolyC\n");
    } else if (!StrCmp(target, "/add") && query) {
      I64 a = QueryInt(query, "a"), b = QueryInt(query, "b");
      U8 sum[64];
      snprintf(sum, sizeof(sum), "%d + %d = %d\n", a, b, a + b);
      Respond(fd, 200, sum);
    } else {
      Respond(fd, 404, "no such page\n");
    }
  }
  close(fd);
  return NULL;
}

U0 *AcceptLoop(Server *srv)
{
  pthread_t *handlers[REQUESTS];
  for (I64 i = 0; i < REQUESTS; i++) {
    I64 fd = accept(srv->fd, NULL, NULL);
    pthread_create(&handlers[i],,&ServeConn,fd(U0 *));
  }
  for (I64 i = 0; i < REQUESTS; i++) {
    pthread_join(handlers[i]);
  }
  return NULL;
}

class Job
{
  I64 port;
  Request *req;
};

/* Client side: send one request and parse the status code and body. */
U0 *Fetch(Job *job)
{
  Request *r = job->req;
  I32 fd = NetConnect("127.0.0.1", job->port);
  if (fd <= 0) return NULL;

  U8 *msg = StrPrint(NULL, "%s %s HTTP/1.0\r\nHost: localhost\r\n\r\n",
                     r->method, r->path);
  SendAll(fd, msg, StrLen(msg));
  Free(msg);

  U8 resp[1024];
  RecvUntilClose(fd, resp, sizeof(resp));
  close(fd);

  U8 *sp = strchr(resp, ' ');                /* "HTTP/1.0 200 OK" */
  if (sp) r->status = Atoi(sp + 1);
  U8 *body = strstr(resp, "\r\n\r\n");
  if (body) {
    StrCpy(r->body, body + 4);
    I64 len = StrLen(r->body);
    if (len && r->body[len - 1] == '\n') r->body[len - 1] = '\0';
  }
  return NULL;
}

U0 Main()
{
  Server srv;
  srv.fd = NetCreateServer(0, "127.0.0.1", REQUESTS);
  if (srv.fd <= 0) {
    "could not start the server\n";
    return;
  }
  srv.port = BoundPort(srv.fd);

  pthread_t *acceptor;
  pthread_create(&acceptor,,&AcceptLoop,&srv);

  Request reqs[REQUESTS];
  MemSet(reqs, 0, sizeof(reqs));
  StrCpy(reqs[0].method, "GET");  StrCpy(reqs[0].path, "/");
  StrCpy(reqs[1].method, "GET");  StrCpy(reqs[1].path, "/add?a=2&b=40");
  StrCpy(reqs[2].method, "GET");  StrCpy(reqs[2].path, "/add?b=-7&a=100");
  StrCpy(reqs[3].method, "GET");  StrCpy(reqs[3].path, "/missing");
  StrCpy(reqs[4].method, "POST"); StrCpy(reqs[4].path, "/");

  /* All five requests are in flight at once, each on its own thread. */
  Job jobs[REQUESTS];
  pthread_t *threads[REQUESTS];
  for (I64 i = 0; i < REQUESTS; i++) {
    jobs[i].port = srv.port;
    jobs[i].req = &reqs[i];
    pthread_create(&threads[i],,&Fetch,&jobs[i]);
  }
  for (I64 i = 0; i < REQUESTS; i++) {
    pthread_join(threads[i]);
  }
  pthread_join(acceptor);
  close(srv.fd);

  for (I64 i = 0; i < REQUESTS; i++) {
    Request *r = &reqs[i];
    "%-4s %-16s -> %d %-18s %s\n", r->method, r->path, r->status,
      StatusText(r->status), r->body;
  }
}

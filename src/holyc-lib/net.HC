/* Socket capabilities, a bit stripped down */
#ifdef IS_LINUX
  #define SOL_SOCKET      1   /* options for socket level */
  #define SO_DEBUG        1   /* turn on debugging info recording */
  #define SO_ACCEPTCONN   30  /* socket has had listen() */
  #define SO_REUSEADDR    2   /* allow local address reuse */
  #define SO_KEEPALIVE    9   /* keep connections alive */
  #define SO_DONTROUTE    5   /* just use interface addresses */
  #define SO_BROADCAST    6   /* permit sending of broadcast msgs */
  #define SO_LINGER       13  /* linger on close if data present (in seconds) */
  #define SO_OOBINLINE    10  /* leave received OOB data in line */
  #define SO_REUSEPORT    15  /* allow local address & port reuse */
  #define SO_TIMESTAMP    29  /* timestamp received dgram traffic */
#else
/*
 * Option flags per-socket.
 */
  #define SOL_SOCKET      0xffff          /* options for socket level */
  #define SO_DEBUG        0x0001          /* turn on debugging info recording */
  #define SO_ACCEPTCONN   0x0002          /* socket has had listen() */
  #define SO_REUSEADDR    0x0004          /* allow local address reuse */
  #define SO_KEEPALIVE    0x0008          /* keep connections alive */
  #define SO_DONTROUTE    0x0010          /* just use interface addresses */
  #define SO_BROADCAST    0x0020          /* permit sending of broadcast msgs */
  #define SO_LINGER       0x1080          /* linger on close if data present (in seconds) */
  #define SO_OOBINLINE    0x0100          /* leave received OOB data in line */
  #define SO_REUSEPORT    0x0200          /* allow local address & port reuse */
  #define SO_TIMESTAMP    0x0400          /* timestamp received dgram traffic */
  #define SO_TIMESTAMP_MONOTONIC  0x0800  /* Monotonically increasing timestamp on rcvd dgram */
#endif

/*
 * Address families.
 */
#define AF_UNSPEC       0               /* unspecified */
#define AF_UNIX         1               /* local to host (pipes) */
#define AF_INET         2               /* internetwork: UDP, TCP, etc. */

#ifdef IS_LINUX
  #define AF_INET6        10              /* IPv6 */
#else
  #define AF_INET6        30              /* IPv6 */
#endif

#define SOCK_STREAM     1               /* stream socket */
#define SOCK_DGRAM      2               /* datagram socket */
#define SOCK_RAW        3               /* raw-protocol interface */
#define SOCK_SEQPACKET  5               /* sequenced packet stream */


#define IPPROTO_IP              0               /* dummy for IP */
#define IPPROTO_ICMP            1               /* control message protocol */
#define IPPROTO_IPV4            4               /* IPv4 encapsulation */
#define IPPROTO_TCP             6               /* tcp */
#define IPPROTO_IPV6            41              /* IP6 header */
#define IPPROTO_ICMPV6          58              /* ICMP6 */
#define IPPROTO_RAW             255             /* raw IP packet */

#ifdef IS_LINUX
  #define TCP_NODELAY             1       /* don't delay send to coalesce packets */
  #define TCP_MAXSEG              2       /* set maximum segment size */
  #define TCP_CORK                3       /* don't send out partial frames */
  #define TCP_KEEPIDLE            4       /* idle time used when SO_KEEPALIVE is enabled */
  #define TCP_KEEPALIVE           4       /* the macOS name of TCP_KEEPIDLE */
  #define TCP_KEEPINTVL           5       /* interval between keepalives */
  #define TCP_KEEPCNT             6       /* number of keepalives before close */
  #define TCP_INFO                11      /* information about this connection */
  #define TCP_QUICKACK            12      /* block/reenable quick acks */
  #define TCP_USER_TIMEOUT        18      /* how long for loss retry before timeout */
  #define TCP_FASTOPEN            23      /* Enable/Disable TCP Fastopen on this socket */
#else
  #define TCP_NODELAY             0x01    /* don't delay send to coalesce packets */
  #define TCP_MAXSEG              0x02    /* set maximum segment size */
  #define TCP_NOPUSH              0x04    /* don't push last block of write */
  #define TCP_NOOPT               0x08    /* don't use TCP options */
  #define TCP_KEEPALIVE           0x10    /* idle time used when SO_KEEPALIVE is enabled */
  #define TCP_CONNECTIONTIMEOUT   0x20    /* connection timeout */
  #define PERSIST_TIMEOUT         0x40    /* time after which a connection in
	                                 *  persist timeout will terminate.
	                                 *  see draft-ananth-tcpm-persist-02.txt
	                                 */
  #define TCP_RXT_CONNDROPTIME    0x80    /* time after which tcp retransmissions will be
	                                 * stopped and the connection will be dropped
	                                 */
  #define TCP_RXT_FINDROP         0x100   /* when this option is set, drop a connection
	                                 * after retransmitting the FIN 3 times. It will
	                                 * prevent holding too many mbufs in socket
	                                 * buffer queues.
	                                 */
  #define TCP_KEEPINTVL           0x101   /* interval between keepalives */
  #define TCP_KEEPCNT             0x102   /* number of keepalives before close */
  #define TCP_SENDMOREACKS        0x103   /* always ack every other packet */
  #define TCP_ENABLE_ECN          0x104   /* Enable ECN on a connection */
  #define TCP_FASTOPEN            0x105   /* Enable/Disable TCP Fastopen on this socket */
  #define TCP_CONNECTION_INFO     0x106   /* State of TCP connection */
#endif

#define INET6_ADDRSTRLEN        46

#define	AI_PASSIVE	0x00000001 /* get address to use bind() */
#define	AI_CANONNAME	0x00000002 /* fill ai_canonname */
#define	AI_NUMERICHOST	0x00000004 /* prevent host name resolution */
#ifdef IS_LINUX
  #define	AI_NUMERICSERV	0x00000400 /* prevent service name resolution */
#else
  #define	AI_NUMERICSERV	0x00001000 /* prevent service name resolution */
  #define	AI_UNUSABLE	0x10000000 /* return addresses even if unusable (i.e. opposite of AI_DEFAULT) */
#endif

public class hostent
{
  U8	*h_name;	/* official name of host */
  U8	**h_aliases;	/* alias list */
  I32 h_addrtype;	/* host address type */
  I32 h_length;	/* length of address */
  U8	**h_addr_list;	/* list of addresses from name server */
};

/*
 * Assumption here is that a network number
 * fits in an unsigned long -- probably a poor one.
 */
public class netent
{
  U8  *n_name;      /* official name of net */
  U8  **n_aliases;  /* alias list */
  I32 n_addrtype;   /* net address type */
  U32 n_net;        /* network # */
};

public class servent
{
  U8 *s_name;	  /* official service name */
  U8 **s_aliases; /* alias list */
  I32 s_port;     /* port # */
  U8 *s_proto;    /* protocol to use */
};

public class protoent
{
  U8  *p_name;     /* official protocol name */
  U8  **p_aliases; /* alias list */
  I32 p_proto;     /* protocol # */
};

/* Linux has no length byte: the family is a U16 at the start. The BSDs and
 * macOS start with a U8 length and a U8 family. */
public class sockaddr
{
#ifdef IS_LINUX
  U16 sa_family;
#else
  U8 sa_len;
  U8 sa_family;
#endif
  U8 sa_data[14];
};

public class in_addr
{
  U32 s_addr;
};

public class sockaddr_in
{
#ifdef IS_LINUX
  U16 sin_family;
#else
  U8 sin_len;
  U8 sin_family;
#endif
  U16 sin_port;
  in_addr sin_addr;
  U8 sin_zero[8];
};

public class in6_addr
{
  union
  {
    U8   __u6_addr8[16];
    U16  __u6_addr16[8];
    U32  __u6_addr32[4];
  };                    /* 128-bit IP6 address */
};

public class sockaddr_in6
{
#ifdef IS_LINUX
  U16 sin6_family;    /* AF_INET6 (sa_family_t) */
#else
  U8  sin6_len;        /* length of this struct(sa_family_t) */
  U8  sin6_family;     /* AF_INET6 (sa_family_t) */
#endif
  U16 sin6_port;      /* Transport layer port # (in_port_t) */
  U32 sin6_flowinfo;  /* IP6 flow information */
  in6_addr sin6_addr; /* IP6 address */
  U32 sin6_scope_id;  /* scope zone index */
};

public class addrinfo;
public class addrinfo
{
  I32 ai_flags;	/* AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST */
  I32 ai_family;	/* PF_xxx */
  I32 ai_socktype;	/* SOCK_xxx */
  I32 ai_protocol;	/* 0 or IPPROTO_xxx for IPv4 and IPv6 */
  U32 ai_addrlen;	/* length of ai_addr */
#ifdef IS_LINUX
  sockaddr *ai_addr;	/* binary address */
  U8  *ai_canonname;	/* canonical name for hostname */
#else
  U8  *ai_canonname;	/* canonical name for hostname */
  sockaddr *ai_addr;	/* binary address */
#endif
  addrinfo *ai_next;	/* next structure in linked list */
};

#define _SS_PAD1SIZE (6)
#define _SS_PAD2SIZE (112)

public class sockaddr_storage
{
#ifdef IS_LINUX
  U16 ss_family;      /* address family */
#else
  U8  ss_len;         /* address length */
  U8  ss_family;      /* [XSI] address family */
#endif
  U8  __ss_pad1[_SS_PAD1SIZE];
  I64 __ss_align;     /* force structure storage alignment */
  U8  __ss_pad2[_SS_PAD2SIZE];
};

public class msghdr
{
  U8    *msg_name;      /* [XSI] optional address */
  I64   msg_namelen;    /* [XSI] size of address */
  iovec *msg_iov;       /* [XSI] scatter/gather array */
  I32   msg_iovlen;     /* [XSI] # elements in msg_iov */
  U0    *msg_control;   /* [XSI] ancillary data, see below */
  I64   msg_controllen; /* [XSI] ancillary data buffer len */
  I32   msg_flags;      /* [XSI] flags on received message */
};

public class sockaddr_un
{
#ifdef IS_LINUX
  U16 sun_family;    /* AF_UNIX */
  U8 sun_path[108];  /* path name */
#else
  U8 sun_len;        /* sockaddr len including null */
  U8 sun_family;     /* [XSI] AF_UNIX */
  U8 sun_path[104];  /* [XSI] path name (gag) */
#endif
};

public extern "c" I32 setsockopt(I32 __sockfd, I32 __level, I32 __option_name,
    U0 *__option_value, I64 __option_len);
public extern "c" I32 getsockopt(I32 socket, I32 level, I32 option_name,
    U0 * option_value, I64 *option_len);
public extern "c" I32 shutdown(I32 socket, I32 how);
public extern "c" U32 inet_addr(U8 *cp);
public extern "c" I32 inet_aton(U8 *cp, in_addr *pin);
public extern "c" U32 inet_lnaof(in_addr in);
public extern "c" in_addr inet_makeaddr(U32 net, U32 lna);
public extern "c" U32 inet_netof(in_addr in);
public extern "c" U32 inet_network(U8 *cp);
public extern "c" U8 *inet_ntoa(in_addr in);
public extern "c" U8 *inet_ntop(I32 af, U0 *src, U8 *dst, I64 size);
public extern "c" I32 inet_pton(I32 af, U8 *src, U0 *dst);

public extern "c" U0 endhostent();
public extern "c" U0 endnetent();
public extern "c" U0 endprotoent();
public extern "c" U0 endservent();

public extern "c" U0 freeaddrinfo(addrinfo *info);
public extern "c" U8 *gai_strerror(I32 __err);
public extern "c" I32 getaddrinfo(U8 *hostname, U8 *servname, addrinfo *hints, addrinfo **res);
/* Depricated */
hostent *gethostbyaddr(U0 *ptr, I64 len, I32 type);
/* Depricated */
hostent *gethostbyname(U8 * name);

public extern "c" hostent *gethostent();
public extern "c" I32 getnameinfo(sockaddr *sa, I64 salen, U8 *host,
    I64 hostlen, U8 *serv, I64 servlen, I32 flags);
public extern "c" netent *getnetbyaddr(U32 net, I32 type);
public extern "c" netent *getnetbyname(U8 *name);
public extern "c" netent *getnetent();
public extern "c" protoent *getprotobyname(U8 *name);
public extern "c" protoent *getprotobynumber(I32 proto);
public extern "c" protoent *getprotoent();
public extern "c" servent *getservbyname(U8 *name, U8 *proto);
public extern "c" servent *getservbyport(I32 port, U8 *proto);
public extern "c" servent *getservent();
public extern "c" U0 sethostent(I32 stayopen);
public extern "c" U0 setnetent(I32 stayopen);
public extern "c" U0 setprotoent(I32 stayopen);
public extern "c" U0 setservent(I32 stayopen);
public extern "c" U8 *hstrerror(I32 err);

public extern "c" I32 socket(I32 domain, I32 type, I32 protocol);
public extern "c" I32 connect(I32 socket, sockaddr *address, I64 address_len);
public extern "c" I32 accept(I32 socket, sockaddr *address, I64 *address_len);
public extern "c" I32 bind(I32 socket, sockaddr *address, I64 address_len);
public extern "c" I32 getpeername(I32 socket, sockaddr *address, I64 *address_len);
public extern "c" I64 recvmsg(I32 socket, msghdr *message, I32 flags); 
public extern "c" I64 recvfrom(I32 socket, U0 *buffer, U64 length, I32 flags, sockaddr *address, U64 *address_len);
public extern "c" I64 recv(I32 socket, U0 *buffer, U64 length, I32 flags);
public extern "c" I32 listen(I32 socket, I32 backlog);
public extern "c" I32 getsockname(I32 socket, sockaddr *address, I64 *address_len);
public extern "c" I64 send(I32 socket, U0 *buffer, U64 length, I32 flags);
public extern "c" I64 sendmsg(I32 socket, msghdr *message, I32 flags);
public extern "c" I64 sendto(I32 socket, U0 *buffer, U64 length, I32 flags, sockaddr *dest_addr, U64 dest_len);

public Bool NetSetSocketNonBlocking(I32 sockfd)
{
  I32 flags = fcntl(sockfd, F_GETFL, 0);
  if (fcntl(sockfd,F_SETFL,flags|O_NONBLOCK)) {
    return FALSE;
  }
  return TRUE;
}

public Bool NetSetSockReuseAddr(I32 sockfd)
{
  I32 yes = 1;

  if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(I32)) == -1)
    return FALSE;

  return TRUE;
}

/* Set TCP no delay, turn off Nagle buffering. Makes the socket sent data as soon
 * as it is avalible. Returns TRUE on success and FALSE if setsockopt fails.
 *
 * https://www.extrahop.com/company/blog/2016/tcp-nodelay-nagle-quickack-best-practices/
 * */
public Bool NetSetSocketNoDelay(I32 sockfd)
{
  I32 yes = 1;

  if (setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, &yes, sizeof(I32)) == -1)
    return FALSE;

  return TRUE;
}

static U0 *NetGetInAddress(sockaddr *sa)
{
  if (sa->sa_family == AF_INET)
    return &(sa(sockaddr_in*)->sin_addr);
  return &(sa(sockaddr_in6 *)->sin6_addr);
}

/* Fills out buf with the IPV4 address */
public Bool NetGetIpv4Address(sockaddr *sAddr, I32 ai_family, U8 *outbuf, I32 size)
{
  U0 *address;
  address = NetGetInAddress(sAddr);
  if (inet_ntop(ai_family, address, outbuf, size) == NULL)
    return FALSE;
  return TRUE;
}

public I32 NetConnect(U8 *addr, I32 port, Bool non_blocking=FALSE)
{// Returns the connected socket, or -1 on failure
  U8 strport[6];
  I32 sockfd;
  addrinfo hints, *servinfo, *ptr;
  I32 rv;

  snprintf(strport, sizeof(strport), "%d", port);
  MemSet(&hints, 0, sizeof(addrinfo));
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  sockfd = -1;

  if ((rv = getaddrinfo(addr, strport, &hints, &servinfo)) != 0) {
    return -1;
  }

  /* connect on the first one we can */
  for (ptr = servinfo; ptr != NULL; ptr = ptr->ai_next) {
    if ((sockfd = socket(ptr->ai_family, ptr->ai_socktype,
            ptr->ai_protocol)) == -1) {
      continue;
    }

    if (connect(sockfd, ptr->ai_addr, ptr->ai_addrlen) == -1) {
      close(sockfd); /* try the next address */
      sockfd = -1;
      continue;
    }
    if (!NetSetSockReuseAddr(sockfd)) goto error;
    if (non_blocking)
      if (!NetSetSocketNonBlocking(sockfd)) goto error;

    break;
  }


  if (ptr == NULL) {
    goto error;
  }

  freeaddrinfo(servinfo);

  return sockfd;

error:
  if (sockfd != -1) close(sockfd);
  freeaddrinfo(servinfo);
  return -1;
}

public Bool NetListen(I32 sockfd, addrinfo *sa, I32 backlog)
{
  if (bind(sockfd, sa->ai_addr, sa->ai_addrlen) == -1) {
    close(sockfd);
    return FALSE;
  }

  if (listen(sockfd, backlog) == -1) {
    close(sockfd);
    return FALSE;
  }
  return TRUE;
}

public I32 NetCreateServer(I32 port, U8 *bindaddr, I32 backlog,
    I32 addrfam=AF_UNSPEC, Bool non_blocking=FALSE)
{// Returns the listening socket, or -1 on failure
  I32 sockfd = -1, rv;
  U8 strport[6];
  addrinfo hints, *servinfo, *ptr;

  snprintf(strport, sizeof(strport), "%d", port);
  MemSet(&hints, 0, sizeof(addrinfo));

  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_PASSIVE;

  if (bindaddr != NULL && !StrCmp("*", bindaddr))
    bindaddr = NULL;
  if (addrfam == AF_INET6 && bindaddr && !StrCmp("::*", bindaddr))
    bindaddr = NULL;

  if ((rv = getaddrinfo(bindaddr, strport, &hints, &servinfo)) != 0)
    return -1;

  for (ptr = servinfo; ptr != NULL; ptr = ptr->ai_next) {
    if ((sockfd = socket(ptr->ai_family, ptr->ai_socktype,
            ptr->ai_protocol)) == -1)
      continue;

    if (!NetSetSockReuseAddr(sockfd)) {
      close(sockfd); /* try the next address */
      sockfd = -1;
      continue;
    }
    if (!NetListen(sockfd, ptr, backlog)) {
      sockfd = -1; /* NetListen closed it; try the next address */
      continue;
    }
    if (non_blocking)
      if (!NetSetSocketNonBlocking(sockfd)) goto error;
    break;
  }

  if (ptr == NULL) {
    goto error;
  }

  freeaddrinfo(servinfo);
  return sockfd;

error:
  if (sockfd != -1) close(sockfd);
  freeaddrinfo(servinfo);
  return -1;
}

public I32 NetAccept(I32 socket, Bool non_blocking=FALSE)
{// Returns the accepted socket, or -1 on failure
  I32 accepted;
  I64 socklen = sizeof(sockaddr_storage);
  sockaddr_storage in_addr;

  if ((accepted = accept(socket,(&in_addr)(sockaddr *),&socklen)) == -1) {
    return -1;
  }

  if (non_blocking) {
    if (!NetSetSocketNonBlocking(accepted)) {
      close(accepted);
      return -1;
    }
  }
  return accepted;
}

/**
 * Socket needs to be accepted for this to work, a better function
 * could probably be made as this only accepts IPV4 which doesn't feel
 * right.
 */
public Bool NetGetIpv4AddressFromAcceptedSocket(I32 sockfd, U8 *ipbuf, I32 outlen)
{
  sockaddr sa;
  I64 len;
  I32 retval;

  len = sizeof(sockaddr);
  if ((retval = getpeername(sockfd, &sa, &len)) == -1) {
    return FALSE;
  }

  return NetGetIpv4Address(&sa, (&sa)(sockaddr_in *)->sin_family, ipbuf, outlen);
}

/* Fills `addr` for the socket file `name`; FALSE if the path doesn't fit */
static Bool NetUnixAddress(sockaddr_un *addr, U8 *name)
{
  I64 len = StrLen(name);
  if (len >= sizeof(addr->sun_path)) {
    return FALSE;
  }
  MemSet(addr, 0, sizeof(sockaddr_un));
#ifndef IS_LINUX
  addr->sun_len = sizeof(sockaddr_un);
#endif
  addr->sun_family = AF_UNIX;
  MemCpy(addr->sun_path, name, len + 1);
  return TRUE;
}

public I32 NetCreateUnixServerSocket(U8 *name, I32 backlog)
{// Listens on the socket file `name`; returns the socket or -1 on failure
  I32 sockfd = -1;
  sockaddr_un srv;

  if (!NetUnixAddress(&srv, name))
    return -1;

  if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
    goto error;

  unlink(name);
  if ((bind(sockfd, (&srv)(sockaddr *), sizeof(sockaddr_un))) == -1)
    goto error;

  if (listen(sockfd, backlog) == -1)
    goto error;

  return sockfd;

error:
  if (sockfd != -1) {
    close(sockfd);
  }
  return -1;
}

public I32 NetCreateUnixClientSocket(U8 *name)
{// Connects to the socket file `name`; returns the socket or -1 on failure
  I32 sockfd;
  sockaddr_un srv;

  if (!NetUnixAddress(&srv, name))
    return -1;

  if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
    return -1;

  if (connect(sockfd, (&srv)(sockaddr *), sizeof(sockaddr_un)) == -1) {
    close(sockfd);
    return -1;
  }
  return sockfd;
}

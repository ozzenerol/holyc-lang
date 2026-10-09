/* All prototypes and classes for all functions and classes provided
 * by the library */
/* XXX: now we have a JSON parser it should be easier to generate this code, 
 * JSON might be easier to maintain than this ever growing header file? */
#define SF_ARG1 8
#define SF_ARG2 16
#define SF_ARG3 24
#define SF_ARG4 32
#define SF_ARG5 40
#define SF_ARG6 48
#define SF_ARG7 52
#define SF_ARG8 56

#define TRUE  1
#define FALSE 0
#define NULL  0

/* POSIX file descriptor numbers */
#define STDIN  0
#define STDOUT 1
#define STDERR 2

#define __BUFSIZ__ 2048

#define EXIT_FAIL 1
#define EXIT_OK   0

#define I64_MIN (-0x7fffffffffffffff - 1)
#define I64_MAX 0x7fffffffffffffff
#define U64_MAX 0xffffffffffffffff
#define U8_MAX  0xFF
#define I8_MAX  0x7F
#define I8_MIN  0xFFFFFF80

public class List;
/* A circular doubly linked list of U0 * values. The list itself is a head
 * node (value unused) that links to itself when the list is empty; walk it
 * with `for (List *it = l->next; it != l; it = it->next)`. Values are
 * borrowed: the list never frees them unless you pass a free function. */
public class List
{
  U0 *value;
  List *next, *prev;
};

/* Make `l` (usually a head on the stack or inside a class) an empty list.
 * Such a head must be emptied with ListClear, never ListRelease. */
public U0 ListInit(List *l);
/* A new empty list (a heap-allocated head); free it with ListRelease. */
public List *ListNew();
/* Add `value` at the front. */
public U0 ListPrepend(List *head, U0 *value);
/* Add `value` at the end. */
public U0 ListAppend(List *head, U0 *value);
/* TRUE if the list has no values (also for NULL). */
public Bool ListEmpty(List *l);
/* Remove the first value and return it (a queue's shift): NULL when the
 * list is empty or NULL - a stored NULL looks the same, so check
 * ListEmpty first if you store NULLs. */
public U0 *ListDeque(List *l);
/* Link `new_node` (not in any list) in before `ll`; with `ll` the head,
 * that is the end of the list. */
public U0 ListInsertBefore(List *ll, List *new_node);
/* Insert `value` before the node `ll` (before the head = at the end). */
public U0 ListInsertValueBefore(List *ll, U0 *value);
/* Remove the last value and return it: NULL when the list is empty or NULL
 * (a stored NULL looks the same, see ListDeque). */
public U0 *ListPop(List *l);
/* Free every node, calling FreeValue on each value if it is not NULL,
 * and then the head itself - so only for ListNew lists (use ListClear on a
 * ListInit head). NULL is ignored. */
public U0 ListRelease(List *ll, U0 (*FreeValue)(U0 *arg));
/* The number of values. O(n): it walks the list. 0 for NULL. */
public I64 ListCount(List *ll);
/* Free every node (calling free_value on each value, if given) but keep
 * the head, now empty; works on a ListInit (stack) head. NULL is ignored. */
public U0 ListClear(List *l, U0 (*free_value)(U0 *value) = NULL);
/* Unlink `node` from its list, free it and return its value. Must not be
 * given the list's head (an empty head is left alone, returning NULL).
 * NULL returns NULL. */
public U0 *ListRemove(List *node);
/* The first value without removing it; NULL if the list is empty or
 * NULL (a stored NULL looks the same: check ListEmpty). */
public U0 *ListFirst(List *l);
/* The last value without removing it; NULL if the list is empty or NULL. */
public U0 *ListLast(List *l);
/* Move all of l2's nodes to the start (Prepend) or the end (Append) of
 * l1, then free l2's head: l2 must not be used afterwards, and must have
 * come from ListNew. An empty l2 is just freed; if either is NULL nothing
 * happens. */
public U0 ListMergePrepend(List *l1, List *l2);
public U0 ListMergeAppend(List *l1, List *l2);

#define CSV_EOF   0
#define CSV_ROW   1
#define CSV_FIELD 2

public extern "c" I32 open(U8 *__name, I32 flags, ...);
public extern "c" I32 creat(U8 *__name, U16 __flags);
public extern "c" I32 fcntl(I32 __fd, I32 __flags, ...);
public extern "c" I32 close(I32 __fd);
public extern "c" I64 read(I32 __fd, U0 *__buf, U64 __nbyte);
public extern "c" I64 write(I32 __fd, U0 *__buf, U64 __nbyte);
public extern "c" I64 lseek(I32 __fd, I64 __offset, I32 __whence);
public extern "c" I32 chdir(U8 *path);

public class CsvParser {
  U8 *csv;
  U64 len, off, row_off, nrows, nfields;
  I64 state;
};

public class CsvSlice {
  U64 idx, off, len;
};
public U0 CsvParserInit(CsvParser *p, U8 *csv, U64 len);
public I64 CsvParse(CsvParser *p, CsvSlice *s);

#define CDATE_YEAR_DAYS        365.24225
#define CDATE_YEAR_DAYS_INT    36524225
#define CDATE_BASE_DAY_OF_WEEK 0

/* XXX: Normalise stat ? */
public class cTimespec
{
  I64 tv_sec;
  I64 tv_nsec;
};

public class timeval
{ // c compatability
  I64 tv_sec;        /* seconds since Jan. 1, 1970 */
  I32 tv_usec;         /* and microseconds */
};

public class tm 
{     // c compatability
  I32 tm_sec;  /* seconds after the minute [0-60] */
  I32 tm_min;  /* minutes after the hour [0-59] */
  I32 tm_hour;   /* hours since midnight [0-23] */
  I32 tm_mday;   /* day of the month [1-31] */
  I32 tm_mon;  /* months since January [0-11] */
  I32 tm_year;   /* years since 1900 */
  I32 tm_wday;   /* days since Sunday [0-6] */
  I32 tm_yday;   /* days since January 1 [0-365] */
  I32 tm_isdst;  /* Daylight Savings Time flag */
  I64 tm_gmtoff; /* offset from UTC in seconds */
  I8 *tm_zone;   /* timezone abbreviation */
};

public extern "c" tm *localtime(I64 *clock);
public extern "c" I32 gettimeofday(timeval *tp, U0 *tzp);

public I64 class CDate {
  U32 time;
  I32 date;
};

public class CDateStruct {
  U64 sec10000, sec100, sec, min, hour, day_of_week, day_of_mon, mon;
  I32 year;
  I64 zone_diff;
};

public U64 NowMilliseconds();
public U0 NowDateTimeStruct(CDateStruct *_ds);
public I64 YearStartDate(I64 year);
public I64 DayOfWeek(I64 i);
public U0 Date2Struct(CDateStruct *_ds, CDate cdt);
public CDate Struct2Date(CDateStruct *_ds);
public I32 FirstDayOfMon(I64 i);
public I64 LastDayOfMon(I64 i);
public I32 FirstDayOfYear(I64 i);
public I64 LastDayOfYear(I64 i);
public CDate Now();
public U0 IsoFromTimespec(cTimespec *ts, U8 *buf);

/* The `order` of a deleted hash table node (a tombstone) */
#define HT_DELETED 0x7fffffffffffffff

/* Growable arrays: `entries[0..size)` are the values, and the vector
 * owns `entries`. `size` and `entries` can be read directly, and
 * `for (I64 x : v)` walks the values; push, pop and set go through the
 * functions so the storage can grow. */
public class IntVec
{
  I64 size;
  I64 *entries;
};

/* A growable array of U0 * values; see IntVec. The values are borrowed
 * unless a free function is passed to PtrVecRelease. */
public class PtrVec
{
  I64 size;
  U0 **entries;
};

/* A growable array of F64 values; see IntVec. */
public class FloatVec 
{
  I64 size;
  F64 *entries;
};

/* Sort arr[low..high] in place (note the order: high before low).
 * `_compare_fn(a, b)` returns TRUE when `a` must come before `b` - a
 * "less than", not a C-style -1/0/1 comparator, which leaves the array
 * unsorted. Not stable; O(n log n), also on sorted, reversed and
 * all-equal input. IntVecSort/FloatVecSort/PtrVecSort use it. */
U0 QSortGeneric(U0 **arr, I64 high, I64 low, 
    I64 (*_compare_fn)(U0 *_arg1, U0 *_arg2));

/* A new empty vector with room for `size` values before it has to grow
 * (its initial capacity). A size below 1 (0 or negative) is taken as 1. */
public FloatVec *FloatVecNew(I64 size = 32);
/* How many values fit before the next push has to grow the storage. */
public U64 FloatVecCapacity(FloatVec *vec);
/* Append `value`, growing the storage (doubling it) when needed. */
public U0 FloatVecPush(FloatVec *vec, F64 value);
/* Remove and return the last entry. When empty, returns -1.0 and sets
 * *_ok to FALSE; `_ok` may be NULL if you don't need to tell. */
public F64 FloatVecPop(FloatVec *vec, Bool *_ok = NULL);
/* The entry at `idx`. An index outside [0, size) prints
 * "FloatVecGet: index N out of range (size M)" on stderr and exits with 1. */
public F64 FloatVecGet(FloatVec *vec, I64 idx);
/* Replace the entry at `idx`; out of range prints an error and exits,
 * like FloatVecGet. */
public U0 FloatVecSet(FloatVec *vec, I64 idx, F64 value);
/* The last entry without removing it; -1.0 and *_ok = FALSE when empty. */
public F64 FloatVecLast(FloatVec *vec, Bool *_ok = NULL);
/* Set the size to 0; the storage is kept for reuse. */
public U0 FloatVecClear(FloatVec *vec);
/* Free the storage and the vector. NULL is ignored. */
public U0 FloatVecRelease(FloatVec *vec);
/* Sort ascending, in place (not stable, O(n log n)). */
public U0 FloatVecSort(FloatVec *vec);

/* A new empty vector with room for `size` values before it has to grow
 * (its initial capacity). A size below 1 (0 or negative) is taken as 1. */
public IntVec *IntVecNew(I64 size = 32);
/* How many values fit before the next push has to grow the storage. */
public U64 IntVecCapacity(IntVec *vec);
/* Append `value`, growing the storage (doubling it) when needed. */
public U0 IntVecPush(IntVec *vec, I64 value);
/* Remove and return the last entry. When empty, returns -1 and sets
 * *_ok to FALSE; `_ok` may be NULL if you don't need to tell. */
public I64 IntVecPop(IntVec *vec, Bool *_ok = NULL);
/* The entry at `idx`. An index outside [0, size) prints
 * "IntVecGet: index N out of range (size M)" on stderr and exits with 1. */
public I64 IntVecGet(IntVec *vec, I64 idx);
/* Replace the entry at `idx`; out of range prints an error and exits,
 * like IntVecGet. */
public U0 IntVecSet(IntVec *vec, I64 idx, I64 value);
/* The last entry without removing it; -1 and *_ok = FALSE when empty. */
public I64 IntVecLast(IntVec *vec, Bool *_ok = NULL);
/* Set the size to 0; the storage is kept for reuse. */
public U0 IntVecClear(IntVec *vec);
/* Free the storage and the vector. NULL is ignored. */
public U0 IntVecRelease(IntVec *vec);
/* Sort ascending, in place (not stable, O(n log n)). */
public U0 IntVecSort(IntVec *vec);

/* A new empty vector with room for `size` values before it has to grow
 * (its initial capacity). A size below 1 (0 or negative) is taken as 1. */
public PtrVec *PtrVecNew(I64 size = 32);
/* How many values fit before the next push has to grow the storage. */
public U64 PtrVecCapacity(PtrVec *vec);
/* Append `value`, growing the storage (doubling it) when needed. */
public U0 PtrVecPush(PtrVec *vec, U0 *value);
/* Remove and return the last entry. When empty, returns NULL and sets
 * *_ok to FALSE; `_ok` may be NULL if you don't need to tell (but a
 * stored NULL then looks like an empty vector). */
public U0 *PtrVecPop(PtrVec *vec, Bool *_ok = NULL);
/* The entry at `idx`. An index outside [0, size) prints
 * "PtrVecGet: index N out of range (size M)" on stderr and exits with 1. */
public U0 *PtrVecGet(PtrVec *vec, I64 idx);
/* Replace the entry at `idx`; out of range prints an error and exits,
 * like PtrVecGet. The old value is not freed. */
public U0 PtrVecSet(PtrVec *vec, I64 idx, U0 *value);
/* The last entry without removing it; NULL and *_ok = FALSE when empty. */
public U0 *PtrVecLast(PtrVec *vec, Bool *_ok = NULL);
/* Set the size to 0; the storage is kept for reuse, the values are not
 * freed. */
public U0 PtrVecClear(PtrVec *vec);
/* Free the storage and the vector, first calling `_free_value` on every
 * value if it is given (e.g. `&Free`). NULL is ignored. */
public U0 PtrVecRelease(PtrVec *vec, U0 (*_free_value)(U0 *_val) = NULL);
/* Sort in place with `_compare_fn(a, b)` returning TRUE when `a` comes
 * before `b` (a "less than", not a C-style -1/0/1 comparator). Not
 * stable; O(n log n). */
public U0 PtrVecSort(PtrVec *vec,
                     I64 (*_compare_fn)(U0 *_arg1, U0 *_arg2));

/* An IntMap entry, as IntMapIter hands it out: `key` and `value` are the
 * caller's; `order` is the map's bookkeeping. */
public class IntMapNode
{
  I64 key;
  U0 *value;
  I64 order; /* Position in the map's `indexes`; HT_DELETED once deleted */
};

/* A StrMap entry, as StrMapIter hands it out: `key` is the pointer the map
 * stores (not a copy), `key_len` its StrLen. */
public class StrMapNode
{
  U8 *key;
  I64 key_len;
  U0 *value;
  I64 order; /* Position in the map's `indexes`; HT_DELETED once deleted */
};

/* A hash table from I64 keys to U0 * values. `size` is the number of
 * entries; `capacity` the number of slots (a power of two), which grows
 * when the entries and deleted holes reach 60% of it and never shrinks.
 * The other fields are internal. */
public class IntMap
{
  U64 size;     /* How many entries are in the hashtable */
  U64 capacity; /* How many slots the entries array has, a power of 2 */
  U64 mask;     /* capacity - 1: `hash & mask` is the home slot */
  IntVec *indexes; /* The slot of every entry, in insertion order, with
                    * HT_DELETED for deleted ones: iteration walks this */
  U64 threashold; /* Rebuild when `indexes` reaches this (60% of capacity) */
  U0 (*_free_value)(U0 *value); /* User defined callback for freeing values */
  IntMapNode **entries; /* The slots */
};

/* A hash table from NUL-terminated strings to U0 * values; see IntMap for
 * the fields. The map stores the key pointers it is given, it does not
 * copy them. */
public class StrMap
{
  U64 size;     /* How many entries are in the hashtable */
  U64 capacity; /* How many slots the entries array has, a power of 2 */
  U64 mask;     /* capacity - 1: `hash & mask` is the home slot */
  IntVec *indexes; /* The slot of every entry, in insertion order, with
                    * HT_DELETED for deleted ones: iteration walks this */
  U64 threashold; /* Rebuild when `indexes` reaches this (60% of capacity) */
  U0 (*_free_value)(U0 *_value); /* User defined callback for freeing values */
  U0 (*_free_key)(U0 *_key); /* User defined callback for freeing keys */
  StrMapNode **entries; /* The slots */
};

/* A new, empty map with room for `capacity` slots: rounded up to a power
 * of two, at least 8; a negative request gets 8 and one above 2^28 slots
 * gets 2^28 (the map still grows past it). NULL when out of memory. */
public StrMap *StrMapNew(U64 capacity = 32);
/* Map `key` to `value`; TRUE, or FALSE when out of memory or `map` or
 * `key` is NULL. A new key's pointer is stored, not copied, so it must
 * live as long as the map. Setting a key that is there replaces the
 * value and keeps the stored key: with destructors registered, the
 * replaced value is freed and so is the key you passed (unless it is the
 * stored key or the new value). */
public Bool StrMapSet(StrMap *map, U8 *key, U0 *value);
/* TRUE when the `key_len` bytes at `key` are a key of the map (`key` need
 * not be NUL-terminated there) */
public Bool StrMapHasLen(StrMap *map, U8 *key, I64 key_len);
/* TRUE when `key` is in the map; FALSE also for a NULL map or key */
public Bool StrMapHas(StrMap *map, U8 *key);
/* StrMapGet for the `key_len` bytes at `key` */
public U0 *StrMapGetLen(StrMap *map, U8 *key, I64 key_len, Bool *_ok = NULL);
/* The value of `key`, or NULL when it is missing. A stored NULL also gives
 * NULL: pass `_ok`, set to TRUE when the key is there, to tell them
 * apart. */
public U0 *StrMapGet(StrMap *map, U8 *key, Bool *_ok = NULL);
/* Register a destructor for values, run when a value is replaced, deleted,
 * cleared or released */
public U0 StrMapSetFreeValue(StrMap *map, U0 (*_free_value)(U0 *value));
/* Register a destructor for keys, run when a key is deleted, cleared or
 * released, and on a duplicate key passed to StrMapSet. A pointer that is
 * both a key and its value is freed once. */
public U0 StrMapSetFreeKey(StrMap *map, U0 (*_free_key)(U0 *key));
/* Free the map, running the destructors on every entry. NULL is a no-op. */
public U0 StrMapRelease(StrMap *map);
/* Double the capacity; FALSE when out of memory. The map grows by itself;
 * this is for presizing. */
public Bool StrMapResize(StrMap *map);
/* Remove `key`, running the destructors on its key and value; FALSE when
 * it was not there. Safe while iterating. */
public Bool StrMapDelete(StrMap *map, U8 *key);
/* Remove every entry, running the destructors; the capacity is kept */
public U0 StrMapClear(StrMap *map);
/* The next entry in insertion order: start with `*_idx = 0` and call until
 * FALSE; `*_idx` is an opaque cursor. Deleting entries while iterating is
 * fine; adding them is not (an added entry may be skipped or the table
 * rebuilt). */
public Bool StrMapIter(StrMap *map, I64 *_idx, StrMapNode **_node);
/* StrMapIter giving only the values */
public Bool StrMapValueIter(StrMap *map, I64 *_idx, U0 **_value);
/* StrMapIter giving only the keys */
public Bool StrMapKeyIter(StrMap *map, I64 *_idx, U8 **_key);
/* `{[key] => value, ...}` in insertion order, each value turned into a
 * string by `stringify_value` (whose result is freed); free the result */
public U8 *StrMapToString(StrMap *map, U8 *(*stringify_value)(U0 *));
/* `{key, ...}` in insertion order; free the result */
public U8 *StrMapKeysToString(StrMap *map);


/* Map `key` to `value`; TRUE, or FALSE when out of memory or `map` is
 * NULL. Setting a key that is there replaces the value, freeing the old
 * one if a destructor is registered. */
public Bool IntMapSet(IntMap *map, I64 key, U0 *value);
/* TRUE when `key` is in the map; FALSE also for a NULL map */
public Bool IntMapHas(IntMap *map, I64 key);
/* The value of `key`, or NULL when it is missing. A stored NULL or 0 also
 * gives NULL: pass `_ok`, set to TRUE when the key is there, to tell them
 * apart. */
public U0 *IntMapGet(IntMap *map, I64 key, Bool *_ok = NULL);
/* A new, empty map; the capacity as for StrMapNew. NULL when out of
 * memory. */
public IntMap *IntMapNew(U64 capacity = 32);
/* Register a destructor for values, run when a value is replaced, deleted,
 * cleared or released */
public U0 IntMapSetFreeValue(IntMap *map, U0 (*_free_value)(U0 *value));
/* Free the map, running the value destructor on every entry. NULL is a
 * no-op. */
public U0 IntMapRelease(IntMap *map);
/* Double the capacity; FALSE when out of memory. The map grows by itself;
 * this is for presizing. */
public Bool IntMapResize(IntMap *map);
/* Remove `key`, running the value destructor; FALSE when it was not
 * there. Safe while iterating. */
public Bool IntMapDelete(IntMap *map, I64 key);
/* Remove every entry, running the value destructor; the capacity is
 * kept */
public U0 IntMapClear(IntMap *map);
/* The next entry in insertion order: start with `*_idx = 0` and call until
 * FALSE; `*_idx` is an opaque cursor. Deleting entries while iterating is
 * fine; adding them is not. */
public Bool IntMapIter(IntMap *map, I64 *_idx, IntMapNode **_node);
/* IntMapIter giving only the values */
public Bool IntMapValueIter(IntMap *map, I64 *_idx, U0 **_value);
/* IntMapIter giving only the keys */
public Bool IntMapKeyIter(IntMap *map, I64 *_idx, I64 *_key);
/* `{[key] => value, ...}` in insertion order, each value turned into a
 * string by `stringify_value` (whose result is freed); free the result */
public U8 *IntMapToString(IntMap *map, U8 *(*stringify_value)(U0 *));
/* `{key, ...}` in insertion order; free the result */
public U8 *IntMapKeysToString(IntMap *map);

/* THREADS ==========*/
#ifdef IS_MACOS
#define __MUTEX_LOCK_PADDING__   56
#define __MUTEX_LOCK_ATTR_SIZE__ 8

#define __THREAD_COND_SIZE__     40
#define __THREAD_CONDATTR_SIZE__ 8
#define __THREAD_SIZE__          8176
#define __THREAD_ATTR_SIZE__     56

/* MACOS definitions */
class pthread_mutex_t 
{
  I64 __sig;
  I8 __opaque[__MUTEX_LOCK_PADDING__];
};

class pthread_mutexattr_t
{
  I64 __sig;
  I8 __opaque[__MUTEX_LOCK_ATTR_SIZE__];
};

class pthread_cond_t
{
  I64 __sig;
  I8 __opaque[__THREAD_COND_SIZE__];
};

class pthread_condattr_t
{
  I64 __sig;
  I8 __opaque[__THREAD_CONDATTR_SIZE__];
};

class pthread_handler_rec;
class pthread_handler_rec
{
  U0 (*__routine)(U0 *__arg); // Routine to call
  U0 *__arg;                  // Argument to pass
  pthread_handler_rec *__next;
};

class pthread_attr_t
{  
  I64 __sig;
  I8 __opaque[__THREAD_ATTR_SIZE__];
};

class pthread_t 
{
  I64 __sig;
  pthread_handler_rec  *__cleanup_stack;
  I8 __opaque[__THREAD_SIZE__];
};

#elifdef IS_LINUX /* Linux definitions, this needs to be auto generated */

#define __SIZEOF_PTHREAD_MUTEX_T   40
#define __SIZEOF_PTHREAD_ATTR_T    56
#define __SIZEOF_PTHREAD_RWLOCK_T  56
#define __SIZEOF_PTHREAD_BARRIER_T 32

#define __SIZEOF_PTHREAD_MUTEXATTR_T   4
#define __SIZEOF_PTHREAD_COND_T        48
#define __SIZEOF_PTHREAD_CONDATTR_T    4
#define __SIZEOF_PTHREAD_RWLOCKATTR_T  8
#define __SIZEOF_PTHREAD_BARRIERATTR_T 4

union pthread_mutexattr_t
{
  I8  __size[__SIZEOF_PTHREAD_MUTEXATTR_T];
  I32 __align;
};

union pthread_condattr_t
{
  I8  __size[__SIZEOF_PTHREAD_CONDATTR_T];
  I32 __align;
};

union pthread_attr_t
{
  I8  __size[__SIZEOF_PTHREAD_ATTR_T];
  I64 __align;
};


/* this is the spiritual equivilent of typedef  */ 
public class pthread_t {
  U64 __padding;
};

class __pthread_list_t;
class __pthread_list_t
{
  __pthread_list_t *__prev;
  __pthread_list_t *__next;
};

class __pthread_mutex_s
{
  I32 __lock;
  U32 __count;
  I32 __owner;
  U32 __nusers;
  I32 __kind;
  I16 __spins;
  I16 __elision;
  __pthread_list_t __list;
};

union pthread_mutex_t 
{
  __pthread_mutex_s __data;
  I32 __size[__SIZEOF_PTHREAD_MUTEX_T];
  I64 __align;
};

union __atomic_wide_counter
{
  U64 __value64;
  class
  {
    U32 __low;
    U32 __high;
  };
};

class __pthread_cond_s
{
  __atomic_wide_counter __wseg;
  __atomic_wide_counter __g1_start;
  U32 __g_regs[2];
  U32 __g_size[2];
  U32 __g1_orig_size;
  U32 __wrefs;
  U32 __g_signals[2];
};

union pthread_cond_t
{
  __pthread_cond_s __data;
  I8 __size[__SIZEOF_PTHREAD_COND_T];
  I64 __align;
};
#endif

class ThreadWorker
{
  pthread_t *th;
  I32 id;
};

public class ThreadWorkerJob;
public class ThreadWorkerJob {
  U0 *(*callback)(U0 *priv_data, U0 *argv);
  U0 *argv;
  ThreadWorkerJob *next;
};

public class ThreadPool {
  U64 worker_count, alive_threads, active_threads;
  Bool run;
  pthread_cond_t has_work, no_work;
  pthread_mutex_t lock;
  ThreadWorker *workers;
  List *jobs;
  U0 *priv_data;
};

public extern "c" I64 pthread_create(pthread_t **th, U0 *thread_attr = NULL,
                U0 *(*function_ptr)(U0 *_argv), U0 *argv = NULL);
public extern "c" I32 pthread_mutex_init(pthread_mutex_t *lk,
                  pthread_mutexattr_t *mutex_attr = NULL);
public extern "c" I32 pthread_mutex_destroy(pthread_mutex_t *lk);
public extern "c" I32 pthread_mutex_lock(pthread_mutex_t *lk);
public extern "c" I32 pthread_mutex_unlock(pthread_mutex_t *lk);
public extern "c" I32 pthread_join(pthread_t *th, U0 *ptr = NULL);
public extern "c" I32 pthread_cond_broadcast(pthread_cond_t *cond);
public extern "c" I32 pthread_cond_destroy(pthread_cond_t *cond);
public extern "c" I32 pthread_cond_init(pthread_cond_t *cond, pthread_condattr_t *attr = NULL);
public extern "c" I32 pthread_cond_signal(pthread_cond_t *cond);
public extern "c" I32 pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *lk);
public extern "c" I32 pthread_exit(U0 *data = NULL);
public extern "c" I32 pthread_detach(pthread_t *th);
public extern "c" I32 pthread_attr_setstacksize(pthread_attr_t *attr, U64 stacksize);
public extern "c" I32 pthread_attr_init(pthread_attr_t *attr);

ThreadPool *ThreadPoolNew(I64 worker_count);
public U0 ThreadPoolEnqueue(ThreadPool *pool, U0 *argv,
           U0 (*callback)(U0 *priv_data, U0 *argv));
/* Block until the queue is empty and no job is running. */
public U0 ThreadPoolWait(ThreadPool *pool);
public ThreadPool *ThreadPoolNew(I64 worker_count);
/* Run every job still queued, then stop and join the workers. */
public U0 ThreadPoolStop(ThreadPool *pool);
/* ThreadPoolStop (queued jobs still run), then free the pool. NULL is ignored. */
public U0 ThreadPoolRelease(ThreadPool *pool);

public extern "c" I32 wait(I32 *statloc);
public extern "c" I32 waitpid(I32 pid, I32 *statlock, I32 options);
public extern "c" I32 fork();
#ifdef IS_X86_64
public _extern _EXIT U0 Exit(I64 exit_code = EXIT_FAIL);
#endif

#ifdef IS_ARM_64
public U0 Exit(I64 exit_code = EXIT_FAIL);
#endif

/* Run `command` with the shell (`sh -c`). Returns the command's exit
 * code (0-255), or -1 if it was killed by a signal or the shell could
 * not be run (also for a NULL command). The shell itself gives 127 for
 * a command it can't find. */
public I64 System(U8 *command);

public I64 Write(I64 fd, U8 *buf, I64 len);

/* Call the shell with `printf`-like formatting. Returns what System
 * returns: the exit code (0-255), or -1 if the command was killed by a
 * signal, could not be run, or fmt is NULL. */
public I32 Sh(U8 *fmt, ...);
public U8 *Shlurp(U8 *fmt, ...);

/* TempleOS-style try/catch/throw. CatchFrame is 256 bytes (matches
 * what the compiler reserves per `try` block); the runtime stores its
 * jmp_buf bytes plus a chain pointer inside. Fs->except_ch holds the
 * u64 thrown by the most recent `throw(...)`. */
public class CatchFrame;
public class CatchFrame
{
  I8 jb[248];
  CatchFrame *prev;
};
public class HCFs
{
  CatchFrame *catch_top;
  U64 except_ch;
};
/* `Fs` is the TempleOS-faithful global task pointer. The canonical
 * definition (and storage init) lives in libtos's except.HC; this
 * `extern` declaration tells user-side parsing that `Fs` exists
 * without emitting storage here (which would clash at link time). */
extern HCFs *Fs;
public extern "c" I32 setjmp(U0 *env);
public extern "c" U0 longjmp(U0 *env, I32 val);
public U0 HCC_PushFrame(CatchFrame *f);
public U0 HCC_TryLeave(CatchFrame *f);
public U0 HCC_Throw(U64 v);

public extern "c" F64 acos(F64 f1);
public extern "c" F64 asin(F64 f1);
public extern "c" F64 atan(F64 f1);
public extern "c" F64 atan2(F64 f1, F64 f2);
public extern "c" F64 cos(F64 f1);
public extern "c" F64 sin(F64 f1);
public extern "c" F64 tan(F64 f1);
public extern "c" F64 acosh(F64 f1);
public extern "c" F64 asinh(F64 f1);
public extern "c" F64 atanh(F64 f1);
public extern "c" F64 cosh(F64 f1);
public extern "c" F64 sinh(F64 f1);
public extern "c" F64 tanh(F64 f1);
public extern "c" F64 exp(F64 f1);
public extern "c" F64 exp2(F64 f1);
public extern "c" F64 expm1(F64 f1);
public extern "c" F64 log(F64 f1);
public extern "c" F64 log10(F64 f1);
public extern "c" F64 log2(F64 f1);
public extern "c" F64 log1p(F64 f1);
public extern "c" F64 logb(F64 f1);
public extern "c" F64 modf(F64 f1, F64 *fptr);
public extern "c" F64 ldexp(F64 f1, I32 i);
public extern "c" F64 frexp(F64 f1, I32 *i);
public extern "c" I32 ilogb(F64 f1);
public extern "c" F64 scalbn(F64 f1, I32 i);
public extern "c" F64 scalbln(F64 f1, I64 i);
public extern "c" F64 fabs(F64 f1);
public extern "c" F64 cbrt(F64 f1);
public extern "c" F64 hypot(F64 f1, F64 f2);
public extern "c" F64 pow(F64 f1, F64 f2);
public extern "c" F64 sqrt(F64 f1);
public extern "c" F64 erf(F64 f1);
public extern "c" F64 erfc(F64 f1);
public extern "c" F64 lgamma(F64 f1);
public extern "c" F64 tgamma(F64 f1);
public extern "c" F64 ceil(F64 f1);
public extern "c" F64 floor(F64 f1);
public extern "c" F64 nearbyint(F64 f1);
public extern "c" F64 rint(F64 f1);
public extern "c" I64 lrint(F64 f1);
public extern "c" F64 round(F64 f1);
public extern "c" I64 lround(F64 f1);
public extern "c" F64 trunc(F64 f1);
public extern "c" F64 fmod(F64 f1, F64 f2);
public extern "c" F64 remainder(F64 f1, F64 f2);
public extern "c" F64 remquo(F64 f1, F64 f2, I32 *ptr);
public extern "c" F64 copysign(F64 f1, F64 f2);
public extern "c" F64 nan(U8 *s);
public extern "c" F64 nextafter(F64 f1, F64 f2);
public extern "c" F64 fdim(F64 f1, F64 f2);
public extern "c" F64 fmax(F64 f1, F64 f2);
public extern "c" F64 fmin(F64 f1, F64 f2);
public extern "c" F64 fma(F64 f1, F64 f2, F64 f3);
#ifdef IS_X86_64
public _extern _ABS I64 Abs(I64 num);
#endif

#ifdef IS_ARM_64
public I64 Abs(I64 num);
#endif
public U64 Gcd(I64 a, I64 b);
public F64 Pow(F64 a, F64 b);
public U64 ModU64(U64 *k, U64 m);

public extern "c" U0 *memchr(U0 *__s, I32 __c, U64 __n);
public extern "c" I32 memcmp(U0 *__s1, U0 *__s2, U64 __n);
public extern "c" U0 *memmove(U0 *__dst, U0 *__src, U64 __len);
public extern "c" U0 free(U0 *ptr);
public extern "c" U0 *malloc(U64 size);

/* MAlloc has a hand-rolled asm trampoline (`_MALLOC`) on both arches,
 * so its binding is declared unconditionally. The remaining core memory
 * ops are asm on x86 but ordinary HolyC on ARM, so those stay split. */
public _extern _MALLOC U0 *MAlloc(U64 size);
public _extern _FREE U0 Free(U0 *ptr);
public _extern _MSIZE U64 MSize(U0 *ptr);
public _extern _MEMSET U0 *MemSet(U0 *dst, I32 ch, U64 len);
public _extern _MEMCPY U0 *MemCpy(U0 *dst, U0 *src, U64 len);
public _extern _CALLOC U0 *CAlloc(U64 new_size);
public _extern _REALLOC U0 *ReAlloc(U0 *ptr, U64 new_size);

/* The size StrPrint and MPrintQ start a new buffer at (it grows). */
#define STR_LEN 256

/* StrPrint's internal format flags; MPrintQ's `flags` takes PRTF_SLASH,
 * which doubles each '%'. */
#define PRTF_PAD_ZERO        0x001
#define PRTF_LEFT_JUSTIFY    0x002
#define PRTF_TRUNCATE        0x004
#define PRTF_SLASH           0x020
#define PRTF_DECIMAL         0x100

/* TempleOS character codes: below CH_SHIFT_SPACE is a control byte. */
#define CH_SHIFT_SPACE 0x1F
#define CH_SPACE       0x20

extern "c" F64 strtod(U8 *nptr, U8 **endptr);
extern "c" I64 strtoll(U8 *nptr, U8 **endptr, I64 base = 10);
extern "c" U64 strtoul(U8 *nptr, U8 **endptr, I64 base = 10);
extern "c" I64 snprintf(I8 *nptr, U64 len, I8 *fmt, ...);
extern "c" I64 printf(I8 *fmt, ...);
extern "c" I64 strnlen(U8 *s, I64 size);
extern "c" U8 *strcat(U8 *__s1, U8 *__s2);
extern "c" U8 *strchr(U8 *__s, I32 __c);
extern "c" I32 strcmp(U8 *__s1, U8 *__s2);
extern "c" I32 strcasecmp(U8 *__s1, U8 *__s2);
extern "c" I32 strncasecmp(U8 *__s1, U8 *__s2, U64 __n);
extern "c" I64 atol(U8 *__str);
extern "c" I32 strcoll(U8 *__s1, U8 *__s2);
extern "c" U8 *strcpy(U8 *__dst, U8 *__src);
extern "c" U64 strcspn(U8 *__s, U8 *__u8set);
extern "c" U8 *strerror(I32 __errnum);
extern "c" U64 strlen(U8 *__s);
extern "c" U8 *strncat(U8 *__s1, U8 *__s2, U64 __n);
extern "c" I32 strncmp(U8 *__s1, U8 *__s2, U64 __n);
extern "c" U8 *strncpy(U8 *__dst, U8 *__src, U64 __n);
extern "c" U8 *strpbrk(U8 *__s, U8 *__u8set);
extern "c" U8 *strrchr(U8 *__s, I32 __c);
extern "c" U8 *strdup(U8 *__s);
extern "c" U64 strspn(U8 *__s, U8 *__u8set);
extern "c" U8 *strstr(U8 *__big, U8 *__little);
extern "c" U8 *strtok(U8 *__str, U8 *__sep);
extern "c" U64 strxfrm(U8 *__s1, U8 *__s2, U64 __n);

/* Strings are NUL-terminated U8 arrays; the case functions are ASCII
 * only. Functions that return a new string (StrNew, StrPrint(NULL, ..),
 * MStrPrint, StrMerge, StrNCpy, MPrintQ, MPrintDate, ...) give you a
 * block to Free. */

/* The length of `buf` before its '\0', 0 for NULL. */
public U64 StrLen(U8 *buf);
/* Compare at most len bytes like C's strncmp: < 0, 0 or > 0, bytes compared
 * as unsigned, stopping at a NUL. NULL sorts before every string (two NULLs
 * are equal), whatever len is. */
public _extern _STRNCMP I64 StrNCmp(U8 *s1, U8 *s2, I64 len);
/* StrNCmp ignoring ASCII case, like C's strncasecmp. */
public _extern _STRNICMP I64 StrNICmp(U8 *s1, U8 *s2, I64 len);
/* Copy src and its NUL into dst, which must be big enough. A NULL src
 * copies "" and a NULL dst does nothing. */
public _extern _STRCPY U0 StrCpy(U8 *dst, U8 *src);
/* Compare like C's strcmp: < 0, 0 or > 0, bytes compared as unsigned.
 * NULL sorts before every string; two NULLs are equal. */
public _extern _STRCMP I64 StrCmp(U8 *s1, U8 *s2);

#ifdef IS_X86_64
/* ch in lower case: only 'A'-'Z' change (ASCII). */
public _extern _TOLOWER U8 ToLower(U8 ch);
/* ch in upper case: only 'a'-'z' change (ASCII). */
public _extern _TOUPPER U8 ToUpper(U8 ch);
/* TRUE for ' ', '\t', '\n', '\v', '\f' and '\r'. */
public _extern _ISSPACE Bool IsSpace(U8 ch);
/* A 64-bit hash of str's bytes: h = h * 31 + c from 0, then a final mix
 * (murmur3's), so similar keys spread over the low bits; "" hashes to 0.
 * The same value on every target. */
public _extern _STRHASH U64 StrHash(U8 *str);
#endif

#ifdef IS_ARM_64
public U8 ToLower(U8 ch);
public U8 ToUpper(U8 ch);
public Bool IsSpace(U8 ch);
public U64 StrHash(U8 *str);
#endif

/* The integer at the start of str, like C's atol: leading spaces and a
 * sign are allowed, parsing stops at the first non-digit, 0 if there is
 * none or str is NULL. */
public I64 Atoi(U8 *str);

/* A new string with at most the first len bytes of buf, stopping at its
 * NUL (like C's strndup), always NUL terminated. A negative len is 0 and a
 * NULL buf gives "". */
public U8 *StrNCpy(U8 *buf, I64 len);
/* TempleOS file names: a pointer to the first '.' that isn't followed by
 * '/' or '.' (so "archive.tar.gz" gives ".tar.gz"), or NULL. */
public U8 *FileExtDot(U8 *src);
/* Cut the extension (from FileExtDot's dot) off src, in place, and copy it
 * without the dot into dst if dst isn't NULL ("" when there is none).
 * Returns dst. */
public U8 *FileExtRem(U8 *src, U8 *dst = NULL);
/* Remove the whitespace at the start, in place (the rest moves down);
 * only the first str_len bytes are looked at (all of it if str_len < 0).
 * Sets *_new_len and returns str. NULL returns NULL. */
public U8 *StrTrimStart(U8 *str, I64 str_len=-1, I64 *_new_len=NULL);
/* Remove the whitespace at the end, in place, by writing a NUL; only the
 * first str_len bytes are looked at (all of it if str_len < 0). Sets
 * *_new_len and returns str. NULL returns NULL. */
public U8 *StrTrimEnd(U8 *str, I64 str_len=-1, I64 *_new_len=NULL);
/* Remove every character in `chars` from the end, in place, by writing a
 * NUL: StrCleanEnd(line, "\r\n") drops a line ending. Returns the new
 * length. NULL str returns 0; NULL or "" chars removes nothing. */
public I64 StrCleanEnd(U8 *str, U8 *chars);
/* TempleOS: TRUE if filename ends in ".Z" and has another '.' before it
 * ("Doc.HC.Z"); "a.Z" is FALSE. */
public Bool IsDotZ(U8 *filename);
/* TempleOS: TRUE if filename ends in ".C" and has another '.' before it. */
public Bool IsDotC(U8 *filename);
/* Internal output helper of StrPrint: write ch and a NUL at *_dst and
 * advance it, growing *_buf (MAlloc'd) when full if _buf isn't NULL. */
public U0 SPutChar(U8 **_dst, U8 ch, U8 **_buf);
/* Internal output helper of StrPrint: write instr padded to len. */
public U0 OutStr(U8 *instr, U8 **_buf, U8 **_dst, I64 len, I64 flags,
                 I64 prec = -1);
/* How many times ch occurs in src (0 for NULL). */
public I64 StrOcc(U8 *src, I64 ch);
/* A pointer to the first character of src that is one of the characters
 * in marker, or NULL (also for a NULL src or marker). */
public U8 *StrFirstOcc(U8 *src, U8 *marker);
/* A pointer to the last character of src that is in marker, or NULL. */
public U8 *StrLastOcc(U8 *src, U8 *marker);
/* Split off the part after the last marker character: it goes into dst
 * (if not NULL) and src is cut there, in place ("a/b/c" -> "a/b" and
 * "c"). Without a marker all of src moves to dst and src becomes "".
 * Returns dst. */
public U8 *StrLastRem(U8 *src, U8 *marker, U8 *dst = NULL);
/* Reverse the first length bytes of buf in place. */
public U0 StrReverse(U8 *buf, I64 length);
/* Internal helper: writes the digits of |num| into buf LEAST significant
 * first (12 -> "21"), with no sign (*_is_neg says if num < 0), and
 * returns how many. Use StrPrint for normal formatting. */
public I64 I64ToStr(U8 *buf, I64 num, Bool *_is_neg = NULL, I64 _len = 5000);
/* Internal helper: the digits of num, least significant first. */
public U64 U64ToStr(U8 *dst, U64 num, I64 len = 5000);
/* StrMerge for an argument array. */
public U8 *StrMergeJoin(I64 argc, U64 *argv);
/* A new string with all the string arguments joined: StrMerge("a", "b"). */
public U8 *StrMerge(...);
/* Format like printf (see the library guide for the conversions). With
 * dst NULL it returns a new string to Free; otherwise it writes into dst,
 * which must be big enough - nothing checks, see StrNPrint - and returns
 * it. */
public U8 *StrPrint(U8 *dst=NULL, U8 *fmt, ...);
/* Format into `dst`, which has room for `size` bytes, like C's snprintf:
 * at most size-1 characters are written, always followed by a '\0' (size
 * <= 0 writes nothing), and longer output is cut short. Returns dst.
 * StrPrint(dst, ...) has no bound, so use this for a fixed buffer. */
public U8 *StrNPrint(U8 *dst, I64 size, U8 *fmt, ...);
/* StrPrint for an argument array. */
public U8 *StrPrintJoin(U8 *_dst, U8 *fmt, I64 argc, I64 *argv);
/* A new "MM/DD/YYYY" string to Free. */
public U8 *MPrintDate(CDate cdt);
/* A new "HH:MM:SS" string to Free. */
public U8 *MPrintTime(CDate cdt);
/* A new "YYYY-MM-DD HH:MM:SS" string of the local time now, to Free. */
public U8 *MPrintTimestampNow();
/* A new copy of buf to Free; "" for NULL. */
public U8 *StrNew(U8 *buf);
/* Split off the part before the first marker character: it goes into dst
 * (if not NULL) and src keeps what follows the marker, in place ("a/b/c"
 * -> "b/c" and "a"). Returns dst. */
public U8 *StrFirstRem(U8 *src, U8 *marker, U8 *dst = NULL);
/* Write num as "0x" and 16 upper-case hex digits into dst (19 bytes with
 * the NUL); returns 18. */
public I64 StrIntToHex(U8 *dst, I64 num);
/* A new string with ptr escaped for a C string literal: \n \r \t \v \f,
 * \" and \\, other control bytes as \xNN. What %Q prints. */
public U8 *MPrintQ(U8 *ptr, I64 flags = 0);
/* StrPrint(NULL, ...) into an exactly sized new string. */
public U8 *MStrPrint(U8 *fmt, ...);
/* Append the formatted text to the heap string _dst (or start one if it
 * is NULL) and return it: write s = CatPrint(s, ...), it may move. Each
 * call measures _dst, so long loops are O(n^2): use CatLenPrint there. */
public U8 *CatPrint(U8 *_dst, U8 *fmt, ...);
/* CatPrint that keeps the length in *_len (start it at 0 with a NULL
 * _dst), so appending doesn't rescan the string. */
public U8 *CatLenPrint(U8 *_dst, I64 *_len, U8 *fmt, ...);
/* Parse strdate with a strptime-like format: %Y %m %d %H %M %s (or %S)
 * %a/%b (day/month name, full or three letters) %p %z %%. Unset date
 * fields are -1, time fields 0. FALSE for empty, short or mismatching
 * input, an unknown conversion or a field out of range. */
public Bool Str2CDateStruct(U8 *strdate, U8 *format, CDateStruct *t);
/* Glob match of all of test_str: '*' any run of characters, '?' any one.
 * FALSE if either is NULL. */
public Bool WildMatch(U8 *test_str, U8 *wild_str);
/* Str2CDateStruct into a CDate; 0 if parsing fails or the format has no
 * year, month and day. */
public CDate StrToCDate(U8 *_str, U8 *fmt);

#define F_DUPFD 0 /* Duplicate a file descriptor */
#define F_GETFD 1 /* Retrieve file descriptor flags */
#define F_SETFD 2 /* Assign flags to file descriptor */
#define F_GETFL 3 /* Get file status flags */
#define F_SETFL 4 /* Assign file status flags */

#define F_FLUSH_DATA  40 /* Commit data to disk */
#define F_CHKCLEAN    41 /* Verify file is not modified */
#define F_PREALLOCATE 42 /* Allocate space for file in advance */
#define F_SETSIZE     43 /* Adjust file size */
#define F_RDADVISE    44 /* Suggest read behavior */
#define F_RDAHEAD     45 /* Enable read ahead */

#define FD_CLOEXEC 1  /* Close file descriptor on exec */

#ifdef IS_LINUX
  #define F_GETOWN 0x9 /* Retrieve SIGIO/SIGURG process/group */
  #define F_SETOWN 0x8 /* Set SIGIO/SIGURG process/group */
  #define F_GETLK  0x5 /* Query record locking info */
  #define F_SETLK  0x6 /* Set record locking info without waiting */
  #define F_SETLKW 0x7 /* Set record locking info with waiting */
#else
  #define F_GETOWN 0x5
  #define F_SETOWN 0x6
  #define F_GETLK  0x7
  #define F_SETLK  0x8
  #define F_SETLKW 0x9
#endif

/* record locking flags */
#ifdef IS_LINUX
  #define F_RDLCK 0 /* Establish a read lock */
  #define F_WRLCK 1 /* Remove a lock */
  #define F_UNLCK 2 /* Establish a write lock */
#else
  #define F_RDLCK 1
  #define F_UNLCK 2
  #define F_WRLCK 3
#endif

#define O_RDONLY  0x0000 /* Open exclusively for reading */
#define O_WRONLY  0x0001 /* Open exclusively for writing */
#define O_RDWR    0x0002 /* Open for reading and writing */
#define O_ACCMODE 0x0003 /* Mask to extract access modes */

/* Record locking flags */
#ifdef IS_LINUX
  #define O_CREAT    0x040 /* Create file if it doesn't exist */
  #define O_TRUNC    0x200 /* Truncate existing file to zero length */
  #define O_EXCL     0x080 /* Error if file already exists */
  #define O_NONBLOCK 0x800 /* Non-blocking mode */
  #define O_APPEND   0x400 /* Append data to the end of the file */
#else
  #define O_CREAT    0x00000200
  #define O_TRUNC    0x00000400
  #define O_EXCL     0x00000800
  #define O_NONBLOCK 0x00000004
  #define O_APPEND   0x00000008
#endif

#define SEEK_SET 0 /* Set offset to specified value */
#define SEEK_CUR 1 /* Set offset to current position plus value */
#define SEEK_END 2 /* Set offset to size of file plus value */

/*
 * The iovec class represents a buffer in memory, with a base address and a length.
 * It's typically used for scatter-gather I/O operations to manage multiple buffers.
 */
class iovec
{
  U0 *iov_base;  /* Pointer to data buffer */
  U64 iov_len;   /* Length of the buffer */
};

public extern "c" I32 open(U8 *__name, I32 flags, ...);
public extern "c" I32 creat(U8 *__name, U16 __flags);
public extern "c" I32 fcntl(I32 __fd, I32 __flags, ...);
public extern "c" I32 close(I32 __fd);
public extern "c" I64 read(I32 __fd, U0 *__buf, U64 __nbyte);
public extern "c" I64 write(I32 __fd, U0 *__buf, U64 __nbyte);
public extern "c" I64 lseek(I32 __fd, I64 __offset, I32 __whence);
public extern "c" I32 chdir(U8 *path);

public U8 *FileRead(U8 *path, I64 *_size = NULL);
public Bool FileWrite(U8 *filename, U8 *buf, I64 size, I64 flags = O_CREAT | O_RDWR);
public I32 Cd(U8 *path);

#define DT_UNKNOWN 0  /* Type not determined */
#define DT_FIFO    1  /* FIFO/pipe */
#define DT_CHR     2  /* Character device */
#define DT_DIR     4  /* Directory */
#define DT_BLK     6  /* Block device */
#define DT_REG     8  /* Regular file */
#define DT_LNK    10  /* Symbolic link */
#define DT_SOCK   12  /* Socket */
#define DT_WHT    14  /* Whiteout */

class cDIR;

#ifdef IS_MACOS
#define DIR_MAXPATHLEN (1024)
class Dirent
{
  U64 ino;
  U64 off;
  U16 reclen;        /* length of this record */
  U16 namlen;        /* length of string in d_name */
  U8 type;         /* file type, see below */
  I8 name[DIR_MAXPATHLEN]; /* entry name (up to MAXPATHLEN bytes) */
};
#endif

#ifdef IS_LINUX
#define DIR_MAXPATHLEN (256)
class Dirent {
  U64 ino;         /* file number of entry */
  U64 seekoff;       /* seek offset (optional, used by servers) */
  U16 reclen;        /* length of this record */
  U8 type;         /* file type, see below */
  I8 name[DIR_MAXPATHLEN]; /* entry name (up to MAXPATHLEN bytes) */
};
public cDIR *opendir(U8 *dirname);
public Dirent *readdir(cDIR *dir);
#endif

/* Mac x86 vs ARM symbol-name divergence -- see dir.HC. */
#ifdef IS_X86_64
public _extern _opendir$INODE64 cDIR *opendir(U8 *dirname);
public _extern _readdir$INODE64 Dirent *readdir(cDIR *dir);
#endif

#ifdef IS_ARM_64
public _extern _opendir cDIR *opendir(U8 *dirname);
public _extern _readdir Dirent *readdir(cDIR *dir);
#endif

public extern "c" I32 closedir(cDIR *dir);
public extern "c" U0 rewinddir(cDIR *dir);
public extern "c" U0 seekdir(cDIR *dir, I64 pos);
public extern "c" I64 telldir(cDIR *dir);

#ifdef IS_MACOS
public class cStat {
  I32 st_dev;
  U16 st_mode;
  U16 st_nlink;
  U64 st_ino;
  U32 st_uid;
  U32 st_gid;
  I32 st_rdev;
  cTimespec st_atimespec;
  cTimespec st_mtimespec;
  cTimespec st_ctimespec;
  cTimespec st_birthtimespec;
  I64 st_size;
  I64 st_blocks;
  I32 st_blksize;
  U32 st_flags;
  U32 st_gen;
  I32 st_lspare;
  I64 st_qspare[2];
};
#elifdef IS_LINUX
class cStat
{
  U64 st_dev;
  U64 st_ino;
  U64 st_nlink;
  U32 st_mode;
  U32 st_uid;
  U32 st_gid;
  I32 __pad0;
  U64 st_rdev;
  I64 st_size;
  I64 st_blksize;
  I64 st_blocks;
  cTimespec st_atim;
  cTimespec st_mtim;
  cTimespec st_ctim;
  I64 __glibc_reserved[3];
};

class statx_timestamp
{
  I64  tv_sec;
  U32  tv_nsec;
  I32  __reserved;
};

class Statx
{
  U32 stx_mask;
  U32 stx_blksize;
  U64 stx_attributes;
  U32 stx_nlink;
  U32 stx_uid;
  U32 stx_gid;
  U16 stx_mode;
  U16 __spare0[1];
  U64 stx_ino;
  U64 stx_size;
  U64 stx_blocks;
  U64 stx_attributes_mask;
  statx_timestamp  stx_atime;
  statx_timestamp  stx_btime;
  statx_timestamp  stx_ctime;
  statx_timestamp  stx_mtime;
  U32 stx_rdev_major;
  U32 stx_rdev_minor;
  U32 stx_dev_major;
  U32 stx_dev_minor;
  U64 stx_mnt_id;
  U32 stx_dio_mem_align;
  U32 stx_dio_offset_align;
  U64 stx_subvol;
  U32 stx_atomic_write_unit_min;
  U32 stx_atomic_write_unit_max;
  U32 stx_atomic_write_segments_max;
  U32 stx_dio_read_offset_align;
  U32 stx_atomic_write_unit_max_opt;
  U32 __spare2[1];
  U64 __spare3[8];
};

#define STATX_TYPE           0x00000001
#define STATX_MODE           0x00000002
#define STATX_NLINK          0x00000004
#define STATX_UID            0x00000008
#define STATX_GID            0x00000010
#define STATX_ATIME          0x00000020
#define STATX_MTIME          0x00000040
#define STATX_CTIME          0x00000080
#define STATX_INO            0x00000100
#define STATX_SIZE           0x00000200
#define STATX_BLOCKS         0x00000400
#define STATX_BASIC_STATS    0x000007ff
#define STATX_BTIME          0x00000800
#define STATX_MNT_ID         0x00001000
#define STATX_DIOALIGN       0x00002000
#define STATX_MNT_ID_UNIQUE  0x00004000
#define STATX_SUBVOL         0x00008000
#define STATX_WRITE_ATOMIC   0x00010000
#define STATX_DIO_READ_ALIGN 0x00020000

#define STATX__RESERVED             0x80000000
#define STATX_ALL                   0x00000fff
#define STATX_ATTR_COMPRESSED       0x00000004
#define STATX_ATTR_IMMUTABLE        0x00000010
#define STATX_ATTR_APPEND           0x00000020
#define STATX_ATTR_NODUMP           0x00000040
#define STATX_ATTR_ENCRYPTED        0x00000800
#define STATX_ATTR_AUTOMOUNT        0x00001000
#define STATX_ATTR_MOUNT_ROOT       0x00002000
#define STATX_ATTR_VERITY           0x00100000
#define STATX_ATTR_DAX              0x00200000
#define STATX_ATTR_WRITE_ATOMIC     0x00400000
#define STAT_X_AT_FDCWD       -100
#define AT_STATX_SYNC_AS_STAT 0x0000
#define STATX_BTIME           0x00000800

public extern "c" I32 statx(I32 __dirfd,
                            I8 *__path,
                            I32 __flags,
                            U32 __mask,
                            Statx *stx);
public extern "c" I32 stat(U8 *pathname, cStat *st);
public extern "c" I32 lstat(U8 *pathname, cStat *st);
public extern "c" I32 fstat(I32 fd, cStat *st);
#endif

/* Mac x86 uses the $INODE64 stat variants; ARM uses the plain
 * symbols. Linux is handled above with `extern "c"`. */
#ifdef IS_X86_64
public _extern _stat$INODE64 I32 stat(U8 *pathname, cStat *st);
public _extern _lstat$INODE64 I32 lstat(U8 *pathname, cStat *st);
public _extern _fstat$INODE64 I32 fstat(I32 fd, cStat *st);
#endif

#ifdef IS_ARM_64
public _extern _stat I32 stat(U8 *pathname, cStat *st);
public _extern _lstat I32 lstat(U8 *pathname, cStat *st);
public _extern _fstat I32 fstat(I32 fd, cStat *st);
#endif

/* Portable (across MacOS and Linux) stat structure */
class Fstat
{
  U64 st_dev;
  U64 st_ino;
  U64 st_nlink;
  U32 st_mode;
  U32 st_uid;
  U32 st_gid;
  U64 st_rdev;
  I64 st_size;
  I64 st_blksize;
  I64 st_blocks;
  cTimespec st_atim;
  cTimespec st_mtim;
  cTimespec st_ctim;
  cTimespec st_btim;
};

public I32 Stat(Fstat *fst, U8 *pathname);
public I64 Dir(U8 *pathname = "./");
public U8 *Pwd(U8 *buf=NULL, U64 buf_size=0);

public extern "c" I32 mkdir(U8 *dirname, I32 mode = 438);
public extern "c" I32 unlink(U8 *pathname);
public extern "c" I32 rmdir(U8 *dirname);

#define S_IFMT      0xF000  /* Bit mask for the file type bit fields */
#define S_IFIFO     0x1000  /* FIFO or pipe */
#define S_IFCHR     0x2000  /* Character device */
#define S_IFDIR     0x4000  /* Directory */
#define S_IFBLK     0x6000  /* Block device */
#define S_IFREG     0x8000  /* Regular file */
#define S_IFLNK     0xA000  /* Symbolic link */
#define S_IFSOCK    0xC000  /* Socket */

#define S_IRWXU 0x1C0  /* Permission: user (owner) can read, write, execute */
#define S_IRUSR 0x100  /* Permission: user (owner) can read */
#define S_IWUSR 0x80   /* Permission: user (owner) can write */
#define S_IXUSR 0x40   /* Permission: user (owner) can execute */

/* Permissions: group can read, write, execute */
#define S_IRWXG 0x38
#define S_IRGRP 0x20   /* Permission: group can read */
#define S_IWGRP 0x10   /* Permission: group can write */
#define S_IXGRP 0x8    /* Permission: group can execute */

/* Permissions: others can read, write, execute */
#define S_IRWXO 0x7
#define S_IROTH 0x4    /* Permission: others can read */
#define S_IWOTH 0x2    /* Permission: others can write */
#define S_IXOTH 0x1    /* Permission: others can execute */

#define S_ISUID 0x800  /* Set user ID on execution */
#define S_ISGID 0x400  /* Set group ID on execution */
#define S_ISVTX 0x200  /* Save swapped text after use (sticky) */
#define MKDIR_DEFAULT (S_ISUID|S_IRWXU|S_IRWXG|S_IROTH|S_IXOTH) /* Default mkdir permission */

#define RM_RECURSE  0x1  /* Remove directories and their contents recursively */
#define RM_VERBOSE  0x2  /* Verbosely list files processed */
#define RM_FORCE    0x4  /* Force removal, ignore nonexistent files and arguments */

public I32 RmDir(U8 *path, Bool flags=0);
public I32 Rm(U8 *path, Bool flags=0);
public Bool MkDir(U8 *path, I32 mode=MKDIR_DEFAULT, Bool recurse=FALSE);

#define FZF_CASE_SMART   0
#define FZF_CASE_IGNORE  1
#define FZF_CASE_RESPECT 2

public class FzFPosition
{
  I64 *data;
  I64 size;
  I64 cap;
  I64 score;
};

public FzFPosition *FzF(U8 *text, U8 *pattern,I32 case_mode=FZF_CASE_SMART,
    Bool fuzzy=TRUE);
public U0 FzFPositionRelease(FzFPosition *pos);

/* JsonParse flags: none, or keep numbers as their text (JSON_STRNUM) */
#define JSON_NO_FLAGS    (0x0)
#define JSON_STRNUM_FLAG (0x1)

/* Json node types: string (str, str_len), float (f64), integer (i64),
 * number kept as text (strnum, with JSON_STRNUM_FLAG), array (array: the
 * first item, NULL when empty), object (object: the first member, NULL
 * when empty), boolean (boolean), null. */
#define JSON_STRING 0
#define JSON_FLOAT  1
#define JSON_INT    2
#define JSON_STRNUM 3
#define JSON_ARRAY  4
#define JSON_OBJECT 5
#define JSON_BOOL   6
#define JSON_NULL   7

/* Only on the root JsonParse returns: the error code, the byte offset,
 * line and column where it was found, and the character there. */
class JsonState
{
  U8 ch;
  I64 offset;
  I64 error;
  I64 line;   /* 1-based line and byte column of `offset` */
  I64 col;
};

public class Json;
/* A JSON value. `type` says which union member holds it; `key` is set on
 * an object's members; `next` is the following item or member. Only the
 * root (what JsonParse returns) has `state`. */
class Json
{
  JsonState *state;
  Json *next;
  I64 type;
  U8 *key;
  union
  {
    Json *array;
    Json *object;
    U8 *str;
    Bool boolean;
    U8 *strnum;
    F64 f64;
    I64 i64;
  };
  /* Bytes in `str` (a JSON_STRING) and in `key`, before their '\0': a
   * string can hold \u0000, which the '\0' termination would cut off.
   * Set them when you change `str` or `key` (0 means "up to the '\0'").
   * JsonSelect matches keys up to their first '\0'. */
  I64 str_len;
  I64 key_len;
};
/* JsonParse error codes (state->error). Not produced any more, kept for
 * old code: 1, 6, 7, 9, 10, 11 and 17 (the end of the input is reported
 * as 8, or as the error of what was being read). */
#define JSON_OK 0
/* Not produced */
#define JSON_INVALID_UTF16 1
/* A \u escape with an unpaired or invalid surrogate */
#define JSON_INVALID_UTF16_SURROGATE 2
/* \u not followed by 4 hex digits */
#define JSON_INVALID_HEX 3
/* A string with no closing quote */
#define JSON_INVALID_STRING_NOT_TERMINATED 4
/* A malformed number (01, +1, .5, 1., 1e, -) */
#define JSON_INVALID_NUMBER 5
/* Not produced */
#define JSON_INVALID_DECIMAL 6
/* Not produced */
#define JSON_INVALID_SIGN 7
/* No value where one was expected, an unexpected character after a
 * value (also after the top-level one), or the input ended early */
#define JSON_INVALID_JSON_TYPE_CHAR 8
/* Not produced (see JSON_INVALID_LITERAL) */
#define JSON_INVALID_BOOL 9
/* Not produced */
#define JSON_INVALID_TYPE 10
/* Not produced */
#define JSON_CANNOT_ADVANCE 11
/* Empty input, or it doesn't start with a JSON value */
#define JSON_CANNOT_START_PARSE 12
/* An object member that doesn't start with a '"' key */
#define JSON_INVALID_KEY_TERMINATOR_CHARACTER 13
/* Something other than whitespace between a key and ':' */
#define JSON_INVALID_KEY_VALUE_SEPARATOR 14
/* Something other than ',' or ']' after an array item */
#define JSON_INVALID_ARRAY_CHARACTER 15
/* An unknown escape such as \q in a string */
#define JSON_INVALID_ESCAPE_CHARACTER 16
/* Not produced */
#define JSON_EOF 17
/* Not true, false or null where a literal starts */
#define JSON_INVALID_LITERAL 18
/* A raw byte below 0x20 inside a string (write \n, \t, \u0001 ...) */
#define JSON_INVALID_CONTROL_CHARACTER 19
/* Arrays/objects nested deeper than JSON_MAX_DEPTH */
#define JSON_NESTING_TOO_DEEP 20

/* JsonParse rejects arrays and objects nested deeper than this */
#define JSON_MAX_DEPTH 512

/* Raw string, with option length of the string and 
 * flags */
/* Parse `len` bytes of `raw` (-1: up to the NUL) into a tree of Json
 * nodes; the text must be exactly one JSON value (RFC 8259), with only
 * whitespace around it. `flags` is JSON_NO_FLAGS or JSON_STRNUM_FLAG,
 * which keeps numbers as the text they were written as. Always returns a
 * root: check JsonOk, then free it with JsonRelease. */
public Json *JsonParse(U8 *raw, I64 len=-1, I64 flags=0);
/* TRUE if j is a root that parsed without error. */
public Bool JsonOk(Json *j);
/* Free a whole document. Only a root does anything: NULL and inner nodes
 * (from JsonSelect, the getters or ->next) are views and are ignored. */
public U0 JsonRelease(Json *J);
/* The JSON text of json's value only (not its key or the nodes after it);
 * a new string to Free. Members are written "key": value, separated by
 * ',' with no space. The output parses back to the same values. */
public U8 *JsonToString(Json *json);
/* A new string describing the parse error, ending "at line L, column C",
 * to Free; NULL on success and for NULL or an inner node. */
public U8 *JsonGetStrerror(Json *json);
/* Print JsonGetStrerror's message (or "No errors"); nothing for NULL or
 * an inner node. */
public U0 JsonPrintError(Json *J);
/* TRUE if j is an object; FALSE for NULL. */
public Bool JsonIsObject(Json *j);
/* TRUE if j is an array; FALSE for NULL. */
public Bool JsonIsArray(Json *j);
/* TRUE if j is a null; FALSE for NULL. */
public Bool JsonIsNull(Json *j);
/* TRUE if j is a boolean; FALSE for NULL. */
public Bool JsonIsBool(Json *j);
/* TRUE if j is a string; FALSE for NULL. */
public Bool JsonIsString(Json *j);
/* TRUE if j is an integer (JSON_INT); FALSE for NULL. */
public Bool JsonIsInt(Json *j);
/* TRUE if j is a float (JSON_FLOAT); FALSE for NULL. */
public Bool JsonIsFloat(Json *j);
/* Walk a path from j: ".key" (first match), "[n]", and ":t" to check the
 * type (s string, i int, f float, a array, o object, b bool, ! null).
 * A '*' takes the next argument: an I64 inside [], a U8 * after '.'.
 * Each part is at most 256 bytes; keys containing . [ ] : * need
 * JsonObjectGet. NULL if anything doesn't match or the path is malformed.
 * The result is a view into the document. */
public Json *JsonSelect(Json *j, U8 *fmt, ...);
/* The value stored under exactly `key` (the first if it is repeated), or
 * NULL if obj isn't an object or has no such key; works for any key,
 * including ones JsonSelect can't spell. A view into the document. */
public Json *JsonObjectGet(Json *obj, U8 *key);
/* Item i (from 0) of an array, or NULL if arr isn't an array or i is out
 * of range (negative included). A view into the document. */
public Json *JsonArrayGet(Json *arr, I64 i);
/* The number of items of an array or object; 0 for any other node or NULL. */
public I64 JsonLen(Json *node);

#ifdef __HCC_LINK_SQLITE3__ 

#define SQLITE_OK           0   /* Successful result */
/* beginning-of-error-codes */
#define SQLITE_ERROR        1   /* Generic error */
#define SQLITE_INTERNAL     2   /* Internal logic error in SQLite */
#define SQLITE_PERM         3   /* Access permission denied */
#define SQLITE_ABORT        4   /* Callback routine requested an abort */
#define SQLITE_BUSY         5   /* The database file is locked */
#define SQLITE_LOCKED       6   /* A table in the database is locked */
#define SQLITE_NOMEM        7   /* A malloc() failed */
#define SQLITE_READONLY     8   /* Attempt to write a readonly database */
#define SQLITE_INTERRUPT    9   /* Operation terminated by sqlite3_interrupt()*/
#define SQLITE_IOERR       10   /* Some kind of disk I/O error occurred */
#define SQLITE_CORRUPT     11   /* The database disk image is malformed */
#define SQLITE_NOTFOUND    12   /* Unknown opcode in sqlite3_file_control() */
#define SQLITE_FULL        13   /* Insertion failed because database is full */
#define SQLITE_CANTOPEN    14   /* Unable to open the database file */
#define SQLITE_PROTOCOL    15   /* Database lock protocol error */
#define SQLITE_EMPTY       16   /* Internal use only */
#define SQLITE_SCHEMA      17   /* The database schema changed */
#define SQLITE_TOOBIG      18   /* String or BLOB exceeds size limit */
#define SQLITE_CONSTRAINT  19   /* Abort due to constraint violation */
#define SQLITE_MISMATCH    20   /* Data type mismatch */
#define SQLITE_MISUSE      21   /* Library used incorrectly */
#define SQLITE_NOLFS       22   /* Uses OS features not supported on host */
#define SQLITE_AUTH        23   /* Authorization denied */
#define SQLITE_FORMAT      24   /* Not used */
#define SQLITE_RANGE       25   /* 2nd parameter to sqlite3_bind out of range */
#define SQLITE_NOTADB      26   /* File opened that is not a database file */
#define SQLITE_NOTICE      27   /* Notifications from sqlite3_log() */
#define SQLITE_WARNING     28   /* Warnings from sqlite3_log() */
#define SQLITE_ROW         100  /* sqlite3_step() has another row ready */
#define SQLITE_DONE        101  /* sqlite3_step() has finished executing */

#define SQLITE_INTEGER  1
#define SQLITE_FLOAT    2
#define SQLITE_BLOB     4
#define SQLITE_NULL     5
#define SQLITE_TEXT     3
#define SQLITE3_TEXT    3

class sqlite3_stmt {};
class sqlite3 {};
class sqlite3_value {};

class SqlParam
{
  I64 type;
  union 
  {
    I64 i64;
    F64 f64;
    U8 *str;
    class 
    {
      U0 *blob;
      I64 blob_len;
    };
  };
};

class SqlPreparedStmt
{
  sqlite3_stmt *stmt;
  I64  params_count;
  I64 *params_type;
};

class SqlColumn
{
  I64 len;
  I64 type;
  union
  {
    I64 i64;
    U8 *str;
    U0 *blob;
    F64 f64;
  };
};

class SqlRow
{
  sqlite3_stmt *stmt;
  I64 cols;
  SqlColumn *col;
};

class SqlCtx
{
  sqlite3 *conn;
  U8 *dbname;
};

public extern "c" I32 sqlite3_prepare_v2(
  sqlite3 *db,            /* Database handle */
  U8 *zSql,               /* SQL statement, UTF-8 encoded */
  I32 nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  U8 **pzTail             /* OUT: Pointer to unused portion of zSql */
);
public extern "c" I32 sqlite3_bind_parameter_count(sqlite3_stmt *stmt);
public extern "c" I32 sqlite3_close(sqlite3 *db);
public extern "c" I32 sqlite3_clear_bindings(sqlite3_stmt *stmt);
public extern "c" I32 sqlite3_reset(sqlite3_stmt *pStmt);
public extern "c" I32 sqlite3_finalize(sqlite3_stmt *pStmt);
public extern "c" I32 sqlite3_exec(
  sqlite3 *db,                               /* An open database */
  U8 *sql,                                  /* SQL to be evaluated */
  I32 (*callback)(U0 *_priv, I32 argc, U8 **ptr, U8 **ptr2),  /* Callback function */
  U8 *priv,                                    /* 1st argument to callback */
  U8 **errmsg                              /* Error msg written here */
);
public extern "c" I32 sqlite3_bind_blob(sqlite3_stmt *stmt, I32 __i, U0 *__ptr, I32 n,
    U0 *(*_bind)(U0 *param));
public extern "c" I32 sqlite3_bind_blob64(sqlite3_stmt *stmt, I32 __i, U0 *__ptr, I64 __i2,
    U0 *(*_bind)(U0 *param));
public extern "c" I32 sqlite3_bind_double(sqlite3_stmt *stmt, I32 __i, F64 __f64);
public extern "c" I32 sqlite3_bind_int(sqlite3_stmt *stmt, I32 __i, I32 __int);
public extern "c" I32 sqlite3_bind_int64(sqlite3_stmt *stmt, I32 __i, I64 __int64);
public extern "c" I32 sqlite3_bind_null(sqlite3_stmt *stmt, I32 __i);
public extern "c" I32 sqlite3_bind_text(sqlite3_stmt *stmt, I32 __i, U8 *__buf, I32 __i2, 
    U0 *(*_bind)(U0 *param));
public extern "c" I32 sqlite3_bind_text16(sqlite3_stmt *stmt, I32 __i, U0 *__buf, I32 __i2, 
    U0 *(*_bind)(U0 *param));
public extern "c" I32 sqlite3_bind_text64(sqlite3_stmt *stmt, I32 __i, U8 *__buf, I64 __int64,
    U0 *(*_bind)(U0 *param), U8 encoding);
public extern "c" I32 sqlite3_bind_value(sqlite3_stmt *stmt, I32 __i, sqlite3_value *__val);

public extern "c" I32 sqlite3_step(sqlite3_stmt *stmt);
public extern "c" I32 sqlite3_data_count(sqlite3_stmt *pStmt);

public extern "c" I32 sqlite3_column_bytes(sqlite3_stmt *stmt, I32 iCol);
public extern "c" U0 *sqlite3_column_blob(sqlite3_stmt *stmt, I32 iCol);
public extern "c" F64 sqlite3_column_double(sqlite3_stmt *stmt, I32 iCol);
public extern "c" I32 sqlite3_column_int(sqlite3_stmt *stmt, I32 iCol);
public extern "c" I64 sqlite3_column_int64(sqlite3_stmt *stmt, I32 iCol);
public extern "c" U8 *sqlite3_column_text(sqlite3_stmt *stmt, I32 iCol);
public extern "c" U0 *sqlite3_column_text16(sqlite3_stmt *stmt, I32 iCol);
public extern "c" sqlite3_value *sqlite3_column_value(sqlite3_stmt *stmt, I32 iCol);
public extern "c" I32 sqlite3_column_bytes(sqlite3_stmt *stmt, I32 iCol);
public extern "c" I32 sqlite3_column_bytes16(sqlite3_stmt *stmt, I32 iCol);
public extern "c" I32 sqlite3_column_type(sqlite3_stmt *stmt, I32 iCol);
public extern "c" Bool sqlite3_open(U8 *dbname, sqlite3 **db);
public extern "c" U8 *sqlite3_errmsg(sqlite3 *db);

public SqlCtx *SqlCtxNew(U8 *dbname, Bool printerror=FALSE);
public U0 SqlCtxRelease(SqlCtx *ctx);
public SqlPreparedStmt *SqlPrepare(SqlCtx *ctx, U8 *Sql);
public U0 SqlFinalizePrepared(SqlPreparedStmt *pstmt);
/* Unsafe */ 
public U8 *SqlExecRaw(SqlCtx *ctx, U8 *sql);
public I32 SqlExecPrepared(SqlPreparedStmt *pstmt, SqlRow *row,
    SqlParam *params);
public Bool SqlSelect(SqlCtx *ctx, SqlRow *row, U8 *sql,
    SqlParam *params=NULL, I32 param_count=0);
public Bool SqlQuery(SqlCtx *ctx, U8 *sql, SqlParam *params=NULL,
    I32 param_count=0);
public I32 SqlIter(SqlRow *row);
public I64 SqlIterPrepared(SqlRow *row);
public U0 SqlRowRelease(SqlRow *row);

#endif /* End of SQLite */

/* Socket options level */
#ifdef IS_LINUX
#define SOL_SOCKET      1               /* Socket-level options */
#else
#define SOL_SOCKET      0xffff          /* Socket-level options */
#endif

/*
 * Address families.
 */
#define AF_UNSPEC       0               /* Unspecified */
#define AF_UNIX         1               /* Local communication (unix pipes) */
#define AF_INET         2               /* Internet IPv4 */
#ifdef IS_LINUX
#define AF_INET6        10              /* Internet IPv6 */
#else
#define AF_INET6        30              /* Internet IPv6 */
#endif

/* Socket types */
#define SOCK_STREAM     1               /* Stream (connection-oriented) socket */
#define SOCK_DGRAM      2               /* Datagram (connectionless) socket */
#define SOCK_RAW        3               /* Raw protocol interface */
#define SOCK_SEQPACKET  5               /* Sequenced packet stream */

/*
 * Per-socket option flags.
 */
#ifdef IS_LINUX
#define SO_DEBUG        1               /* Enable debugging information */
#define SO_ACCEPTCONN   30              /* Socket has had listen() applied */
#define SO_REUSEADDR    2               /* Allow reuse of local addresses */
#define SO_KEEPALIVE    9               /* Keep connections active */
#define SO_DONTROUTE    5               /* Route packets through local interfaces */
#define SO_BROADCAST    6               /* Allow broadcast messages */
#define SO_LINGER       13              /* Linger on close if data is present */
#define SO_OOBINLINE    10              /* Leave out-of-band data inline */
#define SO_REUSEPORT    15              /* Allow reuse of local ports */
#define SO_TIMESTAMP    29              /* Timestamp incoming datagrams */
#else
#define SO_DEBUG        0x0001          /* Enable debugging information */
#define SO_ACCEPTCONN   0x0002          /* Socket has had listen() applied */
#define SO_REUSEADDR    0x0004          /* Allow reuse of local addresses */
#define SO_KEEPALIVE    0x0008          /* Keep connections active */
#define SO_DONTROUTE    0x0010          /* Route packets through local interfaces */
#define SO_BROADCAST    0x0020          /* Allow broadcast messages */
#define SO_LINGER       0x1080          /* Linger on close if data is present */
#define SO_OOBINLINE    0x0100          /* Leave out-of-band data inline */
#define SO_REUSEPORT    0x0200          /* Allow reuse of local ports */
#define SO_TIMESTAMP    0x0400          /* Timestamp incoming datagrams */
#define SO_TIMESTAMP_MONOTONIC  0x0800  /* Use monotonic timestamps for datagrams */
#endif

/* Protocols */
#define IPPROTO_IP              0               /* Placeholder for IP */
#define IPPROTO_ICMP            1               /* Internet Control Message Protocol */
#define IPPROTO_TCP             6               /* Transmission Control Protocol */
#define IPPROTO_UDP             17              /* User Datagram Protocol */
#define IPPROTO_IPV6            41              /* IPv6 protocol */
#define IPPROTO_ICMPV6          58              /* ICMP for IPv6 */
#define IPPROTO_RAW             255             /* Raw IP packets */

/* TCP options */
#ifdef IS_LINUX
#define TCP_NODELAY             1       /* Disable Nagle's algorithm */
#define TCP_MAXSEG              2       /* Set maximum segment size */
#define TCP_CORK                3       /* Don't send partial frames */
#define TCP_KEEPIDLE            4       /* Set keepalive idle time */
#define TCP_KEEPALIVE           4       /* The macOS name of TCP_KEEPIDLE */
#define TCP_KEEPINTVL           5       /* Interval between keepalives */
#define TCP_KEEPCNT             6       /* Number of keepalives before close */
#define TCP_INFO                11      /* TCP connection state info */
#define TCP_QUICKACK            12      /* Disable/enable delayed acks */
#define TCP_USER_TIMEOUT        18      /* Timeout for unacknowledged data */
#define TCP_FASTOPEN            23      /* TCP Fast Open */
#else
#define TCP_NODELAY             0x01    /* Disable Nagle's algorithm */
#define TCP_MAXSEG              0x02    /* Set maximum segment size */
#define TCP_NOPUSH              0x04    /* Disable push on final write */
#define TCP_NOOPT               0x08    /* Disable TCP options */
#define TCP_KEEPALIVE           0x10    /* Set keepalive idle time */
#define TCP_CONNECTIONTIMEOUT   0x20    /* Set connection timeout */
#define PERSIST_TIMEOUT         0x40    /* Timeout for persist state */
#define TCP_RXT_CONNDROPTIME    0x80    /* Connection drop time for retransmissions */
#define TCP_RXT_FINDROP         0x100   /* Drop connection after retransmitting FIN */
#define TCP_KEEPINTVL           0x101   /* Interval between keepalives */
#define TCP_KEEPCNT             0x102   /* Number of keepalives before close */
#define TCP_SENDMOREACKS        0x103   /* Acknowledge every other packet */
#define TCP_ENABLE_ECN          0x104   /* Enable Explicit Congestion Notification */
#define TCP_FASTOPEN            0x105   /* TCP Fast Open */
#define TCP_CONNECTION_INFO     0x106   /* TCP connection state info */
#endif

#define INET6_ADDRSTRLEN        46      /* Length of string form of IPv6 address */

/* Address info flags */
#define AI_PASSIVE     0x00000001 /* Suitable for bind() */
#define AI_CANONNAME   0x00000002 /* Request canonical name */
#define AI_NUMERICHOST 0x00000004 /* Numeric host address string */
#ifdef IS_LINUX
#define AI_NUMERICSERV 0x00000400 /* Numeric service address string */
#else
#define AI_NUMERICSERV 0x00001000 /* Numeric service address string */
#define AI_UNUSABLE    0x10000000 /* Include unusable addresses */
#endif

/*
 * The hostent class represents an entry from the database of host names and addresses.
 * It includes the official name of the host, aliases, the type of address, the length of the address,
 * and a list of addresses for the host.
 */
public class hostent
{
  U8	*h_name;	/* Official name of the host */
  U8	**h_aliases;	/* Null-terminated array of alternate names for the host */
  I32 h_addrtype;	/* Type of address; typically AF_INET */
  I32 h_length;		/* Length of each address in bytes */
  U8	**h_addr_list;	/* Null-terminated array of addresses for the host */
};

/*
 * The netent class provides details about a network including its name, aliases, address type,
 * and the network number. The assumption is that a network number can fit in an unsigned long.
 */
public class netent
{
  U8  *n_name;      /* Official name of the network */
  U8  **n_aliases;  /* Null-terminated array of alternate names for the network */
  I32 n_addrtype;   /* Type of address for the network */
  U32 n_net;        /* Network number */
};

/*
 * The servent class encapsulates information about a service provided over the network,
 * including its official name, aliases, port number, and the protocol used.
 */
public class servent
{
  U8 *s_name;	  /* Official name of the service */
  U8 **s_aliases; /* Null-terminated array of alternate names for the service */
  I32 s_port;     /* Port number associated with the service */
  U8 *s_proto;    /* Name of the protocol to use with this service */
};

/*
 * The protoent class contains information about a given protocol, such as its name,
 * aliases, and the protocol number.
 */
public class protoent
{
  U8  *p_name;     /* Official name of the protocol */
  U8  **p_aliases; /* Null-terminated array of alternate names for the protocol */
  I32 p_proto;     /* Protocol number */
};

/*
 * The sockaddr class is a generic descriptor for socket address information,
 * including length, family, and actual address data.
 */
public class sockaddr
{
#ifdef IS_LINUX
  U16 sa_family;   /* Address family (Linux has no length byte) */
#else
  U8 sa_len;       /* Length of the structure */
  U8 sa_family;    /* Address family */
#endif
  U8 sa_data[14];  /* Actual address information */
};

/*
 * The in_addr class represents an IPv4 Internet address,
 * stored as an unsigned long.
 */
public class in_addr
{
  U32 s_addr; /* IPv4 address */
};

/*
 * The sockaddr_in class represents an IPv4 socket address,
 * including length, family, port, address, and padding to match the size of sockaddr.
 */
public class sockaddr_in
{
#ifdef IS_LINUX
  U16 sin_family;     /* Address family, AF_INET */
#else
  U8 sin_len;         /* Length of the structure */
  U8 sin_family;      /* Address family, AF_INET */
#endif
  U16 sin_port;       /* Port number */
  in_addr sin_addr;   /* IPv4 address */
  U8 sin_zero[8];     /* Padding to make structure the same size as sockaddr */
};

/*
 * The in6_addr class is used to store an IPv6 address,
 * with three different representations for convenience.
 */
public class in6_addr
{
  union
  {
    U8   __u6_addr8[16];  /* 16 bytes of IPv6 address */
    U16  __u6_addr16[8];  /* 8 shorts of IPv6 address */
    U32  __u6_addr32[4];  /* 4 ints of IPv6 address */
  };                      /* Represents a 128-bit IPv6 address */
};

/*
 * The sockaddr_in6 class represents an IPv6 socket address,
 * including length, family, port, flow information, the IPv6 address,
 * and the scope zone index for link-local addresses.
 */
public class sockaddr_in6
{
#ifdef IS_LINUX
  U16 sin6_family;     /* Address family, AF_INET6 */
#else
  U8  sin6_len;        /* Length of this struct */
  U8  sin6_family;     /* Address family, AF_INET6 */
#endif
  U16 sin6_port;       /* Transport layer port number */
  U32 sin6_flowinfo;   /* IPv6 flow information */
  in6_addr sin6_addr;  /* IPv6 address */
  U32 sin6_scope_id;   /* Scope zone index */
};

/*
 * The addrinfo class is used for domain name resolution,
 * containing flags, family, socket type, protocol, address length,
 * canonical name, address, and pointer to the next in list.
 */
class addrinfo;
public class addrinfo
{
  I32 ai_flags;	     /* Input flags */
  I32 ai_family;     /* Address family */
  I32 ai_socktype;   /* Socket type */
  I32 ai_protocol;   /* Protocol for the socket */
  U32 ai_addrlen;    /* Length of the address */
#ifdef IS_LINUX
  sockaddr *ai_addr; /* Binary address */
  U8  *ai_canonname; /* Canonical name for the host */
#else
  U8  *ai_canonname; /* Canonical name for the host */
  sockaddr *ai_addr; /* Binary address */
#endif
  addrinfo *ai_next; /* Next structure in the linked list */
};


#define _SS_PAD1SIZE (6)
#define _SS_PAD2SIZE (112)

/*
 * The sockaddr_storage class is designed to accommodate all supported address families,
 * ensuring sufficient storage and proper alignment. It's used where a socket address
 * structure's size and family are known, but the exact type is not.
 */
public class sockaddr_storage
{
#ifdef IS_LINUX
  U16 ss_family;      /* Address family (AF_*) */
#else
  U8  ss_len;         /* Total length of the address */
  U8  ss_family;      /* Address family (AF_*) */
#endif
  U8  __ss_pad1[_SS_PAD1SIZE]; /* Padding to achieve alignment */
  I64 __ss_align;     /* Force alignment of the structure */
  U8  __ss_pad2[_SS_PAD2SIZE]; /* Additional padding to reach desired size */
};

/*
 * The msghdr class is used with message-based socket operations (sendmsg, recvmsg).
 * It includes an optional socket address, scatter/gather array, ancillary data,
 * and flags for received messages.
 */
public class msghdr
{
  U8    *msg_name;      /* Optional address */
  I64   msg_namelen;    /* Size of the address */
  iovec *msg_iov;       /* Scatter/gather array of buffers */
  I32   msg_iovlen;     /* Number of elements in msg_iov */
  U0    *msg_control;   /* Ancillary data */
  I64   msg_controllen; /* Length of ancillary data buffer */
  I32   msg_flags;      /* Flags on received message */
};

/*
 * The sockaddr_un class specifies a local socket address for Unix domain sockets.
 * It includes the address length, family, and path.
 */
public class sockaddr_un
{
#ifdef IS_LINUX
  U16 sun_family;    /* Address family: AF_UNIX */
  U8 sun_path[108];  /* Path name */
#else
  U8 sun_len;        /* Length of the sockaddr including null */
  U8 sun_family;     /* Address family: AF_UNIX */
  U8 sun_path[104];  /* Path name */
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

public Bool NetSetSocketNonBlocking(I32 sockfd);
public Bool NetSetSockReuseAddr(I32 sockfd);
public Bool NetSetSocketNoDelay(I32 sockfd);
public Bool NetGetIpv4Address(sockaddr *sAddr, I32 ai_family, U8 *outbuf, I32 size);
public I32 NetConnect(U8 *addr, I32 port, Bool non_blocking=FALSE);
public Bool NetListen(I32 sockfd, addrinfo *sa, I32 backlog);
public I32 NetCreateServer(I32 port, U8 *bindaddr, I32 backlog,
    I32 addrfam=AF_UNSPEC, Bool non_blocking=FALSE);
public I32 NetAccept(I32 socket, Bool non_blocking=FALSE);
public Bool NetGetIpv4AddressFromAcceptedSocket(I32 sockfd, U8 *ipbuf, I32 outlen);
public I32 NetCreateUnixServerSocket(U8 *name, I32 backlog);
public I32 NetCreateUnixClientSocket(U8 *name);


class RBNode;
public class RBNode
{
  U0 *key;
  U0 *value;
  I64 color;
  RBNode *left;
  RBNode *right;
  RBNode *parent;
};

public class RBTree
{
  RBNode *root;
  I64 size;
  U0 (*free_key)(U0 *);
  U0 (*free_value)(U0 *);
  I64 (*key_cmp)(U0 *, U0 *);
  RBNode *nil; /* this tree's sentinel leaf */
};

public RBTree *RBTreeNew(U0 (*free_key)(U0 *),
                         U0 (*free_value)(U0 *), 
                         U0 (*key_cmp)(U0 *, U0 *));
/* Insert or update. Updating an existing key keeps the stored key; the
 * destructors (if set) free the passed duplicate key and the old value. */
public U0 RBTreeInsert(RBTree *tree, U0 *key, U0 *value);
public U0 *RBTreeGet(RBTree *tree, U0 *key);
public Bool RBTreeHas(RBTree *tree, U0 *key);
/* Remove `key`, freeing its key and value with the destructors, if set. */
public U0 RBTreeDelete(RBTree *tree, U0 *key);
public U0 RBTreeForEach(RBTree *tree,
                        U0 *user_data,
                        U0 (*callback)(U0 *user_data,
                                       U0 *key, 
                                       U0 *value));
/* Free every entry (calling the key/value destructors, if set) and the
 * tree itself. NULL is ignored. */
public U0 RBTreeRelease(RBTree *tree);

public class RBIter
{
  I64 sp;
  RBNode **stack;
  RBNode *cur;
};

public RBIter *RBIterNew(RBTree *tree);
public U0 RBIterRelease(RBIter *it);
public RBNode *RBIterNext(RBIter *it);

public class IntSet
{
  RBTree *tree;
};
public class IntSetEntry
{
  I64 key;
};
public class IntSetIter
{
  I64 sp;
  RBNode **stack;
  IntSetEntry *entry;
};

/* A sorted set of I64s (a red-black tree): add, delete and lookup are
 * O(log n), iteration is in ascending order. The functions that only read
 * a set treat NULL as the empty set; IntSetAdd and IntSetDelete need a
 * real one. */
public IntSet *IntSetNew(U0);
/* TRUE when `key` is in the set; FALSE for a NULL set */
public Bool IntSetHas(IntSet *set, I64 key);
/* Add `key`; adding one that is already there changes nothing */
public U0 IntSetAdd(IntSet *set, I64 key);
/* Remove `key`; nothing happens if it is not there */
public U0 IntSetDelete(IntSet *set, I64 key);
/* The set operations return a new set (release it with IntSetRelease)
 * and leave their arguments alone. Union: in either set. */
public IntSet *IntSetUnion(IntSet *s1, IntSet *s2);
/* In `s1` but not in `s2` */
public IntSet *IntSetDiff(IntSet *s1, IntSet *s2);
/* In both sets */
public IntSet *IntSetIntersection(IntSet *s1, IntSet *s2);
/* In exactly one of the two sets */
public IntSet *IntSetSymDiff(IntSet *s1, IntSet *s2);
/* TRUE when both sets hold the same keys */
public Bool IntSetEq(IntSet *s1, IntSet *s2);
/* The keys in ascending order in a new IntVec (IntVecRelease it) */
public IntVec *IntSetToVec(IntSet *set);
/* "{1, 2, 3}", in ascending order; free the result */
public U8 *IntSetToString(IntSet *set);
/* Free the set. NULL is ignored. */
public U0 IntSetRelease(IntSet *set);
/* The next key in ascending order, or NULL at the end. The entry belongs
 * to the iterator and is overwritten by the next call. NULL for a NULL
 * iterator. */
public IntSetEntry *IntSetIterNext(IntSetIter *iter);
/* Free the iterator (not the set). NULL is ignored. */
public U0 IntSetIterRelease(IntSetIter *iter);
/* An iterator over the set's keys, smallest first:
 *   while ((e = IntSetIterNext(it))) ... e->key ...
 * Don't add or delete keys while iterating. A NULL set gives an iterator
 * that yields nothing. */
public IntSetIter *IntSetIterNew(IntSet *set);
/* The number of keys; 0 for a NULL set */
public I64 IntSetSize(IntSet *set);

/* A growable set of bits, all 0 at first, indexed from 0. Setting a bit
 * past the end grows the vector; reading or clearing one there does
 * nothing (it is 0). Bit `i` lives in `entries[i / 32]` as `1 << (i % 32)`;
 * `blocks` is the number of U32 entries. */
public class BitVec
{
  I64 blocks;
  U32 *entries;
};

public BitVec *BitVecNew();
/* Free the bit vector. NULL is ignored. */
public U0 BitVecRelease(BitVec *bv);
/* Set bit `idx`, growing the vector if needed; FALSE when out of memory
 * (the vector is unchanged) or `bv` is NULL. */
public Bool BitVecSet(BitVec *bv, U64 idx);
/* Clear bit `idx` */
public U0 BitVecUnSet(BitVec *bv, U64 idx);
/* TRUE when bit `idx` is set; FALSE past the end or for a NULL vector */
public Bool BitVecTest(BitVec *bv, U64 idx);
/* Clear every bit; the storage is kept */
public U0 BitVecClear(BitVec *bv);

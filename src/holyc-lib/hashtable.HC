#include "./defs.HH"
#include "./memory.HC"
#include "./system.HC"
#include "./strings.HC"
#include "./vector.HC"

#define HT_LOAD 60
#define HT_DELETED 0x7fffffffffffffff
#define HT_PROBE_1 1
#define HT_PROBE_3 3
#define HT_MIN_CAPACITY 8

/* Deletion leaves a tombstone: the node stays in its slot with `order` set
 * to HT_DELETED so probe chains running through it are not cut short. For a
 * live node `order` is its position in the map's `indexes` vector, which is
 * how a delete removes it from iteration. Tombstones are dropped whenever the
 * table is rebuilt; the rebuild is triggered by `indexes->size`, which counts
 * live entries plus at least one hole per tombstone, so the table always
 * keeps an empty slot and every probe terminates. */
class IntMapNode
{
  I64 key;
  U0 *value;
  I64 order;
};

class StrMapNode
{
  U8 *key;
  I64 key_len;
  U0 *value;
  I64 order;
};

public class IntMap
{
  U64 size;     /* How many entries are in the hashtable */
  U64 capacity; /* How much capacity we have in the entries array */
  U64 mask;     /* Used for hashing, as the capacity is always a power of 2
                 * we can use fast modulo of `<int> & capacity-1`. */
  IntVec *indexes; /* Where all of the values are in the entries array, in 
                    * insertion order. Means we can iterate over the HashTable 
                    * quickly at the cost of memory */
  U64 threashold; /* rebuild threashold */
  U0 (*_free_value)(U0 *value); /* User defined callback for freeing values */
  IntMapNode **entries; /* All of the entries, XXX: could this be IntMapNode *entries? */
};

public class StrMap
{
  U64 size;     /* How many entries are in the hashtable */
  U64 capacity; /* How much capacity we have in the entries array */
  U64 mask;     /* Used for hashing, as the capacity is always a power of 2
                 * we can use fast modulo of `<int> & capacity-1`. */
  IntVec *indexes; /* Where all of the values are in the entries array, in 
                 * insertion order. Means we can iterate over the HashTable 
                 * quickly at the cost of memory */
  U64 threashold; /* rebuild threashold */
  U0 (*_free_value)(U0 *_value); /* User defined callback for freeing values */
  U0 (*_free_key)(U0 *_key); /* User defined callback for freeing keys */
  StrMapNode **entries; /* All of the entries, XXX: could this be StrMapNode *entries? */
};

U64 RoundUpToNextPowerOf2(U64 v)
{
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  v |= v >> 32;
  v++;
  return v;
}

static U64 HtCapacity(U64 capacity)
{/* The probe loops use `idx & mask`, so the capacity, the mask and the size
  * of the entries array must all be the same power of two. Round any
  * requested size up to one (and to at least HT_MIN_CAPACITY, which also
  * keeps 0 and 1 from producing a zero mask or a zero threshold). */
  if (capacity < HT_MIN_CAPACITY) {
    capacity = HT_MIN_CAPACITY;
  }
  return RoundUpToNextPowerOf2(capacity);
}

static U64 HtFmix64(U64 h)
{/* murmur3's 64-bit finaliser: every bit of `h` affects every bit of the
  * result, so keys that differ only in bits above the mask still land in
  * different slots. */
  h ^= h >> 33;
  h *= 0xff51afd7ed558ccd;
  h ^= h >> 33;
  h *= 0xc4ceb9fe1a85ec53;
  h ^= h >> 33;
  return h;
}

public Bool IntMapSet(IntMap *map, I64 key, U0 *value);
public Bool IntMapHas(IntMap *map, I64 key);
public IntMap *IntMapNew(U64 capacity=32);
public U0 IntMapSetFreeValue(IntMap *map, U0 (*_free_value)(U0 *value));
public U0 IntMapRelease(IntMap *map);
public Bool IntMapResize(IntMap *map);

U64 IntMapHashFunction(I64 key, U64 mask)
{/* Mixed first: `key & mask` alone sent keys sharing their low bits
  * (multiples of a power of two, aligned pointers, `id << 20`) to the
  * same slots. */
  return HtFmix64(key) & mask;
}

IntMap *IntMapNew(U64 capacity)
{
  IntMap *map = MAlloc(sizeof(IntMap));
  capacity = HtCapacity(capacity);
  map->capacity = capacity;
  map->mask = capacity-1;
  map->size = 0;
  map->indexes = IntVecNew();
  map->threashold = (capacity * HT_LOAD)/100;
  map->_free_value = NULL;
  map->entries = CAlloc(capacity * sizeof(IntMapNode *));
  return map;
}

U0 IntMapSetFreeValue(IntMap *map, U0 (*_free_value)(U0 *value))
{
  map->_free_value = _free_value;
}

IntMapNode *IntMapNodeNew(I64 key, U0 *value)
{
  IntMapNode *n = MAlloc(sizeof(IntMapNode));
  n->key = key;
  n->value = value;
  n->order = HT_DELETED;
  return n;
}

static U64 IntMapGetIdx(IntMap *map, I64 key)
{// Slot holding `key`, or HT_DELETED. Tombstones are skipped, not stopped at.
  U64 idx = IntMapHashFunction(key, map->mask); 
  U64 mask = map->mask;
  IntMapNode **entries = map->entries;
  IntMapNode *cur;

  while ((cur = entries[idx])) {
    if (cur->order != HT_DELETED && cur->key == key) {
      return idx;
    }
    idx = (idx + 1) & mask;
  }
  return HT_DELETED;
}

static U64 IntMapGetNextIdx(IntMap *map, I64 key, Bool *_is_free)
{// The slot holding `key` (*_is_free = FALSE), else the slot to insert it
 // into (*_is_free = TRUE): the first tombstone on the probe chain, or the
 // empty slot that ends it.
  U64 mask = map->mask;
  U64 idx = IntMapHashFunction(key, mask);
  U64 tombstone = HT_DELETED;
  IntMapNode *cur;

  while ((cur = map->entries[idx]) != NULL) {
    if (cur->order == HT_DELETED) {
      if (tombstone == HT_DELETED) {
        tombstone = idx;
      }
    } else if (cur->key == key) {
      *_is_free = FALSE;
      return idx;
    }
    idx = (idx + 1) & mask;
  }
  *_is_free = TRUE;
  if (tombstone != HT_DELETED) {
    return tombstone;
  }
  return idx;
}

U0 IntMapRelease(IntMap *map)
{// free the entire hashtable
  if (map) {
    auto indexes = map->indexes;
    U0 (*free_value)(U0 *value) = map->_free_value;
    for (auto i = 0; i < map->capacity; ++i) {
      auto n = map->entries[i];
      if (n) {
        /* A tombstone's value was freed by IntMapDelete. */
        if (free_value && n->order != HT_DELETED) {
          free_value(n->value);
        }
        Free(n);
      }
    }
    IntVecRelease(indexes);
    Free(map->entries);
    Free(map);
  }
}

static Bool IntMapRehash(IntMap *map, U64 new_capacity)
{// Rebuild the table with `new_capacity` slots, keeping insertion order and
 // dropping tombstones. Returns FALSE if OOM.
  U64 new_mask;
  IntMapNode **new_entries, **old_entries;
  Bool is_free = 0;
  I64 *new_indexes, *old_indexes, new_size;
  auto indexes_capacity = IntVecCapacity(map->indexes);
  auto indexes_size = map->indexes->size;
  auto old_capacity = map->capacity;

  old_entries = map->entries;
  old_indexes = map->indexes->entries;

  new_mask = new_capacity - 1;

  /* OOM */
  if ((new_indexes = CAlloc(indexes_capacity * sizeof(I64))) == NULL) {
    return FALSE;
  }

  /* OOM */
  if ((new_entries = CAlloc(new_capacity * sizeof(IntMapNode*))) == NULL) {
    Free(new_indexes);
    return FALSE;
  }

  map->mask = new_mask;
  map->entries = new_entries;
  map->capacity = new_capacity;
  new_size = 0;

  for (U64 i = 0; i < indexes_size; ++i) {
    I64 idx = old_indexes[i];
    if (idx != HT_DELETED) {
      auto old = old_entries[idx];
      auto new_idx = IntMapGetNextIdx(map,old->key,&is_free);
      old->order = new_size;
      new_indexes[new_size] = new_idx;
      new_entries[new_idx] = old;
      new_size++;
    }
  }

  for (U64 i = 0; i < old_capacity; ++i) {
    auto old = old_entries[i];
    if (old && old->order == HT_DELETED) {
      Free(old);
    }
  }

  Free(old_entries);
  Free(old_indexes);
  map->indexes->size = new_size;
  map->indexes->entries = new_indexes;

  map->threashold = (new_capacity * HT_LOAD)/100;
  map->entries = new_entries;
  map->size = new_size;
  return TRUE;
}

public Bool IntMapResize(IntMap *map)
{// Double the hashtable, will return false if OMM
  return IntMapRehash(map,map->capacity << 1);
}

auto IntMapSet(IntMap *map, I64 key, U0 *value)
{
  Bool is_free;

  /* `indexes->size` is the live entries plus the holes deletes left, so this
   * also bounds the tombstones. A table that is mostly tombstones is rebuilt
   * at the same size rather than doubled. */
  if (map->indexes->size >= map->threashold) {
    U64 new_capacity = map->capacity;
    if (map->size >= map->threashold / 2) {
      new_capacity <<= 1;
    }
    if (!IntMapRehash(map,new_capacity)) {
      /* This means we have run out of memory */
      return FALSE;
    }
  }

  U64 idx = IntMapGetNextIdx(map,key,&is_free);
  if (is_free) {
    auto n = map->entries[idx];
    if (n) {
      /* Reuse a tombstone */
      n->key = key;
      n->value = value;
    } else {
      n = IntMapNodeNew(key,value);
      map->entries[idx] = n;
    }
    n->order = map->indexes->size;
    IntVecPush(map->indexes,idx);
    map->size++;
    return TRUE;
  } else {
    auto n = map->entries[idx];
    if (map->_free_value && n->value != value) {
      /* Replacing a live value: the map owned the old one. */
      map->_free_value(n->value);
    }
    n->value = value;
    return TRUE;
  }
}

public Bool IntMapDelete(IntMap *map, I64 key)
{// Remove `key`, freeing its value if a destructor is registered. Returns
 // FALSE if the key was not in the map.
  auto idx = IntMapGetIdx(map,key);
  if (idx != HT_DELETED) {
    auto n = map->entries[idx];
    if (map->_free_value) {
      map->_free_value(n->value);
    }
    map->indexes->entries[n->order] = HT_DELETED;
    n->order = HT_DELETED;
    n->value = NULL;
    map->size--;
    return TRUE;
  }
  return FALSE;
}

public Bool IntMapHas(IntMap *map, I64 key)
{
  auto idx = IntMapGetIdx(map,key);
  return idx != HT_DELETED;
}

public U0 *IntMapGet(IntMap *map, I64 key)
{
  auto idx = IntMapGetIdx(map,key);
  if (idx != HT_DELETED) {
    return map->entries[idx]->value;
  }
  return NULL;
}

public Bool IntMapIter(IntMap *map, I64 *_idx, IntMapNode **_node)
{
  I64 idx = *_idx;
  auto indexes = map->indexes->entries;

  while (idx < map->indexes->size) {
    I64 index = indexes[idx];
    if (index != HT_DELETED) {
      *_idx = idx + 1;
      *_node = map->entries[index];
      return TRUE;
    }
    idx++;
  }
  return FALSE;
}

public Bool IntMapValueIter(IntMap *map, I64 *_idx, U0 **_value)
{
  IntMapNode *node;
  if (IntMapIter(map,_idx,&node)) {
    *_value = node->value;
    return TRUE;
  }
  return FALSE;
}

public Bool IntMapKeyIter(IntMap *map, I64 *_idx, I64 *_key)
{
  IntMapNode *node;
  if (IntMapIter(map,_idx,&node)) {
    *_key = node->key;
    return TRUE;
  }
  return FALSE;
}

public U8 *IntMapToString(IntMap *map, U8 *(*stringify_value)(U0 *))
{
  auto map_size = map->size;
  if (map_size == 0) {
    return StrPrint(NULL,"{}");
  }

  IntMapNode *entry = NULL;
  auto buffer = StrPrint(NULL,"{");
  I64 printed = 0; /* `i` skips the holes deletes leave, so count */
  for (I64 i = 0; IntMapIter(map,&i,&entry);) {
    auto str_val = stringify_value(entry->value);
    if (++printed == map_size) {
      buffer = CatPrint(buffer, "[%d] => %s}",entry->key,str_val);
    } else {
      buffer = CatPrint(buffer, "[%d] => %s, ",entry->key,str_val);
    }
    Free(str_val);
  }
  return buffer;
}

public U8 *IntMapKeysToString(IntMap *map)
{
  auto map_size = map->size;
  if (map_size == 0) {
    return StrPrint(NULL,"{}");
  }

  IntMapNode *entry = NULL;
  auto buffer = StrPrint(NULL,"{");
  I64 printed = 0; /* `i` skips the holes deletes leave, so count */
  for (I64 i = 0; IntMapIter(map,&i,&entry);) {
    if (++printed == map_size) {
      buffer = CatPrint(buffer, "%d}",entry->key);
    } else {
      buffer = CatPrint(buffer, "%d, ",entry->key);
    }
  }
  return buffer;
}


public Bool StrMapSet(StrMap *map, U8 *key, U0 *value);
public StrMap *StrMapNew(U64 capacity=32);
public U0 StrMapSetFreeValue(StrMap *map, U0 (*_free_value)(U0 *value));
public U0 StrMapSetFreeKey(StrMap *map, U0 (*_free_key)(U0 *key));
public U0 StrMapRelease(StrMap *map);
public Bool StrMapResize(StrMap *map);

StrMap *StrMapNew(U64 capacity)
{
  StrMap *map = MAlloc(sizeof(StrMap));
  capacity = HtCapacity(capacity);
  map->capacity = capacity;
  map->mask = capacity-1;
  map->size = 0;
  map->indexes = IntVecNew();
  map->threashold = (capacity * HT_LOAD)/100;
  map->_free_value = NULL;
  map->_free_key = NULL;
  map->entries = CAlloc(capacity * sizeof(StrMapNode *));
  return map;
}

U0 StrMapSetFreeValue(StrMap *map, U0 (*_free_value)(U0 *value))
{
  map->_free_value = _free_value;
}

U0 StrMapSetFreeKey(StrMap *map, U0 (*_free_key)(U0 *key))
{
  map->_free_key = _free_key;
}

StrMapNode *StrMapNodeNew(U8 *key, I64 key_len, U0 *value)
{
  StrMapNode *n = MAlloc(sizeof(StrMapNode));
  n->key = key;
  n->key_len = key_len;
  n->value = value;
  n->order = HT_DELETED;
  return n;
}

static U64 StrMapGetNextIdx(StrMap *map, U8 *key, I64 key_len, Bool *_is_free)
{// The slot holding `key` (*_is_free = FALSE), else the slot to insert it
 // into (*_is_free = TRUE): the first tombstone on the probe chain, or the
 // empty slot that ends it.
  U64 mask = map->mask;
  U64 idx = StrHash(key) & mask;
  U64 tombstone = HT_DELETED;
  StrMapNode *cur;

  while ((cur = map->entries[idx]) != NULL) {
    if (cur->order == HT_DELETED) {
      if (tombstone == HT_DELETED) {
        tombstone = idx;
      }
    } else if (key_len == cur->key_len && !StrNCmp(cur->key,key,key_len)) {
      *_is_free = FALSE;
      return idx;
    }
    idx = (idx + 1) & mask;
  }
  *_is_free = TRUE;
  if (tombstone != HT_DELETED) {
    return tombstone;
  }
  return idx;
}

static I64 StrMapGetIdx(StrMap *map, U8 *key, I64 key_len)
{// Slot holding `key`, or HT_DELETED. Tombstones are skipped, not stopped at.
  U64 mask = map->mask;
  U64 idx = StrHash(key) & mask;
  StrMapNode **entries = map->entries;
  StrMapNode *cur;

  while ((cur = entries[idx]) != NULL) {
    if (cur->order != HT_DELETED && cur->key_len == key_len &&
        !StrNCmp(cur->key, key, key_len)) {
      return idx;
    }
    idx = (idx + 1) & mask;
  }
  return HT_DELETED;
}

U0 StrMapRelease(StrMap *map)
{// free the entire hashtable
  if (map) {
    U0 (*free_value)(U0 *_val) = map->_free_value;
    U0 (*free_key)(U0 *_key) = map->_free_key;
    for (auto i = 0; i < map->capacity; ++i) {
      auto n = map->entries[i];
      if (n) {
        /* A tombstone's key and value were freed by StrMapDelete. */
        if (n->order != HT_DELETED) {
          if (free_value) free_value(n->value);
          if (free_key)   free_key(n->key);
        }
        Free(n);
      }
    }
    Free(map->entries);
    IntVecRelease(map->indexes);
    Free(map);
  }
}

static Bool StrMapRehash(StrMap *map, U64 new_capacity)
{// Rebuild the table with `new_capacity` slots, keeping insertion order and
 // dropping tombstones. Returns FALSE if OOM.
  U64 new_mask;
  StrMapNode **new_entries, **old_entries;
  I64 *new_indexes, *old_indexes;
  Bool is_free = FALSE;
  auto indexes_capacity = IntVecCapacity(map->indexes);
  auto indexes_size = map->indexes->size;
  auto old_capacity = map->capacity;

  old_entries = map->entries;
  old_indexes = map->indexes->entries;

  new_mask = new_capacity - 1;

  /* OOM */
  if ((new_indexes = CAlloc(indexes_capacity * sizeof(I64))) == NULL) {
    return FALSE;
  }

  /* OOM */
  if ((new_entries = CAlloc(new_capacity * sizeof(StrMapNode*))) == NULL) {
    Free(new_indexes);
    return FALSE;
  }

  map->mask = new_mask;
  map->entries = new_entries;
  map->capacity = new_capacity;

  I64 new_size = 0;

  for (I64 i = 0; i < indexes_size; ++i) {
    I64 idx = old_indexes[i];
    if (idx != HT_DELETED) {
      auto old = old_entries[idx];
      I64 new_idx = StrMapGetNextIdx(map,old->key,old->key_len,&is_free);
      old->order = new_size;
      new_indexes[new_size] = new_idx;
      new_entries[new_idx] = old;
      new_size++;
    }
  }

  for (I64 i = 0; i < old_capacity; ++i) {
    auto old = old_entries[i];
    if (old && old->order == HT_DELETED) {
      Free(old);
    }
  }

  Free(old_entries);
  Free(old_indexes);
  map->indexes->size = new_size;
  map->indexes->entries = new_indexes;

  map->size = new_size;
  map->entries = new_entries;
  map->threashold = (new_capacity * HT_LOAD)/100;
  return TRUE;
}

public Bool StrMapResize(StrMap *map)
{// Double the hashtable, will return false if OMM
  return StrMapRehash(map,map->capacity << 1);
}

Bool StrMapSet(StrMap *map, U8 *key, U0 *value)
{
  Bool is_free;

  /* `indexes->size` is the live entries plus the holes deletes left, so this
   * also bounds the tombstones. A table that is mostly tombstones is rebuilt
   * at the same size rather than doubled. */
  if (map->indexes->size >= map->threashold) {
    U64 new_capacity = map->capacity;
    if (map->size >= map->threashold / 2) {
      new_capacity <<= 1;
    }
    if (!StrMapRehash(map,new_capacity)) {
      /* This means we have run out of memory */
      return FALSE;
    }
  }

  I64 key_len = StrLen(key);
  U64 idx = StrMapGetNextIdx(map,key,key_len,&is_free);

  if (is_free) {
    auto n = map->entries[idx];
    if (n) {
      /* Reuse a tombstone */
      n->key = key;
      n->key_len = key_len;
      n->value = value;
    } else {
      n = StrMapNodeNew(key,key_len,value);
      map->entries[idx] = n;
    }
    n->order = map->indexes->size;
    IntVecPush(map->indexes, idx);
    map->size++;
    return TRUE;
  } else {
    auto n = map->entries[idx];
    /* Updating an existing key keeps the key the map already stores; the
     * pointer passed now may be a reused buffer. With a key destructor
     * registered the map owns every key it is given, so the duplicate is
     * freed here instead of leaking (unless it is the stored key itself).
     * Likewise the replaced value is freed when a value destructor is
     * registered, unless the same pointer is being set again. */
    if (map->_free_key && n->key != key) {
      map->_free_key(key);
    }
    if (map->_free_value && n->value != value) {
      map->_free_value(n->value);
    }
    n->value = value;
    return TRUE;
  }
}

public Bool StrMapDelete(StrMap *map, U8 *key)
{// Remove `key`, freeing the stored key and value if destructors are
 // registered. Returns FALSE if the key was not in the map.
  I64 idx = StrMapGetIdx(map,key,StrLen(key));
  if (idx == HT_DELETED) {
    return FALSE;
  }
  auto n = map->entries[idx];
  if (map->_free_key)   map->_free_key(n->key);
  if (map->_free_value) map->_free_value(n->value);
  map->indexes->entries[n->order] = HT_DELETED;
  n->order = HT_DELETED;
  n->key = NULL;
  n->key_len = 0;
  n->value = NULL;
  map->size--;
  return TRUE;
}

public U0 *StrMapGetLen(StrMap *map, U8 *key, I64 key_len)
{
  auto idx = StrMapGetIdx(map,key,key_len);
  if (idx != HT_DELETED) {
    return map->entries[idx]->value;
  }
  return NULL;
}

public U0 *StrMapGet(StrMap *map, U8 *key)
{
  I64 key_len = StrLen(key);
  return StrMapGetLen(map,key,key_len);
}

public Bool StrMapHasLen(StrMap *map, U8 *key, I64 key_len)
{
  I64 idx = StrMapGetIdx(map,key,key_len);
  if (idx != HT_DELETED) {
    return TRUE;
  }
  return FALSE;
}

public Bool StrMapHas(StrMap *map, U8 *key)
{
  I64 key_len = StrLen(key);
  return StrMapHasLen(map,key,key_len);
}

public Bool StrMapIter(StrMap *map, I64 *_idx, StrMapNode **_node)
{
  I64 idx = *_idx;
  auto indexes = map->indexes->entries;
  auto size = map->indexes->size;

  while (idx < size) {
    I64 index = indexes[idx];
    if (index != HT_DELETED) {
      *_idx = idx + 1;
      *_node = map->entries[index];
      return TRUE;
    }
    idx++;
  }
  return FALSE;
}

public Bool StrMapValueIter(StrMap *map, I64 *_idx, U0 **_value)
{
  StrMapNode *node;
  if (StrMapIter(map,_idx,&node)) {
    *_value = node->value;
    return TRUE;
  }
  return FALSE;
}

public Bool StrMapKeyIter(StrMap *map, I64 *_idx, U8 **_key)
{
  StrMapNode *node;
  if (StrMapIter(map,_idx,&node)) {
    *_key = node->key;
    return TRUE;
  }
  return FALSE;
}

public U8 *StrMapToString(StrMap *map, U8 *(*stringify_value)(U0 *))
{
  auto map_size = map->size;

  if (map_size == 0) {
    return StrPrint(NULL,"{}");
  }

  StrMapNode *entry = NULL;
  auto buffer = StrPrint(NULL,"{");
  I64 printed = 0; /* `i` skips the holes deletes leave, so count */
  for (I64 i = 0; StrMapIter(map,&i,&entry);) {
    auto str_val = stringify_value(entry->value);
    if (++printed == map_size) {
      buffer = CatPrint(buffer, "[%s] => %s}",entry->key,str_val);
    } else {
      buffer = CatPrint(buffer, "[%s] => %s, ",entry->key,str_val);
    }
    Free(str_val);
  }
  return buffer;

}

public U8 *StrMapKeysToString(StrMap *map)
{
  auto map_size = map->size;
  if (map_size == 0) {
    return StrPrint(NULL,"{}");
  }

  StrMapNode *entry = NULL;
  auto buffer = StrPrint(NULL,"{");
  I64 printed = 0; /* `i` skips the holes deletes leave, so count */
  for (I64 i = 0; StrMapIter(map,&i,&entry);) {
    if (++printed == map_size) {
      buffer = CatPrint(buffer, "%s}",entry->key);
    } else {
      buffer = CatPrint(buffer, "%s, ",entry->key);
    }
  }
  return buffer;
}

#ifdef HOLYC_HT_TEST
U0 IntMapTests(U0)
{
  IntMap *map = IntMapNew(8);
  IntMapNode *n;
  U8 *strs[] = {
    "hello",
    "world",
    "foo",
    "bar",
    "baz",
    "cat",
    "dog",
    "owl"
  };
  I64 len = sizeof(strs)/sizeof(strs[0]);

  for (I64 i = 0; i < len; i++) {
    IntMapSet(map,i,strs[i]);
  }


  for (I64 i = 0; i < len; i++) {
    U8 *value = IntMapGet(map,i);
    if (value != strs[i]) {
      "Failed IntMapTests -> IntMapGet: %d=>%s\n",i,value;
      Exit;
    }
  }

  for (I64 i = 0; i < len; i++) {
    if (!IntMapHas(map,i)) {
      "Failed IntMapTests -> IntMapHas\n";
      Exit;
    }
  }

  /* Inorder iteration */
  for (I64 i = 0; IntMapIter(map,&i,&n);) {
    if (strs[i-1] != n->value) {
      "Failed IntMapTests -> IntMapIter i=%d key=%d => value=%s str = %s\n",
        i,n->key,n->value,strs[i];
      Exit;
    }
  }

  for (I64 i = 0; i < len; i++) {
    if (!IntMapDelete(map,i)) {
      "Failed IntMapTests -> IntMapDelete\n";
      Exit;
    }
  }

  IntMapRelease(map);
  "PASS IntMap\n";
}

U0 StrMapTests(U0)
{
  StrMap *map = StrMapNew(8);
  StrMapNode *n;
  U8 *keys[] = {
    "card",
    "can",
    "will",
    "shill",
    "cup",
    "mug",
    "glass",
    "tin"
  };
  U8 *strs[] = {
    "hello",
    "world",
    "foo",
    "bar",
    "baz",
    "cat",
    "dog",
    "owl"
  };

  I64 len = sizeof(strs)/sizeof(strs[0]);


  for (I64 i = 0; i < len; i++) {
    StrMapSet(map,keys[i],strs[i]);
  }

  for (I64 i = 0; i < len; i++) {
    if (StrMapGet(map,keys[i]) != strs[i]) {
      "Failed StrMapTests -> StrMapGet\n";
      Exit;
    }
  }

  for (I64 i = 0; i < len; i++) {
    if (!StrMapHas(map,keys[i])) {
      "Failed StrMapTests -> StrMapHas\n";
      Exit;
    }
  }

  /* Inorder iteration */
  for (I64 i = 0; StrMapIter(map,&i,&n);) {
    if (keys[i-1] != n->key || strs[i-1] != n->value) {
      "Failed StrMapTests -> StrMapIter\n";
      Exit;
    }
  }

  for (I64 i = 0; i < len; i++) {
    if (!StrMapDelete(map,keys[i])) {
      "Failed StrMapTests -> StrMapDelete\n";
      Exit;
    }
  }

  StrMapRelease(map);
  "PASS StrMap\n";
}

U0 Main(U0)
{
  IntMapTests;
  StrMapTests;
}
#endif

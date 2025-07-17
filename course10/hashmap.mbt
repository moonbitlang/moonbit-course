///|
fn Int::mod_u(a : Self, b : Self) -> Self {
  (a.reinterpret_as_uint() % b.reinterpret_as_uint()).reinterpret_as_int()
}

///|
struct Map[K, V] {
  get : (K) -> V?
  put : (K, V) -> Unit
  remove : (K) -> Unit
  size : () -> Int
  debug : (&Logger) -> Unit
}

///|
pub fn[K, V] Map::get(map : Map[K, V], key : K) -> V? {
  (map.get)(key)
}

///|
pub fn[K, V] Map::put(map : Map[K, V], key : K, value : V) -> Unit {
  (map.put)(key, value)
}

///|
pub fn[K, V] Map::remove(map : Map[K, V], key : K) -> Unit {
  (map.remove)(key)
}

///|
pub fn[K, V] Map::size(map : Map[K, V]) -> Int {
  (map.size)()
}

///|
pub fn[K, V] Map::is_empty(map : Map[K, V]) -> Bool {
  (map.size)() == 0
}

///|
pub fn[K, V] Map::contains(map : Map[K, V], key : K) -> Bool {
  match (map.get)(key) {
    Some(_) => true
    None => false
  }
}

///|
pub impl[K, V] Show for Map[K, V] with output(map : Map[K, V], buffer : &Logger) -> Unit {
  (map.debug)(buffer)
}

///|
priv struct Entry[K, V] {
  key : K
  mut value : V
} derive(Default, Show)

///|
priv struct HT_open[K, V] {
  mut values : Array[Entry[K, V]]
  mut occupied : Array[Status]
  mut length : Int
  mut size : Int
} derive(Show)

///|
enum Status {
  Empty
  Deleted
  Occupied
} derive(Eq, Show)

///| HashMap based on open addressing 哈希表：开放地址实现
/// 
/// Invariant : there's no empty slots between where a key should be stored and where it is stored
/// 条件：从键的哈希值开始直到键的实际存储位置之间没有任何的空槽
pub fn[K : Hash + Eq + Default + Show, V : Default + Show] Map::hash_open_address() -> Map[
  K,
  V,
] {
  let initial_length = 10
  // load of the hash map 哈希表的负载
  let load = 0.75
  let map : HT_open[K, V] = {
    values: Array::make(initial_length, Entry::default()),
    occupied: Array::make(initial_length, Empty),
    length: initial_length,
    size: 0,
  }

  // search to the right from where the key should be stored
  // return where it is stored (key encountered) or where it can be stored (the first empty slot encountered)
  // 从键的哈希值向右查找，返回键或第一个找到的空槽位置的索引
  letrec find_slot = fn(key : K) -> Int {
    let hash = key.hash()
    let mut i = hash.mod_u(map.length)
    while map.occupied[i] == Occupied {
      if map.values[i].key == key {
        return i
      }
      i = (i + 1).mod_u(map.length)
    }
    return i
  }
  and resize = fn() {
    let { values, occupied, length, .. } = map
    map.length = length * 2
    map.values = Array::make(map.length, Entry::default())
    map.occupied = Array::make(map.length, Empty)
    map.size = 0
    let mut i = 0
    while i < length {
      if occupied[i] == Empty {
        put(values[i].key, values[i].value)
      }
      i = i + 1
    }
  }
  and get = fn(key : K) -> V? {
    let index = find_slot(key)
    if map.occupied[index] == Occupied {
      Some(map.values[index].value)
    } else {
      None
    }
  }
  and put = fn(key : K, value : V) -> Unit {
    let index = find_slot(key)
    if map.occupied[index] == Occupied {
      map.values[index].value = value
    } else {
      map.occupied[index] = Occupied
      map.values[index] = { key, value }
      map.size = map.size + 1
    }
    if map.size.to_double() / map.length.to_double() >= load {
      resize()
    }
  }
  and remove = fn(key : K) -> Unit {
    let index = find_slot(key)
    if map.occupied[index] == Occupied {
      map.values[index] = Default::default()
      map.occupied[index] = Deleted
      map.size = map.size - 1
    }
  }

  fn size() -> Int {
    map.size
  }

  fn debug(buffer : &Logger) -> Unit {
    buffer.write_object(map)
  }

  { get, put, remove, size, debug }
}

///|
struct Bucket[V] {
  mut val : (V, Bucket[V])?
}

///|
impl[V : Show] Show for Bucket[V] with output(
  bucket : Bucket[V],
  buffer : &Logger
) -> Unit {
  match bucket.val {
    Some((v, next)) =>
      buffer..write_object(v)..write_string(" -> ")..write_object(next)
    None => buffer.write_string("End")
  }
}

///|
priv struct HT_bucket[K, V] {
  mut values : Array[Bucket[Entry[K, V]]]
  mut length : Int
  mut size : Int
} derive(Show)

///| HashMap based on linked list 哈希表：链表实现
pub fn[K : Hash + Eq + Show, V : Show] Map::hash_bucket() -> Map[K, V] {
  let initial_length = 10
  let load = 0.75
  let map : HT_bucket[K, V] = {
    values: Array::makei(initial_length, fn(_) { { val: None } }),
    size: 0,
    length: initial_length,
  }
  letrec resize = fn() {
    let { values, length, .. } = map
    map.length = length * 2
    map.values = Array::makei(map.length, fn(_) { { val: None } })
    map.size = 0
    let mut i = 0
    while i < length {
      let mut bucket = values[i]
      while bucket.val is Some((entry, rest)) {
        put(entry.key, entry.value)
        bucket = rest
      }
      i = i + 1
    }
  }
  and put = fn(key : K, value : V) -> Unit {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while bucket.val is Some((entry, rest)) {
      if entry.key == key {
        entry.value = value
        break
      } else {
        bucket = rest
      }
    } else {
      bucket.val = Some(({ key, value }, { val: None }))
      map.size = map.size + 1
    }
    if map.size.to_double() / map.length.to_double() >= load {
      resize()
    }
  }

  fn get(key : K) -> V? {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while bucket.val is Some((entry, rest)) {
      if entry.key == key {
        return Some(entry.value)
      } else {
        bucket = rest
      }
    }
    None
  }

  fn remove(key : K) -> Unit {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while bucket.val is Some((entry, rest)) {
      if entry.key == key {
        bucket.val = rest.val // { Some(entry, { val }) } -> { val }
        map.size = map.size - 1
        break
      } else {
        bucket = rest
      }
    }
  }

  fn size() -> Int {
    map.size
  }

  fn debug(buffer : &Logger) -> Unit {
    buffer.write_object(map)
  }

  { get, put, remove, size, debug }
}

///|
test {
  let map : Map[Int, Int] = Map::hash_bucket()
  for i = 0; i < 5; i = i + 1 {
    map.put(i, i)
  }
  assert_eq(map.size(), 5)
  for i = 0; i < 5; i = i + 1 {
    assert_true(map.contains(i))
  }
  for i = 0; i < 5; i = i + 2 {
    map.remove(i)
  }
  inspect(
    map,
    content="{values: [End, End, {key: 1, value: 1} -> End, End, End, End, End, End, End, {key: 3, value: 3} -> End], length: 10, size: 2}",
  )
  for i = 1; i < 5; i = i + 2 {
    assert_true(map.contains(i))
    map.remove(i)
  }
  assert_true(map.is_empty())
}

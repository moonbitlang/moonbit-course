struct Map[K, V] {
  get : (K) -> Option[V]
  put : (K, V) -> Unit
  remove : (K) -> Unit
  size : () -> Int
  debug : (Buffer) -> Unit
} derive(Show)

pub fn Map::get[K, V](map : Map[K, V], key : K) -> Option[V] {
  (map.get)(key)
}

pub fn Map::put[K, V](map : Map[K, V], key : K, value : V) -> Unit {
  (map.put)(key, value)
}

pub fn Map::remove[K, V](map : Map[K, V], key : K) -> Unit {
  (map.remove)(key)
}

pub fn Map::size[K, V](map : Map[K, V]) -> Int {
  (map.size)()
}

pub fn Map::is_empty[K, V](map : Map[K, V]) -> Bool {
  (map.size)() == 0
}

pub fn Map::contains[K, V](map : Map[K, V], key : K) -> Bool {
  match (map.get)(key) {
    Some(_) => true
    None => false
  }
}

pub fn Map::debug_write[K, V](map : Map[K, V], buffer : Buffer) -> Unit {
  (map.debug)(buffer)
}

priv struct Entry[K, V] {
  key : K
  mut value : V
} derive(Default, Debug)

priv struct HT_open[K, V] {
  mut values : Array[Entry[K, V]]
  mut occupied : Array[Status]
  mut length : Int
  mut size : Int
} derive(Debug)

enum Status {
  Empty
  Deleted
  Occupied
} derive(Eq, Debug)

/// HashMap based on open addressing 哈希表：开放地址实现
/// 
/// Invariant : there's no empty slots between where a key should be stored and where it is stored
/// 条件：从键的哈希值开始直到键的实际存储位置之间没有任何的空槽
pub fn Map::hash_open_address[K : Hash + Eq + Default + Debug, V : Default + Debug]() ->
     Map[K, V] {
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
  fn find_slot(key : K) -> Int {
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

  fn resize() {
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

  fn get(key : K) -> Option[V] {
    let index = find_slot(key)
    if map.occupied[index] == Occupied {
      Some(map.values[index].value)
    } else {
      None
    }
  }

  fn put(key : K, value : V) -> Unit {
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

  fn remove(key : K) -> Unit {
    let index = find_slot(key)
    if map.occupied[index] == Occupied {
      map.values[index] = default()
      map.occupied[index] = Deleted
      map.size = map.size - 1
    }
  }

  fn size() -> Int {
    map.size
  }

  fn debug(buffer : Buffer) -> Unit {
    map.debug_write(buffer)
  }

  { get, put, remove, size, debug }
}

struct Bucket[V] {
  mut val : Option[(V, Bucket[V])]
}

fn Bucket::debug_write[V : Debug](bucket : Bucket[V], buffer : Buffer) -> Unit {
  match bucket.val {
    Some((v, next)) => {
      v.debug_write(buffer)
      buffer.write_string(" -> ")
      next.debug_write(buffer)
    }
    None => buffer.write_string("End")
  }
}

priv struct HT_bucket[K, V] {
  mut values : Array[Bucket[Entry[K, V]]]
  mut length : Int
  mut size : Int
} derive(Debug)

/// HashMap based on linked list 哈希表：链表实现
pub fn Map::hash_bucket[K : Hash + Eq + Debug, V : Debug]() -> Map[K, V] {
  let initial_length = 10
  let load = 0.75
  let map : HT_bucket[K, V] = {
    values: @array.new(initial_length, fn() { { val: None } }),
    size: 0,
    length: initial_length,
  }
  fn resize() {
    let { values, length, .. } = map
    map.length = length * 2
    map.values = @array.new(initial_length, fn() { { val: None } })
    map.size = 0
    let mut i = 0
    while i < length {
      let mut bucket = values[i]
      while true {
        match bucket.val {
          None => break
          Some((entry, rest)) => {
            put(entry.key, entry.value)
            bucket = rest
          }
        }
      }
      i = i + 1
    }
  }

  fn get(key : K) -> Option[V] {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while true {
      match bucket.val {
        None => break
        Some((entry, rest)) =>
          if entry.key == key {
            return Some(entry.value)
          } else {
            bucket = rest
          }
      }
    }
    None
  }

  fn put(key : K, value : V) -> Unit {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while true {
      match bucket.val {
        None => {
          bucket.val = Some(({ key, value }, { val: None }))
          map.size = map.size + 1
          break
        }
        Some((entry, rest)) =>
          if entry.key == key {
            entry.value = value
            break
          } else {
            bucket = rest
          }
      }
    }
    if map.size.to_double() / map.length.to_double() >= load {
      resize()
    }
  }

  fn remove(key : K) -> Unit {
    let hash = key.hash()
    let mut bucket = map.values[hash.mod_u(map.length)]
    while true {
      match bucket.val {
        None => break
        Some((entry, rest)) =>
          if entry.key == key {
            bucket.val = rest.val // { Some(entry, { val }) } -> { val }
            map.size = map.size - 1
            break
          } else {
            bucket = rest
          }
      }
    }
  }

  fn size() -> Int {
    map.size
  }

  fn debug(buffer : Buffer) -> Unit {
    map.debug_write(buffer)
  }

  { get, put, remove, size, debug }
}

test {
  let map : Map[Int, Int] = Map::hash_bucket()
  for i = 0; i < 5; i = i + 1 {
    map.put(i, i)
  }
  @assertion.assert_eq(map.size(), 5)?
  for i = 0; i < 5; i = i + 1 {
    @assertion.assert_true(map.contains(i))?
  }
  for i = 0; i < 5; i = i + 2 {
    map.remove(i)
  }
  inspect(
    map,
    ~content="{values: [End, {key: 1, value: 1} -> End, End, {key: 3, value: 3} -> End, End, End, End, End, End, End], length: 10, size: 2}",
  )?
  for i = 1; i < 5; i = i + 2 {
    @assertion.assert_true(map.contains(i))?
    map.remove(i)
  }
  @assertion.assert_true(map.is_empty())?
}

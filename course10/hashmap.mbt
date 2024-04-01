struct Map[K, V] {
  get : (K) -> Option[V]
  put : (K, V) -> Unit
  remove : (K) -> Unit
  size : () -> Int
  debug_map: () -> Unit
}

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
} derive(Debug)

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
    while map.occupied[i] === Occupied, i = (i + 1).mod_u(map.length) {
      if map.values[i].key == key {
        return i
      }
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
    while i < length, i = i + 1 {
      if occupied[i] === Empty {
        put(values[i].key, values[i].value)
      }
    }
  }

  fn get(key : K) -> Option[V] {
    let index = find_slot(key)
    if map.occupied[index] === Occupied {
      Some(map.values[index].value)
    } else {
      None
    }
  }

  fn put(key : K, value : V) -> Unit {
    let index = find_slot(key)
    if map.occupied[index] === Occupied {
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
    if map.occupied[index] === Occupied {
      map.values[index] = default()
      map.occupied[index] = Deleted
      map.size = map.size - 1
    }
  }

  fn size() -> Int {
    map.size
  }

  fn debug_map() -> Unit {
    debug(map)
  }

  { get, put, remove, size, debug_map }
}

struct Bucket[V] {
  mut val : Option[(V, Bucket[V])]
}

fn Bucket::debug_write[V: Debug](bucket: Bucket[V], buffer: Buffer) {
  match bucket.val {
    Some(v, next) => {
      v.debug_write(buffer)
      buffer.write_string(" -> ")
      next.debug_write(buffer)
    }
    None => { buffer.write_string("End") }
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
    values: Array::make(initial_length, { val: None }),
    size: 0,
    length: initial_length,
  }
  fn resize() {
    let { values, length, .. } = map
    map.length = length * 2
    map.values = Array::make(length, { val: None })
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
        Some((entry, rest)) => {
          if entry.key == key {
            entry.value = value
            break
          } else {
            bucket = rest
          }
        }
      }
    }
    debug(bucket)
    debug(map)
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
        Some((entry, rest)) => {
          if entry.key == key {
            bucket.val = rest.val // { Some(entry, { val }) } -> { val }
            map.size = map.size - 1
            break
          }
          else {
            bucket = rest
          }
        }
      }
    }
  }

  fn size() -> Int {
    map.size
  }
  fn debug_map() -> Unit {
    debug(map)
  }

  { get, put, remove, size, debug_map }
}

fn init {
  let map : Map[Int, Int] = Map::hash_bucket()
  let start = 0
  let end = 3
  let mut i = start
  while i < end {
    map.put(i, i)
    i = i + 1
  }
  debug(map.size())
  i = start
  while i < end {
    // debug(map.contains(i))
    i = i + 1
  }
  while i >= start {
    if i % 2 == 0 { map.remove(i) }
    i = i - 1
  }
  i = end
  (map.debug_map)()
  while i >= start {
    if i % 2 != 0 {
      debug(map.contains(i))
      map.remove(i)
    }
    i = i - 1
  }
  debug(map.is_empty())
}

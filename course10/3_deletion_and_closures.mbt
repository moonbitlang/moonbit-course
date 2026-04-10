// Part 2: Open addressing with deletion (tombstone method) and closures
// Code separator: ///|

// Helper function for modulo operation

// Status enum for tracking slot states

///|
priv enum Status[K, V] {
  Empty
  Deleted // Tombstone marker
  Occupied(K, V)
}

// Hash table with tombstone deletion

///|
priv struct HT_open_tombstone[K, V] {
  mut values : Array[Status[K, V]] // Empty, Deleted, or Occupied
  mut length : Int
  mut size : Int
}

// Create new hash table

///|
fn[K, V] HT_open_tombstone::make(
  initial_capacity : Int,
) -> HT_open_tombstone[K, V] {
  {
    values: Array::makei(initial_capacity, _ => Empty),
    length: initial_capacity,
    size: 0,
  }
}

// Find slot: returns key index if found, or first empty/deleted slot

///|
fn[K : Hash + Eq, V] HT_open_tombstone::find_slot(
  self : HT_open_tombstone[K, V],
  key : K,
) -> Int {
  let mut slot = None
  for index = key.hash().abs() % self.length; ; index = (index + 1) %
        self.length {
    match self.values[index] {
      Empty => return if slot is Some(s) { s } else { index }
      Deleted => if slot is None { slot = Some(index) }
      Occupied(k, _v) => if k == key { return index }
    }
  }
}

// Put operation

///|
fn[K : Hash + Eq, V] HT_open_tombstone::put(
  self : HT_open_tombstone[K, V],
  key : K,
  value : V,
) -> Unit {
  let index = self.find_slot(key)
  match self.values[index] {
    Occupied(_) => self.values[index] = Occupied(key, value)
    _ => { // Insert new key (slot is Empty or Deleted)
      self.values[index] = Occupied(key, value)
      self.size = self.size + 1
    }
  }
  if self.size.to_double() / self.length.to_double() >= 0.75 {
    self.resize()
  }
}

// Get operation

///|
fn[K : Hash + Eq, V] HT_open_tombstone::get(
  self : HT_open_tombstone[K, V],
  key : K,
) -> V? {
  let index = self.find_slot(key)
  match self.values[index] {
    Occupied(_k, v) => Some(v)
    _ => None
  }
}

// Remove operation

///|
fn[K : Hash + Eq, V] HT_open_tombstone::remove(
  self : HT_open_tombstone[K, V],
  key : K,
) -> Unit {
  let index = self.find_slot(key)
  if self.values[index] is Occupied(_) {
    self.values[index] = Deleted
    self.size = self.size - 1
  }
}

// Resize operation

///|
fn[K : Hash, V] HT_open_tombstone::resize(
  self : HT_open_tombstone[K, V],
) -> Unit {
  let new_length = self.length * 2
  let new_values = Array::makei(new_length, _ => Empty)
  for i = 0; i < self.length; i = i + 1 {
    match self.values[i] {
      Occupied(key, v) => {
        let hash = key.hash()
        let mut j = hash.abs() % new_length
        while new_values[j] is Occupied(_) {
          j = (j + 1).abs() % new_length
        }
        new_values[j] = Occupied(key, v)
      }
      _ => ()
    }
  }
  self.values = new_values
  self.length = new_length
}

// Closure examples

///|

// Example 1: Closure captures and modifies variable
test "closure: basic capture" {
  let mut i = 2
  fn debug_i() -> Int {
    i
  }

  i = 3
  inspect(debug_i(), content="3")
  let i = 4 // Different i
  ignore(i)
  inspect(debug_i(), content="3") // Still captures outer i
}

// Example 2: Encapsulating data with closures

///|
fn natural_number_get_and_set() -> (() -> Int, (Int) -> Unit) {
  let mut i = 0
  fn get() -> Int {
    i
  }

  fn set(new_value : Int) -> Unit {
    if new_value >= 0 {
      i = new_value
    } // Only accept non-negative values
  }

  (get, set)
}

///|
test "closure: encapsulation" {
  let (get, set) = natural_number_get_and_set()
  set(10)
  inspect(get(), content="10")
  set(-100) // Invalid, should be ignored
  inspect(get(), content="10") // Value unchanged
  set(20)
  inspect(get(), content="20")
}

// Example 3: Map interface with closures

///|
priv struct Map[K, V] {
  get : (K) -> V?
  put : (K, V) -> Unit
  remove : (K) -> Unit
  size : () -> Int
}

// Helper for creating map with separate chaining

///|
priv struct Entry[K, V] {
  key : K
  mut value : V
}

///|
priv struct Bucket[V] {
  mut val : (V, Bucket[V])?
}

///|
fn[K : Hash + Eq, V] Map::hash_bucket() -> Map[K, V] {
  let initial_length = 10
  let values : Array[Bucket[Entry[K, V]]] = Array::makei(initial_length, _ => {
    val: None,
  })
  for i = 0; i < initial_length; i = i + 1 {
    values[i] = { val: None }
  }
  let mut size_count = 0
  let length = initial_length
  fn get(key : K) -> V? {
    let index = key.hash().abs() % length
    let mut bucket = values[index]
    for {
      match bucket.val {
        Some((entry, rest)) => {
          if entry.key == key {
            return Some(entry.value)
          }
          bucket = rest
        }
        None => return None
      }
    }
    abort("unreachable")
  }

  fn put(key : K, value : V) -> Unit {
    let index = key.hash().abs() % length
    let mut bucket = values[index]
    for {
      match bucket.val {
        Some((entry, rest)) => {
          if entry.key == key {
            entry.value = value
            break
          }
          bucket = rest
        }
        None => {
          bucket.val = Some(({ key, value }, { val: None }))
          size_count = size_count + 1
          break
        }
      }
    }
  }

  fn remove(key : K) -> Unit {
    let index = key.hash().abs() % length
    let mut bucket = values[index]
    for {
      match bucket.val {
        Some((entry, rest)) => {
          if entry.key == key {
            bucket.val = rest.val
            size_count = size_count - 1
            break
          }
          bucket = rest
        }
        None => break
      }
    }
  }

  fn size() -> Int {
    size_count
  }

  { get, put, remove, size }
}

///|
fn[K : Hash + Eq, V] Map::hash_open() -> Map[K, V] {
  let map = HT_open_tombstone::make(8)
  {
    get: v => map.get(v),
    put: (k, v) => map.put(k, v),
    remove: k => map.remove(k),
    size: () => map.size,
  } // 返回包含闭包的结构体
}

// Extension methods for Map

///|
fn[K, V] Map::is_empty(self : Map[K, V]) -> Bool {
  (self.size)() == 0
}

///|
fn[K, V] Map::contains(self : Map[K, V], key : K) -> Bool {
  (self.get)(key) is Some(_)
}

// Tests

///|
test "tombstone deletion: basic operations" {
  let ht : HT_open_tombstone[Int, String] = HT_open_tombstone::make(10)
  ht.put(1, "one")
  ht.put(2, "two")
  ht.put(3, "three")
  assert_eq(ht.get(1), Some("one"))
  assert_eq(ht.get(2), Some("two"))
  assert_eq(ht.size, 3)
  ht.remove(2)
  assert_eq(ht.get(2), None)
  assert_eq(ht.size, 2)
}

///|
test "tombstone deletion: slot reuse" {
  let ht : HT_open_tombstone[Int, Int] = HT_open_tombstone::make(10)
  ht.put(1, 100)
  ht.remove(1)
  assert_eq(ht.get(1), None)
  ht.put(1, 200) // Reuse the deleted slot
  assert_eq(ht.get(1), Some(200))
  assert_eq(ht.size, 1)
}

///|
test "map with closures: basic usage" {
  let map : Map[Int, Int] = Map::hash_bucket()
  inspect(map.is_empty(), content="true")
  (map.put)(1, 10)
  inspect((map.get)(1), content="Some(10)")
  inspect(map.is_empty(), content="false")
  (map.remove)(1)
  inspect(map.contains(1), content="false")
}

///|
test "map with closures: update" {
  let map : Map[Int, String] = Map::hash_bucket()
  (map.put)(1, "hello")
  assert_eq((map.get)(1), Some("hello"))
  (map.put)(1, "world")
  assert_eq((map.get)(1), Some("world"))
  assert_eq((map.size)(), 1) // Size should not increase
}

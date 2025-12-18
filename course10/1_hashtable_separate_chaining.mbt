// Part 1: Hash table basics - Direct addressing (separate chaining)
// Code separator: ///|

// Entry structure: stores key-value pairs

///|
priv struct Entry[K, V] {
  key : K
  mut value : V // Allow in-place value updates
}

// Bucket structure: a mutable linked list

///|
priv struct Bucket[V] {
  mut val : (V, Bucket[V])? // None = empty list, Some = (head, rest)
}

// Hash table with separate chaining

///|
priv struct HT_bucket[K, V] {
  mut values : Array[Bucket[Entry[K, V]]] // Array of buckets (lists)
  mut length : Int // Array length (dynamically maintained)
  mut size : Int // Number of key-value pairs
}

// Helper function for modulo operation

///|
fn Int::mod_u(a : Int, b : Int) -> Int {
  (a.reinterpret_as_uint() % b.reinterpret_as_uint()).reinterpret_as_int()
}

///|
test {
  inspect(
    "这是一个非常非常长的字符串".hash(),
    content="-735211761",
  )
}

// Create a new hash table with separate chaining

///|
fn[K, V] HT_bucket::make(initial_capacity : Int) -> HT_bucket[K, V] {
  let values : Array[Bucket[Entry[K, V]]] = Array::make(initial_capacity, {
    val: None,
  })
  // Initialize each bucket separately to avoid aliasing
  for i = 0; i < initial_capacity; i = i + 1 {
    values[i] = { val: None }
  }
  { values, length: initial_capacity, size: 0 }
}

// Put (insert or update) a key-value pair

///|
fn[K : Hash + Eq, V] HT_bucket::put(
  self : HT_bucket[K, V],
  key : K,
  value : V,
) -> Unit {
  let index = key.hash().mod_u(self.length) // Compute index
  let mut bucket = self.values[index] // Find corresponding bucket

  // Traverse the bucket to find the key
  for {
    match bucket.val {
      Some((entry, rest)) =>
        if entry.key == key {
          // Key found, update value
          entry.value = value
          break
        } else {
          // Continue traversing
          bucket = rest
        }
      None => {
        // Key not found, add new entry
        bucket.val = Some(({ key, value }, { val: None }))
        self.size = self.size + 1
        break
      }
    }
  }

  // Check if resizing is needed based on load factor
  if self.size.to_double() / self.length.to_double() >= 0.75 {
    self.resize()
  }
}

// Get value by key

///|
fn[K : Hash + Eq, V] HT_bucket::get(self : HT_bucket[K, V], key : K) -> V? {
  let index = key.hash().mod_u(self.length)
  let mut bucket = self.values[index]
  for {
    match bucket.val {
      Some((entry, rest)) =>
        if entry.key == key {
          return Some(entry.value)
        } else {
          bucket = rest
        }
      None => return None
    }
  }
  abort("unreachable")
}

// Remove a key-value pair

///|
fn[K : Hash + Eq, V] HT_bucket::remove(self : HT_bucket[K, V], key : K) -> Unit {
  let index = key.hash().mod_u(self.length)
  let mut bucket = self.values[index]
  for {
    match bucket.val {
      Some((entry, rest)) =>
        if entry.key == key {
          // Found the key, remove it
          bucket.val = rest.val
          self.size = self.size - 1
          break
        } else {
          bucket = rest
        }
      None => break // Key not found
    }
  }
}

// Resize the hash table (double the capacity)

///|
fn[K : Hash, V] HT_bucket::resize(self : HT_bucket[K, V]) -> Unit {
  let new_length = self.length * 2
  let new_values : Array[Bucket[Entry[K, V]]] = Array::make(new_length, {
    val: None,
  })

  // Initialize each bucket
  for i = 0; i < new_length; i = i + 1 {
    new_values[i] = { val: None }
  }

  // Rehash all existing entries
  for i = 0; i < self.length; i = i + 1 {
    let mut bucket = self.values[i]
    for {
      match bucket.val {
        Some((entry, rest)) => {
          let new_index = entry.key.hash().mod_u(new_length)
          let old_head = new_values[new_index].val
          new_values[new_index].val = Some((entry, { val: old_head }))
          bucket = rest
        }
        None => break
      }
    }
  }
  self.values = new_values
  self.length = new_length
}

// Tests for separate chaining hash table

///|
test "hash table separate chaining: basic operations" {
  let ht : HT_bucket[Int, String] = HT_bucket::make(5)

  // Test put and get
  ht.put(1, "one")
  ht.put(2, "two")
  ht.put(3, "three")
  assert_eq(ht.get(1), Some("one"))
  assert_eq(ht.get(2), Some("two"))
  assert_eq(ht.get(3), Some("three"))
  assert_eq(ht.get(4), None)
  assert_eq(ht.size, 3)
}

///|
test "hash table separate chaining: update existing key" {
  let ht : HT_bucket[Int, Int] = HT_bucket::make(5)
  ht.put(1, 100)
  assert_eq(ht.get(1), Some(100))
  ht.put(1, 200) // Update
  assert_eq(ht.get(1), Some(200))
  assert_eq(ht.size, 1) // Size should not change
}

///|
test "hash table separate chaining: remove" {
  let ht : HT_bucket[Int, String] = HT_bucket::make(5)
  ht.put(1, "one")
  ht.put(2, "two")
  ht.put(3, "three")
  ht.remove(2)
  assert_eq(ht.get(2), None)
  assert_eq(ht.size, 2)
  ht.remove(10) // Remove non-existent key
  assert_eq(ht.size, 2)
}

///|
test "hash table separate chaining: collision handling" {
  let ht : HT_bucket[Int, String] = HT_bucket::make(5)

  // Keys that hash to the same index (hash % 5)
  ht.put(0, "zero")
  ht.put(5, "five") // 5 % 5 = 0, collision with 0
  ht.put(10, "ten") // 10 % 5 = 0, collision with 0 and 5
  assert_eq(ht.get(0), Some("zero"))
  assert_eq(ht.get(5), Some("five"))
  assert_eq(ht.get(10), Some("ten"))
  assert_eq(ht.size, 3)
}

///|
test "hash table separate chaining: resize" {
  let ht : HT_bucket[Int, Int] = HT_bucket::make(2)

  // Add enough elements to trigger resize (load factor >= 0.75)
  ht.put(1, 1)
  ht.put(2, 2)
  // After adding 2 elements, load = 2/2 = 1.0 >= 0.75, should resize

  ht.put(3, 3)
  ht.put(4, 4)

  // Verify all elements are still accessible after resize
  assert_eq(ht.get(1), Some(1))
  assert_eq(ht.get(2), Some(2))
  assert_eq(ht.get(3), Some(3))
  assert_eq(ht.get(4), Some(4))
  assert_eq(ht.size, 4)
}

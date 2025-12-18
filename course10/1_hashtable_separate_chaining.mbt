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
  mut next : (V, Bucket[V])? // None = empty list, Some = (head, rest)
}

// Hash table with separate chaining

///|
priv struct HT_bucket[K, V] {
  mut values : Array[Bucket[Entry[K, V]]] // Array of buckets (lists)
  mut length : Int // Array length (dynamically maintained)
  mut size : Int // Number of key-value pairs
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
  let values : Array[Bucket[Entry[K, V]]] = Array::makei(initial_capacity, _ => {
    next: None,
  })
  // Initialize each bucket separately to avoid aliasing
  for i = 0; i < initial_capacity; i = i + 1 {
    values[i] = { next: None }
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
  let index = key.hash().abs() % self.length // 计算对应索引
  let mut bucket = self.values[index] // 找到对应列表
  while bucket.next is Some((entry, rest)) { // 遍历列表查找键
    if entry.key == key { // 找到键，更新值
      entry.value = value
      break
    } else {
      bucket = rest // 继续查找
    }
  } else {
    bucket.next = Some(({ key, value }, { next: None })) // 未找到，添加新键值对
    self.size = self.size + 1
  }
  if self.size.to_double() / self.length.to_double() >= 0.75 {
    self.resize() // 根据负载判断是否需要扩容
  }
}

// Get value by key

///|
fn[K : Hash + Eq, V] HT_bucket::get(self : HT_bucket[K, V], key : K) -> V? {
  let index = key.hash().abs() % self.length
  let mut bucket = self.values[index]
  while bucket.next is Some((entry, rest)) {
    if entry.key == key {
      return Some(entry.value)
    } else {
      bucket = rest
    }
  }
  None
}

// Remove a key-value pair

///|
fn[K : Hash + Eq, V] HT_bucket::remove(self : HT_bucket[K, V], key : K) -> Unit {
  let index = key.hash().abs() % self.length
  let mut bucket = self.values[index]
  while bucket.next is Some((entry, rest)) {
    if entry.key == key {
      // 找到键，删除（通过修改指针）
      bucket.next = rest.next
      self.size = self.size - 1
      break
    } else {
      bucket = rest // 继续查找
    }
  }
}

// Resize the hash table (double the capacity)

///|
fn[K : Hash, V] HT_bucket::resize(self : HT_bucket[K, V]) -> Unit {
  let new_length = self.length * 2
  let new_values : Array[Bucket[Entry[K, V]]] = Array::makei(new_length, _ => {
    next: None,
  })

  // Initialize each bucket
  for i = 0; i < new_length; i = i + 1 {
    new_values[i] = { next: None }
  }

  // Rehash all existing entries
  for i = 0; i < self.length; i = i + 1 {
    let mut bucket = self.values[i]
    while bucket.next is Some((entry, rest)) {
      let new_index = entry.key.hash().abs() % new_length
      let old_head = new_values[new_index].next
      new_values[new_index].next = Some((entry, { next: old_head }))
      bucket = rest
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

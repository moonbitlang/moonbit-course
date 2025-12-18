// Part 1: Hash table basics - Open addressing (linear probing)
// Code separator: ///|

// Entry structure for open addressing
///|
priv struct Entry_open[K, V] {
  key : K
  mut value : V
} derive(Default)

// Hash table with open addressing (linear probing)
///|
priv struct HT_open[K, V] {
  mut values : Array[Entry_open[K, V]] // Array of entries
  mut occupied : Array[Bool] // Track which slots are occupied
  mut length : Int // Array length
  mut size : Int // Number of key-value pairs
}

// Create a new hash table with open addressing
///|
fn[K : Default, V : Default] HT_open::make(initial_capacity : Int) -> HT_open[K, V] {
  {
    values: Array::make(initial_capacity, Default::default()),
    occupied: Array::make(initial_capacity, false),
    length: initial_capacity,
    size: 0,
  }
}

// Find slot for a key (returns key index if found, or first empty slot)
///|
fn[K : Hash + Eq, V] HT_open::find_slot(self : HT_open[K, V], key : K) -> Int {
  let hash = key.hash()
  let mut i = hash.abs() % self.length

  while self.occupied[i] {
    if self.values[i].key == key {
      return i // Found the key
    } else {
      i = (i + 1).abs() % self.length // Linear probing
    }
  }
  return i // Found empty slot
}

// Put (insert or update) a key-value pair
///|
fn[K : Hash + Eq + Default, V : Default] HT_open::put(
  self : HT_open[K, V],
  key : K,
  value : V
) -> Unit {
  let index = self.find_slot(key)

  if self.occupied[index] {
    // Key exists, update value
    self.values[index].value = value
  } else {
    // Insert new key-value pair
    self.occupied[index] = true
    self.values[index] = { key, value }
    self.size = self.size + 1
  }

  // Check if resizing is needed
  if self.size.to_double() / self.length.to_double() >= 0.75 {
    self.resize()
  }
}

// Get value by key
///|
fn[K : Hash + Eq, V] HT_open::get(self : HT_open[K, V], key : K) -> Option[V] {
  let index = self.find_slot(key)

  if self.occupied[index] {
    Some(self.values[index].value)
  } else {
    None
  }
}

// Resize the hash table (double the capacity)
///|
fn[K : Hash + Default, V : Default] HT_open::resize(self : HT_open[K, V]) -> Unit {
  let new_length = self.length * 2
  let new_values : Array[Entry_open[K, V]] = Array::make(new_length, Default::default())
  let new_occupied = Array::make(new_length, false)

  // Rehash all existing entries
  for i = 0; i < self.length; i = i + 1 {
    if self.occupied[i] {
      let entry = self.values[i]
      let hash = entry.key.hash()
      let mut j = hash.abs() % self.length

      // Find empty slot in new array
      while new_occupied[j] {
        j = (j + 1).abs() % self.length
      }

      new_values[j] = entry
      new_occupied[j] = true
    }
  }

  self.values = new_values
  self.occupied = new_occupied
  self.length = new_length
}

// Tests for open addressing hash table
///|
test "hash table open addressing: basic operations" {
  let ht : HT_open[Int, String] = HT_open::make(10)

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

test "hash table open addressing: update existing key" {
  let ht : HT_open[Int, Int] = HT_open::make(10)

  ht.put(1, 100)
  assert_eq(ht.get(1), Some(100))

  ht.put(1, 200) // Update
  assert_eq(ht.get(1), Some(200))
  assert_eq(ht.size, 1) // Size should not change
}

test "hash table open addressing: linear probing" {
  let ht : HT_open[Int, String] = HT_open::make(5)

  // Add keys that would collide: 0, 5, 10 all hash to index 0
  ht.put(0, "zero")
  ht.put(5, "five")
  ht.put(10, "ten")

  // Verify all can be retrieved
  assert_eq(ht.get(0), Some("zero"))
  assert_eq(ht.get(5), Some("five"))
  assert_eq(ht.get(10), Some("ten"))
  assert_eq(ht.size, 3)
}

test "hash table open addressing: resize" {
  let ht : HT_open[Int, Int] = HT_open::make(4)

  // Add enough elements to trigger resize
  ht.put(1, 1)
  ht.put(2, 2)
  ht.put(3, 3)
  // After 3 elements, load = 3/4 = 0.75, should resize

  ht.put(4, 4)
  ht.put(5, 5)

  // Verify all elements are still accessible
  assert_eq(ht.get(1), Some(1))
  assert_eq(ht.get(2), Some(2))
  assert_eq(ht.get(3), Some(3))
  assert_eq(ht.get(4), Some(4))
  assert_eq(ht.get(5), Some(5))
  assert_eq(ht.size, 5)
}

test "hash table open addressing: wraparound" {
  let ht : HT_open[Int, String] = HT_open::make(5)

  // Fill the table in a way that requires wraparound
  ht.put(4, "four")  // Goes to index 4
  ht.put(9, "nine")  // 9 % 5 = 4, conflicts, goes to 0 (wraparound)

  assert_eq(ht.get(4), Some("four"))
  assert_eq(ht.get(9), Some("nine"))
}

---
marp: false
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
headingDivider: 1
---

# Modern Programming Ideology

## HashMap and Closure

### Hongbo Zhang

# Review

- Map
  - A collection of key-value pairs, where the each key is unique.
  - Simple implementation: list of tuples:
    - Add to the head of the list.
    - Traverse from the head to query.
  - Tree implementation: balanced binary tree:
    - Modify based on the balanced binary tree introduced in Lecture 5, each node now stores key-value pair.
    - Compare with the first parameter in the key-value pair for tree operations.

# HashMap

- Hash function:
  - Mapping data of arbitrary size to fixed-size values.
  - The `Hash` interface in MoonBit maps data to values in the range of integers  
    - `trait Hash { hash(Self) -> Int }`
    - `"ThisIsAVeryVeryLongString".hash() == -321605584`
- HashMap:
  - Using hash functions to map data to indices in an array, providing efficient data access and manipulation (adding and updating data).
    
    ```moonbit
    // For a: Array[(Key, Value)], key: Key, value: Value
    let index = key.hash().mod_u(a.length()) // key value--hashing-->hash value--modulo operation-->index in array
    a[ index ] = value // add or update data
    let value = a[ index ] // query data
    ```
    
  - Ideally, operations are all in constant time (the balanced binary tree operations are in logarithmic time).

# Hash Collision

- According to the pigeonhole principle/birthday problem:
  - Different pieces of data may have the same hash value.
  - Different hashe values may be mapped to the same index in array.
- Collision Handling in HashMap:
  - Direct Addressing (separate chaining): use another data structure to store items when multiple items are hashed into the same index.
    - Linked Lists
    - Balanced Binary Search Trees, etc.

# Hash Collision

- Collision Handling in HashMap:
  - Direct Addressing (separate chaining): use another data structure to store items when multiple items are hashed into the same index.
    - Linked Lists
    - Balanced Binary Search Trees, etc.

- Open Addressing:

  - Linear Probing: mitigate collision by incrementing the index to find the next empty slot to store the item.

  - Quadratic Probing(incrementing index by $1^2$ $2^2$ $3^2$) etc.

# HashMap Based on Direct Addressing

- When a hash/index collision occurs, store the data of same index into some data structure.
  - For example: Adding 0 and 5 (with hash values of 0 and 5 respectively) into an array of length 5:
    ![](../pics/separate_chaining.drawio.svg)

# HashMap Based on Direct Addressing

- Structure of HashMap:

```moonbit
struct Entry[K, V] { // Struct for key-value pair storage
  key : K
  mut value : V // In-place update enabled
}

struct Bucket[V] { // Collection that can store key-value pairs
  mut val : Option[(V, Bucket[V])] // In-place addition, removal enabled
}

struct HT_bucket[K, V] {
  mut values : Array[Bucket[Entry[K, V]]] // List of key-value pairs, array of lists
  mut length : Int // Length of array dynamically maintained
  mut size : Int // Number of key-value pairs in the HashMap dynamically maintained
}
```

# HashMap Based on Direct Addressing

- Add/Update Operation:
  - To add, first calculate which position to store the key based on its hash value.
  - Then perform key lookup by traversing the collection:
    - If key exists, update the value.
    - Else, add the key-value pair.
- Similar case for the remove operation.

    ![height:200px](../pics/separate_chaining_op_en.drawio.svg)

# HashMap Based on Direct Addressing

- Add/Update Operation: 

```moonbit
fn put[K : Hash + Eq, V](map : HT_bucket[K, V], key : K, value : V) -> Unit {
  let index = key.hash().mod_u(map.length) // Calculate the index
  let mut bucket = map.values[index] // Get the corresponding data structure
  while true {
    match bucket.val {
      None => { // If doesn't exist, add and exit loop
        bucket.val = Some({ key, value }, { val: None })
        map.size = map.size + 1
        break
      }
      Some(entry, rest) => {
        if entry.key == key { // If exists, update the value
          entry.value = value
          break
        } else { // Otherwise, update bucket so the loop terminates
          bucket = rest
  } } } }
  if map.size.to_double() / map.length.to_double() >= load { // Resize according to the load factor
    resize()
  }
}
```

# HashMap Based on Direct Addressing

- Although we won't run out of space with the current array, resize operation is still needed.
- Load factor: the ratio of the number of key-value pairs to the length of the array.
  - Higher load factor means more collisions, longer linked lists, and slower CRUD operations.
  - Solution: If the load factor exceeds a the threshold, reallocate a larger array.
    - Threshold too high: slower traversal.
    - Threshold too low: slower resizing.

# HashMap Based on Direct Addressing

- Remove Operation:

```moonbit
fn remove[K : Hash + Eq, V](map : HT_bucket[K, V], key : K) -> Unit {
  let index = key.hash().mod_u(map.length) // Calculate the index
  let mut bucket = map.values[index] // Get the corresponding data 
  while true {
    match bucket.val {
      None => break // Exit after finishing traversal
      Some(entry, rest) => {
        if entry.key == key { // Remove if exists
          bucket.val = rest.val // { Some(entry, { val }) } -> { val }
          map.size = map.size - 1
          break
        }
        else { // Otherwise, continue traversal
          bucket = rest
  } } } } }
```

# HashMap Based on Open Addressing

- Linear Probing: Under hash collision, keep incrementing the index to find the next empty slot to place the collided key.
  - Invariant: No empty slot between the originally intended slot and the slot where the key-value pair is actually stored.

    - Else, traverse the whole HashMap to check if the key exists.

      ![height:300px](../pics/open_address_en.drawio.svg)


# HashMap Based on Open Addressing

-  Structure definition of HashMap:
  - Here we use an array with default values. Feel free to try and implement it using `Option` as well. 
```moonbit
struct Entry[K, V] { // Struct for key-value pair storage
  key : K
  mut value : V // In-place update enabled
} derive(Default)

struct HT_open[K, V] {
  mut values : Array[Entry[K, V]] // Array of key-value pairs
  mut occupied : Array[Bool] //  Array denoting whether the current slot is empty
  mut length : Int // Length of array dynamically maintained
  mut size : Int // Number of key-value pairs in the HashMap dynamically maintained
}
```

# HashMap Based on Open Addressing

- Add/Update Operation: 
  - Calculate the index to add/update data based on the hash of the key.
  - If the slot is not empty: 
    - If it's the same key, update the value.
    - Else, keep probing.
  - Store the key-value pair when an empty slot occurs.
- We assume empty slot exists.

# HashMap Based on Open Addressing

- Helper method to check if a key already exists:
  - If so, return its index. 
  - Else, return the index of the next empty slot.

```moonbit
// Probe to the right of the index of the original hash, return the index of the first empty slot
fn find_slot[K : Hash + Eq, V](map : HT_open[K, V], key : K) -> Int {
  let hash = key.hash() // Hash value of the key
  let mut i = hash.mod_u(map.length) // Index to be stored at if there's no hash collision
  while map.occupied[i], i = (i + 1).mod_u(map.length) {
    if map.values[i].key == key { // If a key already exists, return its index
      return i
    }
  }
  return i // Otherwise, return when an empty slot occurs
}
```

# HashMap Based on Open Addressing

- Add/Update Operation: 

```moonbit
fn put[K : Hash + Eq + Default, V : Default](map : HT_open[K, V], key : K, value : V) -> Unit {
  let index = find_slot(map, key) // Use helper method to look up the key
  if map.occupied[index] { // Check for key or empty slot
    map.values[index].value = value // Update if the key already exists
  } else { // Otherwise, add the key-value pair into the empty slot
    map.occupied[index] = true
    map.values[index] = { key, value }
    map.size = map.size + 1
  }
  // Check the load factor to determine if resizing is needed
  if map.size.to_double() / map.length.to_double() >= 0.75 {
    resize(map) // fn resize(map) -> Unit
  }
}
```


# HashMap Based on Open Addressing

- Invariant for remove operation: No empty slot between the originally intended slot and the slot where the key-value pair is actually stored.
![height:320px](../pics/open_address_delete_en.drawio.svg)
- Solution: 
  - Mark the slot as "deleted", and treat as if it still contains data during lookup.
  - Rearrange the elements in HashMap.

# HashMap Based on Open Addressing

-  For data removal, mark the slot as "deleted".

```moonbit
enum Status {
  Empty
  Deleted // Add the "deleted status
  Occupied
}

struct HT_open[K, V] {
  mut values : Array[Entry[K, V]]
  mut occupied : Array[Status] // Change from boolean to Status
  mut length : Int
  mut size : Int
}
```

# HashMap Based on Open Addressing

- During key or empty slot lookup, record the first empty slot occurred：denoted by status`Empty` or `Deleted`
  - We still need to find the next `Empty` slot to determine that the key does not exist.

```moonbit
// Probe to the right of the index of the original hash, return the index of the first empty slot
fn find_slot[K : Hash + Eq, V](map : HT_open[K, V], key : K) -> Int {
  let index = key.hash().mod_u(map.length)
  let mut i = index
  let mut empty = -1 // Record the first empty slot occurred: status Empty or Deleted
  while (map.occupied[i] === Empty).not(), i = (i + 1).mod_u(map.length) {
    if map.values[i].key == key {
      return i
    }
    if map.occupied[i] === Deleted && empty != -1 { // Update empty slot
      empty = i
    }
  }
  return if empty == -1 { i } else { empty } // Return the first empty slot
}
```

# HashMap Based on Open Addressing

- For removal, we only need to update the status indicator:
  ```moonbit
  fn remove[K : Hash + Eq + Default, V : Default](map : HT_open[K, V], key : K) -> Unit {
    let index = find_slot(map, key)
    if map.occupied[index] === Occupied {
      map.values[index] = default()
      map.occupied[index] = Deleted
      map.size = map.size - 1
    }
  }
  ```

- Using the `Deleted` status:
  - Extra lookup time after multiple additions and removals as there will be many `Deleted` slots.
  - Need to rearrange the elements afterwards.

# HashMap Based on Open Addressing

- Another implementation of  open addressing: compress after removal
  - Maintain the invariant by moving elements, instead of marking status.
  - Fill in the empty slots after removing the element.
  ![](../pics/rearrange_en.drawio.svg)

# HashMap Based on Open Addressing

![](../pics/rearrange_2_en.drawio.svg)

# Closure

- Closure: the combination of a function bundled together with references to its surrounding state (the lexical environment).
- Surrounding State of Closure:
  - Lexical Environment:  Refer to the program structure, and determined at code definition.
  ```moonbit
  fn init {
    let mut i = 2
    fn debug_i() { debug(i) } // Capturing i
    i = 3
    debug_i() // Output 3
    {
      let i = 4 // A different i variable
      debug_i() // Output 3
    }
  }
  ```

# Closure: Data Encapsulation

- We can use closures to encapsulate data and behavior:
  - Users can't directly access the data, but to use the provided functions instead.
  -  Restrict user operations, conduct parameter validation etc., to ensure data integrity.

```moonbit
fn natural_number_get_and_set()
  -> ( () -> Int, (Int) -> Unit) { // (get, set)
  let mut i = 0 // Does not have direct access
  fn get() -> Int { i }
  fn set(new_value: Int) -> Unit { if new_value >= 0 { i = new_value } } // Can add data validation
  (get, set)
}

fn init {
  let (get, set) = natural_number_get_and_set()
  set(10)
  debug(get()) // 10
  set(-100)
  debug(get()) // 10
}
```

# Closure: Data Encapsulation

- We can use closure + struct to hide the underlying data structure from users.

```moonbit
struct Map[K, V] {
  get : (K) -> Option[V]
  put : (K, V) -> Unit
  remove : (K) -> Unit
  size : () -> Int
}

// Implementation of open addressing
fn Map::hash_open_address[K : Hash + Eq + Default, V : Default]() -> Map[K, V] { ... }
// Implementation of direct addressing
fn Map::hash_bucket[K : Hash + Eq, V]() -> Map[K, V] { ... }
// Implementation with simple list or tree, etc.

fn init {
  let map : Map[Int, Int] = Map::hash_bucket() // Replace the initialization function only, and keep the subsequent code unchanged
  // let map : Map[Int, Int] = Map::hash_open_address()
  (map.put)(1, 1)
  debug((map.size)())
}
```

# Closure: Data Encapsulation

```moonbit
fn Map::hash_bucket[K : Hash + Eq, V]() -> Map[K, V] {
  let initial_length = 10
  let load = 0.75
  let map = {
    values: Array::make(initial_length, { val : None }), // Aliasing
    size: 0,
    length: initial_length,
  }
  fn initialize() { ... } // Initialize the arrays one by one
  initialize()

  fn resize() { ... }

  fn get(key : K) -> Option[V] { ... }
  fn put(key : K, value : V) -> Unit { ... }
  fn remove(key : K) -> Unit { ... }
  fn size() -> Int { map.size }

  { get, put, remove, size }
}
```

# Closure: Data Encapsulation

- We can build more methods upon the struct for convenience.

```moonbit
fn Map::is_empty[K, V](map : Map[K, V]) -> Bool {
  (map.size)() == 0
}

fn Map::contains[K, V](map : Map[K, V], key : K) -> Bool {
  match (map.get)(key) {
    Some(_) => true
    None => false
  }
}

fn init {
  let map : Map[Int, Int] = Map::hash_bucket()
  debug(map.is_empty()) // true
  debug(map.contains(1)) // false
}
```

# Summary

- In this section we introduced
  - Two ways to implement HashMap
    - Direct Addressing
    - Open Addressing
  - The concept of closure and its application
- Recommended Readings
  - Introduction to Algorithms, Chapter 11, or
  - Algorithms, Section 3.4

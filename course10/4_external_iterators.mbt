// Part 3: External iterators with closures
// Code separator: ///|

// List definition for examples
///|
priv enum List[T] {
  Nil
  Cons(T, List[T])
}

// Internal iterator (for comparison)
///|
fn[T] List::each(self : List[T], f : (T) -> Unit) -> Unit {
  match self {
    Nil => ()
    Cons(head, tail) => {
      f(head)
      tail.each(f)
    }
  }
}

// Create external iterator from a list
///|
fn[T] List::iterator(self : List[T]) -> Iterator[T] {
  let mut current = self // Captured mutable state

  fn next() -> Option[T] {
    match current {
      Nil => None
      Cons(head, tail) => {
        current = tail // Update state for next call
        Some(head)
      }
    }
  }

  Iterator::new(next)
}

// Iterator combinators for external iterators
///|

// Map: transform each element
fn[T, R] Iterator::map(self : Iterator[T], f : (T) -> R) -> Iterator[R] {
  fn next() -> Option[R] {
    match self.next() {
      Some(value) => Some(f(value))
      None => None
    }
  }
  Iterator::new(next)
}

// Filter: keep only elements matching predicate
fn[T] Iterator::filter(self : Iterator[T], pred : (T) -> Bool) -> Iterator[T] {
  fn next() -> Option[T] {
    for {
      match self.next() {
        Some(value) => {
          if pred(value) {
            return Some(value)
          }
          // Continue to next element
        }
        None => return None
      }
    }
    abort("unreachable")
  }
  Iterator::new(next)
}

// Take: take first n elements
fn[T] Iterator::take(self : Iterator[T], n : Int) -> Iterator[T] {
  let mut count = 0

  fn next() -> Option[T] {
    if count < n {
      match self.next() {
        Some(value) => {
          count = count + 1
          Some(value)
        }
        None => None
      }
    } else {
      None
    }
  }
  Iterator::new(next)
}

// Collect iterator into a list
fn[T] Iterator::collect(self : Iterator[T]) -> List[T] {
  fn go(acc : List[T]) -> List[T] {
    match self.next() {
      Some(value) => go(Cons(value, acc))
      None => acc
    }
  }

  // Reverse the accumulated list
  fn reverse(list : List[T]) -> List[T] {
    fn rev_helper(l : List[T], acc : List[T]) -> List[T] {
      match l {
        Nil => acc
        Cons(h, t) => rev_helper(t, Cons(h, acc))
      }
    }
    rev_helper(list, Nil)
  }

  reverse(go(Nil))
}

// Count elements
fn[T] Iterator::count(self : Iterator[T]) -> Int {
  let mut n = 0
  while self.next() is Some(_) {
    n = n + 1
  }
  n
}

// Infinite iterators using closures
///|

// Natural numbers: 0, 1, 2, 3, ...
fn naturals() -> Iterator[Int] {
  let mut n = 0

  fn next() -> Option[Int] {
    let current = n
    n = n + 1
    Some(current)
  }

  Iterator::new(next)
}

// Range: from start to end (exclusive)
fn range(start : Int, end : Int) -> Iterator[Int] {
  let mut current = start

  fn next() -> Option[Int] {
    if current < end {
      let value = current
      current = current + 1
      Some(value)
    } else {
      None
    }
  }

  Iterator::new(next)
}

// External iterator for hash table (separate chaining)
///|
priv struct Entry[K, V] {
  key : K
  value : V
}

priv struct Bucket[V] {
  val : Option[(V, Bucket[V])] // Remove mut since we don't use it in iterator
}

priv struct HashTable[K, V] {
  values : Array[Bucket[Entry[K, V]]]
  length : Int
  size : Int
}

fn[K, V] HashTable::iterator(self : HashTable[K, V]) -> Iterator[(K, V)] {
  let mut bucket_index = 0
  let mut current_bucket : Option[Bucket[Entry[K, V]]] = None

  fn next() -> Option[(K, V)] {
    // Try to get next from current bucket
    for {
      match current_bucket {
        Some(bucket) => {
          match bucket.val {
            Some((entry, rest)) => {
              current_bucket = Some(rest)
              return Some((entry.key, entry.value))
            }
            None => {
              // Current bucket exhausted, move to next
              current_bucket = None
              continue  // Loop back to check None branch
            }
          }
        }
        None => {
          // Find next non-empty bucket
          while bucket_index < self.length {
            let bucket = self.values[bucket_index]
            bucket_index = bucket_index + 1

            match bucket.val {
              Some(_) => {
                current_bucket = Some(bucket)
                break
              }
              None => continue
            }
          }

          // No more buckets
          if current_bucket is None {
            return None
          }
          // Found a new bucket, loop back to process it
          continue
        }
      }
    }
    abort("unreachable")
  }

  Iterator::new(next)
}

// Tests
///|
test "external iterator: basic list iteration" {
  let list = Cons(1, Cons(2, Cons(3, Nil)))
  let iter = list.iterator()
  inspect(iter.next(), content="Some(1)")
  inspect(iter.next(), content="Some(2)")
  inspect(iter.next(), content="Some(3)")
  inspect(iter.next(), content="None")
  inspect(iter.next(), content="None")
}

///|
///|
test "external iterator: map" {
  let list = Cons(1, Cons(2, Cons(3, Nil)))
  let iter = list.iterator().map(fn(x) { x * 2 })
  inspect(iter, content="[2, 4, 6]")
}

test "external iterator: filter" {
  let list = Cons(1, Cons(2, Cons(3, Cons(4, Nil))))
  let iter = list.iterator().filter(fn(x) { x % 2 == 0 })

  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(4))
  assert_eq(iter.next(), None)
}

test "external iterator: take" {
  let iter = naturals().take(5)

  assert_eq(iter.next(), Some(0))
  assert_eq(iter.next(), Some(1))
  assert_eq(iter.next(), Some(2))
  assert_eq(iter.next(), Some(3))
  assert_eq(iter.next(), Some(4))
  assert_eq(iter.next(), None)
}

test "external iterator: chaining operations" {
  let list = Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))
  let result = list.iterator()
    .filter(fn(x) { x > 2 })
    .map(fn(x) { x * 10 })
    .take(2)
    .collect()

  match result {
    Cons(a, Cons(b, Nil)) => {
      assert_eq(a, 30)
      assert_eq(b, 40)
    }
    _ => abort("unexpected result")
  }
}

test "external iterator: count" {
  let list = Cons(1, Cons(2, Cons(3, Nil)))
  assert_eq(list.iterator().count(), 3)
}

test "external iterator: range" {
  let iter = range(5, 8)
  assert_eq(iter.next(), Some(5))
  assert_eq(iter.next(), Some(6))
  assert_eq(iter.next(), Some(7))
  assert_eq(iter.next(), None)
}

test "external iterator: early termination" {
  let list = Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil)))))
  let iter = list.iterator()

  // Only consume first 2 elements
  assert_eq(iter.next(), Some(1))
  assert_eq(iter.next(), Some(2))
  // Stop here - remaining elements not consumed
}

test "comparison: internal vs external iterator" {
  let list = Cons(1, Cons(2, Cons(3, Nil)))

  // Internal iterator: must process all elements
  let mut sum_internal = 0
  list.each(fn(x) { sum_internal = sum_internal + x })
  assert_eq(sum_internal, 6)

  // External iterator: can stop early
  let iter = list.iterator()
  let mut sum_external = 0
  while iter.next() is Some(x) {
    sum_external = sum_external + x
    if sum_external >= 3 {
      break // Can stop early!
    }
  }
  assert_eq(sum_external, 3) // Stopped after 1 + 2
}

test {
  let first_five = naturals().take(5)
  inspect(first_five, content="[0, 1, 2, 3, 4]")
}
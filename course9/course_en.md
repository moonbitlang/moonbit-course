---
marp: true
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
---

<!--
```moonbit
enum Tree[T] {
  Empty
  Node(T, Tree[T], Tree[T])
}

struct Queue[T] {
  mut array: Array[T]
  mut start: Int
  mut end: Int
  mut length: Int
}
```
-->

# Programming with MoonBit: A Modern Approach


## Traits

### MoonBit Open Course Team

---

# Recapitulation

- Balanced Binary Search Trees (Chapter 6)
  - Define a more general balanced BST, capable of storing various data types.
  ```moonbit no-check
  enum Tree[T] {
    Empty
    Node(T, Tree[T], Tree[T])
  }

  // We need a comparison function to determine the order of values
  // -1: less than; 0: equal to; 1: greater than
  fn insert[T](self: Tree[T], value: T, compare: (T, T) -> Int) -> Tree[T]
  fn delete[T](self: Tree[T], value: T, compare: (T, T) -> Int) -> Tree[T]
  ```
- Circular Queues (Chapter 8)
  - Initialize the array with the default value of the type.
  ```moonbit no-check
  fn make[T]() -> Queue[T] {
    { array: Array::make(5, T::default()), start: 0, end: 0, length: 0 }
  }
  ```

---

# Methods

Some functions may associate with a type `T`.
- Compare two `T` values: `fn T::compare(self: T, other: T) -> Int`
- Get the default value of `T`: `fn T::default() -> T`
- Get the string representation of a `T` value: `fn T::to_string(self: T) -> String`
- ...

Such functions are called the **methods** of `T`.

---

# Traits

A trait declares a list of methods to be supplied if a type wants to implement it.

```moonbit
trait Compare {
  compare(Self, Self) -> Int
  // `Self` refers to the type that implements the trait.
}
trait Default {
  default() -> Self
}
```

- The trait system in MoonBit is structural.
  - There is no need to implement a trait explicitly.
  - Types with the required methods automatically implements a trait.

---

# Bounded Generics

- In generic functions, we use traits as bounds to specify what methods a type supports.
  - `<type>: <trait>` requires `<type>` to be bound by `<trait>`;
  - The methods of a trait can then be called via `<type>::<method>()`.

```moonbit no-check
fn make[T: Default]() -> Queue[T] { // `T` should support the `default` method.
  { 
    array: Array::make(5, T::default()), // The return type of `default` is `T`.
    start: 0,  end: 0,  length: 0 
  } 
}
```

- With bounds, we can timely detect errors caused by calling missing methods.
![height:150px](../pics/no_method.png)

---

# Bounded Generics

```moonbit
fn insert[T : Compare](tree : Tree[T], value : T) -> Tree[T] {
  // Since `T` is bound by `Compare`, it should support the `compare` method.
  match tree {
    Empty => Node(value, Empty, Empty) 
    Node(v, left, right) =>  
      if T::compare(value, v) == 0 { // We can call `compare` here.
        tree
      } else if T::compare(value, v) < 0 { // We can call `compare` here.
        Node(v, insert(left, value), right)
      } else {
        Node(v, left, insert(right, value))
      }
  }
}
```

---

# Implicit Implementation of Traits

- To implement a trait, we only need to define the corresponding methods.
- Methods can be defined using the syntax `fn <type>::<method>(...) -> ...`.

```moonbit
struct BoxedInt { value : Int }

fn BoxedInt::default() -> BoxedInt {
  // By defining the `default` method, the `Default` trait is now implemented.
  { value : Int::default() }
  // The default value can be defined by boxing the default value of `Int`.
}
```
```moonbit no-check
fn init {
  let array: Queue[BoxedInt] = make()
}
```

---

# Explicit Implementation of Traits

```moonbit no-check
// Provide a default implementation for method `method` of trait `Trait`
impl Trait with method(...) { ... }

// Implement method method of trait `Trait` for type `Type`
impl Trait for Type with method(...) { ... }

// With type parameters
impl[X] Trait for Array[X] with method(...) { ... }
```

The syntax allows explicit specification of the implementing type, providing richer and clearer signature information.

---

# Explicit Implementation of Traits

The compiler can automatically infer the method's parameter and return types, eliminating the need for manual annotations.

```moonbit
trait MyTrait {
  f(Self) -> Option[Int]
}

// No need to annotate `self` and the return type
impl MyTrait for Int with f(self) {
  // Compiler can automatically infer that the return type is `Option[Int]`
  Some(self)
}
```

---

# Method Chaining

- In addition to `<type>::<method>(<expr>, ...)`, we can as well call the method using `<expr>.<method>(...)`, given `<expr>` is of type `<type>`.

```moonbit
fn BoxedInt::plus_one(b: BoxedInt) -> BoxedInt {
  { value : b.value + 1 }
}
// `<type>::` can be omitted when the first parameter is named `self`.
fn plus_two(self: BoxedInt) -> BoxedInt {
  { value : self.value + 2}
}

fn init {
  let _five = { value: 1 }.plus_one().plus_one().plus_two()
  // This avoids multiple nesting of method calls.
  let _five = plus_two(plus_one(plus_one({value: 1})))
}
```

---

# Automatic Derivation of Builtin Traits

- Some simple builtin traits can be automatically derived by adding `derive(<traits>)` after the type definition.

```moonbit no-check
struct BoxedInt { value : Int } derive(Default, Eq, Compare, Debug)
```

- The member data types should have implemented the same traits.

---

# Using Traits to Implement a Map

- A map is a collection of key-value pairs.
  - Each **key** is associated with a **value**.
  - Example: `{ 0 -> "a", 5 -> "Hello", 7 -> "a"}`.

```moonbit no-check
type Map[Key, Value]

// Create a map
fn make[Key, Value]() -> Map[Key, Value]
// Add a key-value pair, or update the corresponding value of a key
fn put[Key, Value](map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value]
// Get the corresponding value of a key
fn get[Key, Value](map: Map[Key, Value], key: Key) -> Option[Value]
```

---

# Using Traits to Implement a Map

- A simple implementation:
  - Store key-value pairs using a list of pairs.
  - Add/update a key-value pair by inserting the pair to the beginning of the list.
  - Search the list from the beginning until the first matching key is found.
- We need to compare the key we are looking for with the keys stored in the list.
  - The `Key` type should implement the `Eq` trait.
  ```moonbit no-check
  fn get[Key: Eq, Value](map: Map[Key, Value], key: Key) -> Option[Value]
  ```

---

# Using Traits to Implement a Map

- Store key-value pairs using a list of pairs.
```moonbit
// Define `Map[Key, Value]` to be `List[(Key, Value)]`
type Map[Key, Value] List[(Key, Value)]

fn make[Key, Value]() -> Map[Key, Value] { 
  Map(Nil)
}

fn put[Key, Value](map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] { 
  let Map(original_map) = map
  Map( Cons( (key, value), original_map ) )
}
```

---

# Using Traits to Implement a Map

- Store key-value pairs using a list of pairs.
```moonbit
fn get[Key: Eq, Value](map : Map[Key, Value], key : Key) -> Option[Value] {
  loop map.0 {
    Nil => None
    Cons((k, v), tl) => if k == key {
      // `Key` is bound by `Eq`, so we can call `==` directly.
      Some(v)
    } else {
      continue tl
    }
  }
}
```

---

# Custom Operators

- Operators can be customized by defining methods with specific names and types.

```moonbit
fn BoxedInt::op_equal(i: BoxedInt, j: BoxedInt) -> Bool {
  i.value == j.value
}
fn BoxedInt::op_add(i: BoxedInt, j: BoxedInt) -> BoxedInt {
  { value: i.value + j.value }
}

fn init {
  let _ = { value: 10 } == { value: 100 } // false
  let _ = { value: 10 } + { value: 100 } // { value: 110 }
}
```

---

# Custom Operators

- Operators can be customized by defining methods with specific names and types.

```moonbit
// map [ key ]
fn Map::op_get[Key: Eq, Value](map: Map[Key, Value], key: Key) -> Option[Value] {
  get(map, key)
}
// map [ key ] = value
fn Map::op_set[Key: Eq, Value](map: Map[Key, Value], key: Key, value: Value) -> Map[Key, Value] {
  put(map, key, value)
}

fn init {
  let empty: Map[Int, Int] = make()
  let one = { empty[1] = 1 } // let one = Map::op_set(empty, 1, 1)
  let _ = one[1] // let _ = Map::op_get(one, 1)
}
```

---

# Summary

- In this chapter, we learned how to
  - Define traits and use them to bound type parameters
  - Implement traits implicitly or explicitly
  - Implement custom operators
  - Implement a simple map using traits in MoonBit
---
marp: true
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
style: |
    ol > li {
        list-style-type:decimal
    }
---

# Modern Programming Ideology

## Functions, Lists & Recursions

### MoonBit Open Course Team

<!--
```moonbit
let pi = 3.1415

fn put(map: @map.Map[Int, Int64], num: Int, result: Int64) -> @map.Map[Int, Int64] {
  map.insert(num, result)
}

fn get(map: @map.Map[Int, Int64], num: Int) -> Option[Int64] {
  map.lookup(num)
}

fn make() -> @map.Map[Int, Int64] {
  @map.empty()
}

```
-->

---

# Basic Data Type: Functions

---

# Functions

- In mathematics: mapping relationships between sets.
  - A function maps each element in the domain to one element in the codomain.
- In computer science: an abstraction of repeated operations.
  - The use of functions can reduce duplication of code.
  - The area of ​​a circle with $r = 1$: `3.1415 * 1 * 1`
  - The area of ​​a circle with $r = 2$: `3.1415 * 2 * 2`
  - The area of ​​a circle with $r = 3$: `3.1415 * 3 * 3`
  - ...
  - `fn area(radius: Double) -> Double { 3.1415 * radius * radius }`

---

# Functions

- Calculate the area of ​​three circles with different radii:
```moonbit expr
let surface_r_1: Double = { let r = 1.0; pi * r * r }
let surface_r_2: Double = { let r = 2.0; pi * r * r }
let surface_r_3: Double = { let r = 3.0; pi * r * r }
let result = (surface_r_1, surface_r_2, surface_r_3)
```

- Use of functions to reduce duplication of code:
```moonbit expr
fn area(radius: Double) -> Double { pi * radius * radius }
let result = (area(1.0), area(2.0), area(3.0))
```

---

# Definition of Top-Level Functions

```
fn <func name> (<param name>: <type>, <param name>: <type>, ...) -> <type> <expr block>
```

Function interface enables one to use a function without knowing its implementation.

```moonbit expr
fn one () -> Int {
  1
}

fn add_char(ch: Char, str: String) -> String { 
  ch.to_string() + str 
}
```

---

# Function Application and Evaluation

- If a function is defined, it can be applied with `<func name>(<expr>, <expr>...)`
   - `one()`
   - `add_char('m', "oonbit")`
   - When applying a function, it is important to ensure that the number of parameters and their types align with the function definition.
     Type Mismatch: `add_char("oonbit", 'm')`
- Steps to evaluate a function application:
   - Evaluate the parameters **from left to right**
   - Replace the occurrences of the parameters with their values
   - Reduce the expressions in the function body

---

# Function Application and Evaluation

```moonbit expr
fn add_char(ch: Char, str: String) -> String { 
  ch.to_string() + str 
}

let moonbit: String = add_char(Char::from_int(109), "oonbit")
```

$$\begin{aligned}
  & \texttt{add\_char(Char::from\_int(109), "oonbit")} \\
  \mapsto & \texttt{add\_char('m', "oonbit")} & \text{because \texttt{Char::from\_int(109)} $\mapsto$ \texttt{'m'}} \\
  \mapsto & \texttt{'m'.to\_string() + "oonbit"} & \text{replace the occurrences of the parameters} \\
  \mapsto & \texttt{"m" + "oonbit"} & \text{because \texttt{m.to\_string()} $\mapsto$ \texttt{"m"}} \\
  \mapsto & \texttt{"moonbit"} & \text{because \texttt{"m" + "oonbit"} $\mapsto$ \texttt{"moonbit"}}
\end{aligned}$$

---

# Partial Functions

Some functions are referred to as **partial functions** as they may not define an output for every possible input in the domain.

```moonbit expr
let ch: Char = Char::from_int(-1) // Invalid: -1 does not correspond to a character.
let nan: Int = 1 / 0 // Forbidden: It will cause an runtime error.
```

Other functions that do define an output for every input are called **total functions**.

To prevent program termination caused by forbidden operations and to distinguish between valid and invalid inputs, the `Option[T]` data type is employed.

---

# Definition of the Option Type

A value of type `Option[T]` falls into one of the two cases:
- `None`: the absence of a value.
- `Some(value: T)`: the presence of a value of type `T`.

For example, we can define a total function for integer division using the option type:
```moonbit expr
fn div(a: Int, b: Int) -> Option[Int] {
  if b == 0 { None } else { Some(a / b) }
}
```

In `Option[T]`, the notation `[T]` indicates that `Option` is a generic type, and the value it holds is of type `T`. For example:
- `Option[Int]`: it can either hold a value of type `Int` or it can be empty.

We will explore how to extract the value from `Some` shortly.

---

# Definition of Local Functions

<style scoped>
    .two-columns { columns: 2; }
</style>

<div class="two-columns">
In most cases, the type and return type of a local function can be omitted, and even its name can also be omitted.

In MoonBit, functions are considered "first-class citizens", i.e., they can be used as parameters, return values, and can also be assigned or stored.

```moonbit expr
let answer: () -> Int = fn () {
  fn real_answer(i) {
    42
  }
  real_answer("Ultimate Question")
}

let x: Int = answer() // 42
```

![height:70px](../pics/func_without_parameter_type.png)
</div>

---

# Function Types

`(<param type>, <param type>, <param type>, ...) -> <return type>`

- `() -> Int`
- `(Int, String, Char) -> Int`
- `((Int, Int, Int)) -> (Int, Int, Int)` accepts a tuple and returns a tuple

---

# Data Structure: Lists

---

# List: A Sequence of Data

- Sometimes, we have data with the following characteristics:
    - The data is ordered.
    - The data can be duplicated.
    - The data can vary in length.
- For example:
    - Words in a sentence: [ `"Words"` `"in"` `"a"` `"sentence"` ]
    - DNA sequence: [`G` `A` `T` `T` `A` `C` `A`]
    - ...

---

# List Interfaces

Taking a single-ended immutable integer list `IntList` as an example, the following operations should be supported:
- Construction
  - `nil : () -> IntList`: construct an empty list
  - `cons : (Int, IntList) -> IntList`: add a new item into the list
- Deconstruction
  - `head_opt : IntList -> Option[Int]`: get the first item
  - `tail : IntList -> IntList`: get the rest items

---

# List Interfaces

Test cases:

```moonbit no-check
let empty_list: IntList = nil()
@assertion.assert_eq(head_opt(empty_list), None)?
@assertion.assert_eq(tail(empty_list), empty_list)?

let list1: IntList = cons(1, empty_list)
@assertion.assert_eq(head_opt(list1), Some(1))?
@assertion.assert_eq(tail(list1), empty_list)?

let list2: IntList = cons(2, list1)
@assertion.assert_eq(head_opt(list2), Some(2))?
@assertion.assert_eq(tail(list2), list1)?
```

---

# List in MoonBit

- In the standard library of MoonBit, the list type is defined as:
```moonbit
enum List[T] {
  Nil // an empty list, or
  Cons(T, List[T]) // an item of type T and a sublist whose items are also of type T
}
```
- Syntactic sugar: `List::[1, 2, 3] == Cons(1, Cons(2, Cons(3, Nil)))`

- The definition of `List[T]` is inductive:
  - Base case: `Nil`
  - Inductive case: `Cons`

![](../pics/list.drawio.png)

---

# Examples

- The following are valid lists:
    - `let int_list: List[Int] = Cons(1, Cons(2, Cons(3, Nil)))`
    - `let string_list: List[String] = List::["This", "is", "a", "sentence."]`
- The following are not valid lists:
    - `List::[1, true, 3]`: Items are of different types.
    - `Cons(1, 2)`: `2` itself is not a list.
    - `Cons(1, Cons(Nil, Nil))`: Items are of different types.

---

# List Type is Generic

The list type `List[T]` is also genereic.

- A list of integers is of type `List[Int]`.
- A list of strings is of type `List[String]`.
- A list of floating-point numbers is of type `List[Double]`.

---

# Pattern Matching

We can use pattern matching to examine the internal structure of a list and handle different cases accordingly.

```
match <expr> {
  <pattern 1> => <expr>
  <pattern 2> => <expr>
}
```

Patterns can be defined by the way data is constructed. Identifiers are defined within patterns and their scope is limited to the corresponding expression.

```moonbit
fn head_opt(list: List[Int]) -> Option[Int] {
  match list {
    Nil              => None
    Cons(head, tail) => Some(head)
  }
}
```

---

# Reduction of Pattern Matching Expressions

- Reduce the expression to be matched.
- Try the patterns in a sequential order until a successful match is found.
- Replace the identifiers in the matched case with their corresponding values.
- Reduce the expression of the matched case.

```moonbit expr
fn head_opt(list: List[Int]) -> Option[Int] {
  match list {
    Nil              => None
    Cons(head, tail) => Some(head)
  }
}

let first_elem: Option[Int] = head_opt(Cons(1, Cons(2, Nil)))
```

---

# Reduction of Pattern Matching Expressions

```moonbit expr
head_opt(Cons(1, Cons(2, Nil)))
```
$\mapsto$ (Replace the identifiers in the function body.)
```moonbit expr
match List::Cons(1, Cons(2, Nil)) { 
  Nil              => Option::None
  Cons(head, tail) => Option::Some(head)
}
```
$\mapsto$ `Some(1)` (Perform pattern matching and replace the identifiers in the matched case.)

The last step of reduction is equivalent to:
```moonbit expr
{
  let head = 1
  let tail = List::Cons(2, Nil)
  Option::Some(head)
}
```

---

# Pattern Matching on Options

We can perform pattern matching to extract the value wrapped by `Some`.

```moonbit
fn get_or_else(option_int: Option[Int64], default: Int64) -> Int64 {
  match option_int {
    None        => default
    Some(value) => value
  }
}
```

If we believe that the expression to be matched will not be `None`, we can write a partial function that omits the `None` pattern.
```moonbit expr
fn get(option_int: Option[Int64]) -> Int64 {
  match option_int { // Warning: Partial match
    Some(value) => value
    // If option_int is None, the program will report an error and terminate
  }
}
```

---

# Algorithm: Recursions

---

# Examples

- **G**NU is **N**ot **U**nix
- **W**ine **I**s **N**ot an **E**mulator
- Fibonacci sequence: each number is the sum of the two preceding ones.
- It was a dark and stormy night, and we said to the captain, "Tell us a story!"
  And this is the story the captain told:
  > It was a dark and stormy night, and we said to the captain, "Tell us a story!"
  > And this is the story the captain told:
  > > It was a dark ...

---

# Recursions

- Recursion is the process of breaking down a problem into smaller subproblems that are similar to the original problem but of a **reduced scale**.
  - A recursion should have one or more **base cases**.
  - In the definition of a function, it directly or indirectly calls itself.

```moonbit
fn fib(n: Int) -> Int {
  if n == 1 || n == 2 { 1 } else { fib (n-1) + fib (n-2) }
}
```

```moonbit
fn even(n: Int) -> Bool {
  n == 0 || odd(n - 1)
}
fn odd(n: Int) -> Bool {
  n == 1 || even(n - 1)
}
```

---

# Recursion on Lists

Since lists are recursively defined, they can be manipulated with recursive functions and pattern matching.

> A list can be either
> - `Nil`: an empty list, or
> - `Cons(head, tail)`: an item `head` and a sublist `tail`

```moonbit 
fn length(list: List[Int]) -> Int {
  match list {
    Nil => 0
    Cons(_, tl) => 1 + length(tl)
  }
}
```

---

# Evaluation of Recursive Functions

```moonbit expr
let n = length(Cons(1, Cons(2, Nil)))

fn length(list: List[Int]) -> Int {
  match list {
    Nil => 0
    Cons(_, tl) => 1 + length(tl)
  }
}
```

---

# Evaluation of Recursive Functions

```moonbit expr
length(List::Cons(1, Cons(2, Nil)))
```
$\mapsto$ (Replace the identifiers in the function body.)
```moonbit expr
match List::Cons(1, Cons(2, Nil)) {
  Nil => 0
  Cons(_, tl) => 1 + length(tl) // tl = Cons(2, Nil)
}
```
$\mapsto$ (Perform pattern matching and replace the identifiers in the matched case.)
```moonbit expr
1 + length(List::Cons(2, Nil))
```
$\mapsto$ (Again, replace the identifiers in the function body.)
```moonbit no-check
1 + match List::Cons(2, Nil) { ... }
```

---

# Evaluation of Recursive Functions

```moonbit expr
1 + match List::Cons(2, Nil) {
  Nil => 0
  Cons(_, tl) => 1 + length(tl) // tl = Nil
}
```
$\mapsto$ (Perform pattern matching and replace the identifiers in the matched case.)
```moonbit expr
1 + 1 + length(Nil)
```
...
$\mapsto$ `1 + 1 + 0` $\mapsto$ `2`

---

# Structural Recursions

For recursively-defined data structures, we can:
- Define the operations on the base cases
- Define the operatoins on the recursive cases

```moonbit expr
fn length(list: List[Int]) -> Int {
  match list {
    Nil => 0                      // Base case
    Cons(_, tl) => 1 + length(tl) // Recursive case
  }
}
```

With each recursion, we iterate through the substructure of the original data, and by defining a base case, we can ensure the program terminates.

Usually, we can use mathematical induction to prove that functions defined through structured recursion are correct.

---

# Mathematical Induction: Sublist Length

- Proposition: For any list `a` of length $l_1$, let the length of the sublist `tail(a)` be $l_2$, then it always holds that $l_1 \ge l_2$.

```moonbit
fn tail(list: List[Int]) -> List[Int] {
  match list {
    Nil => Nil
    Cons(_, tail) => tail
  }
}
```

- Proof:
  - If `a` is in the pattern of `Nil`, then the sublist `tail(a) == a`, and both have a length of $0$. Hence, the proposition holds.
  - If `a` is in the pattern of `Cons(head, tail)`, then the sublist `tail(Cons(head, tail)) == tail`. Since $l_1 = l_2 + 1 > l_2$, the proposition holds.
  - By mathematical induction, the original proposition is proven to be true.

---

# Algorithm: Dynamic Programming

---

# Fibonacci Sequence

1, 1, 2, 3, 5, 8, 13, 21 ...

Different algorithms will lead to different efficiency (`num` > 40).

```moonbit expr
// 002_fib.mbt，try.moonbitlang.com
fn fib(num: Int) -> Int {
  if num == 1 || num == 2 { 1 } else { fib(num - 1) + fib(num - 2) }
}

fn fib2(num : Int) -> Int {
  fn aux(n, acc1, acc2) {
    match n {
      0 => acc1
      1 => acc2
      _ => aux(n - 1, acc2, acc1 + acc2)
    }
  }
  aux(num, 0, 1)
}
```

---

# A Naïve Algorithm

```moonbit expr
fn fib(num: Int) -> Int64 {
  if num == 1 || num == 2 { 1L } else { fib(num - 1) + fib(num - 2) }
}
```
![](../pics/fib_simple.drawio.png)

A large number of duplicated subproblems was observed.

---

# Dynamic Programming

- Decompose the problem into smaller subproblems that are similar to the original problem but of a reduced scale.
- Applicable to problems that have:
  - **Duplicated subproblems**: Dynamic programming solves each subproblem once and caches the result, avoiding redundant computations.
  - **Optimal substructure**: The global solution can be built from subproblems.
- Dynamic programming can be implemented top-down or bottom-up:
  - **Top-down**: For each subproblem, if it has already been solved, use the cached result; otherwise, solve it and cache the result.
  - **Bottom-up**: Solve the subproblems first, then calculate the solutions of larger subproblems from the smaller ones.

---

# Solving Fibonacci Sequence with DP

- Dynamic programming is applicable to this problem.
  - Duplicated subproblems: Both `fib(n + 1)` and `fib(n + 2)` require `fib(n)`.
  - Optimal substructure: `fib(n)` is determined by `fib(n - 1)` and `fib(n - 2)`.

![](../pics/fib_unique.drawio.png)

---

# Top-Down Implementation

- We need a data structure whose average access efficiency is independent of the data size, and it should have the following interfaces:

```moonbit no-check
fn make() -> IntMap                                   // Create
fn put(map: IntMap, num: Int, value: Int64) -> IntMap // Store
fn get(map: IntMap, num: Int) -> Option[Int64]        // Retrieve
```

- There are many siutable data structures, e.g., `@map.Map[Int, Int64]`.
  - Its implementation is not our main focus.
  - It can be repleced with other suitable data structures.

---

# Top-Down Implementation

- Before each computation, we first check if our desired result has been cached.
  - If it does, we can simply use the result.
  - If it doesn't, we calculate the result and store it in the data structure.

```moonbit expr
fn fib1(num: Int) -> Int64 {
  fn aux(num: Int, map: @map.Map[Int, Int64]) -> (Int64, @map.Map[Int, Int64]) {
    match get(map, num) {
      Some(result) => (result, map)
      None => {
        let (result_1, map_1) = aux(num - 1, map)
        let (result_2, map_2) = aux(num - 2, map_1)
        (result_1 + result_2, put(map_2, num, result_1 + result_2))
      }
    }
  }
  let map = put(put(make(), 1, 1L), 2, 1L)
  aux(num, map).0
}
```

---

# Mutable Variables

Note that `map` is being updated and passed as an argument repeatedly.
To simplify the code, MoonBit supports mutable variables.

```moonbit expr
fn fib1_mut(num: Int) -> Int64 {
  // Declare a mutable variable with let mut
  let mut map = put(put(make(), 1, 1L), 2, 1L)
  fn aux(num: Int) -> Int64 {
    match get(map, num) {
      Some(result) => result
      None => {
        let result_1 = aux(num - 1)
        let result_2 = aux(num - 2)
        // Update the binding with <variable> = <expression>
        map = put(map, num, result_1 + result_2) 
        result_1 + result_2
      }
    }
  }
  aux(num)
}
```

---

# Bottom-Up Implementation

Starting from the first one, calculate and store the subsequent items sequentially.

```moonbit expr
fn fib2(num: Int) -> Int64 {
  fn aux(n: Int, map: @map.Map[Int, Int64]) -> Int64 {
    let result = get_or_else(get(map, n - 1), 1L) + 
      get_or_else(get(map, n - 2), 1L)
    if n == num { result } 
    else { aux(n + 1, put(map, n, result)) }
  }
  let map = put(put(make(), 0, 0L), 1, 1L)
  aux(1, map)
}
```

---

# Bottom-Up Implementation

- Since we only need the results of the previous two subproblems when computing the current one, we can pass the results directly through the parameters, without the use of additional data structures.

```moonbit expr
fn fib2(num : Int) -> Int64 {
  fn aux(n: Int, acc1: Int64, acc2: Int64) -> Int64 {
    match n {
      0 => acc1
      _ => aux(n - 1, acc2, acc1 + acc2)
    }
  }
  aux(num, 0L, 1L)
}
```

![](../pics/fib_aux.drawio.png)

---

# Summary

- In this module we learned
   - Basic data type: functions and their operations
   - Data structure: lists and pattern matching on lists
   - Algorithm: recursions and dynamic programming
- Extended reading:
   - _**Software Foundations, Volume 1: Logical Foundations**_
     Basics, Induction & Lists
   - _**Programming Language Foundations in Agda**_
     Naturals, Induction & Relations
   - _**Introduction to Algorithms**_
     Chapter 15 (3e) / Chapter 14 (4e) - Dynamic Programming
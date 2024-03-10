# Modern Programming Ideology: Imperative Programming

## Revisiting Functional Programming

The core idea of functional programming is that each input corresponds to a fixed output, and identifiers can be directly substituted with their corresponding values, a property known as referential transparency. However, developing practical programs often requires "side effects" beyond calculations, such as input/output operations and modifying data in memory. These side effects may lead to inconsistent results upon multiple executions, breaking referential transparency.

```moonbit
let x: Int = 1 + 1 // x can be directly replaced with 2
fn square(x: Int) -> Int { x * x }
let z: Int = square(x) // can be replaced with { 2 * 2 }, still resulting in 4
```

## Commands and Side Effects

The `print` command in MoonBit enables us to output strings, such as `print("hello moonbit")`. We can define initialization instructions in the `init` code block, serving as the program entry point. However, output commands may break referential transparency.

```moonbit
fn init {
  let x: Int = {
    println("hello moonbit") // First, execute the command and perform output
    1 + 1 // Then, take the last value of the expression block as the block's value
  }
  let z: Int = square(x) // Output once
}
```

We typically use the unit type `Unit` to represent the return value of functions or commands with side effects. It has only one value: `()`.

## Variables and Aliases

In MoonBit, we can define temporary variables using `let mut`. The assignment operation itself is a command. Struct fields are immutable by default, but we can use `mut` to identify mutable fields, which are treated as references.

```moonbit
struct Ref[T] { mut val : T }

fn init {
  let ref: Ref[Int] = { val: 1 } // ref itself is just a data binding
  ref.val = 10 // We can modify the fields of the struct
  println(ref.val.to_string()) // Output 10
}
```

Multiple identifiers pointing to the same mutable data structure can be considered aliases, which need to be handled carefully.

```moonbit
fn alter(a: Ref[Int], b: Ref[Int]) {
  a.val = 10
  b.val = 20
}

fn init {
  let x: Ref[Int] = { val : 1 }
  alter(x, x)
  println(x.val.to_string()) // x.val will be changed twice
}
```

## Debugger

- Moon Rabbit's debugger allows us to see real-time running data during operation and better understand the running process

![](../pics/debugger.png)

## Loops

We can define loops using variables in MoonBit. A loop includes defining the loop variable and its initial value, checking whether to continue the loop, and iterating the variable.

```moonbit
let mut i = 0
while i < 2 {
  println("Output")
  i += 1
} // Repeat output 2 times
```

The loop execution flow is: check the condition -> execute commands -> iterate the variable -> repeat the above process. MoonBit provides a debugger that enables observing the changes in runtime data during the loop process.

## Loops and Recursion

Loops and recursion are equivalent. A loop can be written in a recursive form. Taking the calculation of the Fibonacci sequence as an example:

```moonbit
// Loop form
fn fib_mut(n: Int) -> Int {
  let mut a = 0;
  let mut b = 1;
  let mut i = 0
  while i < n {
    let t = a + b
    a = b; b = t
    i += 1
  }
  a
}

// Recursive form
fn fib(n: Int) -> Int {
  if n == 0 { 0 }
  else if n == 1 { 1 }
  else { fib(n - 1) + fib(n - 2) }
}
```

## Controlling Loop Flow

Within a loop, we can use `break` to exit the loop prematurely and `continue` to skip the remaining part of the current loop iteration.

```moonbit
fn print_first_3() {
  let mut i = 0
  while i < 10 {
    if i == 3 {
      break // Skip from 3 onwards
    } else {
      println(i.to_string())
    }
    i += 1
  }
}
```

the excepted output is

```
0
1
2
```

if we change `break` to `continue`

```moonbit
fn print_first_3() {
  let mut i = 0
  while i < 10 {
    if i == 3 {
      continue // Skip from 3 onwards
    } else {
      println(i.to_string())
    }
    i += 1
  }
}
```

the program will go into infinite loops, so there will be no output.

## MoonBit Check

MoonBit checks whether a variable is modified, which can help avoid mistakes like forgetting to add an iteration condition in a loop. It also checks if the function's return value type matches the declared type, preventing incorrect type declarations.

## Mutable Data

Mutable data has various applications, such as direct hardware manipulation, performance advantages (e.g., random access arrays), construction of complex data structures, and in-place modification to save space. Mutable data does not always conflict with referential transparency. For example, when calculating the Fibonacci sequence, although mutable data is used, the final result is still fixed for the same input.

## Summary

This chapter introduces the basics of imperative programming, including using commands, variables, and loops. Imperative programming differs inherently from functional programming, and it is essential to understand the advantages and disadvantages of both and use them appropriately.

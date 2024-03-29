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

## Course Introduction & Program Design

### MoonBit Open Course Team

---

# Acknowledgements

The design of this course is inspired by [UPenn CIS 1200](https://www.seas.upenn.edu/~cis120/current/).

---

# What is **Modern Programming Ideology** Course

- This is a course on **program design**.
    - Target audience: all programming enthusiasts.
- Practical techniques
    - Writing large-scale programs (~10,000 LOC).
    - Independent problem analysis and solving.
    - Test-driven development and program design.
- Foundational concepts
    - Basic data structures and algorithms.
    - Various programming paradigms.
    - Principles of modularity and composition.

---

# Our Programming Language and Tools

- MoonBit
    - A modern, statically-typed, **multi-paradigm** programming language
    - with newbie-friendly lightweight syntax
    - supported on multiple kinds of development environments:
        - browsers, cloud-native environments, local IDEs, etc.

---

<style scoped>
    .columns { columns: 2; }
</style>

# Course Outline

<div class="columns">
<div>

| # | Topic |
|-:|:-:|
| 1 | Introduction & Program Design |
| 2 | Dev Environments & Expressions |
| 3 | Functions, Lists & Recursions |
| 4 | Tuples, Structs & Enums |
| 5 | Trees |
| 6 | Generics & Higher-Order Functions |
| 7 | Imperative Programming |
| 8 | Queues |

</div>
<div>

| # | Topic |
|-:|:-:|
| 9 | Traits |
| 10 | Hash Tables & Closures |
| 11 | Case Study: Parsers |
| 12 | Case Study: Autodiff |
| 13 | Case Study: Neural Networks |

- All materials are available online
- Forum: [discuss.moonbitlang.com](https://discuss.moonbitlang.com/)

</div>
</div>

---

# Program Design

---

# Basic Workflow of Program Design

**Program design** is the process of converting informal specifications into a program.

It is recommended to adopt a **test-driven development** (TDD) workflow, namely,

1. **Understand the problem**: What variables are involved and how are they related?
2. **Define the interfaces**: How should the program interact with the environment?
3. **Write the test cases**: What is the expected behavior for normal inputs? What can be the potential abnormal inputs?
4. **Implement the program**: Usually, it is necessary to break down the problem into smaller subproblems and repeat the above process for each of them.

---

# An Example of Program Design

> There are `num_bottles` water bottles that are initially full of water. You can exchange `num_exchange` empty water bottles from the market with one full water bottle.
> The operation of drinking a full water bottle turns it into an empty bottle.
> Given the two integers `num_bottles` and `num_exchange`, return _the **maximum** number of water bottles you can drink_.
> <span style="float:right;">Source: [LeetCode 1518](https://leetcode.com/problems/water-bottles/description/)</span>

---

# Step 1: Understand the Problem

- What variables are involved?
    - $N_\mathrm{bottles}$: The number of _full_ water **bottles** that we currently have.
    - $N_\mathrm{drunk}$: The number of _empty_ water bottles that we have **drunk**.
- How are they related?
    - The initial value for $N_\mathrm{bottles}$ is given by the input.
    - When $N_\mathrm{bottles} \ge$ `num_exchange`, we can drink `num_exchange` of them, exchange them for one full water bottle, and then repeat the process.
    - When $N_\mathrm{bottles} <$ `num_exchange`, we have to drink them up and quit.
- What do we want to calculate?
    - Given `num_bottles` and `num_exchange`, calculate the maximum number of water bottles we can drink.

---

# Step 2: Define the Interfaces

> Given the two integers `num_bottles` and `num_exchange`, return _the **maximum** number of water bottles you can drink_.

```moonbit no-check
fn num_water_bottles(num_bottles: Int, num_exchange: Int) -> Int {
  abort("To be done")
}
```

---

# Step 3: Write the Test Cases

```moonbit
test {
  @assertion.assert_eq(num_water_bottles(9, 3), 13)? // 9 + 3 + 1 = 13
  @assertion.assert_eq(num_water_bottles(15, 4), 19)?
}
```

---

# Step 4: Implement the Program

A sample implementation:

```moonbit
fn num_water_bottles(num_bottles: Int, num_exchange: Int) -> Int {
  fn consume(num_bottles, num_drunk) {
    if num_bottles >= num_exchange {
      let num_bottles = num_bottles - num_exchange + 1
      let num_drunk = num_drunk + num_exchange
      consume(num_bottles, num_drunk)
    } else {
      num_bottles + num_drunk
    }
  }
  consume(num_bottles, 0)
}
// Test cases omitted for brevity.
```

---

# [Let's have a try!](https://try.moonbitlang.com/#bc2238e7)

---

# Quiz

- For some abnormal inputs, the sample program may fail. Can you identify them?
    - Hint: In MoonBit, the range of `Int` values is $-2^{31}$ to $2^{31} - 1$.

---

# Summary

- It is recommended to adopt a **test-driven development** (TDD) workflow, namely,

    1. **Understand the problem**
    2. **Define the interfaces**
    3. **Write the test cases**
    4. **Implement the program**

- Modern software development relies on TDD.
    - Write the test cases at an early stage.
    - Use the test cases to drive the development process.
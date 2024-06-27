---
marp: true
math: mathjax
paginate: true
backgroundImage: url('../pics/background_moonbit.png')
headingDivider: 1
style: |
  .columns {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 1rem;
  }
---

# Modern Programming Ideology

## Case Study: Stack-based Virtual Machine

### Hongbo Zhang

# Compilation and Interpretation

- Compilation
  - Source program × Compiler → Target program
  - Target program × Input data → Output data
- Interpretation
  - Source program × Input data × Interpreter → Output data
  - The CPU can be seen as a generalized interpreter.
- Further Reading: Futamura projection/Partial Computation
  - Partial Computation: Program optimization, specialization of computation based on known information.
  - Given source program and interpreter, perform partial computation to obtain the target program.
    - Target program × Input data → Output data.

# Virtual Machine

- Write once, run everywhere.

  - Define an instruction set not based on any platform.
  - Implement interpreters on different platforms.

- Two Common Types of Virtual Machines
  - Stack-based Virtual Machine
    Operands are stored on a stack, data follows the Last In, First Out (LIFO) principle.
  - Register-based Virtual Machine
    Operands are stored in registers.

# Register-based Virtual Machine

- Example: Lua VM (The Implementation of Lua 5.0)
  Find the maximum value:
  ```
  MOVE   2 0 0 ; R(2) = R(0)
  LT     0 0 1 ; R(0) < R(1)?
  JMP    1     ; JUMP -> 5 (4 + 1)
  MOVE   2 1 0 ; R(2) = R(1)
  RETURN 2 2 0 ; return R(2)
  RETURN 0 1 0 ; return
  ```

# Stack-based Virtual Machine

- Example: WebAssembly Virtual Machine
  Find the maximum value function `max(a : Int, b : Int) -> Int`:
  ```wasm
  local.get $a local.set $m                     ;; let mut m = a
  local.get $a local.get $b i32.lt_s            ;; if a < b {
  if local.get $b local.set $m end              ;; m = b }
  local.get $m                                  ;; m
  ```

# WebAssembly

- What is WebAssembly?
  - A virtual instruction set that can run in browsers and other runtimes (Wasmtime, WAMR, WasmEdge, etc.).
  - The first backend for MoonBit.
- Using a subset of the WebAssembly instruction set.

# Simple Instruction Set

- Data
  - Only considering 32-bit signed integers.
  - Non-zero represents `true`, zero represents `false`.
- Instructions
  - Data operations: `const`, `add`, `minus`, `equal`, `modulo`
  - Data storage: `local.get`, `local.set`
  - Control flow: `if/else`, `call`

# Type Definitions

- Data

```moonbit
enum Value { I32(Int) } // Only considering 32-bit signed integers
```

- Instructions

```moonbit
enum Instruction {
  Const(Int)                           // Constant
  Add; Sub; Modulo; Equal              // Add, Subtract, Modulo, Equal
  Call(String)                         // Function call
  Local_Get(String); Local_Set(String) // Get value, Set value
  If(Int, @immut/list.List[Instruction], @immut/list.List[Instruction]) // Conditional statement
}
```

# Type Definitions

- Functions

```moonbit
struct Function {
  name : String
  // Only considering one data type, so omit the type of each data, only keep the name and quantity
  params : @immut/list.List[String]; result : Int; locals : @immut/list.List[String]
  instructions : @immut/list.List[Instruction]
}
```

- Programs

```moonbit
struct Program {
  functions : @immut/list.List[Function]
  start : Option[String]
}
```

# Simple Calculation

- Example: `1 + 2`

  ```moonbit no-check
  @immut/list.List::[ Const(1), Const(2), Add ]
  ```

  ![](../pics/add.drawio.svg)

# Local Variable Usage

- Example: Function `add(a : Int, b : Int) { a + b }`

  ```moonbit no-check
  @immut/list.List::[ Local_Get("a"), Local_Get("b"), Add ]
  ```

  - Function parameters and local variables can be accessed and modified via `Local_Get` and `Local_Set`.
    ![](../pics/local.drawio.svg)

# Function Calculation

- Example: `add(1, 2)`

  ```moonbit no-check
  Lists::[ Const(1), Const(2), Call("add") ]
  ```

  - Store the number of return values of functions on the stack.
    ![](../pics/call.drawio.svg)

# Function Calculation

- Example: `add(1, 2)`

  ```moonbit no-check
  Lists::[ Const(1), Const(2), Call("add") ]
  ```

  - Store the number of return values of functions on the stack.
    ![](../pics/return.drawio.svg)

# Conditional Jump

- Example: `if 1 == 0 { 1 } else { 0 }`

  ```moonbit no-check
  @immut/list.List::[
  Const(1), Const(0), Equal,
  If(1, @immut/list.List::[Const(1)], @immut/list.List::[Const(0)])
  ]
  ```

  - When executing `If(n, then_block, else_block)`, if the top of the stack is a non-zero integer (true),
    - execute `then_block`.
    - Otherwise, execute `else_block`.
  - `n` represents the number of arguments returned by the code block.

  ![](../pics/if.drawio.svg)

# Example: Addition

```moonbit expr
let program = Program::{

  start: Some("test_add"), // Program entry point

  functions: @immut/list.List::[
    Function::{
      name: "add", // Addition function
      params: @immut/list.List::["a", "b"], result: 1, locals: @immut/list.List::[],
      instructions: @immut/list.List::[Local_Get("a"), Local_Get("b"), Add],
    },
    Function::{
      name: "test_add", // calculate add and output
      params: @immut/list.List::[], result: 0, locals: @immut/list.List::[], // entry function with no input or output
      // “print_int" is a special function
      instructions: @immut/list.List::[Const(0), Const(1), Call("add"), Call("print_int")],
    },
  ],
}
```

# Program Architecture

# Output Program

```wasm
;; Multiple functions
;; WASM itself only defines operations; interaction depends on external functions
(func $print_int (import "spectest" "print_int") (param i32))

(func $add (export "add") ;; Export function to be directly used by runtime
  (param $a i32) (param $b i32) (result i32 ) ;; (a : Int, b : Int) -> Int
  local.get $a local.get $b i32.add ;;

)

(func $test_add (export "test_add") (result ) ;; Entry function with no input or output
  i32.const 0 i32.const 1 call $add call $print_int
)

(start $test_add)
```

# Online Try

- <https://webassembly.github.io/wabt/demo/wat2wasm/>

  ```javascript
  const wasmInstance = new WebAssembly.Instance(wasmModule, {
    spectest: { print_int: console.log },
  });
  ```

  ![height:400px](../pics/wat2wasm.png)

# Constructing a Compiler

| Operation                                   | WebAssembly Operation                              |
| ------------------------------------------- | -------------------------------------------------- |
| `Const(0)`                                  | `i32.const 0`                                      |
| `Add`                                       | `i32.add`                                          |
| `Local_Get("a")`                            | `local.get $a`                                     |
| `Local_Set("a")`                            | `local.set $a`                                     |
| `Call("add")`                               | `call $add`                                        |
| `If(1, @immut/list.List::[Const(0)], @immut/list.List::[Const(1)])` | `if (result i32) i32.const 0 else i32.const 1 end` |

# Compile Program

- Utilize the built-in Buffer data structure for more efficient operation than string concatenation.

  ```moonbit no-check
  fn Instruction::to_wasm(self : Instruction, buffer : Buffer) -> Unit
  fn Function::to_wasm(self : Function, buffer : Buffer) -> Unit
  fn Program::to_wasm(self : Program, buffer : Buffer) -> Unit
  ```

# Compile Instruction

- Utilize the built-in Buffer data structure for more efficient operation than string concatenation.

  ```moonbit
  fn Instruction::to_wasm(self : Instruction, buffer : Buffer) -> Unit {
    match self {
        Add => buffer.write_string("i32.add ")
        Local_Get(val) => buffer.write_string("local.get $" + val + " ")
        _ => buffer.write_string("...")
    }
  }
  ```

# WebAssembly Binary Format

| Text Format   | Binary Format                                          |
| ------------- | ------------------------------------------------------ |
| `i32.const`   | 0x41                                                   |
| `i32.add`     | 0x6A                                                   |
| `local.get`   | 0x20                                                   |
| `local.set`   | 0x21                                                   |
| `call $add`   | 0x10                                                   |
| `if else end` | 0x04 (vec[instructions]) 0x05 (vec[instructions]) 0x0B |

# Multi-Level Compilation

- String → Token Stream → (Abstract Syntax Tree) → WASM IR → Compile/Run

  ```moonbit
  enum Expression {
    Number(Int)
    Plus(Expression, Expression)
    Minus(Expression, Expression)
    Multiply(Expression, Expression)
    Divide(Expression, Expression)
  }
  ```

# Multi-Level Compilation

- String → Token Stream → (Abstract Syntax Tree) → WASM IR → Compile/Run

  ```moonbit no-check
  fn compile_expression(expression : Expression) -> @immut/list.List[Instruction] {
    match expression {
        Number(i) => @immut/list.List::[Const(I32(i))]
        Plus(a, b) => compile_expression(a) + compile_expression(b) + @immut/list.List::[Add]
        Minus(a, b) => compile_expression(a) + compile_expression(b) + @immut/list.List::[Sub]
        _ => @immut/list.List::[]
    }
  }
  ```

# Building an Interpreter

- A Possible Interpreter
- Operand Stack
  - Values involved in computation
  - Local variables before function execution
- Instruction Queue
  - Currently executing instruction
  - Divided into ordinary instructions and - control instructions (such as return at the end of a function)

# Interpreter Structure

```moonbit
enum StackValue {
  Val(Value) // Ordinary value
  Func(@map.Map[String, Value]) // Function stack, stores previous local variables
}

enum AdministrativeInstruction {
  Plain(Instruction) // Ordinary instruction
  EndOfFrame(Int) // Function end instruction
}

struct State {
  program : Program
  stack : @immut/list.List[StackValue]
  locals : @map.Map[String, Value]
  instructions : @immut/list.List[AdministrativeInstruction]
}
```

- State Iteration
  `fn evaluate(state : State, stdout : Buffer) -> Option[State]`

# Interpreter Construction

- Read the current instruction and the top of the stack data

```moonbit
fn evaluate(state : State, stdout : Buffer) -> Option[State] {
  match (state.instructions, state.stack) {
    (Cons(Plain(Add), tl), Cons(Val(I32(b)), Cons(Val(I32(a)), rest))) =>
      Some(
        State::{ ..state, instructions: tl, stack: Cons(Val(I32(a + b)), rest) },
      )
    _ => None
  }
}
```

![](../pics/interp_add.drawio.svg)

# Interpreter Construction

- Conditional judgement, according to the branch to take out the corresponding code

```moonbit no-check
(Cons(Plain(If(_, then, else_)), tl), Cons(Val(I32(i)), rest)) =>
  Some(State::{..state,
      stack: rest,
      instructions: (if i != 0 { then } else { else_ }).map(
        AdministrativeInstruction::Plain,
      ).concat(tl)})
```

![](../pics/interp_if.drawio.svg)

# Interpreter Construction

- Special case for the output function

```moonbit no-check
(Cons(Plain(Call("print_int")), tl), Cons(Val(I32(i)), rest)) => {
  stdout.write_string(i.to_string())
  Some(State::{ ..state, stack: rest, instructions: tl })
}
```

![](../pics/interp_print_int.drawio.svg)

# Interpreter Construction

- For function calls, store the current running state (variables) into the stack

  ![](../pics/interp_call.drawio.svg)

# Interpreter Construction

- After the function execution is completed

  - Take out elements from the top of the stack according to the number of return values
  - Expand the information of the call stack

  ![](../pics/interp_end_call.drawio.svg)

# Summary

- This lesson demonstrated a stack-based virtual machine
  - Introduced a small part of the WebAssembly instruction set
  - Implemented a compiler
  - Implemented an interpreter
- Challenges
  - Extend function definitions in the syntax parser
  - Add an early return instruction (`return`) to the instruction set

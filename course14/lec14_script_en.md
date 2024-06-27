# Case Study: Stack-based Virtual Machine  

Today, we are going to try to implement a simple stack-based virtual machine, taking the backend Wasm used by Moonbit as an example. In the first part, we will introduce what a stack-based virtual machine is and the instructions we are going to implement.

Before explaining the virtual machine, let's explain two concepts: compilation and interpretation. As we all know, the programs we write are in text format. What the computer can really execute are binary formats. So, there is a compilation process in between. Compilation is the use of a compiler to convert the source program, usually the source code, into the target program we want to execute. After that, we can directly execute the binary format of the target program, providing various inputs during its operation, such as command line arguments, command line input, or various files, network resources, to obtain the output we expect. The compiled language you are familiar with may be C language. But sometimes, for some languages, we don't compile and execute directly, but directly input the text format source code to the interpreter, let the interpreter read the program while executing, to get the output we want. Typical ones are generally JavaScript or Python. Broadly speaking, the CPU is also a kind of interpreter.

Let's extend the topic a bit. Interested students can search and learn. In fact, the interpreter and the compiler are not completely separate concepts. We can transform the interpreter into a compiler through a two-way mapping. The concept used here is partial computation, which is a program optimization technique, that is, to specialize the computation based on known information. For an extreme example, if your interpreter is a calculator and your program is an arithmetic expression, then you can use these two pieces of information to directly calculate the value corresponding to the program, thus obtaining a target program. This target program is equivalent to the compiled program, and you only need to input data to get the output program.

In addition to compiling and interpreting execution, another way is to combine the two. A typical example is Java. The Java virtual machine was created to achieve the purpose of writing once and running everywhere, defining an instruction set that is not based on any platform, and then implementing an interpreter on different platforms. So the first step is to compile from the source code to this virtual instruction set, and then the interpreter interprets and executes the instruction set. The interpreter here is also a virtual machine. There are two common types of virtual machines: one is the stack-based virtual machine, where operands are stored on the stack, and data follows the LIFO (Last In First Out) principle. The other is the register-based virtual machine, similar to a normal computer, where operands are stored in registers. The stack-based virtual machine is relatively simple to implement and has a smaller code size, while the register-based virtual machine is closer to the actual computer structure and has higher performance.

example: Lua VM Maximize function(register-based)
```
MOVE   2 0 0 ; R(2) = R(0)
LT     0 0 1 ; R(0) < R(1)?
JMP    1     ; JUMP -> 5 (4 + 1)
MOVE   2 1 0 ; R(2) = R(1)
RETURN 2 2 0 ; return R(2)
RETURN 0 1 0 ; return 
```
example: WASM Maximize function(stack-based)
```wasm
local.get $a local.set $m                     ;; let mut m = a
local.get $a local.get $b i32.lt_s            ;; if a < b {
if local.get $b local.set $m end              ;; m = b }
local.get $m                                  ;; m
```

Now that we have mentioned WebAssembly, let's give it a brief introduction. WebAssembly, as its name suggests, Web+Assembly, is a virtual instruction set. It was initially used on the web and can be used in browsers, but since it is an instruction set, it can be executed on other platforms as long as a virtual machine is implemented, so there are also runtimes like [Wasmtime](https://github.com/bytecodealliance/wasmtime), (WAMR)[https://github.com/bytecodealliance/wasm-micro-runtime], [WasmEdge](https://wasmedge.org/), etc. It is also the first compilation backend of MoonBit. One of its major features is that its instruction set also has a type system, so there is a great guarantee of security. Today we will take a subset of the WebAssembly instruction set as an example.

The data we consider today is only 32-bit signed integers, that is, Int in Moonbit. To meet the needs of control flow, we use non-zero integers to represent true, and zero to represent false. Our instruction set includes: data operations, data storage, and control flow. On the data side, const can define an integer constant, as well as addition, subtraction, equality judgment, and modulo. Data storage includes fetching and storing operations from local parameters. Control flow includes if-else and function calls.

[The definition of types in Moonbit](https://www.moonbitlang.com/docs/syntax#built-in-data-structures) is basically a one-to-one copy: data is defined using an enumeration type, although we only have 32-bit signed integers; instructions, as just introduced, include the definition of constants, addition, modulo, equality, and function calls, local fetching and setting values, all identified by strings. Finally, there is conditional judgment, which includes an integer and two instruction lists. The integer represents how many calculation results will be left after this expression block ends, and the two instruction lists correspond to the situations when the condition is true and false, respectively.

The function type definition includes the function name, input parameters, output parameters, local variables, and the function body. Here, since we only have one data type, we only record their respective names and quantities, without considering the specific corresponding types. A complete program includes multiple functions and an optional function as the program entry point.

Let's take a look at the specific operation process of the stack-based virtual machine. First is numerical calculation. Taking 1+2 as an example, we have a stack, which is initially empty. The first thing we need to do is to add data to the stack. Since it is a constant, we use the constant instruction to add 1 and 2. Then, we use the addition instruction. The addition instruction will take the top two values of the stack, add them together, and store the result back on the top of the stack. So, after the operation is completed, the top element of the stack is 3.

```moonbit no-check
List::[ Const(1), Const(2), Add ]
```

![](../pics/add.drawio.svg)

In addition to directly using the constant instruction for definition, we can also use local variables. These variables come from the function's parameters and some defined temporary variables. For example, in this addition, there are parameters a and b available for us to use. We use the fetch instruction to store the corresponding values on the stack, and then perform the calculation. Each local variable can be modified, and can be done through the Set instruction.

```moonbit no-check
List::[ Local_Get("a"), Local_Get("b"), Add ]
```

![](../pics/local.drawio.svg)

After that, we can also call other functions for calculation. In this example, we use the addition function for calculation. We still put 1 and 2 on the stack. Then, we call the function. At this time, according to the number of function parameters, the corresponding number of elements on the top of the stack will be taken out, bound to local variables in order, and an element representing the function will be added to the stack. This element separates the original stack data from the function's data, and this element will also record the number of function return values. After the function calculation is finished, according to the number of return values, we take out the top elements of the stack, remove the function's element, and then put the top elements back on the top of the stack, so that we get the calculation result at the place where the function is called.


```moonbit no-check
Lists::[ Const(1), Const(2), Call("add") ]
```

![](../pics/return.drawio.svg)

As for conditional branching, as we said before, we use whether the 32-bit integer is non-zero to represent true or false. When we execute the IF statement, we take out the top element of the stack, judge according to its value, if it is true, then execute the then branch, if it is false, then execute the else branch. It is worth noting that each code block in Wasm has parameter types and return value types, specifically referring to the number and type of stack top elements involved in the calculation when entering the code block, and the modification of the stack top elements compared to the original calculation environment when exiting the code block. For example, here, when we enter the conditional judgment code block, there is no input, so we assume that the stack is empty when we perform calculations inside the IF code block, no matter what is on the stack originally, it is irrelevant to the current code block. And we declared to return an integer, so when we normally end the execution, there must be and only one integer in the current calculation environment.

```moonbit no-check
List::[ 
Const(1), Const(0), Equal,
If(1, List::[Const(1)], List::[Const(0)])
]
```

![](../pics/if.drawio.svg)

We use the content we just described to implement an addition program. The definition of the addition function has been seen before, and we added a test_add as the main entry of the program. The only thing to pay attention to is that after calling the add function, we call the print_int function again. The print_int is a special function. You may have noticed that I did not mention how to define input and output in Wasm, because these functions need to be implemented by external functions, Wasm itself can be considered as a program running in a sandbox.

```moonbit
struct Program {
  functions : @immut/list.List[Function]
  start : Option[String]
}
```

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

output program
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

Finally, we will show the target program we hope to obtain. You can compare it with the program defined in Moonbit before, and you will find that it is almost one-to-one. The next thing we need to do is to write a compiler. The compiler here is relatively simple because our data definition is a one-to-one copy of the Wasm instruction. What we need to do is to convert strings. It should be noted that when I implemented the compiler, we did not directly use string concatenation here, but used the way of modifying the Buffer. The Buffer will allocate additional memory, so when adding new content, it does not necessarily need to allocate additional memory, compared with simple string concatenation, the memory allocation operation can be reduced. As shown in the example code, we directly add strings to the buffer. Of course, Wasm is not only in text format, it also has a binary format. What is now presented to everyone is the binary corresponding to each instruction. Those who are interested can check the WebAssembly standard document.

Recall the previous lessons where we introduced the syntax parser. At that time, we used it to parse integer addition, subtraction, multiplication, and division, and performed calculations. The examples at that time were relatively simple, just addition, subtraction, multiplication, and division, which could be completely constant-folded, meaning the calculations were completed directly during compilation. However, for a program, constant folding for the entire program is obviously not the norm; it must be compiled to a backend for execution. Now, after introducing WebAssembly, we can fill in the last piece of the puzzle. We start with strings, perform lexical analysis to obtain a stream of tokens. Then we use the syntax parser to obtain an abstract syntax tree. From this step, we compile to the WebAssembly instruction set. Finally, we can feed it to various runtime environments for execution. Of course, due to the `Tagless Final` technique we introduced in the last class, the abstract syntax tree can also be omitted. Here, let's recall the syntax book from the last lesson, which includes an integer and addition, subtraction, and multiplication, and division.

So we can use a simple recursive function. This function performs pattern matching on the abstract syntax tree and translates it into the corresponding sequence of WebAssembly instructions. For example, an integer is translated into a single constant instruction, while addition and the like require recursive translation of two parameters. After that, since WebAssembly is a stack-based virtual machine, we link them together and add an addition instruction at the end. It can be seen that we also utilized the operator overloading feature of Moonbit here.

After introducing compilation, let's take a look at interpretation. We build an interpreter here to directly interpret our previous program. To execute, we need two data structures: an operand stack and an instruction queue. On the operand stack, in addition to storing the values involved in the calculation, as previously defined, we also store the variables stored in the environment before the function runs. The instruction queue stores the currently executing instructions. We expand on the original instructions, adding some control instructions, such as the return when the function ends.

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

- Functions

```moonbit
struct Function {
  name : String
  // Only considering one data type, so omit the type of each data, only keep the name and quantity
  params : @immut/list.List[String]; result : Int; locals : @immut/list.List[String]
  instructions : @immut/list.List[Instruction]
}
```

What you see now is our type definition. When expanding instructions, our function end instruction has an integer parameter. What is actually referred to here is the information of the function's return value. Since we only have integers here, we only store the last few values returned. The entire program environment includes the program definition, as well as the operand stack, instruction queue, and local variables in the current calculation environment. All data structures are immutable, and what we need to do is calculate the next state based on the previous state, including the current instruction to be executed, etc. Since errors may occur, after all, we have not verified the code, the returned state is defined by `Option`.

```moonbit no-check
(Cons(Plain(If(_, then, else_)), tl), Cons(Val(I32(i)), rest)) =>
  Some(State::{..state,
      stack: rest,
      instructions: (if i != 0 { then } else { else_ }).map(
        AdministrativeInstruction::Plain,
      ).concat(tl)})
```

![](../pics/interp_if.drawio.svg)

After that, we implement our interpreter. What we need to do is to match the current instruction and data stack. If the match is successful, like the addition instruction here, there should be two consecutive integers at the top of the stack, then we calculate the next state. If all matches fail, it means something went wrong, and we use a wildcard to directly return `None`.

For conditional judgment, we need to take out the corresponding branch code from the stack and add it to the instruction queue. It should be noted that the stored instructions are not expanded, so we perform a mapping here.

Next is the function call. As we mentioned earlier, without an external interface, WebAssembly can only perform calculations silently and cannot perform input and output, unless it uses memory, which is another topic. To solve this problem, we specially judge the function named `print_int` here. If a call is detected, we directly output its value to our cache.

![](../pics/interp_end_call.drawio.svg)

For ordinary function calls, we need to save the current environment and then enter the called environment. In terms of instructions, we need to add a function return instruction, and then expand the corresponding function instructions found in the program above. In terms of data, we need to take a certain number of elements from the top of the current stack according to the number of function parameters to become the new function call environment. After that, we add a function stack on the stack, which stores the current environment variables.

After execution, theoretically, it should be encountering the control instruction to return the function at this time. We take out the elements from the top of the stack according to the number of return values stored in the instruction, clear the current calculation environment, until the function stack that was previously stored. We restore the original calculation environment from it, and then continue to calculate.

So the above is the interpreter introduced in this lesson. Interested students can expand the function definition in the syntax parser according to our instruction set. Or you can also add an early return instruction `return` to the instruction set.

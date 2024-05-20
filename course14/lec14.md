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

# 现代编程思想

## 案例：栈式虚拟机

### Hongbo Zhang

# 编译与解释

- 编译
  - 源程序 x 编译器 -> 目标程序
  - 目标程序 x 输入数据 -> 输出数据
- 解释
  - 源程序 x 输入数据 x 解释器 -> 输出数据
  - CPU可以被视为广义上的解释器
- 拓展阅读：二村映射/部分计算
  - 部分计算：程序优化，根据已知信息，运算进行特化
  - 已知源程序与解释器，进行部分运算，获得目标程序
    - 目标程序 x 输入数据 -> 输出数据

# 虚拟机

- 一处编写，处处运行
  - 定义一个不基于任何平台的指令集
  - 在不同平台上实现解释器
- 两种常见的虚拟机
  - 堆栈虚拟机：运算数存储在栈上，数据遵循先进后出原则
  - 寄存器虚拟机：运算数存储在寄存器中

# 寄存器虚拟机
  - 例：Lua VM (*The Implementation of Lua 5.0*)
    - 取最大值
    ```
    MOVE   2 0 0 ; R(2) = R(0)
    LT     0 0 1 ; R(0) < R(1)?
    JMP    1     ; JUMP -> 5 (4 + 1)
    MOVE   2 1 0 ; R(2) = R(1)
    RETURN 2 2 0 ; return R(2)
    RETURN 0 1 0 ; return 
    ```

# 堆栈虚拟机
  - 例：WebAssembly Virtual Machine
    - 取最大值 `fn max(a : Int, b : Int) -> Int`
    ```wasm
    local.get $a local.set $m                     ;; let mut m = a
    local.get $a local.get $b i32.lt_s            ;; if a < b {
    if local.get $b local.set $m end              ;; m = b }
    local.get $m                                  ;; m
    ```

# WebAssembly

- WebAssembly是什么？
  - 一个虚拟指令集
  - 可以在浏览器以及其他运行时（Wasmtime WAMR WasmEdge等）中运行
  - MoonBit的第一个后端
- WebAssembly指令集的子集为例

# 简单指令集

- 数据
  - 只考虑32位有符号整数
  - 非零代表`true`，零代表`false`
- 指令
  - 数据操作：`const` `add` `minus` `equal` `modulo`
  - 数据存储：`local.get` `local.set`
  - 控制流：`if/else` `call`

# 类型定义

- 数据
```moonbit
enum Value { I32(Int) } // 只考虑32位有符号整数
```

- 指令
```moonbit
enum Instruction {
  Const(Int)                           // 常数
  Add; Sub; Modulo; Equal              // 加、减、取模、相等
  Call(String)                         // 函数调用
  Local_Get(String); Local_Set(String) // 取值、设值
  If(Int, List[Instruction], List[Instruction]) // 条件判断
}
```
  
# 类型定义
- 函数
```moonbit
struct Function {
  name : String
  // 只考虑一种数据类型，故省略每个数据的类型，只保留名称和数量
  params : List[String]; result : Int; locals : List[String]
  instructions : List[Instruction]
}
```

- 程序
```moonbit
struct Program {
  functions : List[Function]
  start : Option[String]
}
```

# 简单计算

- 例：`1 + 2`
  ```moonbit no-check
  List::[ Const(1), Const(2), Add ]
  ```

  ![](../pics/add.drawio.svg)

# 本地变量使用

- 例：`fn add(a : Int, b : Int) { a + b }`
  ```moonbit no-check
  List::[ Local_Get("a"), Local_Get("b"), Add ]
  ```
  - 函数参数及本地变量可通过`Local_Get`获取、`Local_Set`修改
  ![](../pics/local.drawio.svg)

# 函数计算

- 例：`add(1, 2)`
  ```moonbit no-check
  Lists::[ Const(1), Const(2), Call("add") ]
  ```
  - 在栈上存储函数的返回值数量
  ![](../pics/call.drawio.svg)

# 函数计算

- 例：`add(1, 2)`
  ```moonbit no-check
  Lists::[ Const(1), Const(2), Call("add") ]
  ```
  - 在栈上存储函数的返回值数量
  ![](../pics/return.drawio.svg)

# 条件跳转

- 例：`if 1 == 0 { 1 } else { 0 }`
  ```moonbit no-check
  List::[ 
    Const(1), Const(0), Equal,
    If(1, List::[Const(1)], List::[Const(0)])
  ]
  ```

  - 当执行`If(n, then_block, else_block)`时栈顶为非0整数（`true`）
    - 执行then_block
    - 否则，执行else_block
  - `n`表示代码块返回的参数数量

  ![](../pics/if.drawio.svg)

# 例：加法

```moonbit expr
let program = Program::{

  start: Some("test_add"), // 程序入口

  functions: List::[
    Function::{
      name: "add", // 加法函数
      params: List::["a", "b"], result: 1, locals: List::[],
      instructions: List::[Local_Get("a"), Local_Get("b"), Add],
    },

    Function::{
      name: "test_add", // 加法运算并输出
      params: List::[], result: 0, locals: List::[], // 入口函数无输入无输出
      // “print_int"为特殊函数
      instructions: List::[Const(0), Const(1), Call("add"), Call("print_int")], 
    },
  ],
}
```

# 程序整体架构

- 输出程序
```wasm
;; 多个函数
;; WASM本身只定义运算；交互需依赖外部函数
(func $print_int (import "spectest" "print_int") (param i32))

(func $add (export "add") ;; 导出函数使运行时可以直接使用
  (param $a i32) (param $b i32) (result i32 ) ;; (a : Int, b : Int) -> Int
  local.get $a local.get $b i32.add ;; 
)

(func $test_add (export "test_add") (result ) ;; 入口函数无输入无输出
  i32.const 0 i32.const 1 call $add call $print_int
)

(start $test_add)
```

# 在线尝试
- <https://webassembly.github.io/wabt/demo/wat2wasm/>
  ```javascript
  const wasmInstance = new WebAssembly.Instance(wasmModule, {"spectest":{"print_int": console.log}});
  ```

  ![height:400px](../pics/wat2wasm.png)

# 构造编译器

| 指令 | WebAssembly指令 |
|-----|-----------------|
|`Const(0)`|`i32.const 0`|
|`Add`|`i32.add`|
|`Local_Get("a")`|`local.get $a`|
|`Local_Set("a")`|`local.set $a`|
|`Call("add")`|`call $add`|
|`If(1, List::[Const(0)], List::[Const(1)])`| `if (result i32) i32.const 0 else i32.const 1 end`|

# 编译程序

- 利用内建`Buffer`数据结构，比字符串拼接更高效
  ```moonbit no-check
  fn Instruction::to_wasm(self : Instruction, buffer : Buffer) -> Unit
  fn Function::to_wasm(self : Function, buffer : Buffer) -> Unit
  fn Program::to_wasm(self : Program, buffer : Buffer) -> Unit
  ```

# 编译指令

- 利用内建`Buffer`数据结构，比拼接字符串更高效
```moonbit
fn Instruction::to_wasm(self : Instruction, buffer : Buffer) -> Unit {
  match self {
    Add => buffer.write_string("i32.add ")
    Local_Get(val) => buffer.write_string("local.get $\(val) ")
    _ => buffer.write_string("...")
  }
}
```

# Wasm的二进制格式

| 文本格式 | 二进制格式 |
|-----|-----------------|
|`i32.const`| 0x41 |
|`i32.add`| 0x6A |
|`local.get`| 0x20 |
|`local.set`| 0x21 |
|`call $add`| 0x10 |
|`if else end`| 0x04 (vec[instructions]) 0x05 (vec[instructions]) 0x0B |

# 多层编译

- 字符串 -> 单词流 -> (抽象语法树) -> WASM IR -> 运行

```moonbit
enum Expression {
  Number(Int)
  Plus(Expression, Expression)
  Minus(Expression, Expression)
  Multiply(Expression, Expression)
  Divide(Expression, Expression)
}
```

# 多层编译

- 字符串 -> 单词流 -> (抽象语法树) -> WASM IR -> 编译/运行

```moonbit
fn compile_expression(expression : Expression) -> List[Instruction] {
  match expression {
    Number(i) => List::[Const(I32(i))]
    Plus(a, b) => compile_expression(a) + compile_expression(b) + List::[Add]
    Minus(a, b) => compile_expression(a) + compile_expression(b) + List::[Sub]
    _ => List::[]
  }
}
```

# 构建解释器

- 一种可能的解释器
- 操作数栈
  - 参与运算的数值
  - 函数执行前的本地变量
- 指令队列
  - 当前执行的指令
  - 分为普通指令和控制指令（如函数结束时的返回）

# 解释器结构

```moonbit
enum StackValue {
  Val(Value) // 普通数值
  Func(@map.Map[String, Value]) // 函数堆栈，存放先前的本地变量
}

enum AdministrativeInstruction {
  Plain(Instruction) // 普通指令
  EndOfFrame(Int) // 函数结束指令
}

struct State {
  program : Program
  stack : List[StackValue]
  locals : @map.Map[String, Value]
  instructions : List[AdministrativeInstruction]
}
```

- 状态迭代
  `fn evaluate(state : State, stdout : Buffer) -> Option[State]`

# 解释器构造

- 读取当前指令与栈顶数据

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

# 解释器构造

- 条件判断时，根据分支取出对应代码

```moonbit no-check
(Cons(Plain(If(_, then, else_)), tl), Cons(Val(I32(i)), rest)) =>
  Some(State::{..state,
      stack: rest,
      instructions: (if i != 0 { then } else { else_ }).map(
        AdministrativeInstruction::Plain,
      ).concat(tl)})
```

![](../pics/interp_if.drawio.svg)

# 解释器构造

- 对输出函数进行特判

```moonbit no-check
(Cons(Plain(Call("print_int")), tl), Cons(Val(I32(i)), rest)) => {
  stdout.write_string(i.to_string())
  Some(State::{ ..state, stack: rest, instructions: tl })
}
```

![](../pics/interp_print_int.drawio.svg)

# 解释器构造

- 对于函数调用，将当前的运行状态（变量）存入堆栈

  ![](../pics/interp_call.drawio.svg)

# 解释器构造

- 在函数执行完成后
  - 从栈顶根据返回值数量取出元素
  - 将调用栈的信息展开

  ![](../pics/interp_end_call.drawio.svg)

# 总结

- 本节课展示了一个堆栈虚拟机
  - 介绍了WebAssebmly指令集的一小部份
  - 实现了一个编译器
  - 实现了一个解释器
- 挑战
  - 在语法解析器中拓展函数定义
  - 在指令集中添加提前返回指令（`return`）

enum Value {
  I32(Int)
}

enum Instruction {
  Const(Value)
  Add
  Sub
  Modulo
  Equal
  Call(String)
  Local_Get(String)
  Local_Set(String)
  If(Int, List[Instruction], List[Instruction])
}

struct Function {
  name : String
  params : List[String]
  result : Int
  locals : List[String]
  instructions : List[Instruction]
}

struct Program {
  functions : List[Function]
  start : Option[String]
}

fn Instruction::to_wasm(self : Instruction, buffer : Buffer) -> Unit {
  match self {
    Const(I32(i)) => buffer.write_string("i32.const \(i) ")
    Add => buffer.write_string("i32.add ")
    Sub => buffer.write_string("i32.sub ")
    Modulo => buffer.write_string("i32.rem_s ")
    Equal => buffer.write_string("i32.eq ")
    Call(val) => buffer.write_string("call $\(val) ")
    Local_Get(val) => buffer.write_string("local.get $\(val) ")
    Local_Set(val) => buffer.write_string("local.set $\(val) ")
    If(n, then, else_) => {
      buffer.write_string("if (result ")
      for i = 0; i < n; i = i + 1 {
        buffer.write_string("i32 ")
      }
      buffer.write_string(") ")
      then.iter(fn { instruction => instruction.to_wasm(buffer) })
      buffer.write_string("else ")
      else_.iter(fn { instruction => instruction.to_wasm(buffer) })
      buffer.write_string("end ")
    }
  }
}

fn Function::to_wasm(self : Function, buffer : Buffer) -> Unit {
  let { name, params, result, locals, instructions } = self
  buffer.write_string("(func $\(name) (export \"\(name)\")")
  params.iter(fn { param => buffer.write_string("(param $\(param) i32) ") })
  buffer.write_string("(result ")
  for i = 0; i < result; i = i + 1 {
    buffer.write_string("i32 ")
  }
  buffer.write_string(") ")
  locals.iter(fn { local => buffer.write_string("(local $\(local) i32)") })
  instructions.iter(fn { instruction => instruction.to_wasm(buffer) })
  buffer.write_string(")\n")
}

fn Program::to_wasm(self : Program, buffer : Buffer) -> Unit {
  let { functions, start } = self
  buffer.write_string(

    #|(module (func $print_int (import "spectest" "print_int") (param i32))
    #|
    ,
  )
  functions.iter(fn { func => func.to_wasm(buffer) })
  match start {
    Some(start) => buffer.write_string("(start $\(start)))")
    None => buffer.write_string(")")
  }
}

test "add" {
  let program = Program::{
    start: None,
    functions: List::[
      Function::{
        name: "add",
        params: List::["a", "b"],
        result: 1,
        locals: List::[],
        instructions: List::[Local_Get("a"), Local_Get("b"), Add],
      },
    ],
  }
  let buffer = Buffer::make(100)
  program.to_wasm(buffer)
  @assertion.assert_eq(
    buffer.to_string(),

    #|(module (func $print_int (import "spectest" "print_int") (param i32))
    #|(func $add (export "add")(param $a i32) (param $b i32) (result i32 ) local.get $a local.get $b i32.add )
    #|)
    ,
  )?
}

enum StackValue {
  Val(Value)
  Func(@map.Map[String, Value])
}

enum AdministrativeInstruction {
  Plain(Instruction)
  EndOfFrame(Int)
}

struct State {
  program : Program
  stack : List[StackValue]
  locals : @map.Map[String, Value]
  instructions : List[AdministrativeInstruction]
}

fn execute(program : Program) -> Option[String] {
  let start = program.start?
  let function = program.functions.filter(fn { f => f.name == start }).head_option()?
  let stdout = Buffer::make(10)
  loop
    Option::Some(
      State::{
        program,
        stack: Nil,
        locals: function.locals.fold(
          @map.empty(),
          fn { map, name => map.insert(name, I32(0)) },
        ),
        instructions: function.instructions.map(
          AdministrativeInstruction::Plain,
        ),
      },
    ) {
    None => Some(stdout.to_string())
    Some(state) => continue evaluate(state, stdout)
  }
}

fn evaluate(state : State, stdout : Buffer) -> Option[State] {
  match state.instructions {
    Nil => None
    Cons(Plain(instr), tl) =>
      match instr {
        Const(value) =>
          Some(
            State::{
              ..state,
              instructions: tl,
              stack: Cons(Val(value), state.stack),
            },
          )
        Add =>
          match state.stack {
            Cons(Val(I32(b)), Cons(Val(I32(a)), rest)) =>
              Some(
                State::{
                  ..state,
                  instructions: tl,
                  stack: Cons(Val(I32(a + b)), rest),
                },
              )
            _ => None
          }
        Sub =>
          match state.stack {
            Cons(Val(I32(b)), Cons(Val(I32(a)), rest)) =>
              Some(
                State::{
                  ..state,
                  instructions: tl,
                  stack: Cons(Val(I32(a - b)), rest),
                },
              )
            _ => None
          }
        Modulo =>
          match state.stack {
            Cons(Val(I32(b)), Cons(Val(I32(a)), rest)) =>
              Some(
                State::{
                  ..state,
                  instructions: tl,
                  stack: Cons(Val(I32(a % b)), rest),
                },
              )
            _ => None
          }
        Equal =>
          match state.stack {
            Cons(Val(I32(b)), Cons(Val(I32(a)), rest)) =>
              Some(
                State::{
                  ..state,
                  instructions: tl,
                  stack: Cons(Val(I32(if a == b { 1 } else { 0 })), rest),
                },
              )
            _ => None
          }
        Local_Get(var) => {
          let value = state.locals.lookup(var)?
          Some(
            State::{
              ..state,
              instructions: tl,
              stack: Cons(Val(value), state.stack),
            },
          )
        }
        Local_Set(var) =>
          match state.stack {
            Cons(Val(value), rest) =>
              Some(
                State::{
                  ..state,
                  locals: state.locals.insert(var, value),
                  instructions: tl,
                  stack: rest,
                },
              )
            _ => None
          }
        Call(var) =>
          if var == "print_int" {
            match state.stack {
              Cons(Val(I32(i)), rest) => {
                stdout.write_string(i.to_string())
                Some(State::{ ..state, stack: rest, instructions: tl })
              }
              _ => None
            }
          } else {
            let function : Function = state.program.functions.filter(
              fn { f => f.name == var },
            ).head_option()?
            let params = state.stack.take(function.params.length())
            Some(
              State::{
                ..state,
                stack: Cons(
                  Func(state.locals),
                  state.stack.drop(function.params.length()),
                ),
                locals: function.locals.fold(
                  function.params.zip(params.reverse()).fold(
                    @map.empty(),
                    fn {
                      map, (name, Val(value)) => map.insert(name, value)
                      _, _ => abort("Expected a value")
                    },
                  ),
                  fn { map, name => map.insert(name, I32(0)) },
                ),
                instructions: function.instructions.map(
                  AdministrativeInstruction::Plain,
                ).concat(List::[EndOfFrame(function.result)]).concat(tl),
              },
            )
          }
        If(_, then, else_) =>
          match state.stack {
            Cons(Val(I32(i)), rest) =>
              Some(
                State::{
                  ..state,
                  stack: rest,
                  instructions: (if i != 0 { then } else { else_ }).map(
                    AdministrativeInstruction::Plain,
                  ).concat(tl),
                },
              )
            _ => None
          }
      }
    Cons(EndOfFrame(arity), tl) => {
      let params = state.stack.take(arity)
      let stack = state.stack.drop_while(
        fn {
          Func(_) => false
          _ => true
        },
      )
      match stack {
        Cons(Func(locals), rest) =>
          Some(
            State::{ ..state, stack: params.concat(rest), locals, instructions: tl },
          )
        _ => None
      }
    }
  }
}

test "eval" {
  let functions : List[Function] = List::[
    Function::{
      name: "gcd",
      params: List::["a", "b"],
      result: 1,
      locals: List::[],
      instructions: List::[
        Local_Get("a"),
        Const(I32(0)),
        Equal,
        If(
          1,
          List::[Local_Get("b")],
          List::[
            Local_Get("b"),
            Local_Get("a"),
            Modulo,
            Local_Get("a"),
            Call("gcd"),
          ],
        ),
      ],
    },
    Function::{
      name: "fib_aux",
      params: List::["a", "b", "n"],
      result: 1,
      locals: List::[],
      instructions: List::[
        Local_Get("n"),
        Const(I32(0)),
        Equal,
        If(
          1,
          List::[Local_Get("b")],
          List::[
            Local_Get("b"),
            Local_Get("a"),
            Local_Get("b"),
            Add,
            Local_Get("n"),
            Const(I32(1)),
            Sub,
            Call("fib_aux"),
          ],
        ),
      ],
    },
    Function::{
      name: "fib",
      params: List::["n"],
      result: 1,
      locals: List::[],
      instructions: List::[
        Const(I32(0)),
        Const(I32(1)),
        Local_Get("n"),
        Call("fib_aux"),
      ],
    },
    Function::{
      name: "test_fib",
      params: List::[],
      result: 0,
      locals: List::[],
      instructions: List::[Const(I32(5)), Call("fib"), Call("print_int")],
    },
    Function::{
      name: "test_gcd",
      params: List::[],
      result: 0,
      locals: List::[],
      instructions: List::[
        Const(I32(10)),
        Const(I32(100)),
        Call("gcd"),
        Call("print_int"),
      ],
    },
  ]
  let test_gcd = Program::{ start: Some("test_gcd"), functions }
  @assertion.assert_eq(execute(test_gcd), Some("10"))?
  let test_fib = Program::{ start: Some("test_fib"), functions }
  @assertion.assert_eq(execute(test_fib), Some("8"))?
}

fn compile_expression(expression : Expression) -> List[Instruction] {
  match expression {
    Number(i) => List::[Const(I32(i))]
    Plus(a, b) =>
      compile_expression(a).concat(compile_expression(b)).concat(List::[Add])
    Minus(a, b) =>
      compile_expression(a).concat(compile_expression(b)).concat(List::[Sub])
    _ => List::[]
  }
}

fn compile(expression : Expression) -> Program {
  Program::{
    start: Some("main"),
    functions: List::[
      Function::{
        name: "main",
        params: List::[],
        result: 0,
        locals: List::[],
        instructions: compile_expression(expression).concat(
          List::[Call("print_int")],
        ),
      },
    ],
  }
}

test "compile" {
  let input = "1 + 2 - 3"
  let expression = parse_string(input)
  let program = expression.map(fn { (expression, _, _) => compile(expression) })
  @assertion.assert_eq(
    program.bind(execute),
    parse_string_tagless_final(input).map(
      fn { (BoxedInt::BoxedInt(i), _, _) => i.to_string() },
    ),
  )?
}
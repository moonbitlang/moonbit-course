///|
enum Value {
  I32(Int)
}

///|
enum Instruction {
  Const(Value)
  Add
  Sub
  Modulo
  Equal
  Call(String)
  Local_Get(String)
  Local_Set(String)
  If(Int, @list.T[Instruction], @list.T[Instruction])
}

///|
struct Function {
  name : String
  params : @list.T[String]
  result : Int
  locals : @list.T[String]
  instructions : @list.T[Instruction]
}

///|
struct Program {
  functions : @list.T[Function]
  start : String?
}

///|
fn Instruction::to_wasm(self : Instruction, buffer : StringBuilder) -> Unit {
  match self {
    Const(I32(i)) => buffer.write_string("i32.const \{i} ")
    Add => buffer.write_string("i32.add ")
    Sub => buffer.write_string("i32.sub ")
    Modulo => buffer.write_string("i32.rem_s ")
    Equal => buffer.write_string("i32.eq ")
    Call(val) => buffer.write_string("call $\{val} ")
    Local_Get(val) => buffer.write_string("local.get $\{val} ")
    Local_Set(val) => buffer.write_string("local.set $\{val} ")
    If(n, then, else_) => {
      buffer.write_string("if (result ")
      for i = 0; i < n; i = i + 1 {
        buffer.write_string("i32 ")
      }
      buffer.write_string(") ")
      then.each(instruction => instruction.to_wasm(buffer))
      buffer.write_string("else ")
      else_.each(instruction => instruction.to_wasm(buffer))
      buffer.write_string("end ")
    }
  }
}

///|
fn Function::to_wasm(self : Function, buffer : StringBuilder) -> Unit {
  let { name, params, result, locals, instructions } = self
  buffer.write_string("(func $\{name} (export \"\{name}\")")
  params.each(param => buffer.write_string("(param $\{param} i32) "))
  buffer.write_string("(result ")
  for i = 0; i < result; i = i + 1 {
    buffer.write_string("i32 ")
  }
  buffer.write_string(") ")
  locals.each(local_ => buffer.write_string("(local $\{local_} i32)"))
  instructions.each(instruction => instruction.to_wasm(buffer))
  buffer.write_string(")\n")
}

///|
fn Program::to_wasm(self : Program, buffer : StringBuilder) -> Unit {
  let { functions, start } = self
  buffer.write_string(
    (
      #|(module (func $print_int (import "spectest" "print_int") (param i32))
      #|
    ),
  )
  functions.each(func => func.to_wasm(buffer))
  match start {
    Some(start) => buffer.write_string("(start $\{start}))")
    None => buffer.write_string(")")
  }
}

///|
test "add" {
  let program = Program::{
    start: None,
    functions: @list.from_array([
      Function::{
        name: "add",
        params: @list.from_array(["a", "b"]),
        result: 1,
        locals: @list.empty(),
        instructions: @list.from_array([Local_Get("a"), Local_Get("b"), Add]),
      },
    ]),
  }
  let buffer = StringBuilder::new()
  program.to_wasm(buffer)
  assert_eq(
    buffer.to_string(),
    (
      #|(module (func $print_int (import "spectest" "print_int") (param i32))
      #|(func $add (export "add")(param $a i32) (param $b i32) (result i32 ) local.get $a local.get $b i32.add )
      #|)
    ),
  )
}

///|
enum StackValue {
  Val(Value)
  Func(@immut/hashmap.T[String, Value])
}

///|
enum AdministrativeInstruction {
  Plain(Instruction)
  EndOfFrame(Int)
}

///|
struct State {
  program : Program
  stack : @list.T[StackValue]
  locals : @immut/hashmap.T[String, Value]
  instructions : @list.T[AdministrativeInstruction]
}

///|
fn execute(program : Program) -> String? {
  guard program.start is Some(start) else { return None }
  guard program.functions.filter(f => f.name == start).head() is Some(function) else {
    return None
  }
  let stdout = StringBuilder::new()
  loop
    Option::Some(State::{
      program,
      stack: @list.empty(),
      locals: function.locals.fold(init=@immut/hashmap.new(), (map, name) => map.add(
        name,
        I32(0),
      )),
      instructions: function.instructions.map(Plain(_)),
    }) {
    None => Some(stdout.to_string())
    Some(state) => continue evaluate(state, stdout)
  }
}

///|
fn evaluate(state : State, stdout : StringBuilder) -> State? {
  match state.instructions {
    Empty => None
    More(Plain(instr), tail=tl) =>
      match instr {
        Const(value) =>
          Some(State::{
            ..state,
            instructions: tl,
            stack: @list.construct(Val(value), state.stack),
          })
        Add =>
          match state.stack {
            More(Val(I32(b)), tail=More(Val(I32(a)), tail=rest)) =>
              Some(State::{
                ..state,
                instructions: tl,
                stack: @list.construct(Val(I32(a + b)), rest),
              })
            _ => None
          }
        Sub =>
          match state.stack {
            More(Val(I32(b)), tail=More(Val(I32(a)), tail=rest)) =>
              Some(State::{
                ..state,
                instructions: tl,
                stack: @list.construct(Val(I32(a - b)), rest),
              })
            _ => None
          }
        Modulo =>
          match state.stack {
            More(Val(I32(b)), tail=More(Val(I32(a)), tail=rest)) =>
              Some(State::{
                ..state,
                instructions: tl,
                stack: @list.construct(Val(I32(a % b)), rest),
              })
            _ => None
          }
        Equal =>
          match state.stack {
            More(Val(I32(b)), tail=More(Val(I32(a)), tail=rest)) =>
              Some(State::{
                ..state,
                instructions: tl,
                stack: @list.construct(
                  Val(I32(if a == b { 1 } else { 0 })),
                  rest,
                ),
              })
            _ => None
          }
        Local_Get(variable) => {
          guard state.locals.get(variable) is Some(value) else { return None }
          Some(State::{
            ..state,
            instructions: tl,
            stack: @list.construct(Val(value), state.stack),
          })
        }
        Local_Set(variable) =>
          match state.stack {
            More(Val(value), tail=rest) =>
              Some(State::{
                ..state,
                locals: state.locals.add(variable, value),
                instructions: tl,
                stack: rest,
              })
            _ => None
          }
        Call(variable) =>
          if variable == "print_int" {
            match state.stack {
              More(Val(I32(i)), tail=rest) => {
                stdout.write_string(i.to_string())
                Some(State::{ ..state, stack: rest, instructions: tl })
              }
              _ => None
            }
          } else {
            guard state.program.functions.filter(f => f.name == variable).head()
              is Some(function) else {
              return None
            }
            let params = state.stack.take(function.params.length())
            Some(State::{
              ..state,
              stack: @list.construct(
                Func(state.locals),
                state.stack.drop(function.params.length()),
              ),
              locals: function.locals.fold(
                init=function.params
                  .zip(params.rev())
                  .fold(init=@immut/hashmap.new(), (map, value) => match value {
                    (name, Val(value)) => map.add(name, value)
                    _ => abort("Expected a value")
                  }),
                (map, name) => map.add(name, I32(0)),
              ),
              instructions: function.instructions
              .map(Plain(_))
              .concat(@list.from_array([EndOfFrame(function.result)]))
              .concat(tl),
            })
          }
        If(_, then, else_) =>
          match state.stack {
            More(Val(I32(i)), tail=rest) =>
              Some(State::{
                ..state,
                stack: rest,
                instructions: (if i != 0 { then } else { else_ })
                .map(Plain(_))
                .concat(tl),
              })
            _ => None
          }
      }
    More(EndOfFrame(arity), tail=tl) => {
      let params = state.stack.take(arity)
      let stack = state.stack.drop_while(f => !(f is Func(_)))
      match stack {
        More(Func(locals), tail=rest) =>
          Some(State::{
            ..state,
            stack: params.concat(rest),
            locals,
            instructions: tl,
          })
        _ => None
      }
    }
  }
}

///|
test "eval" {
  let functions : @list.T[Function] = @list.from_array([
    Function::{
      name: "gcd",
      params: @list.from_array(["a", "b"]),
      result: 1,
      locals: @list.empty(),
      instructions: @list.from_array([
        Local_Get("a"),
        Const(I32(0)),
        Equal,
        If(
          1,
          @list.from_array([Local_Get("b")]),
          @list.from_array([
            Local_Get("b"),
            Local_Get("a"),
            Modulo,
            Local_Get("a"),
            Call("gcd"),
          ]),
        ),
      ]),
    },
    Function::{
      name: "fib_aux",
      params: @list.from_array(["a", "b", "n"]),
      result: 1,
      locals: @list.empty(),
      instructions: @list.from_array([
        Local_Get("n"),
        Const(I32(0)),
        Equal,
        If(
          1,
          @list.from_array([Local_Get("b")]),
          @list.from_array([
            Local_Get("b"),
            Local_Get("a"),
            Local_Get("b"),
            Add,
            Local_Get("n"),
            Const(I32(1)),
            Sub,
            Call("fib_aux"),
          ]),
        ),
      ]),
    },
    Function::{
      name: "fib",
      params: @list.from_array(["n"]),
      result: 1,
      locals: @list.empty(),
      instructions: @list.from_array([
        Const(I32(0)),
        Const(I32(1)),
        Local_Get("n"),
        Call("fib_aux"),
      ]),
    },
    Function::{
      name: "test_fib",
      params: @list.empty(),
      result: 0,
      locals: @list.empty(),
      instructions: @list.from_array([
        Const(I32(5)),
        Call("fib"),
        Call("print_int"),
      ]),
    },
    Function::{
      name: "test_gcd",
      params: @list.empty(),
      result: 0,
      locals: @list.empty(),
      instructions: @list.from_array([
        Const(I32(10)),
        Const(I32(100)),
        Call("gcd"),
        Call("print_int"),
      ]),
    },
  ])
  let test_gcd = Program::{ start: Some("test_gcd"), functions }
  assert_eq(execute(test_gcd), Some("10"))
  let test_fib = Program::{ start: Some("test_fib"), functions }
  assert_eq(execute(test_fib), Some("8"))
}

///|
fn compile_expression(expression : Expression) -> @list.T[Instruction] {
  match expression {
    Number(i) => @list.from_array([Const(I32(i))])
    Plus(a, b) =>
      compile_expression(a)
      .concat(compile_expression(b))
      .concat(@list.from_array([Add]))
    Minus(a, b) =>
      compile_expression(a)
      .concat(compile_expression(b))
      .concat(@list.from_array([Sub]))
    _ => @list.empty()
  }
}

///|
fn compile(expression : Expression) -> Program {
  Program::{
    start: Some("main"),
    functions: @list.from_array([
      Function::{
        name: "main",
        params: @list.empty(),
        result: 0,
        locals: @list.empty(),
        instructions: compile_expression(expression).concat(
          @list.from_array([Call("print_int")]),
        ),
      },
    ]),
  }
}

///|
test "compile" {
  let input = "1 + 2 - 3"
  let expression = parse_string(input)
  let program = expression.map(e => compile(e.0))
  assert_eq(
    program.bind(execute),
    parse_string_tagless_final(input).map(expr => {
      guard expr is (BoxedInt(i), _, _)
      i.to_string()
    }),
  )
}

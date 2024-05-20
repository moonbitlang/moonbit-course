type Lexer[V] (String) -> Option[(V, String)]

fn parse[V](self : Lexer[V], str : String) -> Option[(V, String)] {
  (self.0)(str)
}

fn pchar(predicate : (Char) -> Bool) -> Lexer[Char] {
  Lexer(
    fn(input) {
      if input.length() > 0 && predicate(input[0]) {
        Some((input[0], input.to_bytes().sub_string(2, input.length() - 2)))
      } else {
        None
      }
    },
  )
}

fn map[I, O](self : Lexer[I], f : (I) -> O) -> Lexer[O] {
  Lexer(
    fn(input) {
      let (value, rest) = self.parse(input)?
      Some((f(value), rest))
    },
  )
}

fn and[V1, V2](self : Lexer[V1], parser2 : Lexer[V2]) -> Lexer[(V1, V2)] {
  Lexer(
    fn(input) {
      let (value, rest) = self.parse(input)?
      let (value2, rest2) = parser2.parse(rest)?
      Some(((value, value2), rest2))
    },
  )
}

fn or[Value](self : Lexer[Value], parser2 : Lexer[Value]) -> Lexer[Value] {
  Lexer(
    fn(input) {
      match self.parse(input) {
        None => parser2.parse(input)
        Some(_) as result => result
      }
    },
  )
}

fn reverse_list[X](list : List[X]) -> List[X] {
  fn go(acc, xs : List[X]) {
    match xs {
      Nil => acc
      Cons(x, rest) => go((Cons(x, acc) : List[X]), rest)
    }
  }

  go(Nil, list)
}

fn fold_left_list[A, B](list : List[A], f : (B, A) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => fold_left_list(tl, f, f(b, hd))
  }
}

fn many[Value](self : Lexer[Value]) -> Lexer[List[Value]] {
  Lexer(
    fn(input) {
      let mut rest = input
      let mut cumul = List::Nil
      while true {
        match self.parse(rest) {
          None => break
          Some((value, new_rest)) => {
            rest = new_rest
            cumul = Cons(value, cumul)
          }
        }
      }
      Some((reverse_list(cumul), rest))
    },
  )
}

/// Number = %x30 / (%x31-39) *(%x30-39)  
/// LParen = "("  
/// RParen = ")"  
/// Plus = "+"  
/// Minus = "-"  
/// Multiply = "*"  
/// Divide = "/"  
/// Whitespace = " "  
enum Token {
  Value(Int)
  LParen
  RParen
  Plus
  Minus
  Multiply
  Divide
} derive(Debug)

let symbol : Lexer[Token] = pchar(
  fn {
    '+' | '-' | '*' | '/' | '(' | ')' => true
    _ => false
  },
).map(
  fn {
    '+' => Plus
    '-' => Minus
    '*' => Multiply
    '/' => Divide
    '(' => LParen
    ')' => RParen
  },
)

let whitespace : Lexer[Char] = pchar(fn { ch => ch == ' ' })

let zero : Lexer[Int] = pchar(fn { ch => ch == '0' }).map(fn { _ => 0 })

let one_to_nine : Lexer[Int] = pchar(
  fn { ch => ch.to_int() >= 0x31 && ch.to_int() <= 0x39 },
).map(fn { ch => ch.to_int() - 0x30 })

let zero_to_nine : Lexer[Int] = pchar(
  fn { ch => ch.to_int() >= 0x30 && ch.to_int() <= 0x39 },
).map(fn { ch => ch.to_int() - 0x30 })

let value : Lexer[Token] = zero.or(
  one_to_nine.and(zero_to_nine.many()).map(
    fn { (i, ls) => fold_left_list(ls, fn { i, j => i * 10 + j }, i) },
  ),
).map(Token::Value)

let tokens : Lexer[List[Token]] = value.or(symbol).and(whitespace.many()).map(
  fn { (symbols, _) => symbols },
).many()

fn aux(show: Show) -> Unit {
  println(show.to_string())
}

test "Lexing" {
  aux(tokens.parse("-10123+-+523 103    ( 5) )  ")) |> debug
  aux(pchar(fn { ch => ch == 'a' }).parse("asdf")) |> debug
  aux(
    pchar(
      fn {
        'a' => true
        _ => false
      },
    ).parse("sdf"),
  ) |> debug
}

/// atomic = Value / LParen expression RParen  
/// combine = atomic *( (Multiply / Divide) combine)  
/// expression = combine *( (Plus / Minus) expression)  
enum Expression {
  Number(Int)
  Plus(Expression, Expression)
  Minus(Expression, Expression)
  Multiply(Expression, Expression)
  Divide(Expression, Expression)
} derive(Debug)

type Parser[V] (List[Token]) -> Option[(V, List[Token])]

fn parse[V](self : Parser[V], tokens : List[Token]) -> Option[(V, List[Token])] {
  (self.0)(tokens)
}

fn ptoken(predicate : (Token) -> Bool) -> Parser[Token] {
  Parser(
    fn {
      Nil => None
      Cons(token, rest) =>
        if predicate(token) {
          Some((token, rest))
        } else {
          None
        }
    },
  )
}

fn map[I, O](self : Parser[I], f : (I) -> O) -> Parser[O] {
  Parser(
    fn(input) {
      let (value, rest) = self.parse(input)?
      Some((f(value), rest))
    },
  )
}

fn and[V1, V2](self : Parser[V1], parser2 : Parser[V2]) -> Parser[(V1, V2)] {
  Parser(
    fn(input) {
      let (value, rest) = self.parse(input)?
      let (value2, rest2) = parser2.parse(rest)?
      Some(((value, value2), rest2))
    },
  )
}

fn or[Value](self : Parser[Value], parser2 : Parser[Value]) -> Parser[Value] {
  Parser(
    fn(input) {
      match self.parse(input) {
        None => parser2.parse(input)
        Some(_) as result => result
      }
    },
  )
}

fn many[Value](self : Parser[Value]) -> Parser[List[Value]] {
  Parser(
    fn(input) {
      let mut i = input
      let mut cumul = List::Nil
      while true {
        match self.parse(i) {
          None => break
          Some((value, rest)) => {
            i = rest
            cumul = Cons(value, cumul)
          }
        }
      }
      Some((reverse_list(cumul), i))
    },
  )
}

fn Parser::ref[Value](ref : Ref[Parser[Value]]) -> Parser[Value] {
  Parser(fn(input) { ref.val.parse(input) })
}

let lparen : Parser[Token] = ptoken(
  fn {
    LParen => true
    _ => false
  },
)

let rparen : Parser[Token] = ptoken(
  fn {
    RParen => true
    _ => false
  },
)

let plus : Parser[Token] = ptoken(
  fn {
    Plus => true
    _ => false
  },
)

let minus : Parser[Token] = ptoken(
  fn {
    Minus => true
    _ => false
  },
)

let multiply : Parser[Token] = ptoken(
  fn {
    Multiply => true
    _ => false
  },
)

let divide : Parser[Token] = ptoken(
  fn {
    Divide => true
    _ => false
  },
)

fn parser() -> Parser[Expression] {
  let expression_ref : Ref[Parser[Expression]] = {
    val: Parser(fn { _ => None }),
  }
  let number : Parser[Expression] = ptoken(
    fn {
      Value(_) => true
      _ => false
    },
  ).map(fn { Value(i) => Number(i) })
  let automic = lparen.and(ref(expression_ref)).and(rparen).map(
    fn { ((_, expr), _) => expr },
  ).or(number)
  let combine = automic.and(multiply.or(divide).and(automic).many()).map(
    fn {
      (expr, list) =>
        fold_left_list(
          list,
          fn {
            e, (Multiply, expr) => Expression::Multiply(e, expr)
            e, (_, expr) => Expression::Divide(e, expr)
          },
          expr,
        )
    },
  )
  expression_ref.val = combine.and(plus.or(minus).and(combine).many()).map(
    fn {
      (expr, list) =>
        fold_left_list(
          list,
          fn {
            e, (Plus, expr) => Expression::Plus(e, expr)
            e, (_, expr) => Expression::Minus(e, expr)
          },
          expr,
        )
    },
  )
  ref(expression_ref)
}

trait Expr {
  number(Int) -> Self
  op_add(Self, Self) -> Self
  op_sub(Self, Self) -> Self
  op_mul(Self, Self) -> Self
  op_div(Self, Self) -> Self
}

// Semantic: create syntax tree 语义：构造语法树
fn Expression::number(i : Int) -> Expression {
  Number(i)
}

fn Expression::op_add(a : Expression, b : Expression) -> Expression {
  Plus(a, b)
}

fn Expression::op_sub(a : Expression, b : Expression) -> Expression {
  Minus(a, b)
}

fn Expression::op_mul(a : Expression, b : Expression) -> Expression {
  Multiply(a, b)
}

fn Expression::op_div(a : Expression, b : Expression) -> Expression {
  Divide(a, b)
}

// Semantic: compute expression 语义：计算表达式
type BoxedInt Int derive(Debug)

fn BoxedInt::number(i : Int) -> BoxedInt {
  BoxedInt(i)
}

fn BoxedInt::op_add(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.0 + b.0)
}

fn BoxedInt::op_sub(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.0 - b.0)
}

fn BoxedInt::op_mul(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.0 * b.0)
}

fn BoxedInt::op_div(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.0 / b.0)
}

// Semantic: print expression 语义：输出表达式
struct BoxedString {
  str : String
  level : Int
} derive(Debug)

fn BoxedString::number(i : Int) -> BoxedString {
  { str: i.to_string(), level: 0 }
}

fn BoxedString::op_add(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = a.str
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\(stra) + \(strb)", level: 1 }
}

fn BoxedString::op_sub(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = a.str
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\(stra) - \(strb)", level: 1 }
}

fn BoxedString::op_mul(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = if a.level == 1 { "(" + a.str + ")" } else { a.str }
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\(stra) * \(strb)", level: 2 }
}

fn BoxedString::op_div(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = if a.level == 1 { "(" + a.str + ")" } else { a.str }
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\(stra) / \(strb)", level: 2 }
}

fn recursive_parser_with_tagless_final[E : Expr]() -> Parser[E] {
  let number : Parser[E] = ptoken(
    fn {
      Value(_) => true
      _ => false
    },
  ).map(fn { Value(i) => E::number(i) })
  fn atomic(tokens : List[Token]) -> Option[(E, List[Token])] {
    lparen.and(Parser(expression)).and(rparen).map(
      fn { ((_, expr), _) => expr },
    ).or(number).parse(tokens)
  }

  fn combine(tokens : List[Token]) -> Option[(E, List[Token])] {
    (Parser(atomic) : Parser[E]).and(
      multiply.or(divide).and(Parser(atomic)).many(),
    ).map(
      fn {
        (e, list) =>
          fold_left_list(
            list,
            fn {
              e, (Multiply, expr) => e * expr
              e, (_, expr) => e / expr
            },
            e,
          )
      },
    ).parse(tokens)
  }

  fn expression(tokens : List[Token]) -> Option[(E, List[Token])] {
    (Parser(combine) : Parser[E]).and(
      plus.or(minus).and(Parser(combine)).many(),
    ).map(
      fn {
        (e, list) =>
          fold_left_list(
            list,
            fn {
              e, (Plus, expr) => e + expr
              e, (_, expr) => e - expr
            },
            e,
          )
      },
    ).parse(tokens)
  }

  Parser(expression)
}

fn parse_string(str : String) -> Option[(Expression, String, List[Token])] {
  let (token_list, rest_string) = tokens.parse(str)?
  let (expr, rest_token) = parser().parse(token_list)?
  Some((expr, rest_string, rest_token))
}

fn parse_string_tagless_final[E : Expr](
  str : String
) -> Option[(E, String, List[Token])] {
  let (token_list, rest_string) = tokens.parse(str)?
  let (expr, rest_token) : (E, List[Token]) = recursive_parser_with_tagless_final().parse(
    token_list,
  )?
  Some((expr, rest_string, rest_token))
}

test "Parsing" {
  aux(parse_string("1 + 1 * (307 + 7) + 5 - 3 - 2")) |> debug
  aux(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      Option[(Expression, String, List[Token])]),
  ) |> debug
  aux(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      Option[(BoxedInt, String, List[Token])]),
  ) |> debug
  aux(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      Option[(BoxedString, String, List[Token])]),
  ) |> debug
}

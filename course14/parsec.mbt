///|
type Lexer[V] (@string.View) -> (V, @string.View)?

///|
fn[V] Lexer::parse(self : Lexer[V], str : @string.View) -> (V, @string.View)? {
  self.inner()(str)
}

///|
fn pchar(predicate : (Char) -> Bool) -> Lexer[Char] {
  Lexer(input => match input {
    [ch, .. rest] if predicate(ch) => Some((ch, rest))
    _ => None
  })
}

///|
fn[I, O] Lexer::map(self : Lexer[I], f : (I) -> O) -> Lexer[O] {
  Lexer(fn(input) { self.parse(input).map(pair => (f(pair.0), pair.1)) })
}

///|
fn[V1, V2] Lexer::then(
  self : Lexer[V1],
  parser2 : Lexer[V2],
) -> Lexer[(V1, V2)] {
  Lexer(fn(input) {
    guard self.parse(input) is Some((value, rest)) else { return None }
    guard parser2.parse(rest) is Some((value2, rest2)) else { return None }
    Some(((value, value2), rest2))
  })
}

///|
fn[Value] Lexer::or(
  self : Lexer[Value],
  parser2 : Lexer[Value],
) -> Lexer[Value] {
  Lexer(fn(input) {
    match self.parse(input) {
      None => parser2.parse(input)
      Some(_) as result => result
    }
  })
}

///|
fn[Value] Lexer::many(self : Lexer[Value]) -> Lexer[@list.T[Value]] {
  Lexer(fn(input) {
    loop (input, @list.empty()) {
      (rest, cumul) =>
        match self.parse(rest) {
          None => Some((cumul.rev(), rest))
          Some((value, rest)) => continue (rest, @list.construct(value, cumul))
        }
    }
  })
}

///| Number = %x30 / (%x31-39) *(%x30-39)  
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
} derive(Show)

///|
let symbol : Lexer[Token] = pchar(ch => ch
  is ('+' | '-' | '*' | '/' | '(' | ')')).map(token => match token {
  '+' => Token::Plus
  '-' => Token::Minus
  '*' => Token::Multiply
  '/' => Token::Divide
  '(' => Token::LParen
  ')' => Token::RParen
  _ => panic()
})

///|
let whitespace : Lexer[Char] = pchar(ch => ch is ' ')

///|
let zero : Lexer[Int] = pchar(ch => ch is '0').map(_ => 0)

///|
let one_to_nine : Lexer[Int] = pchar(ch => ch is ('1'..='9')).map(ch => ch.to_int() -
  '0'.to_int())

///|
let zero_to_nine : Lexer[Int] = pchar(ch => ch is ('0'..='9')).map(ch => ch.to_int() -
  '0'.to_int())

///|
let value : Lexer[Token] = zero
  .or(
    one_to_nine
    .then(zero_to_nine.many())
    .map(pair => {
      let (i, ls) = pair
      ls.fold((i, j) => i * 10 + j, init=i)
    }),
  )
  .map(Token::Value(_))

///|
let tokens : Lexer[@list.T[Token]] = value
  .or(symbol)
  .then(whitespace.many())
  .map(p => p.0)
  .many()

///|
test "pchar" {
  inspect(
    pchar(ch => ch is 'a').parse("asdf"),
    content=(
      #|Some(('a', "sdf"))
    ),
  )
  inspect(pchar(ch => ch is 'a').parse("sdf"), content="None")
}

///|
test "Lexing" {
  inspect(
    tokens.parse("-10123+-+523 103    ( 5) )  ").unwrap(),
    content=(
      #|(@list.of([Minus, Value(10123), Plus, Minus, Plus, Value(523), Value(103), LParen, Value(5), RParen, RParen]), "")
    ),
  )
  inspect(
    pchar(ch => ch is 'a').parse("asdf"),
    content=(
      #|Some(('a', "sdf"))
    ),
  )
  inspect(pchar(ch => ch is 'a').parse("sdf"), content="None")
}

///| atomic = Value / LParen expression RParen  
/// combine = atomic *( (Multiply / Divide) combine)  
/// expression = combine *( (Plus / Minus) expression)  
enum Expression {
  Number(Int)
  Plus(Expression, Expression)
  Minus(Expression, Expression)
  Multiply(Expression, Expression)
  Divide(Expression, Expression)
} derive(Show)

///|
type Parser[V] (@list.T[Token]) -> (V, @list.T[Token])?

///|
fn[V] Parser::parse(
  self : Parser[V],
  tokens : @list.T[Token],
) -> (V, @list.T[Token])? {
  self.inner()(tokens)
}

///|
fn ptoken(predicate : (Token) -> Bool) -> Parser[Token] {
  Parser(token => match token {
    Empty => None
    More(token, tail=rest) =>
      if predicate(token) {
        Some((token, rest))
      } else {
        None
      }
  })
}

///|
fn[I, O] Parser::map(self : Parser[I], f : (I) -> O) -> Parser[O] {
  Parser(fn(input) { self.parse(input).map(pair => (f(pair.0), pair.1)) })
}

///|
fn[V1, V2] Parser::then(
  self : Parser[V1],
  parser2 : Parser[V2],
) -> Parser[(V1, V2)] {
  Parser(fn(input) {
    guard self.parse(input) is Some((value, rest)) else { return None }
    parser2.parse(rest).map(pair => ((value, pair.0), pair.1))
  })
}

///|
fn[Value] Parser::or(
  self : Parser[Value],
  parser2 : Parser[Value],
) -> Parser[Value] {
  Parser(fn(input) {
    match self.parse(input) {
      None => parser2.parse(input)
      Some(_) as result => result
    }
  })
}

///|
fn[Value] Parser::many(self : Parser[Value]) -> Parser[@list.T[Value]] {
  Parser(fn(input) {
    loop (input, @list.empty()) {
      (rest, cumul) =>
        match self.parse(rest) {
          None => Some((cumul.rev(), rest))
          Some((value, rest)) => continue (rest, @list.construct(value, cumul))
        }
    }
  })
}

///|
fn[Value] Parser::from_ref(ref_ : Ref[Parser[Value]]) -> Parser[Value] {
  Parser(fn(input) { ref_.val.parse(input) })
}

///|
let lparen : Parser[Token] = ptoken(token => token is LParen)

///|
let rparen : Parser[Token] = ptoken(token => token is RParen)

///|
let plus : Parser[Token] = ptoken(token => token is Plus)

///|
let minus : Parser[Token] = ptoken(token => token is Minus)

///|
let multiply : Parser[Token] = ptoken(token => token is Multiply)

///|
let divide : Parser[Token] = ptoken(token => token is Divide)

///|
fn parser() -> Parser[Expression] {
  let expression_ref : Ref[Parser[Expression]] = { val: Parser(_ => None) }
  let number : Parser[Expression] = ptoken(token => token is Value(_)).map(token => {
    guard token is Value(i)
    Expression::Number(i)
  })
  let atom = lparen
    .then(Parser::from_ref(expression_ref))
    .then(rparen)
    .map(expr => expr.0.1)
    .or(number)
  let combine = atom
    .then(multiply.or(divide).then(atom).many())
    .map(pair => {
      guard pair is (expr, list)
      list.fold(
        (expr, operator_and_expr) => match operator_and_expr {
          (Multiply, e2) => Expression::Multiply(expr, e2)
          (_, e2) => Expression::Divide(expr, e2)
        },
        init=expr,
      )
    })
  expression_ref.val = combine
    .then(plus.or(minus).then(combine).many())
    .map(pair => {
      guard pair is (expr, list)
      list.fold(
        (e, expr) => match expr {
          (Plus, e2) => Expression::Plus(e, e2)
          (_, e2) => Expression::Minus(e, e2)
        },
        init=expr,
      )
    })
  Parser::from_ref(expression_ref)
}

///|
trait Expr: Add + Sub + Mul + Div {
  number(Int) -> Self
}

// Semantic: create syntax tree 语义：构造语法树

///|
impl Expr for Expression with number(i : Int) -> Expression {
  Number(i)
}

///|
impl Add for Expression with op_add(a : Expression, b : Expression) -> Expression {
  Plus(a, b)
}

///|
impl Sub for Expression with op_sub(a : Expression, b : Expression) -> Expression {
  Minus(a, b)
}

///|
impl Mul for Expression with op_mul(a : Expression, b : Expression) -> Expression {
  Multiply(a, b)
}

///|
impl Div for Expression with op_div(a : Expression, b : Expression) -> Expression {
  Divide(a, b)
}

// Semantic: compute expression 语义：计算表达式

///|
type BoxedInt Int derive(Show)

///|
impl Expr for BoxedInt with number(i : Int) -> BoxedInt {
  BoxedInt(i)
}

///|
impl Add for BoxedInt with op_add(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.inner() + b.inner())
}

///|
impl Sub for BoxedInt with op_sub(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.inner() - b.inner())
}

///|
impl Mul for BoxedInt with op_mul(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.inner() * b.inner())
}

///|
impl Div for BoxedInt with op_div(a : BoxedInt, b : BoxedInt) -> BoxedInt {
  BoxedInt(a.inner() / b.inner())
}

// Semantic: print expression 语义：输出表达式

///|
struct BoxedString {
  str : String
  level : Int
} derive(Show)

///|
impl Expr for BoxedString with number(i : Int) -> BoxedString {
  { str: i.to_string(), level: 0 }
}

///|
impl Add for BoxedString with op_add(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = a.str
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\{stra} + \{strb}", level: 1 }
}

///|
impl Sub for BoxedString with op_sub(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = a.str
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\{stra} - \{strb}", level: 1 }
}

///|
impl Mul for BoxedString with op_mul(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = if a.level == 1 { "(" + a.str + ")" } else { a.str }
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\{stra} * \{strb}", level: 2 }
}

///|
impl Div for BoxedString with op_div(a : BoxedString, b : BoxedString) -> BoxedString {
  let stra = if a.level == 1 { "(" + a.str + ")" } else { a.str }
  let strb = if b.level == 1 { "(" + b.str + ")" } else { b.str }
  { str: "\{stra} / \{strb}", level: 2 }
}

///|
fn[E : Expr] recursive_parser_with_tagless_final() -> Parser[E] {
  let number : Parser[E] = ptoken(token => token is Value(_)).map(ptoken => {
    guard ptoken is Value(i)
    E::number(i)
  })
  letrec atom = fn(tokens : @list.T[Token]) -> (E, @list.T[Token])? {
    lparen
    .then(Parser(expression))
    .then(rparen)
    .map(expr => expr.0.1)
    .or(number)
    .parse(tokens)
  }
  and combine = fn(tokens : @list.T[Token]) -> (E, @list.T[Token])? {
    (Parser(atom) : Parser[E])
    .then(multiply.or(divide).then(Parser(atom)).many())
    .map(pair => {
      guard pair is (e, list)
      list.fold(
        (e, tokens) => match tokens {
          (Multiply, expr) => e * expr
          (_, expr) => e / expr
        },
        init=e,
      )
    })
    .parse(tokens)
  }
  and expression = fn(tokens : @list.T[Token]) -> (E, @list.T[Token])? {
    (Parser(combine) : Parser[E])
    .then(plus.or(minus).then(Parser(combine)).many())
    .map(pair => {
      guard pair is (e, list)
      list.fold(
        (e, expr) => match expr {
          (Plus, expr) => e + expr
          (_, expr) => e - expr
        },
        init=e,
      )
    })
    .parse(tokens)
  }

  Parser(expression)
}

///|
fn parse_string(
  str : @string.View,
) -> (Expression, @string.View, @list.T[Token])? {
  guard tokens.parse(str) is Some((token_list, rest_string)) else {
    return None
  }
  guard parser().parse(token_list) is Some((expr, rest_token)) else {
    return None
  }
  Some((expr, rest_string, rest_token))
}

///|
fn[E : Expr] parse_string_tagless_final(
  str : @string.View,
) -> (E, @string.View, @list.T[Token])? {
  guard tokens.parse(str) is Some((token_list, rest_string)) else {
    return None
  }
  guard recursive_parser_with_tagless_final().parse(token_list)
    is Some((expr, rest_token)) else {
    return None
  }
  Some((expr, rest_string, rest_token))
}

///|
test "Parsing" {
  inspect(
    parse_string("1 + 1 * (307 + 7) + 5 - 3 - 2"),
    content=(
      #|Some((Minus(Minus(Plus(Plus(Number(1), Multiply(Number(1), Plus(Number(307), Number(7)))), Number(5)), Number(3)), Number(2)), "", @list.of([])))
    ),
  )
  inspect(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      (Expression, @string.View, @list.T[Token])?).unwrap(),
    content=(
      #|(Minus(Minus(Plus(Plus(Number(1), Multiply(Number(1), Plus(Number(307), Number(7)))), Number(5)), Number(3)), Number(2)), "", @list.of([]))
    ),
  )
  inspect(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      (BoxedInt, @string.View, @list.T[Token])?).unwrap(),
    content=(
      #|(BoxedInt(315), "", @list.of([]))
    ),
  )
  inspect(
    (
      parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - 3 - 2") :
      (BoxedString, @string.View, @list.T[Token])?),
    content=(
      #|Some(({str: "1 + 1 * (307 + 7) + 5 - 3 - 2", level: 1}, "", @list.of([])))
    ),
  )
}

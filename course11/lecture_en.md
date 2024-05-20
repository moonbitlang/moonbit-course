# Case Study: Parser

Now with the basic understanding of the MoonBit programming language, we can explore more complex programs and present some interesting cases. In this lecture, we'll present a parser.

There are various types of languages in the world, including programming languages and other symbolic languages. Let's take the four basic arithmetic operations as an example. For a string like `"(1+ 5) * 7 / 2"`, the first step is to split it into a list of tokens. For instance, we can tokenize it into a left parenthesis, integer 1, plus sign, integer 5, right parenthesis, multiplication sign, integer 7, division sign, and integer 2. Although there is no space between integer 1, the parenthesis, and the plus sign, they should be separated into three tokens to follow the lexical rules. This step is known as lexical analysis.

Lastly, we calculate the final result according to the semantics. For example, semantically, `1 + 5` means to find the sum of integers 1 and 5.

Syntax analysis/parsing is an important field of computer science because all programming languages will need parsing to analyze and run source code, and thus there exist many mature tools. In this lecture, we will present parser combinators to handle both lexical and syntax analysis. If interested, you may also refer to the recommended readings at the end to dive deeper. All code will be available on the course website. Let's start!

## Lexical Analysis

First, let's talk about lexical analysis. It aims to break the input into tokens where the input is a string, and the output is a token stream. For example, "12 +678" should be split into integer 12, plus sign, and integer 678. Lexical analysis is in general simple and can usually be done using a finite state machine. Domain-specific languages like lex or flex can automatically generate the program. Here, we will use parser combinators. We first define the lexical rules of arithmetic expressions, including integers, parentheses, operators, and whitespaces.

```abnf
Number     = %x30 / (%x31-39) *(%x30-39)
LParen     = "("
RParen     = ")"
Plus       = "+"
Minus      = "-"
Multiply   = "*"
Divide     = "/"
Whitespace = " "
```

Let's take integers and the plus sign for examples. Each line in the lexical rules corresponds to a pattern-matching rule. Content within quotes means matching a string of the same content. Rule `a b` means matching rule `a` first, and if it succeeds, continue to pattern match rule `b`. Rule `a / b` means matching rule `a` or `b`, try matching `a` first, and then try matching rule `b` if it fails. Rule `*a ` with an asterisk in front refers to zero or more matches. Lastly, `%x` means matching a UTF-encoded character, where `x` indicates it's in hexadecimal. For example, `0x30` corresponds to the 48th character `0`, and it is `30` in hexadecimal. With this understanding, let's examine the definition rules. Plus is straightforward, representing the plus sign. Number corresponds to zero or a character from 1-9 followed by zero or more characters from 0-9.

![](../pics/lex_rail.drawio.svg)

In MoonBit, we define tokens as enums, and tokens can be values containing integers or operators and parentheses. Whitespaces are simply discarded.

```moonbit
enum Token {
  Value(Int); LParen; RParen; Plus; Minus; Multiply; Divide
} derive(Debug)
```

### Parser Combinator

We then proceed to build a combinable parser. The parser is a function that takes a string as input and outputs a nullable `Option`. An empty value indicates the pattern matching failed, and a non-empty value contains both the result and the remaining string. Ideally, when parsing fails, we should provide error messages like why and where it failed, but this is omitted for simplicity. Feel free to implement it using `Result[A, B]`. We also provide a `parse` method for convenience.

```moonbit
// V represents the value obtained after parsing succeeds
// Lexer[V] == (String) -> Option[(V, String)]
type Lexer[V] (String) -> Option[(V, String)]

fn parse[V](self : Lexer[V], str : String) -> Option[(V, String)] {
  (self.0)(str)
}
```

We first define the simplest parser, which just matches a single character. To construct this parser, we need a function to check if an input character meets the conditions. In line 3, if the input is not empty and the first character meets our criteria, we read that character and return it as the value, along with the remaining string. Otherwise, we return an empty value indicating matching failure. We'll use this parser in the following code. For instance, we define an anonymous function to determine if a character is `a` and use it to parse the string `"asdf"`. As "asdf" starts with `a`, parsing is successful, giving us the result of `a` and the remaining string `"sdf"`. If we use the same function to match the remaining string again, it will fail.

```moonbit
fn pchar(predicate : (Char) -> Bool) -> Lexer[Char] {
  Lexer(fn(input) {
    if input.length() > 0 && predicate(input[0]) {
      Some((input[0], input.to_bytes().sub_string(2, input.length() * 2 - 2)))
    } else {
      None
} },) }

fn init {
  debug(pchar(fn{ ch => ch == 'a' }).parse("asdf")) // Some(('a', "sdf"))
  debug(pchar(fn{ 
    'a' => true
     _  => false
  }).parse("sdf")) // None
}
```

With this simple parser, we can already handle most tokens, including parentheses, arithmetic operators, and whitespaces. Here, we also define them using anonymous functions and directly try pattern matching all possibilities. It returns `true` if the character is something we want to match; otherwise, it returns `false`. It's the same for whitespaces. However, simply parsing the input into characters isn't enough since we want to obtain more specific enum values, so we'll need to define a mapping function.

The `map` function can convert the result upon successful parsing. Its parameters include the parser itself and a transformation function. At the end of line 3, we use the question mark operator `?`. If parsing succeeds and the value is non-empty, the operator allows us to directly access the tuple containing the value and remaining string; otherwise, it returns the empty value in advance. After obtaining the value, we apply the transformation function. Utilizing this, we can map the characters corresponding to arithmetic operators and parentheses into their corresponding enum values.

```moonbit
fn map[I, O](self : Lexer[I], f : (I) -> O) -> Lexer[O] {
  Lexer(fn(input) {
    // Non-empty value v is in Some(v), empty value None is directly returned
    let (value, rest) = self.parse(input)?
    Some((f(value), rest))
},) }

let symbol: Lexer[Token] = pchar(fn{  
    '+' | '-' | '*' | '/' | '(' | ')' => true
    _ => false
}).map(fn{
    '+' => Plus;     '-' => Minus
    '*' => Multiply; '/' => Divide
    '(' => LParen;   ')' => RParen
})
```

Let's look at other combinators. We've seen other pattern matching rules like matching `a` followed by `b`, `a` or `b`, zero or more occurrences of `a`, etc. Each combinator is simple to implement, and let's do it one by one. For matching `a` and then `b`, we first use `self` for parsing, as shown in line 3. After obtaining the value and the remaining string with the question mark operator `?`, we use another parser to parse the remaining string, as shown in line 4. The two outputs are returned as a tuple. Then, for matching `a` or `b`, we will pattern match the result of parsing using `self`. If empty, we use the result of another parser; otherwise, we return the current result.

```moonbit
fn and[V1, V2](self : Lexer[V1], parser2 : Lexer[V2]) -> Lexer[(V1, V2)] {
  Lexer(fn(input) {
    let (value, rest) = self.parse(input)?
    let (value2, rest2) = parser2.parse(rest)?
    Some(((value, value2), rest2))
},) }

fn or[Value](self : Lexer[Value], parser2 : Lexer[Value]) -> Lexer[Value] {
  Lexer(fn(input) {
    match self.parse(input) {
      None => parser2.parse(input)
      Some(_) as result => result
} },) }
```

For matching zero or more occurrences, we use a loop as shown in lines 5 to 10. We try parsing the remaining input in line 6. If it fails, we exit the loop; otherwise, we add the parsed content to the list and update the remaining input. Ultimately, the parsing always succeeds, so we put the result into `Some`. Note that we're storing values in a list, and a list is a stack, so it needs to be reversed to obtain the correct order.

```moonbit
fn reverse_list[X](list : List[X]) -> List[X] {
  fn go(acc, xs : List[X]) {
    match xs {
      Nil => acc
      Cons(x, rest) => go((Cons(x, acc) : List[X]), rest)
    } }
  go(Nil, list)
}

fn many[Value](self : Lexer[Value]) -> Lexer[List[Value]] {
  Lexer(fn(input) {
    let mut rest = input
    let mut cumul = List::Nil
    while true {
      match self.parse(rest) {
        None => break
        Some((value, new_rest)) => {
          rest = new_rest
          cumul = Cons(value, cumul) // Parsing succeeds, add the content
    } } }
    Some((reverse_list(cumul), rest)) // ⚠️List is a stack, reverse it for the correct order
},) }
```

Lastly, we can build a lexical analyzer for integers. An integer is either zero or starts with a non-zero digit followed by any number of digits. We'll first build three helper parsers. The first parser matches the character `0` and maps it to the number zero. The next two parsers match `1-9` and `0-9`, respectively. Here, we use the ranges of UTF encoding to determine, and since numbers in UTF are ordered from 0 to 9, we calculate the difference between a character's encoding and the encoding of `0` to obtain the corresponding number. Finally, we follow the syntax rules to construct the parser using our combinators. As shown in lines 11 and 12, we mirror the rules exactly. However, a non-zero digit and any number of digits just form a tuple of a digit and a list of digits, so we need one more mapping step. We use `fold_left` to fold it into an integer. Since digits near the head of the list are left digits to the left, multiplying the digit by 10 and adding a right digit forms the final integer, which we then map to an enum.

```moonbit
fn fold_left_list[A, B](list : List[A], f : (B, A) -> B, b : B) -> B {
  match list {
    Nil => b
    Cons(hd, tl) => fold_left_list(tl, f, f(b, hd))
} }

// Convert characters to integers via encoding
let zero: Lexer[Int] = 
  pchar(fn { ch => ch == '0' }).map(fn { _ => 0 })
let one_to_nine: Lexer[Int] = 
  pchar(fn { ch => ch.to_int() >= 0x31 && ch.to_int() <= 0x39 },).map(fn { ch => ch.to_int() - 0x30 })
let zero_to_nine: Lexer[Int] = 
  pchar(fn { ch => ch.to_int() >= 0x30 && ch.to_int() <= 0x39 },).map(fn { ch => ch.to_int() - 0x30 })

// number = %x30 / (%x31-39) *(%x30-39)  
let value : Lexer[Token] = zero.or(
  one_to_nine.and(zero_to_nine.many()).map( // (Int, List[Int])
    fn { (i, ls) => fold_left_list(ls, fn { i, j => i * 10 + j }, i) },
  ),
).map(Token::Value)
```

We're now just one step away from finishing lexical analysis: analyzing the entire input stream. There may be whitespaces in between tokens, so we allow arbitrary lengths of whitespaces after defining the number or symbol in line 2. We map and discard the second value in the tuple representing spaces, and may repeat the entire parser an arbitrary number of times. Finally, we can split a string into minus signs, numbers, plus signs, parentheses, etc. However, this output stream doesn't follow the syntax rules of arithmetic expressions. For this, we will need syntax analysis.

```moonbit
let tokens : Lexer[List[Token]] = 
  value.or(symbol).and(whitespace.many())
    .map(fn { (symbols, _) => symbols },) // Ignore whitespaces
    .many()

fn init {
  debug(tokens.parse("-10123-+-523 103    ( 5) )  "))
}
```

## Syntax Analysis

In the last example, we converted a string into a stream of tokens, discarded unimportant whitespaces, and split the string into meaningful enums. Now we will analyze whether the token stream is syntactically valid in terms of arithmetic expressions. As a simple example, the parentheses in an expression should be paired and should close in the correct order. We defined a simple syntax rule in the following code snippet. An arithmetic expression can be a single number, two arithmetic expressions carrying out an operation, or an expression surrounded by parentheses. We aim to convert a token stream into an abstract syntax tree like the one shown below. For the expression `1 + (1 - 5)`, the root node is a plus sign, representing the last operation executed. It means adding 1 to the expression on the right side. The right subtree contains a minus sign with integers 1 and 5, meaning 1 minus 5. The parentheses mean that it is executed earlier, so it's deeper down in the expression tree. Similarly, for the expression `(1 - 5) * 5`, the first calculation executed is the subtraction inside the parentheses, and then the multiplication. 

```abnf
expression = Value / "(" expression ")"
expression =/ expression "+" expression / expression "-" expression 
expression =/ expression "*" expression / expression "/" expression
```

![](../pics/ast-example.drawio.svg)

However, our syntax rules have some issues since it doesn't differentiate the precedence levels. For instance, `a + b * c` should be interpreted as `a` plus the product of `b` and `c`, but according to the current syntax rules, the sum of `a` and `b` multiplied by `c` is also valid, which introduces ambiguity. It also doesn't show associativity. Arithmetic operators should be left-associative, meaning `a + b + c` should be interpreted as `a` plus `b`, then adding `c`. However, the current syntax also allows adding `a` to the sum of `b` and `c`. So, we need to adjust the syntax rules.

The modified syntax rules are split into three parts. The first one is `atomic`, which is either an integer or an expression within parentheses. The second one is `atomic`, or `combine` multiplied or divided by `atomic`. The third one is `combine`, or `expression` plus or minus `combine`. The purpose of splitting into three rules is to differentiate operator precedence, while the left recursion in a single rule is to reflect left associativity. However, our parser can't handle left recursion. When trying to pattern match the left-recursive rule, it will first try to match the same rule on the side of the operator, which leads to recursion and prevents making progress. Still, this is just a limitation of our parser. Bottom-up parsers can handle left recursion, please refer to the recommended readings if you are interested.

```abnf
atomic     = Value / "(" expression ")"
combine    = atomic  /    combine "*" atomic  /    combine "/" atomic 
expression = combine / expression "+" combine / expression "-" combine
```

Our modified syntax rules eliminate recursion but require additional processing for mapping. In short, we define the abstract syntax tree, and an expression can be an integer or a result of arithmetic operation expressions as mentioned before.

### Syntax Parsing

Let's define a syntax parser similar to the previous definitions, except that the input is now a list of tokens instead of a string. Most combinators are like the previous ones and can be implemented similarly. The challenge is how to define mutually recursive syntax parsers since `atomic` references `expression`, and `expression` depends on `combine`, which in turn depends on `atomic`. To solve this problem, we offer two solutions: deferring the definition or recursive functions.

```moonbit
type Parser[V] (List[Token]) -> Option[(V, List[Token])]

fn parse[V](self : Parser[V], tokens : List[Token]) -> Option[(V, List[Token])] {
  (self.0)(tokens)
}
```

### Recursive Definition

Deferring the definition involves first defining a reference with a default value. After defining the dependent combinators, the reference value is updated so that it retrieves the most recent value during computation. Here, we define a simple `ref` function that treats the reference as a normal parser and only fetches the current value during computation.

```moonbit
fn Parser::ref[Value](ref: Ref[Parser[Value]]) -> Parser[Value] {
  Parser(fn(input) {
    ref.val.parse(input)
  })
}
```

Afterward, we use the delayed definition to parse expressions. We construct a reference to the `expression` rule with a default value that will always fail to parse in any situation. Then, we define a parser for the first rule, `atomic`, using the series of combinators we defined earlier including `ref`, and following the syntax rules. The parser implementations for the left and right parentheses are relatively simple and we will not show any details here. Next, we define a parser for the second rule similarly. After defining the second rule, we update the value in the initial reference with the actual parser. Finally, we return the content of the actual parser. Since the content has been updated, we can directly access the value stored.

```moonbit no-check
fn parser() -> Parser[Expression] {
  // First define an empty reference
  let expression_ref : Ref[Parser[Expression]] = { val : Parser(fn{ _ => None }) }

  // atomic = Value / "(" expression ")"
  let atomic =  // Use the reference for the definition
    (lparen.and(ref(expression_ref)).and(rparen).map(fn { ((_, expr), _) => expr}))
      .or(number)

  // combine = atomic *( ("*" / "/") atomic)
  let combine = atomic.and(multiply.or(divide).and(atomic).many()).map(fn {
    ...
  })

  // expression = combine *( ("+" / "-") combine)
  expression_ref.val = combine.and(plus.or(minus).and(combine).many()).map(fn {
    ...
  })
  ref(expression_ref)
}
```

The concept of recursive functions is similar. Our parser is essentially a function wrapped in another type to distinguish it and make it easier to add methods. Therefore, we can define three mutually recursive functions, as shown in lines 4, 10, and 11. Then, in line 6, we construct the corresponding parser using the function. Finally, we return the parser corresponding to the function. At this point, we've completed our parser. We can use this parser to parse the token stream we previously analyzed into its corresponding abstract syntax tree. We can pattern-match to compute the result, but there are other available options to evaluate expressions.

```moonbit no-check
fn recursive_parser() -> Parser[Expression] {
  // Define mutually recursive functions
  // atomic = Value / "(" expression ")"
  fn atomic(tokens: List[Token]) -> Option[(Expression, List[Token])] {
    lparen.and(
      Parser(expression) // Reference function
    ).and(rparen).map(fn { ((_, expr), _) => expr})
      .or(number).parse(tokens)
  }
  fn combine(tokens: List[Token]) -> Option[(Expression, List[Token])] { ... }
  fn expression(tokens: List[Token]) -> Option[(Expression, List[Token])] { ... }

  // Return the parser represented by the function
  Parser(expression)
}
```

### Beyond the Syntax Tree: Tagless Final

Our previous approach is to generate an abstract syntax tree and then parse it. This is like labeling because we used enums. Here, we introduce Tagless Final as another approach to evaluate expressions without building an abstract syntax tree. This is possible thanks to the interfaces in MoonBit. We abstract the behavior through `trait`. An expression can be constructed from an integer and there can be arithmetic operations between two expressions. Based on this, we defined an interface. An interface comes with implementations, and different implementations of the interface correspond to different interpretations of the behavior or semantics.

```moonbit
trait Expr {
  number(Int) -> Self
  op_add(Self, Self) -> Self
  op_sub(Self, Self) -> Self
  op_mul(Self, Self) -> Self
  op_div(Self, Self) -> Self
}
```

We use behavioral abstractions to modify our parser. For integers, we don't construct an enum typed integer but instead use the `number` method of the interface. For arithmetic operations, we use the operators provided in the interface instead of the enum constructors in the mapping function. Lastly, we combine lexical and syntax parsing to produce a parser that processes a string into the final result. Note that we don't specify the parsing type, any interface compatible with the expression will work.

```moonbit no-check
fn recursive_parser[E : Expr]() -> Parser[E] {
  let number : Parser[E] = ptoken(fn { Value(_) => true; _ => false})
    .map(fn { Value(i) => E::number(i) }) // Use the abstract behavior

  fn atomic(tokens: List[Token]) -> Option[(E, List[Token])] { ... }
  // Convert to a * b * c * ... and a / b / c / ...
  fn combine(tokens: List[Token]) -> Option[(E, List[Token])] { ... }
  // Convert to a + b + c + ... and a - b - c - ...
  fn expression(tokens: List[Token]) -> Option[(E, List[Token])] { ... }

  Parser(expression)
}
// Put things together
fn parse_string[E : Expr](str: String) -> Option[(E, String, List[Token])] {
  let (token_list, rest_string) = tokens.parse(str)?
  let (expr, rest_token) : (E, List[Token]) = recursive_parser().parse(token_list)?
  Some(expr, rest_string, rest_token)
}
```

Thus, we only need to define different implementations and specify which one to use in MoonBit. The former involves defining different methods for the data structure to meet the requirements of the interface, such as the `number` method in lines 4 and 5. The latter specifies the return type of functions to indicate the specific type parameter, as shown in lines 8 and 10. In line 8, we will obtain the expression tree constructed from enums, while in line 10 we can directly obtain the result. You can also add other interpretations, like converting an expression into a formatted string by removing extra parentheses and whitespaces.

```moonbit no-check
enum Expression { ... } derive(Debug) // Implementation of syntax tree
type BoxedInt Int derive(Debug) // Implementation of integer
// Other interface implementation methods omitted
fn BoxedInt::number(i: Int) -> BoxedInt { BoxedInt(i) }
fn Expression::number(i: Int) -> Expression { Number(i) }
// Parse
debug((parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - (3 - 2)") 
  : Option[(Expression, String, List[Token])])) // Get the syntax tree
debug((parse_string_tagless_final("1 + 1 * (307 + 7) + 5 - (3 - 2)") 
  : Option[(BoxedInt, String, List[Token])])) // Get the calculation result
```

## Summary

In summary, we presented a parser in this lecture. We introduced the concepts of lexical and syntax analysis, illustrated the definition and implementation of parser combinators, and expanded on the concept and implementation of Tagless Final. There are a few points to add. For arithmetic expressions, there's a simple algorithm called the Shunting Yard algorithm that calculates the value of the expression after splitting it into tokens. Syntax analysis/parsing is an important field in computer science, and understanding it thoroughly takes a lot of time. It's impossible to cover everything in just one lecture, so we only provided a brief introduction. Feel free to refer to lectures 1-8 of Stanford course CS143, the first five chapters of *Compilers: Principles, Techniques, and Tools*, or the first three chapters of *Modern Compiler Implementation*. Also, the latter two books are sometimes called the Dragon Book and Tiger Book because of their cover designs.

There's also an additional exercise: You might have noticed that the structure of string and token stream parsers is almost identical, so is it possible to abstract the strings and token streams to implement a parser combinator compatible with different streams? You're encouraged to think about it!

Lastly, we hope everyone notices the important modular programming thinking embodied in parsing combinators: building modules from small to large that can be combined together to build programs from simple to complex. By adopting modular thinking, we can manage complexity and discard irrelevant information. For instance, when we defined the parser at the end, we used combinators to basically replicate the syntax one-to-one, without worrying about the specific implementation of the parser. Only in this way can we build larger, maintainable programs with fewer bugs.

